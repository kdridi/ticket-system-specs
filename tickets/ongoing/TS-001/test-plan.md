# Test Plan — TS-001

## Strategy
This is a documentation-only ticket (type: docs). There is no executable code to unit test. Validation is structural: verify the README exists, contains all required sections, and meets the acceptance criteria. All test cases are manual inspections.

## Test Cases

### TC-1: README exists at repository root
- **Type:** integration
- **Target:** README.md file existence
- **Input:** Check for file at repository root
- **Expected:** File exists at `README.md` (not in a subdirectory)
- **Covers criteria:** "README exists at the repository root"

### TC-2: Section — How the ticket system works
- **Type:** integration
- **Target:** README.md content
- **Input:** Read README.md and check for section covering system concepts
- **Expected:** Contains a section explaining ticket lifecycle (backlog, planned, ongoing, completed, rejected), directory structure, agents, skills, and slash commands
- **Covers criteria:** "README has a section explaining how the ticket system works (concepts, directory structure, agents, skills, slash commands)"

### TC-3: Section — Generating the system from specs.md
- **Type:** integration
- **Target:** README.md content
- **Input:** Read README.md and check for generation section
- **Expected:** Contains a section explaining how to feed specs.md to Claude Code and what files get produced (ARCHITECTURE.md, install.sh, init-project.sh, 6 agents, 11 skills, hooks)
- **Covers criteria:** "README has a section explaining how to generate the system from specs.md"

### TC-4: Section — Installing the generated system
- **Type:** integration
- **Target:** README.md content
- **Input:** Read README.md and check for installation section
- **Expected:** Contains a section explaining install.sh usage and $CLAUDE_DIR
- **Covers criteria:** "README has a section explaining how to install the generated system into a target project"

### TC-5: Section — Initializing and using the system
- **Type:** integration
- **Target:** README.md content
- **Input:** Read README.md and check for initialization and usage sections
- **Expected:** Contains sections explaining init-project.sh usage and all 10 slash commands
- **Covers criteria:** "README has a section explaining how to initialize and use the system in a new project"

### TC-6: Worktree model explanation
- **Type:** integration
- **Target:** README.md content
- **Input:** Read README.md and search for worktree explanation
- **Expected:** Contains explanation of why ongoing/ on main stays empty, how worktrees are created at plan time inside .worktrees/, and how merge lands changes back to main
- **Covers criteria:** "README includes a brief explanation of the worktree model"

### TC-7: Writing style — plain English, no emojis
- **Type:** integration
- **Target:** README.md content
- **Input:** Read entire README.md
- **Expected:** Written in plain English, no emoji characters present, clear and concise prose
- **Covers criteria:** "README is written in plain English, no emojis, clear and concise"

### TC-8: CLAUDE.md updated to reflect README
- **Type:** integration
- **Target:** CLAUDE.md content
- **Input:** Read CLAUDE.md
- **Expected:** Repository Structure section lists README.md. Rules section acknowledges README.md as a valid file.
- **Covers criteria:** Implicit requirement from CLAUDE.md sync rule

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| README exists at the repository root | TC-1 |
| Section explaining how the ticket system works | TC-2 |
| Section explaining how to generate the system | TC-3 |
| Section explaining how to install the generated system | TC-4 |
| Section explaining how to initialize and use the system | TC-5 |
| Worktree model explanation | TC-6 |
| Plain English, no emojis, clear and concise | TC-7 |
| CLAUDE.md stays in sync | TC-8 |
