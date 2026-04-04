# Test Plan — TS-004

## Strategy

Manual verification using grep searches across specs.md and CLAUDE.md. No automated tests apply since this ticket modifies only specification and documentation files.

## Test Cases

### TC-1: No hardcoded file count in specs.md section 8
- **Type:** integration
- **Target:** `specs.md`
- **Input:** `grep -i -E 'file count|exactly.*files|18 files' specs.md`
- **Expected:** Zero matches
- **Covers criteria:** AC-1 (no hardcoded file count)

### TC-2: Structural file list present in specs.md section 8
- **Type:** integration
- **Target:** `specs.md` section 8
- **Input:** Verify presence of named file checklist items for: ARCHITECTURE.md, install.sh, init-project.sh, all 6 agent files, all 9 skill directories
- **Expected:** All 18 named items present as individual checklist entries under "Structural completeness"
- **Covers criteria:** AC-2 (lists required files by name)

### TC-3: validate.sh conditional criterion
- **Type:** unit
- **Target:** Repository root
- **Input:** Check if `validate.sh` exists
- **Expected:** File does not exist (TS-002 is still in backlog), so AC-3 is vacuously satisfied
- **Covers criteria:** AC-3 (conditional on validate.sh existence)

### TC-4: CLAUDE.md reflects structural validation approach
- **Type:** integration
- **Target:** `CLAUDE.md`
- **Input:** `grep -i -E 'file count|exactly.*files|18 files' CLAUDE.md`
- **Expected:** Zero matches. The smoke test section references files "by name" and points to specs.md section 8.
- **Covers criteria:** AC-4 (CLAUDE.md updated)

### TC-5: CLAUDE.md checklist count reference is accurate
- **Type:** unit
- **Target:** `CLAUDE.md`
- **Input:** Check that any numeric reference to section 8 checklist count matches the actual count of `- [ ]` items in specs.md section 8
- **Expected:** Either the count matches or a count-agnostic phrasing is used
- **Covers criteria:** AC-4 (CLAUDE.md accuracy)

## Coverage Map

| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: No hardcoded file count in specs.md | TC-1 |
| AC-2: Lists required files by name | TC-2 |
| AC-3: validate.sh implements structural check (if it exists) | TC-3 |
| AC-4: CLAUDE.md updated | TC-4, TC-5 |
