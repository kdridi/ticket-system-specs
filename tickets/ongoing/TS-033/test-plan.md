# Test Plan — TS-033

## Strategy
Manual validation through text search and structural review of specs.md and CLAUDE.md. Since this is a spec-only refactor (no generated code), testing consists of verifying completeness of removal, consistency of replacements, and preservation of unrelated content.

## Test Cases

### TC-1: No AskUserQuestion in schedule or plan
- **Type:** search validation
- **Target:** specs.md sections 4.2 (schedule and plan commands)
- **Input:** grep for `AskUserQuestion` in specs.md
- **Expected:** Only occurrence is in `/ticket-system-abort` (line ~782) and section 2.3 note (updated to reference only abort). Zero occurrences in schedule or plan command specs.
- **Covers criteria:** AC-1, AC-2

### TC-2: No --yes or yes bypass in schedule, plan, run, run-all
- **Type:** search validation
- **Target:** specs.md sections 4.2 (schedule, plan, run, run-all commands)
- **Input:** grep for `--yes` and `yes` bypass patterns in specs.md
- **Expected:** Only occurrence of `--yes` is in `/ticket-system-abort` (line ~782). Zero occurrences in schedule, plan, run, or run-all specs.
- **Covers criteria:** AC-1, AC-2, AC-3, AC-4

### TC-3: Pipeline overview updated
- **Type:** content review
- **Target:** specs.md section 4.1 (line ~483)
- **Input:** read the pipeline overview paragraph
- **Expected:** No `[HUMAN APPROVAL]` markers. No `AskUserQuestion` mention. No `--yes` mention. Pipeline reads as a clean sequence without interactive gates. Stop-on-conflict concept is mentioned for schedule and plan.
- **Covers criteria:** AC-8

### TC-4: Decision D-2 rewritten
- **Type:** content review
- **Target:** specs.md section 6, decision D-2
- **Input:** read D-2 row
- **Expected:** Describes stop-on-conflict model instead of human validation gates. References `/ticket-system-edit` as the resolution path.
- **Covers criteria:** AC-5

### TC-5: Decision D-12 rewritten
- **Type:** content review
- **Target:** specs.md section 6, decision D-12
- **Input:** read D-12 row
- **Expected:** Describes AskUserQuestion usage only for abort confirmation gate. No references to schedule/plan gates, self-evaluation, or --yes bypass.
- **Covers criteria:** AC-6

### TC-6: D-7 and D-11 cleaned
- **Type:** content review
- **Target:** specs.md section 6, decisions D-7 and D-11
- **Input:** read D-7 and D-11 rows
- **Expected:** No "human gate" references in either rationale.
- **Covers criteria:** AC-7

### TC-7: Section 2.4 auto-invocation table updated
- **Type:** content review
- **Target:** specs.md section 2.4 table
- **Input:** read the table rows for schedule, plan, run, run-all
- **Expected:** No "human gate" in any Reason column.
- **Covers criteria:** AC-9

### TC-8: Section 8 validation checklist updated
- **Type:** search validation
- **Target:** specs.md section 8
- **Input:** grep for human gate, AskUserQuestion (excluding abort), --yes forwarding items
- **Expected:** No checklist items about schedule/plan human gates. No checklist items about --yes forwarding in run/run-all. New checklist items for stop-on-conflict behavior in schedule and plan. Abort AskUserQuestion item preserved.
- **Covers criteria:** AC-10

### TC-9: CLAUDE.md updated
- **Type:** search validation
- **Target:** CLAUDE.md
- **Input:** grep for `AskUserQuestion`, `--yes`, `human gate`
- **Expected:** Zero occurrences of these terms except possibly in the context of abort's confirmation gate.
- **Covers criteria:** AC-11

### TC-10: Abort confirmation gate preserved
- **Type:** content review
- **Target:** specs.md section 4.2 (abort command, line ~782)
- **Input:** read the abort command spec
- **Expected:** `AskUserQuestion` confirmation gate is present and unchanged. `--yes` bypass is still available for abort.
- **Covers criteria:** AC-12

### TC-11: No new bypass mechanism introduced
- **Type:** search validation
- **Target:** specs.md, CLAUDE.md
- **Input:** grep for `bypass`, `skip`, `auto-approve` (excluding abort and existing unrelated uses)
- **Expected:** No new bypass patterns introduced as a replacement for --yes in schedule/plan/run/run-all.
- **Covers criteria:** AC-13

### TC-12: Section 2.3 AskUserQuestion note updated
- **Type:** content review
- **Target:** specs.md section 2.3, AskUserQuestion note (line ~133)
- **Input:** read the note
- **Expected:** References only abort, not schedule/plan. Still explains why AskUserQuestion does not need to be listed in Allowed Tools.
- **Covers criteria:** AC-1, AC-2

### TC-13: Schedule split proposal flow updated
- **Type:** content review
- **Target:** specs.md section 4.2, schedule Phase 2-3
- **Input:** read the schedule command spec
- **Expected:** When a ticket needs splitting, the command stops with a structured message telling the user to split manually (create sub-tickets via /ticket-system-create, reject the parent, schedule sub-tickets). No interactive "Accept split?" prompt.
- **Covers criteria:** AC-1

### TC-14: Plan conflict detection present
- **Type:** content review
- **Target:** specs.md section 4.2, plan command
- **Input:** read the plan command spec
- **Expected:** Has conflict detection: empty objective, < 2 acceptance criteria, unmappable scope, unresolved dependencies cause a stop with a structured message directing to /ticket-system-edit.
- **Covers criteria:** AC-2

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: schedule no gate/--yes | TC-1, TC-2, TC-13 |
| AC-2: plan no gate/--yes | TC-1, TC-2, TC-14 |
| AC-3: run no --yes | TC-2 |
| AC-4: run-all no --yes | TC-2 |
| AC-5: D-2 rewritten | TC-4 |
| AC-6: D-12 rewritten | TC-5 |
| AC-7: D-7, D-11 cleaned | TC-6 |
| AC-8: Section 4.1 updated | TC-3 |
| AC-9: Section 2.4 updated | TC-7 |
| AC-10: Section 8 updated | TC-8 |
| AC-11: CLAUDE.md updated | TC-9 |
| AC-12: abort preserved | TC-10 |
| AC-13: no new bypass | TC-11 |
