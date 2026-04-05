---
id: TS-016
title: "Add /ticket-system-next command for automatic next-action detection"
status: ongoing
priority: P1
type: feature
created: 2026-04-04 12:00:00
updated: 2026-04-05 14:51:07
dependencies: []
assignee: unassigned
estimated_complexity: medium
---

# TS-016: Add /ticket-system-next command for automatic next-action detection

## Objective
Add a command that inspects the current state of the ticket system and suggests (or directly invokes) the most logical next action, reducing the cognitive load of remembering the available slash commands.

## Context
After TS-024, the pipeline is simplified to 7 commands: create, schedule, plan, implement, verify, merge, plus utilities (next, doctor, abort, help). While each command has a clear purpose, a developer working through the pipeline should not need to remember which step comes next. The system already has all the information to determine the logical next action.

Identified as the most valuable UX improvement in the external audit review.

## Acceptance Criteria
- [ ] A new skill `/ticket-system-next` exists with its own SKILL.md
- [ ] The command uses the `ticket-system-reader` agent (read-only state inspection)
- [ ] The command detects the current system state and suggests the appropriate next action
- [ ] The command covers all pipeline states (see detection logic below)
- [ ] The output includes: what it detected, what it recommends, and the exact command to run
- [ ] `disable-model-invocation: false` (safe, read-only)

## Technical Approach
Add to specs.md:
- New skill `ticket-system-next/SKILL.md` with `context: fork`, `agent: ticket-system-reader`
- Add `Bash(git worktree *)` to the reader agent's allowed tools if not already present

Detection logic (evaluated in priority order):

1. **Check for inconsistencies** — if `.tickets/.pending` exists → suggest `/ticket-system-doctor`

2. **Check worktrees** (`git worktree list`): if a ticket worktree exists →
   a. Check if ticket is in `completed/` in worktree → suggest `/ticket-system-merge`
   b. Check if code has been modified since plan (git diff in worktree) → suggest `/ticket-system-verify`
   c. Check if `implementation-plan.md` exists → suggest `/ticket-system-implement`
   d. Ticket is in `ongoing/` but no plan yet → suggest `/ticket-system-plan PREFIX-XXX`

3. **Check roadmap** (`roadmap.yml`): if tickets in planned/ →
   a. Read first ticket → suggest `/ticket-system-plan PREFIX-XXX`

4. **Check backlog**: if tickets in `backlog/` →
   a. List them → suggest `/ticket-system-schedule PREFIX-XXX [PREFIX-YYY ...]`

5. **Empty system** → suggest `/ticket-system-create`

Output format:
```
Status: Ticket TS-011 has been implemented in worktree, awaiting verification.
Next action: /ticket-system-verify
```

## Dependencies
None. TS-024 dependency removed — TS-024's pipeline simplification was completed via TS-025/TS-026.

## Files Modified
- `specs.md` (sections 2.3, 2.4, 4.1, 4.2, 5.1)

## Decisions
<!-- To be filled during implementation. -->

## Notes
- This complements `/ticket-system-help` (which shows all commands + counts) with actionable, context-aware guidance.
- The reader agent needs `Bash(git worktree *)` added to its allowed tools for worktree inspection.
- Could be enhanced later to auto-invoke the suggested command with user confirmation.
- Detection of `.pending` file (step 1) depends on TS-012 (doctor) being implemented.

## Log
- 2026-04-04 12:00:00: Ticket created from external audit (M2).
- 2026-04-04 13:00:00: Updated — detection logic adapted to post-TS-024 pipeline (analyze removed, schedule accepts IDs). Added TS-024 as dependency. Added .pending detection for doctor integration.
- 2026-04-05 04:34:28: Removed TS-024 dependency — TS-024 was rejected; its pipeline simplification objectives were completed via TS-025/TS-026.
- 2026-04-05 14:51:07: Ticket activated — moved to ongoing, worktree created.
