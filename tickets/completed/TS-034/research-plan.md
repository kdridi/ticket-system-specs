# Research Plan — TS-034

## Questions to Answer

1. **Where does the planning phase spend disproportionate time?** Analyze the `/ticket-system-plan` spec (Phase 2 codebase analysis) to determine whether the open-ended "explore relevant source code, architecture docs, existing tests" instruction drives broad, untargeted file scanning. Compare against what a developer would do manually (read the ticket, glance at 2-3 relevant files, write a short plan).

2. **Are the artifact templates pushing toward over-specification?** Evaluate whether `implementation-plan.md` and `test-plan.md` require more detail than is useful for small/medium tickets. Specifically: does writing TDD tests per step, a coverage map, and per-step "Done when" criteria add value proportional to the time spent generating them?

3. **How much time does context re-establishment cost across the plan-implement-verify-merge chain?** Each step forks into a separate agent context that does not inherit parent history. Quantify the repeated work: re-reading config, re-reading ticket, re-reading plan artifacts, re-scanning the codebase. Identify which re-reads are necessary versus redundant.

4. **Does the verify step re-read too much context?** Analyze the `/ticket-system-verify` spec to determine whether it re-reads the entire codebase, test plan, and implementation plan when it could focus on running tests and checking acceptance criteria against the diff.

5. **What overhead does /ticket-system-run add beyond the sum of its parts?** Examine the post-step verification logic (checking filesystem state after each sub-skill). Determine whether these checks add meaningful safety or just extra file I/O and latency.

6. **What spec changes would reduce execution time for simple tickets without degrading quality for complex ones?** Evaluate two approaches: (a) a "fast mode" flag in config.yml that skips or lightens certain phases, and (b) permanent spec tightening that removes unnecessary work for all tickets. Consider whether ticket `estimated_complexity` could drive adaptive depth.

## Sources to Investigate

- `specs.md` section 4.2 — all command specifications (plan, implement, verify, merge, run)
- `specs.md` section 3.8 — plan artifact templates (implementation-plan.md, test-plan.md)
- `specs.md` section 2.3 — agent profiles and model assignments
- `specs.md` section 5.2 — file formatting rules (agent system prompts)
- The `ticket-system-conventions` skill — what gets loaded on every agent startup
- The `ticket-system-plan` skill — exact instructions for codebase analysis
- The `ticket-system-implement` skill — step-by-step execution overhead
- The `ticket-system-verify` skill — verification scope and depth
- The `ticket-system-run` skill — orchestration overhead

## Findings Document Structure

- Summary: one-paragraph executive summary of root causes and proposed changes
- Findings by Question: one section per question above, with evidence from the spec
- Time Budget Breakdown: estimated time contribution of each phase (plan, implement, verify, merge, overhead) as percentage ranges
- Ranked Root Causes: causes sorted by estimated time impact (highest first)
- Proposed Changes: concrete spec edits for each root cause, with quality trade-off assessment
- Fast-Path Proposal: recommended defaults or configuration for simple implementation tickets
- Recommendation: prioritized list of changes to implement

## Decision Framework

Changes should be adopted if they meet ALL of:
1. Estimated time savings of at least 10% of the total cycle
2. No loss of correctness guarantees (tests still run, acceptance criteria still checked)
3. No loss of auditability (commits, log entries, ticket tracking preserved)
4. Implementation requires only spec changes (no new external dependencies)

Changes that sacrifice output quality should be clearly flagged and made opt-in (config flag), not default.
