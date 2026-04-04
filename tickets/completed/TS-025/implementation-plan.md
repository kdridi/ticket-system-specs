# Implementation Plan — TS-025

## Overview
Merge `/ticket-system-analyze` into `/ticket-system-schedule` so the pipeline becomes `create -> schedule -> plan -> ...`. The schedule command will accept one or more ticket IDs, perform 7-dimension complexity analysis, present a unified scheduling plan with a human gate, and then execute on approval. The analyze command, its skill, and all references to it are removed from specs.md.

## Steps

### Step 1: Rewrite `/ticket-system-schedule` command specification (section 4.2)
- **Files:** `specs.md` (section 4.2, the `/ticket-system-schedule` block, approximately lines 390-403)
- **What:** Replace the current single-ticket schedule specification with the new multi-ticket, multi-phase specification from the ticket's technical approach. The new command:
  - Accepts one or more ticket IDs OR a description (backward-compatible)
  - Phase 1: Collect tickets, recursively resolve dependencies in backlog
  - Phase 2: Evaluate each ticket (validate, relevance check, 7-dimension atomicity analysis)
  - Phase 3: Present unified scheduling plan (ready / needs attention / propose rejection) with human gate
  - Phase 4: Execute on approval (git mv, update roadmap, commit)
  - Set `disable-model-invocation: false` (safe due to human gate)
- **Tests first:** N/A (specs-only repo, no executable tests)
- **Done when:** The `/ticket-system-schedule` section in specs.md contains the full 4-phase behavior specification

### Step 2: Remove `/ticket-system-analyze` command specification (section 4.2)
- **Files:** `specs.md` (section 4.2, the `/ticket-system-analyze` block, approximately lines 405-421)
- **What:** Delete the entire `/ticket-system-analyze` section. Its 7-dimension analysis logic is now part of schedule's Phase 2.
- **Tests first:** N/A
- **Done when:** No `/ticket-system-analyze` section exists in section 4.2

### Step 3: Update pipeline overview (section 4.1)
- **Files:** `specs.md` (section 4.1, approximately line 368)
- **What:** Change the pipeline description from `create -> schedule -> analyze (-> split) -> plan ...` to `create -> schedule (-> split) -> plan ...`. Remove the mention of analyze from the overview text.
- **Tests first:** N/A
- **Done when:** Section 4.1 accurately describes the new pipeline without analyze

### Step 4: Update agent profiles table (section 2.3)
- **Files:** `specs.md` (section 2.3, approximately lines 104-111)
- **What:** In the agent table:
  - Remove `/ticket-system-analyze` from the `ticket-system-reader` "Used by" column (leaving only `/ticket-system-help`)
  - Update `/ticket-system-schedule` description in `ticket-system-editor` row if needed
- **Tests first:** N/A
- **Done when:** Agent table no longer references analyze

### Step 5: Update auto-invocation table (section 2.4)
- **Files:** `specs.md` (section 2.4, approximately lines 117-129)
- **What:** Remove the `ticket-system-analyze` row from the table entirely.
- **Tests first:** N/A
- **Done when:** Auto-invocation table has no analyze entry

### Step 6: Update file tree (section 5.1)
- **Files:** `specs.md` (section 5.1, approximately lines 567-602)
- **What:** Remove `ticket-system-analyze/` and its `SKILL.md` from the generated file tree.
- **Tests first:** N/A
- **Done when:** File tree shows 9 skill directories (conventions + 8 commands) instead of 10

### Step 7: Update decisions table (section 6)
- **Files:** `specs.md` (section 6, approximately line 723)
- **What:** Remove or rewrite D-7 ("ticket-system-analyze always targets the first ticket on the roadmap"). This decision is obsolete since analyze no longer exists. Replace with a decision about schedule accepting multiple ticket IDs.
- **Tests first:** N/A
- **Done when:** D-7 no longer references analyze

### Step 8: Update future extensions (section 7)
- **Files:** `specs.md` (section 7, approximately lines 730-740)
- **What:**
  - Remove the `/ticket-system-schedule-batch` bullet (schedule now natively supports batch)
  - Remove or update the "Dedicated ticket-analyzer agent" bullet (analysis is now embedded in schedule)
- **Tests first:** N/A
- **Done when:** Section 7 has no references to analyze or batch-schedule (since batch is now built-in)

### Step 9: Update validation checklist (section 8)
- **Files:** `specs.md` (section 8, approximately lines 744-811)
- **What:**
  - Remove `ticket-system-analyze/` from the skills checklist
  - Update count references if any (e.g., "10 skill directories" -> "9 skill directories")
- **Tests first:** N/A
- **Done when:** Validation checklist no longer mentions analyze

### Step 10: Update CLAUDE.md
- **Files:** `CLAUDE.md` (expected output section and any command counts)
- **What:** Update references from "10 skill directories" to "9 skill directories" and from "9 slash commands" to "8 slash commands". Adjust any pipeline descriptions if present.
- **Tests first:** N/A
- **Done when:** CLAUDE.md is consistent with the updated specs.md

### Step 11: Update `/ticket-system-merge` suggestion text (section 4.2)
- **Files:** `specs.md` (section 4.2, merge command, approximately line 546)
- **What:** The merge command currently says "Suggest running `/ticket-system-analyze` to evaluate the next ticket." Change this to suggest running `/ticket-system-plan` (or simply suggest checking the roadmap for the next ticket).
- **Tests first:** N/A
- **Done when:** Merge command no longer references analyze

### Step 12: Update `/ticket-system-help` behavior (section 4.2)
- **Files:** `specs.md` (section 4.2, help command, approximately lines 559-560)
- **What:** The help command lists "analyze" as a known verb. Update the list of known verbs to remove "analyze".
- **Tests first:** N/A
- **Done when:** Help command verb list does not include analyze

## Risk Notes
- **Cross-reference drift:** Many sections reference analyze. A systematic search for "analyze" across the entire specs.md is essential before declaring done. Grep for "analyze", "ticket-system-analyze", and "ticket-system-reader.*analyze" to catch all references.
- **Reader agent may become under-utilized:** After this change, the reader agent is only used by `/ticket-system-help`. This is fine — it still serves a purpose and can be extended later.
- **D-7 rewrite sensitivity:** The decisions table is explicitly marked "do not revisit." However, D-7 references a command that no longer exists, so it must be updated to remain accurate. The decision itself (analyze targets first roadmap ticket) is now embedded in schedule's behavior.
- **TS-018 and TS-024 in backlog:** TS-018 (optional ticket-id on analyze) becomes obsolete after this change. TS-024 (the original unsplit ticket) is already in backlog as rejected/superseded. These should be noted but not modified in this ticket — that is a separate cleanup concern.
