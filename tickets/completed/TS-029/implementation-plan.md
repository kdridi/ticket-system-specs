# Implementation Plan — TS-029

## Overview
Add a new `/ticket-system-run-all` command that reads all planned tickets from `tickets/planned/roadmap.yml` and executes them sequentially using `/ticket-system-run`, stopping on the first failure. This requires creating a new skill file, updating `specs.md` to document the command, and keeping `CLAUDE.md` in sync.

## Steps

### Step 1: Create the skill file `skills/ticket-system-run-all/SKILL.md`
- **Files:** `.claude/skills/ticket-system-run-all/SKILL.md` (new)
- **What:** Create a new skill that:
  - Uses `context: fork` with `agent: ticket-system-coder` (same as `/ticket-system-run` since it needs unrestricted Skill invocation)
  - Has `disable-model-invocation: false` (chains safe-to-chain skills; plan has its own human gate)
  - Reads `tickets/planned/roadmap.yml` and iterates tickets in position order
  - For each ticket, invokes `/ticket-system-run <ticket-id>` (forwarding `--yes` if present in arguments)
  - Stops on first failure with details of which ticket failed
  - Reports a summary at the end: total processed, succeeded, failed
  - Argument hint: `[--yes]`
- **Tests first:** N/A (skill file is a markdown specification, not executable code)
- **Done when:** The skill file exists with correct frontmatter and complete behavioral instructions

### Step 2: Update `specs.md` section 4 — Command Pipeline
- **Files:** `specs.md`
- **What:** Add `/ticket-system-run-all` documentation after the existing `/ticket-system-run` section:
  - Agent: `ticket-system-coder`
  - Auto-invocation: no (manual)
  - Argument: none (reads from roadmap); optional `--yes` to bypass plan human gates
  - Behavior: read roadmap, iterate in order, invoke `/ticket-system-run`, stop on failure, report summary
- **Tests first:** N/A
- **Done when:** The command is fully documented in section 4.2 between `/ticket-system-run` and `/ticket-system-abort`

### Step 3: Update `specs.md` section 2.3 — Agent Profiles table
- **Files:** `specs.md`
- **What:** Add `/ticket-system-run-all` to the `ticket-system-coder` agent's "Used by" column in the agent profiles table (line 127)
- **Tests first:** N/A
- **Done when:** The coder agent row lists `/ticket-system-run-all` alongside `/ticket-system-implement` and `/ticket-system-run`

### Step 4: Update `specs.md` section 2.4 — Auto vs Manual Invocation table
- **Files:** `specs.md`
- **What:** Add a row for `ticket-system-run-all` with `disable-model-invocation: false` and reason "Chains safe-to-chain skills; plan has its own human gate"
- **Tests first:** N/A
- **Done when:** The table includes the new command entry

### Step 5: Update `specs.md` section 5.1 — File Tree to Generate
- **Files:** `specs.md`
- **What:** Add `ticket-system-run-all/` with its `SKILL.md` to the skills directory tree, after `ticket-system-run/`
- **Tests first:** N/A
- **Done when:** The file tree shows 13 skill directories (conventions + 12 slash commands)

### Step 6: Update `specs.md` section 8 — Validation Checklist
- **Files:** `specs.md`
- **What:** Add validation items for the new command:
  - Structural: `ticket-system-run-all/` directory with `SKILL.md`
  - Behavioral: stops on first failure, reports summary, forwards `--yes`, uses `ticket-system-coder` agent
- **Tests first:** N/A
- **Done when:** Section 8 includes validation entries for the new command

### Step 7: Update `CLAUDE.md` to stay in sync with `specs.md`
- **Files:** `CLAUDE.md`
- **What:** Update the "Expected output" section to reflect 13 skill directories (was 12). Update the count from "11 slash commands" to "12 slash commands". Review any other references that need updating.
- **Tests first:** N/A
- **Done when:** `CLAUDE.md` accurately reflects the updated spec

### Step 8: Update the coder agent description
- **Files:** `.claude/agents/ticket-system-coder.md`
- **What:** Verify the agent description mentions orchestrating run-all (the existing description says "orchestrating the full ticket lifecycle" which may already cover this). Update if needed to be explicit about run-all.
- **Tests first:** N/A
- **Done when:** The agent description is accurate for its expanded role
