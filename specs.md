# SPECIFICATION — Ticket Workflow System for Claude Code

> **This document is a self-contained prompt.** Feed it to Claude Code (Opus 4.6) and it will generate the entire system: agents, skills, install scripts, and documentation.
>
> **Instruction for Claude Code:**
> Read this specification in its entirety. Then generate ALL described files in the indicated directory structure, ready to be installed into `$CLAUDE_DIR`. Every file must be complete and functional. Do not skip any file. At the end, generate an `install.sh` script that copies everything to the right location, and an `init-project.sh` script that initializes a new project.

---

## 1. VISION AND PHILOSOPHY

### 1.1 What We're Building

A **file-based, AI-native project management workflow** that runs entirely inside a git repository via Claude Code. No SaaS, no databases, no external dependencies — only markdown files, shell commands, and Claude Code configuration.

### 1.2 Core Principles

- **One active ticket at a time.** Focus over multitasking.
- **No code changes without a ticket.** Even a one-line fix. The discipline is the product.
- **The filesystem is the database.** Git is the audit trail.
- **Each command is autonomous.** Any command can run independently.
- **Artifacts are the contract.** Commands communicate through markdown files, not implicit state.

### 1.3 Installation Directory Variable

Throughout this specification, `$CLAUDE_DIR` refers to the root Claude Code configuration directory where agents and skills are installed.

- **Default:** `~/.claude/`
- **Determined at install time** by an interactive prompt in `install.sh` (see section 5.3).
- All path references in this spec use `$CLAUDE_DIR` so the system is not tied to a single location.

### 1.4 Permission Philosophy

The main Claude Code session always stays in **`default` mode** (locked down). The `/ticket-system-*` slash commands elevate privileges in a targeted way by forking into specialized agents. The user never has to answer a permission prompt — either the agent has the right, or it doesn't. Permission prompts are a sign of misconfiguration, not a feature.

---

## 2. TECHNICAL ARCHITECTURE

### 2.1 Two Complementary Layers: Skills + Agents

The system relies on two types of Claude Code files that complement each other:

**Skills** (`$CLAUDE_DIR/skills/ticket-system-*/SKILL.md`):
- Provide the slash commands (`/ticket-system-create`, `/ticket-system-plan`, etc.)
- Contain the detailed instructions for each command
- Delegate execution to an agent via `context: fork` + `agent: <name>`

**Agents** (`$CLAUDE_DIR/agents/ticket-system-*.md`):
- Define the execution profile: model, `permissionMode`, allowed tools
- Load the shared skill `ticket-system-conventions` via `skills: [ticket-system-conventions]`
- Are NOT directly invocable by the user

**Why this separation:**
- Skills have slash commands but NO `permissionMode` in their frontmatter.
- Agents have `permissionMode` and `model` but are NOT slash commands.
- The combination `context: fork` + `agent: <name>` in the skill gives both.

### 2.2 Shared Skill: `ticket-system-conventions`

An invisible skill (`user-invocable: false`) containing all system conventions: ticket format, directory structure, lifecycle, roadmap format, commit convention. Every agent loads it automatically at startup via `skills: [ticket-system-conventions]`.

### 2.3 Agent Profiles (6 agents, 3 permission levels)

