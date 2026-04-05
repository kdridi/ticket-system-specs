# Implementation Plan — TS-017

## Overview
Add a retry counter mechanism to the implement-verify loop in specs.md. When `/ticket-system-verify` returns VERDICT: FAIL, it records the attempt count in the ticket log. When `/ticket-system-implement` runs, it checks the fail count and refuses to proceed if it equals or exceeds `$MAX_RETRY`, directing the user to re-plan instead.

## Steps

### Step 1: Update `/ticket-system-verify` FAIL behavior in specs.md section 4.2
- **Files:** `specs.md` (section 4.2, `/ticket-system-verify`)
- **What:** Modify the "On VERDICT: FAIL" section. Currently it says "do nothing. The ticket stays in `ongoing/`." Change it to:
  1. Count existing FAIL entries in the ticket's Log section (grep for "VERDICT: FAIL" log entries).
  2. Increment the count to get the current attempt number.
  3. Append a log entry: `VERDICT: FAIL (attempt N/$MAX_RETRY) — <summary of failures>`.
  4. Update frontmatter `updated` timestamp.
  5. Commit: `PREFIX-XXX: Verify FAIL (attempt N/$MAX_RETRY)`
  6. The ticket stays in `ongoing/`.
- **Tests first:** N/A (spec change, not code)
- **Done when:** The verify FAIL section includes attempt counting and structured log entries.

### Step 2: Update `/ticket-system-implement` prerequisites in specs.md section 4.2
- **Files:** `specs.md` (section 4.2, `/ticket-system-implement`)
- **What:** Add a new prerequisite check (item 4 in the prerequisites list) that runs before implementation begins:
  1. Count FAIL entries in the ticket's Log section (grep for "VERDICT: FAIL" log entries).
  2. If count >= `$MAX_RETRY`, STOP and output: "Implementation blocked: $MAX_RETRY consecutive verification failures reached. The plan may need revision. Run /ticket-system-plan PREFIX-XXX to regenerate the plan."
  3. Do NOT proceed with implementation.
- **Tests first:** N/A (spec change, not code)
- **Done when:** The implement command has a retry-count gate in its prerequisites.

### Step 3: Update `/ticket-system-run` to handle retry limit in specs.md section 4.2
- **Files:** `specs.md` (section 4.2, `/ticket-system-run`)
- **What:** In the verify step (step 5), add a note that if implement was blocked by the retry limit, the run command should also stop and suggest re-planning. Also update the implement step (step 4) to handle the case where implement refuses to run due to retry limit: report "STOPPED at implement step — retry limit reached" and suggest re-planning.
- **Tests first:** N/A (spec change, not code)
- **Done when:** The run orchestration handles the retry-limit-blocked scenario.

### Step 4: Update the validation checklist in specs.md section 8
- **Files:** `specs.md` (section 8)
- **What:** Add validation items:
  - `/ticket-system-verify` appends attempt count to FAIL log entries.
  - `/ticket-system-implement` checks FAIL count against `$MAX_RETRY` before starting.
  - The forced re-plan message text is present in the implement skill spec.
- **Tests first:** N/A (spec change, not code)
- **Done when:** Section 8 includes retry counter validation items.

### Step 5: Update CLAUDE.md to reflect the retry counter feature
- **Files:** `CLAUDE.md`
- **What:** If needed, add mention of the retry counter in the validation quick reference or key design decisions. Review CLAUDE.md for any references that need updating based on the new behavior.
- **Tests first:** N/A (documentation)
- **Done when:** CLAUDE.md is consistent with the updated specs.md.

### Step 6: Update ticket metadata
- **Files:** `tickets/ongoing/TS-017/ticket.md`
- **What:** Update `## Files Modified` with actual files changed, add log entries for implementation, and update the `updated` timestamp.
- **Tests first:** N/A (ticket housekeeping)
- **Done when:** Ticket reflects all changes made.

## Risk Notes
- The counting mechanism (`grep -c "VERDICT: FAIL"` on the log section) must be clearly scoped to the Log section to avoid false matches from other parts of the ticket (e.g., the acceptance criteria text). The spec should specify scanning Log entries specifically, not the entire file.
- The `$MAX_RETRY` variable is resolved at generation time, so the generated skill files will contain the literal number (default 3), not a runtime variable. This is consistent with the existing variables system from TS-015.
- Need to ensure the FAIL log entry format is consistent so counting works reliably. The format should be specified precisely (e.g., entries matching the pattern "VERDICT: FAIL (attempt").
