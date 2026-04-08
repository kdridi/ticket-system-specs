# Implementation Plan — TS-033

## Overview
Remove all `AskUserQuestion` human gates and `--yes` bypass logic from `/ticket-system-schedule`, `/ticket-system-plan`, `/ticket-system-run`, and `/ticket-system-run-all`. Replace with deterministic stop-on-conflict behavior in schedule and plan. Update all cross-references in decisions, validation checklist, CLAUDE.md, and the section 2.3/2.4 tables. Preserve the `/ticket-system-abort` confirmation gate unchanged.

## Steps

### Step 1: Update Section 4.1 — Pipeline Overview (specs.md line 483)
- **Files:** specs.md
- **What:** Remove `[HUMAN APPROVAL]` markers from the pipeline description. Remove the sentence about `AskUserQuestion` and `--yes` bypass. Replace with a note about stop-on-conflict behavior for schedule and plan.
- **Tests first:** N/A (spec file, not code)
- **Done when:** Line 483 no longer contains `[HUMAN APPROVAL]`, `AskUserQuestion`, or `--yes` bypass language. The pipeline reads: `create → schedule → plan → implement → verify → merge`.

### Step 2: Update Section 4.2 — `/ticket-system-schedule` (specs.md lines 546-552)
- **Files:** specs.md
- **What:** Remove Phase 3 "Human gate" entirely (lines 546-552). Rename Phase 4 to Phase 3. Remove all `--yes`/`yes` references. In the evaluation phase (Phase 2), add conflict-detection: if problems are found (needs split, missing fields, dependency issues), the command stops with a structured message listing problems and directing the user to `/ticket-system-edit`. On clean pass, proceed directly to execution. The split proposal flow changes: if a ticket needs splitting, the command stops and tells the user to split manually (create sub-tickets via `/ticket-system-create`, reject the parent, then schedule the sub-tickets).
- **Tests first:** N/A
- **Done when:** `/ticket-system-schedule` has no `AskUserQuestion`, no `--yes`/`yes` references, no self-evaluation loop. Has stop-on-conflict behavior. Split proposals stop with instructions rather than interactive acceptance.

### Step 3: Update Section 4.2 — `/ticket-system-plan` (specs.md lines 615-625)
- **Files:** specs.md
- **What:** Remove Phase 4 "Human gate" entirely (lines 615-625). Remove all `--yes`/`yes` references. Add conflict-detection to plan generation: if the plan cannot be built cleanly (empty objective, < 2 acceptance criteria, unmappable scope, unresolved dependencies), stop with a structured message directing to `/ticket-system-edit`. On success, commit plan artifacts and end. Remove the "Do not return to the main agent" paragraph since there is no longer a review loop.
- **Tests first:** N/A
- **Done when:** `/ticket-system-plan` has no `AskUserQuestion`, no `--yes`/`yes` references, no self-evaluation loop. Has stop-on-conflict behavior.

### Step 4: Update Section 4.2 — `/ticket-system-run` (specs.md lines 728-752)
- **Files:** specs.md
- **What:** Remove `--yes` forwarding logic from step 2 (line 736) and step 3 (line 737). Remove the "Note on human gates" paragraph (line 752). Simplify: it just chains the four sub-skills without any human-gate-related logic. Update the argument description to remove `--yes` option.
- **Tests first:** N/A
- **Done when:** `/ticket-system-run` has no `--yes` references, no "human gate" notes.

### Step 5: Update Section 4.2 — `/ticket-system-run-all` (specs.md lines 754-772)
- **Files:** specs.md
- **What:** Remove `--yes` from the argument description (line 756). Remove `--yes` forwarding logic from steps 5 and 6 (lines 765, 768). Remove the "Note on human gates" paragraph (line 772).
- **Tests first:** N/A
- **Done when:** `/ticket-system-run-all` has no `--yes` references, no "human gate" notes. Argument line reads just "none (reads from roadmap)".

### Step 6: Update Section 2.3 — AskUserQuestion note (specs.md line 133)
- **Files:** specs.md
- **What:** Rewrite the `AskUserQuestion` note. Since it is now only used by `/ticket-system-abort`, update the text to say: "It is used by the confirmation gate in `/ticket-system-abort` to keep the approval loop inside the forked agent context." Remove the reference to schedule and plan human gates.
- **Tests first:** N/A
- **Done when:** The AskUserQuestion note references only abort, not schedule/plan.

