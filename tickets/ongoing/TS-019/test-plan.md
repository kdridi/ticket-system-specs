# Test Plan — TS-019

## Strategy
Manual verification by inspecting the spec file. Since this ticket modifies only the agent profiles table in `specs.md` (section 2.3), testing consists of verifying the table contents and cross-referencing each pattern against the documented command behaviors in section 4.2.

## Test Cases

### TC-1: Editor agent git commit pattern tightened
- **Type:** unit
- **Target:** specs.md section 2.3, editor row
- **Input:** Read the editor row from the agent profiles table
- **Expected:** Contains `Bash(git commit -m *)` (not `Bash(git commit *)`)
- **Covers criteria:** AC-1

### TC-2: Editor agent git mv pattern tightened
- **Type:** unit
- **Target:** specs.md section 2.3, editor row
- **Input:** Read the editor row from the agent profiles table
- **Expected:** Contains `Bash(git mv tickets/*)` (not `Bash(git mv *)`)
- **Covers criteria:** AC-2

### TC-3: Planner agent retains broader git mv
- **Type:** unit
- **Target:** specs.md section 2.3, planner row
- **Input:** Read the planner row from the agent profiles table
- **Expected:** Contains `Bash(git mv *)` (unchanged, NOT `Bash(git mv tickets/*)`)
- **Covers criteria:** AC-3

### TC-4: Planner agent git commit pattern tightened
- **Type:** unit
- **Target:** specs.md section 2.3, planner row
- **Input:** Read the planner row from the agent profiles table
- **Expected:** Contains `Bash(git commit -m *)` (not `Bash(git commit *)`)
- **Covers criteria:** AC-1 (extended to planner per technical approach)

### TC-5: Verifier agent git commit pattern tightened
- **Type:** unit
- **Target:** specs.md section 2.3, verifier row
- **Input:** Read the verifier row from the agent profiles table
- **Expected:** Contains `Bash(git commit -m *)` (not `Bash(git commit *)`)
- **Covers criteria:** AC-1

### TC-6: Verifier agent git mv pattern tightened
- **Type:** unit
- **Target:** specs.md section 2.3, verifier row
- **Input:** Read the verifier row from the agent profiles table
- **Expected:** Contains `Bash(git mv tickets/*)` (not `Bash(git mv *)`)
- **Covers criteria:** AC-5 (no documented behavior broken)

### TC-7: Ops agent git commit pattern tightened
- **Type:** unit
- **Target:** specs.md section 2.3, ops row
- **Input:** Read the ops row from the agent profiles table
- **Expected:** Contains `Bash(git commit -m *)` (not `Bash(git commit *)`)
- **Covers criteria:** AC-5

### TC-8: Ops agent git mv pattern tightened
- **Type:** unit
- **Target:** specs.md section 2.3, ops row
- **Input:** Read the ops row from the agent profiles table
- **Expected:** Contains `Bash(git mv tickets/*)` (not `Bash(git mv *)`)
- **Covers criteria:** AC-5

### TC-9: Reader agent has no overly broad patterns
- **Type:** unit
- **Target:** specs.md section 2.3, reader row
- **Input:** Read the reader row from the agent profiles table
- **Expected:** No `git commit` or `git mv` patterns present. Only `Bash(git worktree list)` and `Bash(git diff *)`
- **Covers criteria:** AC-4

### TC-10: Create command compatible with tightened editor patterns
- **Type:** integration
- **Target:** specs.md section 4.2, /ticket-system-create
- **Input:** Review create command behavior against editor's allowed tools
- **Expected:** Create uses `git commit -m "..."` (compatible with `Bash(git commit -m *)`); does not use `git mv` at all
- **Covers criteria:** AC-5

### TC-11: Schedule command compatible with tightened editor patterns
- **Type:** integration
- **Target:** specs.md section 4.2, /ticket-system-schedule
- **Input:** Review schedule command behavior against editor's allowed tools
- **Expected:** Schedule uses `git commit -m "..."` (compatible) and `git mv tickets/backlog/* tickets/planned/*` or `tickets/rejected/*` (all under `tickets/`, compatible with `Bash(git mv tickets/*)`)
- **Covers criteria:** AC-5

### TC-12: Plan command compatible with tightened planner patterns
- **Type:** integration
- **Target:** specs.md section 4.2, /ticket-system-plan
- **Input:** Review plan command behavior against planner's allowed tools
- **Expected:** Plan uses `git commit -m "..."` (compatible with `Bash(git commit -m *)`); git mv operations happen via `git -C` (handled by hook, not by Bash patterns)
- **Covers criteria:** AC-5

### TC-13: Verify command compatible with tightened verifier patterns
- **Type:** integration
- **Target:** specs.md section 4.2, /ticket-system-verify
- **Input:** Review verify command behavior against verifier's allowed tools
- **Expected:** Verify uses `git commit -m "..."` (compatible); `git mv tickets/ongoing/PREFIX-XXX tickets/completed/PREFIX-XXX` (compatible with `Bash(git mv tickets/*)`)
- **Covers criteria:** AC-5

### TC-14: Abort command compatible with tightened ops patterns
- **Type:** integration
- **Target:** specs.md section 4.2, /ticket-system-abort
- **Input:** Review abort command behavior against ops's allowed tools
- **Expected:** Abort uses `git commit -m "..."` on main (compatible with `Bash(git commit -m *)`); ticket copy from worktree uses `git -C` (handled by hook)
- **Covers criteria:** AC-5

### TC-15: No residual `Bash(git commit *)` without `-m` in non-coder agents
- **Type:** unit
- **Target:** specs.md section 2.3, all rows except coder
- **Input:** Search for `Bash(git commit *)` in section 2.3
- **Expected:** Only `Bash(git commit -m *)` appears (no bare `Bash(git commit *)` except in coder which is unrestricted)
- **Covers criteria:** AC-1, AC-6

## Coverage Map
| Acceptance Criterion | Test Cases |
|---------------------|------------|
| AC-1: git commit -m on editor, verifier | TC-1, TC-5, TC-15 |
| AC-2: git mv tickets/* on editor | TC-2 |
| AC-3: planner retains git mv * | TC-3 |
| AC-4: reader reviewed | TC-9 |
| AC-5: no commands broken | TC-10, TC-11, TC-12, TC-13, TC-14 |
| AC-6: section 2.3 updated | TC-1, TC-2, TC-3, TC-4, TC-5, TC-6, TC-7, TC-8, TC-15 |
