#!/usr/bin/env bash
# lock.sh — .skills-lock.json management

lock_init() {
  local lock_file="$1"
  cat > "$lock_file" <<'EOF'
{
  "version": 1,
  "installed": {}
}
EOF
}

lock_ensure() {
  local lock_file="$1"
  if [[ ! -f "$lock_file" ]]; then
    lock_init "$lock_file"
  fi
}

lock_has_entry() {
  local lock_file="$1" name="$2"
  [[ -f "$lock_file" ]] && grep -q "\"${name}\":" "$lock_file"
}

# Add or update an entry.
# Args: lock_file name type version source sourceUrl sourceCommit agents_csv profile
lock_add_entry() {
  local lock_file="$1"
  local name="$2" type="$3" version="$4"
  local source="$5" source_url="$6" source_commit="$7"
  local agents_csv="$8" profile="${9:-}"
  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"

  lock_ensure "$lock_file"

  if lock_has_entry "$lock_file" "$name"; then
    lock_remove_entry "$lock_file" "$name"
    lock_ensure "$lock_file"
  fi

  # Build agents JSON array
  local agents_json="["
  local first=true
  IFS=',' read -ra agents_arr <<< "$agents_csv"
  for a in "${agents_arr[@]}"; do
    [[ "$first" == "true" ]] && first=false || agents_json+=", "
    agents_json+="\"$a\""
  done
  agents_json+="]"

  # Format nullable fields
  local url_json="null"
  [[ -n "$source_url" ]] && url_json="\"$source_url\""
  local commit_json="null"
  [[ -n "$source_commit" ]] && commit_json="\"$source_commit\""
  local profile_json="null"
  [[ -n "$profile" ]] && profile_json="\"$profile\""

  local entry="    \"${name}\": {
      \"type\": \"${type}\",
      \"version\": \"${version}\",
      \"source\": \"${source}\",
      \"sourceUrl\": ${url_json},
      \"sourceCommit\": ${commit_json},
      \"installedAt\": \"${timestamp}\",
      \"agents\": ${agents_json},
      \"profile\": ${profile_json}
    }"

  local lock_content
  lock_content="$(cat "$lock_file")"

  if echo "$lock_content" | grep -q '"installed": {}'; then
    lock_content="${lock_content/'"installed": {}'/"\"installed\": {
${entry}
  }"}"
  else
    lock_content="$(echo "$lock_content" | sed '$d' | sed '$d')"
    lock_content="${lock_content},
${entry}
  }
}"
  fi

  echo "$lock_content" > "$lock_file"
}

lock_remove_entry() {
  local lock_file="$1" name="$2"
  [[ -f "$lock_file" ]] || return

  awk -v name="\"${name}\":" '
    BEGIN { skip=0; brace_depth=0 }
    skip==0 && index($0, name) > 0 {
      skip=1; brace_depth=0; next
    }
    skip==1 {
      for(i=1;i<=length($0);i++) {
        c=substr($0,i,1)
        if(c=="{") brace_depth++
        if(c=="}") brace_depth--
      }
      if(brace_depth<=0) { skip=0 }
      next
    }
    { print }
  ' "$lock_file" > "${lock_file}.tmp"
  mv "${lock_file}.tmp" "$lock_file"

  # Remove trailing commas before closing braces
  sed -i.bak 's/,\([[:space:]]*\)}/\1}/' "$lock_file" 2>/dev/null || \
    sed -i '' 's/,\([[:space:]]*\)}/\1}/' "$lock_file"
  rm -f "${lock_file}.bak"
}

lock_list_entries() {
  local lock_file="$1"
  [[ -f "$lock_file" ]] || return
  grep -oP '^\s{4}"\K[a-z][a-z0-9-]*(?=":)' "$lock_file" 2>/dev/null || \
    awk -F'"' '/^    "[a-z]/ && /:/ { print $2 }' "$lock_file"
}

lock_get_field() {
  local lock_file="$1" name="$2" field="$3"
  [[ -f "$lock_file" ]] || { echo ""; return; }
  awk -v name="\"${name}\":" -v field="\"${field}\":" '
    BEGIN { found=0 }
    found==0 && index($0, name) > 0 { found=1; next }
    found==1 && index($0, field) > 0 {
      sub(/.*: */, ""); gsub(/[",]/, ""); gsub(/^ +| +$/, ""); print; exit
    }
    found==1 && /^    }/ { exit }
  ' "$lock_file"
}
