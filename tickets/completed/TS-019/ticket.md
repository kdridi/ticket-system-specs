---
id: TS-019
title: "Tighten bash wildcard patterns per agent"
status: completed
priority: P2
type: refactor
created: 2026-04-04 12:00:00
updated: 2026-04-05 15:34:40
dependencies: []
assignee: unassigned
estimated_complexity: small
---

# TS-019: Tighten bash wildcard patterns per agent

## Objective
Restrict overly broad bash wildcard patterns in agent definitions to reduce the attack surface without breaking legitimate usage.

## Context
External audit identified that some bash patterns are more permissive than intended. For example, `Bash(git commit *)` allows `git commit --amend` or `git commit --allow-empty`, and `Bash(git mv *)` allows moving any file in the repo, not just tickets.

Updated after TS-024: the agent landscape is simplified. `ticket-system-analyze` and `ticket-system-split` no longer exist — their functions are absorbed into the editor agent via the unified `/ticket-system-schedule`. The remaining agents to audit are: reader, editor, planner, coder, verifier, ops.

## Acceptance Criteria
- [x] `Bash(git commit *)` is replaced with `Bash(git commit -m *)` on agents that should only create new commits (editor, verifier)
- [x] `Bash(git mv *)` is replaced with `Bash(git mv tickets/*)` on the editor agent
- [x] The planner retains broader `git mv *` (needs to move tickets to ongoing/ subdirectories)
- [x] The reader agent's permissions are reviewed for its reduced scope (help, next, doctor only)
- [x] All changes are verified to not break any command's documented behavior
- [x] Updated patterns are reflected in section 2.3 agent profiles table

## Technical Approach
Review each agent's bash patterns against its actual usage in the post-TS-024 command set:

| Agent | Used by | Current | Proposed | Rationale |
|-------|---------|---------|----------|-----------|
| reader | help, next, doctor | `Bash(find *)` | `Bash(find *)` | Unchanged — reader needs codebase access for next's worktree inspection |
| editor | create, schedule | `Bash(git commit *)` | `Bash(git commit -m *)` | Only creates new commits |
| editor | create, schedule | `Bash(git mv *)` | `Bash(git mv tickets/*)` | Only moves ticket files |
| planner | plan | `Bash(git commit *)` | `Bash(git commit -m *)` | Only creates activation commits |
| verifier | verify | `Bash(git commit *)` | `Bash(git commit -m *)` | Only creates completion commits |
| coder | implement, run | unrestricted | unrestricted | By design (bypassPermissions) |
| ops | merge, abort | unrestricted | unrestricted | By design (bypassPermissions) |

Reader agent additions needed for new commands:
- `Bash(git worktree *)` — needed by `/ticket-system-next` (TS-016) to inspect worktree state

## Dependencies
None. TS-024 dependency removed — TS-024's pipeline simplification was completed via TS-025/TS-026.

## Files Modified
- `specs.md` (section 2.3 — agent profiles table, lines 122-127)

## Decisions
- Tightened `git commit` to `git commit -m` on editor, planner, verifier, and ops (not just editor and verifier as originally scoped -- planner and ops also only create new commits).
- Tightened `git mv` to `git mv tickets/*` on editor, verifier, and ops. Planner retains broader `git mv *` because it moves tickets into `ongoing/PREFIX-XXX/` subdirectories.
- Reader agent confirmed correct -- no `git commit` or `git mv` patterns present, only read-only git operations.

## Notes
- This is defense-in-depth. The primary security boundary remains the permissionMode per agent.
- Test each restriction by mentally walking through the commands that use the affected agent.
- The editor agent's scope expands with TS-024 (schedule now includes analysis and split logic). Ensure the tightened patterns don't break the new schedule behavior — notably, creating sub-tickets requires `Bash(mkdir *)` which the editor already has.

## Log
- 2026-04-04 12:00:00: Ticket created from external audit (M7).
- 2026-04-04 13:00:00: Updated — adapted to post-TS-024 agent landscape (analyze/split removed, reader scope reduced).
- 2026-04-05 04:34:28: Removed TS-024 dependency — TS-024 was rejected; its pipeline simplification objectives were completed via TS-025/TS-026.
- 2026-04-05 15:27:39: Ticket activated — moved to ongoing, worktree created at .worktrees/TS-019-worktree.
- 2026-04-05 15:32:25: Implementation complete — tightened bash patterns for editor, planner, verifier, and ops agents in specs.md section 2.3. All patterns cross-validated against command behaviors in section 4.2.
- 2026-04-05 15:34:40: VERDICT: PASS — Ticket completed.
