# Implementation Plan — TS-015

## Overview
Add a "Configuration Variables" section (section 0) to the top of `specs.md` that defines parameterizable values (model names, retry counts) used throughout the spec. Replace all hardcoded model name references in section 2.3 with variable references. Update the generation preamble to instruct Claude Code to resolve variables before generating files.

## Steps

### Step 1: Add section 0 "Configuration Variables" to specs.md
- **Files:** `specs.md`
- **What:** Insert a new section between the preamble (blockquote ending at line 6) and the Table of Contents (line 8). The section defines a table of variables: `WEAK_MODEL` (default: haiku), `MID_MODEL` (default: sonnet), `STRONG_MODEL` (default: opus), `MAX_RETRY` (default: 3). Include a clear note that this is the only section users should customize before generation.
- **Tests first:** N/A (spec file, not code)
- **Done when:** Section 0 exists with all four variables in a properly formatted table, positioned before the Table of Contents.

### Step 2: Update Table of Contents to include section 0
- **Files:** `specs.md`
- **What:** Add a ToC entry for section 0 at the top of the Table of Contents list, before the section 1 entry.
- **Tests first:** N/A
- **Done when:** ToC includes a link to section 0.

### Step 3: Replace hardcoded model names in section 2.3 agent profiles table
- **Files:** `specs.md`
- **What:** In the agent profiles table (lines 106-111), replace:
  - `haiku` with `$WEAK_MODEL` (reader agent, line 106)
  - `sonnet` with `$MID_MODEL` (editor, verifier, ops agents — lines 107, 110, 111)
  - `opus` with `$STRONG_MODEL` (planner, coder agents — lines 108, 109)
- **Tests first:** N/A
- **Done when:** No literal model names remain in the Model column of the table. All use `$VARIABLE` syntax.

### Step 4: Update generation preamble to include variable resolution instruction
- **Files:** `specs.md`
- **What:** Add a sentence to the existing "Instruction for Claude Code" blockquote (line 5-6): "Before generating any files, resolve all `$VARIABLE` references (e.g., `$WEAK_MODEL`, `$MID_MODEL`, `$STRONG_MODEL`, `$MAX_RETRY`) using the defaults from section 0."
- **Tests first:** N/A
- **Done when:** The preamble includes the variable resolution instruction.

### Step 5: Update CLAUDE.md to reflect section 0
- **Files:** `CLAUDE.md`
- **What:** Since the project rules state "Keep CLAUDE.md in sync with specs.md", update the "Preserve the 8-section structure" bullet to mention section 0 and note that users can customize variables in section 0. Update the section structure reference from "8-section" to "9-section" (sections 0-8).
- **Tests first:** N/A
- **Done when:** CLAUDE.md mentions the configuration variables section and the updated section count.

### Step 6: Update ticket with files modified and decisions
- **Files:** `tickets/ongoing/TS-015/ticket.md`
- **What:** Fill in the Files Modified and Decisions sections. Add a log entry.
- **Tests first:** N/A
- **Done when:** Ticket metadata is up to date.

## Risk Notes
- The `$VARIABLE` syntax in the spec could potentially be confused with shell variable expansion if someone copies the table into a shell context. This is mitigated by the fact that specs.md is a generation prompt, not a shell script. The variables are resolved by Claude Code at generation time, not by bash.
- Need to verify that no other sections reference model names by their literal values (haiku/sonnet/opus). The grep in Phase 2 confirmed they only appear in section 2.3's table.
- MAX_RETRY is defined here but not yet used anywhere in the spec (TS-017 will add the usage). This is intentional — define the variable now, use it later.
