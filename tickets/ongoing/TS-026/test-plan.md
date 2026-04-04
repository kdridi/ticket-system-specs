# Test Plan — TS-026

## Strategy
Manual inspection of specs.md and CLAUDE.md after changes. Since this repository contains only specification files (no executable code), verification is done by searching for expected/unexpected patterns in the final text. Each test case below describes what to search for and what the expected outcome is.

## Test Cases

### TC-1: Schedule Phase 2 includes split proposal generation
- **Type:** integration
- **Target:** specs.md section 4.2, `/ticket-system-schedule` Phase 2
- **Input:** Search for "split proposal" or "sub-ticket" in the schedule Phase 2 description
- **Expected:** Phase 2 describes generating 2-4 sub-tickets with titles, scopes, dependency chains, complexity estimates, and rationale when a ticket is flagged as too large
- **Covers criteria:** AC-1 (split proposals for flagged tickets)

### TC-2: Phase 3 output format includes NEEDS SPLIT section
- **Type:** integration
- **Target:** specs.md section 4.2, `/ticket-system-schedule` Phase 3
- **Input:** Search for "NEEDS SPLIT" in the scheduling plan template
- **Expected:** Phase 3 template shows a "NEEDS SPLIT" section with proposed sub-tickets (titles, deps, complexity) and accept/adjust/reject prompt
- **Covers criteria:** AC-2 (unified scheduling plan includes split proposals), AC-3 (user can accept/adjust/reject)

### TC-3: Phase 4 creates sub-tickets in planned/
- **Type:** integration
- **Target:** specs.md section 4.2, `/ticket-system-schedule` Phase 4
- **Input:** Search for "planned/" and "sub-ticket" in Phase 4
- **Expected:** Phase 4 describes: creating sub-tickets directly in planned/, updating the original ticket, inserting sub-tickets into roadmap.yml with correct dependency ordering
- **Covers criteria:** AC-4 (sub-tickets created in planned/), AC-5 (dependency graph includes sub-tickets), AC-6 (original ticket updated)

### TC-4: No /ticket-system-split command spec exists
- **Type:** unit
- **Target:** specs.md section 4.2
- **Input:** Search for "#### `/ticket-system-split`" in specs.md
- **Expected:** No match found
- **Covers criteria:** AC-7 (split command removed)

### TC-5: No split row in invocation table
- **Type:** unit
- **Target:** specs.md section 2.4
- **Input:** Search for "ticket-system-split" in the disable-model-invocation table
- **Expected:** No match found in the table
- **Covers criteria:** AC-7 (split references removed)

### TC-6: Editor agent no longer references split; reader agent retained
- **Type:** unit
- **Target:** specs.md section 2.3
- **Input:** (a) Search for "ticket-system-split" in the agent profiles table. (b) Verify "ticket-system-reader" row still exists.
- **Expected:** (a) No match. (b) Reader agent row present with `/ticket-system-help` in "Used by".
- **Covers criteria:** AC-7 (split references removed), AC-8 (reader agent evaluation)

### TC-7: Pipeline overview is simplified
- **Type:** unit
- **Target:** specs.md section 4.1
- **Input:** Read section 4.1 pipeline description
- **Expected:** Pipeline reads as `create -> schedule -> plan -> implement -> verify -> merge` without a separate split step. May note that schedule handles splitting internally.
- **Covers criteria:** AC-9 (simplified pipeline)

### TC-8: File tree and validation checklist have no split skill
- **Type:** unit
- **Target:** specs.md sections 5.1 and 8
- **Input:** Search for "ticket-system-split" in sections 5.1 and 8
- **Expected:** No matches. File tree lists 9 skill directories (conventions + 8 slash commands minus split = conventions + 7 slash commands). Validation checklist does not include ticket-system-split.
- **Covers criteria:** AC-7 (split skill deleted)

### TC-9: CLAUDE.md reflects updated counts
- **Type:** unit
- **Target:** CLAUDE.md "Expected output" section
- **Input:** Read the skill directory count line
- **Expected:** "8 skill directories in `skills/` (conventions + 7 slash commands)" and 6 agent files (unchanged)
- **Covers criteria:** AC-9 (pipeline simplified)

### TC-10: Decision D-11 exists in section 6
- **Type:** unit
- **Target:** specs.md section 6
- **Input:** Search for a decision about schedule absorbing split
- **Expected:** A row in the decisions table describing that schedule absorbs split functionality
- **Covers criteria:** AC-9 (pipeline simplified, design documented)

### TC-11: disable-model-invocation is false for schedule
- **Type:** unit
- **Target:** specs.md section 2.4
- **Input:** Check the `ticket-system-schedule` row in the invocation table
- **Expected:** `disable-model-invocation: false` with a reason noting it's safe due to human gate
- **Covers criteria:** AC-10 (disable-model-invocation: false)

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: Split proposals for flagged tickets | TC-1 |
| AC-2: Unified scheduling plan includes split proposals | TC-2 |
| AC-3: User can accept/adjust/reject split proposals | TC-2 |
| AC-4: Sub-tickets created directly in planned/ | TC-3 |
| AC-5: Dependency graph includes proposed sub-tickets | TC-3 |
| AC-6: Original too-large ticket updated to reference sub-tickets | TC-3 |
| AC-7: /ticket-system-split removed from system | TC-4, TC-5, TC-6, TC-8 |
| AC-8: ticket-system-reader agent evaluation | TC-6 |
| AC-9: Pipeline fully simplified | TC-7, TC-9, TC-10 |
| AC-10: disable-model-invocation: false for schedule | TC-11 |
