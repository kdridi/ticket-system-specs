# SPECIFICATION — Ticket Workflow System for Claude Code

> **This document is a self-contained prompt.** Feed it to Claude Code (Opus 4.6) and it will generate the entire system: agents, skills, install scripts, and documentation.
>
> **Instruction for Claude Code:**
> Read this specification in its entirety. Then generate ALL described files in the indicated directory structure, ready to be installed into `$CLAUDE_DIR`. Every file must be complete and functional. Do not skip any file. At the end, generate an `install.sh` script that copies everything to the right location, and an `init-project.sh` script that initializes a new project.

## Table of Contents

- [1. Vision and Philosophy](#1-vision-and-philosophy)
  - [1.1 What We're Building](#11-what-were-building)
  - [1.2 Core Principles](#12-core-principles)
  - [1.3 Installation Directory Variable](#13-installation-directory-variable)
  - [1.4 Permission Philosophy](#14-permission-philosophy)
- [2. Technical Architecture](#2-technical-architecture)
  - [2.1 Two Complementary Layers: Skills + Agents](#21-two-complementary-layers-skills--agents)
  - [2.2 Shared Skill: ticket-system-conventions](#22-shared-skill-ticket-system-conventions)
  - [2.3 Agent Profiles (6 agents, 3 permission levels)](#23-agent-profiles-6-agents-3-permission-levels)
  - [2.4 Automatic vs Manual Invocation](#24-automatic-vs-manual-invocation)
  - [2.5 PreToolUse Hook: Worktree Path Validation](#25-pretooluse-hook-worktree-path-validation)
- [3. Data Model](#3-data-model)
  - [3.1 Project Configuration](#31-project-configuration)
  - [3.2 Directory Structure](#32-directory-structure)
  - [3.3 Ticket Format](#33-ticket-format)
  - [3.4 Roadmap Format](#34-roadmap-format)
  - [3.5 Lifecycle (6 phases)](#35-lifecycle-6-phases)
  - [3.6 ID Assignment](#36-id-assignment)
  - [3.7 Commit Convention](#37-commit-convention)
  - [3.8 Plan Artifacts](#38-plan-artifacts)
- [4. Command Pipeline](#4-command-pipeline)
  - [4.1 Overview](#41-overview)
  - [4.2 Detailed Command Specifications](#42-detailed-command-specifications)
- [5. Generation Rules](#5-generation-rules)
  - [5.1 File Tree to Generate](#51-file-tree-to-generate)
  - [5.2 File Formatting Rules](#52-file-formatting-rules)
  - [5.3 Installation Script](#53-installation-script)
  - [5.4 Project Initialization Script](#54-project-initialization-script)
  - [5.5 Technical Constraints](#55-technical-constraints)
  - [5.6 Hook Script Generation Rules](#56-hook-script-generation-rules)
- [6. Decisions Already Made](#6-decisions-already-made-do-not-revisit)
- [7. Future Extensions](#7-future-extensions-do-not-implement-now)
- [8. Validation Checklist](#8-validation-checklist)
  - [Structural completeness](#structural-completeness--all-required-files-present)
  - [Frontmatter and permissions](#frontmatter-and-permissions)
  - [Hooks](#hooks)

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

### 2.3 Agent Profiles (6 agents, 2 permission levels)

| Agent | Model | permissionMode | Allowed Tools | Used by |
|-------|-------|---------------|---------------|---------|
| `ticket-system-reader` | haiku | plan | `Read`, `Glob`, `Grep` | `/ticket-system-help` |
| `ticket-system-editor` | sonnet | bypassPermissions | `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash(git mv *)`, `Bash(git commit *)`, `Bash(git status)`, `Bash(git add *)`, `Bash(date *)`, `Bash(mkdir *)` | `/ticket-system-create`, `/ticket-system-schedule`, `/ticket-system-split` |
| `ticket-system-planner` | opus | bypassPermissions | `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash(git log *)`, `Bash(git diff *)`, `Bash(git worktree *)`, `Bash(git mv *)`, `Bash(git commit *)`, `Bash(git add *)`, `Bash(git status)`, `Bash(mkdir *)`, `Bash(date *)` | `/ticket-system-plan` |
| `ticket-system-coder` | opus | bypassPermissions | Unrestricted (the plan is already approved) | `/ticket-system-implement` |
| `ticket-system-verifier` | sonnet | bypassPermissions | `Read`, `Glob`, `Grep`, `Bash(npm test *)`, `Bash(pytest *)`, `Bash(make test *)`, `Bash(git diff *)`, `Bash(git worktree list)`, `Bash(git mv *)`, `Bash(git add *)`, `Bash(git commit *)`, `Bash(date *)` | `/ticket-system-verify` |
| `ticket-system-ops` | sonnet | bypassPermissions | `Bash(git merge *)`, `Bash(git worktree *)`, `Bash(git branch *)`, `Bash(git mv *)`, `Bash(git commit *)`, `Bash(git add *)`, `Bash(git checkout *)`, `Bash(git status)` | `/ticket-system-merge` |

> **Note:** The fine-grained `Bash(git <subcommand> *)` patterns above match plain git commands. When agents use `git -C <path>` for worktree operations, these commands are validated and auto-approved by the PreToolUse hook described in section 2.5.

### 2.4 Automatic vs Manual Invocation

Each skill has a `disable-model-invocation` flag. Here is the strategy:

| Skill | `disable-model-invocation` | Reason |
|-------|---------------------------|--------|
| `ticket-system-create` | `false` (Claude can invoke) | Low risk — creates a markdown file in backlog |
| `ticket-system-schedule` | `false` | Safe — human gate before any mutation including splits |
| `ticket-system-plan` | `true` | Structural action — ticket activation + deep analysis |
| `ticket-system-implement` | `true` | Full autonomy, bypass permissions — never automatic |
| `ticket-system-verify` | `false` | Read-only + tests — safe |
| `ticket-system-merge` | `true` | Irreversible merge — always explicit |
| `ticket-system-help` | `false` (Claude can invoke) | Read-only, zero risk |

### 2.5 PreToolUse Hook: Worktree Path Validation

**Problem:** Fine-grained `Bash(git <subcommand> *)` patterns (section 2.3) match plain git commands but do NOT match `git -C <path> <subcommand> ...` or `git worktree add <path> ...` because Claude Code's pattern matching is positional and literal. Since agents must use `git -C <path>` when operating in worktrees and `git worktree add/remove` to manage them, these operations would trigger permission prompts. Similarly, `mkdir` commands targeting worktree paths need auto-approval.

**Solution:** A `PreToolUse` hook on the `Bash` tool that intercepts `git worktree`, `git -C`, and `mkdir` commands, validates the target path, and auto-approves commands targeting a valid ticket worktree.

**Validation logic:**

**For `mkdir` commands:**
1. Check if any path argument contains a `*-worktree` component.
2. If yes → allow. If no → fall through to normal permissions.

**For `git worktree` commands:**
1. `git worktree list` → allow (read-only).
2. `git worktree add <path>` → extract the path, validate basename matches `*-worktree`. Allow if valid, deny if not.
3. `git worktree remove/prune` → allow (cleanup operations).

**For `git -C <path>` commands:**
1. Only match if the command starts with `git -C` (anchored match to avoid false positives on `-C` inside commit messages or other quoted arguments).
2. Extract the `-C <path>` argument. Resolve to absolute path (prepend `$CWD` if relative). Validate the basename matches `*-worktree`.
3. If valid → `permissionDecision: "allow"` with reason. If invalid → `permissionDecision: "deny"` with reason.

**Hook file:** `$CLAUDE_DIR/hooks/validate-git-worktree.sh`

**Configuration:** Injected into `$CLAUDE_DIR/settings.json` by `install.sh`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_DIR/hooks/validate-git-worktree.sh"
          }
        ]
      }
    ]
  }
}
```

Plain `git` commands (without `-C` or `worktree`) and `mkdir` commands not targeting worktrees are unaffected — they fall through to the existing fine-grained patterns in section 2.3.

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
│   └── roadmap.yml    # Authoritative execution order
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

`tickets/planned/roadmap.yml`:

```yaml
# roadmap.yml
tickets:
  - position: 1
    id: PREFIX-005
    title: "Title"
    size: medium
    priority: P0
    dependencies: []
    rationale: "Reason"
  - position: 2
    id: PREFIX-008
    title: "Title"
    size: medium
    priority: P0
    dependencies: [PREFIX-005]
    rationale: "Depends on auth"
```

**Insertion ordering rules:**
1. **Dependency ordering:** a ticket must appear after all of its dependencies in the list.
2. **Priority sorting:** within the same dependency tier, sort by priority P0 > P1 > P2.
3. **Position numbering:** positions are sequential integers starting at 1. After any insertion or removal, re-number all positions.

**When a ticket is activated:** remove its entry from the `tickets` list and re-number the remaining positions.

### 3.5 Lifecycle (6 phases)

```
backlog → planned → ongoing → completed
                             → rejected
```

- **Create** → `tickets/backlog/PREFIX-XXX.md`
- **Schedule** → validate, refine, `git mv` to `planned/`, insert into `roadmap.yml`
- **Activate** → verify `ongoing/` is empty, verify dependencies, create git worktree in `.worktrees/`, create `tickets/ongoing/PREFIX-XXX/` in worktree, move ticket inside
- **Work** → all code changes scoped to the ticket (in worktree)
- **Complete** → on VERDICT: PASS, verifier moves ticket to `completed/` in the worktree
- **Reject** → document reason, move to `rejected/` in the worktree
- **Merge** → worktree branch merged to main, worktree removed

Note: `tickets/ongoing/` on main is always empty. Tickets are moved to `ongoing/` only inside worktrees.

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

Pipeline: **create** → **schedule** (→ **split** if too large) → **plan** [HUMAN APPROVAL] → **implement** → **verify** (→ **merge** on PASS, iterate on FAIL). The worktree lifecycle spans from plan through merge. Additionally, `/ticket-system-help` is available at any time as a utility command for self-documentation and live status.

### 4.2 Detailed Command Specifications

#### `/ticket-system-create`

**Agent:** `ticket-system-editor` | **Auto-invocation:** yes | **Argument:** `[title or description]`

**Behavior:**
1. Read `.tickets/config.yml` (prefix, digits, tickets_dir).
2. Scan all files across all `tickets/` subdirectories to find the highest existing ID number.
3. Assign the next ID: increment by 1, zero-pad.
4. If `.tickets/TEMPLATE.md` exists, use it as the base. Otherwise use the standard ticket format from conventions.
5. Fill in: `id`, `created`, `updated` with current timestamp, `status: backlog`, `title` from arguments.
6. Save to `tickets/backlog/PREFIX-XXX.md`.
7. Add log entry: `Ticket created.`
8. Commit: `PREFIX-XXX: Create ticket — <title>`

**Input classification:** If the argument is clear (recognizable title + type/priority cues), use the fast path above. If it is vague (fewer than 8 words, no type/priority keywords) or absent, enter dialogue mode.

**Dialogue mode:** Ask targeted clarifying questions (1-2 at a time) to surface title, type, priority, objective, and acceptance criteria. Maintain a structured draft in-session only — no files written. Cap at 3 rounds. Present the full draft for user review; the user may confirm, adjust fields, or request another iteration. Only upon confirmation, execute steps 1-8 above.

#### `/ticket-system-schedule`

**Agent:** `ticket-system-editor` | **Auto-invocation:** yes | **Argument:** `[ticket-id(s) or description]`

Accepts one or more ticket IDs (e.g., `/ticket-system-schedule TS-011 TS-012 TS-013`) OR a description to fuzzy-match a single ticket in backlog (backward-compatible).

**Phase 1 — Collect and resolve:**
1. Read `.tickets/config.yml`.
2. Parse arguments: extract ticket IDs or fuzzy-match description against backlog (confirm with user).
3. For each ticket ID: read the ticket from `backlog/`, collect its dependencies.
4. Recursively resolve dependencies: if a dependency is also in backlog, include it in the batch.
5. Build a dependency graph of all tickets in scope.

**Phase 2 — Evaluate each ticket:**
For each ticket in the batch:
1. **Validate**: check frontmatter completeness, acceptance criteria quality, technical approach detail. If gaps exist, refine them. Show the user what changed.
2. **Relevance check**: scan `completed/` and current codebase — is this ticket still needed? If obsolete, propose rejection with reason.
3. **Atomicity analysis** (7-dimension complexity assessment, each rated Low / Medium / High):
   - Scope (files/functions)
   - Criteria (count, testability)
   - Cross-cutting (layers)
   - Dependencies (foundational work)
   - Risk (unknowns)
   - Estimated size (effort)
   - Independence (separate testability)
4. **Flag decision**: if any dimension is High, more than 3 acceptance criteria span multiple concerns, or more than 5 files are affected, flag the ticket as "needs split."
5. **Split proposal** (for flagged tickets only): propose 2-4 sub-tickets. Each sub-ticket includes:
   - Title and scope derived from the original ticket's acceptance criteria.
   - Dependency chain between sub-tickets (ordering constraints).
   - Individual complexity estimate (each must be small or medium).
   - Rationale for the split boundary.
   Sub-tickets inherit the parent ticket's priority and type.

**Phase 3 — Present unified scheduling plan:**
```
SCHEDULING PLAN — N tickets evaluated

READY TO SCHEDULE:
  1. PREFIX-XXX "title" — complexity, priority, deps → roadmap position

NEEDS SPLIT:
  2. PREFIX-YYY "title" — High on [dimensions]
     Proposed sub-tickets:
     a. PREFIX-AAA "sub-title A" — small, deps: none
     b. PREFIX-BBB "sub-title B" — small, deps: PREFIX-AAA
     Accept split? [accept / adjust / reject]

PROPOSE REJECTION:
  3. PREFIX-ZZZ "title" — reason

Dependencies resolved: ordering rationale
```

**STOP. Wait for user approval.** The user may approve, adjust, or reject individual entries.

**Phase 4 — Execute on approval:**
1. `git mv` approved tickets from `backlog/` to `planned/`.
2. `git mv` rejected tickets from `backlog/` to `rejected/`.
3. Update frontmatter on each ticket: `status: planned` (or `rejected`), `updated: <now>`.
4. **Execute approved splits:** for each ticket where the user accepted the split:
   a. Assign sequential IDs to sub-tickets (using the standard ID assignment rule).
   b. Create sub-tickets directly in `planned/` (not backlog — they have already been evaluated).
   c. Update the original ticket: add a `## Sub-tickets` section listing the new IDs, set `status: rejected`, add a log entry explaining the split, `git mv` to `rejected/`.
   d. Insert sub-tickets into `roadmap.yml` with correct dependency ordering.
   If the user rejected the split, the ticket schedules normally (moved to `planned/` as in step 1).
5. Read `roadmap.yml`, insert all scheduled tickets (including sub-tickets from splits) at correct positions (respect dependency ordering, then sort by priority P0 > P1 > P2 within the same dependency tier). Re-number positions.
6. Add log entry to each ticket.
7. Commit: `PREFIX-XXX, PREFIX-YYY: Schedule tickets` (list all scheduled ticket IDs).

#### `/ticket-system-plan`

**Agent:** `ticket-system-planner` | **Auto-invocation:** no (manual) | **Argument:** `[ticket-id]` (optional — if empty, checks `ongoing/` or takes the first from roadmap)

**Behavior:**

**Phase 1 — Activation (if the ticket is not already in ongoing):**
1. Verify `tickets/ongoing/` is empty.
2. Verify all dependencies are in `completed/`.
3. Create a git worktree inside the project:
   ```bash
   mkdir -p .worktrees
   git worktree add .worktrees/PREFIX-XXX-worktree -b ticket/PREFIX-XXX
   ```
4. Work in the worktree from this point forward.
5. Create `tickets/ongoing/PREFIX-XXX/`.
6. `git mv` the ticket inside.
7. Remove its entry from `roadmap.yml`.
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

#### `/ticket-system-implement`

**Agent:** `ticket-system-coder` | **Auto-invocation:** no (manual) | **Argument:** `<ticket-id>` (e.g., `PROJ-003`)

**Prerequisites to verify:**
1. The ticket exists in `tickets/ongoing/PREFIX-XXX/` inside the worktree at `.worktrees/PREFIX-XXX-worktree`.
2. `implementation-plan.md` exists in the ticket's directory.
3. The plan has been approved (check the ticket's Log for a plan generation entry).

**Behavior:**
1. Read `.tickets/config.yml`.
2. Locate the worktree at `.worktrees/<ticket-id>-worktree` using the provided ticket ID.
3. Read `implementation-plan.md` from `tickets/ongoing/<ticket-id>/` in the worktree.
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

#### `/ticket-system-verify`

**Agent:** `ticket-system-verifier` | **Auto-invocation:** yes | **Argument:** `<ticket-id>` (e.g., `PROJ-003`)

**Behavior:**
1. Read `.tickets/config.yml`.
2. Locate the worktree at `.worktrees/<ticket-id>-worktree` using the provided ticket ID.
3. Work in the worktree directory for all verification.
4. Find the active ticket in `tickets/ongoing/<ticket-id>/`.
5. Read `test-plan.md`.

**Verification checklist:**
- Run the full test suite (not just new tests).
- For each test case in `test-plan.md`: verify it exists and passes.
- Check the coverage map: every acceptance criterion covered by at least one passing test.
- Walk through each acceptance criterion and assess pass/fail with evidence.
- Check for regressions.

**Verdict:** Either `VERDICT: PASS` (all criteria met, all tests passing, no regressions) or `VERDICT: FAIL` (list failed criteria and test failures, recommend next action).

**On VERDICT: PASS — complete the ticket (in the worktree):**
1. `git mv tickets/ongoing/PREFIX-XXX tickets/completed/PREFIX-XXX`
2. Update frontmatter: `status: completed`, `updated: <now>`.
3. Add log entry: `VERDICT: PASS — Ticket completed.`
4. Commit: `PREFIX-XXX: Complete ticket — <title>`

**On VERDICT: FAIL** — do nothing. The ticket stays in `ongoing/`.

**NEVER attempt to fix code.** The role is verification and ticket completion, not code modification.

#### `/ticket-system-merge`

**Agent:** `ticket-system-ops` | **Auto-invocation:** no (manual) | **Argument:** `<ticket-id>` (e.g., `PROJ-003`)

**Prerequisite:** the ticket is in `tickets/completed/` in the worktree (placed there by `/ticket-system-verify` on VERDICT: PASS).

**Behavior:**
1. Read `.tickets/config.yml`.
2. Locate the worktree at `.worktrees/<ticket-id>-worktree` using the provided ticket ID.
3. Verify the worktree is clean (no uncommitted changes).
4. Verify the ticket is in `tickets/completed/` in the worktree (not in `ongoing/`).
5. Switch to the main branch.
6. Merge the worktree branch (`git merge ticket/PREFIX-XXX`).
7. If merge conflict: report the conflict and **STOP** — let the user resolve.
8. Remove the worktree and delete the branch.
9. Suggest checking the roadmap for the next ticket to plan.

#### `/ticket-system-help`

**Agent:** `ticket-system-reader` | **Auto-invocation:** yes | **Argument:** `[verb]` (optional command name)

**Behavior (no argument):**
1. Read `.tickets/config.yml`.
2. Print all ticket-system commands with one-line descriptions.
3. Scan `tickets/` subdirectories (backlog, planned, ongoing, completed, rejected), count tickets in each.
4. Print a live status section showing actionable next steps ordered by urgency (e.g., ongoing ticket highlighted first, backlog items suggest scheduling).

**Behavior (with verb argument):**
1. If the verb matches a known command (create, schedule, split, plan, implement, verify, merge, help), print detailed documentation: what it does, which agent runs it, arguments, and format/template details.
2. If the verb is unknown, print an error listing all available verbs.

---

## 5. GENERATION RULES

### 5.1 File Tree to Generate

```
ticket-system/
├── ARCHITECTURE.md                # This spec reformatted as architecture doc
├── install.sh                     # Installation script (see 5.3)
├── init-project.sh                # Project initialization script (see 5.4)
├── hooks/
│   └── validate-git-worktree.sh   # PreToolUse hook (see 2.5, 5.6)
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
    ├── ticket-system-help/
    │   └── SKILL.md
    ├── ticket-system-schedule/
    │   └── SKILL.md
    ├── ticket-system-split/
    │   └── SKILL.md
    ├── ticket-system-plan/
    │   └── SKILL.md
    ├── ticket-system-implement/
    │   └── SKILL.md
    ├── ticket-system-verify/
    │   └── SKILL.md
    └── ticket-system-merge/
        └── SKILL.md
```

### 5.2 File Formatting Rules

**Each agent** (`agents/ticket-system-*.md`) must contain:
- YAML frontmatter with: `name`, `description`, `model`, `permissionMode`, `tools` (with the dedicated tools and fine-grained Bash patterns from section 2.3), `skills: [ticket-system-conventions]`
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

**Step 1 — Install hooks:**
1. Create `$CLAUDE_DIR/hooks/` if it doesn't exist.
2. Copy `hooks/validate-git-worktree.sh` to `$CLAUDE_DIR/hooks/`. Make it executable (`chmod +x`).
3. If `$CLAUDE_DIR/settings.json` doesn't exist, create it with the hook configuration from section 2.5 (replacing `$CLAUDE_DIR` with the resolved path).
4. If it exists but has no `hooks.PreToolUse` key, inject the hook configuration.
5. If it already has `PreToolUse` entries, append the hook entry and warn the user to verify the merged result.

**Step 2 — Install agents and skills:**
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
4. Create `.tickets/TEMPLATE.md` using the exact ticket format from section 3.3 — enum fields must show all valid options with pipe separators (e.g., `priority: P0 | P1 | P2`, not a single default value)
5. Create `tickets/{backlog,planned,ongoing,completed,rejected}/` with `.gitkeep` files
6. Create `tickets/planned/roadmap.yml` with `tickets: []` (an empty YAML list)
7. Ensure `.worktrees/` is in the project's `.gitignore`: check with `grep -qx '.worktrees/' .gitignore 2>/dev/null` first — only append if not already present, create `.gitignore` if it does not exist
8. Display a summary of what was created

### 5.5 Technical Constraints

- Skills use the Claude Code Skills format (not the legacy `.claude/commands/` format).
- All files are in English.
- The `ticket-system-conventions` skill must NOT exceed 500 lines.
- Skill descriptions must be < 250 characters to avoid truncation.
- Use `$ARGUMENTS` in skills to capture user arguments.
- No external dependencies (no npm, no pip). Only bash, git, and standard POSIX commands.
- Agents MUST use Claude Code's dedicated tools (`Read`, `Write`, `Edit`, `Grep`, `Glob`) for all file operations. NEVER use `Bash(cat)`, `Bash(grep)`, `Bash(sed)`, `Bash(head)`, `Bash(tail)`, `Bash(find)`, or `Bash(wc)` for tasks these tools handle. Reserve Bash exclusively for git commands, `date`, `mkdir`, and operations that genuinely require shell execution.
- Agents MUST use `git -C <path>` instead of `cd <path> && git` to avoid compound commands. These `git -C` commands are validated and auto-approved by the PreToolUse hook (section 2.5), which verifies the path targets a valid ticket worktree.
- Agents MUST use simple quoted multiline strings for `git commit` messages, NOT heredoc/cat syntax. Use `git commit -m "line1\nline2"` or `git commit -m "` followed by a closing `"` on a later line. Never use `git commit -m "$(cat <<'EOF' ... EOF)"`.

### 5.6 Hook Script Generation Rules

`hooks/validate-git-worktree.sh` must:

- Start with `#!/bin/bash`.
- Read JSON from stdin (the Claude Code hook input). Use `jq` if available on `$PATH`, otherwise fall back to `grep -o`/`sed` for extracting JSON fields.
- Extract `tool_input.command` and `cwd` from the input.
- Handle three command categories in order:

**1. `mkdir` commands:**
- If the command starts with `mkdir`, check if any path argument contains a `*-worktree` component (e.g., `.worktrees/TS-011-worktree/tickets/ongoing/TS-011`).
- If yes → allow with reason. If no match → exit 0 (fall through).

**2. `git worktree` commands:**
- `git worktree list` → allow (read-only).
- `git worktree add <path>` → validate basename of `<path>` matches `*-worktree`. Allow if valid, deny if not.
- `git worktree remove/prune` → allow (cleanup).
- Other `git worktree` subcommands → exit 0 (fall through).

**3. `git -C <path>` commands:**
- If the command does not start with `git -C` (anchored match: `^git\s+-C\s+`), exit 0 (fall through). This avoids false matches on `-C` appearing inside quoted arguments such as commit messages.
- Extract the `-C <path>` argument using bash regex: `[[ "$CMD" =~ git[[:space:]]+-C[[:space:]]+([^[:space:]]+) ]]`.
- Resolve the path: if relative, prepend `$CWD`. Extract the basename.
- Validate the basename matches `*-worktree`. If valid → allow with reason. If not → deny with reason.
- Note: the hook does NOT check for `tickets/ongoing/<id>/` existence — the planner needs to run git commands in the worktree before that directory is created.

**Common rules:**
- On success: output `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"<reason>"}}`.
- On denial: output `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"<reason>"}}`.
- On any internal error (parse failure, missing fields): exit 0 with no output — falls through to the normal permission system.
- MUST NOT hardcode any ticket prefix — the hook validates structural conventions only (basename `*-worktree`).

---

## 6. DECISIONS ALREADY MADE (do not revisit)

| # | Decision | Rationale |
|---|----------|-----------|
| D-1 | Artifacts live in `tickets/ongoing/PREFIX-XXX/` | Co-location. When the ticket moves, artifacts move with it. |
| D-2 | Human validation happens only at the `/ticket-system-plan` stage | Once the plan is approved, `/ticket-system-implement` runs autonomously. |
| D-3 | Worktree created inside `.worktrees/` at `/ticket-system-plan`, used through `/ticket-system-merge` | All ticket work is isolated from main. `tickets/ongoing/` on main is always empty. Worktrees live inside the project (`.worktrees/`, gitignored) so Claude Code's dedicated tools (`Read`, `Write`, `Edit`, `Glob`, `Grep`) can access them without permission prompts. |
| D-4 | Verify completes ticket on PASS, merge lands the branch | On PASS, verifier moves ticket to `completed/` in the worktree. Merge just integrates to main. On FAIL, ticket stays in `ongoing/` in the worktree. |
| D-5 | System installed at user level (`$CLAUDE_DIR`, defaults to `~/.claude/`), not as a plugin | Need `permissionMode` on agents, which is impossible in plugins. Directory chosen interactively at install time. |
| D-6 | No LangGraph or external tool dependency | The filesystem is the state. Git is the persistence. Slash commands are the nodes. |
| D-7 | `/ticket-system-schedule` accepts one or more ticket IDs with integrated complexity analysis | Eliminates the separate analyze step. Schedule validates, evaluates relevance, and performs 7-dimension atomicity analysis before presenting a unified plan with human gate. |
| D-8 | 6 agents grouped by permission profile, not 1 agent per command | Permission profile factorization. Fewer files, more consistency. |
| D-9 | Main session in `default` mode, privilege elevation via fork | Security by default. Permissions are in the design, not in user prompts. |
| D-10 | Fine-grained Bash patterns + PreToolUse hook for worktree validation | Least privilege: patterns restrict plain git commands per agent, hook validates and auto-approves `git worktree`, `git -C`, and `mkdir` commands targeting valid ticket worktrees (section 2.5). |

---

## 7. FUTURE EXTENSIONS (do not implement now)

These items are documented for reference. Do NOT generate them in the current version.

- Makefile with `verify-ticket` target: duplicate checks, max 1 ongoing, status/directory consistency.
- Claude Code Stop hook `verify-ticket-completion.sh`: detect orphaned files after moves, check consistency.
- Pre-commit hooks: linting, YAML/TOML validation.
- Mermaid state diagram of command transitions.
- `uninstall.sh` script.

---

## 8. VALIDATION CHECKLIST

After generation, verify:

### Structural completeness — all required files present

**Scripts:**
- [ ] `ARCHITECTURE.md`
- [ ] `install.sh`
- [ ] `init-project.sh`

**Hooks** (`hooks/`):
- [ ] `validate-git-worktree.sh`

**Agents** (`agents/`):
- [ ] `ticket-system-reader.md`
- [ ] `ticket-system-editor.md`
- [ ] `ticket-system-planner.md`
- [ ] `ticket-system-coder.md`
- [ ] `ticket-system-verifier.md`
- [ ] `ticket-system-ops.md`

**Skills** (`skills/`), each containing `SKILL.md`:
- [ ] `ticket-system-conventions/`
- [ ] `ticket-system-create/`
- [ ] `ticket-system-help/`
- [ ] `ticket-system-schedule/`
- [ ] `ticket-system-split/`
- [ ] `ticket-system-plan/`
- [ ] `ticket-system-implement/`
- [ ] `ticket-system-verify/`
- [ ] `ticket-system-merge/`

### Frontmatter and permissions

- [ ] Every skill has `context: fork` and `agent: <name>` in its frontmatter.
- [ ] Every agent has `skills: [ticket-system-conventions]` in its frontmatter.
- [ ] Every agent uses dedicated tools (`Read`, `Write`, `Edit`, `Grep`, `Glob`) for file operations — no `Bash(cat/grep/find/head/tail/wc/sed)`.
- [ ] Every agent has restrictive Bash patterns for git/date/mkdir only (except `ticket-system-coder`).
- [ ] `ticket-system-conventions` has `user-invocable: false`.
- [ ] Manual-only skills have `disable-model-invocation: true`.
- [ ] Auto-invocable skills have `disable-model-invocation: false`.
- [ ] No prefix is hardcoded — everything comes from `.tickets/config.yml`.
- [ ] Read-only agent (`ticket-system-reader`) has `permissionMode: plan`.
- [ ] All other agents (`ticket-system-editor`, `ticket-system-planner`, `ticket-system-coder`, `ticket-system-verifier`, `ticket-system-ops`) have `permissionMode: bypassPermissions`.
- [ ] `install.sh` prompts for installation directory and copies everything to `$CLAUDE_DIR`.
- [ ] `install.sh` validates user input (empty input defaults to `~/.claude/`, non-existent paths are created with confirmation, non-writable paths are rejected).
- [ ] `init-project.sh` is executable and creates the full project structure.
- [ ] `init-project.sh` generates `TEMPLATE.md` with pipe-separated enum options (e.g., `priority: P0 | P1 | P2`), not single default values.
- [ ] `/ticket-system-plan` contains an explicit STOP instruction after plan generation.
- [ ] `/ticket-system-verify` contains an instruction to NEVER modify code, and moves ticket to `completed/` on PASS.
- [ ] `/ticket-system-implement` verifies prerequisites before starting.
- [ ] `/ticket-system-merge` verifies ticket is in `completed/` before merging.

### Hooks

- [ ] `hooks/validate-git-worktree.sh` exists and is executable.
- [ ] The hook reads `tool_input.command` and `cwd` from stdin JSON.
- [ ] The hook handles `mkdir` commands: allows when path contains `*-worktree`, falls through otherwise.
- [ ] The hook handles `git worktree list` (allow), `git worktree add` (validate `*-worktree` basename), `git worktree remove/prune` (allow).
- [ ] The hook handles `git -C <path>`: extracts path, resolves to absolute, validates basename matches `*-worktree`.
- [ ] The hook does NOT check `tickets/ongoing/<id>/` existence (worktree may be freshly created).
- [ ] The hook outputs `permissionDecision: "allow"` for valid paths, `"deny"` for invalid.
- [ ] The hook works without `jq` (fallback to `grep`/`sed` parsing).
- [ ] The hook does not hardcode any ticket prefix.
- [ ] `install.sh` copies the hook to `$CLAUDE_DIR/hooks/` and merges PreToolUse config into `$CLAUDE_DIR/settings.json`.
- [ ] `init-project.sh` adds `.worktrees/` to `.gitignore` only if not already present (idempotent).
