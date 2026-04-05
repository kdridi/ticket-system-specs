# SPECIFICATION — Ticket Workflow System for Claude Code

> **This document is a self-contained prompt.** Feed it to Claude Code (Opus 4.6) and it will generate the entire system: agents, skills, install scripts, and documentation.
>
> **Instruction for Claude Code:**
> Read this specification in its entirety. Before generating any files, resolve all `$VARIABLE` references (e.g., `$WEAK_MODEL`, `$MID_MODEL`, `$STRONG_MODEL`, `$MAX_RETRY`) using the defaults from section 0. Then generate ALL described files in the indicated directory structure, ready to be installed into `$CLAUDE_DIR`. Every file must be complete and functional. Do not skip any file. At the end, generate an `install.sh` script that copies everything to the right location, and an `init-project.sh` script that initializes a new project.

---

## 0. CONFIGURATION VARIABLES

> **This is the only section you should customize before generation.** Modify the defaults below to control model selection, retry behavior, and other parameters across the entire generated system.

| Variable | Default | Used in | Description |
|----------|---------|---------|-------------|
| `WEAK_MODEL` | haiku | reader agent (section 2.3) | Model for read-only operations |
| `MID_MODEL` | sonnet | editor, verifier, ops agents (section 2.3) | Model for structured edits and verification |
| `STRONG_MODEL` | opus | planner, coder agents (section 2.3) | Model for deep analysis and implementation |
| `MAX_RETRY` | 3 | implement-verify loop (section 4) | Max verify failures before forced re-plan |

---

## Table of Contents

