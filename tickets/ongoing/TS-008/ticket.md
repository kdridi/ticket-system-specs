---
id: TS-008
title: "Implement an interactive ticket creation command with guided scaffolding"
status: ongoing
priority: P1
type: feature
created: 2026-04-03 23:49:43
updated: 2026-04-04 02:48:19
dependencies: []
assignee: unassigned
estimated_complexity: medium
---

# TS-008: Implement an interactive ticket creation command with guided scaffolding

## Objective
Replace the current one-shot `/ticket-system-create` command with an interactive, dialogue-driven variant that guides the user through ticket creation. Rather than requiring a fully-formed request upfront, the command asks clarifying questions, suggests titles and descriptions, and iterates with the user until the ticket accurately reflects their intent.

## Context
The existing create command works well when the user has a clear idea of what they want. However, in many real-world situations the user has only a vague sense of a need — they know something is missing but cannot yet articulate it precisely. In those cases, the current command produces shallow or incomplete tickets. A scaffolded, conversational creation flow would raise ticket quality significantly and reduce the need for post-creation refinement.

## Acceptance Criteria
- [ ] The command detects when the user's input is vague or incomplete and enters a dialogue mode instead of immediately writing a ticket.
- [ ] In dialogue mode, the model asks targeted clarifying questions (one or two at a time) to surface the title, type, priority, objective, and acceptance criteria.
- [ ] The model proposes a draft ticket and asks the user to confirm, adjust, or iterate before writing any file.
- [ ] When the user confirms, the ticket is written to disk and committed exactly as in the current create flow.
- [ ] The command still supports the fast path: if the user provides a clear, complete title and type, it proceeds without dialogue.
- [ ] The dialogue state is held in-session only — no intermediate files are written until the user confirms.

## Technical Approach
- Extend or replace the `/ticket-system-create` skill with a new variant (e.g. `/ticket-system-create-guided` or an upgraded `/ticket-system-create` that auto-detects input quality).
- Use a heuristic or prompt to classify input as "clear" vs "vague": short inputs with no type/priority cues trigger dialogue mode.
- In dialogue mode, maintain a structured draft object in context and update it incrementally as the user answers questions.
- Present the full draft to the user for confirmation before calling any file-write or git operations.
- Keep the skill file within the 250-character description limit; move detailed logic into SKILL.md.

## Dependencies
<!-- List ticket IDs that must be completed before this one. -->

## Files Modified
- `specs.md` — Extended `/ticket-system-create` block in section 4.2 with input classification and dialogue mode specification.

## Decisions
<!-- Design decisions made during this ticket. -->

## Notes
- Consider whether this replaces `/ticket-system-create` entirely or lives alongside it.
- The name candidates discussed: "Create++", "Create Scaffolding", "Intelligent Create". The final name should follow the existing `ticket-system-*` convention.
- Dialogue depth should be configurable or capped (e.g. max 3 rounds) to avoid infinite loops.

## Log
- 2026-04-03 23:49:43: Ticket created.
- 2026-04-04 00:12:40: Ticket scheduled and added to roadmap at position 3.
- 2026-04-04 02:44:23: Ticket activated.
- 2026-04-04 02:48:19: Implementation complete. Extended /ticket-system-create in specs.md with dialogue mode (input classification, clarifying questions, draft confirmation gate). Section 4 at 193 lines (within 200-line budget). validate-spec.sh passes.
