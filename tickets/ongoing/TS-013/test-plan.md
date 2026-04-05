# Test Plan — TS-013

## Strategy
This ticket modifies `specs.md` and `CLAUDE.md` — specification files, not executable code. Testing is done via manual validation against the acceptance criteria and structural consistency checks on the spec. Each test case verifies a specific aspect of the spec changes by reading the modified files and checking for required content.

## Test Cases

### TC-1: Skill entry exists in file tree
- **Type:** integration
- **Target:** specs.md section 5.1 (File Tree to Generate)
- **Input:** Read the file tree block in specs.md
- **Expected:** A line `ticket-system-abort/` with `SKILL.md` appears in the skills directory listing
- **Covers criteria:** AC-1 (new skill exists)

### TC-2: Correct agent assignment
- **Type:** unit
- **Target:** specs.md section 4.2 (abort command specification)
- **Input:** Read the abort command section header
- **Expected:** Agent is `ticket-system-ops`, not any other agent
- **Covers criteria:** AC-2 (uses ticket-system-ops agent)

### TC-3: Active ticket detection
- **Type:** unit
- **Target:** specs.md section 4.2 (abort command behavior steps)
- **Input:** Read behavior steps 2-3
- **Expected:** Steps describe scanning `tickets/ongoing/` on main, then checking worktrees via `git worktree list`, with a "Nothing to abort" exit when no active ticket is found
- **Covers criteria:** AC-3, AC-9

### TC-4: Confirmation gate present
- **Type:** unit
- **Target:** specs.md section 4.2 (abort command behavior)
- **Input:** Read confirmation step
- **Expected:** Uses `AskUserQuestion` to confirm before proceeding; bypassable with `yes`/`--yes`
- **Covers criteria:** AC-4

### TC-5: Ticket moved to rejected with correct frontmatter
- **Type:** unit
- **Target:** specs.md section 4.2 (abort command behavior)
- **Input:** Read steps 5-6
- **Expected:** Ticket file is copied to `tickets/rejected/PREFIX-XXX.md` on main with `status: rejected` and `updated: <now>` (via `date` command)
- **Covers criteria:** AC-5

### TC-6: Log entry added
- **Type:** unit
- **Target:** specs.md section 4.2 (abort command behavior)
- **Input:** Read step 7
- **Expected:** Log entry "Ticket aborted by user." is appended
- **Covers criteria:** AC-6

### TC-7: Worktree and branch cleanup
- **Type:** unit
- **Target:** specs.md section 4.2 (abort command behavior)
- **Input:** Read steps 8-9
- **Expected:** `git worktree remove .worktrees/PREFIX-XXX-worktree --force` and `git branch -D ticket/PREFIX-XXX` are specified
- **Covers criteria:** AC-7

### TC-8: Commit on main
- **Type:** unit
- **Target:** specs.md section 4.2 (abort command behavior)
- **Input:** Read step 10
- **Expected:** Commit message format is `PREFIX-XXX: Abort ticket — <title>` and happens on main (not in the worktree)
- **Covers criteria:** AC-8

### TC-9: disable-model-invocation is true
- **Type:** unit
- **Target:** specs.md section 2.4 (invocation table)
- **Input:** Read the invocation table
- **Expected:** `ticket-system-abort` row has `true` for `disable-model-invocation`
- **Covers criteria:** AC-10

### TC-10: Ops agent references abort
- **Type:** unit
- **Target:** specs.md section 2.3 (agent profiles table)
- **Input:** Read the ops agent row
- **Expected:** "Used by" column includes `/ticket-system-abort`
- **Covers criteria:** AC-2

### TC-11: Validation checklist updated
- **Type:** integration
- **Target:** specs.md section 8 (Validation Checklist)
- **Input:** Read the structural completeness section
- **Expected:** `ticket-system-abort/` appears in the skills checklist
- **Covers criteria:** AC-1

### TC-12: CLAUDE.md consistency
- **Type:** integration
- **Target:** CLAUDE.md
- **Input:** Read expected output section and validation section
- **Expected:** Skill directory count is 9 (or "conventions + 8 slash commands"), command count references are updated
- **Covers criteria:** AC-1

### TC-13: Help command recognizes abort
- **Type:** unit
- **Target:** specs.md section 4.2 (help command specification)
- **Input:** Read the help command verb list
- **Expected:** "abort" appears in the list of recognized verbs
- **Covers criteria:** AC-1

### TC-14: No hardcoded prefixes in abort spec
- **Type:** integration
- **Target:** specs.md section 4.2 (abort command specification)
- **Input:** Search the abort section for hardcoded prefixes
- **Expected:** Only `PREFIX-XXX` placeholders are used, no literal ticket prefixes like `TS-` or `PROJ-`
- **Covers criteria:** (cross-cutting — system convention)

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: New skill `/ticket-system-abort` exists | TC-1, TC-11, TC-12, TC-13 |
| AC-2: Uses `ticket-system-ops` agent | TC-2, TC-10 |
| AC-3: Finds active ticket in ongoing | TC-3 |
| AC-4: Asks for confirmation | TC-4 |
| AC-5: Moves to rejected with updated frontmatter | TC-5 |
| AC-6: Adds log entry "Ticket aborted by user." | TC-6 |
| AC-7: Removes worktree and branch | TC-7 |
| AC-8: Commits rejection on main | TC-8 |
| AC-9: Reports "Nothing to abort" when no ticket | TC-3 |
| AC-10: `disable-model-invocation: true` | TC-9 |
