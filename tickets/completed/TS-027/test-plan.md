# Test Plan — TS-027

## Strategy
This ticket modifies only `specs.md` and `CLAUDE.md` (specification files, not executable code). Testing is validation-based: we verify that the spec is internally consistent and complete by running the existing `validate-spec.sh` script and performing manual cross-reference checks. No unit or integration tests apply since there is no runtime code being written.

## Test Cases

### TC-1: New skill appears in file tree (section 5.1)
- **Type:** manual validation
- **Target:** Section 5.1 file tree listing
- **Input:** Read the skills directory listing in section 5.1
- **Expected:** `ticket-system-doctor/` with `SKILL.md` is listed among the skill directories
- **Covers criteria:** AC-1 (new skill exists)

### TC-2: Doctor command specification exists in section 4.2
- **Type:** manual validation
- **Target:** Section 4.2 command specifications
- **Input:** Search for `/ticket-system-doctor` heading in section 4.2
- **Expected:** A complete command specification block exists with Agent, Auto-invocation, and Behavior sections
- **Covers criteria:** AC-1 (skill exists), AC-2 (uses reader agent)

### TC-3: Reader agent assigned to doctor skill
- **Type:** manual validation
- **Target:** Section 2.3 agent profiles table and section 4.2 doctor specification
- **Input:** Check the agent assignment in the doctor specification and the "Used by" column of the reader row
- **Expected:** Doctor specification says `ticket-system-reader`; reader row includes `/ticket-system-doctor`
- **Covers criteria:** AC-2 (uses reader agent)

### TC-4: Status/directory mismatch check specified
- **Type:** manual validation
- **Target:** Section 4.2 doctor specification behavior
- **Input:** Read the diagnostic checklist steps
- **Expected:** A step exists that scans all ticket files and verifies frontmatter `status` matches the parent directory (backlog/planned/ongoing/completed/rejected)
- **Covers criteria:** AC-3

### TC-5: Orphaned worktree check specified
- **Type:** manual validation
- **Target:** Section 4.2 doctor specification behavior
- **Input:** Read the diagnostic checklist steps
- **Expected:** A step exists that runs `git worktree list` and cross-references with tickets in ongoing/
- **Covers criteria:** AC-4

### TC-6: Stale roadmap entries check specified
- **Type:** manual validation
- **Target:** Section 4.2 doctor specification behavior
- **Input:** Read the diagnostic checklist steps
- **Expected:** A step exists that reads roadmap.yml and verifies each referenced ticket exists in planned/
- **Covers criteria:** AC-5

### TC-7: Multiple ongoing tickets check specified
- **Type:** manual validation
- **Target:** Section 4.2 doctor specification behavior
- **Input:** Read the diagnostic checklist steps
- **Expected:** A step exists that checks ongoing/ contains at most 1 ticket subdirectory
- **Covers criteria:** AC-6

### TC-8: Issue reporting format with suggested fixes
- **Type:** manual validation
- **Target:** Section 4.2 doctor specification output format
- **Input:** Read the output format description
- **Expected:** Each issue includes `[ISSUE]` prefix, a clear description, and a suggested fix command. Healthy checks show `[OK]` prefix.
- **Covers criteria:** AC-7

### TC-9: No auto-fix behavior
- **Type:** manual validation
- **Target:** Section 4.2 doctor specification
- **Input:** Read the full specification
- **Expected:** Explicit statement that the command does NOT auto-fix; it only reports and suggests
- **Covers criteria:** AC-8

### TC-10: Model invocation enabled
- **Type:** manual validation
- **Target:** Section 2.4 invocation table
- **Input:** Check the `ticket-system-doctor` row
- **Expected:** `disable-model-invocation: false` with a reason indicating read-only safety
- **Covers criteria:** AC-9

### TC-11: Reader agent has git worktree list permission
- **Type:** manual validation
- **Target:** Section 2.3 agent profiles table
- **Input:** Check the `ticket-system-reader` allowed tools
- **Expected:** `Bash(git worktree list)` is included in the reader's allowed tools (needed for orphaned worktree detection)
- **Covers criteria:** AC-4 (prerequisite for orphaned worktree check)

### TC-12: Validation checklist updated
- **Type:** manual validation
- **Target:** Section 8 validation checklist
- **Input:** Check structural completeness and frontmatter sections
- **Expected:** `ticket-system-doctor/` listed in skills checklist; doctor-specific validation items present
- **Covers criteria:** AC-1 (completeness)

### TC-13: CLAUDE.md skill count updated
- **Type:** manual validation
- **Target:** CLAUDE.md
- **Input:** Read the expected output section
- **Expected:** "10 skill directories" and "conventions + 9 slash commands"
- **Covers criteria:** (consistency requirement from CLAUDE.md rules)

### TC-14: Help command recognizes "doctor" verb
- **Type:** manual validation
- **Target:** Section 4.2 `/ticket-system-help` specification
- **Input:** Read the known verbs list
- **Expected:** "doctor" is listed among the recognized verbs
- **Covers criteria:** AC-1 (discoverability)

### TC-15: validate-spec.sh passes
- **Type:** automated validation
- **Target:** Full spec consistency
- **Input:** Run `bash validate-spec.sh`
- **Expected:** Script passes (or new checks related to doctor are satisfied)
- **Covers criteria:** All (cross-reference consistency)

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: New skill exists with SKILL.md | TC-1, TC-2, TC-12, TC-14 |
| AC-2: Uses ticket-system-reader agent | TC-2, TC-3 |
| AC-3: Status/directory mismatch check | TC-4 |
| AC-4: Orphaned worktree check | TC-5, TC-11 |
| AC-5: Stale roadmap entries check | TC-6 |
| AC-6: Multiple ongoing tickets check | TC-7 |
| AC-7: Issue reporting with suggested fixes | TC-8 |
| AC-8: No auto-fix | TC-9 |
| AC-9: disable-model-invocation: false | TC-10 |
