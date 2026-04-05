# Test Plan -- TS-014

## Strategy
Since this ticket modifies `specs.md` (a specification file, not executable code), testing is done by generation and validation: generate the ticket system from the updated spec, then validate the output against the acceptance criteria. Each test case below describes what to check in the generated output.

## Test Cases
### TC-1: Config schema includes test_command
- **Type:** integration
- **Target:** Generated `init-project.sh` and conventions skill
- **Input:** Run `init-project.sh TESTPROJ` and inspect the generated `.tickets/config.yml`
- **Expected:** The config file contains a commented-out line `# test_command: "npm test"` (or similar) with an explanatory comment
- **Covers criteria:** AC-1 (config supports test_command), AC-4 (init-project.sh includes commented-out line)

### TC-2: Verifier uses test_command when set
- **Type:** integration
- **Target:** Generated `ticket-system-verify` SKILL.md
- **Input:** Read the generated verify skill instructions
- **Expected:** The skill instructs the agent to read `test_command` from `.tickets/config.yml` and execute it via `bash -c` if present
- **Covers criteria:** AC-3 (verifier reads test_command from config)

### TC-3: Verifier falls back to auto-detection when test_command is absent
- **Type:** integration
- **Target:** Generated `ticket-system-verify` SKILL.md
- **Input:** Read the generated verify skill instructions
- **Expected:** The skill describes a fallback to auto-detection (npm test / pytest / make test) when `test_command` is not set in config
- **Covers criteria:** AC-2 (fallback to auto-detection)

### TC-4: Conventions skill documents test_command
- **Type:** integration
- **Target:** Generated `ticket-system-conventions` SKILL.md
- **Input:** Read the generated conventions skill
- **Expected:** The conventions skill includes `test_command` in the config.yml documentation with a note that it is optional
- **Covers criteria:** AC-5 (conventions documents the field)

### TC-5: Verifier agent has bash -c permission
- **Type:** integration
- **Target:** Generated `ticket-system-verifier.md` agent file
- **Input:** Read the agent frontmatter
- **Expected:** The `tools` list includes `Bash(bash -c *)` alongside the existing test runner patterns
- **Covers criteria:** AC-6 (verifier bash permissions)

### TC-6: Existing test patterns preserved
- **Type:** integration
- **Target:** Generated `ticket-system-verifier.md` agent file
- **Input:** Read the agent frontmatter
- **Expected:** The `tools` list still includes `Bash(npm test *)`, `Bash(pytest *)`, `Bash(make test *)` for backward compatibility
- **Covers criteria:** AC-2 (fallback still works)

### TC-7: No hardcoded test commands in conventions
- **Type:** unit
- **Target:** Generated `ticket-system-conventions` SKILL.md
- **Input:** Search for hardcoded test runner references
- **Expected:** The conventions skill does not hardcode specific test commands as the only option; it references the configurable `test_command` field
- **Covers criteria:** AC-5

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: config.yml supports optional test_command | TC-1 |
| AC-2: Fallback to auto-detection | TC-3, TC-6 |
| AC-3: Verifier reads test_command from config | TC-2 |
| AC-4: init-project.sh includes commented-out test_command | TC-1 |
| AC-5: Conventions documents test_command | TC-4, TC-7 |
| AC-6: Verifier bash permissions include bash -c | TC-5 |
