#!/usr/bin/env bash
# install.sh — install skills/agents/instructions into a target project

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CMD_DIR/../lib/common.sh"
source "$CMD_DIR/../lib/agents.sh"
source "$CMD_DIR/../lib/git.sh"
source "$CMD_DIR/../lib/lock.sh"

REGISTRY_ROOT="${REGISTRY_ROOT:-$(resolve_registry_root)}"
REGISTRY_FILE="$REGISTRY_ROOT/registry.json"

# Parse arguments
TARGET_DIR="$(pwd)"
GLOBAL_INSTALL=false
USE_SYMLINK=false
AGENTS=()
SKILLS=()
PROFILE=""
REF=""
POSITIONAL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)   TARGET_DIR="$2"; shift 2 ;;
    --global|-g) GLOBAL_INSTALL=true; shift ;;
    --symlink)  USE_SYMLINK=true; shift ;;
    --agent|-a) AGENTS+=("$2"); shift 2 ;;
    --skill|-s) SKILLS+=("$2"); shift 2 ;;
    --profile)  PROFILE="$2"; shift 2 ;;
    --ref)      REF="$2"; shift 2 ;;
    --yes|-y)   export SKILL_YES=1; shift ;;
    --help|-h)
      cat <<EOF
Usage: skill install [<name|url>] [options]

  skill install <name>              Install from local registry
  skill install <owner/repo>        Install from GitHub
  skill install <url>               Install from any Git URL
  skill install --profile <name>    Install a profile
  skill install                     Restore from .skills-lock.json

Options:
  --target <path>     Target project (default: cwd)
  --global, -g        Install to global user directory
  --agent, -a <name>  Target agent(s), repeatable
  --skill, -s <name>  Select specific item(s) from a repo
  --profile <name>    Install a named profile
  --ref <commit>      Pin to a specific git commit/tag/branch
  --symlink           Symlink instead of copy
  --yes, -y           Skip prompts
EOF
      exit 0 ;;
    -*)
      die "Unknown flag: $1" ;;
    *)
      POSITIONAL="$1"; shift ;;
  esac
done

# --- Profile install ---
if [[ -n "$PROFILE" ]]; then
  source "$CMD_DIR/../lib/profile.sh"
  install_profile "$PROFILE" "$TARGET_DIR" "$GLOBAL_INSTALL" "$USE_SYMLINK" "${AGENTS[*]}"
  exit $?
fi

# --- Lock-file restore (no args) ---
if [[ -z "$POSITIONAL" ]] && [[ -z "$PROFILE" ]]; then
  LOCK_FILE="$TARGET_DIR/.skills-lock.json"
  if [[ ! -f "$LOCK_FILE" ]]; then
    die "No item specified and no .skills-lock.json found in $TARGET_DIR"
  fi

  echo "Restoring from $(basename "$LOCK_FILE")..."
  ENTRIES="$(lock_list_entries "$LOCK_FILE")"
  ENTRY_COUNT=0

  while IFS= read -r entry_name; do
    [[ -z "$entry_name" ]] && continue
    local_source="$(lock_get_field "$LOCK_FILE" "$entry_name" "source")"
    local_url="$(lock_get_field "$LOCK_FILE" "$entry_name" "sourceUrl")"
    local_commit="$(lock_get_field "$LOCK_FILE" "$entry_name" "sourceCommit")"
    local_agents="$(lock_get_field "$LOCK_FILE" "$entry_name" "agents")"

    # Build agent flags
    AGENT_FLAGS=""
    for a in $(echo "$local_agents" | tr -d '[]"' | tr ',' ' '); do
      AGENT_FLAGS+="--agent $a "
    done

    if [[ "$local_source" == "remote" ]] && [[ -n "$local_url" ]]; then
      # Remote: re-install from URL at pinned commit
      REGISTRY_ROOT="$REGISTRY_ROOT" bash "$CMD_DIR/install.sh" \
        "$local_url" --target "$TARGET_DIR" --skill "$entry_name" \
        --ref "$local_commit" $AGENT_FLAGS --yes
    else
      # Local: re-install from registry
      REGISTRY_ROOT="$REGISTRY_ROOT" bash "$CMD_DIR/install.sh" \
        "$entry_name" --target "$TARGET_DIR" $AGENT_FLAGS --yes
    fi

    ENTRY_COUNT=$((ENTRY_COUNT + 1))
  done <<< "$ENTRIES"

  info "Restored $ENTRY_COUNT items from lock file"
  exit 0
fi

# --- Resolve source ---
ITEM_NAME=""
ITEM_DIR=""
SOURCE_TYPE="local"
SOURCE_URL=""
SOURCE_COMMIT=""
TEMP_CLONE=""

