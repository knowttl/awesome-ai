#!/usr/bin/env bash
# list.sh — list all items in the registry, with optional filters

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CMD_DIR/../lib/common.sh"

REGISTRY_ROOT="${REGISTRY_ROOT:-$(resolve_registry_root)}"
REGISTRY_FILE="$REGISTRY_ROOT/registry.json"

FILTER_TYPE=""
FILTER_TAG=""
FILTER_FOR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)  FILTER_TYPE="$2"; shift 2 ;;
    --tag)   FILTER_TAG="$2"; shift 2 ;;
    --for)   FILTER_FOR="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: skill list [--type <skill|agent|instruction>] [--tag <tag>] [--for <agent>]"
      exit 0 ;;
    *) die "Unknown flag: $1" ;;
  esac
done

if [[ ! -f "$REGISTRY_FILE" ]]; then
  warn "No registry.json found. Run 'skill sync' first."
  exit 1
fi

# Parse and filter using awk
awk -v filter_type="$FILTER_TYPE" -v filter_tag="$FILTER_TAG" -v filter_for="$FILTER_FOR" '
BEGIN {
  in_item=0; name=""; type=""; desc=""; version=""; tags=""; targets=""
  printf "%-30s %-12s %-8s %s\n", "NAME", "TYPE", "VERSION", "DESCRIPTION"
  printf "%-30s %-12s %-8s %s\n", "----", "----", "-------", "-----------"
}

/"name":/ {
  gsub(/[",]/, ""); sub(/.*: /, ""); name=$0
}
/"type":/ {
  gsub(/[",]/, ""); sub(/.*: /, ""); type=$0
}
/"description":/ {
  gsub(/"/, ""); sub(/.*: /, ""); desc=$0
  if (length(desc) > 50) desc = substr(desc, 1, 47) "..."
}
/"version":/ {
  gsub(/[",]/, ""); sub(/.*: /, ""); version=$0
}
/"tags":/ { tags=$0 }
/"targets":/ { targets=$0 }

/"path":/ {
  # End of an item — apply filters and print
  show=1
  if (filter_type != "" && type != filter_type) show=0
  if (filter_tag != "" && index(tags, filter_tag) == 0) show=0
  if (filter_for != "" && index(targets, filter_for) == 0) show=0

  if (show) {
    printf "%-30s %-12s %-8s %s\n", name, type, version, desc
  }
  name=""; type=""; desc=""; version=""; tags=""; targets=""
}
' "$REGISTRY_FILE"
