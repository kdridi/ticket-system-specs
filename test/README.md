# Test Harness

`run-tests.sh` is the test harness for the ticket-system-specs project. It runs
structural and validation checks, provisions isolated temp repos for testing, and
cleans up after itself.

## How to Run

Basic mode (spec validation + test-validate.sh only):

```bash
bash test/run-tests.sh
```

Full mode (includes validate.sh against generated output and init-project.sh
structural verification):

```bash
GENERATED_OUTPUT_DIR=/path/to/generated/output bash test/run-tests.sh
```

The `GENERATED_OUTPUT_DIR` should point to a directory containing the output of
feeding `specs.md` to Claude Code (agents/, skills/, install.sh, init-project.sh,
etc.).

## What Is Automated

- **validate-spec.sh** -- Cross-reference integrity of specs.md (agent names,
  command references, hardcoded paths, section sizes).
- **test-validate.sh** -- The 23 test cases for validate.sh itself, ensuring the
  validation tooling is sound.
- **validate.sh** -- Full structural validation of generated output against the
  specs.md section 8 checklist. Requires `GENERATED_OUTPUT_DIR`.
- **init-project.sh structural checks** -- Verifies that running init-project.sh
  in an isolated temp repo creates the expected directory structure (tickets/,
  .tickets/config.yml, .gitignore with .worktrees/, .gitkeep files). Requires
  `GENERATED_OUTPUT_DIR` containing init-project.sh.

## What Remains Manual

The following cannot be automated because they require a running Claude Code
session:

- **Generating output** -- Feeding specs.md to Claude Code to produce the file
  tree (agents, skills, scripts). This is the inner loop's "generate" step.
- **Running slash commands** -- Testing `/ticket-system-create`,
  `/ticket-system-schedule`, `/ticket-system-plan`, etc. interactively inside
  Claude Code.
- **Agent interactions** -- Verifying that forked agents behave correctly with
  elevated permissions, human gates, self-evaluation, etc.
- **Outer feedback loop** -- The full cycle of install, init project, run
  commands, observe behavior, and iterate on specs.md.

## Temp Directory Lifecycle

Each test that needs an isolated environment calls `setup_test_env`, which:

1. Creates a temp directory via `mktemp -d`
2. Runs `git init` inside it with an initial empty commit
3. Runs `init-project.sh` if available from `GENERATED_OUTPUT_DIR`

Cleanup is guaranteed via a `trap EXIT` handler that removes the temp directory
even if tests fail or the script is interrupted.

## Exit Code

- **0** -- All tests passed (or skipped).
- **Non-zero** -- At least one test failed.
