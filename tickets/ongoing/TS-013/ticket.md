---
id: TS-013
title: "Add /ticket-system-abort command to abandon ongoing tickets"
status: ongoing
priority: P0
type: feature
created: 2026-04-04 12:00:00
updated: 2026-04-05 03:17:16
dependencies: []
assignee: unassigned
estimated_complexity: small
---

# TS-013: Add /ticket-system-abort command to abandon ongoing tickets

## Objective
Add a command that cleanly abandons a ticket currently in ongoing/, moves it to rejected/, and removes the associated worktree and branch. This unblocks the system when a ticket fails mid-implementation or becomes irrelevant.

## Context
If `/ticket-system-implement` fails partway through, or if the user decides a ticket is no longer worth pursuing, there is no command to cleanly exit the ongoing state. The user must manually remove the worktree, delete the branch, move the ticket file, and update the frontmatter. This is error-prone and contradicts the system's philosophy of "no changes without a command."

Identified as a P0 blocker across two independent audit reviews.

## Acceptance Criteria
- [ ] A new skill `/ticket-system-abort` exists with its own SKILL.md
- [ ] The command uses the `ticket-system-ops` agent (needs git worktree remove, git branch -D, git mv)
- [ ] The command finds the active ticket in ongoing/
- [ ] The command asks for confirmation before proceeding (destructive action)
- [ ] The command moves the ticket to rejected/ with updated frontmatter (status: rejected, updated timestamp)
- [ ] The command adds a log entry: "Ticket aborted by user."
- [ ] The command removes the git worktree and deletes the associated branch
- [ ] The command commits the rejection on main
- [ ] If no ticket is in ongoing/, the command reports "Nothing to abort" and exits cleanly
- [ ] `disable-model-invocation: true` (destructive — manual only)

## Technical Approach
Add to specs.md:
- New skill `ticket-system-abort/SKILL.md` with `context: fork`, `agent: ticket-system-ops`
- Behavior:
  1. Read `.tickets/config.yml`
  2. Check `tickets/ongoing/` for an active ticket. If empty, check worktrees for tickets in ongoing in any worktree.
  3. If found in worktree: copy the ticket file back to main's `tickets/rejected/`, update frontmatter, commit on main
  4. Remove worktree: `git worktree remove .worktrees/PREFIX-XXX-worktree --force`
  5. Delete branch: `git branch -D ticket/PREFIX-XXX`
  6. Commit: `PREFIX-XXX: Abort ticket — <title>`
  7. Clean up `.tickets/.pending` if present

## Dependencies
<!-- None -->

## Files Modified
- `specs.md` (sections 2.3, 2.4, 4.1, 4.2, 5.1)

## Decisions
<!-- To be filled during implementation. -->

## Notes
- Uses the ops agent which already has bypassPermissions and all required git commands.
- The confirmation step is critical — this destroys the worktree and all uncommitted work in it.
- A future enhancement could offer "abort and re-plan" (move back to planned/ instead of rejected/).

## Log
- 2026-04-04 12:00:00: Ticket created from audit review (W8).
- 2026-04-05 02:50:01: Scheduled to planned (position 1).
- 2026-04-05 03:17:16: Activated — moved to ongoing.
