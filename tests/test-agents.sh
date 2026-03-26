#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bin/lib/common.sh"
source "$SCRIPT_DIR/../bin/lib/agents.sh"

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

echo "=== test-agents.sh ==="

# Test get_project_path
assert_eq "claude-code project path" ".claude/skills" "$(get_project_path claude-code)"
assert_eq "github-copilot project path" ".github/copilot/skills" "$(get_project_path github-copilot)"
assert_eq "cursor project path" ".agents/skills" "$(get_project_path cursor)"
assert_eq "unknown agent returns empty" "" "$(get_project_path unknown-agent)"

# Test get_global_path — should expand ~ but we just test the suffix
CLAUDE_GLOBAL="$(get_global_path claude-code)"
assert_eq "claude-code global path ends correctly" "0" "$([[ "$CLAUDE_GLOBAL" == *"/.claude/skills" ]] && echo 0 || echo 1)"

COPILOT_GLOBAL="$(get_global_path github-copilot)"
assert_eq "copilot global path ends correctly" "0" "$([[ "$COPILOT_GLOBAL" == *"/.copilot/skills" ]] && echo 0 || echo 1)"

# Test list_known_agents
KNOWN="$(list_known_agents)"
assert_eq "known agents includes claude-code" "0" "$(echo "$KNOWN" | grep -q 'claude-code' && echo 0 || echo 1)"
assert_eq "known agents includes github-copilot" "0" "$(echo "$KNOWN" | grep -q 'github-copilot' && echo 0 || echo 1)"
assert_eq "known agents includes cursor" "0" "$(echo "$KNOWN" | grep -q 'cursor' && echo 0 || echo 1)"

echo ""
echo "Results: $TESTS_PASSED / $TESTS_RUN passed"
[[ "$TESTS_PASSED" -eq "$TESTS_RUN" ]]
