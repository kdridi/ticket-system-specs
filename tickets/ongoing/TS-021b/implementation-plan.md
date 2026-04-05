# Implementation Plan — TS-021b

## Overview
Update specs.md to define research-type variants for the implement and verify phases. When a ticket has `type: research`, implement produces `findings.md` (following the structure in `research-plan.md`) instead of code, and verify checks `findings.md` against `validation-criteria.md` instead of running tests. The PASS/FAIL verdict and completion flow remain identical.

## Steps

### Step 1: Add findings.md format to section 3.8
- **Files:** `specs.md` (section 3.8 Plan Artifacts)
- **What:** Add the `findings.md` document format template after the `validation-criteria.md` template in the Research Plan Artifacts subsection. This defines the expected output of the research implement phase, referenced by both implement and verify commands.
- **Tests first:** N/A (spec file, not code)
- **Done when:** Section 3.8 contains a `findings.md` template with Summary, Findings by Question, Recommendation, and Sources sections.

### Step 2: Add research conditional to /ticket-system-implement (section 4.2)
- **Files:** `specs.md` (section 4.2, `/ticket-system-implement` command)
- **What:** Add a conditional branch after the prerequisites block. If ticket `type` is `research`: read `research-plan.md` instead of `implementation-plan.md`, produce `findings.md` following the research plan's structure instead of writing code, skip TDD/test steps (no code to test), still commit and update ticket log. The prerequisite check (step 2) must also look for `research-plan.md` instead of `implementation-plan.md` when `type: research`. The retry limit check still applies (research can also fail verification). Drift detection does not apply (no code files to drift).
- **Tests first:** N/A (spec file, not code)
- **Done when:** The `/ticket-system-implement` section has a clear conditional: "If `type: research`, read `research-plan.md` and produce `findings.md`; otherwise follow the standard code implementation flow."

### Step 3: Add research conditional to /ticket-system-verify (section 4.2)
- **Files:** `specs.md` (section 4.2, `/ticket-system-verify` command)
- **What:** Add a conditional branch in the verification checklist. If ticket `type` is `research`: read `validation-criteria.md` instead of `test-plan.md`, check `findings.md` against validation criteria (completeness, evidence, deliverable format) instead of running tests, verdict logic is the same (PASS moves to completed, FAIL stays in ongoing with attempt count). The NEVER-modify-code rule naturally extends to NEVER-modify-findings for consistency.
- **Tests first:** N/A (spec file, not code)
- **Done when:** The `/ticket-system-verify` section has a clear conditional for research tickets that checks `findings.md` against `validation-criteria.md`.

### Step 4: Update /ticket-system-run research awareness (section 4.2)
- **Files:** `specs.md` (section 4.2, `/ticket-system-run` command)
- **What:** Update the plan-step verification (step 3) to also accept `research-plan.md` + `validation-criteria.md` as valid plan artifacts (not just `implementation-plan.md` + `test-plan.md`). Update the implement-step verification (step 4) to check for `findings.md` existence for research tickets instead of implementation commits.
- **Tests first:** N/A (spec file, not code)
- **Done when:** The `/ticket-system-run` section correctly verifies research artifacts at each step.

### Step 5: Update conventions skill documentation (section 5.2)
- **Files:** `specs.md` (section 5.2)
- **What:** Ensure the conventions skill content description mentions the research pipeline variant. Section 5.2 line 853 already says "(standard and research variants)" for plan artifacts. Verify this is sufficient and add a note about the research implement/verify flow if needed (the conventions skill documents the full lifecycle including the research variant pipeline: plan produces research-plan.md + validation-criteria.md, implement produces findings.md, verify checks findings against validation criteria).
- **Tests first:** N/A (spec file, not code)
- **Done when:** The conventions skill description covers the research pipeline variant end-to-end.

### Step 6: Add validation checklist items (section 8)
- **Files:** `specs.md` (section 8)
- **What:** Add validation checklist items for the research implement/verify variants:
  - `/ticket-system-implement` checks ticket type and reads `research-plan.md` for research tickets.
  - `/ticket-system-implement` produces `findings.md` for research tickets instead of code.
  - `/ticket-system-verify` checks ticket type and reads `validation-criteria.md` for research tickets.
  - `/ticket-system-verify` checks `findings.md` against `validation-criteria.md` for research tickets.
  - `/ticket-system-run` accepts research artifacts as valid plan output.
  - The PASS/FAIL verdict and completion flow are identical for both ticket types.
- **Tests first:** N/A (spec file, not code)
- **Done when:** Section 8 has checklist items covering research implement/verify behavior.

### Step 7: Sync CLAUDE.md
- **Files:** `CLAUDE.md`
- **What:** Review CLAUDE.md for any references that need updating after the research pipeline additions. The validation quick reference in CLAUDE.md lists deep validation items -- check if any new items need to be mentioned there.
- **Tests first:** N/A (spec file, not code)
- **Done when:** CLAUDE.md accurately reflects the current state of specs.md including research pipeline.

## Risk Notes
- The `/ticket-system-implement` section is already dense. The research conditional needs to be clearly structured (e.g., a separate paragraph or subsection) to avoid confusion.
- The `/ticket-system-run` step verification is tightly coupled to artifact names. Must handle the type-dependent check cleanly.
- The conventions skill is subject to the 500-line limit (D-13). Adding research pipeline documentation may push it closer to the threshold. Monitor line count.
