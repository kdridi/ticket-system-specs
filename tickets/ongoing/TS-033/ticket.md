---
id: TS-033
title: "Remove all human gates and --yes bypass from schedule, plan, run, and run-all commands"
status: ongoing
priority: P1
type: refactor
created: 2026-04-08 12:51:03
updated: 2026-04-08 13:02:52
dependencies: []
assignee: ai
estimated_complexity: medium
---

# TS-033: Remove all human gates and --yes bypass from schedule, plan, run, and run-all commands

## Objective
Eliminate all `AskUserQuestion` human gates and all `--yes` / `yes` bypass options from the ticket system pipeline. Replace with deterministic stop-on-conflict behavior: when a command succeeds cleanly, it proceeds silently; when it detects a problem, it stops with a clear message directing the user to fix the ticket via `/ticket-system-edit` and retry. This applies to `/ticket-system-schedule`, `/ticket-system-plan`, `/ticket-system-run`, and `/ticket-system-run-all`. The `/ticket-system-abort` confirmation gate is unaffected (destructive action, separate concern).

## Context
The current pipeline has `AskUserQuestion` human gates at the schedule and plan stages, with a `--yes` bypass that propagates through run and run-all. In practice, forked agents frequently miss the `--yes` flag, causing pipelines to stall waiting for input. This makes the commands non-composable and frustrating. The real need is simpler: either the command works or it doesn't. When it doesn't, the user should be told what to fix.

The human gate concept is a single design decision (D-2 + D-12 in specs.md section 6) that touches schedule, plan, run, run-all, and the validation checklist. Changing it piecemeal would leave the spec internally inconsistent. This ticket handles it as one atomic change.

Supersedes: TS-031, TS-032 (both rejected and merged here).

## Acceptance Criteria
- [ ] `/ticket-system-schedule` has no `AskUserQuestion` gate and no `--yes` / `yes` argument handling. Clean scheduling proceeds silently. On conflict (needs split, missing fields, dependency issues), the command stops with a structured message and directs the user to `/ticket-system-edit`.
- [ ] `/ticket-system-plan` has no `AskUserQuestion` gate and no `--yes` / `yes` argument handling. Clean planning proceeds silently: plan artifacts are written and committed. On conflict (empty objective, < 2 acceptance criteria, unmappable scope, unresolved deps), the command stops with a structured message and directs the user to `/ticket-system-edit`.
- [ ] `/ticket-system-run` no longer accepts or forwards `--yes`. It chains plan/implement/verify/merge without any human prompts (plan runs silently on success).
- [ ] `/ticket-system-run-all` no longer accepts or forwards `--yes`. It chains runs without any human prompts.
- [ ] Decision D-2 in specs.md section 6 is rewritten to describe the stop-on-conflict model instead of human validation gates.
- [ ] Decision D-12 in specs.md section 6 is rewritten or removed (no more AskUserQuestion gates in schedule/plan).
- [ ] The `--yes` bypass references in D-7, D-11, and D-12 rationale text are removed.
- [ ] Section 4.1 pipeline overview no longer mentions `[HUMAN APPROVAL]` for schedule and plan.
- [ ] Section 2.4 auto-invocation table reasons no longer reference "human gate" for schedule and plan.
- [ ] Section 8 validation checklist items referencing human gates, `AskUserQuestion`, `--yes` forwarding, and self-evaluation in schedule/plan are removed or rewritten.
- [ ] `CLAUDE.md` is updated wherever it references `--yes` bypass, human gates, or `AskUserQuestion` at schedule/plan stages.
- [ ] The `/ticket-system-abort` confirmation gate (AskUserQuestion, destructive action) is preserved unchanged.
- [ ] No new bypass mechanism is introduced as a replacement.

## Technical Approach
### specs.md changes
1. **Section 4.1** — Remove `[HUMAN APPROVAL]` from the pipeline diagram. Remove mentions of `--yes` bypass and `AskUserQuestion` from the overview paragraph.
2. **Section 4.2 `/ticket-system-schedule`** — Remove Phase 3 (human gate). Rename Phase 4 to Phase 3. Remove all `--yes`/`yes` references. Add conflict-detection heuristics to the evaluation phase: on conflict, emit a structured stop message listing problems and suggesting `/ticket-system-edit`. On clean pass, proceed directly to execution.
3. **Section 4.2 `/ticket-system-plan`** — Remove Phase 4 (human gate). Remove all `--yes`/`yes` references. Add conflict-detection to plan generation: if plan cannot be built cleanly (empty objective, < 2 criteria, unresolvable scope), stop with a message directing to `/ticket-system-edit`. On success, commit and end.
4. **Section 4.2 `/ticket-system-run`** — Remove `--yes` forwarding logic. Remove the "Note on human gates" paragraph. Simplify: it just chains the four sub-skills.
5. **Section 4.2 `/ticket-system-run-all`** — Remove `--yes` forwarding logic. Remove the "Note on human gates" paragraph. Remove `--yes` from argument description.
6. **Section 6 decisions** — Rewrite D-2: "Schedule and plan use stop-on-conflict instead of interactive gates. Clean operations proceed silently; conflicts stop with a message directing to /ticket-system-edit." Rewrite or remove D-12 (no more AskUserQuestion gates). Clean up D-7 and D-11 rationale text.
7. **Section 8 checklist** — Remove/rewrite items about human gates, `AskUserQuestion`, `--yes` forwarding, self-evaluation in schedule/plan forks.

### CLAUDE.md changes
- Update the "Deep Validation" bullet that references `AskUserQuestion human gates in schedule and plan forks with self-evaluation and --yes bypass`.
- Update any other references to human gates or `--yes`.

## Dependencies
None.

## Files Modified
- `specs.md` — Sections 2.3, 2.4, 4.1, 4.2 (schedule, plan, run, run-all, help), 6 (D-2, D-7, D-11, D-12), 8 (validation checklist)
- `CLAUDE.md` — Deep Validation bullet, Key Design Decisions bullet

## Decisions
<!-- Design decisions made during this ticket. -->

## Notes
- The `/ticket-system-abort` confirmation gate (AskUserQuestion for destructive action) is a separate concern and stays unchanged.
- The `AskUserQuestion` note in section 2.3 about it not needing to be listed in allowed tools may need rewording since it's now only used by abort.
- No new bypass mechanism should replace `--yes`. The whole point is to eliminate bypass patterns.
- The schedule command's split proposal flow needs rethinking: currently splits are proposed during the human gate. With stop-on-conflict, if a ticket needs splitting, the command should stop and tell the user to split manually (create sub-tickets via `/ticket-system-create`, reject the parent, then schedule the sub-tickets).

## Log
- 2026-04-08 12:51:03: Ticket created. Supersedes TS-031 and TS-032.
- 2026-04-08 12:53:13: Scheduled to roadmap at position 1.
- 2026-04-08 12:55:24: Activated — moved to ongoing, worktree created.
- 2026-04-08 13:02:52: Implementation complete — all 11 steps executed across specs.md and CLAUDE.md. Removed human gates, --yes bypass, AskUserQuestion from schedule/plan. Replaced with stop-on-conflict model. Updated decisions D-2, D-7, D-11, D-12. Updated validation checklist. Preserved abort confirmation gate.
