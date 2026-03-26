#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bin/lib/common.sh"

TESTS_RUN=0
TESTS_PASSED=0

assert_eq() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  PASS: $label"
  else
    echo "  FAIL: $label"
    echo "    expected: '$expected'"
    echo "    actual:   '$actual'"
  fi
}

echo "=== test-sync.sh ==="

TMP_DIR="$(mktemp -d)"
mkdir -p "$TMP_DIR/skills/sample-skill"
mkdir -p "$TMP_DIR/instructions/sample-instruction"
mkdir -p "$TMP_DIR/bin/lib" "$TMP_DIR/bin/commands"

cp "$SCRIPT_DIR/fixtures/sample-skill/manifest.yaml" "$TMP_DIR/skills/sample-skill/"
cp "$SCRIPT_DIR/fixtures/sample-skill/SKILL.md" "$TMP_DIR/skills/sample-skill/"
cp "$SCRIPT_DIR/fixtures/sample-instruction/manifest.yaml" "$TMP_DIR/instructions/sample-instruction/"
cp "$SCRIPT_DIR/fixtures/sample-instruction/sample-instruction.instructions.md" \
   "$TMP_DIR/instructions/sample-instruction/"
cp "$SCRIPT_DIR/../bin/lib/common.sh" "$TMP_DIR/bin/lib/"
cp "$SCRIPT_DIR/../bin/commands/sync.sh" "$TMP_DIR/bin/commands/"

REGISTRY_ROOT="$TMP_DIR" bash "$TMP_DIR/bin/commands/sync.sh"

assert_eq "registry.json exists" "0" "$([[ -f "$TMP_DIR/registry.json" ]] && echo 0 || echo 1)"

REGISTRY="$(cat "$TMP_DIR/registry.json")"
assert_eq "contains sample-skill" "0" "$(echo "$REGISTRY" | grep -q '"sample-skill"' && echo 0 || echo 1)"
assert_eq "contains sample-instruction" "0" "$(echo "$REGISTRY" | grep -q '"sample-instruction"' && echo 0 || echo 1)"
assert_eq "has type skill" "0" "$(echo "$REGISTRY" | grep -q '"type": "skill"' && echo 0 || echo 1)"
assert_eq "has type instruction" "0" "$(echo "$REGISTRY" | grep -q '"type": "instruction"' && echo 0 || echo 1)"
assert_eq "total 2 items" "2" "$(echo "$REGISTRY" | grep -c '"name":' || true)"

rm -rf "$TMP_DIR"

echo ""
echo "Results: $TESTS_PASSED / $TESTS_RUN passed"
[[ "$TESTS_PASSED" -eq "$TESTS_RUN" ]]