if is_url "$POSITIONAL" || is_shorthand "$POSITIONAL"; then
  # Remote source
  SOURCE_TYPE="remote"
  SOURCE_URL="$(normalize_repo_url "$POSITIONAL")"
  echo "Cloning $(echo "$SOURCE_URL" | sed 's/\.git$//')..."
  TEMP_CLONE="$(clone_shallow "$SOURCE_URL" "$REF")"
  SOURCE_COMMIT="$(resolve_commit "$TEMP_CLONE")"

  # Scan for items
  FOUND_ITEMS="$(scan_repo_for_items "$TEMP_CLONE")"
  if [[ -z "$FOUND_ITEMS" ]]; then
    cleanup_temp "$TEMP_CLONE"
    die "No skills/agents/instructions found in $POSITIONAL"
  fi

  # If --skill flag given, filter
  if [[ ${#SKILLS[@]} -gt 0 ]]; then
    FILTERED=""
    for skill_name in "${SKILLS[@]}"; do
      while IFS= read -r dir; do
        if [[ -f "$dir/manifest.yaml" ]]; then
          local_name="$(cat "$dir/manifest.yaml" | yaml_read_field name)"
        else
          local_name="$(basename "$dir")"
        fi
        if [[ "$local_name" == "$skill_name" ]]; then
          FILTERED+="$dir"$'\n'
        fi
      done <<< "$FOUND_ITEMS"
    done
    FOUND_ITEMS="$FILTERED"
  fi

  # For now, install first found item (multi-item support in profile task)
  ITEM_DIR="$(echo "$FOUND_ITEMS" | head -1 | tr -d '[:space:]')"
  if [[ -f "$ITEM_DIR/manifest.yaml" ]]; then
    ITEM_NAME="$(cat "$ITEM_DIR/manifest.yaml" | yaml_read_field name)"
  else
    ITEM_NAME="$(basename "$ITEM_DIR")"
  fi
else
  # Local source — look up in registry
  ITEM_NAME="$POSITIONAL"
  if [[ ! -f "$REGISTRY_FILE" ]]; then
    die "No registry.json found. Run 'skill sync' first."
  fi

  # Find the item path in registry
  ITEM_PATH="$(awk -v name="$ITEM_NAME" '
    /"name":/ { gsub(/[",]/, ""); sub(/.*: /, ""); n=$0 }
    /"path":/ && n==name { gsub(/[",]/, ""); sub(/.*: /, ""); print; exit }
  ' "$REGISTRY_FILE")"

  if [[ -z "$ITEM_PATH" ]]; then
    die "Item not found in registry: $ITEM_NAME"
  fi

  ITEM_DIR="$REGISTRY_ROOT/$ITEM_PATH"
fi

# --- Read manifest ---
MANIFEST="$ITEM_DIR/manifest.yaml"
if [[ ! -f "$MANIFEST" ]]; then
  die "No manifest.yaml found in $ITEM_DIR"
fi

MANIFEST_CONTENT="$(cat "$MANIFEST")"
ITEM_TYPE="$(echo "$MANIFEST_CONTENT" | yaml_read_field type)"
ITEM_VERSION="$(echo "$MANIFEST_CONTENT" | yaml_read_field version)"
[[ -z "$ITEM_VERSION" ]] && ITEM_VERSION="0.0.0"

# Read targets and files from manifest
ITEM_TARGETS="$(echo "$MANIFEST_CONTENT" | yaml_read_list targets)"
ITEM_FILES="$(echo "$MANIFEST_CONTENT" | yaml_read_list files)"

# --- Select agents ---
if [[ ${#AGENTS[@]} -eq 0 ]]; then
  COMPATIBLE="$ITEM_TARGETS"
  SELECTED="$(select_agents "$COMPATIBLE")"
else
  SELECTED="$(printf '%s\n' "${AGENTS[@]}")"
fi

if [[ -z "$SELECTED" ]]; then
  warn "No agents selected. Nothing to install."
  [[ -n "$TEMP_CLONE" ]] && cleanup_temp "$TEMP_CLONE"
  exit 0
fi

# --- Install files for each selected agent ---
LOCK_FILE="$TARGET_DIR/.skills-lock.json"
if [[ "$GLOBAL_INSTALL" == "true" ]]; then
  LOCK_FILE="$HOME/.skills-lock.json"
fi

while IFS= read -r agent; do
  [[ -z "$agent" ]] && continue

  base_path=""
  if [[ "$GLOBAL_INSTALL" == "true" ]]; then
    base_path="$(get_global_path "$agent")"
  else
    base_path="$TARGET_DIR/$(get_project_path "$agent")"
  fi

  if [[ -z "$base_path" ]]; then
    warn "Unknown agent: $agent — skipping"
    continue
  fi

  dest_dir="$base_path/$ITEM_NAME"
  mkdir -p "$dest_dir"

  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    src="$ITEM_DIR/$file"
    dst="$dest_dir/$file"

    if [[ ! -f "$src" ]]; then
      warn "File not found: $src — skipping"
      continue
    fi

    # Handle conflicts
    if [[ -f "$dst" ]]; then
      if diff -q "$src" "$dst" >/dev/null 2>&1; then
        continue  # identical, skip
      fi
      if ! prompt_yn "  File exists and differs: $dst. Overwrite?"; then
        continue
      fi
    fi

    # Create parent dirs for nested files
    mkdir -p "$(dirname "$dst")"

    if [[ "$USE_SYMLINK" == "true" ]]; then
      ln -sf "$src" "$dst"
    else
      cp "$src" "$dst"
    fi
  done <<< "$ITEM_FILES"

  # Print per-agent result
  if [[ "$GLOBAL_INSTALL" == "true" ]]; then
    echo "  → $agent: $dest_dir"
  else
    echo "  → $agent: ${dest_dir#$TARGET_DIR/}"
  fi
done <<< "$SELECTED"

# --- Update lock file ---
AGENTS_CSV="$(echo "$SELECTED" | tr '\n' ',' | sed 's/,$//')"
lock_add_entry "$LOCK_FILE" \
  "$ITEM_NAME" "$ITEM_TYPE" "$ITEM_VERSION" \
  "$SOURCE_TYPE" "$SOURCE_URL" "$SOURCE_COMMIT" \
  "$AGENTS_CSV" ""

info "Installed $ITEM_NAME ($ITEM_TYPE v$ITEM_VERSION)"
echo "  Lock file updated: $(basename "$LOCK_FILE")"

# Clean up temp clone
if [[ -n "$TEMP_CLONE" ]]; then
  cleanup_temp "$TEMP_CLONE"
fi
