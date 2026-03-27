#!/usr/bin/env bash
# update.sh — pull latest skills from an upstream repo into the local registry

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CMD_DIR/../lib/common.sh"
source "$CMD_DIR/../lib/git.sh"

REGISTRY_ROOT="${REGISTRY_ROOT:-$(resolve_registry_root)}"

DEFAULT_UPSTREAM="obra/superpowers"
UPSTREAM=""
REF=""
DRY_RUN=false
FORCE=false
ITEMS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref)      REF="$2"; shift 2 ;;
    --dry-run)  DRY_RUN=true; shift ;;
    --force|-f) FORCE=true; shift ;;
    --item|-i)  ITEMS+=("$2"); shift 2 ;;
    --yes|-y)   export SKILL_YES=1; shift ;;
    --help|-h)
      cat <<EOF
Usage: skill update [<url|owner/repo>] [options]

Pull the latest skills from an upstream repository and update local copies.

  skill update                         Update from $DEFAULT_UPSTREAM
  skill update obra/superpowers        Update from a GitHub repo
  skill update <url>                   Update from any Git URL
  skill update --item brainstorming    Update a specific item only

Options:
  --item, -i <name>   Update only the named item(s), repeatable
  --ref <commit>      Fetch a specific commit/tag/branch
  --dry-run           Show what would change without modifying files
  --force, -f         Overwrite without prompting
  --yes, -y           Auto-accept prompts
EOF
      exit 0 ;;
    -*)
      die "Unknown flag: $1" ;;
    *)
      UPSTREAM="$1"; shift ;;
  esac
done

[[ -z "$UPSTREAM" ]] && UPSTREAM="$DEFAULT_UPSTREAM"

# --- Clone upstream ---
SOURCE_URL="$(normalize_repo_url "$UPSTREAM")"
echo "Fetching upstream: $SOURCE_URL"
TEMP_CLONE="$(clone_shallow "$SOURCE_URL" "$REF")"
trap 'cleanup_temp "$TEMP_CLONE"' EXIT

UPSTREAM_COMMIT="$(resolve_commit "$TEMP_CLONE")"
echo "  Commit: ${UPSTREAM_COMMIT:0:10}"
echo ""

# --- Scan upstream for items ---
FOUND_ITEMS="$(scan_repo_for_items "$TEMP_CLONE")"
if [[ -z "$FOUND_ITEMS" ]]; then
  die "No skills/instructions found in $UPSTREAM"
fi

# --- Compare and update ---
UPDATED=0
SKIPPED=0
NEW_ITEMS=()

while IFS= read -r remote_dir; do
  [[ -z "$remote_dir" ]] && continue
  remote_dir="${remote_dir%/}"

  # Read remote manifest
  if [[ -f "$remote_dir/manifest.yaml" ]]; then
    remote_name="$(cat "$remote_dir/manifest.yaml" | yaml_read_field name)"
    remote_type="$(cat "$remote_dir/manifest.yaml" | yaml_read_field type)"
    remote_version="$(cat "$remote_dir/manifest.yaml" | yaml_read_field version)"
  else
    continue
  fi

  [[ -z "$remote_name" ]] && remote_name="$(basename "$remote_dir")"
  [[ -z "$remote_type" ]] && remote_type="skill"
  [[ -z "$remote_version" ]] && remote_version="0.0.0"

  # If --item filter is set, skip non-matching items
  if [[ ${#ITEMS[@]} -gt 0 ]]; then
    match=false
    for want in "${ITEMS[@]}"; do
      [[ "$want" == "$remote_name" ]] && match=true
    done
    [[ "$match" == "false" ]] && continue
  fi

  # Determine local type directory
  case "$remote_type" in
    skill|agent) local_type_dir="skills" ;;
    instruction) local_type_dir="instructions" ;;
    *) local_type_dir="skills" ;;
  esac

  local_dir="$REGISTRY_ROOT/$local_type_dir/$remote_name"

  if [[ ! -d "$local_dir" ]]; then
    NEW_ITEMS+=("$remote_name ($remote_type)")
    continue
  fi

  # Compare files — check if any differ
  changed_files=()
  remote_files="$(cat "$remote_dir/manifest.yaml" | yaml_read_list files)"
  # Always include manifest.yaml in the comparison
  all_files="manifest.yaml"$'\n'"$remote_files"

  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    remote_file="$remote_dir/$file"
    local_file="$local_dir/$file"

    if [[ ! -f "$remote_file" ]]; then
      continue
    fi

    if [[ ! -f "$local_file" ]]; then
      changed_files+=("$file (new)")
    elif ! diff -q "$remote_file" "$local_file" >/dev/null 2>&1; then
      changed_files+=("$file")
    fi
  done <<< "$all_files"

  if [[ ${#changed_files[@]} -eq 0 ]]; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Show changes
  echo "${BOLD}$remote_name${RESET} ($remote_type v$remote_version)"
  for cf in "${changed_files[@]}"; do
    echo "  ~ $cf"
  done

  if [[ "$DRY_RUN" == "true" ]]; then
    UPDATED=$((UPDATED + 1))
    echo ""
    continue
  fi

  # Prompt unless --force or --yes
  if [[ "$FORCE" != "true" ]] && [[ "${SKILL_YES:-}" != "1" ]]; then
    if ! prompt_yn "  Update $remote_name?"; then
      SKIPPED=$((SKIPPED + 1))
      echo ""
      continue
    fi
  fi

  # Copy files
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    remote_file="$remote_dir/$file"
    local_file="$local_dir/$file"

    [[ ! -f "$remote_file" ]] && continue

    mkdir -p "$(dirname "$local_file")"
    cp "$remote_file" "$local_file"
  done <<< "$all_files"

  UPDATED=$((UPDATED + 1))
  echo ""
done <<< "$FOUND_ITEMS"

# --- Summary ---
echo "---"
if [[ "$DRY_RUN" == "true" ]]; then
  echo "Dry run: $UPDATED item(s) would be updated, $SKIPPED unchanged"
else
  if [[ $UPDATED -gt 0 ]]; then
    info "Updated $UPDATED item(s) from upstream"
    echo "  Run ${CYAN}skill sync${RESET} to regenerate the registry index."
  else
    echo "All local items are up to date."
  fi
fi

if [[ ${#NEW_ITEMS[@]} -gt 0 ]]; then
  echo ""
  echo "${BOLD}New items available upstream:${RESET}"
  for ni in "${NEW_ITEMS[@]}"; do
    echo "  + $ni"
  done
  echo "  Use ${CYAN}skill install $UPSTREAM --skill <name>${RESET} to add them."
fi
