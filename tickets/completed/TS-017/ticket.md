---
id: TS-017
title: "Add retry counter for implement-verify loop with forced re-plan"
status: completed
priority: P1
type: feature
created: 2026-04-04 12:00:00
updated: 2026-04-05 15:19:23
dependencies:
  - TS-015
assignee: unassigned
estimated_complexity: small
---

# TS-017: Add retry counter for implement-verify loop with forced re-plan

## Objective
Prevent infinite implement→verify→FAIL loops by tracking the number of consecutive verification failures and forcing a return to the planning phase after a configurable threshold.

## Context
When `/ticket-system-verify` returns VERDICT: FAIL, the user typically relaunches `/ticket-system-implement` to fix the issues. If the plan is fundamentally flawed, this creates an unproductive loop with no circuit breaker. Neither the system nor the user gets a signal that the plan itself needs revision.

Identified in both audit reviews as a missing safeguard.

## Acceptance Criteria
- [ ] The verifier records each FAIL verdict in the ticket's Log section with a running count (e.g., "VERDICT: FAIL (attempt 2/3)")
- [ ] The implement skill checks the FAIL count before starting. If count >= MAX_RETRY, it refuses to run and recommends re-planning.
- [ ] MAX_RETRY is configurable via the variables system (TS-015), default: 3
- [ ] On a VERDICT: PASS, the fail counter is implicitly reset (ticket moves to completed)
- [ ] The forced re-plan message includes: "The plan may need revision. Run /ticket-system-plan PREFIX-XXX to regenerate the plan."

## Technical Approach
Update specs.md:
- Section 4.2 `/ticket-system-verify`: On FAIL, append log entry with attempt count. Count is determined by scanning existing FAIL entries in the log.
- Section 4.2 `/ticket-system-implement`: Before starting, count FAIL entries in the ticket log. If >= MAX_RETRY, STOP and report.
- Section 0 (variables): MAX_RETRY = 3

The counting mechanism is simple: `grep -c "VERDICT: FAIL" ticket.md`.

## Dependencies
- TS-015 (MAX_RETRY variable definition)

## Files Modified
- `specs.md` (sections 4.2, 8) — verify FAIL attempt counting, implement retry limit prerequisite, run retry limit handling, validation checklist
- `CLAUDE.md` — deep validation reference updated to mention retry counter

## Decisions
<!-- To be filled during implementation. -->

## Notes
- The re-plan does not need to be automatic. The user decides whether to re-plan or to manually fix the plan and retry.
- This is a prerequisite for the future `/ticket-system-run` automated orchestration (TS-022).

## Log
- 2026-04-04 12:00:00: Ticket created from audit review (W14 + M1).
- 2026-04-05 15:13:10: Ticket activated, moved to ongoing.
- 2026-04-05 15:17:08: Implementation complete. Updated specs.md (verify FAIL counting, implement retry gate, run retry handling, validation checklist) and CLAUDE.md.
- 2026-04-05 15:19:23: VERDICT: PASS — Ticket completed.
