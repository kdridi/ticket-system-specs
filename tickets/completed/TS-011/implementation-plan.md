# Implementation Plan — TS-011

## Overview
Replace every reference to the markdown-table-based `roadmap.md` with a YAML-based `roadmap.yml` throughout `specs.md`. This touches section 3.2 (directory tree), section 3.4 (roadmap format definition), section 3.5 (lifecycle), section 4.2 (commands: schedule, analyze, plan), section 5.4 (init-project.sh), and section 5.5/conventions references. After updating `specs.md`, update `CLAUDE.md` if any guidance references the roadmap format.

## Steps

### Step 1: Update section 3.2 — Directory Structure
- **Files:** `specs.md` (line ~198)
- **What:** Change the tree listing from `roadmap.md` to `roadmap.yml` and update the comment from "Authoritative execution order" to reflect YAML format.
- **Tests first:** N/A (spec file, not executable code). Verification is textual — grep for `roadmap.md` in the tree block should return zero hits after this step.
- **Done when:** The directory tree in section 3.2 shows `roadmap.yml` instead of `roadmap.md`.

### Step 2: Rewrite section 3.4 — Roadmap Format
- **Files:** `specs.md` (lines ~258-270)
- **What:** Replace the entire section 3.4 content. Change the filename from `tickets/planned/roadmap.md` to `tickets/planned/roadmap.yml`. Replace the markdown table example with the YAML format from the ticket's Technical Approach. Add explicit insertion ordering rules: (1) respect dependency ordering (a ticket must come after all its dependencies), (2) within the same dependency tier, sort by priority P0 > P1 > P2. Describe how "removing a ticket" works in YAML (remove the list entry, re-number positions).
- **Tests first:** N/A. Verification: section 3.4 contains a YAML code block, no markdown table pipes outside of other sections.
- **Done when:** Section 3.4 fully describes the YAML roadmap format with insertion ordering logic.

### Step 3: Update section 3.5 — Lifecycle
- **Files:** `specs.md` (line ~281)
- **What:** Change the "Schedule" bullet from `insert into roadmap.md` to `insert into roadmap.yml`.
- **Tests first:** N/A.
- **Done when:** The lifecycle description references `roadmap.yml`.

### Step 4: Update section 4.2 — `/ticket-system-schedule` command
- **Files:** `specs.md` (line ~386)
- **What:** Change step 7 from `Read roadmap.md, insert the ticket at the correct position` to `Read roadmap.yml, insert the ticket at the correct position`. The insertion logic description stays the same (dependency ordering, then priority sort).
- **Tests first:** N/A.
- **Done when:** The schedule command references `roadmap.yml`.

### Step 5: Update section 4.2 — `/ticket-system-analyze` command
- **Files:** `specs.md` (lines ~392, ~396)
- **What:** Change the argument description from `always picks the first ticket from roadmap.md` to `always picks the first ticket from roadmap.yml`. Change step 2 from `Read roadmap.md` to `Read roadmap.yml`.
- **Tests first:** N/A.
- **Done when:** The analyze command references `roadmap.yml`.

### Step 6: Update section 4.2 — `/ticket-system-plan` command
- **Files:** `specs.md` (line ~438)
- **What:** Change step 7 from `Remove its row from roadmap.md` to `Remove its entry from roadmap.yml`.
- **Tests first:** N/A.
- **Done when:** The plan command references `roadmap.yml`.

### Step 7: Update section 5.4 — `init-project.sh`
- **Files:** `specs.md` (line ~648)
- **What:** Change step 6 from `Create tickets/planned/roadmap.md with an empty table header` to `Create tickets/planned/roadmap.yml with tickets: []` (an empty YAML list).
- **Tests first:** N/A.
- **Done when:** The init-project script description references `roadmap.yml` with YAML content.

### Step 8: Final sweep — verify no remaining `roadmap.md` references
- **Files:** `specs.md` (entire file)
- **What:** Grep for any remaining `roadmap.md` references. Fix any that were missed. Also verify that generic "roadmap" references (without file extension) still make contextual sense.
- **Tests first:** N/A.
- **Done when:** `grep -c 'roadmap\.md' specs.md` returns 0.

### Step 9: Sync CLAUDE.md
- **Files:** `CLAUDE.md`
- **What:** Review `CLAUDE.md` for any references to the roadmap format. Currently there are none (confirmed by grep), so this step is likely a no-op. If any are found, update them.
- **Tests first:** N/A.
- **Done when:** `CLAUDE.md` is consistent with the updated `specs.md`.

## Risk Notes
- This is a pure spec refactoring — no executable code changes. The risk is low.
- The main concern is missing a `roadmap.md` reference somewhere in the spec, which Step 8 (final sweep) addresses.
- The convention skill content is defined by the spec generation process, not directly edited here. The acceptance criterion about updating the conventions skill is satisfied by updating section 3.4 (and the generation rule in 5.2 line 605 that references "roadmap format"), since the conventions skill is generated from the spec.
- The `CLAUDE.md` rule says "Only modify CLAUDE.md and specs.md" — this ticket only modifies those two files, which is correct for this repository.
