#!/bin/bash
# run-tests.sh — Test harness for the ticket-system-specs project.
# Provisions isolated repos, runs structural checks, and tears down.
# Usage: bash test/run-tests.sh
#        GENERATED_OUTPUT_DIR=/path/to/output bash test/run-tests.sh

set -euo pipefail

# --- Path resolution ---

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Counters and reporting ---

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

record_pass() {
  local name="$1"
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  [PASS] $name"
}

record_fail() {
  local name="$1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "  [FAIL] $name"
}

record_skip() {
  local name="$1"
  local reason="$2"
  SKIP_COUNT=$((SKIP_COUNT + 1))
  echo "  [SKIP] $name — $reason"
}

# --- Assertion helpers for command coverage tests ---

assert_file_exists() {
  local file_path="$1"
  local label="$2"
  if [ -e "$file_path" ]; then
    record_pass "$label"
  else
    record_fail "$label (file not found: $file_path)"
  fi
}

assert_file_not_exists() {
  local file_path="$1"
  local label="$2"
  if [ ! -e "$file_path" ]; then
    record_pass "$label"
  else
    record_fail "$label (file unexpectedly exists: $file_path)"
  fi
}

assert_frontmatter_field() {
  local file_path="$1"
  local field="$2"
  local expected="$3"
  local label="$4"
  if [ ! -f "$file_path" ]; then
    record_fail "$label (file not found: $file_path)"
    return
  fi
  # Extract frontmatter value: find line matching "^field: value" between --- delimiters
  # Handles both quoted and unquoted values
  local actual
  actual=$(sed -n '/^---$/,/^---$/{ /^'"$field"':/{ s/^'"$field"': *//; s/^"//; s/"$//; s/^ *//; p; } }' "$file_path" | head -1)
  if [ "$actual" = "$expected" ]; then
    record_pass "$label"
  else
    record_fail "$label (expected '$expected', got '$actual')"
  fi
}

assert_file_contains() {
  local file_path="$1"
  local pattern="$2"
  local label="$3"
  if [ ! -f "$file_path" ]; then
    record_fail "$label (file not found: $file_path)"
    return
  fi
  if grep -q "$pattern" "$file_path" 2>/dev/null; then
    record_pass "$label"
  else
    record_fail "$label (pattern not found: $pattern)"
  fi
}

# --- Setup and teardown ---

TEST_ENV_DIR=""

setup_test_env() {
  TEST_ENV_DIR="$(mktemp -d)"
  echo "  Setup: created temp dir $TEST_ENV_DIR"
  git init "$TEST_ENV_DIR" --quiet
  # Create an initial commit so worktree operations work
  git -C "$TEST_ENV_DIR" commit --allow-empty -m "Initial commit" --quiet
  # Run init-project.sh if available in GENERATED_OUTPUT_DIR
  if [ -n "${GENERATED_OUTPUT_DIR:-}" ] && [ -f "$GENERATED_OUTPUT_DIR/init-project.sh" ]; then
    (cd "$TEST_ENV_DIR" && bash "$GENERATED_OUTPUT_DIR/init-project.sh")
  fi
}

teardown_test_env() {
  if [ -n "$TEST_ENV_DIR" ] && [ -d "$TEST_ENV_DIR" ]; then
    rm -rf "$TEST_ENV_DIR"
    echo "  Teardown: removed $TEST_ENV_DIR"
  fi
  TEST_ENV_DIR=""
}

trap teardown_test_env EXIT

# --- Summary ---

print_summary() {
  echo ""
  echo "========================================"
  echo "  Test Summary"
  echo "========================================"
  echo "  PASS: $PASS_COUNT"
  echo "  FAIL: $FAIL_COUNT"
  echo "  SKIP: $SKIP_COUNT"
  echo "  TOTAL: $((PASS_COUNT + FAIL_COUNT + SKIP_COUNT))"
  echo "========================================"
  if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "  RESULT: FAILED"
    return 1
  else
    echo "  RESULT: PASSED"
    return 0
  fi
}

# --- Test: validate.sh against generated output ---

test_validate_sh() {
  echo "Test: validate.sh against generated output"
  if [ -z "${GENERATED_OUTPUT_DIR:-}" ]; then
    record_skip "validate.sh" "Set GENERATED_OUTPUT_DIR=/path/to/output to enable"
    return
  fi
  if [ ! -d "$GENERATED_OUTPUT_DIR" ]; then
    record_fail "validate.sh — GENERATED_OUTPUT_DIR does not exist: $GENERATED_OUTPUT_DIR"
    return
  fi
  if bash "$PROJECT_ROOT/validate.sh" "$GENERATED_OUTPUT_DIR" > /dev/null 2>&1; then
    record_pass "validate.sh"
  else
    record_fail "validate.sh"
  fi
}

# --- Test: validate-spec.sh ---

