---
id: TS-029
title: "Add /ticket-system-run-all command to execute all planned tickets sequentially"
status: ongoing
priority: P1
type: feature
created: 2026-04-05 19:41:45
updated: 2026-04-07 23:35:07
dependencies: []
assignee: ai
estimated_complexity: medium
---

# TS-029: Add /ticket-system-run-all command to execute all planned tickets sequentially

## Objective
Introduce a new `/ticket-system-run-all` command that reads all planned tickets from `tickets/planned/roadmap.yml` and executes them one after another using `/ticket-system-run`, stopping on the first failure.

## Context
`/ticket-system-run` already automates the full lifecycle for a single ticket (plan → implement → verify → merge). However, when multiple tickets are in the roadmap, the user must invoke `/ticket-system-run` once per ticket. A `/ticket-system-run-all` command would let the user trigger unattended sequential execution of the entire roadmap, improving developer productivity on single-developer projects.

## Acceptance Criteria
- [ ] `/ticket-system-run-all` reads `tickets/planned/roadmap.yml` in position order.
- [ ] For each ticket in the roadmap, it invokes `/ticket-system-run` with the ticket ID.
- [ ] If `/ticket-system-run` fails for a ticket, execution stops and the user is notified of which ticket failed.
- [ ] On success of each ticket, execution continues to the next one in roadmap order.
- [ ] The command reports a summary at the end: how many tickets were processed, which succeeded, which failed (if any).
- [ ] The command is documented in the spec (`specs.md`) and has a corresponding skill file.

## Technical Approach
Add a new skill `ticket-system-run-all` under `skills/` with a `SKILL.md` following the same structure as other skills. The skill reads `tickets/planned/roadmap.yml`, iterates over tickets in `position` order, and chains `/ticket-system-run` calls. Execution is aborted on first failure. The agent used should have sufficient permissions (same profile as the `run` command). Update `specs.md` section 4 (Command Pipeline) to document the new command.

## Dependencies
<!-- List ticket IDs that must be completed before this one. -->

## Files Modified
- `specs.md` — Added /ticket-system-run-all command documentation (sections 2.3, 2.4, 4.1, 4.2, 5.1, 8)
- `CLAUDE.md` — Updated skill count (13 directories, 12 slash commands) and deep validation reference
- `.claude/skills/ticket-system-run-all/SKILL.md` — New skill file (created in main repo, not tracked in worktree)

## Decisions
<!-- Design decisions made during this ticket. -->

## Notes
- The command operates only on the `planned` queue; it does not pick up `backlog` tickets.
- Stop-on-failure matches the philosophy of `/ticket-system-run` which also stops on verify failure.
- Human approval gates that exist within `/ticket-system-run` are preserved per-ticket (they are not bypassed by this command unless `--yes` is passed through).

## Log
- 2026-04-05 19:41:45: Ticket created.
- 2026-04-05 19:48:14: Scheduled to planned (roadmap position 1).
- 2026-04-06 00:04:41: Aborted — moved back to backlog. Worktree and branch removed.
- 2026-04-07 23:09:29: Scheduled to planned (roadmap position 1).
- 2026-04-07 23:11:10: Activated — moved to ongoing, worktree created.
- 2026-04-07 23:35:07: Implementation complete — skill file created, specs.md updated (sections 2.3, 2.4, 4.1, 4.2, 5.1, 8), CLAUDE.md synced.
