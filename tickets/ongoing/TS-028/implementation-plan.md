# Implementation Plan -- TS-028

## Overview
Add `.tickets/.pending` transaction log instrumentation to all mutative commands (schedule, plan, abort, merge) in `specs.md`, and extend the doctor command to detect stale `.pending` files. This involves editing section 4.2 of specs.md for each of the four mutative commands plus the doctor command.

## Steps

### Step 1: Define the .pending file format in section 3 (Data Model)
- **Files:** `specs.md` (section 3.2 Directory Structure)
- **What:** Add `.tickets/.pending` to the directory structure documentation, noting it is a transient sentinel file created during multi-step operations. Add a subsection or note describing the YAML format (operation, ticket, started, description).
- **Tests first:** N/A (spec-only change). Verify by visual inspection.
- **Done when:** The `.pending` file format is documented in the data model section, and the directory structure listing includes `.tickets/.pending` with a comment.

### Step 2: Add .pending write/delete to /ticket-system-schedule
- **Files:** `specs.md` (section 4.2, `/ticket-system-schedule`)
- **What:** Insert "Write `.tickets/.pending`" as the first action in Phase 4 (Execute on approval), before any git mv operations. Insert "Delete `.tickets/.pending`" as the final step of Phase 4, after the commit. The `.pending` content should use `operation: schedule`, the list of ticket IDs, and an appropriate description.
- **Tests first:** N/A (spec-only change).
- **Done when:** The schedule command spec includes `.pending` write at the start of Phase 4 and delete at the end.

### Step 3: Add .pending write/delete to /ticket-system-plan
- **Files:** `specs.md` (section 4.2, `/ticket-system-plan`)
- **What:** Insert "Write `.tickets/.pending`" as the first action in Phase 1 (Activation), before creating the worktree. Insert "Delete `.tickets/.pending`" as the last step of Phase 4, after the plan commit (and after the human gate loop resolves). The `.pending` content should use `operation: plan` and appropriate description.
- **Tests first:** N/A (spec-only change).
- **Done when:** The plan command spec includes `.pending` write at the start of Phase 1 and delete at the end of Phase 4.

### Step 4: Add .pending write/delete to /ticket-system-merge
- **Files:** `specs.md` (section 4.2, `/ticket-system-merge`)
- **What:** Insert "Write `.tickets/.pending`" as the first step (step 1, before reading config, or immediately after). Insert "Delete `.tickets/.pending`" as the final step, after worktree removal. The `.pending` content should use `operation: merge` and appropriate description.
- **Tests first:** N/A (spec-only change).
- **Done when:** The merge command spec includes `.pending` write and delete.

### Step 5: Verify /ticket-system-abort already handles .pending cleanup
- **Files:** `specs.md` (section 4.2, `/ticket-system-abort`)
- **What:** The abort command already has step 10: "If `.tickets/.pending` exists, remove it." Additionally, abort itself is a mutative command, so it needs its own `.pending` write at the start and delete at the end (with the cleanup of any pre-existing `.pending` as part of its operation). Add `.pending` write/delete around the abort operation itself. Update step 10 wording if needed to clarify it removes any pre-existing `.pending` from whatever operation was interrupted, and the abort's own `.pending` is managed separately (or combined -- the abort replaces the prior `.pending` with its own).
- **Tests first:** N/A (spec-only change).
- **Done when:** The abort command spec has its own `.pending` instrumentation and cleanly handles pre-existing `.pending` files.

### Step 6: Extend /ticket-system-doctor with .pending check
- **Files:** `specs.md` (section 4.2, `/ticket-system-doctor`)
- **What:** Add a new check as step 2 (immediately after reading config, before the status/directory mismatch check). The check reads `.tickets/.pending`, and if present, reports it as an [ISSUE] with the operation name, ticket ID, start time, and description. Suggest recovery based on the operation type. Renumber subsequent steps. Update the report template to include the `.pending` check as the first diagnostic item (highest urgency).
- **Tests first:** N/A (spec-only change).
- **Done when:** The doctor command spec includes the `.pending` check as its first diagnostic, with example output in the report template.

### Step 7: Update the validation checklist (section 8)
- **Files:** `specs.md` (section 8, Validation Checklist)
- **What:** Add checklist items verifying that all mutative commands write/delete `.tickets/.pending`, and that doctor checks for it as the first diagnostic.
- **Tests first:** N/A (spec-only change).
- **Done when:** Section 8 has validation entries for the `.pending` instrumentation.

### Step 8: Update ticket metadata
- **Files:** `tickets/ongoing/TS-028/ticket.md`
- **What:** Update the Files Modified section and add log entries for the implementation work.
- **Tests first:** N/A.
- **Done when:** Ticket metadata reflects all changes made.

## Risk Notes
- The `.pending` file is written on main (not in the worktree) for schedule and plan, since the worktree may not exist yet. For merge, it is also on main since merge operates on main. For abort, it is also on main. This is consistent -- `.tickets/.pending` always lives on main.
- The abort command has a special case: it needs to remove a pre-existing `.pending` (from whatever operation was interrupted) AND manage its own `.pending`. The simplest approach is to have abort write its own `.pending` (overwriting any existing one) at the start, and delete it at the end. This way step 10 (removing `.pending`) is naturally the abort's own cleanup.
- Need to be careful about the `.pending` file format: the ticket specifies YAML with `operation`, `ticket`, `started`, `description` fields. This should be documented consistently across all commands.
- The specs.md section 4.1 Overview mentions `.tickets/.pending` should be referenced there too, but the ticket does not explicitly ask for it. Will add a brief mention if it fits naturally.
