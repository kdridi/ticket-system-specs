---
id: TS-009
title: "Implement /ticket-system-help command with per-verb detail and live status summary"
status: ongoing
priority: P1
type: feature
created: 2026-04-03 23:52:07
updated: 2026-04-04 03:01:13
dependencies: []
assignee: unassigned
estimated_complexity: medium
---

# TS-009: Implement /ticket-system-help command with per-verb detail and live status summary

## Objective
Add a `/ticket-system-help` command that, when run without arguments, lists all available ticket-system commands with short descriptions and shows a live summary of what can currently be done (based on the current state of backlog, planned, and ongoing tickets). When run with a verb argument (e.g., `/ticket-system-help create`), it displays detailed documentation for that specific command including the template it uses and all supported options.

## Context
The ticket system currently has no self-documenting entry point. Users must read individual skill files to understand what commands are available and what they do. A help command lowers the barrier to entry, accelerates onboarding, and surfaces actionable next steps based on the current project state.

## Acceptance Criteria
- [ ] Running `/ticket-system-help` with no arguments prints the full list of available ticket-system verbs with one-line descriptions.
- [ ] Running `/ticket-system-help <verb>` prints detailed documentation for that verb, including the template or format it uses and what it accomplishes.
- [ ] The no-argument output includes a live status section showing what the user can currently do (e.g., "2 tickets in backlog — run /ticket-system-schedule to plan them", "1 ticket ongoing — run /ticket-system-implement to continue").
- [ ] The live status section reads the current state from the tickets directory using config from `.tickets/config.yml`.
- [ ] Unknown verbs produce a helpful error message listing available verbs.
- [ ] The command is registered as a proper skill with correct frontmatter.

## Technical Approach
Create a new skill `ticket-system-help` following the conventions in `ticket-system-conventions`. The skill reads `.tickets/config.yml` for `tickets_dir`, then scans ticket directories to build the live status summary. Verb documentation is embedded in the skill itself, describing each command. The skill is user-invocable and dispatches on the first argument if provided.

## Dependencies
<!-- List ticket IDs that must be completed before this one. -->

## Files Modified
- `specs.md` — Added /ticket-system-help command across sections 2.3, 2.4, 4.1, 4.2, 5.1, and 8
- `CLAUDE.md` — Updated skill directory count from 9 to 10

## Decisions
<!-- Design decisions made during this ticket. -->

## Notes
The live status section should be contextually smart: it should surface the single most actionable next step prominently, followed by additional context. For example, if there is an ongoing ticket, that should be highlighted first.

## Log
- 2026-04-03 23:52:07: Ticket created.
- 2026-04-04 00:12:40: Ticket scheduled and added to roadmap at position 4.
- 2026-04-04 02:55:14: Ticket activated.
- 2026-04-04 03:01:13: Implementation complete. All 8 plan steps executed, validate-spec.sh passes.
