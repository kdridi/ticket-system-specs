# Implementation Plan — TS-013

## Overview
Add a `/ticket-system-abort` command that cleanly abandons an ongoing ticket: moves it to `rejected/`, removes the git worktree and branch, and commits on main. This requires changes to `specs.md` across multiple sections and a corresponding update to `CLAUDE.md`.

## Steps

### Step 1: Add `/ticket-system-abort` to section 2.4 (Automatic vs Manual Invocation table)
- **Files:** `specs.md`
- **What:** Add a row to the table in section 2.4 for `ticket-system-abort` with `disable-model-invocation: true` and reason "Destructive — destroys worktree and all uncommitted work."
- **Tests first:** N/A (spec file, not code)
- **Done when:** The table has 8 rows (7 commands + abort), abort is marked `true`.

### Step 2: Update section 2.3 (Agent Profiles) — add abort to ops agent's "Used by" column
- **Files:** `specs.md`
- **What:** In the `ticket-system-ops` row of the agent profiles table, change `Used by` from `/ticket-system-merge` to `/ticket-system-merge`, `/ticket-system-abort`. Also add `Bash(git worktree remove *)` to the ops agent's allowed tools if not already covered by `Bash(git worktree *)`, and add `Bash(git branch -D *)` pattern. Verify that the existing `Bash(git worktree *)` and `Bash(git branch *)` patterns already cover `git worktree remove` and `git branch -D` respectively — if yes, no change to tools is needed.
- **Tests first:** N/A
- **Done when:** The ops agent row references both `/ticket-system-merge` and `/ticket-system-abort`.

### Step 3: Add `/ticket-system-abort` command specification in section 4.2
- **Files:** `specs.md`
- **What:** Add a new subsection after `/ticket-system-merge` (and before `/ticket-system-help`) with the full command specification:
  - Agent: `ticket-system-ops`
  - Auto-invocation: no (manual)
  - Argument: none (finds the active ticket automatically)
  - Behavior:
    1. Read `.tickets/config.yml`.
    2. Detect the active ticket: scan `tickets/ongoing/` on main first. If empty, list worktrees with `git worktree list` and check each for a ticket in `tickets/ongoing/`.
    3. If no active ticket found, report "Nothing to abort" and exit.
    4. Confirmation gate: use `AskUserQuestion` to confirm ("This will destroy the worktree and all uncommitted changes. Abort PREFIX-XXX?"). Bypassable with `yes`/`--yes`.
    5. Copy the ticket file from the worktree to `tickets/rejected/PREFIX-XXX.md` on main.
    6. Update frontmatter: `status: rejected`, `updated: <now>`.
    7. Add log entry: "Ticket aborted by user."
    8. Remove worktree: `git worktree remove .worktrees/PREFIX-XXX-worktree --force`.
    9. Delete branch: `git branch -D ticket/PREFIX-XXX`.
    10. Commit on main: `PREFIX-XXX: Abort ticket — <title>`.
- **Tests first:** N/A
- **Done when:** Section 4.2 has 8 command specifications.

### Step 4: Update section 4.1 (Overview) to mention abort
- **Files:** `specs.md`
- **What:** Update the pipeline overview to mention that `/ticket-system-abort` is available as an escape hatch at any point after plan (when a worktree exists). Keep the main pipeline description unchanged; add a sentence about abort being orthogonal to the main flow.
- **Tests first:** N/A
- **Done when:** Section 4.1 references abort as a side-exit command.

### Step 5: Add `ticket-system-abort/` to section 5.1 (File Tree to Generate)
- **Files:** `specs.md`
- **What:** Add `ticket-system-abort/` with `SKILL.md` to the skills directory in the file tree listing.
- **Tests first:** N/A
- **Done when:** The file tree shows 9 skill directories (conventions + 8 commands).

### Step 6: Update section 8 (Validation Checklist)
- **Files:** `specs.md`
- **What:** Add `ticket-system-abort/` to the structural completeness skills list. Add validation items:
  - `ticket-system-abort` has `disable-model-invocation: true`.
  - `ticket-system-abort` uses `AskUserQuestion` confirmation gate (destructive action).
  - `ticket-system-abort` uses the `ticket-system-ops` agent.
- **Tests first:** N/A
- **Done when:** Checklist includes abort-specific validations.

### Step 7: Update CLAUDE.md to reflect the new command count
- **Files:** `CLAUDE.md`
- **What:** Update the expected output description from "8 skill directories" to "9 skill directories" (conventions + 8 slash commands). Update the "7 slash commands" reference to "8 slash commands". Add abort to any command lists in the validation section if relevant. Update the help command description in section 4.2 to mention abort as a recognized verb.
- **Tests first:** N/A
- **Done when:** CLAUDE.md references for skill/command counts are consistent with specs.md.

### Step 8: Update `/ticket-system-help` to recognize the abort verb
- **Files:** `specs.md`
- **What:** In the help command specification (section 4.2), update the list of recognized verbs from "create, schedule, plan, implement, verify, merge, help" to include "abort".
- **Tests first:** N/A
- **Done when:** Help command lists abort as a valid verb.

## Risk Notes
- The ops agent's existing `Bash(git worktree *)` and `Bash(git branch *)` patterns should already cover `git worktree remove --force` and `git branch -D`. Need to verify these wildcard patterns match the exact commands. If `Bash(git branch *)` does not match `git branch -D ticket/PREFIX-XXX` (because `-D` is a flag), may need to add a specific pattern.
- The abort command operates on main, not in a worktree. This is different from other ops commands. The commit happens on main after the worktree is removed — ensure the spec is clear about this ordering.
- Need to decide: should abort also clean up `.tickets/.pending` if present? The ticket mentions this (step 7 of Technical Approach), which relates to TS-028. Since TS-028 is not yet implemented, we should include a conditional step ("if `.tickets/.pending` exists, remove it") to future-proof.
