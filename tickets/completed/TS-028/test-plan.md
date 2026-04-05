# Test Plan -- TS-028

## Strategy
Since this ticket modifies a specification file (`specs.md`), not executable code, testing is done via manual validation of the spec content. Each test case verifies that the correct text is present in the right location within specs.md. Validation uses `Grep` to confirm the presence of key phrases.

## Test Cases

### TC-1: .pending format documented in data model
- **Type:** integration
- **Target:** specs.md section 3.2 (Directory Structure)
- **Input:** Read section 3.2
- **Expected:** The directory structure listing includes `.tickets/.pending` with a description. The YAML format (operation, ticket, started, description) is documented.
- **Covers criteria:** AC-3 (format specification)

### TC-2: /ticket-system-schedule writes .pending
- **Type:** unit
- **Target:** specs.md section 4.2, `/ticket-system-schedule` Phase 4
- **Input:** Read the schedule command spec
- **Expected:** Phase 4 begins with writing `.tickets/.pending` (with operation: schedule) and ends with deleting it.
- **Covers criteria:** AC-1, AC-2

### TC-3: /ticket-system-plan writes .pending
- **Type:** unit
- **Target:** specs.md section 4.2, `/ticket-system-plan` Phase 1
- **Input:** Read the plan command spec
- **Expected:** Phase 1 begins with writing `.tickets/.pending` (with operation: plan) and Phase 4 ends with deleting it.
- **Covers criteria:** AC-1, AC-2

### TC-4: /ticket-system-merge writes .pending
- **Type:** unit
- **Target:** specs.md section 4.2, `/ticket-system-merge`
- **Input:** Read the merge command spec
- **Expected:** The merge command begins with writing `.tickets/.pending` (with operation: merge) and ends with deleting it.
- **Covers criteria:** AC-1, AC-2

### TC-5: /ticket-system-abort writes .pending and cleans up
- **Type:** unit
- **Target:** specs.md section 4.2, `/ticket-system-abort`
- **Input:** Read the abort command spec
- **Expected:** The abort command writes its own `.tickets/.pending` (with operation: abort) at the start and deletes it at the end. Pre-existing `.pending` files from interrupted operations are overwritten by the abort's own `.pending`.
- **Covers criteria:** AC-1, AC-2

### TC-6: /ticket-system-doctor checks .pending first
- **Type:** unit
- **Target:** specs.md section 4.2, `/ticket-system-doctor`
- **Input:** Read the doctor command spec
- **Expected:** The first diagnostic check (step 2, immediately after reading config) looks for `.tickets/.pending`. If found, it reports an [ISSUE] with the operation name, ticket ID, start time, and suggested recovery.
- **Covers criteria:** AC-4, AC-5

### TC-7: .pending format consistency
- **Type:** integration
- **Target:** All mutative command specs in section 4.2
- **Input:** Grep for `.pending` across all command specs
- **Expected:** All four mutative commands reference the same `.pending` format with `operation`, `ticket`, `started`, `description` fields.
- **Covers criteria:** AC-3

### TC-8: Doctor report template includes .pending check
- **Type:** unit
- **Target:** specs.md section 4.2, `/ticket-system-doctor` report template
- **Input:** Read the diagnostic report template in the doctor spec
- **Expected:** The report template shows the `.pending` check as the FIRST item (before status/directory mismatch), with example [OK] and [ISSUE] output.
- **Covers criteria:** AC-4, AC-5

### TC-9: Validation checklist updated
- **Type:** unit
- **Target:** specs.md section 8 (Validation Checklist)
- **Input:** Read section 8
- **Expected:** Checklist includes items for: mutative commands write/delete `.pending`, doctor checks `.pending` as first diagnostic.
- **Covers criteria:** AC-1, AC-2, AC-4, AC-5

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: All mutative commands write .pending before work | TC-2, TC-3, TC-4, TC-5, TC-7 |
| AC-2: All mutative commands delete .pending on success | TC-2, TC-3, TC-4, TC-5, TC-7 |
| AC-3: .pending file follows YAML format | TC-1, TC-7 |
| AC-4: Doctor checks .pending and reports as [ISSUE] | TC-6, TC-8 |
| AC-5: .pending check listed first in doctor diagnostics | TC-6, TC-8, TC-9 |
