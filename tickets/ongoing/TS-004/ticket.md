---
id: TS-004
title: "Decouple smoke test file count from exact number of generated files"
status: ongoing
priority: P1
type: refactor
created: 2026-04-03 23:41:51
updated: 2026-04-04 02:12:18
dependencies: []
assignee: unassigned
estimated_complexity: small
---

# TS-004: Decouple smoke test file count from exact number of generated files

## Objective
Replace the brittle "exactly 18 files" check in the smoke test with a structural completeness check that verifies the presence of required files by role, not by total count.

## Context
The smoke test currently asserts that exactly 18 files are generated. This number will break any time a new slash command, agent, or supporting file is added to the spec. The check creates friction against extending the system and gives misleading failures (a new command added = smoke test fails even if everything is correct).

The underlying goal of the check is to ensure that no files were accidentally omitted. That goal is better served by checking for required files by name/role rather than by count.

## Acceptance Criteria
- [ ] The smoke test in `specs.md` section 8 no longer contains a hardcoded file count
- [ ] The smoke test instead lists required files/directories by name: `ARCHITECTURE.md`, `install.sh`, `init-project.sh`, each expected agent file, each expected skill directory
- [ ] If `validate.sh` (TS-002) exists, it implements this structural check
- [ ] `CLAUDE.md` is updated to reflect the new validation approach

## Technical Approach
- Edit section 8 of `specs.md` to replace "File count: exactly 18 files generated" with a checklist of named required outputs
- Group checks by category: scripts, agents, skills
- Update the quick reference in `CLAUDE.md` accordingly

## Dependencies
<!-- None -->

## Files Modified
<!-- To be filled during implementation. -->

## Decisions
<!-- To be filled during implementation. -->

## Notes
- This is a low-risk editorial change to the spec. No generated behavior changes.

## Log
- 2026-04-03 23:41:51: Ticket created.
- 2026-04-04 00:12:40: Ticket scheduled and added to roadmap at position 1.
- 2026-04-04: Cancelled and returned to planned — worktree lifecycle redesign needed.
- 2026-04-04 02:12:18: Ticket activated.
