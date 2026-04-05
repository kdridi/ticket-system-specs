---
id: TS-020
title: "Add anti-drift guard to /ticket-system-implement"
status: planned
priority: P2
type: feature
created: 2026-04-04 12:00:00
updated: 2026-04-05 04:36:22
dependencies: []
assignee: unassigned
estimated_complexity: small
---

# TS-020: Add anti-drift guard to /ticket-system-implement

## Objective
Add an explicit instruction in the implement skill that requires the coder agent to verify each modified file against the implementation plan, logging any unplanned file modifications.

## Context
The coder agent runs with `bypassPermissions` because the plan has been human-approved. However, LLMs can drift from the plan — "cleaning up" unrelated files, modifying dependencies, or making scope-expanding changes that seem logical but were not approved. The current spec has no mechanism to detect this drift.

Both audit reviews identified this as a risk. Rather than changing the permission model (which would add friction to the happy path), this ticket adds a lightweight verification instruction.

## Acceptance Criteria
- [ ] The implement skill includes an explicit instruction: "Before each commit, verify that ALL modified files are listed in implementation-plan.md. If a file not in the plan was modified, add a log entry explaining why and flag it for user review."
- [ ] The "Files Modified" section of the ticket is updated after implementation with the actual list of modified files
- [ ] Any unplanned file modification is highlighted in the ticket log with prefix "[DRIFT]"
- [ ] The verify skill checks for [DRIFT] entries and includes them in its report

## Technical Approach
Update specs.md section 4.2 `/ticket-system-implement`:
- Add after step 5c: "Before committing, run `git diff --name-only` and compare against files listed in implementation-plan.md. If any file is not in the plan, add a [DRIFT] log entry: `[DRIFT] Modified <file> — reason: <explanation>`. Continue with the commit."

Update specs.md section 4.2 `/ticket-system-verify`:
- Add to verification checklist: "Check for [DRIFT] entries in the ticket log. If present, report them prominently and flag for user attention."

## Dependencies
<!-- None -->

## Files Modified
- `specs.md` (section 4.2)

## Decisions
<!-- To be filled during implementation. -->

## Notes
- This does NOT prevent drift — it makes drift visible. The coder can still modify unplanned files, but it must document why.
- This is a prompt-level guard, not a technical enforcement. It relies on the LLM following instructions, which is the same trust model as the rest of the system.
- Future enhancement: extract a file allowlist from the plan and enforce it in the agent's bash permissions (would require dynamic agent configuration).

## Log
- 2026-04-04 12:00:00: Ticket created from audit review (W4 + C3).
