# Test Plan — TS-002

## Strategy
Integration testing using a synthetic generated output directory. Tests create minimal valid/invalid output trees and run `validate.sh` against them to verify correct detection. A test harness script (`test-validate.sh`) runs all test cases and reports results.

## Test Cases

### TC-1: Script exists and is executable
- **Type:** unit
- **Target:** `validate.sh` file attributes
- **Input:** Check file existence and execute permission
- **Expected:** File exists at repo root, has `#!/bin/bash` shebang, is executable
- **Covers criteria:** AC-1 (validate.sh exists and is executable)

### TC-2: Rejects missing directory argument
- **Type:** unit
- **Target:** Argument parsing
- **Input:** Run `validate.sh` with no arguments
- **Expected:** Prints usage message and exits with non-zero code
- **Covers criteria:** AC-2 (accepts path as argument)

### TC-3: Rejects non-existent directory
- **Type:** unit
- **Target:** Argument validation
- **Input:** Run `validate.sh /tmp/nonexistent-dir-XXXX`
- **Expected:** Prints error and exits with non-zero code
- **Covers criteria:** AC-2 (accepts path as argument)

### TC-4: All structural files present
- **Type:** integration
- **Target:** Structural completeness checks
- **Input:** Create a synthetic output directory with all required files (ARCHITECTURE.md, install.sh, init-project.sh, hooks/validate-git-worktree.sh, 6 agents, 11 skill directories with SKILL.md)
- **Expected:** All structural checks report PASS
- **Covers criteria:** AC-3 (checks smoke test items — file count)

### TC-5: Missing file detected
- **Type:** integration
- **Target:** Structural completeness checks
- **Input:** Synthetic output directory missing `agents/ticket-system-verifier.md`
- **Expected:** That specific check reports FAIL, script exits non-zero
- **Covers criteria:** AC-3, AC-7 (PASS/FAIL summary), AC-8 (non-zero exit on failure)

### TC-6: Executable scripts pass permission check
- **Type:** integration
- **Target:** Permission validation
- **Input:** Synthetic output with `chmod +x` on install.sh, init-project.sh, hooks/validate-git-worktree.sh
- **Expected:** Permission checks report PASS
- **Covers criteria:** AC-3 (script permissions)

### TC-7: Non-executable script detected
- **Type:** integration
- **Target:** Permission validation
- **Input:** Synthetic output where `install.sh` is not executable
- **Expected:** Permission check for install.sh reports FAIL
- **Covers criteria:** AC-3, AC-8

### TC-8: Valid agent frontmatter passes
- **Type:** integration
- **Target:** Agent frontmatter checks
- **Input:** Agent file with correct `skills: [ticket-system-conventions]` and `permissionMode: bypassPermissions`
- **Expected:** Agent checks report PASS
- **Covers criteria:** AC-3 (frontmatter fields)

### TC-9: Agent missing skills field detected
- **Type:** integration
- **Target:** Agent frontmatter checks
- **Input:** Agent file without `skills: [ticket-system-conventions]`
- **Expected:** Check reports FAIL
- **Covers criteria:** AC-3, AC-8

### TC-10: Valid skill frontmatter passes
- **Type:** integration
- **Target:** Skill frontmatter checks
- **Input:** Skill SKILL.md with `context: fork` and `agent: ticket-system-editor`
- **Expected:** Skill checks report PASS
- **Covers criteria:** AC-3 (frontmatter fields)

### TC-11: Skill missing context: fork detected
- **Type:** integration
- **Target:** Skill frontmatter checks
- **Input:** Skill SKILL.md without `context: fork`
- **Expected:** Check reports FAIL
- **Covers criteria:** AC-3, AC-8

### TC-12: Clean output passes hardcoded value check
- **Type:** integration
- **Target:** Hardcoded value scanner
- **Input:** Output directory with no hardcoded prefixes or `~/.claude/` paths
- **Expected:** Hardcoded checks report PASS
- **Covers criteria:** AC-3 (hardcoded values)

### TC-13: Hardcoded prefix detected
- **Type:** integration
- **Target:** Hardcoded value scanner
- **Input:** Agent file containing `PROJ-001` outside a template context
- **Expected:** Check reports FAIL
- **Covers criteria:** AC-3, AC-8

