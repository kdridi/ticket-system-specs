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

# --- Main ---

echo "ticket-system-specs test harness"
echo "================================"
echo ""

print_summary
