# Implementation Plan — TS-008

## Overview
Extend the `/ticket-system-create` command specification in `specs.md` to support an interactive, dialogue-driven creation mode. When the user's input is vague or incomplete, the command enters a scaffolded dialogue that surfaces the ticket's title, type, priority, objective, and acceptance criteria before writing any file. The existing fast path (clear, complete input) is preserved.

This ticket modifies `specs.md` only (and `CLAUDE.md` if needed to reflect any new guidance). No new files are added to the repository.

## Steps

### Step 1: Extend `/ticket-system-create` in section 4.2
- **Files:** `specs.md` (section 4.2, `/ticket-system-create` block, lines ~306-319)
- **What:** Replace the existing "Without arguments: ask for the title, type, and priority" line with a full dialogue-mode specification. Add the following sub-behaviors:
  1. **Input classification:** After receiving the user's argument, classify it as "clear" (has a recognizable title and type/priority cues) or "vague" (short, no type/priority, ambiguous scope). Define the heuristic: inputs with fewer than 8 words and no explicit type/priority keywords trigger dialogue mode.
  2. **Fast path (clear input):** Proceed as currently specified -- fill in fields and write the ticket immediately.
  3. **Dialogue mode (vague input):** Ask targeted clarifying questions one or two at a time to surface: title, type, priority, objective, acceptance criteria, and technical approach. Maintain a structured draft in-session (no files written). Cap the dialogue at 3 rounds of questions.
  4. **Draft presentation:** After gathering enough information, present the full draft ticket to the user for review. The user can confirm, adjust specific fields, or request another iteration.
  5. **Confirmation gate:** Only upon user confirmation, write the ticket to disk and commit exactly as in the current flow.
  6. **No intermediate files:** Emphasize that dialogue state is held in-session only.
- **Tests first:** Not applicable (spec-only change). Validation via `validate-spec.sh`.
- **Done when:** The `/ticket-system-create` block in section 4.2 includes clear instructions for both the fast path and the dialogue mode, and `validate-spec.sh` passes.

### Step 2: Update the "Without arguments" behavior
- **Files:** `specs.md` (section 4.2, same block)
- **What:** The current spec says "Without arguments: ask for the title, type, and priority." This must be updated to say that without arguments, the command always enters dialogue mode. This is a subset of the vague-input case.
- **Tests first:** N/A
- **Done when:** The "without arguments" case is clearly defined as entering dialogue mode.

### Step 3: Verify section 4 line budget
- **Files:** `specs.md`
- **What:** After extending the create command specification, verify that section 4 stays within the 200-line budget enforced by `validate-spec.sh`. If it exceeds 200 lines, tighten the language to stay within budget. The current section 4 spans from line ~298 to ~486 (~188 lines), so there is approximately 12 lines of headroom.
- **Tests first:** Run `validate-spec.sh`.
- **Done when:** `validate-spec.sh` passes with no section line count warnings.

### Step 4: Update CLAUDE.md if needed
- **Files:** `CLAUDE.md`
- **What:** Review whether any new guidance is needed in CLAUDE.md to reflect the interactive create behavior. Per the repo rules, CLAUDE.md must stay in sync with specs.md. If the create command now has a dialogue mode, note this in the validation quick reference or workflow section if relevant.
- **Tests first:** N/A
- **Done when:** CLAUDE.md accurately reflects the current state of specs.md.

### Step 5: Run validate-spec.sh
- **Files:** `validate-spec.sh`
- **What:** Run the validation script to confirm no cross-reference drift, no hardcoded paths/prefixes, and all section line counts are within budget.
- **Tests first:** N/A
- **Done when:** `validate-spec.sh` exits 0.

## Risk Notes
- **Section 4 line budget:** The main risk is exceeding the 200-line limit for section 4. The current section uses ~188 lines, leaving only ~12 lines of headroom. The dialogue mode specification must be written concisely. If it cannot fit, we may need to trim other command descriptions or restructure slightly.
- **Spec coherence:** The dialogue mode must not contradict the editor agent's permission model (it already has `acceptEdits` and the necessary Bash patterns). The editor agent does not need changes since the dialogue is purely prompt-level behavior.
- **No new agent or skill needed:** The interactive behavior is an enhancement to the existing `/ticket-system-create` skill instructions. The same `ticket-system-editor` agent handles it. No new files appear in the file tree (section 5.1).
