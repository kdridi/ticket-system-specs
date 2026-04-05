# Implementation Plan — TS-005a

## Overview
Create a test harness scaffold (`test/run-tests.sh`) that provisions an isolated temp repo, installs the ticket system into it, runs `validate.sh` as the first structural check, and tears everything down on exit. Accompany it with a `test/README.md` explaining automated vs. manual testing boundaries.

## Steps

### Step 1: Create `test/` directory and `test/run-tests.sh` scaffold
- **Files:** `test/run-tests.sh` (create)
- **What:** Create the test runner script with:
  - `#!/bin/bash` shebang
  - `set -euo pipefail` for strict error handling
  - `SCRIPT_DIR` resolution using `$(cd "$(dirname "$0")" && pwd)` and `PROJECT_ROOT` as parent
  - `PASS_COUNT`, `FAIL_COUNT` counters and `record_pass`/`record_fail` helper functions
  - A final summary section that prints pass/fail counts and exits non-zero on any failure
- **Tests first:** N/A (this is the harness itself)
- **Done when:** `bash test/run-tests.sh` runs and prints a summary (0 tests initially)

### Step 2: Add setup function — mktemp + git init + install
- **Files:** `test/run-tests.sh` (modify)
- **What:** Implement a `setup_test_env` function that:
  1. Creates a temp directory via `mktemp -d`
  2. Runs `git init` inside it (with initial commit so worktree operations work)
  3. Runs `bash "$PROJECT_ROOT/init-project.sh"` inside it to create the ticket structure
  4. Stores the path in `TEST_ENV_DIR` for use by test functions
- **Tests first:** N/A (infrastructure)
- **Done when:** Calling `setup_test_env` creates a fully initialized ticket-system project in a temp directory

### Step 3: Add teardown function — trap-based cleanup
- **Files:** `test/run-tests.sh` (modify)
- **What:** Implement a `teardown_test_env` function that:
  1. Removes `TEST_ENV_DIR` if it exists
  2. Register a `trap teardown_test_env EXIT` at the top of the script so cleanup happens even on failures/interrupts
  3. Also support per-test setup/teardown so multiple tests can each get a fresh environment
- **Tests first:** N/A (infrastructure)
- **Done when:** Temp directory is always cleaned up, even when tests fail or the script is interrupted

### Step 4: Add validate.sh integration as the first test
- **Files:** `test/run-tests.sh` (modify)
- **What:** After setup, the harness needs a generated output directory to validate against. Since this project generates output by feeding `specs.md` to Claude Code (which cannot be scripted), the harness should:
  1. Check if a `GENERATED_OUTPUT_DIR` environment variable is set
  2. If set, run `bash "$PROJECT_ROOT/validate.sh" "$GENERATED_OUTPUT_DIR"` and capture the exit code
  3. Record PASS/FAIL based on the exit code
  4. If not set, skip the validate.sh test with a message explaining how to provide it
  - This keeps the harness useful: run it with `GENERATED_OUTPUT_DIR=/path/to/output bash test/run-tests.sh`
- **Tests first:** N/A (integration point)
- **Done when:** `validate.sh` runs against a provided generated output directory and its result is captured in the test summary

### Step 5: Add validate-spec.sh as a second structural test
- **Files:** `test/run-tests.sh` (modify)
- **What:** Run `bash "$PROJECT_ROOT/validate-spec.sh"` as a test that does not need external input (it validates `specs.md` which is always present). This exercises the spec cross-reference checker.
- **Tests first:** N/A
- **Done when:** validate-spec.sh result is captured in the test summary

### Step 6: Add test-validate.sh as a third structural test
- **Files:** `test/run-tests.sh` (modify)
- **What:** Run `bash "$PROJECT_ROOT/test-validate.sh"` as a test. This exercises the existing 23 test cases for validate.sh and confirms the validation tooling itself is sound.
- **Tests first:** N/A
- **Done when:** test-validate.sh result is captured in the test summary

### Step 7: Add init-project.sh structural verification test
- **Files:** `test/run-tests.sh` (modify)
- **What:** Use the `setup_test_env` function to create an isolated repo with init-project.sh, then verify:
  1. `tickets/backlog/`, `tickets/planned/`, `tickets/ongoing/`, `tickets/completed/`, `tickets/rejected/` all exist
  2. `.tickets/config.yml` exists (or the init script creates it)
  3. `.gitignore` contains `.worktrees/`
  4. `.gitkeep` files exist in each ticket subdirectory
  Record PASS/FAIL for each structural check.
- **Tests first:** N/A
- **Done when:** Structural verification runs inside an isolated temp repo and reports per-check results

### Step 8: Make script executable and create test/README.md
- **Files:** `test/run-tests.sh` (chmod +x), `test/README.md` (create)
- **What:**
  - Ensure `test/run-tests.sh` is executable
  - Create `test/README.md` documenting:
    - What `run-tests.sh` does (setup, validate, teardown)
    - How to run it: `bash test/run-tests.sh` for basic tests, `GENERATED_OUTPUT_DIR=/path bash test/run-tests.sh` for full validation
    - What is automated (spec validation, init-project structural checks, validate.sh against generated output)
    - What remains manual (generating output via Claude Code, running slash commands interactively, testing the outer feedback loop)
- **Tests first:** N/A
- **Done when:** README.md is clear and the script runs end-to-end

## Risk Notes
- `init-project.sh` may not create `.tickets/config.yml` (it may only create the `tickets/` structure). Need to check during implementation and adjust the structural verification accordingly.
- The harness cannot test Claude Code slash commands programmatically. The README must clearly document this boundary.
- The existing `test-validate.sh` uses `sed -i.bak` which is macOS-compatible but may behave differently on Linux. The new harness should avoid platform-specific constructs where possible.
