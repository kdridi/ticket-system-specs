# Findings — TS-034

## Summary

The ticket system's 10-15 minute end-to-end cycle (vs 2-3 minutes manual) is driven by five compounding factors: (1) unbounded codebase exploration during planning (~30-40% of total time), (2) context re-establishment across four forked agent contexts that each re-read config, ticket, and plan artifacts from scratch (~15-20%), (3) over-specified artifact templates that demand verbose output regardless of ticket complexity (~15-20%), (4) post-step verification checks in /ticket-system-run that add redundant file I/O (~5-10%), and (5) the verify step re-reading the full plan and test artifacts when it could focus on test results and acceptance criteria diffs (~10-15%). The most impactful changes are: bounding codebase exploration in the planner by complexity, streamlining artifact templates for small tickets, and reducing redundant context loading. All proposed changes preserve correctness guarantees and audit trails.

## Findings by Question

### Q1: Where does the planning phase spend disproportionate time?

The `/ticket-system-plan` skill (Phase 2 — Codebase analysis) contains these instructions:

> "Read acceptance criteria, technical approach, context. Explore relevant source code, architecture docs, existing tests. Understand patterns and conventions in the project."

This is an **open-ended exploration directive** with no scope bound. The planner agent uses the `$STRONG_MODEL` (opus) — the most expensive and thorough model — and is instructed to "explore relevant source code, architecture docs, existing tests" and "understand patterns and conventions." For a small ticket (e.g., "rename a config field"), the planner will still attempt to scan broadly across the codebase to understand "patterns and conventions," which is unnecessary work.

**Evidence of impact:** A manual developer would glance at the ticket, open 1-3 relevant files, and write a short plan in under 60 seconds. The planner agent, following its instructions faithfully, will:
1. Read config.yml (necessary, fast)
2. Read the ticket (necessary, fast)
3. Explore "relevant source code" — this triggers Glob and Read across potentially dozens of files
4. Explore "architecture docs" — reads CLAUDE.md, README.md, any .md files
5. Explore "existing tests" — scans test directories
6. "Understand patterns and conventions" — reads additional files to infer style

Steps 3-6 are unbounded. The spec provides no guidance on when to stop exploring. For a large ticket this depth is justified; for a small ticket it produces 3-5 minutes of unnecessary file reading.

**Key spec location:** specs.md section 4.2, `/ticket-system-plan` Phase 2.

### Q2: Are the artifact templates pushing toward over-specification?

Yes. The `implementation-plan.md` template (specs.md section 3.8) requires per-step:
- **Files:** list of files to create/modify
- **What:** description of changes
- **Tests first:** TDD test(s) to write before implementation
- **Done when:** observable outcome

The `test-plan.md` template requires:
- Per-test-case: Type, Target, Input, Expected, Covers criteria
- A Coverage Map table mapping every acceptance criterion to test cases

For a small ticket with 2-3 acceptance criteria affecting 1-2 files, writing a detailed test plan with a coverage map and per-step TDD specifications is overhead that a manual developer would skip entirely. They would just write the code and run the tests.

**Quantified impact:** Generating these two artifacts typically involves:
- Reading the templates from conventions (fast)
- Deep analysis to populate every field (1-2 minutes for small tickets, 3-5 minutes for large)
- Writing the markdown (fast, but the analysis drives the time)

The `test-plan.md` is particularly expensive because the planner must predict specific test inputs, expected outputs, and coverage mappings before any code is written. For small tickets, this prediction work is often wasted — the actual tests end up different from what was planned.

**Key spec locations:** specs.md section 3.8, conventions skill (plan artifact templates).

### Q3: How much time does context re-establishment cost across the plan-implement-verify-merge chain?

Each step in the pipeline forks into a separate agent context via `context: fork`. The spec explicitly states (section 2.1): "Each slash command forks into a separate agent context. The forked agent does not see the parent conversation history."

This means each of the four steps (plan, implement, verify, merge) independently:
1. Loads and parses `.tickets/config.yml`
2. Locates the worktree
3. Reads the ticket frontmatter and body
4. Reads relevant plan artifacts

