# Implementation Plan — TS-004

## Overview

The core work of TS-004 (replacing a hardcoded file count with a structural file checklist in specs.md section 8) was already accomplished in commit `604235d`. This ticket formalizes that work, verifies all acceptance criteria are satisfied, and fixes a remaining inconsistency in CLAUDE.md.

## Steps

### Step 1: Fix stale checklist count reference in CLAUDE.md
- **Files:** `CLAUDE.md`
- **What:** Replace "39-point checklist" with the correct count. The current section 8 has 37 checklist items (the structural rewrite changed the count). Update the reference to avoid confusion.
- **Tests first:** N/A (editorial change to a documentation file)
- **Done when:** CLAUDE.md accurately describes the number of checklist items in specs.md section 8, or uses a count-agnostic phrasing.

### Step 2: Verify specs.md section 8 has no residual count-based checks
- **Files:** `specs.md` (read-only verification)
- **What:** Confirm there are zero references to a hardcoded file count in section 8. Confirm all required files are listed by name under "Structural completeness."
- **Tests first:** N/A (verification step)
- **Done when:** No matches for "file count", "exactly N files", or raw numeric file assertions exist in specs.md.

### Step 3: Verify CLAUDE.md smoke test references structural check
- **Files:** `CLAUDE.md` (read-only verification)
- **What:** Confirm the smoke test section references checking files "by name" and points to specs.md section 8 structural checklist. Confirm no residual count-based language.
- **Tests first:** N/A (verification step)
- **Done when:** CLAUDE.md smoke test says "All required files present by name" and contains no file-count assertion.

### Step 4: Update ticket metadata
- **Files:** `tickets/ongoing/TS-004/ticket.md`
- **What:** Fill in "Files Modified" and "Decisions" sections. Add log entries.
- **Tests first:** N/A
- **Done when:** Ticket reflects all changes made.

## Risk Notes

- The actual spec change was already done in a prior commit. The main risk is that we miss a stale reference somewhere. Steps 2 and 3 mitigate this with explicit grep-based verification.
- TS-002 (backlog) references "file count" in its acceptance criteria, but that is a separate ticket and outside scope for TS-004.
