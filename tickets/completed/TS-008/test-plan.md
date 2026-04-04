# Test Plan — TS-008

## Strategy
Validation-based testing. Since this ticket modifies only `specs.md` (a specification document), testing consists of:
1. Automated cross-reference validation via `validate-spec.sh`.
2. Manual review of the spec text against acceptance criteria.
3. Outer-loop functional testing (generate the system from the updated spec and test the create command in a real project).

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
- **Covers criteria:** Implicit constraint from TS-010

### TC-3: Dialogue mode instructions present in spec
- **Type:** unit (manual review)
- **Target:** `/ticket-system-create` block in section 4.2
- **Input:** Read the create command specification
- **Expected:** The spec includes explicit instructions for: (a) classifying input as clear vs vague, (b) entering dialogue mode for vague input, (c) asking clarifying questions, (d) presenting a draft for confirmation, (e) only writing files after confirmation
- **Covers criteria:** AC-1, AC-2, AC-3, AC-6

### TC-4: Fast path preserved in spec
- **Type:** unit (manual review)
- **Target:** `/ticket-system-create` block in section 4.2
- **Input:** Read the create command specification
- **Expected:** The spec explicitly states that clear, complete input bypasses dialogue and proceeds directly to file creation
- **Covers criteria:** AC-5

### TC-5: Confirmation gate before file write
- **Type:** unit (manual review)
- **Target:** `/ticket-system-create` block in section 4.2
- **Input:** Read the create command specification
- **Expected:** The spec states that no files are written and no git operations occur until the user confirms the draft
- **Covers criteria:** AC-4, AC-6

### TC-6: No new agents or skills introduced
- **Type:** unit (manual review)
- **Target:** Section 5.1 file tree and section 2.3 agent table
- **Input:** Read sections 2.3 and 5.1
- **Expected:** No new agents or skills added. The create command still uses `ticket-system-editor`.
- **Covers criteria:** Structural stability

### TC-7: Agent-command cross-references intact
- **Type:** integration
- **Target:** `validate-spec.sh` check 1
- **Input:** Run validation
- **Expected:** All commands reference valid agents, no unknown agent errors
- **Covers criteria:** Structural integrity

### TC-8: No hardcoded paths or prefixes
- **Type:** integration
- **Target:** `validate-spec.sh` checks 3 and 4
- **Input:** Run validation
- **Expected:** No hardcoded `~/.claude/` paths outside allowed contexts, no hardcoded ticket prefixes
- **Covers criteria:** Structural integrity

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: Detects vague input and enters dialogue mode | TC-3 |
| AC-2: Asks targeted clarifying questions | TC-3 |
| AC-3: Proposes draft and asks for confirmation | TC-3, TC-5 |
| AC-4: Writes and commits on confirmation | TC-5 |
| AC-5: Fast path for clear input | TC-4 |
| AC-6: No intermediate files | TC-3, TC-5 |
| Structural integrity | TC-1, TC-2, TC-6, TC-7, TC-8 |