### TC-14: Behavioral checks pass for valid skills
- **Type:** integration
- **Target:** Command behavioral validation
- **Input:** Skill files containing required patterns (AskUserQuestion in schedule/plan, NEVER modify in verify, etc.)
- **Expected:** All behavioral checks report PASS
- **Covers criteria:** AC-3 (smoke test items)

### TC-15: Missing human gate detected
- **Type:** integration
- **Target:** Command behavioral validation
- **Input:** `/ticket-system-schedule` SKILL.md without `AskUserQuestion`
- **Expected:** Check reports FAIL
- **Covers criteria:** AC-3, AC-8

### TC-16: Absent conditional feature is skipped
- **Type:** integration
- **Target:** Conditional feature checks
- **Input:** Output directory that does not include a `ticket-system-next` skill (feature not yet in spec)
- **Expected:** Check reports SKIP, not FAIL
- **Covers criteria:** AC-4 (validates new agents if present), AC-6 (test_command if configured)

### TC-17: Valid hook passes content checks
- **Type:** integration
- **Target:** Hook validation
- **Input:** Hook script containing JSON parsing, permissionDecision output, jq fallback, no hardcoded prefix
- **Expected:** Hook checks report PASS
- **Covers criteria:** AC-3 (smoke test — hook)

### TC-18: Hook with hardcoded prefix detected
- **Type:** integration
- **Target:** Hook validation
- **Input:** Hook script containing `TS-` hardcoded prefix
- **Expected:** Check reports FAIL
- **Covers criteria:** AC-3, AC-8

### TC-19: Valid install.sh passes content checks
- **Type:** integration
- **Target:** Script content validation
- **Input:** install.sh with directory prompt, CLAUDE_DIR usage, hook installation
- **Expected:** Content checks report PASS
- **Covers criteria:** AC-3 (script behavior)

### TC-20: install.sh missing directory prompt detected
- **Type:** integration
- **Target:** Script content validation
- **Input:** install.sh without any prompt/menu for installation directory
- **Expected:** Check reports FAIL
- **Covers criteria:** AC-3, AC-8

### TC-21: Full valid output — zero exit code
- **Type:** integration
- **Target:** End-to-end validation
- **Input:** Complete synthetic output directory with all files, correct frontmatter, no hardcoded values, all behavioral patterns present
- **Expected:** Script exits 0 with all PASS (no FAIL)
- **Covers criteria:** AC-7 (clear summary), AC-8 (exit code)

### TC-22: No external dependencies used
- **Type:** unit
- **Target:** `validate.sh` source code
- **Input:** Scan script for non-POSIX tool invocations
- **Expected:** No references to python, node, jq, ruby, perl, npm, pip
- **Covers criteria:** AC-9 (no external dependencies)

### TC-23: Pending file checks in mutative commands
- **Type:** integration
- **Target:** `.tickets/.pending` validation
- **Input:** Skill files for schedule, plan, merge, abort containing `.pending` write/delete patterns
- **Expected:** Checks report PASS for pending file handling
- **Covers criteria:** AC-3

## Coverage Map

| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: validate.sh exists and is executable | TC-1 |
| AC-2: Accepts path to generated output directory | TC-2, TC-3 |
| AC-3: Checks smoke test items (file count, frontmatter, hardcoded values, permissions) | TC-4, TC-5, TC-6, TC-7, TC-8, TC-9, TC-10, TC-11, TC-12, TC-13, TC-14, TC-15, TC-17, TC-18, TC-19, TC-20, TC-23 |
| AC-4: Validates new agents if features added | TC-16 |
| AC-5: Checks roadmap.yml YAML format | TC-16 |
| AC-6: Checks test_command in verifier if configured | TC-16 |
| AC-7: Clear PASS/FAIL summary with per-check detail | TC-5, TC-21 |
| AC-8: Non-zero exit on failure | TC-2, TC-3, TC-5, TC-7, TC-9, TC-11, TC-13, TC-15, TC-18, TC-20 |
| AC-9: No external dependencies | TC-22 |
