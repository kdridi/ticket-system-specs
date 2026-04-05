---
id: TS-015
title: "Add configuration variables system to specs.md"
status: completed
priority: P1
type: feature
created: 2026-04-04 12:00:00
updated: 2026-04-05 14:49:09
dependencies: []
assignee: unassigned
estimated_complexity: small
---

# TS-015: Add configuration variables system to specs.md

## Objective
Add a variables section at the top of `specs.md` that defines configurable parameters (model names, retry counts, etc.) used throughout the spec. This makes the spec parameterizable without modifying the body of the document.

## Context
Currently, model names (haiku, sonnet, opus) and other parameters are hardcoded throughout specs.md. If a user wants to use different models (e.g., Sonnet instead of Opus for the coder to reduce cost), they must find and replace multiple occurrences. A variables system allows changing one value at the top to affect the entire generation.

Identified during audit review as a key usability improvement for spec customization.

## Acceptance Criteria
- [ ] A new section 0 "Configuration Variables" exists at the top of specs.md
- [ ] Variables are defined in a table: name, default value, description
- [ ] At minimum these variables are defined: WEAK_MODEL, MID_MODEL, STRONG_MODEL, MAX_RETRY
- [ ] All model references in section 2.3 (agent profiles) use the variable names instead of hardcoded model names
- [ ] The generation instruction (preamble) tells Claude Code to resolve variables before generating files
- [ ] The variables section is clearly marked as the only section users should customize

## Technical Approach
Add a new section 0 to specs.md before the current section 1:

```markdown
## 0. CONFIGURATION VARIABLES

These variables control the generated system. Modify defaults here before generation.

| Variable | Default | Used in | Description |
|----------|---------|---------|-------------|
| WEAK_MODEL | haiku | reader agent | Model for read-only operations |
| MID_MODEL | sonnet | editor, verifier, ops agents | Model for structured edits |
| STRONG_MODEL | opus | planner, coder agents | Model for deep analysis and implementation |
| MAX_RETRY | 3 | implement-verify loop | Max verify failures before forced re-plan |
```

In section 2.3, replace:
- `haiku` → `$WEAK_MODEL`
- `sonnet` → `$MID_MODEL`  
- `opus` → `$STRONG_MODEL`

Add to the generation preamble: "Resolve all $VARIABLE references using the defaults from section 0 before generating files."

## Dependencies
<!-- None -->

## Files Modified
- `specs.md` — added section 0 (Configuration Variables), updated ToC, replaced hardcoded model names in section 2.3 with `$VARIABLE` references, added variable resolution instruction to preamble
- `CLAUDE.md` — updated section structure reference from 8 to 9 sections, noted section 0 as user-customizable

## Decisions
- Variables use `$VARIABLE` syntax (dollar-sign prefix) for clarity in the spec context. These are resolved by Claude Code at generation time, not by bash.
- `MAX_RETRY` is defined now but not yet referenced in the spec body; TS-017 will add the usage.
- Section 0 is placed before the ToC with horizontal rule separators for visual clarity.

## Notes
- The variable system is resolved at generation time, not at runtime. The generated files contain the resolved values.
- This enables users to generate a "budget" version (all Sonnet) or a "premium" version (all Opus) with a single change.
- MAX_RETRY will be used by TS-017 (retry counter).

## Log
- 2026-04-04 12:00:00: Ticket created from audit review (W16).
- 2026-04-05 14:42:32: Ticket activated, moved to ongoing.
- 2026-04-05 14:47:13: Implementation complete. Added section 0 with 4 variables, replaced model names in 2.3, updated preamble and CLAUDE.md.
- 2026-04-05 14:49:09: VERDICT: PASS — Ticket completed.