| Agent | Model | permissionMode | Allowed Bash | Used by |
|-------|-------|---------------|--------------|---------|
| `ticket-system-reader` | haiku | plan | `Bash(cat *)`, `Bash(find *)`, `Bash(wc *)`, `Bash(grep *)`, `Bash(head *)`, `Bash(tail *)` | `/ticket-system-analyze` |
| `ticket-system-editor` | sonnet | acceptEdits | `Bash(git mv *)`, `Bash(git commit *)`, `Bash(git status)`, `Bash(git add *)`, `Bash(date *)`, `Bash(find tickets/*)`, `Bash(cat *)`, `Bash(mkdir *)` | `/ticket-system-create`, `/ticket-system-schedule`, `/ticket-system-split` |
| `ticket-system-planner` | opus | acceptEdits | `Bash(cat *)`, `Bash(find *)`, `Bash(wc *)`, `Bash(grep *)`, `Bash(head *)`, `Bash(tail *)`, `Bash(git log *)`, `Bash(git diff *)`, `Bash(git worktree *)`, `Bash(git mv *)`, `Bash(git commit *)`, `Bash(git add *)`, `Bash(git status)`, `Bash(mkdir *)`, `Bash(date *)` | `/ticket-system-plan` |
| `ticket-system-coder` | opus | bypassPermissions | Unrestricted (the plan is already approved) | `/ticket-system-implement` |
| `ticket-system-verifier` | sonnet | plan | `Bash(npm test *)`, `Bash(pytest *)`, `Bash(make test *)`, `Bash(git diff *)`, `Bash(git worktree list)`, `Bash(cat *)`, `Bash(find *)` | `/ticket-system-verify` |
| `ticket-system-ops` | sonnet | bypassPermissions | `Bash(git merge *)`, `Bash(git worktree *)`, `Bash(git branch *)`, `Bash(git mv *)`, `Bash(git commit *)`, `Bash(git add *)`, `Bash(git checkout *)`, `Bash(git status)` | `/ticket-system-commit` |

### 2.4 Automatic vs Manual Invocation

Each skill has a `disable-model-invocation` flag. Here is the strategy:

| Skill | `disable-model-invocation` | Reason |
|-------|---------------------------|--------|
| `ticket-system-create` | `false` (Claude can invoke) | Low risk — creates a markdown file in backlog |
| `ticket-system-schedule` | `false` | Relatively safe — git mv + roadmap edit |
| `ticket-system-analyze` | `false` | Read-only, zero risk |
| `ticket-system-split` | `true` (manual only) | Interactive, creates/rejects tickets — keep control |
| `ticket-system-plan` | `true` | Structural action — ticket activation + deep analysis |
| `ticket-system-implement` | `true` | Full autonomy, bypass permissions — never automatic |
| `ticket-system-verify` | `false` | Read-only + tests — safe |
| `ticket-system-commit` | `true` | Irreversible merge — always explicit |

---

## 3. DATA MODEL

### 3.1 Project Configuration

Every project using this system has a `.tickets/config.yml`:

```yaml
prefix: "PROJ"           # Ticket ID prefix (PROJ-001, PROJ-002, ...)
digits: 3                # Zero-padding width
tickets_dir: "tickets"   # Root directory for tickets
```

**Absolute rule:** all commands, templates, and scripts read this file first. No hardcoded prefixes.

### 3.2 Directory Structure

```
tickets/
├── backlog/           # Rough ideas, not yet refined
├── planned/           # Refined, ready to activate
│   └── roadmap.md     # Authoritative execution order
├── ongoing/           # The active ticket (max 1) — stored as subdirectory
│   └── PREFIX-XXX/    # Contains ticket.md + plan artifacts
├── completed/         # Successfully finished tickets
└── rejected/          # Cancelled or invalid tickets
```

### 3.3 Ticket Format

Markdown file with YAML frontmatter:

```markdown
---
id: PREFIX-XXX
title: "<concise title>"
status: backlog | planned | ongoing | completed | rejected
priority: P0 | P1 | P2
type: feature | bugfix | refactor | docs | research | infrastructure
created: YYYY-MM-DD HH:MM:SS
updated: YYYY-MM-DD HH:MM:SS
dependencies: []
assignee: human | ai | unassigned
estimated_complexity: small | medium | large
---

# PREFIX-XXX: <title>

## Objective
<!-- One paragraph: what does this ticket accomplish? -->

## Context
<!-- Why is this needed? -->

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Technical Approach
<!-- How should this be implemented? Key files, architecture decisions. -->

## Dependencies
<!-- List ticket IDs that must be completed before this one. -->

## Files Modified
<!-- Filled in during/after implementation. Track every file created or changed. -->

## Decisions
<!-- Design decisions made during this ticket. -->

## Notes
<!-- Open questions, risks, links to external resources. -->

## Log
<!-- Append-only log of significant events. -->
- YYYY-MM-DD HH:MM:SS: Ticket created.
```

