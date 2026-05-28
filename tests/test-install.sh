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

echo "=== test-install.sh ==="

# Set up temp registry with a skill
REG_DIR="$(mktemp -d)"
mkdir -p "$REG_DIR/skills/sample-skill"
mkdir -p "$REG_DIR/bin/lib" "$REG_DIR/bin/commands"

cp "$SCRIPT_DIR/fixtures/sample-skill/manifest.yaml" "$REG_DIR/skills/sample-skill/"
cp "$SCRIPT_DIR/fixtures/sample-skill/SKILL.md" "$REG_DIR/skills/sample-skill/"
cp "$SCRIPT_DIR/../bin/lib/"*.sh "$REG_DIR/bin/lib/"
cp "$SCRIPT_DIR/../bin/commands/sync.sh" "$REG_DIR/bin/commands/"
cp "$SCRIPT_DIR/../bin/commands/install.sh" "$REG_DIR/bin/commands/"

# Generate registry
REGISTRY_ROOT="$REG_DIR" bash "$REG_DIR/bin/commands/sync.sh" >/dev/null

# Set up target project directory
TARGET_DIR="$(mktemp -d)"

# Install with explicit agent and --yes to skip prompts
export SKILL_YES=1
REGISTRY_ROOT="$REG_DIR" bash "$REG_DIR/bin/commands/install.sh" \
  "sample-skill" --target "$TARGET_DIR" --agent claude-code --agent github-copilot

# Verify files were copied
assert_eq "claude-code skill dir exists" "0" \
  "$([[ -d "$TARGET_DIR/.claude/skills/sample-skill" ]] && echo 0 || echo 1)"
assert_eq "claude-code SKILL.md copied" "0" \
  "$([[ -f "$TARGET_DIR/.claude/skills/sample-skill/SKILL.md" ]] && echo 0 || echo 1)"
assert_eq "copilot skill dir exists" "0" \
  "$([[ -d "$TARGET_DIR/.github/skills/sample-skill" ]] && echo 0 || echo 1)"
assert_eq "copilot SKILL.md copied" "0" \
  "$([[ -f "$TARGET_DIR/.github/skills/sample-skill/SKILL.md" ]] && echo 0 || echo 1)"

# Verify lock file
LOCK_FILE="$TARGET_DIR/.skills-lock.json"
assert_eq "lock file created" "0" "$([[ -f "$LOCK_FILE" ]] && echo 0 || echo 1)"
assert_eq "lock has entry" "0" "$(lock_has_entry "$LOCK_FILE" "sample-skill" && echo 0 || echo 1)"

# Clean up
rm -rf "$REG_DIR" "$TARGET_DIR"
unset SKILL_YES

echo ""
echo "Results: $TESTS_PASSED / $TESTS_RUN passed"
[[ "$TESTS_PASSED" -eq "$TESTS_RUN" ]]
