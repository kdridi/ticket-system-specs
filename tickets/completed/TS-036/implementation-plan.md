# Implementation Plan — TS-036

## Overview
Add a `.context.md` artifact to the planning phase that captures codebase analysis findings for reuse by downstream phases (implement, verify, merge). This requires changes to three areas of `specs.md`: (1) the plan artifacts section (3.8), (2) the command specifications for plan/implement/verify/merge (section 4.2), and (3) the validation checklist (section 8). The `ticket-system-conventions` SKILL.md also needs updating to document the new artifact format. Finally, `CLAUDE.md` must stay in sync with any spec changes.

## Steps

### Step 1: Add `.context.md` artifact format to specs.md section 3.8 (Plan Artifacts)
- **Files:** `specs.md`
- **What:** Add a new subsection after the existing plan artifact descriptions documenting the `.context.md` format. This artifact applies to both standard and research ticket types. The format should include sections for: relevant files examined (with brief descriptions), key patterns discovered, architecture notes, and gotchas. Include a note that the file is optional -- if the planner's codebase analysis is minimal (very small ticket), it may be omitted and downstream agents fall back to normal exploration.
- **Tests first:** N/A (spec file, no automated tests)
- **Done when:** specs.md section 3.8 contains a `.context.md` template with the format described above

### Step 2: Update `/ticket-system-plan` command spec to write `.context.md`
- **Files:** `specs.md`
- **What:** In section 4.2, under `/ticket-system-plan`, add a step between Phase 2 (codebase analysis) and Phase 3 (plan generation) where the planner writes `.context.md` to `tickets/ongoing/PREFIX-XXX/` capturing the findings from Phase 2. Update the commit message in Phase 4 to include `.context.md` as part of plan artifacts. Update the `/ticket-system-run` verification step for the plan phase to optionally check for `.context.md` (but not require it -- it is optional).
- **Tests first:** N/A
- **Done when:** The plan command spec includes `.context.md` generation after Phase 2 analysis

### Step 3: Update `/ticket-system-implement` command spec to read `.context.md`
- **Files:** `specs.md`
- **What:** In section 4.2, under `/ticket-system-implement`, add a step early in the behavior (after reading config and locating the worktree, before reading the plan) that reads `.context.md` if it exists in `tickets/ongoing/<ticket-id>/`. The agent should use this context to skip redundant codebase exploration for files already documented there. If `.context.md` does not exist, proceed normally (fallback).
- **Tests first:** N/A
- **Done when:** The implement command spec includes `.context.md` reading as an early step

### Step 4: Update `/ticket-system-verify` command spec to read `.context.md`
- **Files:** `specs.md`
- **What:** In section 4.2, under `/ticket-system-verify`, add a step after locating the worktree and before reading the plan/test artifacts that reads `.context.md` if it exists. The agent uses this context to understand the codebase without re-exploring files already analyzed by the planner.
- **Tests first:** N/A
- **Done when:** The verify command spec includes `.context.md` reading as an early step

### Step 5: Update `/ticket-system-merge` command spec to read `.context.md`
- **Files:** `specs.md`
- **What:** In section 4.2, under `/ticket-system-merge`, add a step after locating the worktree that reads `.context.md` if it exists. The merge agent can use this to understand the scope of changes being merged without re-exploring.
- **Tests first:** N/A
- **Done when:** The merge command spec includes `.context.md` reading as an early step

### Step 6: Update `ticket-system-conventions` SKILL.md to document `.context.md`
- **Files:** `.claude/skills/ticket-system-conventions/SKILL.md`
- **What:** Add the `.context.md` format documentation in the Plan Artifacts section, after the existing artifact formats. Include it as a "Context Artifact (all ticket types)" subsection. Update the line count comment. Ensure the total stays under 500 lines.
- **Tests first:** N/A
- **Done when:** The conventions skill documents `.context.md` format and the line count is accurate and under 500

### Step 7: Add validation checklist items to specs.md section 8
- **Files:** `specs.md`
- **What:** Add validation items for: (1) `/ticket-system-plan` writes `.context.md` after codebase analysis, (2) `.context.md` is optional -- downstream agents fall back to normal exploration when absent, (3) `/ticket-system-implement` reads `.context.md` before starting work, (4) `/ticket-system-verify` reads `.context.md` before verification, (5) `/ticket-system-merge` reads `.context.md` before merge, (6) `.context.md` format is documented in `ticket-system-conventions`.
- **Tests first:** N/A
- **Done when:** Section 8 includes all six validation items

### Step 8: Update CLAUDE.md to reflect `.context.md` in validation references
- **Files:** `CLAUDE.md`
- **What:** Update the Deep Validation bullet list in CLAUDE.md to mention `.context.md` as a plan artifact that downstream agents read. Keep the description concise -- just enough to reflect the spec change.
- **Tests first:** N/A
- **Done when:** CLAUDE.md validation section mentions `.context.md`

## Risk Notes
- The `ticket-system-conventions` SKILL.md is at 273/500 lines. Adding the `.context.md` format template (approximately 25-30 lines) will bring it to roughly 300/500, well within limits.
- The `.context.md` must be explicitly optional to avoid breaking existing workflows where the planner might not produce it.
- Must be careful not to make `/ticket-system-run` require `.context.md` in its plan verification step, since it is optional.
