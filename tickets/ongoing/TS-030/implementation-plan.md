# Implementation Plan — TS-030

## Overview
Add a new `/ticket-system-edit` slash command that allows modifying existing tickets in `backlog/` or `planned/` status. The command accepts a ticket ID and free-form modification instructions, applies changes while preserving metadata and log history, and commits the result. It uses the existing `ticket-system-editor` agent via `context: fork`.

## Steps

### Step 1: Add /ticket-system-edit to specs.md — Command Pipeline section
- **Files:** `specs.md`
- **What:** Add a new `/ticket-system-edit` command specification in section 4.2 (Detailed Command Specifications), after `/ticket-system-schedule`. Define the agent (`ticket-system-editor`), auto-invocation setting, argument format, and full behavior description including: reading config, locating the ticket in backlog or planned, rejecting ongoing/completed/rejected tickets, applying modifications, preserving metadata, updating timestamps, appending log entries, updating roadmap.yml if title/priority changes for planned tickets, and committing.
- **Tests first:** N/A (spec file)
- **Done when:** The command specification exists in specs.md section 4.2 with complete behavior description.

### Step 2: Update cross-references in specs.md and CLAUDE.md
- **Files:** `specs.md`, `CLAUDE.md`
- **What:** Update the agent table in section 2.3 to include `/ticket-system-edit` in the `ticket-system-editor` "Used by" column. Update the file tree in section 5.1 to include `ticket-system-edit/` skill directory. Update the structural completeness checklist in section 8 to include the new skill. Update CLAUDE.md expected output count from "13 skill directories (conventions + 12 slash commands)" to "14 skill directories (conventions + 13 slash commands)".
- **Tests first:** N/A (spec file)
- **Done when:** All cross-references in specs.md and CLAUDE.md reflect the new command.

### Step 3: Create the skill SKILL.md file
- **Files:** `.claude/skills/ticket-system-edit/SKILL.md`
- **What:** Create the skill file with proper frontmatter (`name: ticket-system-edit`, `description` under 250 chars, `disable-model-invocation: false`, `context: fork`, `agent: ticket-system-editor`, `argument-hint: "[ticket-id] [modification instructions]"`). The body describes the full behavior: read config, locate ticket in backlog/ or planned/, reject if in ongoing/completed/rejected, read current content, apply requested modifications, preserve id/created/log history, update `updated` timestamp via `date`, append log entry describing changes, write modified file, update roadmap.yml if title or priority changed for a planned ticket, commit with message format `PREFIX-XXX: Edit ticket — <brief summary>`.
- **Tests first:** N/A (skill definition)
- **Done when:** `.claude/skills/ticket-system-edit/SKILL.md` exists with correct frontmatter and complete behavior specification.

