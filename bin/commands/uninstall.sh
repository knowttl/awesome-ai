#!/usr/bin/env bash
# uninstall.sh — remove an installed item and update the lock file

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CMD_DIR/../lib/common.sh"
source "$CMD_DIR/../lib/agents.sh"
source "$CMD_DIR/../lib/lock.sh"

TARGET_DIR="$(pwd)"
GLOBAL_INSTALL=false
AGENTS=()
NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)    TARGET_DIR="$2"; shift 2 ;;
    --global|-g) GLOBAL_INSTALL=true; shift ;;
    --agent|-a)  AGENTS+=("$2"); shift 2 ;;
    --yes|-y)    export SKILL_YES=1; shift ;;
    --help|-h)
      echo "Usage: skill uninstall <name> [--target <path>] [--global] [--agent <agent>]"
      exit 0 ;;
    -*)
      die "Unknown flag: $1" ;;
    *)
      NAME="$1"; shift ;;
  esac
done

if [[ -z "$NAME" ]]; then
  die "Usage: skill uninstall <name>"
fi

LOCK_FILE="$TARGET_DIR/.skills-lock.json"
[[ "$GLOBAL_INSTALL" == "true" ]] && LOCK_FILE="$HOME/.skills-lock.json"

# Determine which agents to remove from
if [[ ${#AGENTS[@]} -gt 0 ]]; then
  REMOVE_AGENTS=("${AGENTS[@]}")
else
  # Get agents from lock file entry, or fall back to all known
  if lock_has_entry "$LOCK_FILE" "$NAME"; then
    REMOVE_AGENTS=($(lock_get_field "$LOCK_FILE" "$NAME" "agents" | tr -d '[]"' | tr ',' ' '))
  else
    REMOVE_AGENTS=($(list_known_agents))
  fi
fi

# Remove files for each agent
REMOVED=false
for agent in "${REMOVE_AGENTS[@]}"; do
  base_path=""
  if [[ "$GLOBAL_INSTALL" == "true" ]]; then
    base_path="$(get_global_path "$agent")"
  else
    base_path="$TARGET_DIR/$(get_project_path "$agent")"
  fi

  [[ -z "$base_path" ]] && continue

  skill_dir="$base_path/$NAME"
  if [[ -d "$skill_dir" ]]; then
    if prompt_yn "  Remove $skill_dir?"; then
      rm -rf "$skill_dir"
      echo "  → Removed: ${skill_dir#$TARGET_DIR/}"
      REMOVED=true

      # Clean up empty parent dirs
      parent="$(dirname "$skill_dir")"
      if [[ -d "$parent" ]] && [[ -z "$(ls -A "$parent" 2>/dev/null)" ]]; then
        rmdir "$parent" 2>/dev/null || true
      fi
    fi
  fi
done

# Update lock file
if [[ "$REMOVED" == "true" ]] && lock_has_entry "$LOCK_FILE" "$NAME"; then
  lock_remove_entry "$LOCK_FILE" "$NAME"
  info "Uninstalled $NAME"
  echo "  Lock file updated: $(basename "$LOCK_FILE")"
elif [[ "$REMOVED" == "false" ]]; then
  warn "No installed files found for: $NAME"
fi
