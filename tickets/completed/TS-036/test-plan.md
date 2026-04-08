# Test Plan — TS-036

## Strategy
Manual validation -- this ticket modifies specification files (`specs.md`, `CLAUDE.md`) and a conventions skill file. Verification is structural: checking that all required sections exist, formats are correct, cross-references are consistent, and the conventions file stays within its line limit. After implementation, a fresh generation from `specs.md` should be tested (outer loop) to confirm the generated system includes `.context.md` support.

## Test Cases

### TC-1: `.context.md` format documented in specs.md section 3.8
- **Type:** integration
- **Target:** specs.md section 3.8 (Plan Artifacts)
- **Input:** Read specs.md section 3.8
- **Expected:** A `.context.md` template exists with sections for: relevant files examined, key patterns discovered, architecture notes, and gotchas. The template is marked as applicable to all ticket types (both standard and research).
- **Covers criteria:** AC-6 (format documented)

### TC-2: Planner writes `.context.md` after Phase 2
- **Type:** integration
- **Target:** specs.md `/ticket-system-plan` command spec
- **Input:** Read the plan command specification
- **Expected:** Between Phase 2 (codebase analysis) and Phase 3 (plan generation), there is an explicit step to write `.context.md` to `tickets/ongoing/PREFIX-XXX/`. The step is described as optional (may be omitted for minimal analysis).
- **Covers criteria:** AC-1, AC-2, AC-7

### TC-3: Implement agent reads `.context.md`
- **Type:** integration
- **Target:** specs.md `/ticket-system-implement` command spec
- **Input:** Read the implement command specification
- **Expected:** An early step reads `.context.md` from `tickets/ongoing/<ticket-id>/` if it exists. If absent, the agent proceeds normally.
- **Covers criteria:** AC-3

### TC-4: Verify agent reads `.context.md`
- **Type:** integration
- **Target:** specs.md `/ticket-system-verify` command spec
- **Input:** Read the verify command specification
- **Expected:** An early step reads `.context.md` from `tickets/ongoing/<ticket-id>/` (or `tickets/completed/<ticket-id>/` after completion) if it exists. If absent, the agent proceeds normally.
- **Covers criteria:** AC-4

### TC-5: Merge agent reads `.context.md`
- **Type:** integration
- **Target:** specs.md `/ticket-system-merge` command spec
- **Input:** Read the merge command specification
- **Expected:** An early step reads `.context.md` from the ticket directory if it exists. If absent, the agent proceeds normally.
- **Covers criteria:** AC-5

### TC-6: Conventions SKILL.md documents `.context.md` and stays under 500 lines
- **Type:** unit
- **Target:** `.claude/skills/ticket-system-conventions/SKILL.md`
- **Input:** Read the conventions file
- **Expected:** Contains a `.context.md` format section in the Plan Artifacts area. The `<!-- Lines: N/500 -->` comment reflects the accurate line count, and N is less than or equal to 500.
- **Covers criteria:** AC-6

### TC-7: Validation checklist includes `.context.md` items
- **Type:** integration
- **Target:** specs.md section 8 (Validation Checklist)
- **Input:** Read the validation section
- **Expected:** Checklist items verify: planner writes `.context.md`, downstream agents read it, fallback behavior when absent, format documented in conventions.
- **Covers criteria:** AC-1, AC-3, AC-4, AC-5, AC-6

### TC-8: CLAUDE.md updated to reference `.context.md`
- **Type:** unit
- **Target:** CLAUDE.md
- **Input:** Read the Deep Validation section
- **Expected:** Mentions `.context.md` as a plan artifact used by downstream agents.
- **Covers criteria:** AC-6 (documentation)

### TC-9: No regression in planning thoroughness
- **Type:** integration
- **Target:** specs.md `/ticket-system-plan` Phase 2
- **Input:** Read the plan command specification
- **Expected:** Phase 2 codebase analysis instructions are unchanged -- the planner still explores the codebase fully. `.context.md` writing happens after Phase 2 completes, not replacing it.
- **Covers criteria:** AC-7

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: Planner writes `.context.md` | TC-2, TC-7 |
| AC-2: `.context.md` captures relevant info | TC-1, TC-2 |
| AC-3: Implement reads `.context.md` | TC-3, TC-7 |
| AC-4: Verify reads `.context.md` | TC-4, TC-7 |
| AC-5: Merge reads `.context.md` | TC-5, TC-7 |
| AC-6: Format documented in conventions | TC-1, TC-6, TC-7, TC-8 |
| AC-7: No regression in planning thoroughness | TC-2, TC-9 |