**Timestamp rule:** All `created`, `updated`, and log-entry timestamps **must** be obtained by running the `date` command (e.g., `date '+%Y-%m-%d %H:%M:%S'`). Never rely on the model's internal knowledge of the current date — it can be wrong. Every agent that writes timestamps has `Bash(date *)` in its allowed tools for this reason.

### 3.4 Roadmap Format

`tickets/planned/roadmap.md`:

```markdown
# Roadmap

| Position | Ticket | Title | Size | Priority | Dependencies | Rationale |
|----------|--------|-------|------|----------|--------------|-----------|
| 1 | PREFIX-005 | Title | medium | P0 | — | Reason |
| 2 | PREFIX-008 | Title | medium | P0 | PREFIX-005 | Depends on auth |
```

When a ticket is activated, its row is removed from the roadmap.

### 3.5 Lifecycle (6 phases)

```
backlog → planned → ongoing → completed
                             → rejected
```

- **Create** → `tickets/backlog/PREFIX-XXX.md`
- **Schedule** → validate, refine, `git mv` to `planned/`, insert into `roadmap.md`
- **Activate** → verify `ongoing/` is empty, verify dependencies, create git worktree, create `tickets/ongoing/PREFIX-XXX/` in worktree, move ticket inside
- **Work** → all code changes scoped to the ticket
- **Complete** → verify all criteria are `[x]`, move to `completed/`
- **Reject** → document reason, move to `rejected/`

### 3.6 ID Assignment

1. Scan all files across all `tickets/` subdirectories
2. Find the highest `PREFIX-XXX` number
3. Increment by 1, zero-pad according to config

### 3.7 Commit Convention

```
PREFIX-XXX: Short description of the change
```

One ticket may span multiple commits.

### 3.8 Plan Artifacts

Two files live in `tickets/ongoing/PREFIX-XXX/`:

**`implementation-plan.md`:**
```markdown
# Implementation Plan — PREFIX-XXX

## Overview
Brief summary of what will be built.

## Steps
### Step 1: <title>
- **Files:** list of files to create/modify
- **What:** description of changes
- **Tests first:** TDD test(s) to write before implementation
- **Done when:** observable outcome

## Risk Notes
Anything that might go wrong or need adjustment.
```

**`test-plan.md`:**
```markdown
# Test Plan — PREFIX-XXX

## Strategy
Which testing approach (unit, integration, both).

## Test Cases
### TC-1: <description>
- **Type:** unit | integration
- **Target:** function/module being tested
- **Input:** test data
- **Expected:** expected outcome
- **Covers criteria:** which acceptance criteria this validates

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| Criterion 1         | TC-1, TC-3 |
```

---

## 4. COMMAND PIPELINE

### 4.1 Overview

```
/ticket-system-create           Create a ticket in backlog
      │
      ▼
/ticket-system-schedule         Backlog → Planned + roadmap
      │
      ▼
/ticket-system-analyze          Evaluate the 1st ticket on the roadmap
      │
      ├── too large → /ticket-system-split   Decompose, put back in flow
      │
      ▼
/ticket-system-plan             Activate + create worktree + generate plans
      │                    ↑
      │            [HUMAN APPROVAL GATE]
      ▼                                        ┐
/ticket-system-implement        Execute the plan │ worktree
      │                                        │ lifecycle
      ▼                                        │
/ticket-system-verify           Verify against test-plan │
      │                                        │
      ├── pass → /ticket-system-commit   Merge worktree → main ┘
      │
      └── fail → iterate on /ticket-system-implement or back to /ticket-system-plan
```

### 4.2 Detailed Command Specifications

---

#### `/ticket-system-create`

**Agent:** `ticket-system-editor` | **Auto-invocation:** yes
**Argument:** `[title or description]`

**Behavior:**
1. Read `.tickets/config.yml` (prefix, digits, tickets_dir).
2. Scan all files across all `tickets/` subdirectories to find the highest existing ID number.
3. Assign the next ID: increment by 1, zero-pad.
4. If `.tickets/TEMPLATE.md` exists, use it as the base. Otherwise use the standard ticket format from conventions.
5. Fill in: `id`, `created`, `updated` with current timestamp, `status: backlog`, `title` from arguments.
6. Save to `tickets/backlog/PREFIX-XXX.md`.
7. Add log entry: `Ticket created.`
8. Commit: `PREFIX-XXX: Create ticket — <title>`

