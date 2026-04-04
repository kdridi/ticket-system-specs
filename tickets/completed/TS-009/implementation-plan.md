# Implementation Plan — TS-009

## Overview
Add a `/ticket-system-help` command to `specs.md` that provides self-documentation for the ticket system. When run without arguments, it lists all available commands with one-line descriptions and shows a live status summary based on the current ticket state. When run with a verb argument, it displays detailed documentation for that specific command. This requires changes to sections 2.3, 2.4, 4.1, 4.2, 5.1, and 8 of `specs.md`.

Since this repository contains only `specs.md` and `CLAUDE.md`, no runtime code is written here. The changes define the new command so that the generation pipeline produces the correct skill and agent configuration.

## Steps

### Step 1: Add `/ticket-system-help` to section 2.3 (Agent Profiles)
- **Files:** `specs.md` (section 2.3, agent table)
- **What:** The help command is read-only (scans directories, reads config, prints output). It fits the `ticket-system-reader` agent (model: haiku, permissionMode: plan, read-only Bash patterns). Add `/ticket-system-help` to the "Used by" column of the `ticket-system-reader` row.
- **Tests first:** N/A (spec-only). Run `validate-spec.sh` after.
- **Done when:** The agent table lists `/ticket-system-help` under `ticket-system-reader`.

### Step 2: Add `/ticket-system-help` to section 2.4 (Auto vs Manual Invocation)
- **Files:** `specs.md` (section 2.4, invocation table)
- **What:** Add a row for `ticket-system-help` with `disable-model-invocation: false`. The help command is read-only and zero risk, so it is safe for auto-invocation.
- **Tests first:** N/A.
- **Done when:** The invocation table includes the new skill row.

### Step 3: Add `/ticket-system-help` command specification to section 4.2
- **Files:** `specs.md` (section 4.2, after the last command or in a logical position)
- **What:** Add a new command block following the established format:
  - **Agent:** `ticket-system-reader` | **Auto-invocation:** yes
  - **Argument:** `[verb]` (optional verb name)
  - **Behavior (no argument):**
    1. Read `.tickets/config.yml`.
    2. Print a header and list all ticket-system commands with one-line descriptions.
    3. Scan `tickets/` subdirectories (backlog, planned, ongoing, completed, rejected) and count tickets in each.
    4. Print a live status section showing what the user can currently do, ordered by actionability (e.g., if ongoing exists, highlight that first; if backlog has items, suggest scheduling).
  - **Behavior (with verb argument):**
    1. If the verb matches a known command (create, schedule, analyze, split, plan, implement, verify, merge, help), print detailed documentation: what it does, which agent runs it, what arguments it takes, and what template/format it uses.
    2. If the verb is unknown, print an error listing all available verbs.
  - Keep the specification concise to stay within the section 4 line budget.
- **Tests first:** N/A. Run `validate-spec.sh` after.
- **Done when:** Section 4.2 contains the full `/ticket-system-help` block and `validate-spec.sh` passes.

### Step 4: Update section 4.1 (Pipeline Overview)
- **Files:** `specs.md` (section 4.1)
- **What:** Mention `/ticket-system-help` in the overview as an available utility command (it is not part of the linear pipeline but is always available). Add a brief note after the pipeline description.
- **Tests first:** N/A.
- **Done when:** Section 4.1 acknowledges the help command.

### Step 5: Add `ticket-system-help/` to section 5.1 (File Tree)
- **Files:** `specs.md` (section 5.1, skills directory listing)
- **What:** Add `ticket-system-help/` with `SKILL.md` to the skills tree, maintaining alphabetical order within the skills section.
- **Tests first:** N/A.
- **Done when:** The file tree includes the new skill directory.

### Step 6: Add `/ticket-system-help` to section 8 (Validation Checklist)
- **Files:** `specs.md` (section 8, structural completeness)
- **What:** Add a checkbox for `ticket-system-help/` in the Skills list. Also ensure the frontmatter and permissions checks cover it (it should have `context: fork`, `agent: ticket-system-reader`, `disable-model-invocation: false`).
- **Tests first:** N/A.
- **Done when:** Section 8 includes the new skill in the checklist.

### Step 7: Verify section line budgets
- **Files:** `specs.md`
- **What:** Run `validate-spec.sh` to confirm all sections remain within the 200-line budget. Section 4 is the most constrained. If it exceeds 200 lines, tighten language across command specifications.
- **Tests first:** Run `bash validate-spec.sh`.
- **Done when:** `validate-spec.sh` exits 0 with no warnings.

### Step 8: Update CLAUDE.md if needed
- **Files:** `CLAUDE.md`
- **What:** Review whether CLAUDE.md needs updates to reflect the new help command. Per repo rules, CLAUDE.md must stay in sync with specs.md. If the help command changes the validation quick reference or command list, update accordingly.
- **Tests first:** N/A.
- **Done when:** CLAUDE.md accurately reflects the current state of specs.md.

## Risk Notes
- **Section 4 line budget:** Section 4 currently uses approximately 188 lines. The help command specification must be kept concise (target: 25-30 lines). This leaves some headroom but requires tight writing.
- **No new agent needed:** The help command fits naturally under `ticket-system-reader` since it is entirely read-only. No agent creation or permission changes are needed.
- **Spec coherence:** The help command references all other commands by name. If any command is renamed in a concurrent change, the help command spec would need updating. Since TS-009 has no dependencies and is the only active ticket, this risk is minimal.
- **validate-spec.sh coverage:** The validation script checks agent-command cross-references. Adding `/ticket-system-help` to the reader agent's "Used by" column ensures the cross-reference check passes. The skill must also appear in the file tree for the structural check.
