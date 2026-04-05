# Test Plan — TS-017

## Strategy
Manual verification of spec content. Since this ticket modifies `specs.md` (a specification document, not executable code), testing consists of verifying that the correct text is present in the right sections, that cross-references are consistent, and that the behavior described is unambiguous.

## Test Cases

### TC-1: Verify FAIL log entry includes attempt count
- **Type:** integration
- **Target:** specs.md section 4.2, `/ticket-system-verify` FAIL behavior
- **Input:** Read the "On VERDICT: FAIL" section of `/ticket-system-verify`
- **Expected:** The section specifies: (1) counting existing FAIL entries in the Log, (2) incrementing to get current attempt number, (3) appending a log entry with format including "VERDICT: FAIL (attempt N/$MAX_RETRY)", (4) committing the change
- **Covers criteria:** AC-1 (verifier records each FAIL verdict with running count)

### TC-2: Implement checks FAIL count before starting
- **Type:** integration
- **Target:** specs.md section 4.2, `/ticket-system-implement` prerequisites
- **Input:** Read the prerequisites section of `/ticket-system-implement`
- **Expected:** A prerequisite exists that counts FAIL entries in the ticket log and refuses to run if count >= `$MAX_RETRY`, with a message recommending re-planning
- **Covers criteria:** AC-2 (implement skill checks FAIL count and refuses if >= MAX_RETRY)

### TC-3: MAX_RETRY uses the variables system
- **Type:** unit
- **Target:** specs.md section 0 and section 4.2
- **Input:** Read section 0 variables table and the implement/verify sections
- **Expected:** `$MAX_RETRY` appears in the variables table with default 3, and the implement/verify sections reference `$MAX_RETRY` (not a hardcoded number)
- **Covers criteria:** AC-3 (MAX_RETRY configurable via variables system, default 3)

### TC-4: PASS implicitly resets the counter
- **Type:** unit
- **Target:** specs.md section 4.2, `/ticket-system-verify` PASS behavior
- **Input:** Read the "On VERDICT: PASS" section
- **Expected:** The PASS behavior moves the ticket to `completed/`, which means the FAIL log entries become historical. No explicit reset is needed because the ticket is done. The spec should NOT add any counter-reset logic on PASS.
- **Covers criteria:** AC-4 (on PASS, fail counter is implicitly reset)

### TC-5: Forced re-plan message text
- **Type:** unit
- **Target:** specs.md section 4.2, `/ticket-system-implement` prerequisites
- **Input:** Read the implement prerequisites section
- **Expected:** The exact text "The plan may need revision. Run /ticket-system-plan PREFIX-XXX to regenerate the plan." (or equivalent with `$MAX_RETRY` substitution) appears in the blocked message
- **Covers criteria:** AC-5 (forced re-plan message includes the specified text)

### TC-6: Run command handles retry limit
- **Type:** integration
- **Target:** specs.md section 4.2, `/ticket-system-run`
- **Input:** Read the run command specification
- **Expected:** The implement step handles the case where implement refuses to run due to retry limit, and the run command stops with an appropriate message suggesting re-planning
- **Covers criteria:** AC-2 (end-to-end: implement refuses and run propagates the failure)

### TC-7: Validation checklist updated
- **Type:** unit
- **Target:** specs.md section 8
- **Input:** Read the validation checklist
- **Expected:** Contains items verifying: (1) verify appends attempt count, (2) implement checks FAIL count, (3) re-plan message is present
- **Covers criteria:** AC-1, AC-2, AC-5 (validation coverage)

### TC-8: No hardcoded retry count
- **Type:** unit
- **Target:** specs.md sections 4.2
- **Input:** Search for hardcoded "3" in the context of retry/fail counting
- **Expected:** All references use `$MAX_RETRY`, not a hardcoded number. The only place "3" appears is in the section 0 defaults table.
- **Covers criteria:** AC-3 (configurable, not hardcoded)

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: Verifier records FAIL with running count | TC-1, TC-7 |
| AC-2: Implement checks FAIL count, refuses if >= MAX_RETRY | TC-2, TC-6, TC-7 |
| AC-3: MAX_RETRY configurable via variables, default 3 | TC-3, TC-8 |
| AC-4: PASS implicitly resets counter | TC-4 |
| AC-5: Forced re-plan message text | TC-5, TC-7 |
