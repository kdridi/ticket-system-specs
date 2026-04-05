# Implementation Plan — TS-019

## Overview
Tighten overly broad `Bash(git commit *)` and `Bash(git mv *)` wildcard patterns in the section 2.3 agent profiles table of `specs.md`. This restricts what git operations each agent can perform without breaking any documented command behavior.

## Current State (section 2.3 of specs.md, lines 120-127)

| Agent | Current `git commit` | Current `git mv` |
|-------|---------------------|-------------------|
| editor | `Bash(git commit *)` | `Bash(git mv *)` |
| planner | `Bash(git commit *)` | `Bash(git mv *)` |
| verifier | `Bash(git commit *)` | `Bash(git mv *)` |
| ops | `Bash(git commit *)` | `Bash(git mv *)` |

## Target State

| Agent | New `git commit` | New `git mv` | Rationale |
|-------|------------------|--------------|-----------|
| editor | `Bash(git commit -m *)` | `Bash(git mv tickets/*)` | Only creates new commits; only moves ticket files |
| planner | `Bash(git commit -m *)` | `Bash(git mv *)` (unchanged) | Only creates new commits; needs broader mv for ticket activation (planned -> ongoing subdirectory) |
| verifier | `Bash(git commit -m *)` | `Bash(git mv tickets/*)` | Only creates new commits; only moves ticket directories (ongoing -> completed) |
| ops | `Bash(git commit -m *)` | `Bash(git mv tickets/*)` | Only creates new commits; only moves ticket files (abort: ongoing -> rejected) |

## Steps

### Step 1: Tighten editor agent patterns
- **Files:** `specs.md` (line 123)
- **What:** Replace `Bash(git commit *)` with `Bash(git commit -m *)` and `Bash(git mv *)` with `Bash(git mv tickets/*)` in the editor row.
- **Tests first:** N/A (spec-only change; verified by reading the line)
- **Done when:** The editor row in section 2.3 shows the tightened patterns.

### Step 2: Tighten planner agent commit pattern
- **Files:** `specs.md` (line 124)
- **What:** Replace `Bash(git commit *)` with `Bash(git commit -m *)` in the planner row. Keep `Bash(git mv *)` unchanged -- planner needs to move tickets into `ongoing/PREFIX-XXX/` subdirectories which requires broader path access.
- **Tests first:** N/A (spec-only change)
- **Done when:** The planner row shows `Bash(git commit -m *)` but retains `Bash(git mv *)`.

### Step 3: Tighten verifier agent patterns
- **Files:** `specs.md` (line 126)
- **What:** Replace `Bash(git commit *)` with `Bash(git commit -m *)` and `Bash(git mv *)` with `Bash(git mv tickets/*)` in the verifier row.
- **Tests first:** N/A (spec-only change)
- **Done when:** The verifier row shows both tightened patterns.

### Step 4: Tighten ops agent patterns
- **Files:** `specs.md` (line 127)
- **What:** Replace `Bash(git commit *)` with `Bash(git commit -m *)` and `Bash(git mv *)` with `Bash(git mv tickets/*)` in the ops row.
- **Tests first:** N/A (spec-only change)
- **Done when:** The ops row shows both tightened patterns.

### Step 5: Review reader agent (no changes needed)
- **Files:** `specs.md` (line 122)
- **What:** Verify the reader agent has no `git commit` or `git mv` patterns (it does not). The reader currently has `Bash(git worktree list)` and `Bash(git diff *)`, which are appropriate for its read-only role (help, next, doctor). No changes needed.
- **Tests first:** N/A
- **Done when:** Confirmed reader has no overly broad patterns.

### Step 6: Cross-validate all patterns against command behaviors
- **Files:** `specs.md` (sections 2.3 and 4.2)
- **What:** Walk through every command in section 4.2 and verify the tightened patterns do not break any documented behavior:
  - **editor** (`create`, `schedule`): both use `git commit -m "..."` (never amend), both `git mv` only ticket files in `tickets/`.
  - **planner** (`plan`): uses `git commit -m "..."` (never amend), uses `git mv` to move from `planned/` to `ongoing/PREFIX-XXX/`.
  - **verifier** (`verify`): uses `git commit -m "..."` (never amend), uses `git mv tickets/ongoing/PREFIX-XXX tickets/completed/PREFIX-XXX`.
  - **ops** (`merge`, `abort`): merge does `git merge` (no commit needed beyond merge commit), abort uses `git commit -m "..."` on main and moves ticket to `rejected/` which is under `tickets/`.
- **Tests first:** N/A
- **Done when:** All commands verified compatible with tightened patterns.

### Step 7: Update ticket and commit
- **Files:** `tickets/ongoing/TS-019/ticket.md`
- **What:** Update `## Files Modified`, `## Decisions`, and `## Log` sections. Mark acceptance criteria as checked.
- **Tests first:** N/A
- **Done when:** Ticket reflects all changes made.

## Risk Notes
- The `git mv tickets/*` pattern must match paths like `git mv tickets/ongoing/TS-019 tickets/completed/TS-019` (moving directories). The wildcard after `tickets/` covers any subpath, so this works.
- The planner needs `git mv *` (not `git mv tickets/*`) because the planner's `git mv` operates inside the worktree where the path is relative: `git -C <worktree> mv tickets/planned/PREFIX-XXX.md tickets/ongoing/PREFIX-XXX/ticket.md`. However, since `git -C` commands go through the PreToolUse hook (not the agent's Bash patterns), the planner's `Bash(git mv *)` pattern only applies to plain `git mv` commands. The broader pattern is retained for safety in case the planner needs to run `git mv` without `-C`.
- The ops agent's abort command copies the ticket from the worktree to main, then commits. The `git mv` in ops is used within `git -C` context (worktree), which is handled by the hook. The `Bash(git mv tickets/*)` pattern covers any plain `git mv` on main targeting ticket paths.
