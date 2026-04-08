# Test Plan — TS-030

## Strategy
Manual validation and structural verification. Since this is a spec-and-skill project (no runtime code to unit test), validation focuses on structural correctness, cross-reference consistency, and behavioral completeness of the generated skill file.

## Test Cases

### TC-1: Skill file exists with correct frontmatter
- **Type:** structural
- **Target:** `.claude/skills/ticket-system-edit/SKILL.md`
- **Input:** Read the file
- **Expected:** File exists; frontmatter contains `name: ticket-system-edit`, `context: fork`, `agent: ticket-system-editor`, `disable-model-invocation: false`, `argument-hint` is present, description is under 250 characters
- **Covers criteria:** Skill file location, agent assignment

### TC-2: Skill rejects non-editable ticket states
- **Type:** behavioral (specification review)
- **Target:** `.claude/skills/ticket-system-edit/SKILL.md`
- **Input:** Read the behavior section
- **Expected:** Explicit rejection logic for tickets in `ongoing/`, `completed/`, and `rejected/` states; only `backlog/` and `planned/` are accepted
- **Covers criteria:** State guard

### TC-3: Skill preserves metadata and log history
- **Type:** behavioral (specification review)
- **Target:** `.claude/skills/ticket-system-edit/SKILL.md`
- **Input:** Read the behavior section
- **Expected:** Instructions to preserve `id`, `created` date, and existing log entries; instructions to update `updated` timestamp via `date` command; instructions to append a new log entry
- **Covers criteria:** Metadata preservation, timestamp update, log entry

### TC-4: Skill handles roadmap.yml updates for planned tickets
- **Type:** behavioral (specification review)
- **Target:** `.claude/skills/ticket-system-edit/SKILL.md`
- **Input:** Read the behavior section
- **Expected:** When editing a planned ticket and the title or priority changes, the corresponding entry in `roadmap.yml` is also updated
- **Covers criteria:** Roadmap consistency

### TC-5: specs.md agent table includes /ticket-system-edit
- **Type:** structural
- **Target:** `specs.md`
- **Input:** Search for `ticket-system-editor` in agent table
- **Expected:** The "Used by" column includes `/ticket-system-edit` alongside existing commands
- **Covers criteria:** Cross-reference consistency

### TC-6: specs.md file tree includes ticket-system-edit skill
- **Type:** structural
- **Target:** `specs.md`
- **Input:** Search for file tree in section 5.1
- **Expected:** `ticket-system-edit/` directory listed under `skills/`
- **Covers criteria:** File tree completeness

### TC-7: specs.md command specification exists
- **Type:** structural
- **Target:** `specs.md`
- **Input:** Search for `/ticket-system-edit` in section 4.2
- **Expected:** Full command specification present with agent, argument, and behavior description
- **Covers criteria:** Command specification

### TC-8: Commit message format in skill
- **Type:** behavioral (specification review)
- **Target:** `.claude/skills/ticket-system-edit/SKILL.md`
- **Input:** Read commit instructions
- **Expected:** Commit message format is `PREFIX-XXX: Edit ticket — <brief summary of changes>`
- **Covers criteria:** Commit convention

### TC-9: No hardcoded prefixes
- **Type:** structural
- **Target:** `.claude/skills/ticket-system-edit/SKILL.md`
- **Input:** Grep for hardcoded prefix patterns (e.g., "TS-")
- **Expected:** No hardcoded prefixes; all references use PREFIX-XXX or read from config
- **Covers criteria:** No hardcoded prefixes

### TC-10: CLAUDE.md skill directory count is correct
- **Type:** structural
- **Target:** `CLAUDE.md`
- **Input:** Read the expected output section
- **Expected:** Skill directory count reflects the addition of `/ticket-system-edit`
- **Covers criteria:** Documentation accuracy

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| Command accepts ticket ID and modification instructions | TC-1, TC-7 |
| Rejects ongoing/completed/rejected tickets | TC-2 |
| Reads current ticket content before changes | TC-2, TC-3 |
| Applies requested modifications | TC-3, TC-7 |
| Preserves metadata (id, created, log history) | TC-3 |
| Updates `updated` timestamp via date | TC-3 |
| Appends log entry | TC-3 |
| Commits with correct message format | TC-8 |
| Runs via context: fork with ticket-system-editor | TC-1 |
| Skill file in correct location | TC-1 |
| No hardcoded prefixes | TC-9 |
| Roadmap.yml updated when title/priority changes | TC-4 |
