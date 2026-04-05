# Implementation Plan — TS-023

## Overview
Add five small documentation clarifications to `specs.md` and update `CLAUDE.md` to stay in sync. All changes are additive (no existing behavior is modified). The ticket also updates `CLAUDE.md` per the project rule that it must reflect any `specs.md` changes.

## Steps

### Step 1: Add "one active ticket per project" clarification to section 1.2
- **Files:** `specs.md`
- **What:** After the existing bullet "One active ticket at a time. Focus over multitasking." in section 1.2 (Core Principles), expand it or add a follow-up sentence clarifying this constraint applies per `.tickets/` directory (per project), not per machine or per user. A developer working on multiple projects has independent ticket systems.
- **Tests first:** N/A (docs ticket)
- **Done when:** Section 1.2 explicitly states the per-project scope of the one-ticket constraint.

### Step 2: Add "Conflict resolution" subsection to `/ticket-system-merge` in section 4.2
- **Files:** `specs.md`
- **What:** After step 8 (merge conflict report and STOP) in the `/ticket-system-merge` specification, add a "Manual conflict resolution" note documenting the procedure: user resolves conflicts with standard git tools, commits the merge, then re-runs `/ticket-system-merge` which detects the completed merge and proceeds to worktree cleanup.
- **Tests first:** N/A (docs ticket)
- **Done when:** The `/ticket-system-merge` section contains clear instructions for conflict resolution.

### Step 3: Add "Context isolation" note to section 2.1
- **Files:** `specs.md`
- **What:** Add a note at the end of section 2.1 (Two Complementary Layers) explaining the `context: fork` limitation: forked agents do not inherit the parent conversation context. Users should include sufficient detail in command arguments.
- **Tests first:** N/A (docs ticket)
- **Done when:** Section 2.1 contains a note about context isolation in forked agents.

### Step 4: Add D-11 single-developer decision to section 6
- **Files:** `specs.md`
- **What:** Note: there is already a D-11 entry in the decisions table (about `/ticket-system-schedule` absorbing split functionality). The new decision about single-developer workflow should be assigned the next available number. Add a new row to the decisions table in section 6 with the appropriate number, stating that this system is designed for a single-developer workflow and multi-developer usage is not supported.
- **Tests first:** N/A (docs ticket)
- **Done when:** Section 6 contains a decision entry about single-developer workflow.

### Step 5: Add worktree model explanation to section 3.5 or 3.2
- **Files:** `specs.md`
- **What:** Expand the existing note in section 3.5 (line 341: "Note: `tickets/ongoing/` on main is always empty...") to include the explanation: this design allows planning and scheduling to continue on main while implementation runs in parallel in a worktree. Alternatively, add this near the directory structure in section 3.2 alongside the ongoing/ directory description.
- **Tests first:** N/A (docs ticket)
- **Done when:** The worktree model is explained with the rationale about parallel work on main.

### Step 6: Update CLAUDE.md to reflect specs.md changes
- **Files:** `CLAUDE.md`
- **What:** Review CLAUDE.md and update any sections that should reflect the new documentation clarifications (e.g., Key Design Decisions section mentioning single-developer workflow, worktree model). Per project rules, CLAUDE.md must stay in sync with specs.md.
- **Tests first:** N/A (docs ticket)
- **Done when:** CLAUDE.md accurately reflects the new clarifications added to specs.md.

## Risk Notes
- The ticket's technical approach references "D-11" for the single-developer decision, but D-11 is already taken in the decisions table. The implementation must use the next available number (D-14, since D-13 is the last current entry).
- All changes are additive and in separate sections, so there is no risk of conflicting edits within specs.md.
- Need to be careful with the merge conflict resolution wording to not imply automatic re-detection behavior that does not exist in the current spec.