### Step 7: Update Section 2.4 — Auto-invocation table (specs.md lines 139-152)
- **Files:** specs.md
- **What:** Update the Reason column for `/ticket-system-schedule` (remove "human gate" reference), `/ticket-system-plan` (remove "human gate" reference), `/ticket-system-run` (remove "plan has its own human gate"), `/ticket-system-run-all` (remove "plan has its own human gate"). Replace with accurate reasons (e.g., "Low risk — validates and moves tickets", "Safe — generates plans in worktree", "Chains safe-to-chain skills", "Chains safe-to-chain skills").
- **Tests first:** N/A
- **Done when:** No table entry references "human gate".

### Step 8: Update Section 4.2 — `/ticket-system-help` (specs.md line 833)
- **Files:** specs.md
- **What:** Remove the `--yes` bypass mention from the help command's documentation behavior: "options (e.g., `--yes` bypass)" should become just "options" or be removed if there are no notable options for most commands.
- **Tests first:** N/A
- **Done when:** `/ticket-system-help` spec does not mention `--yes`.

### Step 9: Update Section 6 — Decisions D-2, D-7, D-11, D-12 (specs.md lines 1048-1058)
- **Files:** specs.md
- **What:**
  - **D-2:** Rewrite from "Human validation at schedule and plan stages" to "Schedule and plan use stop-on-conflict instead of interactive gates. Clean operations proceed silently; conflicts stop with a message directing to /ticket-system-edit."
  - **D-7:** Remove "with human gate" from the rationale text.
  - **D-11:** Remove "all behind the existing human gate" from the rationale text.
  - **D-12:** Rewrite entirely. The decision is now about AskUserQuestion being used only for abort's confirmation gate. Update the rationale to explain why destructive actions still need confirmation but plan/schedule do not.
- **Tests first:** N/A
- **Done when:** D-2 describes stop-on-conflict. D-7 and D-11 have no human-gate references. D-12 describes abort-only AskUserQuestion.

### Step 10: Update Section 8 — Validation Checklist (specs.md lines 1133-1164)
- **Files:** specs.md
- **What:**
  - Remove line 1133: schedule human gate checklist item.
  - Remove line 1140: plan human gate checklist item.
  - Remove line 1158: run forwards `--yes` checklist item.
  - Remove line 1164: run-all forwards `--yes` checklist item.
  - Add new checklist items: `/ticket-system-schedule` stops on conflict with structured message directing to `/ticket-system-edit`. `/ticket-system-plan` stops on conflict with structured message directing to `/ticket-system-edit`.
  - Keep line 1152 (abort AskUserQuestion) unchanged.
- **Tests first:** N/A
- **Done when:** Checklist has no schedule/plan human-gate items, no `--yes` forwarding items. Has stop-on-conflict items for schedule and plan. Abort confirmation gate item is preserved.

### Step 11: Update CLAUDE.md — Deep Validation bullet and Key Design Decisions
- **Files:** CLAUDE.md
- **What:**
  - Update the Deep Validation bullet (line 91) to replace "AskUserQuestion human gates in schedule and plan forks with self-evaluation and --yes bypass" with "stop-on-conflict behavior in schedule and plan (stops with structured message directing to /ticket-system-edit)".
  - Update Key Design Decisions bullet (line 110) from "Human approval gates at /ticket-system-schedule and /ticket-system-plan stages, using AskUserQuestion..." to "Schedule and plan use stop-on-conflict — clean operations proceed silently, conflicts stop with a message directing to /ticket-system-edit. No interactive gates or --yes bypass."
- **Tests first:** N/A
- **Done when:** CLAUDE.md has no references to human gates or `--yes` bypass for schedule/plan. References to abort's confirmation gate (if any) are preserved.

## Risk Notes
- The split proposal flow in schedule needs careful rethinking. Currently splits are proposed during the human gate. With stop-on-conflict, if a ticket needs splitting, the command should stop and tell the user to split manually. This changes the schedule Phase 2/3/4 flow significantly.
- The "Do not return to the main agent" instruction in schedule and plan exists because of the approval loop. Without the loop, this instruction may still be needed for execution but the rationale changes.
- Section 2.3 AskUserQuestion note currently justifies not listing it in Allowed Tools by referencing schedule/plan usage. With only abort using it, the note should still exist but needs rewording.
