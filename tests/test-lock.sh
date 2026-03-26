#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bin/lib/common.sh"
source "$SCRIPT_DIR/../bin/lib/lock.sh"

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

echo "=== test-lock.sh ==="

TMP_DIR="$(mktemp -d)"
LOCK_FILE="$TMP_DIR/.skills-lock.json"

# Test: new lock file creation
lock_init "$LOCK_FILE"
assert_eq "lock file created" "0" "$([[ -f "$LOCK_FILE" ]] && echo 0 || echo 1)"

CONTENT="$(cat "$LOCK_FILE")"
assert_eq "lock file has version" "0" "$(echo "$CONTENT" | grep -q '"version": 1' && echo 0 || echo 1)"
assert_eq "lock file has installed" "0" "$(echo "$CONTENT" | grep -q '"installed"' && echo 0 || echo 1)"

# Test: add an entry
lock_add_entry "$LOCK_FILE" \
  "test-skill" "skill" "1.0.0" \
  "local" "" "" \
  "claude-code,github-copilot" ""

CONTENT="$(cat "$LOCK_FILE")"
assert_eq "entry added" "0" "$(echo "$CONTENT" | grep -q '"test-skill"' && echo 0 || echo 1)"
assert_eq "entry has type" "0" "$(echo "$CONTENT" | grep -q '"type": "skill"' && echo 0 || echo 1)"
assert_eq "entry has source" "0" "$(echo "$CONTENT" | grep -q '"source": "local"' && echo 0 || echo 1)"

# Test: check if entry exists
assert_eq "lock_has_entry true" "0" "$(lock_has_entry "$LOCK_FILE" "test-skill" && echo 0 || echo 1)"
assert_eq "lock_has_entry false" "1" "$(lock_has_entry "$LOCK_FILE" "nonexistent" && echo 0 || echo 1)"

# Test: remove entry
lock_remove_entry "$LOCK_FILE" "test-skill"
assert_eq "entry removed" "0" "$(lock_has_entry "$LOCK_FILE" "test-skill" && echo 1 || echo 0)"

rm -rf "$TMP_DIR"

echo ""
echo "Results: $TESTS_PASSED / $TESTS_RUN passed"
[[ "$TESTS_PASSED" -eq "$TESTS_RUN" ]]
