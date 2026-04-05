# Test Plan — TS-005b

## Strategy
Integration-level tests that verify filesystem side effects after each slash command is manually invoked. Each test case is a documented procedure with machine-checkable assertions. Tests run in two modes:

1. **Skip mode** (default): When `MANUAL_TEST_DIR` is not set, tests are skipped with a descriptive message.
2. **Assert mode**: When `MANUAL_TEST_DIR` points to a repo where commands have been executed, assertions run against the actual filesystem state.

Unit tests cover the assertion helper functions themselves to ensure they correctly detect pass/fail conditions.

## Test Cases

### TC-1: assert_file_exists helper works correctly
- **Type:** unit
- **Target:** `assert_file_exists` helper function
- **Input:** An existing file path and a non-existing file path
- **Expected:** PASS for existing file, FAIL for non-existing file
- **Covers criteria:** Pass/fail reporting per test case

### TC-2: assert_frontmatter_field helper works correctly
- **Type:** unit
- **Target:** `assert_frontmatter_field` helper function
- **Input:** A markdown file with YAML frontmatter containing `status: backlog`
- **Expected:** PASS when checking `status` equals `backlog`, FAIL when checking `status` equals `planned`
- **Covers criteria:** Pass/fail reporting per test case

### TC-3: /ticket-system-create produces correct file in backlog
- **Type:** integration (manual command + automated assertion)
- **Target:** `/ticket-system-create` command
- **Input:** `MANUAL_TEST_DIR` pointing to repo after running create with title "Test ticket", type feature, priority P1
- **Expected:** File matching `PREFIX-NNN.md` exists in `tickets/backlog/`, frontmatter has `status: backlog`, `type: feature`, `priority: P1`, log contains "Ticket created"
- **Covers criteria:** Test cases for /ticket-system-create exercising expected file outputs; Documented expected outcomes for each command

### TC-4: /ticket-system-schedule moves ticket to planned and updates roadmap
- **Type:** integration (manual command + automated assertion)
- **Target:** `/ticket-system-schedule` command
- **Input:** `MANUAL_TEST_DIR` pointing to repo after running schedule on a backlog ticket
- **Expected:** Ticket file in `tickets/planned/`, frontmatter has `status: planned`, `updated` is refreshed, entry exists in `roadmap.yml` with correct ID, original backlog file is gone
- **Covers criteria:** Test cases for /ticket-system-schedule exercising expected file outputs; Documented expected outcomes for each command

### TC-5: /ticket-system-plan creates worktree and plan artifacts
- **Type:** integration (manual command + automated assertion)
- **Target:** `/ticket-system-plan` command
- **Input:** `MANUAL_TEST_DIR` pointing to repo after running plan on a planned ticket
- **Expected:** Worktree directory exists at `.worktrees/PREFIX-NNN-worktree/`, ticket moved to `tickets/ongoing/PREFIX-NNN/ticket.md` in worktree, `implementation-plan.md` and `test-plan.md` exist in ticket directory, frontmatter has `status: ongoing`, ticket removed from `roadmap.yml` in worktree, git branch `ticket/PREFIX-NNN` exists
- **Covers criteria:** Test cases for /ticket-system-plan exercising expected file outputs; Documented expected outcomes for each command

### TC-6: Pass/fail summary counts are accurate
- **Type:** unit
- **Target:** `record_pass`, `record_fail`, `record_skip` counters and `print_summary`
- **Input:** Known number of pass/fail/skip calls
- **Expected:** Summary totals match the expected counts
- **Covers criteria:** Pass/fail reporting per test case

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| Test cases for /ticket-system-create, /ticket-system-schedule, /ticket-system-plan exercising expected file outputs | TC-3, TC-4, TC-5 |
| Documented expected outcomes for each command | TC-3, TC-4, TC-5 |
| Pass/fail reporting per test case | TC-1, TC-2, TC-6 |
