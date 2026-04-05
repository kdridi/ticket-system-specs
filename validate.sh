#!/bin/bash
# validate.sh — Validates generated ticket-system output against specs.md section 8 checklist.
# Usage: bash validate.sh <path-to-generated-output-directory>
# Exits 0 if all checks pass, non-zero if any fail.

# --- Argument handling ---

if [ $# -lt 1 ]; then
  echo "Usage: validate.sh <generated-output-directory>"
  echo "Error: Missing directory argument."
  exit 1
fi

OUTPUT_DIR="$1"

if [ ! -d "$OUTPUT_DIR" ]; then
  echo "Error: Directory does not exist: $OUTPUT_DIR"
  exit 1
fi

# --- Reporting framework ---

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

check_pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "[PASS] $1"
}

check_fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "[FAIL] $1"
}

check_skip() {
  SKIP_COUNT=$((SKIP_COUNT + 1))
  echo "[SKIP] $1"
}

echo "Validating generated output: $OUTPUT_DIR"
echo ""

# ============================================================
# STRUCTURAL COMPLETENESS — all required files present
# ============================================================

echo "--- Structural completeness ---"

# Root files
for f in ARCHITECTURE.md install.sh init-project.sh; do
  if [ -f "$OUTPUT_DIR/$f" ]; then
    check_pass "File exists: $f"
  else
    check_fail "File missing: $f"
  fi
done

# Hooks
if [ -f "$OUTPUT_DIR/hooks/validate-git-worktree.sh" ]; then
  check_pass "File exists: hooks/validate-git-worktree.sh"
else
  check_fail "File missing: hooks/validate-git-worktree.sh"
fi

# Agents (6)
AGENTS=(
  ticket-system-reader
  ticket-system-editor
  ticket-system-planner
  ticket-system-coder
  ticket-system-verifier
  ticket-system-ops
)

for agent in "${AGENTS[@]}"; do
  if [ -f "$OUTPUT_DIR/agents/${agent}.md" ]; then
    check_pass "File exists: agents/${agent}.md"
  else
    check_fail "File missing: agents/${agent}.md"
  fi
done

