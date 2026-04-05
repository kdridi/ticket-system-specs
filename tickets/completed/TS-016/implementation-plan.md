# Implementation Plan — TS-016

## Overview
Add a `/ticket-system-next` skill to specs.md that inspects the ticket system state and suggests the most logical next action. This is a read-only command using the `ticket-system-reader` agent. The implementation touches five areas of specs.md: the agent profile table (2.3), the auto-invocation table (2.4), the command pipeline (4.1 overview + 4.2 detail), and the file tree and validation checklist (5.1, 8).

## Steps

### Step 1: Update the reader agent's allowed tools (section 2.3)
- **Files:** `specs.md` (line ~122)
- **What:** Add `Bash(git diff *)` to the `ticket-system-reader` agent's Allowed Tools column. The next command needs `git -C <worktree> diff` to detect whether code has been modified since the plan was generated. The `git -C` form is handled by the PreToolUse hook (section 2.5), but the base `git diff *` pattern must be in the agent's tool list. Also add `/ticket-system-next` to the "Used by" column.
- **Tests first:** N/A (spec file modification, validated structurally)
- **Done when:** The reader agent row includes `Bash(git diff *)` in tools and `/ticket-system-next` in Used by.

### Step 2: Update the auto-invocation table (section 2.4)
- **Files:** `specs.md` (line ~148, between doctor and the end of the table)
- **What:** Add a row for `ticket-system-next` with `disable-model-invocation: false` and reason "Read-only state inspection, zero risk".
- **Tests first:** N/A
- **Done when:** The table in section 2.4 includes the next command row.

### Step 3: Update the command pipeline overview (section 4.1)
- **Files:** `specs.md` (line ~405)
- **What:** Add a sentence to the overview paragraph mentioning `/ticket-system-next` as a utility command that inspects the current state and suggests the next action. Insert it alongside the existing mentions of `/ticket-system-help` and `/ticket-system-doctor`.
- **Tests first:** N/A
- **Done when:** Section 4.1 mentions `/ticket-system-next` in context with the other utility commands.

### Step 4: Add the detailed command specification (section 4.2)
- **Files:** `specs.md` (insert before `/ticket-system-help` which is at line ~641)
- **What:** Add a new `#### /ticket-system-next` subsection following the established pattern. Include:
  - Agent: `ticket-system-reader` | Auto-invocation: yes | Argument: none
  - Detection logic (5 priority-ordered checks) as specified in the ticket
  - Output format showing "Status:" and "Next action:" lines
  - Note that it does not auto-invoke the suggested command
- **Tests first:** N/A
- **Done when:** A complete command specification exists between `/ticket-system-abort` and `/ticket-system-help` (or in another logical position among utility commands).

### Step 5: Update the file tree (section 5.1)
- **Files:** `specs.md` (line ~742, in the skills tree)
- **What:** Add `ticket-system-next/` with `SKILL.md` to the skill directory listing. Place it alphabetically or grouped with other utility skills (help, doctor).
- **Tests first:** N/A
- **Done when:** The file tree includes `ticket-system-next/SKILL.md`.

### Step 6: Update the validation checklist (section 8)
- **Files:** `specs.md` (line ~919, in the skills checklist)
- **What:** Add `ticket-system-next/` to the structural completeness skills list. Also update any counts if mentioned (e.g., "11 skill directories" becomes "12 skill directories"). Add a checklist item confirming the next command uses the reader agent and has `disable-model-invocation: false`.
- **Tests first:** N/A
- **Done when:** The validation checklist includes the next skill and any aggregate counts are updated.

### Step 7: Update CLAUDE.md to reflect the new command count
- **Files:** `CLAUDE.md`
- **What:** If CLAUDE.md references specific command counts (e.g., "11 skill directories" or "10 slash commands"), update them to reflect the addition of the next command. Also update any pipeline descriptions that enumerate utility commands.
- **Tests first:** N/A
- **Done when:** CLAUDE.md is consistent with the updated specs.md.

## Risk Notes
- The reader agent currently has `permissionMode: plan` which is the most restrictive. Adding `Bash(git diff *)` does not change the permission mode -- it just allows the agent to run diffs. The PreToolUse hook already handles `git -C` validation, so `git -C <worktree> diff` will work correctly.
- The detection logic for step 2b ("code modified since plan") depends on being able to diff inside the worktree. If the worktree has uncommitted changes after the plan commit, `git diff` will show them. This is a reasonable heuristic but not perfect -- it will not detect the case where implementation was committed but verification has not been run. A more refined check could look at git log for implementation commits, but the simple diff check is a good starting point.
- The `.pending` file check (detection step 1) references TS-012 (doctor) infrastructure. Since TS-012 is not yet implemented, the next command should still include this check in the spec -- it will simply never trigger until .pending files are actually created by other commands. This is fine for forward-compatibility.
- The ticket references "sections 2.3, 2.4, 4.1, 4.2, 5.1" but we also need to update section 8 (validation checklist) and CLAUDE.md. These are additions beyond what the ticket explicitly lists.
