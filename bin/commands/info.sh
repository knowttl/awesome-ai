#!/usr/bin/env bash
# info.sh — show full details for a single registry item

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CMD_DIR/../lib/common.sh"

REGISTRY_ROOT="${REGISTRY_ROOT:-$(resolve_registry_root)}"
REGISTRY_FILE="$REGISTRY_ROOT/registry.json"

if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
  echo "Usage: skill info <name>"
  exit 0
fi

NAME="$1"

if [[ ! -f "$REGISTRY_FILE" ]]; then
  warn "No registry.json found. Run 'skill sync' first."
  exit 1
fi

# Find the item in registry and display all fields
awk -v search_name="$NAME" '
BEGIN { found=0; in_item=0; name=""; type=""; desc=""; version=""; path="" }

/"name":/ {
  gsub(/[",]/, ""); sub(/.*: /, ""); name=$0
  if (name == search_name) found=1
}

found && /"type":/     { gsub(/[",]/, ""); sub(/.*: /, ""); type=$0 }
found && /"description":/ { gsub(/"/, ""); sub(/.*: /, ""); gsub(/,$/, ""); desc=$0 }
found && /"version":/  { gsub(/[",]/, ""); sub(/.*: /, ""); version=$0 }

found && /"tags":/    { tags_line=$0 }
found && /"targets":/ { targets_line=$0 }
found && /"files":/   { files_line=$0 }
found && /"dependencies":/ { deps_line=$0 }

found && /"path":/ {
  gsub(/[",]/, ""); sub(/.*: /, ""); path=$0

  printf "\n  \033[1m%s\033[0m  (%s v%s)\n\n", name, type, version
  printf "  Description:  %s\n", desc
  printf "  Path:         %s\n", path

  # Extract arrays (simplified)
  gsub(/[\[\]"]/, "", tags_line); sub(/.*: /, "", tags_line); gsub(/,$/, "", tags_line)
  printf "  Tags:         %s\n", tags_line

  gsub(/[\[\]"]/, "", targets_line); sub(/.*: /, "", targets_line); gsub(/,$/, "", targets_line)
  printf "  Targets:      %s\n", targets_line

  gsub(/[\[\]"]/, "", files_line); sub(/.*: /, "", files_line); gsub(/,$/, "", files_line)
  printf "  Files:        %s\n", files_line

  gsub(/[\[\]"]/, "", deps_line); sub(/.*: /, "", deps_line); gsub(/,$/, "", deps_line)
  if (deps_line != "") printf "  Dependencies: %s\n", deps_line

  printf "\n"
  exit
}

END {
  if (!found) {
    printf "Item not found: %s\n", search_name > "/dev/stderr"
    exit 1
  }
}
' "$REGISTRY_FILE"
