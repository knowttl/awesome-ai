#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILED=0
PASSED=0

echo "==============================="
echo "  skills-registry test suite"
echo "==============================="
echo ""

for test_file in "$SCRIPT_DIR"/test-*.sh; do
  echo "--- $(basename "$test_file") ---"
  if bash "$test_file"; then
    PASSED=$((PASSED + 1))
  else
    FAILED=$((FAILED + 1))
    echo "  ^^^ FAILED ^^^"
  fi
  echo ""
done

echo "==============================="
echo "  $PASSED passed, $FAILED failed"
echo "==============================="

exit $FAILED
