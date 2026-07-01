#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bin/lib/common.sh"
source "$SCRIPT_DIR/../bin/lib/agents.sh"
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

echo "=== test-uninstall.sh ==="

# Setup: create a fake installed state — .agents/skills/ is source of truth
TARGET_DIR="$(mktemp -d)"
mkdir -p "$TARGET_DIR/.agents/skills/sample-skill"
echo "# Test" > "$TARGET_DIR/.agents/skills/sample-skill/SKILL.md"
mkdir -p "$TARGET_DIR/.claude/skills"
ln -s "../../.agents/skills/sample-skill" "$TARGET_DIR/.claude/skills/sample-skill"

# Create lock file
LOCK_FILE="$TARGET_DIR/.skills-lock.json"
lock_init "$LOCK_FILE"
lock_add_entry "$LOCK_FILE" \
  "sample-skill" "skill" "1.0.0" \
  "local" "" "" \
  "claude-code,github-copilot" ""

assert_eq "setup: lock entry exists" "0" "$(lock_has_entry "$LOCK_FILE" "sample-skill" && echo 0 || echo 1)"
assert_eq "setup: files exist" "0" "$([[ -f "$TARGET_DIR/.agents/skills/sample-skill/SKILL.md" ]] && echo 0 || echo 1)"

# Run uninstall
export SKILL_YES=1
REG_DIR="$(mktemp -d)"
mkdir -p "$REG_DIR/bin/lib" "$REG_DIR/bin/commands" "$REG_DIR/skills"
cp "$SCRIPT_DIR/../bin/lib/"*.sh "$REG_DIR/bin/lib/"
cp "$SCRIPT_DIR/../bin/commands/uninstall.sh" "$REG_DIR/bin/commands/"

REGISTRY_ROOT="$REG_DIR" bash "$REG_DIR/bin/commands/uninstall.sh" \
  "sample-skill" --target "$TARGET_DIR"

# Verify removal — claude-code symlink and .agents/skills/ dir both gone
assert_eq "claude-code symlink removed" "1" "$([[ -L "$TARGET_DIR/.claude/skills/sample-skill" ]] && echo 0 || echo 1)"
assert_eq "agents skills dir removed" "1" "$([[ -d "$TARGET_DIR/.agents/skills/sample-skill" ]] && echo 0 || echo 1)"
assert_eq "lock entry removed" "1" "$(lock_has_entry "$LOCK_FILE" "sample-skill" && echo 0 || echo 1)"

rm -rf "$TARGET_DIR" "$REG_DIR"
unset SKILL_YES

echo ""
echo "Results: $TESTS_PASSED / $TESTS_RUN passed"
[[ "$TESTS_PASSED" -eq "$TESTS_RUN" ]]
