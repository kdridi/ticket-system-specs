# Test Plan — TS-011

## Strategy
This ticket modifies a specification file (`specs.md`), not executable code. There are no unit tests to run. Verification is done through textual validation: grepping for expected and unexpected patterns, and manual review of each changed section.

All test cases below are integration-level checks performed by reading the final `specs.md` after all changes are applied.

## Test Cases

### TC-1: Section 3.4 defines YAML format
- **Type:** integration
- **Target:** `specs.md` section 3.4
- **Input:** Read section 3.4 content
- **Expected:** Section 3.4 references `tickets/planned/roadmap.yml` (not `roadmap.md`), contains a YAML code block with `tickets:` as the root key, and each entry has fields: position, id, title, size, priority, dependencies, rationale.
- **Covers criteria:** AC-1 (YAML format defined), AC-2 (all fields preserved)

### TC-2: All current fields preserved in YAML format
- **Type:** integration
- **Target:** `specs.md` section 3.4 YAML example
- **Input:** Read the YAML example in section 3.4
- **Expected:** The example contains all seven fields: position, id (as `id:`), title, size, priority, dependencies, rationale. No field from the old markdown table is missing.
- **Covers criteria:** AC-2

### TC-3: Commands reference roadmap.yml
- **Type:** integration
- **Target:** `specs.md` section 4.2
- **Input:** Grep for `roadmap.md` in section 4.2
- **Expected:** Zero occurrences of `roadmap.md`. The schedule command (step 7), analyze command (description + step 2), and plan command (step 7) all reference `roadmap.yml`.
- **Covers criteria:** AC-3

### TC-4: init-project.sh creates roadmap.yml
- **Type:** integration
- **Target:** `specs.md` section 5.4
- **Input:** Read section 5.4, step 6
- **Expected:** Step 6 says `Create tickets/planned/roadmap.yml` with `tickets: []` (empty YAML list), not `roadmap.md` with a table header.
- **Covers criteria:** AC-4

### TC-5: No remaining roadmap.md references
- **Type:** integration
- **Target:** `specs.md` (entire file)
- **Input:** `Grep` for `roadmap\.md` across the entire file
- **Expected:** Zero matches.
- **Covers criteria:** AC-1, AC-3, AC-4, AC-5 (ensures completeness)

### TC-6: Conventions skill generation references YAML roadmap
- **Type:** integration
- **Target:** `specs.md` section 5.2 (line ~605) and section 3.4
- **Input:** Read the generation rule for ticket-system-conventions skill
- **Expected:** The generation rule still references "roadmap format" (which now points to the YAML format in section 3.4). The conventions skill will be generated from the spec, so updating section 3.4 is sufficient.
- **Covers criteria:** AC-5

### TC-7: Insertion ordering logic specified
- **Type:** integration
- **Target:** `specs.md` section 3.4
- **Input:** Read section 3.4
- **Expected:** The section explicitly describes insertion ordering: (1) dependency-first (a ticket must appear after its dependencies), (2) within the same dependency tier, sort by priority P0 > P1 > P2. It also describes how to remove a ticket (delete the entry, re-number positions).
- **Covers criteria:** AC-6

### TC-8: Directory tree updated
- **Type:** integration
- **Target:** `specs.md` section 3.2
- **Input:** Read the directory tree in section 3.2
- **Expected:** The tree shows `roadmap.yml` not `roadmap.md`.
- **Covers criteria:** AC-1 (consistency)

### TC-9: Lifecycle description updated
- **Type:** integration
- **Target:** `specs.md` section 3.5
- **Input:** Read the lifecycle bullets
- **Expected:** The "Schedule" bullet references `roadmap.yml` not `roadmap.md`.
- **Covers criteria:** AC-3 (consistency)

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: Section 3.4 defines YAML roadmap format | TC-1, TC-5, TC-8 |
| AC-2: All current fields preserved | TC-1, TC-2 |
| AC-3: Section 4.2 commands reference roadmap.yml | TC-3, TC-5, TC-9 |
| AC-4: init-project.sh creates roadmap.yml | TC-4, TC-5 |
| AC-5: Conventions skill updated with new format | TC-5, TC-6 |
| AC-6: Insertion ordering logic specified | TC-7 |
