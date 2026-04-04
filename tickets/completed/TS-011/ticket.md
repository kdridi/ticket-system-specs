---
id: TS-011
title: "Migrate roadmap from markdown table to YAML format"
status: completed
priority: P0
type: refactor
created: 2026-04-04 12:00:00
updated: 2026-04-04 23:48:02
dependencies: []
assignee: unassigned
estimated_complexity: medium
---

# TS-011: Migrate roadmap from markdown table to YAML format

## Objective
Replace the `roadmap.md` markdown table format with a `roadmap.yml` YAML format to eliminate parsing fragility and silent corruption risks.

## Context
The current roadmap uses a markdown table that agents must parse, modify, and re-serialize. Markdown tables are fragile: a pipe character in a title or rationale breaks parsing, column alignment drifts, and ordered reinsertion (by priority + dependencies) is complex string manipulation for an LLM. YAML is unambiguous, machine-friendly, and still human-readable.

Identified during audit review as the most probable source of silent data corruption in the current system.

## Acceptance Criteria
- [x] `specs.md` section 3.4 defines the roadmap format as YAML instead of markdown table
- [x] The YAML format preserves all current fields: position, ticket ID, title, size, priority, dependencies, rationale
- [x] `specs.md` section 4.2 updates all commands that read/write the roadmap (schedule, analyze, plan) to reference `roadmap.yml`
- [x] `init-project.sh` creates `tickets/planned/roadmap.yml` with an empty list instead of `roadmap.md`
- [x] The `ticket-system-conventions` skill is updated with the new roadmap format
- [x] Insertion ordering logic (dependency-first, then priority) is clearly specified for the YAML structure

## Technical Approach
Replace the roadmap format in specs.md section 3.4:

```yaml
# roadmap.yml
tickets:
  - position: 1
    id: PREFIX-005
    title: "Title"
    size: medium
    priority: P0
    dependencies: []
    rationale: "Reason"
  - position: 2
    id: PREFIX-008
    title: "Title"
    size: medium
    priority: P0
    dependencies: [PREFIX-005]
    rationale: "Depends on auth"
```

Update all command specs that reference `roadmap.md`:
- `/ticket-system-schedule` (inserts into roadmap)
- `/ticket-system-analyze` (reads first item)
- `/ticket-system-plan` (removes row on activation)

Update `init-project.sh` to create `roadmap.yml` with `tickets: []`.

## Dependencies
<!-- None -->

## Files Modified
- `specs.md` (sections 3.2, 3.4, 3.5, 4.2 schedule/analyze/plan, 5.4)

## Decisions
<!-- To be filled during implementation. -->

## Notes
- The YAML format is easier for LLMs to manipulate (append to list, filter, sort) than markdown table string manipulation.
- Human readability is preserved — YAML is widely understood by developers.
- This is a breaking change for existing generated systems. Since regeneration replaces everything, impact is limited.

## Log
- 2026-04-04 12:00:00: Ticket created from audit review (W1).
- 2026-04-04 21:12:15: Ticket scheduled — moved to planned.
- 2026-04-04 23:28:20: Ticket activated — moved to ongoing.
- 2026-04-04 23:45:41: Implementation complete — all 9 plan steps executed (steps 8-9 were no-ops as expected).
- 2026-04-04 23:48:02: VERDICT: PASS — Ticket completed.
