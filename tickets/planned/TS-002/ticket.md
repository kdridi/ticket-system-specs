---
id: TS-002
title: "Add automated validation script for generated output"
status: planned
priority: P1
type: infrastructure
created: 2026-04-03 23:41:51
updated: 2026-04-05 04:36:22
dependencies: []
assignee: unassigned
estimated_complexity: small
---

# TS-002: Add automated validation script for generated output

## Objective
Replace the manual 39-point checklist in `specs.md` section 8 with a `validate.sh` script that runs automatically against a generated output directory and reports pass/fail for each check.

## Context
The current validation process is entirely manual. A developer must read through 39 checklist items and verify each one by hand after every generation cycle. This is slow, error-prone, and discourages frequent iteration. Automating these checks would make the inner feedback loop much faster and more reliable.

## Acceptance Criteria
- [ ] `validate.sh` exists at the repository root and is executable
- [ ] The script accepts the path to a generated output directory as its argument
- [ ] The script checks all items from the smoke test section (file count, frontmatter fields, hardcoded values, script permissions)
- [ ] The script validates that new agents (doctor, abort, next) are present if those features have been added to the spec
- [ ] The script checks that `roadmap.yml` format is valid YAML if the YAML migration has been applied
- [ ] The script checks that `test_command` is referenced in the verifier skill if configured
- [ ] The script reports a clear PASS/FAIL summary with per-check detail
- [ ] The script exits with a non-zero code on any failure (suitable for CI)
- [ ] No external dependencies beyond bash and standard POSIX utilities

## Technical Approach
- Parse generated agent files for required frontmatter fields using `grep`/`awk`
- Check for hardcoded prefixes and paths using `grep -r`
- Verify file permissions with `test -x`
- Count generated files with `find`
- Output a structured report (e.g., `[PASS]`/`[FAIL]` prefixes per check)
- Make checks conditional: if a feature is present in the spec, validate it; if not, skip with `[SKIP]`

## Dependencies
<!-- None -->

## Files Modified
- `validate.sh` (create)

## Decisions
<!-- To be filled during implementation. -->

## Notes
- The deep validation checklist (full 39 points) may be harder to automate; start with the smoke test items and expand incrementally.
- This file belongs in `ticket-system-specs/` alongside `install.sh` and `init-project.sh`.
- Updated 2026-04-04: expanded scope to cover validation of new features identified during audits (doctor, abort, next, roadmap YAML, test_command).

## Log
- 2026-04-03 23:41:51: Ticket created.
- 2026-04-04 12:00:00: Updated scope — added conditional checks for new audit-driven features.