test_validate_spec_sh() {
  echo "Test: validate-spec.sh"
  if [ ! -f "$PROJECT_ROOT/validate-spec.sh" ]; then
    record_skip "validate-spec.sh" "Script not found"
    return
  fi
  if bash "$PROJECT_ROOT/validate-spec.sh" > /dev/null 2>&1; then
    record_pass "validate-spec.sh"
  else
    record_fail "validate-spec.sh"
  fi
}

# --- Test: test-validate.sh ---

test_validate_tests() {
  echo "Test: test-validate.sh"
  if [ ! -f "$PROJECT_ROOT/test-validate.sh" ]; then
    record_skip "test-validate.sh" "Script not found"
    return
  fi
  if bash "$PROJECT_ROOT/test-validate.sh" > /dev/null 2>&1; then
    record_pass "test-validate.sh"
  else
    record_fail "test-validate.sh"
  fi
}

# --- Test: init-project.sh structural verification ---

test_init_project_structure() {
  echo "Test: init-project.sh structural verification"
  if [ -z "${GENERATED_OUTPUT_DIR:-}" ] || [ ! -f "${GENERATED_OUTPUT_DIR}/init-project.sh" ]; then
    record_skip "init-project.sh structure" "Set GENERATED_OUTPUT_DIR with init-project.sh to enable"
    return
  fi

  setup_test_env

  # Verify expected directories exist
  local dirs=("tickets/backlog" "tickets/planned" "tickets/ongoing" "tickets/completed" "tickets/rejected")
  for dir in "${dirs[@]}"; do
    if [ -d "$TEST_ENV_DIR/$dir" ]; then
      record_pass "init-project: $dir/ exists"
    else
      record_fail "init-project: $dir/ missing"
    fi
  done

  # Verify .tickets/config.yml exists
  if [ -f "$TEST_ENV_DIR/.tickets/config.yml" ]; then
    record_pass "init-project: .tickets/config.yml exists"
  else
    record_skip "init-project: .tickets/config.yml" "init-project.sh may not create config"
  fi

  # Verify .gitignore contains .worktrees/
  if [ -f "$TEST_ENV_DIR/.gitignore" ] && grep -q '\.worktrees/' "$TEST_ENV_DIR/.gitignore" 2>/dev/null; then
    record_pass "init-project: .gitignore has .worktrees/"
  else
    record_fail "init-project: .gitignore missing .worktrees/ entry"
  fi

  # Verify .gitkeep files exist
  local gitkeep_found=0
  for dir in "${dirs[@]}"; do
    if [ -f "$TEST_ENV_DIR/$dir/.gitkeep" ]; then
      gitkeep_found=$((gitkeep_found + 1))
    fi
  done
  if [ "$gitkeep_found" -eq "${#dirs[@]}" ]; then
    record_pass "init-project: .gitkeep files in all ticket dirs"
  else
    record_fail "init-project: .gitkeep files missing ($gitkeep_found/${#dirs[@]} found)"
  fi

  teardown_test_env
}

# --- Command coverage tests (require MANUAL_TEST_DIR) ---

# /ticket-system-create test
# Manual step: Run `/ticket-system-create` with arguments:
#   title="Test ticket", type=feature, priority=P1
# Then set MANUAL_TEST_DIR to the project root and MANUAL_TEST_TICKET_ID
# to the created ticket ID (e.g., PROJ-001).

test_create_command() {
  echo "Test: /ticket-system-create command coverage"
  if [ -z "${MANUAL_TEST_DIR:-}" ]; then
    record_skip "create command" "Set MANUAL_TEST_DIR to enable command coverage tests"
    return
  fi
  if [ -z "${MANUAL_TEST_TICKET_ID:-}" ]; then
    record_skip "create command" "Set MANUAL_TEST_TICKET_ID to the created ticket ID"
    return
  fi

  local ticket_file="$MANUAL_TEST_DIR/tickets/backlog/${MANUAL_TEST_TICKET_ID}.md"

  # Expected outcomes:
  # 1. A new .md file appears in tickets/backlog/ matching PREFIX-NNN.md
  assert_file_exists "$ticket_file" "create: ticket file exists in backlog"

  # 2. Frontmatter contains status: backlog
  assert_frontmatter_field "$ticket_file" "status" "backlog" "create: status is backlog"

  # 3. Frontmatter contains type: feature
  assert_frontmatter_field "$ticket_file" "type" "feature" "create: type is feature"

  # 4. Frontmatter contains priority: P1
  assert_frontmatter_field "$ticket_file" "priority" "P1" "create: priority is P1"

  # 5. Title field matches the provided title
  assert_file_contains "$ticket_file" "Test ticket" "create: title contains expected text"

  # 6. A log entry with "Ticket created" exists
  assert_file_contains "$ticket_file" "Ticket created" "create: log contains 'Ticket created'"
}

# /ticket-system-schedule test
# Prerequisites: A ticket must exist in tickets/backlog/
# Manual step: Run `/ticket-system-schedule PREFIX-NNN --yes`
# Then set MANUAL_TEST_DIR and MANUAL_TEST_SCHEDULED_ID.

