#!/usr/bin/env bash
# profile.sh — profile loading and installation

# Read a profile YAML and install all items.
# Uses the yaml_read_* functions from common.sh.
install_profile() {
  local profile_name="$1"
  local target_dir="$2"
  local global_install="$3"
  local use_symlink="$4"
  local agents_override="$5"

  local profile_file="$REGISTRY_ROOT/profiles/${profile_name}.yaml"
  if [[ ! -f "$profile_file" ]]; then
    die "Profile not found: $profile_name (expected at $profile_file)"
  fi

  local profile_content
  profile_content="$(cat "$profile_file")"
  local description
  description="$(echo "$profile_content" | yaml_read_field description)"

  echo -e "\n${BOLD}Installing profile: $profile_name${RESET}"
  [[ -n "$description" ]] && echo "  $description"
  echo ""

  # Parse items — each item block has name, source, and optional ref
  # We use awk to extract item blocks
  local items
  items="$(awk '
    /^items:/ { in_items=1; next }
    in_items && /^[^ ]/ {
      if (name != "") print name "|" source "|" ref
      exit
    }
    in_items && /^  - name:/ {
      if (name != "") print name "|" source "|" ref
      gsub(/^  - name: */, ""); name=$0; source=""; ref=""
    }
    in_items && /^    source:/ {
      gsub(/^    source: */, ""); source=$0
    }
    in_items && /^    ref:/ {
      gsub(/^    ref: */, ""); ref=$0
    }
    END {
      if (name != "") print name "|" source "|" ref
    }
  ' "$profile_file")"

  local count=0
  local install_cmd="$CMD_DIR/install.sh"

  # Build agent flags
  local agent_flags=""
  if [[ -n "$agents_override" ]]; then
    for a in $agents_override; do
      agent_flags+="--agent $a "
    done
  fi

  local global_flag=""
  [[ "$global_install" == "true" ]] && global_flag="--global"

  local symlink_flag=""
  [[ "$use_symlink" == "true" ]] && symlink_flag="--symlink"

  while IFS='|' read -r item_name item_source item_ref; do
    [[ -z "$item_name" ]] && continue

    echo "  Installing: $item_name (from $item_source)..."

    if [[ "$item_source" == "local" ]]; then
      REGISTRY_ROOT="$REGISTRY_ROOT" bash "$install_cmd" \
        "$item_name" --target "$target_dir" $agent_flags $global_flag $symlink_flag --yes
    else
      REGISTRY_ROOT="$REGISTRY_ROOT" bash "$install_cmd" \
        "$item_source" --target "$target_dir" --skill "$item_name" \
        $agent_flags $global_flag $symlink_flag --yes
    fi

    count=$((count + 1))
  done <<< "$items"

  echo ""
  info "Profile '$profile_name' installed: $count items"
}
