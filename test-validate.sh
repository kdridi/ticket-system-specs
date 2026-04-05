#!/bin/bash
# test-validate.sh — Test harness for validate.sh
# Runs all test cases and reports results.
# Usage: bash test-validate.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VALIDATE="$SCRIPT_DIR/validate.sh"
TEST_DIR=""
PASS_COUNT=0
FAIL_COUNT=0
ERRORS=""

# --- Helpers ---

setup_test_dir() {
  TEST_DIR="$(mktemp -d)"
}

teardown_test_dir() {
  if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
  TEST_DIR=""
}

record_pass() {
  local name="$1"
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  [PASS] $name"
}

record_fail() {
  local name="$1"
  local detail="$2"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  ERRORS="${ERRORS}\n  [FAIL] $name: $detail"
  echo "  [FAIL] $name: $detail"
}

# Create the minimal valid generated output tree with all required files,
# correct frontmatter, valid content patterns, and executable permissions.
create_valid_output() {
  local dir="$1"

  # Root files
  touch "$dir/ARCHITECTURE.md"

  # install.sh — must be executable, have shebang, prompt for directory, use CLAUDE_DIR
  cat > "$dir/install.sh" <<'INST'
#!/bin/bash
# Prompt for installation directory
read -p "Enter installation directory [$HOME/.claude]: " INSTALL_DIR
INSTALL_DIR="${INSTALL_DIR:-$HOME/.claude}"
CLAUDE_DIR="$INSTALL_DIR"
mkdir -p "$CLAUDE_DIR/hooks"
cp hooks/validate-git-worktree.sh "$CLAUDE_DIR/hooks/"
# Merge PreToolUse config into settings.json
echo "Installed to $CLAUDE_DIR"
INST
  chmod +x "$dir/install.sh"

  # init-project.sh — must be executable, have shebang, accept prefix, create structure
  cat > "$dir/init-project.sh" <<'INIT'
#!/bin/bash
PREFIX="${1:-PROJ}"
mkdir -p tickets/{backlog,planned,ongoing,completed,rejected}
# Generate TEMPLATE.md with pipe-separated enums
cat > tickets/TEMPLATE.md <<TMPL
---
priority: P0 | P1 | P2
type: feature | bugfix | refactor | docs | research | infrastructure
status: backlog | planned | ongoing | completed | rejected
---
TMPL
# Add .worktrees/ to .gitignore if not present
grep -q '.worktrees/' .gitignore 2>/dev/null || echo '.worktrees/' >> .gitignore
INIT
  chmod +x "$dir/init-project.sh"

  # Hooks
  mkdir -p "$dir/hooks"
  cat > "$dir/hooks/validate-git-worktree.sh" <<'HOOK'
#!/bin/bash
# Read JSON from stdin
read -r INPUT
# Extract command and cwd using grep/sed fallback (no jq required)
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | sed 's/"command":"//;s/"//')
CWD=$(echo "$INPUT" | grep -o '"cwd":"[^"]*"' | sed 's/"cwd":"//;s/"//')
# Handle mkdir commands
if echo "$COMMAND" | grep -q '^mkdir'; then
  if echo "$COMMAND" | grep -q '\-worktree'; then
    echo '{"permissionDecision":"allow"}'
    exit 0
  fi
fi
# Handle git worktree commands
if echo "$COMMAND" | grep -q '^git worktree list'; then
  echo '{"permissionDecision":"allow"}'
  exit 0
fi
if echo "$COMMAND" | grep -q '^git worktree add'; then
  if echo "$COMMAND" | grep -q '\-worktree'; then
    echo '{"permissionDecision":"allow"}'
    exit 0
  fi
  echo '{"permissionDecision":"deny"}'
  exit 0
fi
if echo "$COMMAND" | grep -q '^git worktree remove\|^git worktree prune'; then
  echo '{"permissionDecision":"allow"}'
  exit 0
