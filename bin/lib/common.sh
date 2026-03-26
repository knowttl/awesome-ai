#!/usr/bin/env bash
# common.sh — shared utilities for skills-registry CLI

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  RED='' GREEN='' YELLOW='' CYAN='' BOLD='' RESET=''
fi

# Logging
info()  { echo -e "${GREEN}✓${RESET} $*"; }
warn()  { echo -e "${YELLOW}⚠${RESET} $*" >&2; }
die()   { echo -e "${RED}✗${RESET} $*" >&2; exit 1; }

# Prompt yes/no. Returns 0 for yes, 1 for no.
# Usage: prompt_yn "Overwrite file?" && do_thing
prompt_yn() {
  local prompt="$1"
  if [[ "${SKILL_YES:-}" == "1" ]]; then
    return 0
  fi
  echo -ne "$prompt ${CYAN}(y/n)${RESET} "
  read -r answer
  [[ "$answer" =~ ^[Yy] ]]
}

# Lightweight YAML parser — reads a scalar field value from stdin.
# Handles: `key: value`, `key: "value"`, `key: 'value'`
# Usage: cat manifest.yaml | yaml_read_field name
yaml_read_field() {
  local key="$1"
  sed -n "s/^${key}:[[:space:]]*[\"']\{0,1\}\([^\"']*\)[\"']\{0,1\}[[:space:]]*$/\1/p" | head -1
}

# Reads a YAML list field from stdin. Outputs one item per line.
# Handles: `  - item` lines under the given key.
# Usage: cat manifest.yaml | yaml_read_list tags
yaml_read_list() {
  local key="$1"
  awk -v key="$key:" '
    BEGIN { found=0 }
    $0 ~ "^"key { found=1; next }
    found && /^[[:space:]]*-[[:space:]]/ {
      sub(/^[[:space:]]*-[[:space:]]*/, "")
      gsub(/^["'"'"']|["'"'"']$/, "")
      print
      next
    }
    found && /^[^[:space:]]/ { found=0 }
  '
}

# Check if a string looks like a URL
is_url() {
  [[ "$1" =~ ^https?:// ]] || [[ "$1" =~ ^git@ ]]
}

# Check if a string looks like owner/repo shorthand (exactly one slash, no protocol)
is_shorthand() {
  ! is_url "$1" && [[ "$1" =~ ^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$ ]]
}

# Resolve REGISTRY_ROOT — the root of the skills-registry repo.
# Walks up from the script's location to find the repo root.
resolve_registry_root() {
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
  # Walk up until we find registry.json or bin/
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/bin/lib" ]] && [[ -d "$dir/skills" || -d "$dir/agents" || -d "$dir/instructions" ]]; then
      echo "$dir"
      return 0
    fi
    if [[ -f "$dir/bin/skill" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  die "Could not find skills-registry root directory"
}
