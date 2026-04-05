# Implementation Plan — TS-020

## Overview
Add an anti-drift guard to `/ticket-system-implement` in specs.md. The guard requires the coder agent to compare modified files against the implementation plan before each commit, log any unplanned modifications with a `[DRIFT]` prefix, and update the "Files Modified" section. The verify skill is updated to check for and prominently report `[DRIFT]` entries. The validation checklist in section 8 is updated to cover both new behaviors.

## Steps

### Step 1: Add drift detection instructions to `/ticket-system-implement`
- **Files:** `specs.md` (section 4.2, `/ticket-system-implement` specification, lines 546-554)
- **What:** Insert a new sub-step after step 5c ("Verify") and before step 5d ("Commit"). The new sub-step instructs the coder agent to:
  1. Run `git diff --name-only` to get the list of modified files.
  2. Compare each modified file against the files listed in `implementation-plan.md`.
  3. For any file not listed in the plan, add a `[DRIFT]` log entry to the ticket: `[DRIFT] Modified <file> — reason: <explanation>`.
  4. Continue with the commit regardless (drift is logged, not blocked).
  Also update step 6 ("After all steps") to explicitly require updating the "Files Modified" section with the actual list of files changed (comparing plan vs reality).
- **Tests first:** N/A (spec file, no executable tests)
- **Done when:** The `/ticket-system-implement` section in specs.md includes drift detection between verify and commit steps, and the "Files Modified" update instruction is explicit.

### Step 2: Add drift reporting to `/ticket-system-verify`
- **Files:** `specs.md` (section 4.2, `/ticket-system-verify` specification, lines 556-585)
- **What:** Add a new item to the verification checklist (after the existing checks): "Check for `[DRIFT]` entries in the ticket log. If any are present, list them prominently in the verification report and flag for user attention. Drift entries do not automatically cause a FAIL verdict but must be reported."
- **Tests first:** N/A (spec file)
- **Done when:** The `/ticket-system-verify` section includes drift entry checking in its verification checklist.

### Step 3: Update validation checklist in section 8
- **Files:** `specs.md` (section 8, validation checklist, around lines 987-991)
- **What:** Add validation items:
  - `/ticket-system-implement` includes a drift detection step (compare modified files against plan, log `[DRIFT]` entries).
  - `/ticket-system-implement` updates the "Files Modified" section of the ticket after implementation.
  - `/ticket-system-verify` checks for `[DRIFT]` entries and reports them prominently.
- **Tests first:** N/A (spec file)
- **Done when:** Section 8 includes checklist items covering the drift guard in both implement and verify skills.

### Step 4: Update CLAUDE.md to reflect drift guard behavior
- **Files:** `CLAUDE.md` (validation quick reference or key design decisions, if relevant)
- **What:** Review CLAUDE.md for any sections that reference implement/verify behavior. If the validation checklist section or key design decisions mention relevant behaviors, add a note about the drift guard. Per project rules, CLAUDE.md must stay in sync with specs.md.
- **Tests first:** N/A
- **Done when:** CLAUDE.md reflects the drift guard addition if any relevant sections exist.

## Risk Notes
- The changes are additive (new instructions inserted, no existing instructions removed), so the risk of breaking existing behavior is low.
- The drift detection is prompt-level only — it relies on the LLM following the instruction. This is consistent with the system's existing trust model.
- Care must be taken with the exact insertion point in the implement spec to maintain logical step ordering (verify tests, then check drift, then commit).
