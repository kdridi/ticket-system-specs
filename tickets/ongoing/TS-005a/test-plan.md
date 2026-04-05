# Test Plan — TS-005a

## Strategy
Integration testing. The harness itself is the deliverable, so we verify its behavior by running it and checking that it produces correct output under various conditions. Tests are manual invocations of the script with different configurations.

## Test Cases

### TC-1: Script exists and is executable
- **Type:** unit
- **Target:** `test/run-tests.sh`
- **Input:** `ls -la test/run-tests.sh`
- **Expected:** File exists, has executable permission, starts with `#!/bin/bash`
- **Covers criteria:** AC-1 (`run-tests.sh` exists and is executable)

### TC-2: Temp directory is created during setup
- **Type:** integration
- **Target:** `setup_test_env` function
- **Input:** Run `bash test/run-tests.sh` and observe output
- **Expected:** Output shows a temp directory path was created; directory exists during execution
- **Covers criteria:** AC-2 (creates isolated temp repo via `mktemp -d`)

### TC-3: Ticket system is installed into temp repo
- **Type:** integration
- **Target:** `setup_test_env` function
- **Input:** Run `bash test/run-tests.sh` and check structural verification results
- **Expected:** Init-project structural checks pass (directories exist, .gitignore has .worktrees/)
- **Covers criteria:** AC-3 (installs the ticket system into the temp repo)

### TC-4: validate.sh runs as first check with GENERATED_OUTPUT_DIR
- **Type:** integration
- **Target:** validate.sh integration
- **Input:** `GENERATED_OUTPUT_DIR=/path/to/valid/output bash test/run-tests.sh`
- **Expected:** validate.sh test appears first in output and reports PASS
- **Covers criteria:** AC-4 (runs validate.sh as the first check after installation)

### TC-5: validate.sh is skipped when GENERATED_OUTPUT_DIR is not set
- **Type:** integration
- **Target:** validate.sh integration
- **Input:** `bash test/run-tests.sh` (no env var)
- **Expected:** Output shows a SKIP message for validate.sh with instructions
- **Covers criteria:** AC-4 (graceful handling when validate.sh cannot run)

### TC-6: Temp directory is cleaned up on normal exit
- **Type:** integration
- **Target:** trap-based teardown
- **Input:** Run `bash test/run-tests.sh`, capture temp dir path from output, check after exit
- **Expected:** Temp directory does not exist after script completes
- **Covers criteria:** AC-5 (cleans up temp directory on exit via trap)

### TC-7: Temp directory is cleaned up on failure
- **Type:** integration
- **Target:** trap-based teardown
- **Input:** Intentionally break a test (e.g., remove init-project.sh temporarily), run harness
- **Expected:** Temp directory is still cleaned up despite test failures
- **Covers criteria:** AC-5 (cleanup via trap handles failures)

### TC-8: README.md documents manual steps
- **Type:** unit
- **Target:** `test/README.md`
- **Input:** Read the file
- **Expected:** Contains sections on: what is automated, what is manual, how to run, how to provide GENERATED_OUTPUT_DIR
- **Covers criteria:** AC-6 (documents manual steps)

### TC-9: validate-spec.sh runs as a structural check
- **Type:** integration
- **Target:** validate-spec.sh integration
- **Input:** `bash test/run-tests.sh`
- **Expected:** validate-spec.sh result appears in output and reports PASS
- **Covers criteria:** AC-4 (structural checks run)

### TC-10: test-validate.sh runs as a structural check
- **Type:** integration
- **Target:** test-validate.sh integration
- **Input:** `bash test/run-tests.sh`
- **Expected:** test-validate.sh result appears in output and reports PASS
- **Covers criteria:** AC-4 (validation tooling is exercised)

### TC-11: Exit code is non-zero when a test fails
- **Type:** integration
- **Target:** Summary and exit logic
- **Input:** Run harness with a broken configuration that causes a failure
- **Expected:** Script exits with non-zero status
- **Covers criteria:** General correctness (CI-friendly exit codes)

### TC-12: No external dependencies
- **Type:** unit
- **Target:** `test/run-tests.sh`
- **Input:** `grep -E '\b(python|node|jq|ruby|perl|npm|pip)\b' test/run-tests.sh`
- **Expected:** No matches found
- **Covers criteria:** POSIX-only constraint

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: run-tests.sh exists and is executable | TC-1 |
| AC-2: Creates isolated temp repo via mktemp -d | TC-2 |
| AC-3: Installs ticket system into temp repo | TC-3 |
| AC-4: Runs validate.sh as first check | TC-4, TC-5, TC-9, TC-10 |
| AC-5: Cleans up temp directory on exit via trap | TC-6, TC-7 |
| AC-6: Documents manual steps | TC-8 |
