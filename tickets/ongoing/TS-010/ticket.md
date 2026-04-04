---
id: TS-010
title: "Improve specs.md maintainability without splitting"
status: ongoing
priority: P1
type: infrastructure
created: 2026-04-03 23:57:53
updated: 2026-04-04 02:38:31
dependencies: []
assignee: unassigned
estimated_complexity: medium
---

# TS-010: Improve specs.md maintainability without splitting

## Objective

Make `specs.md` easier to navigate and maintain as the backlog grows, without splitting it into multiple files. Add tooling to catch cross-reference drift and enforce section discipline.

## Context

With 10+ tickets in the backlog, many requiring spec changes, we evaluated splitting `specs.md` into sub-files. The conclusion: splitting breaks the core "self-contained prompt" contract and introduces assembly complexity. Instead, we invest in navigation, validation, and discipline within the monolith.

Key factors in the decision:
- 664 lines (~3,000 tokens) is trivial for 1M context — no size pressure
- Cross-references between sections are tight and would drift if split
- Assembly/concatenation step has no clean owner
- Claude Code's Edit tool handles surgical changes efficiently

## Acceptance Criteria
- [ ] `specs.md` has a clickable table of contents at the top with anchors to all sections and subsections
- [ ] A `validate-spec.sh` script exists that checks cross-reference integrity (every command references a valid agent, every agent has a matching skill, no hardcoded paths or prefixes)
- [ ] No section in `specs.md` exceeds 200 lines (refactor any that do)
- [ ] `CLAUDE.md` documents the feature-branch workflow for parallel spec changes
- [ ] `validate-spec.sh` is POSIX-compatible (bash + standard utils only)

## Technical Approach

1. **Clickable TOC** — Add markdown anchor links at the top of `specs.md` covering all 8 sections and key subsections. ~10-15 lines.
2. **validate-spec.sh** — A bash script that:
   - Extracts agent names from the agent table (section 2.3) and verifies each command (section 4) references one
   - Checks for hardcoded `~/.claude/` paths (should all be `$CLAUDE_DIR`)
   - Checks for hardcoded ticket prefixes
   - Reports section line counts and warns if any exceed 200
3. **Section budget enforcement** — Review current section sizes, refactor any exceeding 200 lines (likely section 4 Commands)
4. **CLAUDE.md update** — Add a "Parallel Spec Work" subsection recommending feature branches for concurrent spec changes

## Dependencies

None.

## Files Modified
- `specs.md` — Added clickable TOC (36 lines), refactored section 4 from 267 to 190 lines
- `validate-spec.sh` — New file: cross-reference integrity checker
- `test-validate-spec.sh` — New file: test suite for validate-spec.sh (9 test cases)
- `CLAUDE.md` — Added "Parallel Spec Work" subsection

## Decisions

- D-1: Decided NOT to split specs.md into sub-files. The self-contained prompt contract and cross-reference integrity outweigh the parallel-edit benefits.

## Notes

- This decision was reached by running two independent analysis agents (FOR and AGAINST splitting) and synthesizing their arguments.
- If specs.md ever exceeds ~1500 lines, revisit the split decision.

## Log
- 2026-04-03 23:57:53: Ticket created.
- 2026-04-04 00:12:40: Ticket scheduled and added to roadmap at position 2.
- 2026-04-04 02:26:18: Ticket activated.
- 2026-04-04 02:38:31: Implementation complete. All 5 steps executed, all 9 test cases passing.
