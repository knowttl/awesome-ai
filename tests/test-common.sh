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

echo "=== test-common.sh ==="

# Test yaml_read_field
MANIFEST="$(cat <<'EOF'
name: test-skill
type: skill
description: A test skill for testing
tags:
  - testing
  - example
targets:
  - claude-code
  - github-copilot
files:
  - SKILL.md
version: "1.0.0"
EOF
)"

assert_eq "yaml_read_field name" "test-skill" "$(echo "$MANIFEST" | yaml_read_field name)"
assert_eq "yaml_read_field type" "skill" "$(echo "$MANIFEST" | yaml_read_field type)"
assert_eq "yaml_read_field version" "1.0.0" "$(echo "$MANIFEST" | yaml_read_field version)"
assert_eq "yaml_read_field missing returns empty" "" "$(echo "$MANIFEST" | yaml_read_field nonexistent)"

# Test yaml_read_list
TAGS="$(echo "$MANIFEST" | yaml_read_list tags)"
assert_eq "yaml_read_list tags line 1" "testing" "$(echo "$TAGS" | sed -n '1p')"
assert_eq "yaml_read_list tags line 2" "example" "$(echo "$TAGS" | sed -n '2p')"

TARGETS="$(echo "$MANIFEST" | yaml_read_list targets)"
assert_eq "yaml_read_list targets line 1" "claude-code" "$(echo "$TARGETS" | sed -n '1p')"
assert_eq "yaml_read_list targets line 2" "github-copilot" "$(echo "$TARGETS" | sed -n '2p')"

FILES="$(echo "$MANIFEST" | yaml_read_list files)"
assert_eq "yaml_read_list files" "SKILL.md" "$(echo "$FILES" | sed -n '1p')"

# Test is_url
assert_eq "is_url with https" "0" "$(is_url 'https://github.com/owner/repo' && echo 0 || echo 1)"
assert_eq "is_url with git@" "0" "$(is_url 'git@github.com:owner/repo.git' && echo 0 || echo 1)"
assert_eq "is_url with owner/repo" "1" "$(is_url 'owner/repo' && echo 0 || echo 1)"
assert_eq "is_url with plain name" "1" "$(is_url 'my-skill' && echo 0 || echo 1)"

# Test is_shorthand
assert_eq "is_shorthand owner/repo" "0" "$(is_shorthand 'owner/repo' && echo 0 || echo 1)"
assert_eq "is_shorthand plain name" "1" "$(is_shorthand 'my-skill' && echo 0 || echo 1)"
assert_eq "is_shorthand url" "1" "$(is_shorthand 'https://github.com/x/y' && echo 0 || echo 1)"

echo ""
echo "Results: $TESTS_PASSED / $TESTS_RUN passed"
[[ "$TESTS_PASSED" -eq "$TESTS_RUN" ]]
