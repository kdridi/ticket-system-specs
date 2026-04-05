# Test Plan — TS-020

## Strategy
Manual validation of the spec file changes. Since this ticket modifies `specs.md` (a specification document, not executable code), testing consists of verifying the text content is correct, complete, and consistent. After generation, the generated skills can be inspected to confirm the instructions propagated correctly.

## Test Cases

### TC-1: Drift detection step exists in implement spec
- **Type:** manual inspection
- **Target:** specs.md section 4.2 `/ticket-system-implement`
- **Input:** Read the implement specification steps
- **Expected:** A sub-step exists between "Verify" (tests) and "Commit" that instructs the coder to run `git diff --name-only`, compare against `implementation-plan.md`, and log `[DRIFT]` entries for unplanned files
- **Covers criteria:** AC-1 (implement skill includes explicit drift detection instruction)

### TC-2: Files Modified update instruction exists
- **Type:** manual inspection
- **Target:** specs.md section 4.2 `/ticket-system-implement` step 6
- **Input:** Read the post-implementation steps
- **Expected:** Step 6 explicitly requires updating the "Files Modified" section of the ticket with the actual list of modified files
- **Covers criteria:** AC-2 (Files Modified section updated after implementation)

### TC-3: DRIFT prefix format is specified
- **Type:** manual inspection
- **Target:** specs.md section 4.2 `/ticket-system-implement`
- **Input:** Read the drift detection step
- **Expected:** The log entry format uses `[DRIFT]` prefix: `[DRIFT] Modified <file> — reason: <explanation>`
- **Covers criteria:** AC-3 (unplanned modifications highlighted with [DRIFT] prefix)

### TC-4: Verify skill checks for DRIFT entries
- **Type:** manual inspection
- **Target:** specs.md section 4.2 `/ticket-system-verify`
- **Input:** Read the verification checklist
- **Expected:** The checklist includes checking for `[DRIFT]` entries in the ticket log, reporting them prominently, and flagging for user attention
- **Covers criteria:** AC-4 (verify skill checks for [DRIFT] entries)

### TC-5: Validation checklist covers drift guard
- **Type:** manual inspection
- **Target:** specs.md section 8
- **Input:** Read the validation checklist
- **Expected:** At least two new checklist items: one for implement drift detection, one for verify drift reporting
- **Covers criteria:** AC-1, AC-3, AC-4 (validation ensures generated output includes drift guard)

### TC-6: CLAUDE.md stays in sync
- **Type:** manual inspection
- **Target:** CLAUDE.md
- **Input:** Read CLAUDE.md validation and design sections
- **Expected:** Any relevant sections are updated to reflect the drift guard behavior
- **Covers criteria:** Project rule (CLAUDE.md must stay in sync with specs.md)

### TC-7: No hardcoded prefixes in new text
- **Type:** manual inspection
- **Target:** All new text added to specs.md
- **Input:** Review all inserted text
- **Expected:** No hardcoded ticket prefixes (e.g., "TS-", "PROJ-"). Uses `PREFIX-XXX` placeholder or references config
- **Covers criteria:** Project constraint (no hardcoded prefixes)

### TC-8: Step ordering is logical
- **Type:** manual inspection
- **Target:** specs.md section 4.2 `/ticket-system-implement` step 5
- **Input:** Read the full step 5 sequence
- **Expected:** Order is: (a) tests first, (b) implement, (c) verify tests pass, (d) drift check, (e) commit. The drift check happens after tests pass but before commit, which is the logical place
- **Covers criteria:** AC-1 (instruction says "before each commit")

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: Implement skill includes drift detection instruction | TC-1, TC-5, TC-8 |
| AC-2: Files Modified section updated after implementation | TC-2 |
| AC-3: Unplanned modifications highlighted with [DRIFT] prefix | TC-3, TC-5, TC-7 |
| AC-4: Verify skill checks for [DRIFT] entries | TC-4, TC-5 |
