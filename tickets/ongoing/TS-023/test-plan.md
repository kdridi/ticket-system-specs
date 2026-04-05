# Test Plan — TS-023

## Strategy
Manual review (documentation-only ticket). Each test case verifies the presence and correctness of a specific documentation addition by reading the modified file and checking for the expected content.

## Test Cases

### TC-1: Per-project ticket constraint in section 1.2
- **Type:** manual review
- **Target:** `specs.md` section 1.2 (Core Principles)
- **Input:** Read section 1.2 after implementation
- **Expected:** Text explicitly states that "one active ticket at a time" applies per `.tickets/` directory (per project), not per machine or per user.
- **Covers criteria:** AC-1

### TC-2: Conflict resolution subsection in /ticket-system-merge
- **Type:** manual review
- **Target:** `specs.md` section 4.2, `/ticket-system-merge` specification
- **Input:** Read the `/ticket-system-merge` section after implementation
- **Expected:** A conflict resolution note/subsection exists after step 8, documenting: (a) user resolves conflicts with standard git tools, (b) user commits the merge, (c) user re-runs `/ticket-system-merge` to proceed with cleanup.
- **Covers criteria:** AC-2

### TC-3: Context isolation note in section 2.1
- **Type:** manual review
- **Target:** `specs.md` section 2.1 (Two Complementary Layers)
- **Input:** Read section 2.1 after implementation
- **Expected:** A note about `context: fork` limitation exists, stating forked agents do not inherit parent conversation context and users should include relevant context in arguments.
- **Covers criteria:** AC-3

### TC-4: Single-developer decision in section 6
- **Type:** manual review
- **Target:** `specs.md` section 6 (Decisions)
- **Input:** Read the decisions table after implementation
- **Expected:** A new decision row (D-14 or next available number) states this system is designed for single-developer workflow and multi-developer usage is not supported.
- **Covers criteria:** AC-4

### TC-5: Worktree model explanation
- **Type:** manual review
- **Target:** `specs.md` section 3.2 or 3.5
- **Input:** Read the relevant section after implementation
- **Expected:** The text explains that `tickets/ongoing/` on main is always empty because active tickets live in worktrees, and this allows planning/scheduling to continue on main while implementation runs in parallel.
- **Covers criteria:** AC-5

### TC-6: CLAUDE.md in sync with specs.md
- **Type:** manual review
- **Target:** `CLAUDE.md`
- **Input:** Compare CLAUDE.md Key Design Decisions with the new specs.md content
- **Expected:** CLAUDE.md reflects the single-developer workflow decision and any other relevant additions. No stale or contradictory information.
- **Covers criteria:** AC-1 through AC-5 (indirectly)

### TC-7: No existing content broken
- **Type:** manual review
- **Target:** `specs.md` (full file)
- **Input:** Review the overall file structure and section numbering
- **Expected:** All existing content is preserved. No section numbers shifted. No existing decisions renumbered. Table of contents still valid if present.
- **Covers criteria:** All (regression check)

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: Per-project clarification | TC-1, TC-6, TC-7 |
| AC-2: Conflict resolution subsection | TC-2, TC-7 |
| AC-3: Context isolation note | TC-3, TC-6, TC-7 |
| AC-4: Single-developer decision | TC-4, TC-6, TC-7 |
| AC-5: Worktree model explanation | TC-5, TC-6, TC-7 |