fi
# Handle git -C <path>
if echo "$COMMAND" | grep -q '^git -C'; then
  GITPATH=$(echo "$COMMAND" | sed 's/^git -C \([^ ]*\).*/\1/')
  # Resolve to absolute
  case "$GITPATH" in
    /*) ABSPATH="$GITPATH" ;;
    *)  ABSPATH="$CWD/$GITPATH" ;;
  esac
  BASENAME=$(basename "$ABSPATH")
  if echo "$BASENAME" | grep -q '\-worktree$'; then
    echo '{"permissionDecision":"allow"}'
    exit 0
  fi
  echo '{"permissionDecision":"deny"}'
  exit 0
fi
# Fall through — allow other commands
echo '{"permissionDecision":"allow"}'
HOOK
  chmod +x "$dir/hooks/validate-git-worktree.sh"

  # Agents — 6 agents with correct frontmatter
  mkdir -p "$dir/agents"

  # Reader — permissionMode: plan
  cat > "$dir/agents/ticket-system-reader.md" <<'AGENT'
---
skills: [ticket-system-conventions]
permissionMode: plan
tools:
  - Read
  - Glob
  - Grep
  - Bash(git log:*):
  - Bash(git status:*):
  - Bash(date:*):
---
# ticket-system-reader
AGENT

  # Editor — permissionMode: bypassPermissions
  cat > "$dir/agents/ticket-system-editor.md" <<'AGENT'
---
skills: [ticket-system-conventions]
permissionMode: bypassPermissions
tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(git *):
  - Bash(date *):
  - Bash(mkdir *):
---
# ticket-system-editor
AGENT

  # Planner — permissionMode: bypassPermissions
  cat > "$dir/agents/ticket-system-planner.md" <<'AGENT'
---
skills: [ticket-system-conventions]
permissionMode: bypassPermissions
tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(git *):
  - Bash(date *):
  - Bash(mkdir *):
---
# ticket-system-planner
AGENT

  # Coder — permissionMode: bypassPermissions, NO tools field
  cat > "$dir/agents/ticket-system-coder.md" <<'AGENT'
---
skills: [ticket-system-conventions]
permissionMode: bypassPermissions
---
# ticket-system-coder
AGENT

  # Verifier — permissionMode: bypassPermissions
  cat > "$dir/agents/ticket-system-verifier.md" <<'AGENT'
---
skills: [ticket-system-conventions]
permissionMode: bypassPermissions
tools:
  - Read
  - Glob
  - Grep
  - Bash(git *):
  - Bash(date *):
---
# ticket-system-verifier
AGENT

  # Ops — permissionMode: bypassPermissions
  cat > "$dir/agents/ticket-system-ops.md" <<'AGENT'
---
skills: [ticket-system-conventions]
permissionMode: bypassPermissions
tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(git *):
  - Bash(date *):
  - Bash(mkdir *):
---
# ticket-system-ops
AGENT

  # Skills — 11 skill directories, each with SKILL.md
  local skills=(
    ticket-system-conventions
    ticket-system-create
    ticket-system-help
    ticket-system-schedule
    ticket-system-plan
    ticket-system-implement
    ticket-system-verify
    ticket-system-merge
    ticket-system-run
    ticket-system-abort
    ticket-system-doctor
  )

  for skill in "${skills[@]}"; do
    mkdir -p "$dir/skills/$skill"
  done

  # conventions — user-invocable: false
  cat > "$dir/skills/ticket-system-conventions/SKILL.md" <<'SKILL'
---
context: fork
agent: ticket-system-reader
user-invocable: false
disable-model-invocation: false
---
# Ticket System Conventions
Shared conventions.
SKILL

  # create
  cat > "$dir/skills/ticket-system-create/SKILL.md" <<'SKILL'
---
context: fork
agent: ticket-system-editor
disable-model-invocation: false
---
# /ticket-system-create
Create a ticket. Writes .tickets/.pending before starting. Deletes .tickets/.pending on completion.
SKILL

  # help
  cat > "$dir/skills/ticket-system-help/SKILL.md" <<'SKILL'
---
context: fork
agent: ticket-system-reader
disable-model-invocation: false
---
# /ticket-system-help
Show help.
SKILL

  # schedule — must have AskUserQuestion, writes .pending
  cat > "$dir/skills/ticket-system-schedule/SKILL.md" <<'SKILL'
---
context: fork
agent: ticket-system-editor
disable-model-invocation: false
---
# /ticket-system-schedule
Schedule a ticket. Write .tickets/.pending before multi-step work. Use AskUserQuestion to get human approval. Self-evaluate before engaging user. Delete .tickets/.pending on success.
SKILL

  # plan — must have AskUserQuestion, writes .pending
  cat > "$dir/skills/ticket-system-plan/SKILL.md" <<'SKILL'
---
context: fork
agent: ticket-system-planner
disable-model-invocation: false
---
# /ticket-system-plan
Plan a ticket. Write .tickets/.pending before multi-step work. Use AskUserQuestion for human gate after plan generation. Delete .tickets/.pending on success.
SKILL

  # implement — must check prerequisites
  cat > "$dir/skills/ticket-system-implement/SKILL.md" <<'SKILL'
---
context: fork
agent: ticket-system-coder
disable-model-invocation: false
---
# /ticket-system-implement
Implement a ticket. Check prerequisites before starting.
SKILL

  # verify — must contain NEVER modify
  cat > "$dir/skills/ticket-system-verify/SKILL.md" <<'SKILL'
---
context: fork
agent: ticket-system-verifier
disable-model-invocation: false
---
# /ticket-system-verify
Verify a ticket. NEVER modify code. Move ticket to completed/ on PASS.
SKILL

  # merge — must verify completed status, writes .pending
  cat > "$dir/skills/ticket-system-merge/SKILL.md" <<'SKILL'
---
context: fork
agent: ticket-system-ops
disable-model-invocation: false
---
# /ticket-system-merge
Merge a ticket. Verify ticket is in completed/ before merging. Write .tickets/.pending before multi-step work. Delete .tickets/.pending on success.
SKILL

  # run — must chain plan/implement/verify/merge, handle --yes
  cat > "$dir/skills/ticket-system-run/SKILL.md" <<'SKILL'
---
context: fork
agent: ticket-system-coder
disable-model-invocation: false
---
# /ticket-system-run
Orchestrate full pipeline: plan, implement, verify, merge. Verify filesystem state after each step. Stop on failure. Forward --yes to plan sub-skill.
SKILL

  # abort — disable-model-invocation: true, AskUserQuestion confirmation
  cat > "$dir/skills/ticket-system-abort/SKILL.md" <<'SKILL'
---
context: fork
agent: ticket-system-ops
disable-model-invocation: true
---
# /ticket-system-abort
Abort a ticket. Use AskUserQuestion confirmation gate. Destructive action. Write .tickets/.pending before multi-step work. Delete .tickets/.pending on success.
SKILL

  # doctor — read-only, checks .pending
  cat > "$dir/skills/ticket-system-doctor/SKILL.md" <<'SKILL'
---
context: fork
agent: ticket-system-reader
disable-model-invocation: false
---
# /ticket-system-doctor
Run diagnostics. NO file modifications. Check .tickets/.pending as first diagnostic step.
SKILL
}

# ============================================================
# TEST CASES
# ============================================================

echo "=== Running validate.sh tests ==="
echo ""

# --- TC-1: Script exists and is executable ---
echo "TC-1: Script exists and is executable"
if [ ! -f "$VALIDATE" ]; then
  record_fail "TC-1" "validate.sh does not exist"
elif [ ! -x "$VALIDATE" ]; then
  record_fail "TC-1" "validate.sh is not executable"
elif ! head -1 "$VALIDATE" | grep -q '^#!/bin/bash'; then
  record_fail "TC-1" "validate.sh missing #!/bin/bash shebang"
else
  record_pass "TC-1"
fi

# --- TC-2: Rejects missing directory argument ---
echo "TC-2: Rejects missing directory argument"
OUTPUT=$(bash "$VALIDATE" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ] && echo "$OUTPUT" | grep -qi 'usage\|error\|argument'; then
  record_pass "TC-2"
else
  record_fail "TC-2" "Expected non-zero exit and usage message, got exit=$EXIT_CODE"
fi

# --- TC-3: Rejects non-existent directory ---
echo "TC-3: Rejects non-existent directory"
OUTPUT=$(bash "$VALIDATE" "/tmp/nonexistent-dir-validate-test-$$" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  record_pass "TC-3"
else
  record_fail "TC-3" "Expected non-zero exit for nonexistent dir, got exit=0"
fi

# --- TC-4: All structural files present ---
echo "TC-4: All structural files present"
setup_test_dir
create_valid_output "$TEST_DIR"
OUTPUT=$(bash "$VALIDATE" "$TEST_DIR" 2>&1)
EXIT_CODE=$?
STRUCT_FAILS=$(echo "$OUTPUT" | grep '\[FAIL\]' | grep -i 'file\|exist\|missing\|struct' || true)
if [ $EXIT_CODE -eq 0 ] && [ -z "$STRUCT_FAILS" ]; then
  record_pass "TC-4"
else
  record_fail "TC-4" "Valid output had failures: $STRUCT_FAILS (exit=$EXIT_CODE)"
fi
teardown_test_dir

# --- TC-5: Missing file detected ---
echo "TC-5: Missing file detected"
setup_test_dir
create_valid_output "$TEST_DIR"
rm -f "$TEST_DIR/agents/ticket-system-verifier.md"
OUTPUT=$(bash "$VALIDATE" "$TEST_DIR" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ] && echo "$OUTPUT" | grep -q '\[FAIL\]'; then
  record_pass "TC-5"
else
  record_fail "TC-5" "Missing agent not detected (exit=$EXIT_CODE)"
fi
teardown_test_dir

# --- TC-6: Executable scripts pass permission check ---
echo "TC-6: Executable scripts pass permission check"
setup_test_dir
create_valid_output "$TEST_DIR"
OUTPUT=$(bash "$VALIDATE" "$TEST_DIR" 2>&1)
PERM_FAILS=$(echo "$OUTPUT" | grep '\[FAIL\]' | grep -i 'execut\|permiss\|shebang' || true)
if [ -z "$PERM_FAILS" ]; then
  record_pass "TC-6"
else
  record_fail "TC-6" "Permission checks failed: $PERM_FAILS"
fi
teardown_test_dir

# --- TC-7: Non-executable script detected ---
echo "TC-7: Non-executable script detected"
setup_test_dir
create_valid_output "$TEST_DIR"
chmod -x "$TEST_DIR/install.sh"
OUTPUT=$(bash "$VALIDATE" "$TEST_DIR" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ] && echo "$OUTPUT" | grep '\[FAIL\]' | grep -qi 'install.sh.*execut\|execut.*install.sh'; then
  record_pass "TC-7"
else
  record_fail "TC-7" "Non-executable install.sh not detected (exit=$EXIT_CODE)"
fi
teardown_test_dir

# --- TC-8: Valid agent frontmatter passes ---
echo "TC-8: Valid agent frontmatter passes"
setup_test_dir
create_valid_output "$TEST_DIR"
OUTPUT=$(bash "$VALIDATE" "$TEST_DIR" 2>&1)
AGENT_FAILS=$(echo "$OUTPUT" | grep '\[FAIL\]' | grep -i 'agent\|frontmatter\|skills\|permission' || true)
if [ -z "$AGENT_FAILS" ]; then
  record_pass "TC-8"
else
  record_fail "TC-8" "Agent frontmatter checks failed: $AGENT_FAILS"
fi
teardown_test_dir

# --- TC-9: Agent missing skills field detected ---
echo "TC-9: Agent missing skills field detected"
setup_test_dir
create_valid_output "$TEST_DIR"
# Remove skills line from reader agent
sed -i.bak '/skills:/d' "$TEST_DIR/agents/ticket-system-reader.md"
OUTPUT=$(bash "$VALIDATE" "$TEST_DIR" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ] && echo "$OUTPUT" | grep '\[FAIL\]' | grep -qi 'skills'; then
  record_pass "TC-9"
else
  record_fail "TC-9" "Missing skills field not detected (exit=$EXIT_CODE)"
fi
teardown_test_dir

# --- TC-10: Valid skill frontmatter passes ---
echo "TC-10: Valid skill frontmatter passes"
setup_test_dir
create_valid_output "$TEST_DIR"
OUTPUT=$(bash "$VALIDATE" "$TEST_DIR" 2>&1)
SKILL_FAILS=$(echo "$OUTPUT" | grep '\[FAIL\]' | grep -i 'skill.*context\|skill.*agent\|context.*fork' || true)
if [ -z "$SKILL_FAILS" ]; then
  record_pass "TC-10"
else
  record_fail "TC-10" "Skill frontmatter checks failed: $SKILL_FAILS"
fi
teardown_test_dir

# --- TC-11: Skill missing context: fork detected ---
echo "TC-11: Skill missing context: fork detected"
setup_test_dir
create_valid_output "$TEST_DIR"
sed -i.bak '/context: fork/d' "$TEST_DIR/skills/ticket-system-create/SKILL.md"
OUTPUT=$(bash "$VALIDATE" "$TEST_DIR" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ] && echo "$OUTPUT" | grep '\[FAIL\]' | grep -qi 'context'; then
  record_pass "TC-11"
else
  record_fail "TC-11" "Missing context: fork not detected (exit=$EXIT_CODE)"
fi
teardown_test_dir

# --- TC-12: Clean output passes hardcoded value check ---
echo "TC-12: Clean output passes hardcoded value check"
setup_test_dir
create_valid_output "$TEST_DIR"
OUTPUT=$(bash "$VALIDATE" "$TEST_DIR" 2>&1)
HARD_FAILS=$(echo "$OUTPUT" | grep '\[FAIL\]' | grep -i 'hardcod' || true)
if [ -z "$HARD_FAILS" ]; then
  record_pass "TC-12"
else
  record_fail "TC-12" "Clean output had hardcoded value failures: $HARD_FAILS"
fi
teardown_test_dir

# --- TC-13: Hardcoded prefix detected ---
echo "TC-13: Hardcoded prefix detected"
setup_test_dir
create_valid_output "$TEST_DIR"
echo "Handle PROJ-001 ticket" >> "$TEST_DIR/agents/ticket-system-editor.md"
OUTPUT=$(bash "$VALIDATE" "$TEST_DIR" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ] && echo "$OUTPUT" | grep '\[FAIL\]' | grep -qi 'hardcod.*prefix'; then
  record_pass "TC-13"
else
  record_fail "TC-13" "Hardcoded prefix not detected (exit=$EXIT_CODE)"
fi
teardown_test_dir

# --- TC-14: Behavioral checks pass for valid skills ---
echo "TC-14: Behavioral checks pass for valid skills"
setup_test_dir
create_valid_output "$TEST_DIR"
OUTPUT=$(bash "$VALIDATE" "$TEST_DIR" 2>&1)
BEHAV_FAILS=$(echo "$OUTPUT" | grep '\[FAIL\]' | grep -i 'behav\|AskUser\|NEVER\|prerequis\|complet\|chain\|pending' || true)
if [ -z "$BEHAV_FAILS" ]; then
  record_pass "TC-14"
else
  record_fail "TC-14" "Behavioral checks failed: $BEHAV_FAILS"
fi
teardown_test_dir

# --- TC-15: Missing human gate detected ---
echo "TC-15: Missing human gate detected"
setup_test_dir
create_valid_output "$TEST_DIR"
sed -i.bak 's/AskUserQuestion/ApprovalStep/g' "$TEST_DIR/skills/ticket-system-schedule/SKILL.md"
OUTPUT=$(bash "$VALIDATE" "$TEST_DIR" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ] && echo "$OUTPUT" | grep '\[FAIL\]' | grep -qi 'AskUser\|human.*gate\|schedule'; then
  record_pass "TC-15"
else
  record_fail "TC-15" "Missing human gate not detected (exit=$EXIT_CODE)"
fi
teardown_test_dir

# --- TC-16: Absent conditional feature is skipped ---
echo "TC-16: Absent conditional feature is skipped"
setup_test_dir
create_valid_output "$TEST_DIR"
# Remove an optional skill (ticket-system-next does not exist in our valid output)
# The test checks that absent optional features get SKIP, not FAIL
OUTPUT=$(bash "$VALIDATE" "$TEST_DIR" 2>&1)
SKIP_COUNT=$(echo "$OUTPUT" | grep -c '\[SKIP\]' || true)
if [ "$SKIP_COUNT" -gt 0 ]; then
  record_pass "TC-16"
else
  record_fail "TC-16" "No SKIP results found for conditional features"
fi
teardown_test_dir

# --- TC-17: Valid hook passes content checks ---
echo "TC-17: Valid hook passes content checks"
setup_test_dir
create_valid_output "$TEST_DIR"
OUTPUT=$(bash "$VALIDATE" "$TEST_DIR" 2>&1)
HOOK_FAILS=$(echo "$OUTPUT" | grep '\[FAIL\]' | grep -i 'hook' || true)
if [ -z "$HOOK_FAILS" ]; then
  record_pass "TC-17"
else
  record_fail "TC-17" "Hook checks failed: $HOOK_FAILS"
fi
teardown_test_dir

# --- TC-18: Hook with hardcoded prefix detected ---
echo "TC-18: Hook with hardcoded prefix detected"
setup_test_dir
create_valid_output "$TEST_DIR"
echo 'EXPECTED_PREFIX="TS-"' >> "$TEST_DIR/hooks/validate-git-worktree.sh"
OUTPUT=$(bash "$VALIDATE" "$TEST_DIR" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ] && echo "$OUTPUT" | grep '\[FAIL\]' | grep -qi 'hook.*hardcod\|hardcod.*hook\|prefix.*hook\|hook.*prefix'; then
  record_pass "TC-18"
else
  record_fail "TC-18" "Hook hardcoded prefix not detected (exit=$EXIT_CODE)"
fi
teardown_test_dir

# --- TC-19: Valid install.sh passes content checks ---
echo "TC-19: Valid install.sh passes content checks"
setup_test_dir
create_valid_output "$TEST_DIR"
OUTPUT=$(bash "$VALIDATE" "$TEST_DIR" 2>&1)
SCRIPT_FAILS=$(echo "$OUTPUT" | grep '\[FAIL\]' | grep -i 'install.sh\|init-project.sh\|script.*content' || true)
if [ -z "$SCRIPT_FAILS" ]; then
  record_pass "TC-19"
else
  record_fail "TC-19" "Script content checks failed: $SCRIPT_FAILS"
fi
teardown_test_dir

# --- TC-20: install.sh missing directory prompt detected ---
echo "TC-20: install.sh missing directory prompt detected"
setup_test_dir
create_valid_output "$TEST_DIR"
# Replace install.sh with one missing directory prompt
cat > "$TEST_DIR/install.sh" <<'NOPROMPT'
#!/bin/bash
cp -r agents/ ~/.claude/agents/
NOPROMPT
chmod +x "$TEST_DIR/install.sh"
OUTPUT=$(bash "$VALIDATE" "$TEST_DIR" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ] && echo "$OUTPUT" | grep '\[FAIL\]' | grep -qi 'install.*prompt\|install.*director\|prompt.*install'; then
  record_pass "TC-20"
else
  record_fail "TC-20" "Missing install.sh directory prompt not detected (exit=$EXIT_CODE)"
fi
teardown_test_dir

# --- TC-21: Full valid output — zero exit code ---
echo "TC-21: Full valid output — zero exit code"
setup_test_dir
create_valid_output "$TEST_DIR"
OUTPUT=$(bash "$VALIDATE" "$TEST_DIR" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
  record_pass "TC-21"
else
  FAILURES=$(echo "$OUTPUT" | grep '\[FAIL\]')
  record_fail "TC-21" "Valid output exited non-zero ($EXIT_CODE). Failures: $FAILURES"
fi
teardown_test_dir

# --- TC-22: No external dependencies used ---
echo "TC-22: No external dependencies used"
if grep -qE '\b(python|node|jq|ruby|perl|npm|pip)\b' "$VALIDATE"; then
  record_fail "TC-22" "Script references non-POSIX tools"
else
  record_pass "TC-22"
fi

# --- TC-23: Pending file checks in mutative commands ---
echo "TC-23: Pending file checks in mutative commands"
setup_test_dir
create_valid_output "$TEST_DIR"
OUTPUT=$(bash "$VALIDATE" "$TEST_DIR" 2>&1)
PENDING_FAILS=$(echo "$OUTPUT" | grep '\[FAIL\]' | grep -i 'pending' || true)
if [ -z "$PENDING_FAILS" ]; then
  record_pass "TC-23"
else
  record_fail "TC-23" "Pending file checks failed: $PENDING_FAILS"
fi
teardown_test_dir

# ============================================================
# SUMMARY
# ============================================================

echo ""
echo "=== Test Summary ==="
echo "  PASS: $PASS_COUNT"
echo "  FAIL: $FAIL_COUNT"
if [ $FAIL_COUNT -gt 0 ]; then
  echo ""
  echo "  Failures:"
  echo -e "$ERRORS"
  echo ""
  exit 1
fi
echo ""
echo "All tests passed."
exit 0
