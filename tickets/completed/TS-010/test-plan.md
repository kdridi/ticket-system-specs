# Test Plan — TS-010

## Strategy

Integration testing using bash commands (grep, wc, awk) to validate structural properties of specs.md and CLAUDE.md. The validate-spec.sh script itself serves as both deliverable and test harness.

## Test Cases

### TC-1: Clickable TOC exists in specs.md
- **Type:** integration
- **Target:** `specs.md`
- **Input:** Search for markdown anchor links matching the pattern `[...](#...)` near the top of the file (first 30 lines after the blockquote)
- **Expected:** At least 8 anchor links present (one per section), all corresponding to actual headings in the file
- **Covers criteria:** AC-1 (clickable table of contents)

### TC-2: TOC anchors resolve to actual headings
- **Type:** integration
- **Target:** `specs.md`
- **Input:** Extract all anchor targets from TOC links, convert to heading format, verify each exists as a heading in specs.md
- **Expected:** Every TOC anchor corresponds to an actual heading. Zero broken links.
- **Covers criteria:** AC-1 (clickable table of contents with anchors to all sections and subsections)

### TC-3: validate-spec.sh exists and is executable
- **Type:** unit
- **Target:** `validate-spec.sh`
- **Input:** `test -f validate-spec.sh && test -x validate-spec.sh`
- **Expected:** Both tests pass (file exists and is executable)
- **Covers criteria:** AC-2 (validate-spec.sh script exists)

### TC-4: validate-spec.sh detects valid cross-references
- **Type:** integration
- **Target:** `validate-spec.sh`
- **Input:** `bash validate-spec.sh` on the current (valid) specs.md
- **Expected:** Exit code 0, no errors reported for agent-command or agent-skill cross-references
- **Covers criteria:** AC-2 (checks cross-reference integrity)

### TC-5: validate-spec.sh detects hardcoded paths
- **Type:** integration
- **Target:** `validate-spec.sh`
- **Input:** Temporarily insert a hardcoded `~/.claude/agents` path in specs.md, run validate-spec.sh
- **Expected:** Exit code 1, error message about hardcoded path
- **Covers criteria:** AC-2 (no hardcoded paths or prefixes)

### TC-6: validate-spec.sh reports section line counts
- **Type:** integration
- **Target:** `validate-spec.sh`
- **Input:** Run `bash validate-spec.sh` and capture output
- **Expected:** Output contains line counts for all 8 sections, with a warning for any section exceeding 200 lines
- **Covers criteria:** AC-2, AC-3 (section budget enforcement)

### TC-7: No section in specs.md exceeds 200 lines
- **Type:** integration
- **Target:** `specs.md`
- **Input:** Count lines between consecutive `## N.` section headers
- **Expected:** All sections have 200 or fewer lines
- **Covers criteria:** AC-3 (no section exceeds 200 lines)

### TC-8: CLAUDE.md documents feature-branch workflow
- **Type:** integration
- **Target:** `CLAUDE.md`
- **Input:** `grep -c 'Parallel Spec Work' CLAUDE.md`
- **Expected:** At least 1 match
- **Covers criteria:** AC-4 (CLAUDE.md documents the feature-branch workflow)

### TC-9: validate-spec.sh is POSIX-compatible
- **Type:** unit
- **Target:** `validate-spec.sh`
- **Input:** Verify script uses `#!/bin/bash` shebang and only standard POSIX utilities (grep, awk, sed, wc, etc.)
- **Expected:** No references to non-POSIX tools (python, node, jq, etc.)
- **Covers criteria:** AC-5 (POSIX-compatible)

## Coverage Map

| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: specs.md has clickable TOC with anchors | TC-1, TC-2 |
| AC-2: validate-spec.sh checks cross-reference integrity | TC-3, TC-4, TC-5 |
| AC-3: No section exceeds 200 lines | TC-6, TC-7 |
| AC-4: CLAUDE.md documents feature-branch workflow | TC-8 |
| AC-5: validate-spec.sh is POSIX-compatible | TC-9 |