- [0. Configuration Variables](#0-configuration-variables)
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

- **One active ticket at a time.** Focus over multitasking. This constraint applies per `.tickets/` directory (per project), not per machine or per user. A developer working on multiple projects has independent ticket systems.
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
| `ticket-system-reader` | `$WEAK_MODEL` | plan | `Read`, `Glob`, `Grep`, `Bash(git worktree list)`, `Bash(git diff *)` | `/ticket-system-help`, `/ticket-system-doctor`, `/ticket-system-next` |
| `ticket-system-editor` | `$MID_MODEL` | bypassPermissions | `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash(git mv tickets/*)`, `Bash(git commit -m *)`, `Bash(git status)`, `Bash(git add *)`, `Bash(date *)`, `Bash(mkdir *)` | `/ticket-system-create`, `/ticket-system-schedule` |
| `ticket-system-planner` | `$STRONG_MODEL` | bypassPermissions | `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash(git log *)`, `Bash(git diff *)`, `Bash(git worktree *)`, `Bash(git mv *)`, `Bash(git commit -m *)`, `Bash(git add *)`, `Bash(git status)`, `Bash(mkdir *)`, `Bash(date *)` | `/ticket-system-plan` |
| `ticket-system-coder` | `$STRONG_MODEL` | bypassPermissions | Unrestricted (the plan is already approved) | `/ticket-system-implement`, `/ticket-system-run` |
| `ticket-system-verifier` | `$MID_MODEL` | bypassPermissions | `Read`, `Glob`, `Grep`, `Bash(bash -c *)`, `Bash(npm test *)`, `Bash(pytest *)`, `Bash(make test *)`, `Bash(git diff *)`, `Bash(git worktree list)`, `Bash(git mv tickets/*)`, `Bash(git add *)`, `Bash(git commit -m *)`, `Bash(date *)` | `/ticket-system-verify` |
| `ticket-system-ops` | `$MID_MODEL` | bypassPermissions | `Bash(git merge *)`, `Bash(git worktree *)`, `Bash(git branch *)`, `Bash(git mv tickets/*)`, `Bash(git commit -m *)`, `Bash(git add *)`, `Bash(git checkout *)`, `Bash(git status)`, `Bash(date *)` | `/ticket-system-merge`, `/ticket-system-abort` |

> **Note:** The fine-grained `Bash(git <subcommand> *)` patterns above match plain git commands. When agents use `git -C <path>` for worktree operations, these commands are validated and auto-approved by the PreToolUse hook described in section 2.5.
>
> **Note:** `AskUserQuestion` does not need to be listed in the `Allowed Tools` column. Unlike tools that act on the system (`Read`, `Write`, `Bash`, etc.), asking the user a question requires no permission gate — requesting permission to ask a question would be circular. Claude Code passes it through automatically for all foreground subagents (which includes `context: fork` skills). It is used by human gates in `/ticket-system-schedule` and `/ticket-system-plan` to keep the approval loop inside the forked agent context.

### 2.4 Automatic vs Manual Invocation

Each skill has a `disable-model-invocation` flag. Here is the strategy:

| Skill | `disable-model-invocation` | Reason |
|-------|---------------------------|--------|
| `ticket-system-create` | `false` (Claude can invoke) | Low risk — creates a markdown file in backlog |
| `ticket-system-schedule` | `false` | Safe — human gate before any mutation including splits |
| `ticket-system-plan` | `false` | Has human gate — safe to chain |
| `ticket-system-implement` | `false` | Runs in isolated worktree — safe to chain |
| `ticket-system-verify` | `false` | Read-only + tests — safe |
| `ticket-system-merge` | `false` | Requires completed status — safe to chain |
| `ticket-system-run` | `false` | Chains safe-to-chain skills; plan has its own human gate |
| `ticket-system-abort` | `true` | Destructive — destroys worktree and all uncommitted work |
| `ticket-system-doctor` | `false` | Read-only diagnostics, zero risk |
| `ticket-system-next` | `false` | Read-only state inspection, zero risk |
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
# test_command: "npm test"  # Optional: custom test runner command
```

**`test_command`** is optional. When set, the verifier uses this command instead of auto-detecting the test runner. When omitted, the verifier falls back to auto-detection (`npm test`, `pytest`, `make test`).

**Absolute rule:** all commands, templates, and scripts read this file first. No hardcoded prefixes.

### 3.2 Directory Structure

```
.tickets/
├── config.yml         # Project configuration (prefix, digits, tickets_dir)
└── .pending           # Transient sentinel file — present only during multi-step operations

tickets/
├── backlog/           # Rough ideas, not yet refined
├── planned/           # Refined, ready to activate
│   └── roadmap.yml    # Authoritative execution order
├── ongoing/           # The active ticket (max 1) — stored as subdirectory
│   └── PREFIX-XXX/    # Contains ticket.md + plan artifacts
├── completed/         # Successfully finished tickets
└── rejected/          # Cancelled or invalid tickets
```

**`.tickets/.pending` file format:**

A YAML sentinel file written by mutative commands before starting multi-step operations and deleted on successful completion. Its presence indicates an interrupted transaction.

```yaml
operation: plan          # One of: schedule, plan, merge, abort
ticket: PREFIX-XXX       # The ticket ID being operated on
started: YYYY-MM-DD HH:MM:SS   # When the operation began
description: "Activating ticket — creating worktree and moving to ongoing"
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

Plan artifacts live in `tickets/ongoing/PREFIX-XXX/`. There are two sets of artifacts depending on ticket type:

- **Standard artifacts** (`implementation-plan.md` + `test-plan.md`) — for code tickets (`feature`, `bugfix`, `refactor`, `docs`, `infrastructure`).
- **Research artifacts** (`research-plan.md` + `validation-criteria.md`) — for tickets with `type: research`.

#### Standard Plan Artifacts

Two files for code tickets:

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

#### Research Plan Artifacts

Two files for research tickets (`type: research`):

**`research-plan.md`:**
```markdown
# Research Plan — PREFIX-XXX

## Questions to Answer
1. Question 1
2. Question 2

## Sources to Investigate
- Source category 1
- Source category 2

## Findings Document Structure
- Section 1: ...
- Section 2: ...

## Decision Framework
How the findings should inform a decision.
```

**`validation-criteria.md`:**
```markdown
# Validation Criteria — PREFIX-XXX

## Completeness Criteria
- All research questions answered with evidence
- ...

## Evidence Requirements
- Sources cited for each finding
- ...

## Deliverable Format
Expected structure of findings.md
```

#### Research Output Artifact

The implement phase for research tickets produces a single deliverable:

**`findings.md`:**
```markdown
# Findings — PREFIX-XXX

## Summary
One-paragraph executive summary of the research results.

## Findings by Question
### Q1: <question from research-plan.md>
<answer with evidence>

### Q2: <question from research-plan.md>
<answer with evidence>

## Recommendation
Decision or next step informed by the findings.

## Sources
- Source 1
- Source 2
```

---

## 4. COMMAND PIPELINE

### 4.1 Overview

Pipeline: **create** → **schedule** [HUMAN APPROVAL] → **plan** [HUMAN APPROVAL] → **implement** → **verify** (→ **merge** on PASS, iterate on FAIL). Both approval gates use `AskUserQuestion` inside the forked agent (preserving elevated permissions) and can be bypassed with `yes` or `--yes` in the arguments. Schedule handles splitting internally when tickets are too large — no separate split step. The worktree lifecycle spans from plan through merge. For end-to-end execution, `/ticket-system-run <ticket-id>` chains plan → implement → verify → merge in sequence, stopping on failure at any step (the user can then `/ticket-system-abort` to clean up). Additionally, `/ticket-system-help` is available at any time as a utility command for self-documentation and live status. `/ticket-system-next` inspects the current system state and suggests the most logical next action, reducing the cognitive load of remembering which command to run. `/ticket-system-doctor` is a read-only diagnostic tool that checks the ticket system for consistency issues (status/directory mismatches, orphaned worktrees, stale roadmap entries) and reports findings with suggested fixes. `/ticket-system-abort` is an escape hatch available at any point after plan (when a worktree exists) — it cleanly abandons the active ticket, moves it to `rejected/`, and removes the worktree and branch.

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
3. **Atomicity analysis** (7 dimensions, each rated Low / Medium / High): scope, criteria count, cross-cutting layers, dependencies, risk, estimated size, independence.
4. **Flag decision**: if any dimension is High, >3 criteria span multiple concerns, or >5 files affected, flag as "needs split."
5. **Split proposal** (flagged tickets only): propose 2-4 sub-tickets with title, scope (from acceptance criteria), dependency chain, complexity estimate (small or medium), and rationale. Sub-tickets inherit parent priority and type.

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

**Human gate:** If the user's original arguments contain `yes` or `--yes`, skip this gate and proceed directly to Phase 4. Otherwise, the agent self-evaluates the plan before engaging the user:

1. **Self-assessment:** The agent reviews its own scheduling plan for quality — are the evaluations well-reasoned? Are split proposals balanced? Are rejection reasons solid? Does the dependency ordering make sense?
2. **If confident:** Present the plan and use `AskUserQuestion` to ask: "The plan looks good — approve, or would you like to adjust anything?"
3. **If issues detected:** The agent identifies specific concerns (e.g., "TS-012's split may be too granular", "unsure if TS-015 is still relevant given recent changes"). It builds a list of targeted questions and uses `AskUserQuestion` to collect the user's input on each concern. After incorporating the answers, it revises the plan and loops back to step 1.

**Do not return to the main agent.** The forked agent handles the full question-and-answer loop and the subsequent execution so that elevated permissions remain active throughout.

**Phase 4 — Execute on approval:**
1. Write `.tickets/.pending` with `operation: schedule`, `ticket:` listing all ticket IDs in scope, `started: <now>`, `description: "Scheduling tickets — moving to planned and updating roadmap"`.
2. `git mv` approved tickets from `backlog/` to `planned/`.
3. `git mv` rejected tickets from `backlog/` to `rejected/`.
4. Update frontmatter on each ticket: `status: planned` (or `rejected`), `updated: <now>`.
5. **Execute approved splits:** assign sequential IDs to sub-tickets, create them directly in `planned/` (already evaluated). Update the original ticket: add `## Sub-tickets` listing new IDs, set `status: rejected`, add log entry, `git mv` to `rejected/`. If the user rejected the split, schedule the ticket normally (step 2).
6. Read `roadmap.yml`, insert all scheduled tickets (including sub-tickets) at correct positions (dependency ordering, then priority P0 > P1 > P2). Re-number positions.
7. Add log entry to each ticket.
8. Commit: `PREFIX-XXX, PREFIX-YYY: Schedule tickets` (list all scheduled ticket IDs).
9. Delete `.tickets/.pending`.

#### `/ticket-system-plan`

**Agent:** `ticket-system-planner` | **Auto-invocation:** no (manual) | **Argument:** `[ticket-id]` (optional — if empty, checks `ongoing/` or takes the first from roadmap)

**Behavior:**

**Phase 1 — Activation (if the ticket is not already in ongoing):**
1. Write `.tickets/.pending` with `operation: plan`, `ticket: PREFIX-XXX`, `started: <now>`, `description: "Activating ticket — creating worktree and moving to ongoing"`.
2. Verify `tickets/ongoing/` is empty.
3. Verify all dependencies are in `completed/`.
4. Create a git worktree inside the project:
   ```bash
   mkdir -p .worktrees
   git worktree add .worktrees/PREFIX-XXX-worktree -b ticket/PREFIX-XXX
   ```
5. Work in the worktree from this point forward.
6. Create `tickets/ongoing/PREFIX-XXX/`.
7. `git mv` the ticket inside.
8. Remove its entry from `roadmap.yml`.
9. Update frontmatter: `status: ongoing`, `updated: <now>`.
10. Commit activation changes in the worktree.

**Phase 2 — Codebase analysis:**
- Read acceptance criteria, technical approach, context.
- Explore relevant source code, architecture docs, existing tests.
- Understand patterns and conventions in the project.

**Phase 3 — Plan generation:**
- Check the ticket's frontmatter `type` field.
- **If `type: research`:** Write `research-plan.md` and `validation-criteria.md` in the ticket directory (research artifact formats described in section 3.8).
- **Otherwise (all other types):** Write `implementation-plan.md` and `test-plan.md` in the ticket directory (standard artifact formats described in section 3.8).

**Phase 4 — Human gate.**
- Commit: `PREFIX-XXX: Generate implementation and test plans`
- If the user's original arguments contain `yes` or `--yes`, present a summary and end (the user will invoke `/ticket-system-implement` next).
- Otherwise, the agent self-evaluates before engaging the user:
  1. **Self-assessment:** Review both plans for quality — is the implementation order logical? Are edge cases covered? Does the test plan have gaps? Are there risky steps that need clarification?
  2. **If confident:** Present both plans with key decisions and tradeoffs, then use `AskUserQuestion` to ask: "The plans look solid — approve, or would you like to adjust anything?"
  3. **If issues detected:** The agent identifies specific concerns (e.g., "step 3 may conflict with existing module X", "test coverage is thin on error paths", "unclear whether we should use approach A or B for the parser"). It uses `AskUserQuestion` to collect the user's input on each concern, revises the plans accordingly, amends the commit, and loops back to step 1.

**Do not return to the main agent.** The forked agent handles the full review loop so elevated permissions remain available for plan adjustments.

- Delete `.tickets/.pending`.

#### `/ticket-system-implement`

**Agent:** `ticket-system-coder` | **Auto-invocation:** no (manual) | **Argument:** `<ticket-id>` (e.g., `PROJ-003`)

**Prerequisites to verify:**
1. The ticket exists in `tickets/ongoing/PREFIX-XXX/` inside the worktree at `.worktrees/PREFIX-XXX-worktree`.
2. **Plan artifact check:** If ticket `type` is `research`, `research-plan.md` must exist in the ticket's directory. Otherwise, `implementation-plan.md` must exist.
3. The plan has been approved (check the ticket's Log for a plan generation entry).
4. **Retry limit check:** Count FAIL entries in the ticket's `## Log` section (entries matching "VERDICT: FAIL (attempt"). If count >= `$MAX_RETRY`, STOP and output: "Implementation blocked: `$MAX_RETRY` consecutive verification failures reached. The plan may need revision. Run /ticket-system-plan PREFIX-XXX to regenerate the plan." Do NOT proceed with implementation.

**Behavior:**
1. Read `.tickets/config.yml`.
2. Locate the worktree at `.worktrees/<ticket-id>-worktree` using the provided ticket ID.
3. Read the ticket's frontmatter to determine the ticket `type`.
4. Work in the worktree directory.

**If `type: research` — research implementation flow:**
1. Read `research-plan.md` from `tickets/ongoing/<ticket-id>/` in the worktree.
2. Follow the research plan to produce `findings.md` in `tickets/ongoing/<ticket-id>/`:
   - Answer each question listed in "Questions to Answer" with evidence.
   - Follow the "Findings Document Structure" to organize the document.
   - Cite sources for each finding.
3. Update `## Files Modified` in the ticket (will include `findings.md`). Update `## Log` with a completion entry.
4. Commit: `PREFIX-XXX: Research findings complete`
5. Commit ticket updates.

**Otherwise — standard code implementation flow:**
1. Read `implementation-plan.md` from `tickets/ongoing/<ticket-id>/` in the worktree.
2. For each step in the plan, in order:
   a. **Tests first**: write the TDD tests specified in the step.
   b. **Implement**: write the code to make the tests pass.
   c. **Verify**: run tests (new + existing, no regressions).
   d. **Drift check**: run `git diff --name-only` to get the list of modified files. Compare each modified file against the files listed in `implementation-plan.md` for the current step. For any file not listed in the plan, add a `[DRIFT]` log entry to the ticket's `## Log`: `[DRIFT] Modified <file> — reason: <explanation>`. Continue with the commit regardless (drift is logged, not blocked).
   e. **Commit**: `PREFIX-XXX: <step description>`
3. After all steps: update `## Files Modified` in the ticket with the actual list of all files created or changed during implementation (comparing plan vs reality). Update `## Log` with a completion entry.
4. Commit ticket updates.

**Error handling:** fix in-scope test failures (code flow) or incomplete findings (research flow), log and skip blocked steps, STOP if the entire plan is unworkable. On completion, suggest running `/ticket-system-verify`.

#### `/ticket-system-verify`

**Agent:** `ticket-system-verifier` | **Auto-invocation:** yes | **Argument:** `<ticket-id>` (e.g., `PROJ-003`)

**Behavior:**
1. Read `.tickets/config.yml`.
2. Locate the worktree at `.worktrees/<ticket-id>-worktree` using the provided ticket ID.
3. Work in the worktree directory for all verification.
4. Find the active ticket in `tickets/ongoing/<ticket-id>/`.
5. Read the ticket's frontmatter to determine the ticket `type`.

**If `type: research` — research verification flow:**
1. Read `validation-criteria.md` from the ticket's directory.
2. Read `findings.md` from the ticket's directory.
3. **Verification checklist:** Check `findings.md` against `validation-criteria.md`:
   - **Completeness:** all research questions answered with evidence (per Completeness Criteria).
   - **Evidence:** sources cited for each finding (per Evidence Requirements).
   - **Format:** findings document follows the expected structure (per Deliverable Format).
4. Walk through each acceptance criterion with evidence from `findings.md`.

**Otherwise — standard code verification flow:**
1. Read `test-plan.md`.
2. **Verification checklist:** First, read `test_command` from `.tickets/config.yml`. If `test_command` is set, run the test suite via `bash -c "<test_command>"` in the worktree directory. If `test_command` is not set, fall back to auto-detection: try `npm test`, `pytest`, or `make test` based on what is available in the project. Then verify each test case in `test-plan.md` exists and passes. Check the coverage map (every criterion covered). Walk through each acceptance criterion with evidence. Check for regressions. Check for `[DRIFT]` entries in the ticket's `## Log` section. If any `[DRIFT]` entries are present, list them prominently in the verification report and flag for user attention. Drift entries do not automatically cause a FAIL verdict but must be reported.

**Verdict:** Either `VERDICT: PASS` (all criteria met, all tests/checks passing, no regressions) or `VERDICT: FAIL` (list failed criteria and test/check failures, recommend next action).

**On VERDICT: PASS — complete the ticket (in the worktree):**
1. `git mv tickets/ongoing/PREFIX-XXX tickets/completed/PREFIX-XXX`
2. Update frontmatter: `status: completed`, `updated: <now>`.
3. Add log entry: `VERDICT: PASS — Ticket completed.`
4. Commit: `PREFIX-XXX: Complete ticket — <title>`

**On VERDICT: FAIL — record attempt and leave in `ongoing/`:**
1. Count existing FAIL entries in the ticket's `## Log` section (entries matching "VERDICT: FAIL (attempt").
2. Increment the count to get the current attempt number N.
3. Append a log entry: `YYYY-MM-DD HH:MM:SS: VERDICT: FAIL (attempt N/$MAX_RETRY) — <summary of failures>`.
4. Update frontmatter `updated` timestamp (via `date` command).
5. Commit in the worktree: `PREFIX-XXX: Verify FAIL (attempt N/$MAX_RETRY)`.
6. The ticket stays in `ongoing/`.

**NEVER attempt to fix code or modify findings.** The role is verification and ticket completion, not code/findings modification.

#### `/ticket-system-merge`

**Agent:** `ticket-system-ops` | **Auto-invocation:** no (manual) | **Argument:** `<ticket-id>` (e.g., `PROJ-003`)

**Prerequisite:** the ticket is in `tickets/completed/` in the worktree (placed there by `/ticket-system-verify` on VERDICT: PASS).

**Behavior:**
1. Read `.tickets/config.yml`.
2. Write `.tickets/.pending` with `operation: merge`, `ticket: PREFIX-XXX`, `started: <now>`, `description: "Merging ticket branch into main and cleaning up worktree"`.
3. Locate the worktree at `.worktrees/<ticket-id>-worktree` using the provided ticket ID.
4. Verify the worktree is clean (no uncommitted changes).
5. Verify the ticket is in `tickets/completed/` in the worktree (not in `ongoing/`).
6. Switch to the main branch.
7. Merge the worktree branch (`git merge ticket/PREFIX-XXX`).
8. If merge conflict: report the conflict and **STOP** — let the user resolve.
9. Remove the worktree and delete the branch.
10. Delete `.tickets/.pending`.
11. Suggest checking the roadmap for the next ticket to plan.

#### `/ticket-system-run`

**Agent:** `ticket-system-coder` | **Auto-invocation:** no (manual) | **Argument:** `<ticket-id>` (e.g., `PROJ-003`)

This is an orchestration command that chains four sub-skills in sequence: plan → implement → verify → merge. It stops immediately if any step fails, letting the user inspect and either fix the issue or `/ticket-system-abort`.

**Behavior:**
1. Read `.tickets/config.yml` to get the prefix and configuration.
2. Validate the ticket-id argument is provided. The ticket must exist in `tickets/planned/` (not yet activated) or `tickets/ongoing/` (already activated by a prior `/ticket-system-plan` that was interrupted). If `$ARGUMENTS` contains `yes` or `--yes`, note it for forwarding to the plan step.
3. **Step 1 — Plan:** Invoke `/ticket-system-plan <ticket-id>` via the Skill tool (forward `--yes` if present).
   - After return, verify success: check that `.worktrees/<ticket-id>-worktree` exists and contains the expected plan artifacts in `tickets/ongoing/<ticket-id>/`. Read the ticket's `type` from frontmatter: if `type: research`, check for `research-plan.md` and `validation-criteria.md`; otherwise check for `implementation-plan.md` and `test-plan.md`.
   - If verification fails → report "STOPPED at plan step" with the sub-skill's output and suggest `/ticket-system-abort`. **STOP.**
4. **Step 2 — Implement:** Invoke `/ticket-system-implement <ticket-id>` via the Skill tool.
   - After return, verify success: for research tickets, check that `findings.md` exists in `tickets/ongoing/<ticket-id>/`; for code tickets, check for implementation commits in the worktree beyond the plan commits.
   - If the sub-skill was blocked by the retry limit (`$MAX_RETRY` consecutive failures) → report "STOPPED at implement step — retry limit reached. The plan may need revision. Run /ticket-system-plan PREFIX-XXX to regenerate the plan." **STOP.**
   - If the sub-skill reported failure or verification fails → report "STOPPED at implement step" and suggest `/ticket-system-abort`. **STOP.**
5. **Step 3 — Verify:** Invoke `/ticket-system-verify <ticket-id>` via the Skill tool.
   - After return, check for `VERDICT: PASS` in the output, or verify `tickets/completed/<ticket-id>/` exists in the worktree.
   - If VERDICT: FAIL → report "STOPPED at verify step — VERDICT: FAIL" with failure details. Suggest re-running `/ticket-system-implement` to fix issues, then `/ticket-system-verify`, or `/ticket-system-abort` to abandon. **STOP.**
6. **Step 4 — Merge:** Invoke `/ticket-system-merge <ticket-id>` via the Skill tool.
   - After return, verify the worktree has been removed and the branch deleted.
   - If merge conflict → report "STOPPED at merge step — merge conflict" and let the user resolve. **STOP.**
7. On full success, report: "Ticket <ticket-id> completed: planned, implemented, verified, and merged."

**Note on human gates:** The plan sub-skill contains its own `AskUserQuestion` human gate. The user will still be prompted for plan approval unless `--yes` was forwarded. This preserves the human-in-the-loop design.

#### `/ticket-system-abort`

**Agent:** `ticket-system-ops` | **Auto-invocation:** no (manual) | **Argument:** none (finds the active ticket automatically)

**Behavior:**
1. Read `.tickets/config.yml`.
2. Detect the active ticket: scan `tickets/ongoing/` on main first. If empty, list worktrees with `git worktree list` and check each for a ticket in `tickets/ongoing/`.
3. If no active ticket found, report "Nothing to abort" and exit.
4. **Confirmation gate:** use `AskUserQuestion` to confirm: "This will destroy the worktree and all uncommitted changes. Abort PREFIX-XXX?" Bypassable with `yes` or `--yes` in arguments.
5. Write `.tickets/.pending` with `operation: abort`, `ticket: PREFIX-XXX`, `started: <now>`, `description: "Aborting ticket — removing worktree and moving to rejected"`. This overwrites any pre-existing `.pending` from the interrupted operation.
6. Copy the ticket file from the worktree to `tickets/rejected/PREFIX-XXX.md` on main.
7. Update frontmatter: `status: rejected`, `updated: <now>` (via `date` command).
8. Add log entry: `Ticket aborted by user.`
9. Remove worktree: `git worktree remove .worktrees/PREFIX-XXX-worktree --force`.
10. Delete branch: `git branch -D ticket/PREFIX-XXX`.
11. Commit on main: `PREFIX-XXX: Abort ticket — <title>`.
12. Delete `.tickets/.pending`.

#### `/ticket-system-next`

**Agent:** `ticket-system-reader` | **Auto-invocation:** yes | **Argument:** none

**Behavior:**
1. Read `.tickets/config.yml` (prefix, digits, tickets_dir).
2. **Detection logic** — evaluate checks in priority order, stop at the first match:

   **Check 1 — Incomplete transaction:** If `.tickets/.pending` exists, suggest `/ticket-system-doctor`.

   **Check 2 — Active worktree exists:** Run `git worktree list` and look for a worktree matching `.worktrees/*-worktree`. If found, extract the ticket ID from the worktree directory name and inspect its state:
   - **(a)** If the ticket is in `tickets/completed/` inside the worktree, suggest `/ticket-system-merge PREFIX-XXX`.
   - **(b)** If `git -C <worktree> diff` shows uncommitted changes (code modified since last commit), suggest `/ticket-system-verify PREFIX-XXX`.
   - **(c)** If `tickets/ongoing/PREFIX-XXX/implementation-plan.md` exists in the worktree, suggest `/ticket-system-implement PREFIX-XXX`.
   - **(d)** Otherwise (ticket is ongoing but no plan yet), suggest `/ticket-system-plan PREFIX-XXX`.

   **Check 3 — Planned tickets in roadmap:** Read `tickets/planned/roadmap.yml`. If it contains entries, read the first ticket (position 1) and suggest `/ticket-system-plan PREFIX-XXX`.

   **Check 4 — Backlog tickets exist:** Scan `tickets/backlog/`. If tickets are found, list them and suggest `/ticket-system-schedule PREFIX-XXX [PREFIX-YYY ...]`.

   **Check 5 — Empty system:** No tickets anywhere. Suggest `/ticket-system-create`.

3. **Output format:**
```
Status: <what was detected — e.g., "Ticket PREFIX-XXX has been implemented in worktree, awaiting verification.">
Next action: <exact command to run — e.g., "/ticket-system-verify PREFIX-XXX">
```

> **Note:** This command does not auto-invoke the suggested command. It only reports the detection and recommendation. The user decides whether to run it.

#### `/ticket-system-help`

**Agent:** `ticket-system-reader` | **Auto-invocation:** yes | **Argument:** `[verb]` (optional command name)

**Behavior (no argument):**
1. Read `.tickets/config.yml`.
2. Print all ticket-system commands with one-line descriptions.
3. Scan `tickets/` subdirectories (backlog, planned, ongoing, completed, rejected), count tickets in each.
4. Print a live status section showing actionable next steps ordered by urgency (e.g., ongoing ticket highlighted first, backlog items suggest scheduling).

**Behavior (with verb argument):**
1. If the verb matches a known command (create, schedule, plan, implement, verify, merge, run, abort, next, doctor, help), read the corresponding `ticket-system-<verb>/SKILL.md` and print detailed documentation derived from it: what it does, which agent runs it, arguments, options (e.g., `--yes` bypass), and format/template details.
2. If the verb is unknown, print an error listing all available verbs.

#### `/ticket-system-doctor`

**Agent:** `ticket-system-reader` | **Auto-invocation:** yes | **Argument:** none

**Behavior:**
1. Read `.tickets/config.yml` (prefix, digits, tickets_dir).
2. **Incomplete transaction check:** Check if `.tickets/.pending` exists. If present, read the YAML contents (`operation`, `ticket`, `started`, `description`). Report as `[ISSUE]` with the operation name, ticket ID, start time, and description. Suggest recovery based on operation type:
   - `schedule`: "Re-run `/ticket-system-schedule` to retry, or manually complete the scheduling."
   - `plan`: "Re-run `/ticket-system-plan` to retry, or `/ticket-system-abort` to clean up."
   - `merge`: "Re-run `/ticket-system-merge` to retry, or manually complete the merge."
   - `abort`: "Re-run `/ticket-system-abort` to retry cleanup."
3. **Status/directory mismatch check:** Scan all ticket files across all subdirectories (`backlog/`, `planned/`, `ongoing/`, `completed/`, `rejected/`). For each ticket, read frontmatter `status` and verify it matches the parent directory name. Report mismatches.
4. **Orphaned worktree check:** Run `git worktree list` and parse the output. For each worktree whose basename matches `*-worktree`, check that a corresponding ticket exists in `tickets/ongoing/` (either on main or inside that worktree). Report orphaned worktrees (worktree exists but no matching ongoing ticket).
5. **Stale roadmap entries check:** Read `tickets/planned/roadmap.yml`. For each ticket ID referenced in the roadmap, verify that a corresponding ticket file exists in `tickets/planned/`. Report stale entries (referenced in roadmap but missing from `planned/`).
6. **Multiple ongoing tickets check:** Count the number of ticket subdirectories in `tickets/ongoing/`. Report if more than 1 is found (the system enforces max 1 active ticket).
7. **Report findings** as a structured checklist:

```
TICKET SYSTEM DIAGNOSTIC REPORT

[OK]   No incomplete transactions
[ISSUE] Incomplete transaction — operation "plan" on PREFIX-XXX started at 2026-04-05 02:50:01
        Description: Activating ticket — creating worktree and moving to ongoing
        Fix: Re-run /ticket-system-plan to retry, or /ticket-system-abort to clean up

[OK]   Status/directory consistency — all N tickets match
[ISSUE] Status/directory mismatch — PREFIX-XXX has status "planned" but is in completed/
        Fix: Edit PREFIX-XXX frontmatter to set status: completed
        Or:  git mv tickets/completed/PREFIX-XXX tickets/planned/PREFIX-XXX.md

[OK]   No orphaned worktrees found
[ISSUE] Orphaned worktree — .worktrees/PREFIX-YYY-worktree exists but no ticket in ongoing/
        Fix: git worktree remove .worktrees/PREFIX-YYY-worktree

[OK]   Roadmap entries are consistent
[ISSUE] Stale roadmap entry — PREFIX-ZZZ referenced in roadmap but not in planned/
        Fix: Remove PREFIX-ZZZ entry from tickets/planned/roadmap.yml

[OK]   At most 1 ticket in ongoing/
[ISSUE] Multiple ongoing tickets — found N tickets in ongoing/: PREFIX-AAA, PREFIX-BBB
        Fix: Move extra tickets back to planned/ and re-add to roadmap

Summary: N checks passed, M issues found
```

**The command does NOT auto-fix any issues.** It only reports findings and suggests fix commands. The user decides whether and how to act.

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
    ├── ticket-system-plan/
    │   └── SKILL.md
    ├── ticket-system-implement/
    │   └── SKILL.md
    ├── ticket-system-verify/
    │   └── SKILL.md
    ├── ticket-system-merge/
    │   └── SKILL.md
    ├── ticket-system-run/
    │   └── SKILL.md
    ├── ticket-system-abort/
    │   └── SKILL.md
    ├── ticket-system-doctor/
    │   └── SKILL.md
    └── ticket-system-next/
        └── SKILL.md
```

### 5.2 File Formatting Rules

**Each agent** (`agents/ticket-system-*.md`) must contain:
- YAML frontmatter with: `name`, `description`, `model`, `permissionMode`, `tools` (with the dedicated tools and fine-grained Bash patterns from section 2.3 — **omit the `tools` field entirely** for `ticket-system-coder` since "Unrestricted" means no tool restrictions; including an empty or placeholder `tools` list would block all tool access), `skills: [ticket-system-conventions]`
- A system prompt in the markdown body that:
  - Describes the agent's role in one sentence.
  - Reminds it to read `.tickets/config.yml` first.
  - Lists rules specific to its profile (e.g., "never modify files" for the reader).

**Each skill** (`skills/ticket-system-*/SKILL.md`) must contain:
- YAML frontmatter with: `name`, `description` (< 250 characters, front-loaded), `disable-model-invocation` (per the table in section 2.4), `context: fork`, `agent: <name>`, `argument-hint` if relevant
- A markdown body with the complete command instructions, copied/adapted from section 4.2.

**The `ticket-system-conventions` skill** (`skills/ticket-system-conventions/SKILL.md`) must contain:
- Frontmatter with `user-invocable: false`
- Immediately after the frontmatter closing `---`, before any markdown heading, a line-count comment: `<!-- Lines: N/500 -->` where N is the total line count of the file. This gives generators and reviewers immediate visibility into budget usage.
- The entire data model from section 3: config, directory structure, ticket format, roadmap format, lifecycle, ID assignment, commit convention, plan artifact formats (standard and research variants), and the research output artifact (`findings.md`). The conventions skill must document the full research pipeline variant: plan produces `research-plan.md` + `validation-criteria.md`, implement produces `findings.md`, verify checks findings against validation criteria.

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
3. Create `.tickets/config.yml` with the given prefix — include a commented-out `# test_command: "npm test"` line with an inline comment explaining it is optional
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
| D-2 | Human validation at `/ticket-system-schedule` and `/ticket-system-plan` stages | Schedule gate covers batch decisions (splits, rejections, ordering). Plan gate covers implementation strategy. Once the plan is approved, `/ticket-system-implement` runs autonomously. |
| D-3 | Worktree created inside `.worktrees/` at `/ticket-system-plan`, used through `/ticket-system-merge` | All ticket work is isolated from main. `tickets/ongoing/` on main is always empty. Worktrees live inside the project (`.worktrees/`, gitignored) so Claude Code's dedicated tools (`Read`, `Write`, `Edit`, `Glob`, `Grep`) can access them without permission prompts. |
| D-4 | Verify completes ticket on PASS, merge lands the branch | On PASS, verifier moves ticket to `completed/` in the worktree. Merge just integrates to main. On FAIL, ticket stays in `ongoing/` in the worktree. |
| D-5 | System installed at user level (`$CLAUDE_DIR`, defaults to `~/.claude/`), not as a plugin | Need `permissionMode` on agents, which is impossible in plugins. Directory chosen interactively at install time. |
| D-6 | No LangGraph or external tool dependency | The filesystem is the state. Git is the persistence. Slash commands are the nodes. |
| D-7 | `/ticket-system-schedule` accepts one or more ticket IDs with integrated complexity analysis | Eliminates the separate analyze step. Schedule validates, evaluates relevance, and performs 7-dimension atomicity analysis before presenting a unified plan with human gate. |
| D-8 | 6 agents grouped by permission profile, not 1 agent per command | Permission profile factorization. Fewer files, more consistency. |
| D-9 | Main session in `default` mode, privilege elevation via fork | Security by default. Permissions are in the design, not in user prompts. |
| D-10 | Fine-grained Bash patterns + PreToolUse hook for worktree validation | Least privilege: patterns restrict plain git commands per agent, hook validates and auto-approves `git worktree`, `git -C`, and `mkdir` commands targeting valid ticket worktrees (section 2.5). |
| D-11 | `/ticket-system-schedule` absorbs split functionality | Eliminates `/ticket-system-split` as a standalone command. Schedule evaluates atomicity (7 dimensions), proposes sub-tickets for oversized tickets, and executes splits on approval — all behind the existing human gate. Simplifies the pipeline to 6 commands: create, schedule, plan, implement, verify, merge. |
| D-12 | Human gates use `AskUserQuestion` inside forks, not STOP | Approval gates stay inside the forked agent context so elevated permissions remain active through execution. Avoids the main agent inheriting mutation work without the right permission profile. The agent self-evaluates before engaging the user: if confident, asks for simple approval; if issues detected, asks targeted questions, revises, and re-evaluates. Gates are bypassable with `yes` or `--yes` in arguments for power-user workflows. |
| D-13 | `ticket-system-conventions` has a 500-line hard limit with a documented split strategy | Context efficiency: oversized skills degrade Claude Code performance. The 500-line limit is enforced by `validate.sh`. When the skill exceeds 400 lines (80% threshold), extract heavy reference-only sections into `ticket-system-conventions-extended` (`user-invocable: false`, added only to planner and verifier agents). **Extractable sections:** plan artifact formats (`implementation-plan.md`, `test-plan.md`, `research-plan.md`, and `validation-criteria.md` templates), coverage map format. **Must-stay sections:** config, directory structure, ticket format, roadmap format, lifecycle, ID assignment, commit convention, worktree convention, tool usage rules. |

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
- [ ] `ticket-system-plan/`
- [ ] `ticket-system-implement/`
- [ ] `ticket-system-verify/`
- [ ] `ticket-system-merge/`
- [ ] `ticket-system-run/`
- [ ] `ticket-system-abort/`
- [ ] `ticket-system-doctor/`
- [ ] `ticket-system-next/`

### Frontmatter and permissions

- [ ] Every skill has `context: fork` and `agent: <name>` in its frontmatter.
- [ ] Every agent has `skills: [ticket-system-conventions]` in its frontmatter.
- [ ] Every agent uses dedicated tools (`Read`, `Write`, `Edit`, `Grep`, `Glob`) for file operations — no `Bash(cat/grep/find/head/tail/wc/sed)`.
- [ ] Every agent has restrictive Bash patterns for git/date/mkdir only (except `ticket-system-coder`).
- [ ] `ticket-system-coder` has **no `tools` field** in its frontmatter (unrestricted access — an empty or placeholder `tools` list would block all tool access).
- [ ] `ticket-system-conventions` has `user-invocable: false`.
- [ ] Only `ticket-system-abort` has `disable-model-invocation: true` (destructive).
- [ ] All other skills have `disable-model-invocation: false`.
- [ ] No prefix is hardcoded — everything comes from `.tickets/config.yml`.
- [ ] `ticket-system-verifier` agent includes `Bash(bash -c *)` in its allowed tools (for configurable test command execution).
- [ ] `init-project.sh` generates a `.tickets/config.yml` that includes a commented-out `# test_command: "npm test"` line.
- [ ] Read-only agent (`ticket-system-reader`) has `permissionMode: plan`.
- [ ] All other agents (`ticket-system-editor`, `ticket-system-planner`, `ticket-system-coder`, `ticket-system-verifier`, `ticket-system-ops`) have `permissionMode: bypassPermissions`.
- [ ] `install.sh` prompts for installation directory and copies everything to `$CLAUDE_DIR`.
- [ ] `install.sh` validates user input (empty input defaults to `~/.claude/`, non-existent paths are created with confirmation, non-writable paths are rejected).
- [ ] `init-project.sh` is executable and creates the full project structure.
- [ ] `init-project.sh` generates `TEMPLATE.md` with pipe-separated enum options (e.g., `priority: P0 | P1 | P2`), not single default values.
- [ ] `/ticket-system-schedule` contains a human gate (via `AskUserQuestion`) with self-evaluation inside the fork — agent stays forked through Phase 4 execution.
- [ ] `/ticket-system-plan` contains a human gate (via `AskUserQuestion`) with self-evaluation after plan generation — agent stays forked.
- [ ] `/ticket-system-verify` contains an instruction to NEVER modify code, and moves ticket to `completed/` on PASS.
- [ ] `/ticket-system-implement` verifies prerequisites before starting.
- [ ] `/ticket-system-implement` checks FAIL count in the ticket log against `$MAX_RETRY` before starting. If count >= `$MAX_RETRY`, refuses to run and outputs a re-plan message.
- [ ] `/ticket-system-implement` includes a drift detection step (step 5d): compares modified files against `implementation-plan.md` and logs `[DRIFT]` entries for unplanned modifications.
- [ ] `/ticket-system-implement` updates the "Files Modified" section of the ticket after implementation with the actual list of files changed.
- [ ] `/ticket-system-verify` checks for `[DRIFT]` entries in the ticket log and reports them prominently in the verification report.
- [ ] `/ticket-system-verify` appends attempt count to FAIL log entries (format: "VERDICT: FAIL (attempt N/$MAX_RETRY)").
- [ ] The forced re-plan message in `/ticket-system-implement` includes "The plan may need revision. Run /ticket-system-plan PREFIX-XXX to regenerate the plan."
- [ ] `/ticket-system-run` handles retry-limit-blocked implement step and stops with a re-plan suggestion.
- [ ] `/ticket-system-merge` verifies ticket is in `completed/` before merging.
- [ ] `/ticket-system-abort` has `disable-model-invocation: true`.
- [ ] `/ticket-system-abort` uses `AskUserQuestion` confirmation gate (destructive action), bypassable with `yes`/`--yes`.
- [ ] `/ticket-system-abort` uses the `ticket-system-ops` agent.
- [ ] `/ticket-system-run` uses the `ticket-system-coder` agent (needs unrestricted tool access for Skill invocation).
- [ ] `/ticket-system-run` has `disable-model-invocation: false`.
- [ ] `/ticket-system-run` verifies filesystem state after each sub-skill invocation before proceeding.
- [ ] `/ticket-system-run` stops and reports on failure at any step.
- [ ] `/ticket-system-run` forwards `--yes` to the plan sub-skill when present.
- [ ] `/ticket-system-implement` checks ticket `type` and reads `research-plan.md` for research tickets instead of `implementation-plan.md`.
- [ ] `/ticket-system-implement` produces `findings.md` for research tickets instead of code changes.
- [ ] `/ticket-system-verify` checks ticket `type` and reads `validation-criteria.md` for research tickets instead of `test-plan.md`.
- [ ] `/ticket-system-verify` checks `findings.md` against `validation-criteria.md` for research tickets (completeness, evidence, format).
- [ ] `/ticket-system-run` accepts research artifacts (`research-plan.md` + `validation-criteria.md`) as valid plan output for research tickets.
- [ ] `/ticket-system-run` checks for `findings.md` existence (not implementation commits) for research tickets at the implement verification step.
- [ ] The PASS/FAIL verdict and completion flow are identical for both code and research ticket types.
- [ ] `/ticket-system-next` uses the `ticket-system-reader` agent (read-only state inspection).
- [ ] `/ticket-system-next` has `disable-model-invocation: false` (safe, read-only).
- [ ] `/ticket-system-doctor` uses the `ticket-system-reader` agent (read-only diagnostics).
- [ ] `/ticket-system-doctor` has `disable-model-invocation: false` (safe, read-only).
- [ ] `/ticket-system-doctor` performs NO file modifications — reports and suggests only.
- [ ] `/ticket-system-doctor` checks `.tickets/.pending` as its FIRST diagnostic (step 2, immediately after reading config).
- [ ] All mutative commands (`/ticket-system-schedule`, `/ticket-system-plan`, `/ticket-system-merge`, `/ticket-system-abort`) write `.tickets/.pending` before starting multi-step work.
- [ ] All mutative commands delete `.tickets/.pending` on successful completion.
- [ ] `ticket-system-conventions` SKILL.md does not exceed 500 lines.
- [ ] `ticket-system-conventions` SKILL.md has a `<!-- Lines: N/500 -->` comment with correct count.

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
