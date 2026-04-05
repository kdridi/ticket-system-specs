# Test Plan — TS-021b

## Strategy
Manual validation of spec content. Since this project is a specification file (not code), testing means verifying the spec text is correct, complete, consistent, and follows the established patterns. Each test case is a manual review checklist item.

## Test Cases

### TC-1: findings.md format exists in section 3.8
- **Type:** integration
- **Target:** specs.md section 3.8
- **Input:** Read section 3.8 after changes
- **Expected:** A `findings.md` template exists with sections: Summary, Findings by Question (with Q1 pattern), Recommendation, Sources. It appears in the "Research Plan Artifacts" subsection alongside `research-plan.md` and `validation-criteria.md`.
- **Covers criteria:** Conventions skill documents the research pipeline variant (partial)

### TC-2: /ticket-system-implement has research conditional
- **Type:** integration
- **Target:** specs.md section 4.2, `/ticket-system-implement`
- **Input:** Read the implement command spec
- **Expected:** Contains a conditional: when ticket type is `research`, reads `research-plan.md` (not `implementation-plan.md`), produces `findings.md` instead of code, skips TDD/test steps. The prerequisite check accepts `research-plan.md` as a valid plan artifact for research tickets.
- **Covers criteria:** `/ticket-system-implement` for research tickets produces `findings.md` following the structure defined in `research-plan.md`

### TC-3: /ticket-system-verify has research conditional
- **Type:** integration
- **Target:** specs.md section 4.2, `/ticket-system-verify`
- **Input:** Read the verify command spec
- **Expected:** Contains a conditional: when ticket type is `research`, reads `validation-criteria.md` (not `test-plan.md`), checks `findings.md` against validation criteria. The NEVER-modify rule still applies.
- **Covers criteria:** `/ticket-system-verify` for research tickets checks `findings.md` against `validation-criteria.md`

### TC-4: PASS/FAIL verdict is identical for research tickets
- **Type:** unit
- **Target:** specs.md section 4.2, both `/ticket-system-implement` and `/ticket-system-verify`
- **Input:** Read the VERDICT sections of both commands
- **Expected:** The PASS flow (move to completed, update frontmatter, log entry, commit) and FAIL flow (attempt count, log entry, stay in ongoing) are unchanged between code and research tickets. No separate verdict logic for research.
- **Covers criteria:** The PASS/FAIL verdict and completion flow work the same as for code tickets

### TC-5: /ticket-system-run handles research artifacts
- **Type:** integration
- **Target:** specs.md section 4.2, `/ticket-system-run`
- **Input:** Read the run command spec
- **Expected:** Step 3 (plan verification) accepts `research-plan.md` + `validation-criteria.md` as valid plan output for research tickets. Step 4 (implement verification) checks for `findings.md` for research tickets.
- **Covers criteria:** `/ticket-system-implement` for research tickets produces `findings.md` (indirectly via run orchestration)

### TC-6: Conventions skill documents research pipeline
- **Type:** integration
- **Target:** specs.md section 5.2
- **Input:** Read the conventions skill content requirements
- **Expected:** Section 5.2 mentions that the conventions skill covers the research pipeline variant (plan, implement, verify phases for research tickets).
- **Covers criteria:** The conventions skill documents the research pipeline variant

### TC-7: Validation checklist covers research variants
- **Type:** unit
- **Target:** specs.md section 8
- **Input:** Read section 8
- **Expected:** Contains checklist items for: implement reads `research-plan.md` for research tickets, implement produces `findings.md`, verify reads `validation-criteria.md` for research tickets, verify checks `findings.md`, run accepts research artifacts, verdict flow is identical.
- **Covers criteria:** All acceptance criteria (validation coverage)

### TC-8: No hardcoded ticket prefix in new content
- **Type:** unit
- **Target:** All new/modified text in specs.md
- **Input:** Search new content for literal ticket prefixes
- **Expected:** All references use `PREFIX-XXX` placeholder, never a concrete prefix like `TS-001`.
- **Covers criteria:** General correctness

### TC-9: Retry limit still applies to research tickets
- **Type:** unit
- **Target:** specs.md section 4.2, `/ticket-system-implement`
- **Input:** Read the research conditional in implement
- **Expected:** The retry limit check (MAX_RETRY) is not bypassed for research tickets. It applies equally to all ticket types.
- **Covers criteria:** The PASS/FAIL verdict and completion flow work the same as for code tickets

### TC-10: CLAUDE.md is in sync
- **Type:** integration
- **Target:** CLAUDE.md
- **Input:** Compare CLAUDE.md validation references with specs.md section 8
- **Expected:** CLAUDE.md reflects any new validation items added for the research pipeline.
- **Covers criteria:** General correctness (project rule: keep CLAUDE.md in sync)

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| `/ticket-system-implement` for research tickets produces `findings.md` following `research-plan.md` | TC-2, TC-5, TC-9 |
| `/ticket-system-verify` for research tickets checks `findings.md` against `validation-criteria.md` | TC-3 |
| The PASS/FAIL verdict and completion flow work the same as for code tickets | TC-4, TC-9 |
| The conventions skill documents the research pipeline variant | TC-1, TC-6 |
| General correctness and consistency | TC-7, TC-8, TC-10 |
