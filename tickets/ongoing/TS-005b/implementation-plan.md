# Implementation Plan — TS-005b

## Overview
Extend `test/run-tests.sh` with test functions that exercise the filesystem-observable side effects of `/ticket-system-create`, `/ticket-system-schedule`, and `/ticket-system-plan`. Since these commands require a running Claude Code session, the tests are structured as documented manual verification procedures: each test function describes the setup, the command to run, and the filesystem assertions to check afterward. A helper function performs the assertions so that results are machine-parseable (PASS/FAIL per assertion).

## Steps

### Step 1: Add assertion helpers for frontmatter and file checks
- **Files:** `test/run-tests.sh` (extend)
- **What:** Add helper functions: `assert_file_exists`, `assert_file_not_exists`, `assert_frontmatter_field` (extracts a YAML frontmatter field from a file and compares to expected value), `assert_file_contains` (grep for a pattern in a file). Each helper calls `record_pass` or `record_fail` with a descriptive label.
- **Tests first:** N/A (these are test utilities themselves)
- **Done when:** Helpers are defined and available for use in subsequent test functions.

### Step 2: Add test function for /ticket-system-create
- **Files:** `test/run-tests.sh` (extend)
- **What:** Add `test_create_command()` that:
  1. Documents the manual step: "Run `/ticket-system-create` with arguments: title='Test ticket', type=feature, priority=P1"
  2. Defines expected outcomes:
     - A new `.md` file appears in `tickets/backlog/` matching the pattern `PREFIX-NNN.md`
     - Frontmatter contains `status: backlog`, `type: feature`, `priority: P1`
     - The title field matches the provided title
     - A log entry with "Ticket created" exists
     - The ID is one higher than the previous highest ID
  3. Provides assertion calls (commented out or gated behind a `MANUAL_TEST_DIR` variable) that can be run against a directory where the command was already executed
- **Tests first:** N/A
- **Done when:** Function exists, documents expected outcomes, and provides runnable assertions.

### Step 3: Add test function for /ticket-system-schedule
- **Files:** `test/run-tests.sh` (extend)
- **What:** Add `test_schedule_command()` that:
  1. Documents prerequisites: a ticket must exist in `tickets/backlog/`
  2. Documents the manual step: "Run `/ticket-system-schedule PREFIX-NNN --yes`"
  3. Defines expected outcomes:
     - The ticket file moves from `tickets/backlog/PREFIX-NNN.md` to `tickets/planned/PREFIX-NNN.md`
     - Frontmatter `status` changes to `planned`
     - Frontmatter `updated` timestamp is refreshed
     - An entry is added to `tickets/planned/roadmap.yml` with the ticket's ID
     - A log entry with scheduling information exists
  4. Provides assertion calls for each outcome
- **Tests first:** N/A
- **Done when:** Function exists with documented outcomes and assertions.

### Step 4: Add test function for /ticket-system-plan
- **Files:** `test/run-tests.sh` (extend)
- **What:** Add `test_plan_command()` that:
  1. Documents prerequisites: a ticket must be in `tickets/planned/` and in `roadmap.yml`, `tickets/ongoing/` must be empty, all dependencies completed
  2. Documents the manual step: "Run `/ticket-system-plan PREFIX-NNN --yes`"
  3. Defines expected outcomes:
     - A worktree exists at `.worktrees/PREFIX-NNN-worktree/`
     - Inside the worktree: `tickets/ongoing/PREFIX-NNN/ticket.md` exists
     - Inside the worktree: `tickets/ongoing/PREFIX-NNN/implementation-plan.md` exists
     - Inside the worktree: `tickets/ongoing/PREFIX-NNN/test-plan.md` exists
     - Ticket frontmatter has `status: ongoing`
     - The ticket's entry is removed from `roadmap.yml` in the worktree
     - A git branch `ticket/PREFIX-NNN` exists
  4. Provides assertion calls for each outcome
- **Tests first:** N/A
- **Done when:** Function exists with documented outcomes and assertions.

### Step 5: Wire test functions into main and update documentation
- **Files:** `test/run-tests.sh` (extend), `test/README.md` (update)
- **What:** 
  - Add calls to `test_create_command`, `test_schedule_command`, `test_plan_command` in the main section of `run-tests.sh`, gated behind a `MANUAL_TEST_DIR` environment variable (similar to how `GENERATED_OUTPUT_DIR` gates other tests)
  - Update `test/README.md` to document the new command coverage tests, how to run them, and the manual verification workflow
- **Done when:** Running `MANUAL_TEST_DIR=/path/to/tested/repo bash test/run-tests.sh` invokes the new test functions and the README documents the procedure.

## Risk Notes
- These tests cannot be fully automated because the slash commands require a running Claude Code session. The design intentionally separates "document expected outcomes" from "verify outcomes" so that a human can run the command, then run the assertions against the result.
- The `/ticket-system-plan` test involves worktree state that may be tricky to assert against from outside the worktree. The assertions should use explicit paths into `.worktrees/PREFIX-NNN-worktree/`.
- Frontmatter parsing in bash is fragile. The `assert_frontmatter_field` helper should use simple grep/sed patterns and document its limitations.
