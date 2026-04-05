# Implementation Plan — TS-021a

## Overview
Add research-specific plan artifacts to specs.md so that tickets with `type: research` get `research-plan.md` and `validation-criteria.md` instead of `implementation-plan.md` and `test-plan.md` during the plan phase.

## Steps

### Step 1: Add research artifact formats to Section 3.8
- **Files:** `specs.md` (section 3.8)
- **What:** After the existing `test-plan.md` template block (ending around line 398), add two new artifact format definitions: `research-plan.md` and `validation-criteria.md`. Use the formats specified in the ticket's Technical Approach section. Add a preamble note explaining that section 3.8 defines two sets of artifacts — standard (implementation-plan.md + test-plan.md) for code tickets, and research (research-plan.md + validation-criteria.md) for research tickets.
- **Tests first:** N/A — this is a spec-only change, no executable code.
- **Done when:** Section 3.8 contains both standard and research artifact templates with clear labeling.

### Step 2: Add conditional logic to Section 4.2 /ticket-system-plan
- **Files:** `specs.md` (section 4.2, `/ticket-system-plan` command)
- **What:** In Phase 3 (Plan generation), add a conditional: "If the ticket's frontmatter has `type: research`, generate `research-plan.md` and `validation-criteria.md` (formats in section 3.8) instead of `implementation-plan.md` and `test-plan.md`." The Phase 4 human gate behavior remains identical regardless of ticket type.
- **Tests first:** N/A — spec-only change.
- **Done when:** The `/ticket-system-plan` specification clearly describes the branching behavior based on ticket type, and references section 3.8 for the research artifact formats.

### Step 3: Update Section 5.2 conventions skill description
- **Files:** `specs.md` (section 5.2)
- **What:** The conventions skill content description currently says "plan artifact formats" — update it to say "plan artifact formats (standard and research variants)" so that generators know to include both sets of templates in the conventions skill. Also note that research artifact formats fall under the D-13 extractable sections (same category as plan artifact formats).
- **Tests first:** N/A — spec-only change.
- **Done when:** Section 5.2 references both standard and research plan artifacts. D-13 in section 6 mentions research artifact formats as extractable alongside the standard ones.

### Step 4: Update CLAUDE.md to reflect the new research artifact support
- **Files:** `CLAUDE.md`
- **What:** Per the project rule "Keep CLAUDE.md in sync with specs.md", review CLAUDE.md and add any necessary references to research-type ticket handling if relevant sections are affected. This is likely minimal — the key design decisions and validation checklist sections may not need changes since the research artifacts follow the same patterns as existing artifacts.
- **Tests first:** N/A.
- **Done when:** CLAUDE.md accurately reflects the updated specs.md content without contradictions.

## Risk Notes
- The conventions skill has a 500-line limit (D-13). Adding two more artifact templates increases its size. If it is already near 400 lines, the research templates may need to go into `ticket-system-conventions-extended` instead. The implementer should check the current line count and decide accordingly.
- The `/ticket-system-implement` and `/ticket-system-verify` commands reference `implementation-plan.md` and `test-plan.md`. Those are addressed by TS-021b (the sibling ticket), not this one. This ticket only covers the plan phase.
- The section line numbers referenced above are approximate and should be verified at implementation time, as the file may have shifted.