# Skills (11), each with SKILL.md
SKILLS=(
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

for skill in "${SKILLS[@]}"; do
  if [ -f "$OUTPUT_DIR/skills/${skill}/SKILL.md" ]; then
    check_pass "File exists: skills/${skill}/SKILL.md"
  else
    check_fail "File missing: skills/${skill}/SKILL.md"
  fi
done

echo ""

# ============================================================
# SCRIPT PERMISSION CHECKS
# ============================================================

echo "--- Script permissions ---"

EXECUTABLES=(
  install.sh
  init-project.sh
  hooks/validate-git-worktree.sh
)

for f in "${EXECUTABLES[@]}"; do
  if [ ! -f "$OUTPUT_DIR/$f" ]; then
    check_fail "Cannot check permissions — file missing: $f"
    continue
  fi
  # Check shebang
  FIRST_LINE=$(head -1 "$OUTPUT_DIR/$f")
  if echo "$FIRST_LINE" | grep -q '^#!/bin/bash'; then
    check_pass "Shebang present: $f"
  else
    check_fail "Shebang missing (#!/bin/bash): $f"
  fi
  # Check executable
  if [ -x "$OUTPUT_DIR/$f" ]; then
    check_pass "Executable: $f"
  else
    check_fail "Not executable: $f"
  fi
done

echo ""

# ============================================================
# AGENT FRONTMATTER VALIDATION
# ============================================================

echo "--- Agent frontmatter ---"

for agent in "${AGENTS[@]}"; do
  AGENT_FILE="$OUTPUT_DIR/agents/${agent}.md"
  if [ ! -f "$AGENT_FILE" ]; then
    check_fail "Cannot validate agent frontmatter — file missing: ${agent}.md"
    continue
  fi

  # Check skills: [ticket-system-conventions]
  if grep -q 'skills:.*ticket-system-conventions' "$AGENT_FILE"; then
    check_pass "Agent ${agent} has skills: [ticket-system-conventions]"
  else
    check_fail "Agent ${agent} missing skills: [ticket-system-conventions]"
  fi

  # Check permissionMode
  if [ "$agent" = "ticket-system-reader" ]; then
    if grep -q 'permissionMode:.*plan' "$AGENT_FILE"; then
      check_pass "Agent ${agent} has permissionMode: plan"
    else
      check_fail "Agent ${agent} should have permissionMode: plan"
    fi
  else
    if grep -q 'permissionMode:.*bypassPermissions' "$AGENT_FILE"; then
      check_pass "Agent ${agent} has permissionMode: bypassPermissions"
    else
      check_fail "Agent ${agent} should have permissionMode: bypassPermissions"
    fi
  fi

  # Check tools field: coder should NOT have it, others should
  if [ "$agent" = "ticket-system-coder" ]; then
    if grep -q '^tools:' "$AGENT_FILE" || grep -q '^  - ' "$AGENT_FILE" | head -1 | grep -q 'tools'; then
      # More precise: check between --- markers
      FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$AGENT_FILE")
      if echo "$FRONTMATTER" | grep -q 'tools:'; then
        check_fail "Agent ${agent} should NOT have a tools field (needs unrestricted access)"
      else
        check_pass "Agent ${agent} has no tools field (correct)"
      fi
    else
      check_pass "Agent ${agent} has no tools field (correct)"
    fi
  else
    FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$AGENT_FILE")
    if echo "$FRONTMATTER" | grep -q 'tools:'; then
      check_pass "Agent ${agent} has a tools field"
    else
      check_fail "Agent ${agent} missing tools field"
    fi
  fi
done

echo ""

# ============================================================
# SKILL FRONTMATTER VALIDATION
# ============================================================

echo "--- Skill frontmatter ---"

for skill in "${SKILLS[@]}"; do
  SKILL_FILE="$OUTPUT_DIR/skills/${skill}/SKILL.md"
  if [ ! -f "$SKILL_FILE" ]; then
    check_fail "Cannot validate skill frontmatter — file missing: ${skill}/SKILL.md"
    continue
  fi

  # Check context: fork
  if grep -q 'context:.*fork' "$SKILL_FILE"; then
    check_pass "Skill ${skill} has context: fork"
  else
    check_fail "Skill ${skill} missing context: fork"
  fi

  # Check agent: <name>
  if grep -q 'agent:' "$SKILL_FILE"; then
    # Validate agent reference points to actual agent file
    AGENT_REF=$(grep 'agent:' "$SKILL_FILE" | head -1 | sed 's/.*agent:[[:space:]]*//' | tr -d '[:space:]')
    if [ -f "$OUTPUT_DIR/agents/${AGENT_REF}.md" ]; then
      check_pass "Skill ${skill} references valid agent: ${AGENT_REF}"
    else
      check_fail "Skill ${skill} references unknown agent: ${AGENT_REF}"
    fi
  else
    check_fail "Skill ${skill} missing agent: field"
  fi

  # Check conventions user-invocable: false
  if [ "$skill" = "ticket-system-conventions" ]; then
    if grep -q 'user-invocable:.*false' "$SKILL_FILE"; then
      check_pass "Skill ${skill} has user-invocable: false"
    else
      check_fail "Skill ${skill} should have user-invocable: false"
    fi
  fi

  # Check abort has disable-model-invocation: true
  if [ "$skill" = "ticket-system-abort" ]; then
    if grep -q 'disable-model-invocation:.*true' "$SKILL_FILE"; then
      check_pass "Skill ${skill} has disable-model-invocation: true"
    else
      check_fail "Skill ${skill} should have disable-model-invocation: true"
    fi
  elif [ "$skill" != "ticket-system-conventions" ]; then
    # All other skills should have disable-model-invocation: false
    if grep -q 'disable-model-invocation:.*false' "$SKILL_FILE"; then
      check_pass "Skill ${skill} has disable-model-invocation: false"
    else
      check_fail "Skill ${skill} should have disable-model-invocation: false"
    fi
  fi
done

echo ""

# ============================================================
# HARDCODED VALUE CHECKS
# ============================================================

echo "--- Hardcoded value checks ---"

# Check for hardcoded ticket prefixes (e.g., PROJ-001, MYAPP-002)
# Exclude template patterns like PREFIX-XXX and config examples
HARDCODED_PREFIXES=$(grep -rn '[A-Z][A-Z][A-Z]*-[0-9][0-9][0-9]' "$OUTPUT_DIR" \
  --include='*.md' --include='*.sh' --include='*.yml' \
  2>/dev/null | grep -v 'PREFIX-' | grep -v 'TC-' | grep -v 'AC-' | grep -v 'P[0-2]' || true)

if [ -z "$HARDCODED_PREFIXES" ]; then
  check_pass "No hardcoded ticket prefixes found"
else
  check_fail "Hardcoded ticket prefix detected: $(echo "$HARDCODED_PREFIXES" | head -3)"
fi

# Check for hardcoded ~/.claude/ paths
HARDCODED_PATHS=$(grep -rn '~/\.claude/' "$OUTPUT_DIR" \
  --include='*.md' --include='*.sh' --include='*.yml' \
  2>/dev/null | grep -v 'CLAUDE_DIR' | grep -v 'default' | grep -v '#' | grep -v 'comment' || true)

# More lenient: allow ~/.claude/ when it appears as a default value reference
HARDCODED_PATHS_STRICT=$(echo "$HARDCODED_PATHS" | grep -v 'HOME/\.claude' | grep -v '\$HOME' | grep -v 'defaults\|default' || true)

if [ -z "$HARDCODED_PATHS_STRICT" ]; then
  check_pass "No hardcoded ~/.claude/ paths (all use CLAUDE_DIR or defaults)"
else
  check_fail "Hardcoded ~/.claude/ path detected: $(echo "$HARDCODED_PATHS_STRICT" | head -3)"
fi

echo ""

# ============================================================
# BEHAVIORAL CHECKS FOR SPECIFIC COMMANDS
# ============================================================

echo "--- Behavioral checks ---"

# /ticket-system-schedule — must have AskUserQuestion
SCHED_FILE="$OUTPUT_DIR/skills/ticket-system-schedule/SKILL.md"
if [ -f "$SCHED_FILE" ]; then
  if grep -q 'AskUserQuestion' "$SCHED_FILE"; then
    check_pass "schedule skill has AskUserQuestion human gate"
  else
    check_fail "schedule skill missing AskUserQuestion human gate"
  fi
else
  check_skip "schedule skill not found — cannot check behavioral requirement"
fi

# /ticket-system-plan — must have AskUserQuestion
PLAN_FILE="$OUTPUT_DIR/skills/ticket-system-plan/SKILL.md"
if [ -f "$PLAN_FILE" ]; then
  if grep -q 'AskUserQuestion' "$PLAN_FILE"; then
    check_pass "plan skill has AskUserQuestion human gate"
  else
    check_fail "plan skill missing AskUserQuestion human gate"
  fi
else
  check_skip "plan skill not found — cannot check behavioral requirement"
fi

# /ticket-system-verify — must contain NEVER modify or equivalent
VERIFY_FILE="$OUTPUT_DIR/skills/ticket-system-verify/SKILL.md"
if [ -f "$VERIFY_FILE" ]; then
  if grep -qi 'NEVER modify\|never modify\|do not modify\|must not modify' "$VERIFY_FILE"; then
    check_pass "verify skill contains NEVER modify instruction"
  else
    check_fail "verify skill missing NEVER modify instruction"
  fi
  # Also check: moves to completed/ on PASS
  if grep -qi 'completed/' "$VERIFY_FILE"; then
    check_pass "verify skill references completed/ (moves on PASS)"
  else
    check_fail "verify skill missing completed/ reference"
  fi
else
  check_skip "verify skill not found — cannot check behavioral requirement"
fi

# /ticket-system-implement — must check prerequisites
IMPL_FILE="$OUTPUT_DIR/skills/ticket-system-implement/SKILL.md"
if [ -f "$IMPL_FILE" ]; then
  if grep -qi 'prerequisit' "$IMPL_FILE"; then
    check_pass "implement skill checks prerequisites"
  else
    check_fail "implement skill missing prerequisites check"
  fi
else
  check_skip "implement skill not found — cannot check behavioral requirement"
fi

# /ticket-system-merge — must verify completed status
MERGE_FILE="$OUTPUT_DIR/skills/ticket-system-merge/SKILL.md"
if [ -f "$MERGE_FILE" ]; then
  if grep -qi 'completed/' "$MERGE_FILE"; then
    check_pass "merge skill verifies completed status"
  else
    check_fail "merge skill missing completed/ verification"
  fi
else
  check_skip "merge skill not found — cannot check behavioral requirement"
fi

# /ticket-system-run — chains plan/implement/verify/merge
RUN_FILE="$OUTPUT_DIR/skills/ticket-system-run/SKILL.md"
if [ -f "$RUN_FILE" ]; then
  CHAIN_OK=true
  for phase in plan implement verify merge; do
    if ! grep -qi "$phase" "$RUN_FILE"; then
      CHAIN_OK=false
      break
    fi
  done
  if [ "$CHAIN_OK" = true ]; then
    check_pass "run skill chains plan/implement/verify/merge"
  else
    check_fail "run skill missing one or more phases (plan/implement/verify/merge)"
  fi
  # Check --yes forwarding
  if grep -q '\-\-yes' "$RUN_FILE"; then
    check_pass "run skill handles --yes forwarding"
  else
    check_fail "run skill missing --yes forwarding"
  fi
  # Check stop on failure
  if grep -qi 'stop.*fail\|failure\|Stop on failure' "$RUN_FILE"; then
    check_pass "run skill stops on failure"
  else
    check_fail "run skill missing stop-on-failure behavior"
  fi
  # Check filesystem state verification
  if grep -qi 'verify.*state\|filesystem.*state\|state.*after\|Verify filesystem' "$RUN_FILE"; then
    check_pass "run skill verifies filesystem state after each step"
  else
    check_fail "run skill missing filesystem state verification after steps"
  fi
else
  check_skip "run skill not found — cannot check behavioral requirement"
fi

# /ticket-system-abort — confirmation gate
ABORT_FILE="$OUTPUT_DIR/skills/ticket-system-abort/SKILL.md"
if [ -f "$ABORT_FILE" ]; then
  if grep -q 'AskUserQuestion' "$ABORT_FILE"; then
    check_pass "abort skill has AskUserQuestion confirmation gate"
  else
    check_fail "abort skill missing AskUserQuestion confirmation gate"
  fi
  # Check agent is ticket-system-ops
  if grep -q 'agent:.*ticket-system-ops' "$ABORT_FILE"; then
    check_pass "abort skill uses ticket-system-ops agent"
  else
    check_fail "abort skill should use ticket-system-ops agent"
  fi
else
  check_skip "abort skill not found — cannot check behavioral requirement"
fi

# /ticket-system-run — uses ticket-system-coder agent
if [ -f "$RUN_FILE" ]; then
  if grep -q 'agent:.*ticket-system-coder' "$RUN_FILE"; then
    check_pass "run skill uses ticket-system-coder agent"
  else
    check_fail "run skill should use ticket-system-coder agent"
  fi
fi

# /ticket-system-doctor — read-only, checks .pending
DOCTOR_FILE="$OUTPUT_DIR/skills/ticket-system-doctor/SKILL.md"
if [ -f "$DOCTOR_FILE" ]; then
  if grep -qi 'no.*modif\|read.only\|NO file modifications' "$DOCTOR_FILE"; then
    check_pass "doctor skill is read-only (no modifications)"
  else
    check_fail "doctor skill missing read-only instruction"
  fi
  if grep -q '\.pending' "$DOCTOR_FILE"; then
    check_pass "doctor skill checks .tickets/.pending"
  else
    check_fail "doctor skill missing .pending check"
  fi
  # Check agent is ticket-system-reader
  if grep -q 'agent:.*ticket-system-reader' "$DOCTOR_FILE"; then
    check_pass "doctor skill uses ticket-system-reader agent"
  else
    check_fail "doctor skill should use ticket-system-reader agent"
  fi
else
  check_skip "doctor skill not found — cannot check behavioral requirement"
fi

# Mutative commands write/delete .tickets/.pending
MUTATIVE_SKILLS=(ticket-system-schedule ticket-system-plan ticket-system-merge ticket-system-abort)
for ms in "${MUTATIVE_SKILLS[@]}"; do
  MS_FILE="$OUTPUT_DIR/skills/${ms}/SKILL.md"
  if [ -f "$MS_FILE" ]; then
    if grep -q '\.pending' "$MS_FILE"; then
      check_pass "Mutative skill ${ms} references .pending file"
    else
      check_fail "Mutative skill ${ms} missing .pending file handling"
    fi
  fi
done

echo ""

# ============================================================
# CONDITIONAL FEATURE CHECKS
# ============================================================

echo "--- Conditional feature checks ---"

# New agents (doctor, abort, next) — may or may not be present
OPTIONAL_SKILLS=(ticket-system-next)
for opt in "${OPTIONAL_SKILLS[@]}"; do
  if [ -d "$OUTPUT_DIR/skills/$opt" ]; then
    if [ -f "$OUTPUT_DIR/skills/$opt/SKILL.md" ]; then
      check_pass "Optional skill $opt present with SKILL.md"
    else
      check_fail "Optional skill $opt directory exists but missing SKILL.md"
    fi
  else
    check_skip "Optional skill $opt not present (feature not in spec)"
  fi
done

# roadmap.yml YAML format validation — check if any skill mentions roadmap.yml
# This is a conditional feature: SKIP if not present
if grep -rq 'roadmap\.yml' "$OUTPUT_DIR/skills/" 2>/dev/null; then
  check_pass "Skills reference roadmap.yml format"
else
  check_skip "No roadmap.yml references found in skills (may not be applicable)"
fi

# test_command references in verifier skill
if [ -f "$VERIFY_FILE" ]; then
  if grep -q 'test_command' "$VERIFY_FILE"; then
    check_pass "Verifier skill references test_command"
  else
    check_skip "Verifier skill does not reference test_command (may not be configured)"
  fi
fi

echo ""

# ============================================================
# HOOK VALIDATION
# ============================================================

echo "--- Hook validation ---"

HOOK_FILE="$OUTPUT_DIR/hooks/validate-git-worktree.sh"
if [ -f "$HOOK_FILE" ]; then
  # Reads JSON from stdin
  if grep -q 'read.*INPUT\|read.*input\|read.*json\|stdin' "$HOOK_FILE"; then
    check_pass "Hook reads from stdin"
  else
    check_fail "Hook does not appear to read from stdin"
  fi

  # Handles mkdir commands
  if grep -q 'mkdir' "$HOOK_FILE"; then
    check_pass "Hook handles mkdir commands"
  else
    check_fail "Hook missing mkdir handling"
  fi

  # Handles git worktree commands
  if grep -q 'git worktree' "$HOOK_FILE"; then
    check_pass "Hook handles git worktree commands"
  else
    check_fail "Hook missing git worktree handling"
  fi

  # Handles git -C <path>
  if grep -q 'git -C' "$HOOK_FILE"; then
    check_pass "Hook handles git -C commands"
  else
    check_fail "Hook missing git -C handling"
  fi

  # Outputs permissionDecision JSON
  if grep -q 'permissionDecision' "$HOOK_FILE"; then
    check_pass "Hook outputs permissionDecision JSON"
  else
    check_fail "Hook missing permissionDecision output"
  fi

  # Works without external JSON parsers (has grep/sed fallback)
  if grep -q 'grep\|sed' "$HOOK_FILE"; then
    check_pass "Hook has grep/sed fallback (works without external JSON tools)"
  else
    check_fail "Hook missing grep/sed fallback — may require external JSON parser"
  fi

  # No hardcoded ticket prefix in hook — look for specific ID patterns like TS-, PROJ-, etc.
  # Exclude comment lines and generic template references
  HOOK_PREFIXES=$(grep -nE '[A-Z]{2,}-[0-9]|[A-Z]{2,}-"' "$HOOK_FILE" | grep -v '^[[:space:]]*#' || true)
  if [ -z "$HOOK_PREFIXES" ]; then
    # Also check for variable assignments that embed a specific prefix string
    HOOK_PREFIX_VARS=$(grep -nE '="[A-Z]{2,}-"' "$HOOK_FILE" || true)
    if [ -z "$HOOK_PREFIX_VARS" ]; then
      check_pass "Hook has no hardcoded ticket prefix"
    else
      check_fail "Hook has hardcoded ticket prefix: $HOOK_PREFIX_VARS"
    fi
  else
    check_fail "Hook has hardcoded ticket prefix: $HOOK_PREFIXES"
  fi

  # Check worktree basename validation
  if grep -q '\-worktree' "$HOOK_FILE"; then
    check_pass "Hook validates *-worktree basename pattern"
  else
    check_fail "Hook missing *-worktree basename validation"
  fi
else
  check_fail "Hook file not found — cannot validate"
fi

echo ""

# ============================================================
# INSTALL.SH AND INIT-PROJECT.SH CONTENT VALIDATION
# ============================================================

echo "--- Script content validation ---"

# install.sh checks
INSTALL_FILE="$OUTPUT_DIR/install.sh"
if [ -f "$INSTALL_FILE" ]; then
  # Prompts for installation directory
  if grep -q 'read.*[Dd]ir\|read.*install\|read.*CLAUDE\|read.*path\|Enter.*director' "$INSTALL_FILE"; then
    check_pass "install.sh prompts for installation directory"
  else
    check_fail "install.sh missing directory prompt"
  fi

  # Uses CLAUDE_DIR
  if grep -q 'CLAUDE_DIR' "$INSTALL_FILE"; then
    check_pass "install.sh uses CLAUDE_DIR variable"
  else
    check_fail "install.sh missing CLAUDE_DIR usage"
  fi

  # Copies hooks
  if grep -q 'hooks\|hook' "$INSTALL_FILE"; then
    check_pass "install.sh handles hook installation"
  else
    check_fail "install.sh missing hook installation"
  fi

  # Merges PreToolUse config
  if grep -qi 'settings\|PreToolUse\|settings\.json' "$INSTALL_FILE"; then
    check_pass "install.sh references settings/PreToolUse config"
  else
    check_skip "install.sh does not explicitly mention PreToolUse/settings (may use different approach)"
  fi
else
  check_fail "install.sh not found — cannot validate content"
fi

# init-project.sh checks
INITP_FILE="$OUTPUT_DIR/init-project.sh"
if [ -f "$INITP_FILE" ]; then
  # Accepts prefix argument
  if grep -q 'PREFIX\|prefix\|\$1' "$INITP_FILE"; then
    check_pass "init-project.sh accepts prefix argument"
  else
    check_fail "init-project.sh missing prefix argument handling"
  fi

  # Creates directory structure
  if grep -q 'mkdir' "$INITP_FILE"; then
    check_pass "init-project.sh creates directory structure"
  else
    check_fail "init-project.sh missing directory creation"
  fi

  # Generates TEMPLATE.md with pipe-separated enums
  if grep -q 'TEMPLATE\|template' "$INITP_FILE"; then
    # Check for pipe-separated values
    if grep -q '|' "$INITP_FILE"; then
      check_pass "init-project.sh generates TEMPLATE.md with pipe-separated enums"
    else
      check_fail "init-project.sh TEMPLATE.md missing pipe-separated enum values"
    fi
  else
    check_fail "init-project.sh missing TEMPLATE.md generation"
  fi

  # Adds .worktrees/ to .gitignore
  if grep -q '\.worktrees\|worktrees' "$INITP_FILE"; then
    check_pass "init-project.sh adds .worktrees/ to .gitignore"
  else
    check_fail "init-project.sh missing .worktrees/ gitignore entry"
  fi
else
  check_fail "init-project.sh not found — cannot validate content"
fi

echo ""

# ============================================================
# CONVENTIONS SKILL LINE BUDGET
# ============================================================

echo "--- Conventions skill line budget ---"

CONV_FILE="$OUTPUT_DIR/skills/ticket-system-conventions/SKILL.md"
if [ -f "$CONV_FILE" ]; then
  # Check line count does not exceed 500
  ACTUAL_LINES=$(wc -l < "$CONV_FILE" | tr -d '[:space:]')
  if [ "$ACTUAL_LINES" -le 500 ]; then
    check_pass "Conventions skill is within budget ($ACTUAL_LINES/500 lines)"
  else
    check_fail "Conventions skill exceeds 500-line budget ($ACTUAL_LINES lines)"
  fi

  # Check for <!-- Lines: N/500 --> comment
  LINE_COMMENT=$(grep -n '<!-- Lines: [0-9]*/500 -->' "$CONV_FILE" || true)
  if [ -n "$LINE_COMMENT" ]; then
    # Extract the N value from the comment
    CLAIMED_LINES=$(echo "$LINE_COMMENT" | grep -o 'Lines: [0-9]*' | grep -o '[0-9]*')
    if [ "$CLAIMED_LINES" = "$ACTUAL_LINES" ]; then
      check_pass "Line-count comment matches actual count ($CLAIMED_LINES/500)"
    else
      check_fail "Line-count comment mismatch: claims $CLAIMED_LINES but file has $ACTUAL_LINES lines"
    fi
  else
    check_fail "Conventions skill missing <!-- Lines: N/500 --> comment"
  fi
else
  check_fail "Conventions skill not found — cannot check line budget"
fi

echo ""

# ============================================================
# SUMMARY
# ============================================================

echo "=== Validation Summary ==="
echo "  PASS: $PASS_COUNT"
echo "  FAIL: $FAIL_COUNT"
echo "  SKIP: $SKIP_COUNT"
TOTAL=$((PASS_COUNT + FAIL_COUNT + SKIP_COUNT))
echo "  TOTAL: $TOTAL checks"
echo ""

if [ $FAIL_COUNT -gt 0 ]; then
  echo "RESULT: FAILED ($FAIL_COUNT failures)"
  exit 1
else
  echo "RESULT: PASSED"
  exit 0
fi
