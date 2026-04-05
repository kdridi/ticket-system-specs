---
id: TS-021a
title: "Add research artifacts to plan phase for research-type tickets"
status: ongoing
priority: P2
type: feature
created: 2026-04-05 04:34:35
updated: 2026-04-05 15:58:53
dependencies: []
assignee: unassigned
estimated_complexity: small
parent: TS-021
---

# TS-021a: Add research artifacts to plan phase for research-type tickets

## Objective
Update specs.md to define research-plan.md and validation-criteria.md as plan-phase artifacts for tickets with type: research, replacing implementation-plan.md and test-plan.md.

## Context
The ticket system supports a `research` type in the frontmatter, but the plan phase always generates `implementation-plan.md` and `test-plan.md`. For research tickets ("Evaluate migration to GraphQL", "Compare state management libraries"), these artifacts are meaningless — the deliverable is a findings document, not code. This ticket addresses the plan phase specifically by defining appropriate research artifacts.

## Acceptance Criteria
- [ ] specs.md section 3 defines `research-plan.md` format (research questions, sources to investigate, findings document structure, decision framework)
- [ ] specs.md section 3 defines `validation-criteria.md` format (completeness criteria, evidence requirements, deliverable format)
- [ ] `/ticket-system-plan` generates `research-plan.md` and `validation-criteria.md` when ticket type is `research`
- [ ] Plan approval gate works the same for research tickets as for code tickets

## Technical Approach
Update specs.md:
- Section 3.8: Add `research-plan.md` and `validation-criteria.md` artifact formats
- Section 4.2 `/ticket-system-plan`: Add conditional logic: "If ticket type is `research`, generate research-plan.md and validation-criteria.md instead of implementation-plan.md and test-plan.md"

Research plan format:
```markdown
# Research Plan — PREFIX-XXX

## Questions to Answer
1. Question 1
2. Question 2

## Sources to Investigate
- Source category 1
- Source category 2

## Findings Document Structure
- Section 1: ...
- Section 2: ...

## Decision Framework
How the findings should inform a decision.
```

Validation criteria format:
```markdown
# Validation Criteria — PREFIX-XXX

## Completeness Criteria
- All research questions answered with evidence
- ...

## Evidence Requirements
- Sources cited for each finding
- ...

## Deliverable Format
Expected structure of findings.md
```

## Dependencies
<!-- None -->

## Files Modified
- `specs.md` (sections 3.8, 4.2, 5.2, 6 D-13)
- `CLAUDE.md` (Constraints section)

## Decisions
<!-- To be filled during implementation. -->

## Notes
- The same agents are used — only the artifacts and instructions differ.
- TS-021b depends on this ticket to define the research artifacts used in implement/verify.

## Log
- 2026-04-05 04:34:35: Ticket created as sub-ticket of TS-021 (split).
- 2026-04-05 15:54:10: Ticket activated, moved to ongoing.
- 2026-04-05 15:58:53: Implementation complete. All 4 steps done: section 3.8 research artifact formats, section 4.2 conditional plan logic, section 5.2 and D-13 references, CLAUDE.md sync.
