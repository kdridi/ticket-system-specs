---
id: TS-027
title: "Add /ticket-system-doctor diagnostic skill (read-only checks)"
status: ongoing
priority: P0
type: feature
created: 2026-04-05 02:50:01
updated: 2026-04-05 03:35:53
dependencies: []
assignee: unassigned
estimated_complexity: small
---

# TS-027: Add /ticket-system-doctor diagnostic skill (read-only checks)

## Objective
Add a read-only diagnostic command that verifies the consistency of the ticket system state and reports issues with suggested fixes. Covers status/directory mismatches, orphaned worktrees, stale roadmap entries, and multiple tickets in ongoing/.

## Context
The ticket system performs multi-step operations (git mv + frontmatter update + roadmap edit + commit). If any step fails mid-operation, the system is left in an inconsistent state with no recovery mechanism. This ticket delivers the diagnostic half: a safe, read-only reporter the user can run at any time to understand what is wrong.

Split from TS-012 (original medium-complexity ticket). TS-028 adds the `.pending` transaction log to mutative commands, extending this ticket's checks.

## Acceptance Criteria
- [ ] A new skill `/ticket-system-doctor` exists with its own SKILL.md
- [ ] The command uses the `ticket-system-reader` agent (read-only diagnostics)
- [ ] The command checks: frontmatter `status` matches the directory the ticket is in (backlog/planned/ongoing/completed/rejected)
- [ ] The command checks: orphaned git worktrees (worktree exists but no corresponding ticket in ongoing/)
- [ ] The command checks: stale roadmap entries (ticket referenced in roadmap but not in planned/)
- [ ] The command checks: multiple tickets in ongoing/ (should be max 1)
- [ ] Each issue is reported with a clear description and a suggested fix command
- [ ] The command does NOT auto-fix — it reports and suggests. User decides.
- [ ] `disable-model-invocation: false` (safe to auto-invoke, read-only)

## Technical Approach
Add to specs.md:
- New skill `ticket-system-doctor/SKILL.md` with `context: fork`, `agent: ticket-system-reader`
- Diagnostics checklist executed in order:
  1. Read `.tickets/config.yml`
  2. Scan all ticket files, verify `status` field matches parent directory
  3. Run `git worktree list`, cross-reference with tickets in ongoing/
  4. Read roadmap, verify each referenced ticket exists in planned/
  5. Check that ongoing/ contains at most 1 ticket
  6. Report findings as a structured checklist with [OK] / [ISSUE] prefixes

## Dependencies
<!-- None -->

## Files Modified
- `specs.md` (sections 2.3, 2.4, 4.2, 5.1)

## Decisions
<!-- To be filled during implementation. -->

## Notes
- The reader agent already has the necessary bash permissions for read-only operations.
- TS-028 extends this ticket by adding `.pending` file checks (requires mutative commands to be updated first).

## Log
- 2026-04-05 02:50:01: Ticket created as sub-ticket A of TS-012 split. Scheduled to planned (position 2).
- 2026-04-05 03:35:53: Ticket activated. Moved to ongoing.
