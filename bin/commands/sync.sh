#!/usr/bin/env bash
# sync.sh — regenerate registry.json by scanning content directories

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CMD_DIR/../lib/common.sh"

REGISTRY_ROOT="${REGISTRY_ROOT:-$(resolve_registry_root)}"
OUTPUT_FILE="$REGISTRY_ROOT/registry.json"

scan_manifests() {
  local items=()
  local count=0

  for content_dir in skills agents instructions; do
    local dir_path="$REGISTRY_ROOT/$content_dir"
    [[ -d "$dir_path" ]] || continue

    for item_dir in "$dir_path"/*/; do
      [[ -d "$item_dir" ]] || continue
      local manifest="$item_dir/manifest.yaml"
      [[ -f "$manifest" ]] || continue

      local mc
      mc="$(cat "$manifest")"

      local name type description version
      name="$(echo "$mc" | yaml_read_field name)"
      type="$(echo "$mc" | yaml_read_field type)"
      description="$(echo "$mc" | yaml_read_field description)"
      version="$(echo "$mc" | yaml_read_field version)"
      [[ -z "$version" ]] && version="0.0.0"

      # Build JSON arrays for list fields
      local tags_json targets_json files_json deps_json
      tags_json="[$(echo "$mc" | yaml_read_list tags | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')]"
      targets_json="[$(echo "$mc" | yaml_read_list targets | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')]"
      files_json="[$(echo "$mc" | yaml_read_list files | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')]"
      deps_json="[$(echo "$mc" | yaml_read_list dependencies | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')]"

      [[ $count -gt 0 ]] && items+=(",")
      items+=("    {
      \"name\": \"$name\",
      \"type\": \"$type\",
      \"description\": \"$description\",
      \"tags\": $tags_json,
      \"targets\": $targets_json,
      \"files\": $files_json,
      \"dependencies\": $deps_json,
      \"version\": \"$version\",
      \"path\": \"$content_dir/$(basename "$item_dir")\"
    }")
      count=$((count + 1))
    done
  done

  {
    echo "{"
    echo "  \"version\": 1,"
    echo "  \"generatedAt\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"items\": ["
    printf '%s\n' "${items[@]}"
    echo "  ]"
    echo "}"
  } > "$OUTPUT_FILE"

  info "Registry updated: $count items → $(basename "$OUTPUT_FILE")"
}

scan_manifests
