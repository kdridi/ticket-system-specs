#!/bin/bash
# Test suite for validate-spec.sh
# Covers TC-1 through TC-9 from the test plan

PASS=0
FAIL=0
SPECS="specs.md"

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Test Suite: validate-spec.sh ==="
echo ""

# TC-1: Clickable TOC exists in specs.md
echo "TC-1: Clickable TOC exists in specs.md"
toc_links=$(head -50 "$SPECS" | grep -c '\](#')
if [ "$toc_links" -ge 8 ]; then
  pass "Found $toc_links TOC anchor links (>= 8 required)"
else
  fail "Found only $toc_links TOC anchor links (>= 8 required)"
fi

# TC-2: TOC anchors resolve to actual headings
echo "TC-2: TOC anchors resolve to actual headings"
# Extract all anchors from TOC, check each resolves
broken=0
for anchor in $(grep '^\- \[' "$SPECS" | grep -o '](#[^)]*' | sed 's/](#//'); do
  # Generate anchors from all headings
  match=$(grep '^##' "$SPECS" | sed 's/^#* //' | sed 's/`//g' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 -]//g' | sed 's/  */ /g' | sed 's/ /-/g' | grep -c "^${anchor}$")
  if [ "$match" -eq 0 ]; then
    broken=$((broken + 1))
    echo "    Broken anchor: #$anchor"
  fi
done
if [ "$broken" -eq 0 ]; then
  pass "All TOC anchors resolve to headings"
else
  fail "$broken broken TOC anchors"
fi

# TC-3: validate-spec.sh exists and is executable
echo "TC-3: validate-spec.sh exists and is executable"
if [ -f validate-spec.sh ] && [ -x validate-spec.sh ]; then
  pass "validate-spec.sh exists and is executable"
else
  fail "validate-spec.sh missing or not executable"
fi

# TC-4: validate-spec.sh detects valid cross-references
echo "TC-4: validate-spec.sh detects valid cross-references"
output=$(bash validate-spec.sh 2>&1)
rc=$?
if [ "$rc" -eq 0 ]; then
  pass "validate-spec.sh exits 0 on valid specs.md"
else
  fail "validate-spec.sh exits $rc (expected 0)"
  echo "    Output: $output"
fi

# TC-5: validate-spec.sh detects hardcoded paths
echo "TC-5: validate-spec.sh detects hardcoded paths"
# Create a temp copy with a hardcoded path injected
cp "$SPECS" /tmp/specs-test-modified.md
# Insert a hardcoded path in a non-prose context (not containing "default")
awk 'NR==10{print "Install agents to ~/.claude/agents/ directly."}1' "$SPECS" > /tmp/specs-test-modified.md
output=$(bash validate-spec.sh /tmp/specs-test-modified.md 2>&1)
rc=$?
if [ "$rc" -ne 0 ]; then
  pass "validate-spec.sh detects hardcoded ~/.claude/ path (exit $rc)"
else
  fail "validate-spec.sh did not detect hardcoded path (exit 0)"
fi
rm -f /tmp/specs-test-modified.md

# TC-6: validate-spec.sh reports section line counts
echo "TC-6: validate-spec.sh reports section line counts"
output=$(bash validate-spec.sh 2>&1)
section_count=$(echo "$output" | grep -c 'Section [0-9]')
if [ "$section_count" -ge 8 ]; then
  pass "Reports line counts for $section_count sections"
else
  fail "Reports line counts for only $section_count sections (>= 8 required)"
fi

# TC-7: No section in specs.md exceeds 200 lines
echo "TC-7: No section in specs.md exceeds 200 lines"
over_200=$(awk '/^## [0-9]+\./{if(name && NR-1-start > 200) print name, NR-1-start; name=$0; start=NR} END{if(NR-start > 200) print name, NR-start}' "$SPECS")
if [ -z "$over_200" ]; then
  pass "All sections are within 200-line budget"
else
  fail "Sections over 200 lines: $over_200"
fi

# TC-8: CLAUDE.md documents feature-branch workflow
echo "TC-8: CLAUDE.md documents feature-branch workflow"
match=$(grep -c 'Parallel Spec Work' CLAUDE.md)
if [ "$match" -ge 1 ]; then
  pass "CLAUDE.md contains 'Parallel Spec Work' section"
else
  fail "CLAUDE.md missing 'Parallel Spec Work' section"
fi

# TC-9: validate-spec.sh is POSIX-compatible
echo "TC-9: validate-spec.sh is POSIX-compatible"
has_shebang=$(head -1 validate-spec.sh | grep -c '#!/bin/bash')
non_posix=$(grep -c 'python\|node\|jq\|ruby\|perl' validate-spec.sh || true)
if [ "$has_shebang" -eq 1 ] && [ "$non_posix" -eq 0 ]; then
  pass "Has bash shebang and no non-POSIX tools"
else
  fail "Missing shebang or uses non-POSIX tools"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
