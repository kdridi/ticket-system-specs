---
id: TS-028
title: "Add .pending transaction log to all mutative commands"
status: ongoing
priority: P0
type: feature
created: 2026-04-05 02:50:01
updated: 2026-04-05 04:18:13
dependencies: [TS-027]
assignee: unassigned
estimated_complexity: small
---

# TS-028: Add .pending transaction log to all mutative commands

## Objective
Extend all mutative ticket-system commands (schedule, plan, abort, merge) to write a `.tickets/.pending` file before starting multi-step operations and delete it on successful completion. Extend `/ticket-system-doctor` to check for this file and report incomplete transactions.

## Context
Multi-step operations can leave the system in an inconsistent state if interrupted. A lightweight `.pending` sentinel file provides a reliable signal that a transaction was in progress when the system crashed. This ticket adds the write/delete instrumentation to mutative commands and extends the doctor command introduced in TS-027 to detect and report stale `.pending` files.

Split from TS-012 (original medium-complexity ticket). Depends on TS-027 which delivers the doctor command that this ticket extends.

## Acceptance Criteria
- [ ] All mutative commands (schedule, plan, abort, merge) write `.tickets/.pending` before starting multi-step work
- [ ] All mutative commands delete `.tickets/.pending` on successful completion
- [ ] The `.pending` file follows the format: `operation`, `ticket`, `started`, `description` fields in YAML
- [ ] `/ticket-system-doctor` checks for `.tickets/.pending` and reports it as an [ISSUE] with description and suggested recovery
- [ ] The check is listed first in the doctor's diagnostics checklist (highest urgency)

## Technical Approach
`.pending` file format:
```yaml
operation: plan
ticket: PREFIX-XXX
started: 2026-04-05 02:50:01
description: "Activating ticket — creating worktree and moving to ongoing"
```

Changes required in specs.md:
- In each mutative command's SKILL.md: add "Write `.tickets/.pending`" as first step, "Delete `.tickets/.pending`" as final step
- In `ticket-system-doctor/SKILL.md`: add check for `.tickets/.pending` as step 1 (before all other checks)

## Dependencies
- TS-027 (doctor skill must exist before it can be extended)

## Files Modified
- `specs.md` (sections 4.1, 4.2, 4.3, 4.4, 4.5 — one per mutative command + doctor extension)

## Decisions
<!-- To be filled during implementation. -->

## Notes
- The `.pending` mechanism is intentionally lightweight — no locking, no process IDs. It is a best-effort crash signal.
- Future enhancement: a `--fix` flag on doctor that auto-applies suggested corrections (requires ops agent).

## Log
- 2026-04-05 02:50:01: Ticket created as sub-ticket B of TS-012 split. Scheduled to planned (position 3).
- 2026-04-05 04:18:13: Ticket activated. Moved to ongoing, worktree created at .worktrees/TS-028-worktree.