**Without arguments:** ask for the title, type, and priority.

---

#### `/ticket-system-schedule`

**Agent:** `ticket-system-editor` | **Auto-invocation:** yes
**Argument:** `[ticket-id or description]`

**Behavior:**
1. Read `.tickets/config.yml`.
2. Locate the target ticket in `backlog/`. If a description is given instead of an ID, search backlog tickets for the best match and confirm with the user.
3. **Validate** the ticket: all frontmatter fields complete, acceptance criteria concrete and testable, technical approach sufficiently detailed.
4. If not refined enough: refine it (fill gaps, sharpen criteria). Show the user what changed.
5. `git mv` to `planned/`.
6. Update frontmatter: `status: planned`, `updated: <now>`.
7. Read `roadmap.md`, insert the ticket at the correct position (respect dependency ordering, then sort by priority P0 > P1 > P2 within the same dependency tier).
8. Add log entry.
9. Commit: `PREFIX-XXX: Schedule ticket — <title>`

---

#### `/ticket-system-analyze`

**Agent:** `ticket-system-reader` | **Auto-invocation:** yes
**Argument:** none (always picks the first ticket from `roadmap.md`)

**Behavior:**
1. Read `.tickets/config.yml`.
2. Read `roadmap.md`, identify the first ticket (position 1).
3. Read the ticket file from `planned/`.
4. Verify all dependencies are in `completed/`. If not, report which ones are blocking.

**7-dimension complexity analysis** (each: Low / Medium / High):

| Dimension | What to assess |
|-----------|---------------|
| Scope | How many files/functions need to change? |
| Criteria | How many acceptance criteria? Are they testable? |
| Cross-cutting | Does it span multiple layers (API, DB, UI)? |
| Dependencies | Is foundational work required first? |
| Risk | Are there unknowns or research needed? |
| Estimated size | Rough lines of code / effort |
| Independence | Can parts be built and tested separately? |

**Verdict:**
- **Ready** (all dimensions ≤ Medium, ≤3 criteria, ≤3 files, single concern): summary, effort estimate, key files, suggested approach. Suggest `/ticket-system-plan`.
- **Needs split** (any dimension High, >3 criteria across concerns, >5 files): explain why it's too large, suggest splitting strategies. Suggest `/ticket-system-split`.

**Readiness checks:**
- Architecture alignment: does the approach follow the project's patterns?
- TDD readiness: can tests be identified before writing code?
- Documentation: is the technical approach detailed enough to plan from?

---

#### `/ticket-system-split`

**Agent:** `ticket-system-editor` | **Auto-invocation:** no (manual)
**Argument:** `[ticket-id]`

**Behavior:**
1. Read `.tickets/config.yml`.
2. Read the target ticket.
3. Propose **2-4 splitting strategies**:
   - By layer (backend, frontend, database)
   - By feature (independent features within scope)
   - Incremental delivery (minimal version first, enhance later)
   - By concern (infrastructure vs business logic)
4. For each strategy: proposed sub-tickets with title, scope, complexity, dependency chain, pros/cons.
5. **Wait for the user's choice.** Do not proceed without approval.
6. Once approved: assign sequential IDs, create in `backlog/`, set dependencies, reject the original with log entry, `git mv` to `rejected/`.
7. Commit: `PREFIX-XXX: Split into sub-tickets`
8. Suggest running `/ticket-system-schedule` on the new sub-tickets.

---

#### `/ticket-system-plan`

**Agent:** `ticket-system-planner` | **Auto-invocation:** no (manual)
**Argument:** `[ticket-id]` (optional — if empty, checks `ongoing/` or takes the first from roadmap)

**Behavior:**

**Phase 1 — Activation (if the ticket is not already in ongoing):**
1. Verify `tickets/ongoing/` is empty.
2. Verify all dependencies are in `completed/`.
3. Create a git worktree:
   ```bash
   git worktree add ../PREFIX-XXX-worktree -b ticket/PREFIX-XXX
   ```
