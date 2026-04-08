# Implementation Plan — TS-035

## Overview
Add two layers of observability instrumentation to the ticket system specification: (A) hook-based tool-level telemetry via PreToolUse/PostToolUse hooks that log every tool call with timing, and (B) phase-level timing in `/ticket-system-run` that records wall-clock durations per phase. Both layers are opt-in via `stats: true` in `.tickets/config.yml`. This ticket modifies `specs.md` and `CLAUDE.md` to describe the new hooks, config option, output formats, and orchestrator changes.

## Steps

### Step 1: Add `stats` config option to the data model (specs.md section 3.1)
- **Files:** `specs.md`
- **What:** Add `stats: false` as an optional field in `.tickets/config.yml` (section 3.1 — Project Configuration). Add a description explaining it enables hook-based telemetry and phase-level timing. Also add `.tickets/stats/` to the directory structure (section 3.2) with a comment that it is gitignored.
- **Tests first:** N/A (spec change)
- **Done when:** Section 3.1 shows `stats` as an optional config field with documentation, and section 3.2 shows `.tickets/stats/` in the directory tree.

### Step 2: Add instrumentation hook scripts to the file tree (specs.md section 5.1)
- **Files:** `specs.md`
- **What:** Add `hooks/instrument-pre.sh` and `hooks/instrument-post.sh` to the file tree in section 5.1. These are new hook scripts alongside the existing `validate-git-worktree.sh`.
- **Tests first:** N/A (spec change)
- **Done when:** Section 5.1 file tree includes both new hook files under `hooks/`.

### Step 3: Add hook script generation rules (specs.md section 5.6)
- **Files:** `specs.md`
- **What:** Add a new subsection (or extend section 5.6) with generation rules for the two instrumentation hooks. Specify:
  - `instrument-pre.sh`: reads JSON from stdin, checks `stats: true` in `.tickets/config.yml` (exit 0 immediately if not set), extracts `tool_use_id`, `tool_name`, `tool_input` summary (file_path for Read/Write/Edit, command for Bash, pattern for Grep/Glob), records start timestamp to `.tickets/stats/.hook-state/<tool_use_id>.tmp`. Must handle macOS `date` lacking `%N` (use `python3` or `gdate` fallback for millisecond precision). Always exit 0 to avoid blocking tool execution.
  - `instrument-post.sh`: reads JSON from stdin, checks `stats: true` (exit 0 if not), correlates via `tool_use_id`, computes elapsed_ms, appends JSONL entry to `.tickets/stats/tool-calls.jsonl`, deletes the tmp file. Also handles PostToolUseFailure (marks entry as failed). Always exit 0.
  - Both hooks are POSIX-compatible (bash, jq with grep/sed fallback, date).
  - Hook overhead target: under 50ms per invocation.
- **Tests first:** N/A (spec change)
- **Done when:** Section 5.6 (or a new section 5.7) contains complete generation rules for both instrumentation hooks, including the conditional stats check, JSONL output format, temp state file mechanism, and macOS compatibility.

### Step 4: Update install.sh spec to register instrumentation hooks (specs.md section 5.3)
- **Files:** `specs.md`
- **What:** Update the installation script specification (section 5.3, Step 1) to:
  - Copy `hooks/instrument-pre.sh` and `hooks/instrument-post.sh` to `$CLAUDE_DIR/hooks/`.
  - Make them executable.
  - Register them in `$CLAUDE_DIR/settings.json` under `hooks.PreToolUse` (with matcher `".*"` to capture all tools) and `hooks.PostToolUse` (similarly). The existing `validate-git-worktree.sh` hook stays as-is under `PreToolUse` with matcher `"Bash"`.
- **Tests first:** N/A (spec change)
- **Done when:** Section 5.3 describes copying, chmod, and settings.json registration for both new hooks alongside the existing worktree hook.

### Step 5: Update init-project.sh spec to gitignore stats directory (specs.md section 5.4)
- **Files:** `specs.md`
- **What:** Update section 5.4 to add `.tickets/stats/` to the project's `.gitignore` (similar to how `.worktrees/` is handled — check first, append if not present).
- **Tests first:** N/A (spec change)
- **Done when:** Section 5.4 includes a step to ensure `.tickets/stats/` is in `.gitignore`.

### Step 6: Add phase-level timing to /ticket-system-run spec (specs.md section 4.2)
- **Files:** `specs.md`
- **What:** Update the `/ticket-system-run` command specification to:
  - At startup, read `stats` flag from `.tickets/config.yml`.
  - If `stats: true`, record `date +%s` before and after each phase (plan, implement, verify, merge).
  - After run completion (success or failure), write `.tickets/stats/<ticket-id>.json` with: ticket_id, title, type, priority, estimated_complexity, per-phase records (name, started_at, ended_at, duration_sec), total_duration_sec, run_status, and tool_call_count per phase (derived from timestamp-range filtering of tool-calls.jsonl).
  - Stats are written even on early stop (partial phase data).
- **Tests first:** N/A (spec change)
- **Done when:** The `/ticket-system-run` specification includes conditional stats collection logic and output file format.

### Step 7: Add validation checklist items (specs.md section 8)
- **Files:** `specs.md`
- **What:** Add checklist items to section 8 covering:
  - `hooks/instrument-pre.sh` and `hooks/instrument-post.sh` exist in file tree.
  - Both hooks check `stats: true` and exit 0 immediately when stats are disabled.
  - Both hooks always exit 0 (never block tool execution).
  - JSONL output format is correct.
  - `install.sh` registers instrumentation hooks in settings.json.
  - `init-project.sh` adds `.tickets/stats/` to `.gitignore`.
  - `/ticket-system-run` writes phase-level stats when `stats: true`.
  - Stats are written even on early failure.
  - Hook scripts are POSIX-compatible with macOS date fallback.
- **Tests first:** N/A (spec change)
- **Done when:** Section 8 includes all instrumentation-related validation items.

### Step 8: Update CLAUDE.md to reflect stats feature
- **Files:** `CLAUDE.md`
- **What:** Update the validation quick reference and deep validation sections to mention the new hooks, stats config option, and instrumentation-related checks. Keep CLAUDE.md in sync with specs.md per project rules.
- **Tests first:** N/A (spec change)
- **Done when:** CLAUDE.md reflects the stats/instrumentation additions.

## Risk Notes
- The macOS `date` command does not support `%N` (nanoseconds). The spec must mandate a fallback strategy (e.g., `python3 -c "import time; print(int(time.time()*1000))"` or `gdate` from coreutils). This adds a soft dependency on python3 or coreutils for millisecond-precision timing, which should be documented.
- The `.hook-state/` temp file approach creates one file per in-flight tool call. Stale files from interrupted sessions should be documented as a known consideration (suggest periodic cleanup).
- Registering hooks with matcher `".*"` means the instrumentation hooks fire on ALL tools, including non-Bash tools. The spec must ensure this does not conflict with the existing `validate-git-worktree.sh` hook which only matches `"Bash"`.
- The POSIX-only constraint means jq may not be available. Both hook scripts need grep/sed fallback for JSON parsing, consistent with the existing worktree hook pattern.
