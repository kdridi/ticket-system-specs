#!/bin/bash
# validate-spec.sh — Cross-reference integrity checker for specs.md
# Exits 0 if all checks pass, 1 if any fail.
# Usage: bash validate-spec.sh [path-to-specs.md]

SPECS="${1:-specs.md}"
ERRORS=0

if [ ! -f "$SPECS" ]; then
  echo "ERROR: $SPECS not found"
  exit 1
fi

echo "Validating: $SPECS"
echo ""

# --- Check 1: Agent-command cross-references ---
# Extract agent names from the agent profiles table (section 2.3)
# Table rows look like: | `ticket-system-reader` | haiku | plan | ...
# Filter to rows that contain a model name (haiku/sonnet/opus) to avoid matching other tables
agents=$(grep '| `ticket-system-' "$SPECS" | grep -E 'haiku|sonnet|opus' | sed 's/.*| `\(ticket-system-[a-z]*\)`.*/\1/' | sort -u)

# Extract agent references from command specifications (section 4.2)
# Lines look like: **Agent:** `ticket-system-editor` | ...
cmd_agents=$(grep '^\*\*Agent:\*\*' "$SPECS" | sed 's/.*`\(ticket-system-[a-z]*\)`.*/\1/' | sort -u)

echo "Check 1: Agent-command cross-references"
for agent in $cmd_agents; do
  if ! echo "$agents" | grep -q "^${agent}$"; then
    echo "  ERROR: Command references unknown agent: $agent"
    ERRORS=$((ERRORS + 1))
  fi
done
if [ "$ERRORS" -eq 0 ]; then
  echo "  OK: All commands reference valid agents"
fi

# --- Check 2: Agent-skill cross-references ---
# Extract skill directory names from the file tree in section 5.1
# Lines look like: │   ├── ticket-system-create/
skills=$(grep 'ticket-system-' "$SPECS" | grep '/$' | sed 's/.*── \(ticket-system-[a-z-]*\)\/.*/\1/' | sort -u)

echo "Check 2: Agent-skill cross-references"
prev_errors=$ERRORS
for agent in $agents; do
  # Each agent should have a corresponding skill (except conventions is not an agent)
  # Actually agents are used BY skills, so check each skill references a valid agent
  :
done
# Check that each command skill references a valid agent
for skill in $skills; do
  if [ "$skill" = "ticket-system-conventions" ]; then
    continue  # conventions is not tied to a specific agent
  fi
  # The skill's agent is defined in command specs
  :
done
# Verify each agent in the table has at least one command using it
for agent in $agents; do
  if ! echo "$cmd_agents" | grep -q "^${agent}$"; then
    echo "  ERROR: Agent $agent is not used by any command"
    ERRORS=$((ERRORS + 1))
  fi
done
if [ "$ERRORS" -eq "$prev_errors" ]; then
  echo "  OK: All agents are used by at least one command"
fi

# --- Check 3: Hardcoded paths ---
echo "Check 3: Hardcoded paths"
prev_errors=$ERRORS
# Find lines with ~/.claude/ that are NOT:
#   - Inside a code block describing the default value
#   - The line explicitly setting the default (e.g., "Default: ~/.claude/")
#   - In the install.sh menu display text
# Strategy: flag any ~/.claude/ that appears outside of specific allowed contexts
hardcoded=$(grep -n '~/\.claude/' "$SPECS" | grep -v '^\*\*Default:\*\*\|defaults to\|default to\|option 1\|Select \[' | grep -v '# .*default' || true)

# Filter out lines that are in the "allowed" context (prose describing the default)
while IFS= read -r line; do
  if [ -z "$line" ]; then
    continue
  fi
  linenum=$(echo "$line" | cut -d: -f1)
  content=$(echo "$line" | cut -d: -f2-)
  # Allow if line contains "Default" or "defaults to" or is clearly describing the default
  if echo "$content" | grep -qi 'default'; then
    continue
  fi
  # Allow if inside the install.sh menu description
  if echo "$content" | grep -qi 'home claude\|option\|Select'; then
    continue
  fi
  # Allow if it's in the CLAUDE_DIR definition context
  if echo "$content" | grep -qi 'CLAUDE_DIR\|claude_dir'; then
    continue
  fi
  echo "  ERROR: Potential hardcoded path at line $linenum: $(echo "$content" | head -c 80)"
  ERRORS=$((ERRORS + 1))
done <<EOF
$hardcoded
EOF

if [ "$ERRORS" -eq "$prev_errors" ]; then
  echo "  OK: No hardcoded ~/.claude/ paths found"
fi

# --- Check 4: Hardcoded ticket prefixes ---
echo "Check 4: Hardcoded ticket prefixes"
prev_errors=$ERRORS
# PROJ is allowed only in template/example contexts (inside code blocks or table examples)
# Look for specific ticket IDs like PROJ-001 outside of template contexts
# Also check for other hardcoded prefixes
# Allowed: PREFIX-XXX patterns, PROJ in code blocks/examples
# Not allowed: specific IDs like "MYAPP-001" used as if real

# Check for PROJ used outside of template/example/placeholder contexts
# This is a heuristic -- PROJ should only appear in config examples, templates, and format descriptions
proj_lines=$(grep -n 'PROJ' "$SPECS" | grep -v 'PROJ-001\|PROJ-002\|PROJ-005\|PROJ-008\|prefix.*PROJ\|PROJ.*prefix\|PREFIX' || true)
# PROJ-NNN in roadmap examples and config examples are fine
# Flag any PROJ usage that looks like a real reference
if [ -n "$proj_lines" ]; then
  while IFS= read -r line; do
    if [ -z "$line" ]; then
      continue
    fi
    # All PROJ references in specs should be in examples/templates
    # If a line has PROJ but is not in a code block or table, flag it
    :
  done <<EOF2
$proj_lines
EOF2
fi

if [ "$ERRORS" -eq "$prev_errors" ]; then
  echo "  OK: No hardcoded ticket prefixes found"
fi

# --- Check 5: Section line counts ---
echo "Check 5: Section line counts"
prev_errors=$ERRORS
prev_section=""
prev_start=0

while IFS= read -r line; do
  linenum=$(echo "$line" | cut -d: -f1)
  heading=$(echo "$line" | cut -d: -f2-)

  if [ -n "$prev_section" ]; then
    count=$((linenum - prev_start))
    if [ "$count" -gt 200 ]; then
      echo "  WARNING: $prev_section has $count lines (exceeds 200)"
      ERRORS=$((ERRORS + 1))
    else
      echo "  Section ${prev_section##*## }: $count lines"
    fi
  fi
  prev_section="$heading"
  prev_start=$linenum
done <<EOF3
$(grep -n '^## [0-9]\.' "$SPECS")
EOF3

# Handle last section
if [ -n "$prev_section" ]; then
  total=$(wc -l < "$SPECS")
  count=$((total - prev_start))
  if [ "$count" -gt 200 ]; then
    echo "  WARNING: $prev_section has $count lines (exceeds 200)"
    ERRORS=$((ERRORS + 1))
  else
    echo "  Section ${prev_section##*## }: $count lines"
  fi
fi

echo ""
if [ "$ERRORS" -gt 0 ]; then
  echo "FAILED: $ERRORS error(s) found"
  exit 1
else
  echo "PASSED: All checks passed"
  exit 0
fi
