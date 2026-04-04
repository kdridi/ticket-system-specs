# Test Plan — TS-009

## Strategy
Validation-based testing. Since this ticket modifies only `specs.md` (and potentially `CLAUDE.md`), testing consists of:
1. Automated cross-reference validation via `validate-spec.sh`.
2. Manual review of the spec text against acceptance criteria.
3. Structural checks to confirm the new command is properly integrated across all relevant sections.

## Test Cases

### TC-1: validate-spec.sh passes
- **Type:** integration
- **Target:** `specs.md` cross-reference integrity
- **Input:** Run `bash validate-spec.sh specs.md`
- **Expected:** Exit code 0, "PASSED: All checks passed"
- **Covers criteria:** All criteria (structural integrity of the spec)

### TC-2: Section 4 line count within budget
- **Type:** unit
- **Target:** Section 4 of `specs.md`
- **Input:** Count lines between `## 4. COMMAND PIPELINE` and `## 5. GENERATION RULES`
- **Expected:** 200 lines or fewer
- **Covers criteria:** Implicit constraint from existing budget rules

### TC-3: Help command specification present in section 4.2
- **Type:** unit (manual review)
- **Target:** `/ticket-system-help` block in section 4.2
- **Input:** Read the help command specification
- **Expected:** The spec includes: (a) agent assignment to `ticket-system-reader`, (b) auto-invocation set to yes, (c) argument described as optional verb, (d) no-argument behavior listing all commands with descriptions, (e) live status section scanning ticket directories, (f) verb-argument behavior showing detailed command documentation, (g) unknown verb error handling
- **Covers criteria:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-6

### TC-4: Help command in agent table
- **Type:** unit (manual review)
- **Target:** Section 2.3, `ticket-system-reader` row
- **Input:** Read the agent profiles table
- **Expected:** `/ticket-system-help` appears in the "Used by" column of the reader agent
- **Covers criteria:** AC-6 (registered as proper skill)

### TC-5: Help command in invocation table
- **Type:** unit (manual review)
- **Target:** Section 2.4, invocation table
- **Input:** Read the auto vs manual invocation table
- **Expected:** `ticket-system-help` row exists with `disable-model-invocation: false`
- **Covers criteria:** AC-6

### TC-6: Help skill in file tree
- **Type:** unit (manual review)
- **Target:** Section 5.1, file tree
- **Input:** Read the file tree listing
- **Expected:** `ticket-system-help/` directory with `SKILL.md` is listed under `skills/`
- **Covers criteria:** AC-6

### TC-7: Help skill in validation checklist
- **Type:** unit (manual review)
- **Target:** Section 8, structural completeness
- **Input:** Read the skills checklist
- **Expected:** `ticket-system-help/` has a checkbox entry
- **Covers criteria:** AC-6

### TC-8: Live status section reads from config
- **Type:** unit (manual review)
- **Target:** `/ticket-system-help` block in section 4.2
- **Input:** Read the help command specification
- **Expected:** The spec explicitly states that the command reads `.tickets/config.yml` to determine `tickets_dir` and scans ticket directories for counts
- **Covers criteria:** AC-3, AC-4

### TC-9: Unknown verb handling
- **Type:** unit (manual review)
- **Target:** `/ticket-system-help` block in section 4.2
- **Input:** Read the help command specification
- **Expected:** The spec states that an unknown verb produces an error message listing all available verbs
- **Covers criteria:** AC-5

### TC-10: No hardcoded paths or prefixes introduced
- **Type:** integration
- **Target:** `validate-spec.sh` checks 3 and 4
- **Input:** Run validation
- **Expected:** No new hardcoded `~/.claude/` paths or ticket prefixes
- **Covers criteria:** Structural integrity

### TC-11: Agent-command cross-references intact
- **Type:** integration
- **Target:** `validate-spec.sh` check 1
- **Input:** Run validation
- **Expected:** All commands reference valid agents, including the new help command
- **Covers criteria:** Structural integrity

### TC-12: Pipeline overview mentions help command
- **Type:** unit (manual review)
- **Target:** Section 4.1
- **Input:** Read the pipeline overview
- **Expected:** The help command is mentioned as an available utility
- **Covers criteria:** AC-1

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: No-arg prints full list of verbs with descriptions | TC-3, TC-12 |
| AC-2: Verb arg prints detailed documentation | TC-3 |
| AC-3: Live status section with actionable suggestions | TC-3, TC-8 |
| AC-4: Live status reads from tickets dir via config | TC-8 |
| AC-5: Unknown verb produces helpful error | TC-9 |
| AC-6: Registered as proper skill with correct frontmatter | TC-3, TC-4, TC-5, TC-6, TC-7 |
| Structural integrity | TC-1, TC-2, TC-10, TC-11 |
