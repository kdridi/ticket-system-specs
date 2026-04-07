# Test Plan — TS-029

## Strategy
Manual validation through document review since all deliverables are markdown specification files and skill definitions. Verification focuses on structural correctness, cross-reference consistency, and behavioral completeness.

## Test Cases

### TC-1: Skill file frontmatter correctness
- **Type:** unit
- **Target:** `.claude/skills/ticket-system-run-all/SKILL.md`
- **Input:** Read the skill file frontmatter
- **Expected:** Contains `name: ticket-system-run-all`, `description` under 250 characters, `disable-model-invocation: false`, `context: fork`, `agent: ticket-system-coder`, `argument-hint: "[--yes]"`
- **Covers criteria:** Skill file exists and is correctly structured

### TC-2: Skill behavior — roadmap reading
- **Type:** unit
- **Target:** `.claude/skills/ticket-system-run-all/SKILL.md` body
- **Input:** Read the behavior section
- **Expected:** Instructions specify reading `.tickets/config.yml` first, then `tickets/planned/roadmap.yml`, iterating in position order
- **Covers criteria:** Reads roadmap in position order

### TC-3: Skill behavior — sequential execution with stop-on-failure
- **Type:** unit
- **Target:** `.claude/skills/ticket-system-run-all/SKILL.md` body
- **Input:** Read the behavior section
- **Expected:** For each ticket, invokes `/ticket-system-run <ticket-id>`. On failure, stops immediately and reports which ticket failed.
- **Covers criteria:** Invokes /ticket-system-run per ticket, stops on failure

### TC-4: Skill behavior — yes flag forwarding
- **Type:** unit
- **Target:** `.claude/skills/ticket-system-run-all/SKILL.md` body
- **Input:** Read the behavior section
- **Expected:** If `$ARGUMENTS` contains `yes` or `--yes`, it is forwarded to each `/ticket-system-run` invocation
- **Covers criteria:** Human gates preserved unless --yes

### TC-5: Skill behavior — summary report
- **Type:** unit
- **Target:** `.claude/skills/ticket-system-run-all/SKILL.md` body
- **Input:** Read the behavior section
- **Expected:** After completion (success or failure), reports total tickets attempted, succeeded count, and failed ticket ID (if any)
- **Covers criteria:** Summary report at end

### TC-6: specs.md section 4 — command documentation
- **Type:** integration
- **Target:** `specs.md` section 4.2
- **Input:** Read the run-all command section
- **Expected:** Complete command spec with agent, auto-invocation flag, argument, behavior steps, and note on human gates
- **Covers criteria:** Command documented in spec

### TC-7: specs.md cross-references — agent table
- **Type:** integration
- **Target:** `specs.md` section 2.3
- **Input:** Read the agent profiles table
- **Expected:** `ticket-system-coder` row lists `/ticket-system-run-all` in "Used by"
- **Covers criteria:** Agent mapping is consistent

### TC-8: specs.md cross-references — auto-invocation table
- **Type:** integration
- **Target:** `specs.md` section 2.4
- **Input:** Read the invocation table
- **Expected:** `ticket-system-run-all` row with `false` and appropriate reason
- **Covers criteria:** Auto-invocation setting is documented

### TC-9: specs.md cross-references — file tree
- **Type:** integration
- **Target:** `specs.md` section 5.1
- **Input:** Read the file tree
- **Expected:** `ticket-system-run-all/` with `SKILL.md` appears in the skills directory listing
- **Covers criteria:** File tree includes the new skill

### TC-10: specs.md cross-references — validation checklist
- **Type:** integration
- **Target:** `specs.md` section 8
- **Input:** Read the validation checklist
- **Expected:** Entries for `ticket-system-run-all/` structural check and behavioral checks
- **Covers criteria:** Validation checklist updated

### TC-11: CLAUDE.md sync
- **Type:** integration
- **Target:** `CLAUDE.md`
- **Input:** Read the expected output section
- **Expected:** Reflects 13 skill directories (conventions + 12 slash commands)
- **Covers criteria:** CLAUDE.md in sync with specs.md

### TC-12: No hardcoded prefixes
- **Type:** unit
- **Target:** `.claude/skills/ticket-system-run-all/SKILL.md`
- **Input:** Grep for hardcoded ticket prefixes (TS-, PROJ- used as actual IDs rather than examples)
- **Expected:** No hardcoded prefixes; uses `PREFIX-XXX` or `PROJ-003` only as examples with clear context
- **Covers criteria:** Follows conventions — no hardcoded prefixes

### TC-13: Empty roadmap handling
- **Type:** unit
- **Target:** `.claude/skills/ticket-system-run-all/SKILL.md` body
- **Input:** Read the behavior section
- **Expected:** If roadmap is empty (`tickets: []`), reports "No planned tickets to run" and exits cleanly
- **Covers criteria:** Edge case — empty roadmap

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| Reads roadmap in position order | TC-2 |
| Invokes /ticket-system-run per ticket | TC-3 |
| Stops on first failure with notification | TC-3 |
| Continues on success | TC-3 |
| Reports summary at end | TC-5 |
| Documented in specs.md with skill file | TC-1, TC-6, TC-7, TC-8, TC-9, TC-10, TC-11 |
