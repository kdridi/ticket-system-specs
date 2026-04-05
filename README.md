# ticket-system-specs

A specification file that generates a complete file-based, AI-native project management system for Claude Code.

## What is the Ticket System

The Ticket System is a project management workflow that runs entirely inside a git repository via Claude Code. There are no external dependencies -- no SaaS platforms, no databases, no package managers. The filesystem is the database and git is the audit trail.

The system enforces a single active ticket at a time. Every code change requires a ticket, even a one-line fix. Commands communicate through markdown files (called artifacts), not implicit state, so each command can run independently.

## How It Works

### Ticket Lifecycle

Every ticket moves through a defined lifecycle with five states:

- **backlog** -- rough ideas, not yet refined.
- **planned** -- refined and ready to activate, ordered in a roadmap.
- **ongoing** -- the single active ticket being worked on.
- **completed** -- successfully finished and verified.
- **rejected** -- cancelled or invalid.

### Directory Structure

Tickets live in a structured directory tree inside the project:

```
tickets/
  backlog/           Rough ideas, one markdown file per ticket
  planned/           Refined tickets ready for activation
    roadmap.yml      Authoritative execution order
  ongoing/           The active ticket (max 1), stored as a subdirectory
    PREFIX-XXX/      Contains ticket.md plus plan artifacts
  completed/         Successfully finished tickets
  rejected/          Cancelled or invalid tickets
```

Project configuration lives in `.tickets/config.yml`, which defines the ticket ID prefix (e.g., `PROJ`), zero-padding width, and tickets directory name. Every command reads this file first -- no prefixes are hardcoded anywhere.

### Agents and Permissions

The system uses 6 agents grouped by permission profile, not one per command:

- **reader** -- read-only access, used by help and diagnostics commands.
- **editor** -- file creation and git operations, used by create and schedule commands.
- **planner** -- deep analysis with git log/diff plus worktree management, used by the plan command.
- **coder** -- unrestricted access (the plan is already approved), used by implement and run commands.
- **verifier** -- read access plus test runners, used by the verify command.
- **ops** -- git merge and branch operations, used by merge and abort commands.

The main Claude Code session always stays in default (locked down) mode. Slash commands elevate privileges by forking into the appropriate agent.

### Skills as Slash Commands

Each slash command is implemented as a skill file that forks into an agent for permission elevation. The skill contains the detailed instructions; the agent defines the execution profile (model, permissions, allowed tools). A shared conventions skill is loaded by all agents automatically, providing consistent knowledge of ticket format, lifecycle, and commit rules.

### Worktree Isolation

All ticket work happens in a git worktree, not on the main branch. The worktree is created at plan time inside a `.worktrees/` directory (which is gitignored). The `tickets/ongoing/` directory on main is always empty -- the active ticket exists only inside the worktree. When work is complete and verified, the merge command lands the worktree branch back to main and removes the worktree.

This isolation means the main branch stays clean while work is in progress.

## Generating the System

To generate the ticket system from this repository:

1. Open a fresh Claude Code session with Opus 4.6 (1M context).
2. Feed the entire `specs.md` file as input.
3. Claude Code reads the specification and generates all files.

The generation produces:

- `ARCHITECTURE.md` -- the specification reformatted as an architecture document.
- `install.sh` -- an interactive script that prompts for the install directory and copies files to the right location.
- `init-project.sh` -- a script that initializes a new project with the ticket directory structure.
- 6 agent files in `agents/` (reader, editor, planner, coder, verifier, ops).
- 11 skill directories in `skills/`, each containing a `SKILL.md` file (1 shared conventions skill plus 10 slash commands).
- A `hooks/` directory containing a worktree path validation hook.

## Installing

After generation, run `install.sh`. The script prompts interactively for the installation directory. The `$CLAUDE_DIR` variable refers to this directory and defaults to `~/.claude/`. The script copies agents, skills, hooks, and configuration to the chosen location.

## Initializing a Project

To set up the ticket system in a new or existing repository, run `init-project.sh` inside the target repo. This creates:

- `.tickets/config.yml` with project-specific configuration (prefix, digit width, tickets directory name).
- The `tickets/` directory tree with `backlog/`, `planned/`, `ongoing/`, `completed/`, and `rejected/` subdirectories.
- A `.gitignore` entry for `.worktrees/` to keep worktree directories out of version control.

## Using the System

The system provides 10 slash commands:

- `/ticket-system-create` -- Create a new ticket in backlog from a title or description. Enters dialogue mode for vague input to refine the ticket before saving.

- `/ticket-system-schedule` -- Validate and refine a backlog ticket, then move it to planned and insert it into the roadmap. Includes atomicity analysis that proposes splitting oversized tickets. Requires human approval before committing changes.

- `/ticket-system-plan` -- Activate a planned ticket by creating a git worktree, analyzing the codebase, and generating implementation and test plans. Requires human approval of the plans before proceeding.

- `/ticket-system-implement` -- Execute the approved implementation plan in the ticket's worktree using TDD methodology. Writes tests first, then implementation code, committing each step.

- `/ticket-system-verify` -- Run tests and check acceptance criteria against the implementation. Issues a PASS or FAIL verdict. On PASS, moves the ticket to completed status inside the worktree. Never modifies code.

- `/ticket-system-merge` -- Merge a completed ticket's worktree branch into main, remove the worktree, and clean up the branch.

- `/ticket-system-run` -- Chain plan, implement, verify, and merge in sequence. Stops on failure at any step. The plan step retains its human approval gate.

- `/ticket-system-abort` -- Destroy the worktree and move the ticket to rejected status. This is destructive and cannot be undone.

- `/ticket-system-doctor` -- Run read-only diagnostic checks on the ticket system. Detects status/directory mismatches, orphaned worktrees, stale roadmap entries, and multiple ongoing tickets.

- `/ticket-system-help` -- Display available commands with live project status, or show detailed documentation for a specific command.

## Limitations

- **Mono-developer workflow.** The system supports one active ticket at a time. It is designed for a single developer (human or AI) working sequentially through a prioritized backlog, not for team-based parallel development.

- **Fork context loss.** Each slash command runs in its own forked context. The fork does not carry conversation history from the main session or from previous commands. Commands communicate exclusively through files on disk.

- **POSIX-only dependencies.** The system requires only bash, git, and standard POSIX utilities. There are no npm, pip, or other package manager dependencies. This keeps the system portable but limits it to environments where these tools are available.

- **User-level installation.** The system is installed into the Claude Code configuration directory, not as a plugin or extension. It relies on Claude Code's skills and agents format.

- **No external tool dependencies.** The system does not integrate with external issue trackers, CI/CD systems, or notification services. It is self-contained within the git repository.
