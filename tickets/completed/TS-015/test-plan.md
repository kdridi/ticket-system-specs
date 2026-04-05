# Test Plan — TS-015

## Strategy
Manual validation of the spec file structure. Since this ticket modifies a specification document (not code), testing consists of structural verification and content checks performed by reviewing the modified `specs.md`.

## Test Cases

### TC-1: Section 0 exists and is positioned correctly
- **Type:** integration
- **Target:** `specs.md` structure
- **Input:** Read specs.md
- **Expected:** A section titled "0. CONFIGURATION VARIABLES" (or similar) appears after the preamble blockquote and before the Table of Contents.
- **Covers criteria:** AC-1

### TC-2: Variables table is complete
- **Type:** unit
- **Target:** Section 0 content
- **Input:** Read the variables table in section 0
- **Expected:** Table contains at minimum: `WEAK_MODEL` (default: haiku), `MID_MODEL` (default: sonnet), `STRONG_MODEL` (default: opus), `MAX_RETRY` (default: 3). Each row has name, default value, and description columns.
- **Covers criteria:** AC-2, AC-3

### TC-3: No hardcoded model names in section 2.3
- **Type:** unit
- **Target:** Section 2.3 agent profiles table
- **Input:** Grep for literal `haiku`, `sonnet`, `opus` in the Model column of section 2.3
- **Expected:** Zero matches. All model references use `$WEAK_MODEL`, `$MID_MODEL`, or `$STRONG_MODEL`.
- **Covers criteria:** AC-4

### TC-4: Generation preamble includes variable resolution instruction
- **Type:** unit
- **Target:** Preamble blockquote in specs.md
- **Input:** Read the preamble (first blockquote)
- **Expected:** Contains instruction to resolve `$VARIABLE` references using section 0 defaults before generating files.
- **Covers criteria:** AC-5

### TC-5: Section 0 is marked as user-customizable
- **Type:** unit
- **Target:** Section 0 content
- **Input:** Read section 0 text
- **Expected:** Contains explicit language indicating this is the only section users should modify before generation.
- **Covers criteria:** AC-6

### TC-6: Table of Contents includes section 0
- **Type:** unit
- **Target:** Table of Contents in specs.md
- **Input:** Read the ToC
- **Expected:** Contains an entry for section 0 (Configuration Variables) before the section 1 entry.
- **Covers criteria:** AC-1

### TC-7: No literal model names leaked elsewhere in specs.md
- **Type:** integration
- **Target:** Entire specs.md
- **Input:** Grep for `\bhaiku\b`, `\bsonnet\b`, `\bopus\b` outside of section 0
- **Expected:** Zero matches outside the defaults column of section 0's variable table. (Note: "Opus 4.6" in the preamble refers to the Claude Code model being used to process the spec, not a generated variable -- this is acceptable.)
- **Covers criteria:** AC-4

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: Section 0 exists at top of specs.md | TC-1, TC-6 |
| AC-2: Variables in a table with name, default, description | TC-2 |
| AC-3: WEAK_MODEL, MID_MODEL, STRONG_MODEL, MAX_RETRY defined | TC-2 |
| AC-4: Model references in 2.3 use variables | TC-3, TC-7 |
| AC-5: Preamble tells Claude to resolve variables | TC-4 |
| AC-6: Section 0 marked as only customizable section | TC-5 |
