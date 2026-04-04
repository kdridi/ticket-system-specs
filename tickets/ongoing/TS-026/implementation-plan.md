# Implementation Plan — TS-026

## Overview
Absorb the `/ticket-system-split` command into `/ticket-system-schedule` so that schedule handles the full lifecycle from evaluation through split proposals. Remove `/ticket-system-split` as a standalone command. Evaluate and retain the `ticket-system-reader` agent (still used by `/ticket-system-help`). Update CLAUDE.md to reflect the simplified pipeline and reduced skill count.

## Steps

### Step 1: Enhance `/ticket-system-schedule` with split proposal generation (Phase 2)
- **Files:** `specs.md` (section 4.2, `/ticket-system-schedule` Phase 2)
- **What:** Extend the existing atomicity analysis (step 4 under Phase 2) so that tickets flagged as "needs attention" (any High dimension, >3 criteria across concerns, >5 files) now get a split proposal with 2-4 sub-tickets. Each sub-ticket includes title, scope derived from acceptance criteria, dependency chain, individual complexity estimate (small or medium), and rationale for the split boundary. Sub-tickets inherit parent priority and type.
- **Tests first:** TC-1 (spec contains split proposal generation in schedule Phase 2)
- **Done when:** Phase 2 step 4 describes generating split proposals for flagged tickets instead of just reporting them.

### Step 2: Update Phase 3 presentation to include "NEEDS SPLIT" section
- **Files:** `specs.md` (section 4.2, `/ticket-system-schedule` Phase 3)
- **What:** Replace the "NEEDS ATTENTION" section in the scheduling plan with "NEEDS SPLIT" that displays proposed sub-tickets with titles, scopes, deps, and an accept/adjust/reject prompt. The user can accept the split, adjust it, or reject it (keeping the original ticket as-is).
- **Tests first:** TC-2 (Phase 3 output format includes NEEDS SPLIT with sub-ticket details)
- **Done when:** Phase 3 template shows the new format with sub-ticket proposals.

### Step 3: Add split execution to Phase 4
- **Files:** `specs.md` (section 4.2, `/ticket-system-schedule` Phase 4)
- **What:** When the user approves a split: (a) assign sequential IDs to sub-tickets, (b) create them directly in `planned/` (not backlog -- they've already been evaluated), (c) update the original ticket to reference its sub-tickets and move it to `rejected/` with a log entry explaining the split, (d) include sub-tickets in roadmap.yml with correct dependency ordering. The user can also reject the split (original ticket schedules normally) or adjust (modify proposals before executing).
- **Tests first:** TC-3 (Phase 4 describes creating sub-tickets in planned/, updating original, inserting into roadmap)
- **Done when:** Phase 4 includes the complete split execution flow alongside existing schedule execution.

### Step 4: Remove `/ticket-system-split` command specification
- **Files:** `specs.md` (section 4.2, lines around the `/ticket-system-split` block)
- **What:** Delete the entire `/ticket-system-split` command specification (section 4.2, the block starting with `#### /ticket-system-split`).
- **Tests first:** TC-4 (no `/ticket-system-split` command spec exists in section 4.2)
- **Done when:** Section 4.2 no longer contains a `/ticket-system-split` entry.

### Step 5: Remove `/ticket-system-split` from section 2.4 (invocation table)
- **Files:** `specs.md` (section 2.4)
- **What:** Remove the `ticket-system-split` row from the disable-model-invocation table. Update the `ticket-system-schedule` row's reason to mention it now handles splits (safe -- human gate before any mutation including splits).
- **Tests first:** TC-5 (no split row in section 2.4 table)
- **Done when:** The invocation table has no split entry.

### Step 6: Update section 2.3 (Agent Profiles) — remove split from editor's "Used by"
- **Files:** `specs.md` (section 2.3)
- **What:** Remove `/ticket-system-split` from the `ticket-system-editor` agent's "Used by" column. The editor is still used by `/ticket-system-create` and `/ticket-system-schedule`. Keep `ticket-system-reader` as-is (still used by `/ticket-system-help`).
- **Tests first:** TC-6 (editor "Used by" does not reference split; reader still present)
- **Done when:** Agent table no longer references `/ticket-system-split` anywhere.

### Step 7: Update section 4.1 (Pipeline Overview)
- **Files:** `specs.md` (section 4.1)
- **What:** Simplify the pipeline description from `create -> schedule (-> split if too large) -> plan -> ...` to `create -> schedule -> plan -> implement -> verify -> merge`. Note that schedule now handles splitting internally when tickets are too large.
- **Tests first:** TC-7 (pipeline overview shows simplified flow without separate split step)
- **Done when:** Section 4.1 describes the simplified pipeline.

### Step 8: Remove `/ticket-system-split` from section 5.1 (File Tree) and section 8 (Validation)
- **Files:** `specs.md` (sections 5.1 and 8)
- **What:** Remove `ticket-system-split/` from the file tree listing and from the structural completeness checklist. Update the total skill count (from 10 directories to 9, from 9 skills/SKILL.md to 8).
- **Tests first:** TC-8 (no ticket-system-split in file tree or validation checklist)
- **Done when:** Sections 5.1 and 8 no longer reference ticket-system-split.

### Step 9: Sync CLAUDE.md with specs.md changes
- **Files:** `CLAUDE.md`
- **What:** Update the "Expected output" section to reflect the new counts: still 6 agent files but now 8 skill directories (conventions + 7 slash commands). Update any pipeline references if present.
- **Tests first:** TC-9 (CLAUDE.md reflects correct counts and simplified pipeline)
- **Done when:** CLAUDE.md accurately describes the generated output after the split removal.

### Step 10: Add decision D-11 to section 6 (Decisions Already Made)
- **Files:** `specs.md` (section 6)
- **What:** Add a new decision entry documenting that `/ticket-system-schedule` absorbs split functionality, eliminating `/ticket-system-split` as a standalone command. Reference that this simplifies the pipeline to 6 commands and keeps the human gate in schedule for split approvals.
- **Tests first:** TC-10 (section 6 contains a decision about schedule absorbing split)
- **Done when:** A new decision row exists in the table.

## Risk Notes
- The schedule command's Phase 2/3/4 sections become significantly longer. Need to ensure the spec remains clear and well-structured without becoming bloated.
- The `ticket-system-reader` agent is retained because `/ticket-system-help` still uses it. If a future ticket removes `/ticket-system-help` or changes its agent, the reader could be removed then.
- Removing `/ticket-system-split` from the editor's "Used by" is straightforward since the split logic is now part of schedule (which already uses the editor).
- The `ticket-system-conventions` skill (500-line limit) does not need changes -- the pipeline description there is minimal and the split command is not referenced.
