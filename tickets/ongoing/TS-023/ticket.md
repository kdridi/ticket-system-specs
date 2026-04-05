---
id: TS-023
title: "Add documentation clarifications and known limitations from audit reviews"
status: ongoing
priority: P3
type: docs
created: 2026-04-04 12:00:00
updated: 2026-04-05 16:28:41
dependencies: []
assignee: unassigned
estimated_complexity: small
---

# TS-023: Add documentation clarifications and known limitations from audit reviews

## Objective
Address several small documentation gaps and ambiguities identified during audit reviews by adding clarifications to specs.md and the conventions skill.

## Context
Two independent audit reviews identified minor documentation gaps that individually are trivial but collectively improve the spec's precision. Rather than creating separate tickets for each one-line change, this ticket groups them.

## Acceptance Criteria
- [ ] Section 1.2 or conventions clarifies: "One active ticket at a time" means per project (per `.tickets/` directory), not per machine or per user
- [ ] Section 4.2 `/ticket-system-merge` includes a "Conflict resolution" subsection documenting the manual procedure: resolve conflicts, `git add`, `git commit`, then re-run merge
- [ ] Section 2.1 or a new note documents the `context: fork` limitation: forked agents do not inherit the parent conversation context. Users should include sufficient detail in command arguments.
- [ ] Section 1.2 or 6 (Decisions) adds a note: "This system is designed for a single-developer workflow. Multi-developer usage is not supported and may cause data inconsistencies."
- [ ] The worktree model is briefly explained in context: "tickets/ongoing/ on main is always empty because active tickets live in worktrees. This allows planning and scheduling to continue on main while implementation runs in parallel."

## Technical Approach
Add the following to specs.md:
1. In section 1.2 (Core Principles), append: "**One active ticket per project.** The 'one active ticket' constraint applies per `.tickets/` directory. A developer working on multiple projects has independent ticket systems."
2. In section 4.2 `/ticket-system-merge`, after step 7 (conflict report), add: "**Manual conflict resolution:** The user resolves conflicts using standard git tools (`git diff`, `git add`). After resolution, the user commits the merge (`git commit`) and re-runs `/ticket-system-merge` which will detect the completed merge and proceed to worktree cleanup."
3. In section 2.1, add a note: "**Context isolation:** Each slash command forks into a separate agent context. The forked agent does not see the parent conversation history. Include relevant context in the command arguments."
4. In section 6 (Decisions), add: "D-11: Single-developer workflow by design. Multi-developer usage on the same repository is not supported."

## Dependencies
<!-- None -->

## Files Modified
- `specs.md` (sections 1.2, 2.1, 3.5, 4.2, 6)
- `CLAUDE.md` (Key Design Decisions section)

## Decisions
<!-- To be filled during implementation. -->

## Notes
- These are all additive changes — no existing behavior is modified.
- Each change is 1-3 sentences. The ticket is small by design.

## Log
- 2026-04-04 12:00:00: Ticket created — groups minor documentation items from audit reviews (M5, M9, M10, mono-dev clarification).
- 2026-04-05 16:24:21: Ticket activated — moved to ongoing, worktree created.
- 2026-04-05 16:28:41: Implementation complete — 6 documentation clarifications added across specs.md and CLAUDE.md in 6 commits.
