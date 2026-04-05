---
id: TS-014
title: "Add configurable test_command to project configuration"
status: ongoing
priority: P1
type: feature
created: 2026-04-04 12:00:00
updated: 2026-04-05 14:35:08
dependencies: []
assignee: unassigned
estimated_complexity: small
---

# TS-014: Add configurable test_command to project configuration

## Objective
Allow projects to specify their test runner command in `.tickets/config.yml` instead of hardcoding `npm test`, `pytest`, and `make test` in the verifier agent.

## Context
The verifier agent currently has bash permissions for `npm test *`, `pytest *`, and `make test *`. Projects using Vitest, Playwright, Cypress, Cargo, Go test, or any other framework cannot run their tests through the verifier. Adding every possible test runner to the agent's bash permissions is not scalable.

Identified during external audit as a trivial fix with high practical impact.

## Acceptance Criteria
- [ ] `.tickets/config.yml` supports an optional `test_command` field (e.g., `test_command: "npx vitest run"`)
- [ ] If `test_command` is not set, the verifier falls back to auto-detection (npm test / pytest / make test)
- [ ] The verifier skill reads `test_command` from config and uses it for test execution
- [ ] `init-project.sh` includes a commented-out `test_command` line in the generated config.yml
- [ ] The `ticket-system-conventions` skill documents the `test_command` field
- [ ] The verifier agent's bash permissions include `Bash(bash -c *)` or a sufficiently broad pattern to execute the configured command

## Technical Approach
Update specs.md:
- Section 3.1: Add `test_command` to the config.yml schema (optional, string)
- Section 4.2 `/ticket-system-verify`: Read test_command from config; if set, use it; if not, auto-detect
- Section 5.4: Add commented `# test_command: "npm test"` to generated config.yml
- Section 2.3: Add `Bash(bash -c *)` to the verifier's allowed bash patterns (needed to execute arbitrary test commands)

## Dependencies
<!-- None -->

## Files Modified
- `specs.md` (sections 2.3, 3.1, 4.2, 5.4)

## Decisions
<!-- To be filled during implementation. -->

## Notes
- The `Bash(bash -c *)` permission on the verifier is broader than the current specific patterns but is necessary to support arbitrary test commands. The verifier remains in `plan` permissionMode so it cannot write files.
- Common test commands: `npm test`, `npx vitest run`, `npx playwright test`, `pytest`, `cargo test`, `go test ./...`, `make test`

## Log
- 2026-04-04 12:00:00: Ticket created from external audit (M8).
- 2026-04-05 14:35:08: Ticket activated, moved to ongoing.
