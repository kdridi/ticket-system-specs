---
id: TS-001
title: "Add root README explaining the ticket system for developers and users"
status: ongoing
priority: P1
type: docs
created: 2026-04-03 23:41:51
updated: 2026-04-05 14:14:15
dependencies: []
assignee: unassigned
estimated_complexity: small
---

# TS-001: Add root README explaining the ticket system for developers and users

## Objective
Create a `README.md` at the repository root that explains the ticket system from two perspectives: developers who want to understand how it works, and users who want to install and use it after generation.

## Context
The repository currently has no README, making it hard for newcomers to understand the purpose of the project, how to generate the system from `specs.md`, and how to install and run the resulting ticket workflow system in their own projects.

## Acceptance Criteria
- [ ] README exists at the repository root
- [ ] README has a section explaining how the ticket system works (concepts, directory structure, agents, skills, slash commands)
- [ ] README has a section explaining how to generate the system from `specs.md`
- [ ] README has a section explaining how to install the generated system into a target project
- [ ] README has a section explaining how to initialize and use the system in a new project
- [ ] README includes a brief explanation of the worktree model (why ongoing/ on main stays empty, how planning continues while implementation runs in a worktree)
- [ ] README is written in plain English, no emojis, clear and concise

## Technical Approach
Write `README.md` with the following sections:
1. **What is the Ticket System** — overview of the file-based, AI-native project management system
2. **How It Works** — agents, skills, slash commands, ticket lifecycle, worktree isolation model
3. **Generating the System** — how to feed `specs.md` to Claude Code and what gets produced
4. **Installing** — how to run `install.sh` and what `$CLAUDE_DIR` means
5. **Initializing a Project** — how to run `init-project.sh` in a target repo
6. **Using the System** — brief guide to all available slash commands including utility commands (next, doctor, abort, help)
7. **Limitations** — mono-developer workflow, fork context loss, known constraints

## Dependencies
<!-- None -->

## Files Modified
- `README.md` (create)
- `CLAUDE.md` (modify -- updated repo structure and rules sections)

## Decisions
<!-- To be filled during implementation. -->

## Notes
- This file belongs in `ticket-system-specs/` — it documents the spec repo, not the generated system.
- The generated system's own documentation lives in `ARCHITECTURE.md` (produced during generation).
- Updated 2026-04-04: expanded scope to cover worktree model explanation and new utility commands (next, doctor, abort) identified during audit reviews.

## Log
- 2026-04-03 23:41:51: Ticket created.
- 2026-04-04 12:00:00: Updated scope — added worktree explanation, new commands, limitations section.
- 2026-04-05 14:09:40: Ticket activated, moved to ongoing.
- 2026-04-05 14:14:15: Implementation complete. Created README.md, updated CLAUDE.md.
