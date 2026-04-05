# Test Plan -- TS-007

## Strategy
Manual review of spec changes plus automated validation via validate.sh. Since this ticket modifies specs.md (a generation prompt) and validate.sh (a bash script), testing focuses on:
1. Verifying the spec changes are internally consistent and correctly cross-referenced.
2. Running validate.sh against mock generated output to confirm the new checks work.

## Test Cases

### TC-1: D-13 decision entry exists in specs.md section 6
- **Type:** manual review
- **Target:** specs.md section 6 (Decisions table)
- **Input:** Read specs.md after implementation
- **Expected:** A D-13 row exists with: (a) the 500-line budget stated, (b) the split strategy described (extract plan artifacts into ticket-system-conventions-extended), (c) the 400-line trigger threshold mentioned
- **Covers criteria:** AC-1 (specs.md section 6 documents the budget)

### TC-2: Split strategy identifies extractable sections
- **Type:** manual review
- **Target:** specs.md section 6 D-13
- **Input:** Read the decision entry
- **Expected:** Plan artifact formats and test plan formats are listed as extractable. Core sections (config, directory structure, ticket format, roadmap, lifecycle, ID assignment, commit convention, worktree convention, tool usage rules) are listed as must-stay.
- **Covers criteria:** AC-2 (split strategy defined)

### TC-3: Generation rule for line-count comment documented
- **Type:** manual review
- **Target:** specs.md section 5
- **Input:** Read section 5 conventions skill generation rules
- **Expected:** A rule states the conventions skill must include `<!-- Lines: N/500 -->` after frontmatter, where N is the actual line count
- **Covers criteria:** AC-3 (generated skill tracks line count)

### TC-4: validate.sh checks conventions skill line count
- **Type:** integration (script execution)
- **Target:** validate.sh
- **Input:** A mock generated output directory with a conventions skill under 500 lines and correct line-count comment
- **Expected:** validate.sh reports PASS for the line-count check and the comment check
- **Covers criteria:** AC-4 (validate.sh checks line limit)

### TC-5: validate.sh fails on oversized conventions skill
- **Type:** integration (script execution)
- **Target:** validate.sh
- **Input:** A mock generated output directory with a conventions skill over 500 lines
- **Expected:** validate.sh reports FAIL for the line-count check
- **Covers criteria:** AC-4 (validate.sh checks line limit)

### TC-6: validate.sh fails on missing or incorrect line-count comment
- **Type:** integration (script execution)
- **Target:** validate.sh
- **Input:** A mock generated output directory with no `<!-- Lines: N/500 -->` comment, or one where N does not match actual line count
- **Expected:** validate.sh reports FAIL for the comment check
- **Covers criteria:** AC-3, AC-4

### TC-7: CLAUDE.md reflects the split strategy
- **Type:** manual review
- **Target:** CLAUDE.md Constraints section
- **Input:** Read CLAUDE.md after implementation
- **Expected:** The constraints section mentions the split strategy and references D-13
- **Covers criteria:** AC-2 (documentation)

### TC-8: Section 8 validation checklist updated
- **Type:** manual review
- **Target:** specs.md section 8
- **Input:** Read section 8 after implementation
- **Expected:** Two new checklist items for conventions skill line count and line-count comment
- **Covers criteria:** AC-4

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: specs.md section 6 documents budget | TC-1 |
| AC-2: Split strategy defined | TC-2, TC-7 |
| AC-3: Generated skill tracks line count | TC-3, TC-6 |
| AC-4: validate.sh checks line limit | TC-4, TC-5, TC-6, TC-8 |
