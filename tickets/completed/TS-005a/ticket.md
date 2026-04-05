---
id: TS-005a
title: "Add test harness scaffold with setup/teardown and validate.sh integration"
status: completed
priority: P2
type: infrastructure
created: 2026-04-05 04:34:19
updated: 2026-04-05 15:52:10
dependencies: [TS-002]
assignee: unassigned
estimated_complexity: small
parent: TS-005
---

# TS-005a: Add test harness scaffold with setup/teardown and validate.sh integration

## Objective
Create the test harness scaffold — run-tests.sh script with setup (mktemp -d, git init, install ticket system) and teardown (cleanup temp dir), integrated with validate.sh from TS-002.

## Context
The outer feedback loop is entirely manual. A reusable scaffold that provisions an isolated repo, installs the ticket system, and tears everything down on exit is the foundational piece needed before individual command tests can be written. TS-002 provides validate.sh which should be exercised as the first structural check inside this harness.

## Acceptance Criteria
- [x] `run-tests.sh` exists and is executable
- [x] Creates an isolated temp repo per test run via `mktemp -d`
- [x] Installs the ticket system into the temp repo
- [x] Runs validate.sh as the first check after installation
- [x] Cleans up the temp directory on exit via `trap`
- [x] Documents manual steps where Claude Code invocation cannot be scripted

## Technical Approach
- Use `mktemp -d` to create an isolated temp directory per run
- Run `git init` inside it and invoke `install.sh` + `init-project.sh`
- Source or call validate.sh from TS-002 as the first assertion
- Register a `trap` on EXIT to remove the temp directory unconditionally
- Add a `test/README.md` explaining what is automated vs. what remains manual

## Dependencies
- TS-002 (validate.sh, reusable check primitives)

## Files Modified
- `test/run-tests.sh` (created) -- test harness with setup/teardown, validate.sh integration, structural checks
- `test/README.md` (created) -- documents automated vs manual testing boundaries

## Decisions
- init-project.sh does not exist in this repo (it is generated output), so setup_test_env only runs it when GENERATED_OUTPUT_DIR is provided.
- Pre-existing failures in validate-spec.sh and test-validate.sh are correctly captured by the harness (not bugs in the harness).

## Notes
- Full end-to-end testing of slash commands requires Claude Code to be running, which limits full automation. The scaffold should cover filesystem-level setup and document the AI-interaction steps separately.

## Log
- 2026-04-05 04:34:19: Ticket created as sub-ticket of TS-005 (split).
- 2026-04-05 15:45:24: Ticket activated, moved to ongoing.
- 2026-04-05 15:50:27: Implementation complete. Created test/run-tests.sh with setup/teardown, validate.sh/validate-spec.sh/test-validate.sh integration, init-project structural checks, and test/README.md.
- 2026-04-05 15:52:10: VERDICT: PASS — Ticket completed.