test_schedule_command() {
  echo "Test: /ticket-system-schedule command coverage"
  if [ -z "${MANUAL_TEST_DIR:-}" ]; then
    record_skip "schedule command" "Set MANUAL_TEST_DIR to enable command coverage tests"
    return
  fi
  if [ -z "${MANUAL_TEST_SCHEDULED_ID:-}" ]; then
    record_skip "schedule command" "Set MANUAL_TEST_SCHEDULED_ID to the scheduled ticket ID"
    return
  fi

  local planned_file="$MANUAL_TEST_DIR/tickets/planned/${MANUAL_TEST_SCHEDULED_ID}.md"
  local backlog_file="$MANUAL_TEST_DIR/tickets/backlog/${MANUAL_TEST_SCHEDULED_ID}.md"
  local roadmap_file="$MANUAL_TEST_DIR/tickets/planned/roadmap.yml"

  # Expected outcomes:
  # 1. Ticket file moves from backlog/ to planned/
  assert_file_exists "$planned_file" "schedule: ticket file exists in planned"
  assert_file_not_exists "$backlog_file" "schedule: ticket file removed from backlog"

  # 2. Frontmatter status changes to planned
  assert_frontmatter_field "$planned_file" "status" "planned" "schedule: status is planned"

  # 3. Frontmatter updated timestamp is refreshed (we just check it exists)
  assert_file_contains "$planned_file" "^updated:" "schedule: updated timestamp present"

  # 4. An entry is added to roadmap.yml with the ticket's ID
  assert_file_exists "$roadmap_file" "schedule: roadmap.yml exists"
  assert_file_contains "$roadmap_file" "$MANUAL_TEST_SCHEDULED_ID" "schedule: ticket ID in roadmap.yml"

  # 5. A log entry with scheduling information exists
  assert_file_contains "$planned_file" "[Ss]chedul" "schedule: log contains scheduling entry"
}

# /ticket-system-plan test
# Prerequisites: A ticket must be in tickets/planned/ and in roadmap.yml,
#   tickets/ongoing/ must be empty, all dependencies completed
# Manual step: Run `/ticket-system-plan PREFIX-NNN --yes`
# Then set MANUAL_TEST_DIR and MANUAL_TEST_PLANNED_ID.

test_plan_command() {
  echo "Test: /ticket-system-plan command coverage"
  if [ -z "${MANUAL_TEST_DIR:-}" ]; then
    record_skip "plan command" "Set MANUAL_TEST_DIR to enable command coverage tests"
    return
  fi
  if [ -z "${MANUAL_TEST_PLANNED_ID:-}" ]; then
    record_skip "plan command" "Set MANUAL_TEST_PLANNED_ID to the planned ticket ID"
    return
  fi

  local worktree_dir="$MANUAL_TEST_DIR/.worktrees/${MANUAL_TEST_PLANNED_ID}-worktree"
  local ticket_dir="$worktree_dir/tickets/ongoing/${MANUAL_TEST_PLANNED_ID}"

  # Expected outcomes:
  # 1. A worktree exists at .worktrees/PREFIX-NNN-worktree/
  assert_file_exists "$worktree_dir" "plan: worktree directory exists"

  # 2. Inside the worktree: tickets/ongoing/PREFIX-NNN/ticket.md exists
  assert_file_exists "$ticket_dir/ticket.md" "plan: ticket.md in ongoing dir"

  # 3. Inside the worktree: implementation-plan.md exists
  assert_file_exists "$ticket_dir/implementation-plan.md" "plan: implementation-plan.md exists"

  # 4. Inside the worktree: test-plan.md exists
  assert_file_exists "$ticket_dir/test-plan.md" "plan: test-plan.md exists"

  # 5. Ticket frontmatter has status: ongoing
  assert_frontmatter_field "$ticket_dir/ticket.md" "status" "ongoing" "plan: status is ongoing"

  # 6. The ticket's entry is removed from roadmap.yml in the worktree
  local worktree_roadmap="$worktree_dir/tickets/planned/roadmap.yml"
  if [ -f "$worktree_roadmap" ]; then
    if grep -q "$MANUAL_TEST_PLANNED_ID" "$worktree_roadmap" 2>/dev/null; then
      record_fail "plan: ticket ID still in worktree roadmap.yml"
    else
      record_pass "plan: ticket ID removed from worktree roadmap.yml"
    fi
  else
    record_pass "plan: roadmap.yml absent from worktree (acceptable if empty)"
  fi

  # 7. A git branch ticket/PREFIX-NNN exists
  if git -C "$MANUAL_TEST_DIR" branch --list "ticket/${MANUAL_TEST_PLANNED_ID}" | grep -q "ticket/${MANUAL_TEST_PLANNED_ID}" 2>/dev/null; then
    record_pass "plan: git branch ticket/${MANUAL_TEST_PLANNED_ID} exists"
  else
    record_fail "plan: git branch ticket/${MANUAL_TEST_PLANNED_ID} not found"
  fi
}

# --- Main ---

echo "ticket-system-specs test harness"
echo "================================"
echo ""

test_validate_sh
test_validate_spec_sh
test_validate_tests
test_init_project_structure

print_summary
