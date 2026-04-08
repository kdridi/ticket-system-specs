# Validation Criteria — TS-034

## Completeness Criteria

- All 6 research questions answered with specific evidence from the spec (section references, quoted instructions)
- Each identified cause includes an estimated time contribution (percentage range or relative ranking)
- At least 3 concrete, actionable spec changes proposed (with exact section references for where to edit)
- Each proposed change includes a quality trade-off assessment (what is preserved, what is sacrificed)
- A fast-path variant or recommended defaults section exists for simple implementation tickets
- The time budget breakdown covers all 4 phases (plan, implement, verify, merge) plus inter-step overhead

## Evidence Requirements

- Every claim about time spent must reference a specific spec instruction or artifact requirement that drives the work
- Proposed changes must cite the exact spec section and paragraph to modify
- Quality trade-off assessments must reference specific acceptance criteria or audit trail features that are affected
- The fast-path proposal must be implementable via config.yml or spec changes alone (no new tooling)

## Deliverable Format

findings.md must follow this structure:
1. Summary (one paragraph)
2. Findings by Question (Q1-Q6, each with evidence)
3. Time Budget Breakdown (table or list with percentage estimates per phase)
4. Ranked Root Causes (ordered by time impact)
5. Proposed Changes (numbered, with spec section references and trade-off notes)
6. Fast-Path Proposal (concrete configuration or defaults)
7. Recommendation (prioritized action list)
8. Sources (spec section references used)
