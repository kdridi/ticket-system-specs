# Implementation Plan -- TS-014

## Overview
Add an optional `test_command` field to `.tickets/config.yml` so projects can specify their own test runner. The verifier agent will read this field and use it instead of the hardcoded `npm test` / `pytest` / `make test` patterns. This requires changes to four sections of `specs.md`: the config schema, the verifier agent permissions, the verify command behavior, and the init-project script.

## Steps
### Step 1: Add `test_command` to the config schema (Section 3.1)
- **Files:** `specs.md` (section 3.1, around line 187)
- **What:** Add `test_command: "npm test"  # Optional: custom test runner command` as a commented-out optional field in the config.yml example block. Add a note below the block explaining that `test_command` is optional and defaults to auto-detection if omitted.
- **Tests first:** N/A (spec file, no executable tests)
- **Done when:** Section 3.1 shows `test_command` as an optional field with a clear description

### Step 2: Add `Bash(bash -c *)` to the verifier agent permissions (Section 2.3)
- **Files:** `specs.md` (section 2.3, around line 110)
- **What:** In the agent profiles table, add `Bash(bash -c *)` to the `ticket-system-verifier` row's Allowed Tools column. This is needed because the configured test command will be executed via `bash -c "<test_command>"` to support arbitrary commands with arguments and pipes.
- **Tests first:** N/A (spec file)
- **Done when:** The verifier row in the agent table includes `Bash(bash -c *)` alongside the existing test patterns

### Step 3: Update `/ticket-system-verify` behavior to use `test_command` (Section 4.2)
- **Files:** `specs.md` (section 4.2, the `/ticket-system-verify` specification, around line 535)
- **What:** In the verification checklist paragraph, update the "Run the full test suite" instruction to: first read `test_command` from `.tickets/config.yml`; if set, run `bash -c "<test_command>"` in the worktree; if not set, fall back to auto-detection (try `npm test`, `pytest`, `make test` based on what is available). Make this the explicit first item in the verification checklist.
- **Tests first:** N/A (spec file)
- **Done when:** The verify command specification describes the config-first, auto-detect-fallback test execution flow

### Step 4: Update `init-project.sh` generation rules (Section 5.4)
- **Files:** `specs.md` (section 5.4, around line 783)
- **What:** Add a new sub-item to the `init-project.sh` requirements: the generated `.tickets/config.yml` must include a commented-out `# test_command: "npm test"` line with a brief inline comment explaining it is optional.
- **Tests first:** N/A (spec file)
- **Done when:** Section 5.4 explicitly requires `init-project.sh` to include the commented-out `test_command` line

### Step 5: Update the validation checklist (Section 8)
- **Files:** `specs.md` (section 8, around line 917)
- **What:** Add a validation item under "Frontmatter and permissions" confirming that the verifier agent includes `Bash(bash -c *)` in its allowed tools. Add a validation item confirming that `init-project.sh` generates a config with the commented-out `test_command` field.
- **Tests first:** N/A (spec file)
- **Done when:** Section 8 includes checklist items for the new `test_command` functionality

## Risk Notes
- The `Bash(bash -c *)` pattern is broader than the existing specific test runner patterns. This is an intentional trade-off: the verifier still runs in `bypassPermissions` mode and cannot write files (it uses `plan` permissionMode -- correction: it uses `bypassPermissions` but the SKILL.md instruction says "NEVER attempt to fix code"). The behavioral constraint is enforced by the skill instructions, not by bash permissions. The existing specific patterns (`npm test *`, `pytest *`, `make test *`) should be kept for backward compatibility with projects that do not set `test_command`.
- The `bash -c` wrapper is necessary because test commands may contain spaces, flags, and pipes (e.g., `npx vitest run --coverage`). Running the raw command without `bash -c` would require splitting it, which is fragile.
