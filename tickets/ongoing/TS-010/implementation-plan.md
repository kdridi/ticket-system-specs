# Implementation Plan — TS-010

## Overview

Add a clickable table of contents to specs.md, create a validate-spec.sh script for cross-reference integrity checking, refactor section 4 (268 lines, exceeds 200-line budget), and document the feature-branch workflow in CLAUDE.md.

## Steps

### Step 1: Add clickable table of contents to specs.md
- **Files:** `specs.md`
- **What:** Insert a markdown TOC immediately after the opening blockquote (before the first `---` separator). The TOC will contain anchor links to all 8 sections and their key subsections. GitHub-flavored markdown auto-generates anchors from headings, so links like `[1. Vision and Philosophy](#1-vision-and-philosophy)` will work.
- **Tests first:** N/A (documentation change). Verify with grep that all TOC anchors correspond to actual headings.
- **Done when:** A TOC block exists at the top of specs.md with clickable links to all sections and subsections.

### Step 2: Refactor section 4 to fit within 200-line budget
- **Files:** `specs.md`
- **What:** Section 4 (Command Pipeline) currently spans lines 262-529 (268 lines). To bring it under 200 lines, apply these techniques:
  - Remove the ASCII pipeline diagram (section 4.1, ~25 lines) and replace with a compact summary sentence or short list
  - Tighten verbose command descriptions by removing redundant phrasing
  - Collapse the `/ticket-system-analyze` 7-dimension table into a compact list if it saves lines
  - Ensure no semantic content is lost -- all behavioral requirements must remain
- **Tests first:** N/A. After editing, count lines between section 4 and section 5 headers.
- **Done when:** Section 4 is under 200 lines. No acceptance criteria or behavioral requirements are removed.

### Step 3: Create validate-spec.sh
- **Files:** `validate-spec.sh` (new file, repository root)
- **What:** A POSIX-compatible bash script that:
  1. Extracts agent names from the agent profiles table in section 2.3 and verifies each command in section 4 references a valid agent
  2. Extracts skill names from the file tree in section 5.1 and verifies each agent has a matching skill directory
  3. Checks for hardcoded `~/.claude/` paths (should all be `$CLAUDE_DIR` except in prose describing the default)
  4. Checks for hardcoded ticket prefixes (PROJ is allowed only in template examples)
  5. Reports line counts for each section and warns if any exceed 200 lines
  6. Exits with 0 if all checks pass, 1 if any fail
- **Tests first:** Write the test cases in TC-1 through TC-6 before implementing the script.
- **Done when:** Running `bash validate-spec.sh` passes on the current specs.md. The script reports section line counts and validates cross-references.

### Step 4: Update CLAUDE.md with feature-branch workflow documentation
- **Files:** `CLAUDE.md`
- **What:** Add a "Parallel Spec Work" subsection under the existing "Iterative Workflow" section. The subsection will recommend:
  - Use feature branches for concurrent spec changes
  - Keep changes scoped to specific sections to minimize merge conflicts
  - Run `validate-spec.sh` before merging to catch cross-reference drift
- **Tests first:** N/A (documentation change).
- **Done when:** CLAUDE.md contains a "Parallel Spec Work" subsection with the described guidance.

### Step 5: Update ticket metadata
- **Files:** `tickets/ongoing/TS-010/ticket.md`
- **What:** Fill in "Files Modified" and "Decisions" sections. Add log entries for implementation progress.
- **Tests first:** N/A
- **Done when:** Ticket reflects all changes made.

## Risk Notes

- Refactoring section 4 is the highest-risk step. The 200-line budget requires cutting ~68 lines without losing any behavioral specification. The approach prioritizes removing visual formatting (ASCII diagrams) and tightening prose over removing requirements.
- The validate-spec.sh script relies on grep patterns to extract agent names and skill names from markdown tables and code blocks. If the specs.md format changes significantly, these patterns may need updating.
- The "allowed hardcoded paths" exception (prose mentioning `~/.claude/` as the default) needs a clear pattern so validate-spec.sh does not produce false positives.
