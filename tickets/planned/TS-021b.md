---
id: TS-021b
title: "Add research implement/verify variant with findings and validation"
status: planned
priority: P2
type: feature
created: 2026-04-05 04:34:35
updated: 2026-04-05 04:36:22
dependencies:
  - TS-021a
assignee: unassigned
estimated_complexity: small
parent: TS-021
---

# TS-021b: Add research implement/verify variant with findings and validation

## Objective
Update specs.md to define the implement and verify phases for research-type tickets — implement produces findings.md, verify checks findings against validation-criteria.md.

## Context
Once the plan phase generates research artifacts (TS-021a), the implement and verify phases must also be adapted for research tickets. Currently both phases assume code changes: implement writes code, verify runs tests. For research tickets the implement phase should produce a `findings.md` document and the verify phase should check it against the `validation-criteria.md` defined in the plan.

## Acceptance Criteria
- [ ] `/ticket-system-implement` for research tickets produces `findings.md` following the structure defined in `research-plan.md`
- [ ] `/ticket-system-verify` for research tickets checks `findings.md` against `validation-criteria.md`
- [ ] The PASS/FAIL verdict and completion flow work the same as for code tickets
- [ ] The conventions skill documents the research pipeline variant

## Technical Approach
Update specs.md:
- Section 4.2 `/ticket-system-implement`: Add conditional: "If ticket type is `research`, follow research-plan.md to produce findings.md instead of code changes"
- Section 4.2 `/ticket-system-verify`: Add conditional: "If ticket type is `research`, verify findings.md against validation-criteria.md instead of running tests"

Findings document format:
```markdown
# Findings — PREFIX-XXX

## Summary
One-paragraph executive summary.

## Findings by Question
### Q1: <question>
<answer with evidence>

## Recommendation
Decision or next step informed by the findings.

## Sources
- Source 1
- Source 2
```

## Dependencies
- TS-021a — defines the research-plan.md and validation-criteria.md artifacts consumed by this phase

## Files Modified
- `specs.md` (section 4.2)

## Decisions
<!-- To be filled during implementation. -->

## Notes
- The same agents are used — only the artifacts and instructions differ.
- The `docs` type could also benefit from this variant but is less clear-cut. Start with `research` only.

## Log
- 2026-04-05 04:34:35: Ticket created as sub-ticket of TS-021 (split).
