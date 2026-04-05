# Test Plan — TS-021a

## Strategy
Manual validation against the acceptance criteria. Since the deliverable is a specification document (specs.md), there is no executable code to test. Validation consists of structural checks on the spec content and cross-reference consistency checks.

## Test Cases

### TC-1: research-plan.md format defined in section 3.8
- **Type:** manual / structural
- **Target:** specs.md section 3.8
- **Input:** Read section 3.8 after implementation
- **Expected:** A `research-plan.md` template block is present containing at minimum: "Questions to Answer", "Sources to Investigate", "Findings Document Structure", and "Decision Framework" sections. The template uses PREFIX-XXX placeholder (not a hardcoded prefix).
- **Covers criteria:** AC-1 (specs.md section 3 defines research-plan.md format)

### TC-2: validation-criteria.md format defined in section 3.8
- **Type:** manual / structural
- **Target:** specs.md section 3.8
- **Input:** Read section 3.8 after implementation
- **Expected:** A `validation-criteria.md` template block is present containing at minimum: "Completeness Criteria", "Evidence Requirements", and "Deliverable Format" sections. The template uses PREFIX-XXX placeholder.
- **Covers criteria:** AC-2 (specs.md section 3 defines validation-criteria.md format)

### TC-3: /ticket-system-plan conditional logic for research tickets
- **Type:** manual / behavioral
- **Target:** specs.md section 4.2 /ticket-system-plan
- **Input:** Read the /ticket-system-plan specification after implementation
- **Expected:** Phase 3 (Plan generation) contains explicit conditional: when ticket type is `research`, generate research-plan.md and validation-criteria.md instead of implementation-plan.md and test-plan.md. The conditional references section 3.8 for the formats.
- **Covers criteria:** AC-3 (/ticket-system-plan generates research artifacts for research tickets)

### TC-4: Plan approval gate unchanged for research tickets
- **Type:** manual / behavioral
- **Target:** specs.md section 4.2 /ticket-system-plan Phase 4
- **Input:** Read Phase 4 specification after implementation
- **Expected:** The human gate behavior is identical regardless of ticket type. No special-casing for research tickets in Phase 4. The self-evaluation and AskUserQuestion flow applies to both standard and research plans.
- **Covers criteria:** AC-4 (plan approval gate works the same)

### TC-5: No hardcoded prefixes in new content
- **Type:** manual / structural
- **Target:** All new content added to specs.md
- **Input:** Search new content for hardcoded ticket prefixes (TS-, PROJ- used as literal IDs rather than examples)
- **Expected:** All examples use PREFIX-XXX placeholder. No hardcoded project-specific prefixes.
- **Covers criteria:** Project-wide convention (no hardcoded prefixes)

### TC-6: Section cross-references are consistent
- **Type:** manual / structural
- **Target:** specs.md sections 3.8, 4.2, 5.2, 6
- **Input:** Check all cross-references between sections
- **Expected:** Section 4.2 references "section 3.8" for research formats. Section 5.2 mentions both standard and research artifact variants. D-13 includes research artifacts in extractable sections.
- **Covers criteria:** Cross-reference consistency (implicit quality requirement)

### TC-7: Conventions skill line budget not exceeded
- **Type:** manual / constraint
- **Target:** specs.md section 5.2 and D-13
- **Input:** Assess whether added content would push the conventions skill past 500 lines
- **Expected:** Either the research templates fit within the 500-line budget, or the spec explicitly directs them to `ticket-system-conventions-extended` per D-13 split strategy.
- **Covers criteria:** D-13 constraint compliance

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: research-plan.md format in section 3 | TC-1, TC-5 |
| AC-2: validation-criteria.md format in section 3 | TC-2, TC-5 |
| AC-3: /ticket-system-plan generates research artifacts | TC-3, TC-6 |
| AC-4: Plan approval gate unchanged | TC-4 |
| No hardcoded prefixes | TC-5 |
| Cross-reference consistency | TC-6 |
| Line budget compliance | TC-7 |
