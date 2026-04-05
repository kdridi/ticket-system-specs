# Implementation Plan — TS-002

## Overview
Create a `validate.sh` script at the repository root that accepts the path to a generated output directory and validates it against the full checklist in specs.md section 8. The script reports per-check PASS/FAIL/SKIP results and exits non-zero on any failure.

## Steps

### Step 1: Script skeleton and argument handling
- **Files:** `validate.sh` (create)
- **What:** Create the script with shebang, usage message, argument parsing (accept a directory path), and the reporting framework (pass/fail/skip counters, helper functions for `check_pass`, `check_fail`, `check_skip`, and final summary).
- **Tests first:** TC-1 (script exists and is executable), TC-2 (rejects missing directory argument), TC-3 (rejects non-existent directory).
- **Done when:** Running `bash validate.sh /nonexistent` prints an error and exits 1; running without arguments prints usage.

### Step 2: Structural completeness checks
- **Files:** `validate.sh` (modify)
- **What:** Add checks for all required files from section 8 "Structural completeness":
  - `ARCHITECTURE.md`, `install.sh`, `init-project.sh` at root
  - `hooks/validate-git-worktree.sh`
  - 6 agent files in `agents/`
  - 11 skill directories in `skills/`, each containing `SKILL.md`
- **Tests first:** TC-4 (all files present in a valid output), TC-5 (missing file detected).
- **Done when:** Script lists all expected files and reports PASS/FAIL for each.

### Step 3: Script permission checks
- **Files:** `validate.sh` (modify)
- **What:** Verify `install.sh`, `init-project.sh`, and `hooks/validate-git-worktree.sh` have `#!/bin/bash` shebang and are executable (`test -x`).
- **Tests first:** TC-6 (executable scripts pass), TC-7 (non-executable script detected).
- **Done when:** Script reports PASS/FAIL for each permission check.

### Step 4: Agent frontmatter validation
- **Files:** `validate.sh` (modify)
- **What:** For each agent file in `agents/`:
  - Check it contains `skills: [ticket-system-conventions]`
  - Check it contains `permissionMode:` with the correct value (plan for reader, bypassPermissions for all others)
  - Check `ticket-system-coder.md` does NOT have a `tools:` field
  - Check all other agents DO have a `tools:` field
- **Tests first:** TC-8 (valid agent passes), TC-9 (agent missing skills field detected).
- **Done when:** Each agent is validated for its specific permission profile.

### Step 5: Skill frontmatter validation
- **Files:** `validate.sh` (modify)
- **What:** For each skill directory in `skills/`:
  - Check `SKILL.md` contains `context: fork` and `agent: <name>`
  - Check `ticket-system-conventions` has `user-invocable: false`
  - Check `ticket-system-abort` has `disable-model-invocation: true`
  - Check all other skills have `disable-model-invocation: false`
  - Validate agent references point to actual agent files
- **Tests first:** TC-10 (valid skill passes), TC-11 (skill missing context: fork detected).
- **Done when:** Each skill is validated for correct frontmatter fields.

### Step 6: Hardcoded value checks
- **Files:** `validate.sh` (modify)
- **What:** Scan the entire generated output directory for:
  - Hardcoded ticket prefixes (specific ticket IDs like `PROJ-001` outside of template/example contexts)
  - Hardcoded `~/.claude/` paths that should use `$CLAUDE_DIR`
- **Tests first:** TC-12 (clean output passes), TC-13 (hardcoded prefix detected).
- **Done when:** Script recursively scans all generated files and flags hardcoded values.

### Step 7: Behavioral checks for specific commands
- **Files:** `validate.sh` (modify)
- **What:** Check skill content (not just frontmatter) for key behavioral requirements:
  - `/ticket-system-schedule` contains `AskUserQuestion` (human gate)
  - `/ticket-system-plan` contains `AskUserQuestion` (human gate)
  - `/ticket-system-verify` contains "NEVER modify" or equivalent
  - `/ticket-system-implement` checks prerequisites
  - `/ticket-system-merge` verifies completed status
  - `/ticket-system-run` chains plan, implement, verify, merge and handles `--yes`
  - `/ticket-system-abort` has confirmation gate
  - `/ticket-system-doctor` is read-only and checks `.pending`
  - Mutative commands write/delete `.tickets/.pending`
- **Tests first:** TC-14 (valid skills pass behavioral checks), TC-15 (missing human gate detected).
- **Done when:** Each behavioral requirement from section 8 is checked.

### Step 8: Conditional feature checks
- **Files:** `validate.sh` (modify)
- **What:** Add SKIP-able checks for features that may or may not be present:
  - New agents (doctor, abort, next) -- present based on spec version
  - `roadmap.yml` YAML format validation
  - `test_command` references in verifier skill
- **Tests first:** TC-16 (absent feature skipped, not failed).
- **Done when:** Conditional checks report SKIP when the feature is not present, PASS/FAIL when it is.

### Step 9: Hook validation
- **Files:** `validate.sh` (modify)
- **What:** Validate `hooks/validate-git-worktree.sh` content:
  - Reads JSON from stdin
  - Handles `mkdir`, `git worktree`, and `git -C` commands
  - Outputs `permissionDecision` JSON
  - Works without `jq` (has fallback)
  - No hardcoded ticket prefix
- **Tests first:** TC-17 (valid hook passes), TC-18 (hook with hardcoded prefix detected).
- **Done when:** Hook content is validated against section 8 requirements.

### Step 10: install.sh and init-project.sh content validation
- **Files:** `validate.sh` (modify)
- **What:** Check script content for required behaviors:
  - `install.sh` prompts for installation directory, handles empty input, validates paths
  - `install.sh` copies hooks and merges PreToolUse config into settings.json
  - `init-project.sh` accepts prefix argument, creates directory structure, generates TEMPLATE.md with pipe-separated enums, adds `.worktrees/` to `.gitignore`
- **Tests first:** TC-19 (valid scripts pass), TC-20 (script missing directory prompt detected).
- **Done when:** Both scripts are validated for key behavioral patterns.

### Step 11: Summary output and exit code
- **Files:** `validate.sh` (modify)
- **What:** Ensure final output shows total PASS/FAIL/SKIP counts and exits with non-zero code if any check failed. Format: `[PASS] Check description` / `[FAIL] Check description` / `[SKIP] Check description`.
- **Tests first:** Already covered by TC-1 through TC-20 integration.
- **Done when:** Running against a valid generated output returns exit 0; running against a deliberately broken output returns exit 1.

## Risk Notes
- The script validates generated output by pattern-matching file content (e.g., grepping for `AskUserQuestion` in skill files). This is inherently heuristic -- if the generated output uses different wording, checks may false-positive or false-negative. Mitigation: use broad patterns that match the intent rather than exact strings.
- The "no hardcoded prefix" check must avoid false positives on template/example text like `PREFIX-XXX` which is intentional. The check should only flag specific prefix patterns (e.g., `PROJ-001`, `MYAPP-002`) that look like real ticket IDs.
- Some checklist items from section 8 are behavioral (e.g., "agent stays forked through Phase 4") and cannot be fully validated by static analysis. The script should check for the presence of the mechanism (e.g., `AskUserQuestion` exists in the skill) rather than runtime behavior.
- The existing `validate-spec.sh` validates `specs.md` itself. The new `validate.sh` validates generated output. These are complementary and should not conflict.