**Repeated reads across the pipeline:**

| Artifact | Plan | Implement | Verify | Merge | Total reads |
|----------|------|-----------|--------|-------|-------------|
| config.yml | 1 | 1 | 1 | 1 | 4 |
| ticket.md | 1 | 1 | 1 | 1 | 4 |
| implementation-plan.md | writes | 1 | 0 | 0 | 1 read |
| test-plan.md | writes | 0 | 1 | 0 | 1 read |
| conventions skill | loaded | loaded | loaded | loaded | 4 loads |

The conventions skill is 273 lines. It is loaded into every agent's context at startup. Across 4 steps, that is ~1092 lines of convention text processed.

Additionally, when `/ticket-system-run` orchestrates the chain, it itself is a forked agent that reads config.yml (5th time), reads the ticket (5th time), and performs post-step verification after each sub-skill.

**Estimated overhead:** Each context establishment costs ~10-20 seconds (model startup, skill loading, initial file reads). Across 4 sub-skills + the orchestrator = 5 context establishments = ~50-100 seconds of pure overhead, representing ~10-15% of a 10-minute cycle.

**Key spec locations:** specs.md section 2.1 (context isolation), section 4.2 `/ticket-system-run`.

### Q4: Does the verify step re-read too much context?

The verify step reads:
1. `.tickets/config.yml`
2. The ticket in `tickets/ongoing/<id>/`
3. `test-plan.md` (for code tickets) or `validation-criteria.md` (for research)
4. Runs tests (code) or reads findings.md (research)
5. Checks for `[DRIFT]` entries in the ticket log

For code verification, the spec instructs: "verify each test case in test-plan.md exists and passes. Check the coverage map (every criterion covered). Walk through each acceptance criterion with evidence. Check for regressions."

The "walk through each acceptance criterion with evidence" instruction causes the verifier to re-read source code to find evidence of implementation, rather than relying solely on test results. This is a full re-analysis of the implementation, not just a test-runner check.

**What a manual developer does:** Run `npm test`, check if tests pass, glance at the diff, done in 30 seconds.

**What the verifier does:** Re-reads the test plan, checks each test case exists individually, verifies coverage map completeness, walks through each acceptance criterion finding evidence in the code, checks for regressions, and checks for drift entries. This is thorough but takes 2-4 minutes.

**Key spec location:** specs.md section 4.2, `/ticket-system-verify`.

### Q5: What overhead does /ticket-system-run add beyond the sum of its parts?

The `/ticket-system-run` skill adds post-step verification after each sub-skill:

- **After plan:** Check worktree exists, check plan artifacts exist, read ticket type from frontmatter.
- **After implement:** Check findings.md exists (research) or check for implementation commits beyond plan commits (code).
- **After verify:** Check for VERDICT: PASS in output or verify completed directory exists.
- **After merge:** Verify worktree removed and branch deleted.

Each check involves file existence checks (Glob/Read), git operations, and ticket frontmatter re-reading.

**Estimated overhead:** ~15-30 seconds per verification check, 4 checks = ~60-120 seconds total (~5-10% of the cycle).

These checks are defensive — they guard against sub-skills failing silently. In practice, sub-skills either succeed (checks redundant) or fail loudly (with error messages). The checks are most valuable when a sub-skill partially succeeds, which is rare.

**Key spec location:** specs.md section 4.2, `/ticket-system-run` steps 3-6.

### Q6: What spec changes would reduce execution time for simple tickets without degrading quality for complex ones?

Two approaches were evaluated:

**Approach A: "Fast mode" config flag** — Add `fast_mode: true` to config.yml for lighter behavior across all commands. Trade-off: sacrifices depth of analysis and audit trail completeness universally for that project.

**Approach B: Complexity-adaptive behavior** — Use the existing `estimated_complexity` frontmatter field (small | medium | large) to drive adaptive depth. Trade-off: preserves full depth for medium/large tickets. Small tickets lose the detailed test plan and coverage map but gain ~50-60% time savings.

**Approach B is recommended** because it uses existing metadata, requires no new config flags, and provides proportional depth. The key insight is that most tickets in practice are small or medium — the system was designed for the hardest case (large) and applies that depth universally.

