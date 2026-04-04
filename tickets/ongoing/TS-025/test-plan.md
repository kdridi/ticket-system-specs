# Test Plan — TS-025

## Strategy
This is a specification-only repository (no executable code), so testing is manual validation of the spec document. Each test case is a grep/read check against the modified `specs.md` and `CLAUDE.md` to verify correctness and consistency.

## Test Cases

### TC-1: Schedule command accepts multiple ticket IDs
- **Type:** integration
- **Target:** specs.md section 4.2, `/ticket-system-schedule`
- **Input:** Read the schedule command specification
- **Expected:** The argument description mentions "one or more ticket IDs" and the behavior describes batch processing
- **Covers criteria:** AC-1 (accepts one or more ticket IDs)

### TC-2: Schedule preserves description-based matching
- **Type:** integration
- **Target:** specs.md section 4.2, `/ticket-system-schedule`
- **Input:** Read the schedule command specification
- **Expected:** The command still accepts a description to fuzzy-match tickets in backlog
- **Covers criteria:** AC-2 (description fuzzy-match preserved)

### TC-3: Schedule includes 7-dimension analysis
- **Type:** integration
- **Target:** specs.md section 4.2, `/ticket-system-schedule`
- **Input:** Read the schedule command specification
- **Expected:** Phase 2 includes validity, relevance, and atomicity (7-dimension) evaluation with all 7 dimensions listed
- **Covers criteria:** AC-3 (evaluates validity, relevance, atomicity)

### TC-4: Schedule proposes rejection for irrelevant tickets
- **Type:** integration
- **Target:** specs.md section 4.2, `/ticket-system-schedule`
- **Input:** Read the schedule command specification
- **Expected:** The specification describes proposing rejection with reason for tickets no longer relevant
- **Covers criteria:** AC-4 (proposes rejection)

### TC-5: Schedule resolves dependency graph
- **Type:** integration
- **Target:** specs.md section 4.2, `/ticket-system-schedule`
- **Input:** Read the schedule command specification
- **Expected:** Phase 1 describes recursively resolving dependencies and building a dependency graph
- **Covers criteria:** AC-5 (dependency graph resolution)

### TC-6: Schedule presents unified plan with human gate
- **Type:** integration
- **Target:** specs.md section 4.2, `/ticket-system-schedule`
- **Input:** Read the schedule command specification
- **Expected:** Phase 3 presents a categorized plan (ready/needs attention/propose rejection) and Phase 4 requires user approval before mutations
- **Covers criteria:** AC-6 (unified plan), AC-7 (human gate)

### TC-7: Schedule executes on approval
- **Type:** integration
- **Target:** specs.md section 4.2, `/ticket-system-schedule`
- **Input:** Read the schedule command specification
- **Expected:** Phase 4 describes git mv to planned/rejected, roadmap.yml update, frontmatter updates, and commit
- **Covers criteria:** AC-8 (execute on approval)

### TC-8: Analyze command fully removed from specs.md
- **Type:** unit
- **Target:** specs.md (all sections)
- **Input:** Grep for "ticket-system-analyze" across the entire file
- **Expected:** Zero matches
- **Covers criteria:** AC-10 (analyze removed)

### TC-9: Agent table updated
- **Type:** unit
- **Target:** specs.md section 2.3
- **Input:** Read the agent profiles table
- **Expected:** Reader agent "Used by" column only shows `/ticket-system-help`. No mention of analyze.
- **Covers criteria:** AC-10

### TC-10: Auto-invocation table updated
- **Type:** unit
- **Target:** specs.md section 2.4
- **Input:** Read the auto-invocation table
- **Expected:** No row for `ticket-system-analyze`
- **Covers criteria:** AC-10

### TC-11: Pipeline overview updated
- **Type:** unit
- **Target:** specs.md section 4.1
- **Input:** Read the pipeline description
- **Expected:** Pipeline is `create -> schedule (-> split) -> plan ...` with no mention of analyze
- **Covers criteria:** AC-10

### TC-12: File tree updated
- **Type:** unit
- **Target:** specs.md section 5.1
- **Input:** Read the file tree
- **Expected:** No `ticket-system-analyze/` directory listed. 9 skill directories total.
- **Covers criteria:** AC-10

### TC-13: Decisions table updated
- **Type:** unit
- **Target:** specs.md section 6
- **Input:** Read D-7
- **Expected:** D-7 no longer references analyze. Updated to reflect the new schedule behavior.
- **Covers criteria:** AC-10

### TC-14: Validation checklist updated
- **Type:** unit
- **Target:** specs.md section 8
- **Input:** Read the skills checklist
- **Expected:** No `ticket-system-analyze/` entry
- **Covers criteria:** AC-10

### TC-15: CLAUDE.md updated
- **Type:** unit
- **Target:** CLAUDE.md
- **Input:** Read the expected output section
- **Expected:** References "9 skill directories" and "8 slash commands" (not 10/9)
- **Covers criteria:** AC-10

### TC-16: Merge command no longer suggests analyze
- **Type:** unit
- **Target:** specs.md section 4.2, `/ticket-system-merge`
- **Input:** Read the merge command specification
- **Expected:** Does not suggest running `/ticket-system-analyze`
- **Covers criteria:** AC-10

### TC-17: Help command verb list excludes analyze
- **Type:** unit
- **Target:** specs.md section 4.2, `/ticket-system-help`
- **Input:** Read the help command specification
- **Expected:** Known verbs list does not include "analyze"
- **Covers criteria:** AC-10

### TC-18: Schedule disable-model-invocation is false
- **Type:** unit
- **Target:** specs.md section 2.4
- **Input:** Read the auto-invocation table, schedule row
- **Expected:** `disable-model-invocation: false`
- **Covers criteria:** AC-11 (disable-model-invocation: false)

### TC-19: No stale "analyze" references anywhere in specs.md
- **Type:** integration
- **Target:** specs.md (full file)
- **Input:** Grep for the word "analyze" (case-insensitive)
- **Expected:** Zero matches (or only in clearly unrelated contexts like "complexity analysis" which is fine). Specifically, no "/ticket-system-analyze", no "ticket-system-analyze", no "D-7.*analyze".
- **Covers criteria:** AC-10

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: Accepts multiple ticket IDs | TC-1 |
| AC-2: Preserves description fuzzy-match | TC-2 |
| AC-3: Evaluates validity, relevance, atomicity | TC-3 |
| AC-4: Proposes rejection for irrelevant | TC-4 |
| AC-5: Resolves dependency graph | TC-5 |
| AC-6: Presents unified scheduling plan | TC-6 |
| AC-7: Human gate before mutations | TC-6 |
| AC-8: Execute on approval (git mv, roadmap, commit) | TC-7 |
| AC-9: Commit format | TC-7 |
| AC-10: Analyze removed from system | TC-8, TC-9, TC-10, TC-11, TC-12, TC-13, TC-14, TC-15, TC-16, TC-17, TC-19 |
| AC-11: disable-model-invocation: false | TC-18 |
