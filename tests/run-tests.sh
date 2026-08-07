#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==============================="
echo "  skills-registry test suite"
echo "==============================="
echo ""

echo "--- test-catalog.js ---"
node "$SCRIPT_DIR/test-catalog.js"
