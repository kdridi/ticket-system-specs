---
id: TS-005b
title: "Add command coverage tests to test harness"
status: ongoing
priority: P2
type: infrastructure
created: 2026-04-05 04:34:19
updated: 2026-04-05 16:08:08
dependencies: [TS-005a]
assignee: unassigned
estimated_complexity: small
parent: TS-005
---

# TS-005b: Add command coverage tests to test harness

## Objective
Add test cases covering the core slash commands (create, schedule, plan, implement stubs) to the harness from TS-005a.

## Context
Once the scaffold from TS-005a is in place, the harness needs actual test cases. These cases exercise the file-system-observable side effects of each slash command (directory creation, frontmatter changes, roadmap updates) and emit PASS/FAIL per test, making regressions detectable without manual inspection.

## Acceptance Criteria
- [ ] Test cases for /ticket-system-create, /ticket-system-schedule, /ticket-system-plan exercising expected file outputs
- [ ] Documented expected outcomes for each command
- [ ] Pass/fail reporting per test case

## Technical Approach
- Add one test function per command inside `run-tests.sh` (or sourced files)
- For each command, assert on observable filesystem outcomes: file existence, frontmatter field values, roadmap entries
- Emit `PASS` / `FAIL` with a short description for each assertion
- Where Claude Code must be invoked, record the step as a documented manual verification point with expected output

## Dependencies
- TS-005a (test harness scaffold)

## Files Modified
- `test/run-tests.sh` (extended with assertion helpers and command coverage tests)
- `test/README.md` (updated with command coverage test documentation)

## Decisions
- Assertion helpers use sed-based frontmatter parsing (simple but documented as fragile for complex YAML).
- Command coverage tests are gated behind MANUAL_TEST_DIR and per-command ticket ID env vars, skipping cleanly when not set.
- All three command test functions (create, schedule, plan) added in a single implementation pass since they follow identical patterns.

## Notes
- Coverage should include at minimum: ticket create, schedule, and plan. Implement and verify stubs can follow in a later iteration once the harness is proven stable.

## Log
- 2026-04-05 04:34:19: Ticket created as sub-ticket of TS-005 (split).
- 2026-04-05 16:03:37: Ticket activated, moved to ongoing.
- 2026-04-05 16:08:08: Implementation complete. Added assertion helpers (assert_file_exists, assert_file_not_exists, assert_frontmatter_field, assert_file_contains), test functions for create/schedule/plan commands, wired into main, updated README.