4. Work in the worktree from this point forward.
5. Create `tickets/ongoing/PREFIX-XXX/`.
6. `git mv` the ticket inside.
7. Remove its row from `roadmap.md`.
8. Update frontmatter: `status: ongoing`, `updated: <now>`.
9. Commit activation changes in the worktree.

**Phase 2 — Codebase analysis:**
- Read acceptance criteria, technical approach, context.
- Explore relevant source code, architecture docs, existing tests.
- Understand patterns and conventions in the project.

**Phase 3 — Plan generation:**
- Write `implementation-plan.md` in the ticket directory (format described in section 3.8).
- Write `test-plan.md` in the ticket directory (format described in section 3.8).

**Phase 4 — STOP. Human gate.**
- Present both plans.
- Explain key decisions and tradeoffs.
- **Do not proceed further.** Wait for explicit approval.
- Commit: `PREFIX-XXX: Generate implementation and test plans`

---

#### `/ticket-system-implement`

**Agent:** `ticket-system-coder` | **Auto-invocation:** no (manual)
**Argument:** none (works on the ticket in `ongoing/`)

**Prerequisites to verify:**
1. Exactly one ticket exists in `tickets/ongoing/`.
2. `implementation-plan.md` exists in the ticket's directory.
3. The plan has been approved (check the ticket's Log for a plan generation entry).

**Behavior:**
1. Read `.tickets/config.yml`.
2. Read `implementation-plan.md`.
3. Locate the existing worktree for the active ticket (use `git worktree list` to find `../PREFIX-XXX-worktree`).
4. Work in the worktree directory.
5. For each step in the plan, in order:
   a. **Tests first**: write the TDD tests specified in the step.
   b. **Implement**: write the code to make the tests pass.
   c. **Verify**: run tests (new + existing, no regressions).
   d. **Commit**: `PREFIX-XXX: <step description>`
6. After all steps: update `## Files Modified` and `## Log` in the ticket.
7. Commit ticket updates.

**Error handling:**
- If a test fails and the fix is within the step's scope: fix it.
- If a step is fundamentally blocked: log it and continue with the next independent step.
- If the entire plan is unworkable: STOP and report to the user.

**Completion:** report what was done, suggest running `/ticket-system-verify`.

---

#### `/ticket-system-verify`

**Agent:** `ticket-system-verifier` | **Auto-invocation:** yes
**Argument:** none

**Behavior:**
1. Read `.tickets/config.yml`.
2. Locate the worktree for the active ticket (use `git worktree list` to find `../PREFIX-XXX-worktree`).
3. Work in the worktree directory for all verification.
4. Find the active ticket in `ongoing/`.
5. Read `test-plan.md`.

**Verification checklist:**
- Run the full test suite (not just new tests).
- For each test case in `test-plan.md`: verify it exists and passes.
- Check the coverage map: every acceptance criterion covered by at least one passing test.
- Walk through each acceptance criterion and assess pass/fail with evidence.
- Check for regressions.

**Verdict:**

```
✅ VERDICT: PASS
All N acceptance criteria met.
All M test cases passing.
No regressions detected.
→ Ready for /ticket-system-commit
```

```
❌ VERDICT: FAIL
Criteria passed: X/N
Criteria failed:
  - Criterion K: <reason>
Test failures:
  - TC-M: <error>
Recommendation: [iterate on /ticket-system-implement | go back to /ticket-system-plan]
```

**NEVER attempt to fix anything.** The role is strictly verification.

---

#### `/ticket-system-commit`

**Agent:** `ticket-system-ops` | **Auto-invocation:** no (manual)
**Argument:** none

**Prerequisite:** the ticket's Log contains a `VERDICT: PASS` entry from `/ticket-system-verify`.

**Behavior:**
1. Read `.tickets/config.yml`.
2. Identify the active ticket and its worktree branch (`ticket/PREFIX-XXX`).
3. Ensure the worktree is clean (no uncommitted changes).
4. Switch to the main branch.
5. Merge the worktree branch.
6. Remove the worktree and delete the branch.
7. `git mv tickets/ongoing/PREFIX-XXX tickets/completed/PREFIX-XXX`.
8. Update frontmatter: `status: completed`, `updated: <now>`.
9. Add log entry: `Ticket completed.`
10. Final commit: `PREFIX-XXX: Complete ticket — <title>`
11. Suggest running `/ticket-system-analyze` to evaluate the next ticket.

---

## 5. GENERATION RULES

### 5.1 File Tree to Generate

```
ticket-system/
├── ARCHITECTURE.md                # This spec reformatted as architecture doc
├── install.sh                     # Installation script (see 5.3)
├── init-project.sh                # Project initialization script (see 5.4)
├── agents/
│   ├── ticket-system-reader.md
│   ├── ticket-system-editor.md
│   ├── ticket-system-planner.md
│   ├── ticket-system-coder.md
│   ├── ticket-system-verifier.md
│   └── ticket-system-ops.md
└── skills/
    ├── ticket-system-conventions/
    │   └── SKILL.md
    ├── ticket-system-create/
    │   └── SKILL.md
    ├── ticket-system-schedule/
    │   └── SKILL.md
    ├── ticket-system-analyze/
    │   └── SKILL.md
    ├── ticket-system-split/
    │   └── SKILL.md
    ├── ticket-system-plan/
    │   └── SKILL.md
    ├── ticket-system-implement/
    │   └── SKILL.md
    ├── ticket-system-verify/
    │   └── SKILL.md
    └── ticket-system-commit/
        └── SKILL.md
```

### 5.2 File Formatting Rules

**Each agent** (`agents/ticket-system-*.md`) must contain:
- YAML frontmatter with: `name`, `description`, `model`, `permissionMode`, `tools` (with the fine-grained Bash patterns from section 2.3), `skills: [ticket-system-conventions]`
- A system prompt in the markdown body that:
  - Describes the agent's role in one sentence.
  - Reminds it to read `.tickets/config.yml` first.
  - Lists rules specific to its profile (e.g., "never modify files" for the reader).

**Each skill** (`skills/ticket-system-*/SKILL.md`) must contain:
- YAML frontmatter with: `name`, `description` (< 250 characters, front-loaded), `disable-model-invocation` (per the table in section 2.4), `context: fork`, `agent: <name>`, `argument-hint` if relevant
- A markdown body with the complete command instructions, copied/adapted from section 4.2.

**The `ticket-system-conventions` skill** (`skills/ticket-system-conventions/SKILL.md`) must contain:
- Frontmatter with `user-invocable: false`
- The entire data model from section 3: config, directory structure, ticket format, roadmap format, lifecycle, ID assignment, commit convention, plan artifact formats.

### 5.3 Installation Script

`install.sh` must:

**Step 0 — Prompt for installation directory:**
1. Display a numbered menu:
   ```
   Where would you like to install the ticket system?
     1) Home Claude directory (~/.claude/)  [default]
     2) Current directory Claude config (./.claude/)
     3) Custom path
   Select [1-3]:
   ```
2. Read user input. If empty (user presses Enter), default to option 1.
3. For option 3: prompt for a path. If the entered path is empty, abort with an error.
4. Resolve the chosen path and set `CLAUDE_DIR` to it.
5. If the directory does not exist, ask for confirmation before creating it. Abort if the user declines.
6. Validate the directory is writable. Abort with an error if not.

**Step 1 — Install:**
1. Copy `agents/*.md` to `$CLAUDE_DIR/agents/`
2. Copy `skills/ticket-system-*/` to `$CLAUDE_DIR/skills/`
3. Display the list of available commands
4. Remind to restart Claude Code or run `/reload-plugins`
5. Provide instructions for initializing a new project (or suggest running `init-project.sh`)

### 5.4 Project Initialization Script

`init-project.sh` must:
1. Accept the ticket prefix as an argument (e.g., `bash init-project.sh MYPROJ`)
2. Accept an optional digits argument (default: 3)
3. Create `.tickets/config.yml` with the given prefix
4. Create `.tickets/TEMPLATE.md` with the standard ticket template (using the given prefix as placeholder)
5. Create `tickets/{backlog,planned,ongoing,completed,rejected}/` with `.gitkeep` files
6. Create `tickets/planned/roadmap.md` with an empty table header
7. Display a summary of what was created

### 5.5 Technical Constraints

- Skills use the Claude Code Skills format (not the legacy `.claude/commands/` format).
- All files are in English.
- The `ticket-system-conventions` skill must NOT exceed 500 lines.
- Skill descriptions must be < 250 characters to avoid truncation.
- Use `$ARGUMENTS` in skills to capture user arguments.
- No external dependencies (no npm, no pip). Only bash, git, and standard POSIX commands.

---

## 6. DECISIONS ALREADY MADE (do not revisit)

| # | Decision | Rationale |
|---|----------|-----------|
| D-1 | Artifacts live in `tickets/ongoing/PREFIX-XXX/` | Co-location. When the ticket moves, artifacts move with it. |
| D-2 | Human validation happens only at the `/ticket-system-plan` stage | Once the plan is approved, `/ticket-system-implement` runs autonomously. |
| D-3 | Worktree created at `/ticket-system-plan`, used through `/ticket-system-commit` | All ticket work (plans, implementation, verification) is isolated from main. Only merged on PASS. |
| D-4 | Merge worktree on PASS, stay on branch on FAIL | Clean main branch. Failed work stays isolated. |
| D-5 | System installed at user level (`$CLAUDE_DIR`, defaults to `~/.claude/`), not as a plugin | Need `permissionMode` on agents, which is impossible in plugins. Directory chosen interactively at install time. |
| D-6 | No LangGraph or external tool dependency | The filesystem is the state. Git is the persistence. Slash commands are the nodes. |
| D-7 | `/ticket-system-analyze` always targets the first ticket on the roadmap | No manual selection needed for the happy path. The roadmap is the priority queue. |
| D-8 | 6 agents grouped by permission profile, not 1 agent per command | Permission profile factorization. Fewer files, more consistency. |
| D-9 | Main session in `default` mode, privilege elevation via fork | Security by default. Permissions are in the design, not in user prompts. |
| D-10 | Fine-grained Bash restrictions per agent via wildcard patterns | Least privilege principle. Each agent can only run commands necessary for its mission. |

---

## 7. FUTURE EXTENSIONS (do not implement now)

These items are documented for reference. Do NOT generate them in the current version.

- `/ticket-system-schedule-batch`: schedule multiple tickets at once with topological sorting.
- Makefile with `verify-ticket` target: duplicate checks, max 1 ongoing, status/directory consistency.
- Claude Code Stop hook `verify-ticket-completion.sh`: detect orphaned files after moves, check consistency.
- Pre-commit hooks: linting, YAML/TOML validation.
- Dedicated `ticket-analyzer` agent: standalone sub-agent for complexity analysis (currently embedded in `/ticket-system-analyze`).
- Mermaid state diagram of command transitions.
- `uninstall.sh` script.

---

## 8. VALIDATION CHECKLIST

After generation, verify:

- [ ] Every skill has `context: fork` and `agent: <name>` in its frontmatter.
- [ ] Every agent has `skills: [ticket-system-conventions]` in its frontmatter.
- [ ] Every agent has restrictive Bash patterns (except `ticket-system-coder`).
- [ ] `ticket-system-conventions` has `user-invocable: false`.
- [ ] Manual-only skills have `disable-model-invocation: true`.
- [ ] Auto-invocable skills have `disable-model-invocation: false`.
- [ ] No prefix is hardcoded — everything comes from `.tickets/config.yml`.
- [ ] Read-only agents (`ticket-system-reader`, `ticket-system-verifier`) have `permissionMode: plan`.
- [ ] Autonomous agents (`ticket-system-coder`, `ticket-system-ops`) have `permissionMode: bypassPermissions`.
- [ ] `install.sh` prompts for installation directory and copies everything to `$CLAUDE_DIR`.
- [ ] `install.sh` validates user input (empty input defaults to `~/.claude/`, non-existent paths are created with confirmation, non-writable paths are rejected).
- [ ] `init-project.sh` is executable and creates the full project structure.
- [ ] `/ticket-system-plan` contains an explicit STOP instruction after plan generation.
- [ ] `/ticket-system-verify` contains an instruction to NEVER modify files.
- [ ] `/ticket-system-implement` verifies prerequisites before starting.
- [ ] `/ticket-system-commit` verifies VERDICT: PASS before merging.