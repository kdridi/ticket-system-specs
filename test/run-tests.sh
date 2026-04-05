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

# --- Main ---

echo "ticket-system-specs test harness"
echo "================================"
echo ""

test_validate_sh
test_validate_spec_sh
test_validate_tests
test_init_project_structure

print_summary
