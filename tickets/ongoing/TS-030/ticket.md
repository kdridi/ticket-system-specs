---
id: TS-030
title: "Add /ticket-system-edit command to modify tickets in backlog or planned"
status: ongoing
priority: P1
type: feature
created: 2026-04-08 11:26:17
updated: 2026-04-08 11:40:28
dependencies: []
assignee: ai
estimated_complexity: medium
---

# TS-030: Add /ticket-system-edit command to modify tickets in backlog or planned

## Objective
Add a `/ticket-system-edit` command that allows modifying existing tickets that are in the `backlog/` or `planned/` state. The command runs in a forked sub-agent (ticket-system-editor) to keep the main conversation context clean. It accepts a ticket ID and free-form modification instructions, applies the changes, preserves metadata and log history, and commits the result.

## Context
Currently there is no dedicated command to edit a ticket once it has been created. Users who want to narrow scope, update acceptance criteria, change priority, or refine a description must edit ticket files manually. A dedicated `/ticket-system-edit` command standardises this workflow, enforces guards against editing tickets that are already in progress or finished, and keeps a log of what changed.

## Acceptance Criteria
- [ ] Command accepts a ticket ID and modification instructions as arguments (e.g., `/ticket-system-edit TS-029 narrow scope to API layer only, remove UI criteria`).
- [ ] Rejects tickets whose current state is `ongoing/`, `completed/`, or `rejected/`; accepts only `backlog/` and `planned/`.
- [ ] Reads the current ticket content before applying any changes.
- [ ] Applies the requested modifications: rewrite acceptance criteria, narrow/expand scope, update description, change priority, etc.
- [ ] Preserves ticket metadata: `id`, `created` date, and the existing log history (append-only).
- [ ] Updates the `updated` timestamp to the current time (via `date '+%Y-%m-%d %H:%M:%S'`).
- [ ] Appends a log entry describing what was changed.
- [ ] Commits the modified ticket file with the message `PREFIX-XXX: Edit ticket — <brief summary of changes>`.
- [ ] Runs via `context: fork` with the `ticket-system-editor` agent.
- [ ] Skill file is located at `.claude/skills/ticket-system-edit/SKILL.md`.

## Technical Approach
- Create a new skill directory `.claude/skills/ticket-system-edit/` with a `SKILL.md` file.
- Frontmatter: `context: fork`, `agent: ticket-system-editor`, `user-invocable: true`.
- The skill reads `.tickets/config.yml` first (no hardcoded prefixes).
- Locate the ticket by checking `tickets/backlog/PREFIX-XXX.md` then `tickets/planned/PREFIX-XXX.md`; error if found elsewhere or not found at all.
- Parse the current ticket, apply modifications from the argument instructions, update `updated` timestamp, append log entry.
- Write the modified file back using the `Edit` or `Write` tool.
- Commit using a simple quoted git commit message (no heredoc).

## Dependencies
<!-- None -->

## Files Modified
- `specs.md` — Added /ticket-system-edit command specification (section 4.2), updated agent table (section 2.3), auto-invocation table (section 2.4), file tree (section 5.1), and validation checklist (section 8).
- `CLAUDE.md` — Updated skill directory count from 13 to 14.
- `.claude/skills/ticket-system-edit/SKILL.md` — Created skill file (gitignored, local only).

## Decisions
<!-- Design decisions made during this ticket. -->

## Notes
- The modification instructions are free-form natural language; the agent must interpret them intelligently.
- If the ticket is in `planned/`, the roadmap.yml entry does not need to be changed unless priority or title changes — handle title/priority updates to roadmap.yml as well.

## Log
- 2026-04-08 11:26:17: Ticket created.
- 2026-04-08 11:29:40: Scheduled to planned (roadmap position 1).
- 2026-04-08 11:33:15: Activated — moved to ongoing, worktree created.
- 2026-04-08 11:40:28: Implementation complete — specs.md updated with command specification, cross-references, and validation checklist entries; CLAUDE.md updated; skill SKILL.md created locally.
