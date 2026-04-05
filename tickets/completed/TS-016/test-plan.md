# Test Plan — TS-016

## Strategy
This is a spec-file modification ticket. Testing is structural validation: verify that all required sections of specs.md are updated consistently, that cross-references are correct, and that the generated system (when specs.md is fed to Claude Code) would produce a working `/ticket-system-next` skill. Since we cannot run the generated system in this repo, testing focuses on spec-level correctness.

## Test Cases

### TC-1: Skill entry exists in file tree
- **Type:** structural
- **Target:** specs.md section 5.1
- **Input:** Search for `ticket-system-next/` in the file tree block
- **Expected:** A line `ticket-system-next/` with `SKILL.md` appears in the skills directory listing
- **Covers criteria:** AC-1 (new skill exists)

### TC-2: Reader agent assignment
- **Type:** structural
- **Target:** specs.md section 4.2 (next command specification)
- **Input:** Read the agent line of the `/ticket-system-next` command spec
- **Expected:** Says `ticket-system-reader`
- **Covers criteria:** AC-2 (uses reader agent)

### TC-3: Reader agent tools updated
- **Type:** structural
- **Target:** specs.md section 2.3
- **Input:** Read the `ticket-system-reader` row in the agent profiles table
- **Expected:** Allowed Tools includes `Bash(git diff *)` and Used by includes `/ticket-system-next`
- **Covers criteria:** AC-2, AC-3

### TC-4: Detection logic covers all pipeline states
- **Type:** content
- **Target:** specs.md section 4.2 (next command specification)
- **Input:** Read the detection logic section
- **Expected:** Five priority-ordered checks are present:
  1. Inconsistency check (.pending file) -> doctor
  2. Worktree exists with sub-checks (completed -> merge, modified code -> verify, plan exists -> implement, no plan -> plan)
  3. Roadmap has tickets -> plan first ticket
  4. Backlog has tickets -> schedule
  5. Empty system -> create
- **Covers criteria:** AC-4 (covers all pipeline states)

### TC-5: Output format includes status, recommendation, and command
- **Type:** content
- **Target:** specs.md section 4.2 (next command specification)
- **Input:** Read the output format section
- **Expected:** Output includes "Status:" line (what it detected), "Next action:" line (exact command to run)
- **Covers criteria:** AC-5 (output includes detection, recommendation, command)

### TC-6: Auto-invocation setting
- **Type:** structural
- **Target:** specs.md section 2.4
- **Input:** Read the disable-model-invocation table
- **Expected:** `ticket-system-next` row has `false` with reason indicating read-only safety
- **Covers criteria:** AC-6 (disable-model-invocation: false)

### TC-7: Validation checklist updated
- **Type:** structural
- **Target:** specs.md section 8
- **Input:** Search for `ticket-system-next` in the validation checklist
- **Expected:** Listed in the structural completeness skills section
- **Covers criteria:** AC-1 (new skill exists -- validation confirms it)

### TC-8: Command pipeline overview mentions next
- **Type:** content
- **Target:** specs.md section 4.1
- **Input:** Read the overview paragraph
- **Expected:** `/ticket-system-next` is mentioned alongside help and doctor as a utility command
- **Covers criteria:** AC-3 (command detects state and suggests action -- described in overview)

### TC-9: No hardcoded prefixes in command spec
- **Type:** structural
- **Target:** specs.md section 4.2 (next command specification)
- **Input:** Search for literal "TS-" in the next command specification
- **Expected:** Any ticket ID references use `PREFIX-XXX` notation, not hardcoded prefixes. The output format example may use a concrete example like `TS-011` for illustration, which is acceptable as long as the behavior description uses `PREFIX-XXX`.
- **Covers criteria:** General convention (no hardcoded prefixes)

### TC-10: CLAUDE.md consistency
- **Type:** structural
- **Target:** CLAUDE.md
- **Input:** Check skill/command counts and utility command references
- **Expected:** Counts updated to reflect 12 skill directories (conventions + 11 slash commands), and any utility command lists include next
- **Covers criteria:** Repository consistency rule

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: New skill exists with SKILL.md | TC-1, TC-7 |
| AC-2: Uses ticket-system-reader agent | TC-2, TC-3 |
| AC-3: Detects state and suggests next action | TC-3, TC-4, TC-8 |
| AC-4: Covers all pipeline states | TC-4 |
| AC-5: Output includes detection, recommendation, command | TC-5 |
| AC-6: disable-model-invocation: false | TC-6 |
