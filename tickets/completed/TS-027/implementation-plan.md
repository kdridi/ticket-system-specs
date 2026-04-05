# Implementation Plan — TS-027

## Overview
Add a new `/ticket-system-doctor` diagnostic skill to specs.md. This is a read-only command that checks the ticket system for consistency issues (status/directory mismatches, orphaned worktrees, stale roadmap entries, multiple tickets in ongoing) and reports findings with suggested fix commands. It uses the `ticket-system-reader` agent (plan permission mode) and is safe for auto-invocation.

## Steps

### Step 1: Add `/ticket-system-doctor` to section 2.3 (Agent Profiles table)
- **Files:** `specs.md` (line ~106, the agent profiles table)
- **What:** Add `/ticket-system-doctor` to the "Used by" column of the `ticket-system-reader` row, changing `'/ticket-system-help'` to `'/ticket-system-help', '/ticket-system-doctor'`.
- **Tests first:** N/A (spec file, not code)
- **Done when:** The reader agent table row lists both `/ticket-system-help` and `/ticket-system-doctor`.

### Step 2: Add `/ticket-system-doctor` to section 2.4 (Automatic vs Manual Invocation table)
- **Files:** `specs.md` (line ~119, the invocation table)
- **What:** Add a new row for `ticket-system-doctor` with `disable-model-invocation: false` and reason "Read-only diagnostics, zero risk".
- **Tests first:** N/A
- **Done when:** The invocation table includes a `ticket-system-doctor` entry with `false`.

### Step 3: Add the `/ticket-system-doctor` command specification to section 4.2
- **Files:** `specs.md` (after the `/ticket-system-help` block, before section 5)
- **What:** Add a new `#### /ticket-system-doctor` subsection with:
  - Agent: `ticket-system-reader`, Auto-invocation: yes, Argument: none
  - Behavior: 6-step diagnostic checklist (read config, scan status mismatches, check orphaned worktrees, validate roadmap entries, check ongoing count, report structured results)
  - Output format: structured checklist with `[OK]` / `[ISSUE]` prefixes
  - Each issue includes a description and a suggested fix command
  - Explicit note: does NOT auto-fix
- **Tests first:** N/A
- **Done when:** Section 4.2 contains the full doctor command specification.

### Step 4: Add `ticket-system-doctor/` to section 5.1 (File Tree to Generate)
- **Files:** `specs.md` (line ~623, skills list in file tree)
- **What:** Add `ticket-system-doctor/` with `SKILL.md` to the skills directory listing.
- **Tests first:** N/A
- **Done when:** The file tree lists 10 skill directories (conventions + 9 slash commands).

### Step 5: Add `/ticket-system-doctor` to section 8 (Validation Checklist)
- **Files:** `specs.md` (structural completeness and frontmatter sections)
- **What:**
  - Add `ticket-system-doctor/` to the skills checklist in structural completeness
  - Add validation items for the doctor skill: uses `ticket-system-reader` agent, `disable-model-invocation: false`, read-only (no file modifications)
- **Tests first:** N/A
- **Done when:** Section 8 includes doctor-specific validation items.

### Step 6: Update section 4.1 (Overview) to mention the doctor command
- **Files:** `specs.md` (line ~369)
- **What:** Add a mention of `/ticket-system-doctor` as a utility command alongside `/ticket-system-help`, noting it is a read-only diagnostic tool.
- **Tests first:** N/A
- **Done when:** The overview paragraph references the doctor command.

### Step 7: Update CLAUDE.md to reflect the new skill count
- **Files:** `CLAUDE.md` (line ~30)
- **What:** Change "9 skill directories" to "10 skill directories" and "conventions + 8 slash commands" to "conventions + 9 slash commands".
- **Tests first:** N/A
- **Done when:** CLAUDE.md reflects the correct count.

### Step 8: Add `/ticket-system-doctor` to the help command's recognized verbs
- **Files:** `specs.md` (section 4.2, `/ticket-system-help` specification, line ~583)
- **What:** Add "doctor" to the list of known verbs: "create, schedule, plan, implement, verify, merge, abort, doctor, help".
- **Tests first:** N/A
- **Done when:** The help command specification lists "doctor" as a recognized verb.

## Risk Notes
- The reader agent already has the right permissions (Read, Glob, Grep) plus `Bash(git worktree list)` would be needed for the orphaned worktree check. However, looking at the current reader agent tools (`Read`, `Glob`, `Grep`), it does NOT have `Bash(git worktree list)`. We need to add this to the reader agent's allowed tools in section 2.3. This should be handled in Step 1 by also adding the Bash pattern.
- The doctor skill must be careful not to introduce any write operations, staying purely diagnostic.
- Adding a new skill increases the generated file count, so install.sh and init-project.sh do not need changes (they copy all files in the directories).
