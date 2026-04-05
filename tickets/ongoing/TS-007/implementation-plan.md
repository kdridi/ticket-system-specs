# Implementation Plan -- TS-007

## Overview
Document the 500-line budget for `ticket-system-conventions` in specs.md, define a split strategy for when the limit is approached, add a generation rule for a line-count comment at the top of the conventions skill, and add a validate.sh check for the line limit.

## Steps

### Step 1: Add conventions skill budget decision to specs.md section 6
- **Files:** `specs.md` (section 6, Decisions table)
- **What:** Add a new decision entry (D-13) documenting the 500-line hard limit for `ticket-system-conventions`, the rationale (context efficiency), and the split strategy: when nearing the limit, extract "heavy" reference sections (plan artifact formats, test plan formats) into a `ticket-system-conventions-extended` skill that is only loaded by agents that need those formats (planner, verifier).
- **Tests first:** N/A (documentation change)
- **Done when:** D-13 row exists in the decisions table with budget, threshold, and split strategy described.

### Step 2: Add generation rule for line-count comment in specs.md section 5
- **Files:** `specs.md` (section 5.2 or 5.5, under the conventions skill generation rules)
- **What:** Add a generation rule stating that the generated `ticket-system-conventions` SKILL.md must include a `<!-- Lines: N/500 -->` comment on the first line after frontmatter (before any markdown heading). N is the total line count of the file. This gives generators and reviewers immediate visibility into how close the skill is to its limit.
- **Tests first:** N/A (spec change)
- **Done when:** The generation rule is documented in section 5, near the existing conventions skill requirements (around line 793-795).

### Step 3: Define the split strategy details in specs.md section 6
- **Files:** `specs.md` (section 6, as part of D-13 or adjacent prose)
- **What:** Specify which sections are candidates for extraction:
  - **Extractable (heavy, reference-only):** Plan artifact formats (implementation-plan.md and test-plan.md templates), coverage map format. These are only needed by the planner and verifier agents.
  - **Must stay (core, used by all agents):** Config, directory structure, ticket format, roadmap format, lifecycle, ID assignment, commit convention, worktree convention, tool usage rules.
  - **Trigger:** When the conventions skill exceeds 400 lines (80% of budget), the split should be performed. The new skill (`ticket-system-conventions-extended`) gets `user-invocable: false` and is added to the `skills` list of only the planner and verifier agents.
- **Tests first:** N/A (documentation)
- **Done when:** The split strategy clearly identifies extractable sections, the trigger threshold, and the new skill's configuration.

### Step 4: Add validate.sh check for conventions skill line count
- **Files:** `validate.sh`
- **What:** Add a check near the existing frontmatter/permissions section that counts the lines of `skills/ticket-system-conventions/SKILL.md` and fails if it exceeds 500 lines. Also check that the `<!-- Lines: N/500 -->` comment is present and that N matches the actual line count.
- **Tests first:** N/A (this is a validation script, not application code)
- **Done when:** Running `validate.sh` against a generated output reports PASS for a conventions skill under 500 lines with correct line-count comment, and FAIL for one that exceeds 500 lines or has a mismatched/missing comment.

### Step 5: Add validate.sh check to specs.md section 8 (validation checklist)
- **Files:** `specs.md` (section 8)
- **What:** Add two new checklist items:
  - `[ ] ticket-system-conventions SKILL.md does not exceed 500 lines`
  - `[ ] ticket-system-conventions SKILL.md has a <!-- Lines: N/500 --> comment with correct count`
- **Tests first:** N/A
- **Done when:** Section 8 includes these checklist items.

### Step 6: Update CLAUDE.md constraints section
- **Files:** `CLAUDE.md`
- **What:** Add a note under the existing "500 lines" constraint bullet explaining the split strategy: when nearing the limit, plan artifact formats can be extracted into `ticket-system-conventions-extended`. Reference specs.md section 6 D-13 for details.
- **Tests first:** N/A
- **Done when:** CLAUDE.md Constraints section documents the split strategy succinctly.

## Risk Notes
- The `<!-- Lines: N/500 -->` comment requires the generator to count lines at generation time. This is straightforward but adds a post-generation consistency check (the count must be accurate). The validate.sh check will catch mismatches.
- The 400-line trigger threshold is a guideline, not enforced by tooling. Only the 500-line hard limit is checked by validate.sh.
- The split has not been tested end-to-end since the conventions skill is currently well under the limit. The strategy is documented for future use only.