## Time Budget Breakdown

| Phase | Estimated % of 10-min cycle | Primary time driver |
|-------|----------------------------|---------------------|
| Plan (activation + analysis + artifact generation) | 30-40% | Unbounded codebase exploration, verbose artifact generation |
| Implement (code + tests + drift checks) | 25-30% | Actual coding work — least reducible |
| Verify (test run + criterion walkthrough + drift check) | 15-20% | Full re-analysis of implementation, not just test results |
| Merge (branch merge + cleanup) | 5-10% | Straightforward git operations, minimal reduction possible |
| Inter-step overhead (context re-establishment + run verification) | 15-20% | 5 independent context loads, 4 post-step checks |

## Ranked Root Causes

1. **Unbounded codebase exploration in planning** (~3-4 min, 30-40%). The planner has no stopping criterion for Phase 2, leading to broad file scanning regardless of ticket size.

2. **Context re-establishment across forked agents** (~1.5-2 min, 15-20%). Each of 5 forked contexts independently loads conventions, reads config, reads the ticket, and parses artifacts.

3. **Over-specified artifact templates** (~1.5-2 min, 15-20%). The test-plan.md coverage map and per-test-case specifications add planning overhead disproportionate to their value for small tickets.

4. **Verify re-analysis depth** (~1-1.5 min, 10-15%). The verifier walks through acceptance criteria with evidence from code rather than relying on test results.

5. **Run orchestrator post-step checks** (~1-2 min, 5-10%). Defensive filesystem checks after each sub-skill are rarely needed but always executed.

## Proposed Changes

### Change 1: Bound codebase exploration by complexity (saves ~2-3 min for small tickets)

**Spec section:** 4.2, `/ticket-system-plan` Phase 2

**Current:** "Explore relevant source code, architecture docs, existing tests. Understand patterns and conventions in the project."

**Proposed:** Add complexity-adaptive guidance:

> Phase 2 — Codebase analysis (depth scales with `estimated_complexity`):
> - **small:** Read only files explicitly mentioned in the ticket's Technical Approach section. Skip broad exploration.
> - **medium:** Read files in Technical Approach plus their direct imports/dependencies. Skim test directory structure.
> - **large:** Current behavior — full exploration of relevant source, architecture docs, and tests.

**Quality trade-off:** Small tickets lose broad pattern discovery, but small tickets by definition affect few files and rarely need it. No correctness loss — tests still run, criteria still checked.

### Change 2: Condensed artifact format for small tickets (saves ~1-2 min)

**Spec section:** 3.8 (Plan Artifacts) and 4.2 `/ticket-system-plan` Phase 3

**Proposed:** When `estimated_complexity: small`, the planner produces a single `implementation-plan.md` with inline test notes instead of a separate `test-plan.md`:

```markdown
# Implementation Plan — PREFIX-XXX

## Overview
Brief summary.

## Steps
### Step 1: <title>
- **Files:** list
- **What:** description
- **Tests:** inline test description (replaces separate test-plan.md)
- **Done when:** outcome
```

No coverage map, no per-test-case Type/Target/Input/Expected breakdown. The verifier for small tickets runs the test command and checks acceptance criteria without cross-referencing a coverage map.

**Quality trade-off:** Small tickets lose the formal coverage map. For a 2-criterion ticket this is paperwork, not safety. Medium and large tickets retain full artifacts.

### Change 3: Lightweight verify mode for small tickets (saves ~1 min)

**Spec section:** 4.2, `/ticket-system-verify`

**Proposed:** When `estimated_complexity: small`:
1. Run the test command (or auto-detect).
2. Check each acceptance criterion against the git diff (not a full code walkthrough).
3. Check for drift entries.
4. Skip coverage map verification (no test-plan.md for small tickets).

**Quality trade-off:** Acceptance criteria are still verified. Tests still run. The loss is the detailed evidence walkthrough, which for small tickets is redundant with the test results.

### Change 4: Make run post-step checks lightweight (saves ~30-60 sec)

