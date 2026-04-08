# Test Plan — TS-035

## Strategy
Since this ticket modifies a specification file (not runnable code), testing is validation-based: verify that the spec changes are structurally correct, internally consistent, and complete. The "tests" are manual or scripted checks against the generated output after feeding the updated spec to Claude Code. Integration testing happens in the outer loop (generate, install, run commands, observe stats output).

## Test Cases

### TC-1: Stats config option is documented
- **Type:** integration (spec validation)
- **Target:** specs.md section 3.1
- **Input:** Read the updated section 3.1
- **Expected:** `stats: false` appears as an optional commented-out field in the config.yml example, with documentation explaining it enables telemetry
- **Covers criteria:** AC-1 (stats disabled by default means unchanged behavior)

### TC-2: Stats directory in project structure
- **Type:** integration (spec validation)
- **Target:** specs.md section 3.2
- **Input:** Read the updated section 3.2
- **Expected:** `.tickets/stats/` appears in the directory structure with a note that it is gitignored
- **Covers criteria:** AC-9 (stats directory is gitignored)

### TC-3: Hook scripts in file tree
- **Type:** integration (spec validation)
- **Target:** specs.md section 5.1
- **Input:** Read the updated file tree
- **Expected:** `hooks/instrument-pre.sh` and `hooks/instrument-post.sh` appear alongside `validate-git-worktree.sh`
- **Covers criteria:** AC-2 (hooks are installed with the system)

### TC-4: PreToolUse hook generation rules are complete
- **Type:** integration (spec validation)
- **Target:** specs.md section 5.6 or 5.7
- **Input:** Read the instrumentation hook generation rules
- **Expected:** Rules specify: read JSON from stdin, check stats config, extract tool_use_id/tool_name/tool_input, write temp state file with start timestamp, handle macOS date fallback, always exit 0
- **Covers criteria:** AC-2, AC-3, AC-10, AC-11

### TC-5: PostToolUse hook generation rules are complete
- **Type:** integration (spec validation)
- **Target:** specs.md section 5.6 or 5.7
- **Input:** Read the instrumentation hook generation rules
- **Expected:** Rules specify: correlate via tool_use_id, compute elapsed_ms, append JSONL entry, delete temp file, handle PostToolUseFailure, always exit 0
- **Covers criteria:** AC-4, AC-5, AC-6, AC-10, AC-11

### TC-6: Install script registers hooks
- **Type:** integration (spec validation)
- **Target:** specs.md section 5.3
- **Input:** Read the updated install.sh specification
- **Expected:** install.sh copies both instrumentation hooks, makes them executable, and registers them in settings.json with appropriate matchers (PreToolUse with ".*" matcher, PostToolUse with ".*" matcher)
- **Covers criteria:** AC-2

### TC-7: Init script gitignores stats directory
- **Type:** integration (spec validation)
- **Target:** specs.md section 5.4
- **Input:** Read the updated init-project.sh specification
- **Expected:** init-project.sh adds `.tickets/stats/` to `.gitignore` if not already present
- **Covers criteria:** AC-9

### TC-8: /ticket-system-run includes phase timing
- **Type:** integration (spec validation)
- **Target:** specs.md section 4.2, /ticket-system-run
- **Input:** Read the updated run command specification
- **Expected:** Specification describes reading stats flag, recording timestamps before/after each phase, writing `<ticket-id>.json` to `.tickets/stats/`, and the exact JSON output format with per-phase timing and tool_call_count
- **Covers criteria:** AC-7, AC-8

### TC-9: Stats written on early failure
- **Type:** integration (spec validation)
- **Target:** specs.md section 4.2, /ticket-system-run
- **Input:** Read the run command specification's failure handling
- **Expected:** Specification explicitly states stats are written even when the run stops early (partial phase data with run_status reflecting the failure)
- **Covers criteria:** AC-8

### TC-10: Validation checklist covers instrumentation
- **Type:** integration (spec validation)
- **Target:** specs.md section 8
- **Input:** Read the updated validation checklist
- **Expected:** Checklist items exist for: hook file existence, stats-disabled fast exit, JSONL format, install.sh hook registration, init-project.sh gitignore, run phase timing, early-failure stats, POSIX compatibility
- **Covers criteria:** All ACs (validation coverage)

### TC-11: CLAUDE.md reflects changes
- **Type:** integration (spec validation)
- **Target:** CLAUDE.md
- **Input:** Read CLAUDE.md
- **Expected:** Validation sections mention instrumentation hooks and stats collection
- **Covers criteria:** All ACs (documentation sync)

### TC-12: No hardcoded prefixes in new spec sections
- **Type:** unit (grep check)
- **Target:** All new/modified sections of specs.md
- **Input:** Search for hardcoded ticket prefixes in new sections
- **Expected:** No hardcoded prefixes — all examples use `PREFIX-XXX` or `PROJ-001` placeholder patterns
- **Covers criteria:** Existing validation rule (no hardcoded prefixes)

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: Stats disabled by default | TC-1 |
| AC-2: Hooks installed with system | TC-3, TC-4, TC-5, TC-6 |
| AC-3: PreToolUse records to temp state | TC-4 |
| AC-4: PostToolUse correlates and appends JSONL | TC-5 |
| AC-5: Tool call log entry format | TC-5 |
| AC-6: PostToolUseFailure hooked | TC-5 |
| AC-7: /ticket-system-run phase-level summary | TC-8 |
| AC-8: Stats written on early failure | TC-9 |
| AC-9: Stats directory gitignored | TC-2, TC-7 |
| AC-10: POSIX-compatible hooks | TC-4, TC-5 |
| AC-11: Hook overhead under 50ms | TC-4, TC-5 |
