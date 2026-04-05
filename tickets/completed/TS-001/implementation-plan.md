# Implementation Plan — TS-001

## Overview
Create a `README.md` at the repository root that explains the ticket-system-specs project from two perspectives: developers who want to understand how the system works, and users who want to generate, install, and use it. The README documents the spec repo itself, not the generated system (which has its own `ARCHITECTURE.md`).

## Steps

### Step 1: Create README.md with all required sections
- **Files:** `README.md` (create)
- **What:** Write the complete README with the following sections:
  1. **Title and one-line summary** -- what this repository is.
  2. **What is the Ticket System** -- overview of the file-based, AI-native project management system. Mention: no SaaS, no databases, runs entirely inside git repos via Claude Code. One active ticket at a time. Filesystem is the database, git is the audit trail.
  3. **How It Works** -- cover these concepts:
     - Ticket lifecycle: backlog, planned, ongoing, completed, rejected.
     - Directory structure (tickets/backlog, tickets/planned with roadmap.yml, tickets/ongoing, tickets/completed, tickets/rejected).
     - 6 agents grouped by permission profile (reader, editor, planner, coder, verifier, ops).
     - Skills as slash commands that fork into agents for permission elevation.
     - The shared conventions skill loaded by all agents.
     - Worktree isolation model: worktree created at plan time inside `.worktrees/`, all work happens there, `tickets/ongoing/` on main is always empty, merge lands the branch back.
  4. **Generating the System** -- how to feed `specs.md` to a fresh Claude Code session with Opus 4.6 (1M context). List what gets produced: ARCHITECTURE.md, install.sh, init-project.sh, 6 agents, 11 skills (conventions + 10 commands), hooks directory with worktree validator.
  5. **Installing** -- how to run `install.sh`, what `$CLAUDE_DIR` means (defaults to `~/.claude/`), that the script prompts for the install directory interactively.
  6. **Initializing a Project** -- how to run `init-project.sh` in a target repo, what it creates (.tickets/config.yml, tickets/ directory tree with subdirectories, .gitignore entries for .worktrees/).
  7. **Using the System** -- brief guide to all 10 slash commands:
     - `/ticket-system-create` -- create a new ticket in backlog
     - `/ticket-system-schedule` -- refine and move to planned, insert into roadmap (includes split analysis)
     - `/ticket-system-plan` -- activate ticket, create worktree, generate implementation and test plans
     - `/ticket-system-implement` -- execute the plan in the worktree
     - `/ticket-system-verify` -- run tests, check acceptance criteria, issue PASS/FAIL verdict
     - `/ticket-system-merge` -- merge completed ticket branch to main, remove worktree
     - `/ticket-system-run` -- chain plan, implement, verify, merge in sequence (stops on failure)
     - `/ticket-system-abort` -- destroy worktree, move ticket to rejected
     - `/ticket-system-doctor` -- diagnostic checks for system health
     - `/ticket-system-help` -- list commands and project status, or get detailed help on a specific command
  8. **Limitations** -- mono-developer workflow (one ticket at a time), fork context loss (each command runs in its own fork), POSIX-only dependencies, system installed at user level (not plugin), no external tool dependencies.
- **Tests first:** Not applicable (documentation-only ticket).
- **Done when:** README.md exists at the repo root with all 8 sections, written in plain English with no emojis.

### Step 2: Update CLAUDE.md repository structure section
- **Files:** `CLAUDE.md` (modify)
- **What:** The CLAUDE.md "Repository Structure" section currently lists only `CLAUDE.md` and `specs.md`. After adding the README, this section should be updated to include `README.md` in the file listing. Also review the "Rules for Working on This Repo" section -- the rule "Only modify CLAUDE.md and specs.md" should be updated to include `README.md` as an accepted file.
- **Tests first:** Not applicable.
- **Done when:** CLAUDE.md accurately reflects the repo structure including README.md.

### Step 3: Update ticket metadata
- **Files:** `tickets/ongoing/TS-001/ticket.md` (modify)
- **What:** Update the Files Modified section with the actual files changed. Add a log entry for plan completion and implementation.
- **Tests first:** Not applicable.
- **Done when:** Ticket metadata reflects the work done.

## Risk Notes
- The CLAUDE.md currently says "Only modify CLAUDE.md and specs.md -- no other files belong here." Adding README.md means this rule needs updating. Step 2 handles this explicitly.
- The README must describe the generated system accurately based on specs.md without becoming a duplicate of specs.md. It should be a high-level guide, not an exhaustive specification.
- The README should not include content that would become stale if specs.md changes. Focus on stable concepts (lifecycle, command names, architecture) rather than implementation details that may shift.