**Spec section:** 4.2, `/ticket-system-run` steps 3-6

**Proposed:** Replace filesystem verification with output-based verification:
- After each sub-skill, check the sub-skill's output/return for success indicators rather than re-reading filesystem state.
- After plan, check for "committed" in output. After implement, check for "complete" in output. After verify, check for "VERDICT: PASS" in output. After merge, check for "merged" in output.
- Remove the explicit filesystem checks (worktree exists, artifacts exist, commits exist).

**Quality trade-off:** Slightly less defensive against silent partial failures, but sub-skills are designed to report failures explicitly.

### Change 5: Document context-passing best practices (saves ~30-60 sec)

**Spec section:** 2.1 (context isolation note) and 5.2 (agent system prompts)

**Proposed:** Add to each agent's system prompt: "Read config.yml, locate the ticket, and begin work immediately. Do not explore the codebase beyond what is needed for your specific task."

**Quality trade-off:** None. This is guidance, not restriction.

## Fast-Path Proposal

For simple implementation tickets (`estimated_complexity: small`), the recommended fast path:

1. **No new config flag needed.** Use the existing `estimated_complexity` field in ticket frontmatter.
2. **Planner:** Read only files in Technical Approach. Produce a single `implementation-plan.md` with inline test notes. Skip `test-plan.md`.
3. **Implementer:** Follow the plan as-is (no change — the plan is already lighter).
4. **Verifier:** Run tests + check acceptance criteria against the diff. Skip coverage map verification.
5. **Run orchestrator:** Use output-based post-step checks instead of filesystem checks.

**Expected time reduction for small tickets:** From ~10-15 minutes to ~4-6 minutes (~50-60% reduction).

**Implementation requires edits to:**
- specs.md section 3.8 (add condensed artifact format for small complexity)
- specs.md section 4.2 `/ticket-system-plan` Phase 2 (add complexity-adaptive exploration)
- specs.md section 4.2 `/ticket-system-plan` Phase 3 (conditional artifact generation)
- specs.md section 4.2 `/ticket-system-verify` (conditional verification depth)
- specs.md section 4.2 `/ticket-system-run` (lighter post-step checks)
- `ticket-system-conventions` skill (add condensed artifact format documentation)

## Recommendation

Prioritized implementation order (by impact-to-effort ratio):

1. **Change 1 — Bound codebase exploration** (highest impact, easiest — one paragraph in specs.md 4.2). Saves 2-3 minutes per small ticket.
2. **Change 2 — Condensed artifacts for small tickets** (high impact, moderate effort). Saves 1-2 minutes and reduces downstream verify time.
3. **Change 4 — Lightweight run post-step checks** (moderate impact, easy). Saves 30-60 seconds.
4. **Change 3 — Lightweight verify for small tickets** (moderate impact, moderate effort). Saves ~1 minute.
5. **Change 5 — Context-passing guidance** (low impact, trivial). Marginal improvement, zero risk.

Changes 1-3 together would reduce the small-ticket cycle from ~10-15 minutes to ~4-6 minutes.

## Sources

- specs.md section 0 — Configuration Variables (model assignments, MAX_RETRY)
- specs.md section 2.1 — Two Complementary Layers (context isolation)
- specs.md section 2.3 — Agent Profiles (model assignments per agent)
- specs.md section 3.8 — Plan Artifacts (implementation-plan.md, test-plan.md templates)
- specs.md section 4.2 `/ticket-system-plan` — Phase 2 codebase analysis, Phase 3 plan generation
- specs.md section 4.2 `/ticket-system-implement` — step-by-step execution with drift checks
- specs.md section 4.2 `/ticket-system-verify` — verification checklist and criterion walkthrough
- specs.md section 4.2 `/ticket-system-run` — post-step verification logic
- specs.md section 4.2 `/ticket-system-run-all` — batch orchestration
- ticket-system-conventions SKILL.md — 273-line conventions loaded per agent
- ticket-system-plan SKILL.md — Phase 2 instructions
- ticket-system-verify SKILL.md — verification instructions
- ticket-system-run SKILL.md — orchestration instructions
