#!/usr/bin/env bash
# git.sh — git operations for remote skill fetching

# Convert owner/repo shorthand to a full HTTPS URL.
shorthand_to_url() {
  local shorthand="$1"
  echo "https://github.com/${shorthand}.git"
}

# Normalize any input (URL, shorthand) to a clone-able URL.
normalize_repo_url() {
  local input="$1"
  if is_url "$input"; then
    echo "$input"
  elif is_shorthand "$input"; then
    shorthand_to_url "$input"
  else
    die "Cannot resolve '$input' as a URL or owner/repo shorthand"
  fi
}

# Shallow-clone a repo to a temp directory.
# Args: url [commit_hash]
# Outputs: path to temp directory
# If commit_hash is given, fetches that exact commit.
clone_shallow() {
  local url="$1"
  local commit="${2:-}"
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  if [[ -n "$commit" ]]; then
    git init "$tmp_dir" --quiet
    git -C "$tmp_dir" remote add origin "$url"
    git -C "$tmp_dir" fetch --depth 1 origin "$commit" --quiet 2>/dev/null || {
      # Fallback: some servers don't support fetching by commit hash
      rm -rf "$tmp_dir"
      tmp_dir="$(mktemp -d)"
      git clone --depth 1 "$url" "$tmp_dir" --quiet
    }
    git -C "$tmp_dir" checkout FETCH_HEAD --quiet 2>/dev/null || true
  else
    git clone --depth 1 "$url" "$tmp_dir" --quiet || die "Failed to clone $url"
  fi

  echo "$tmp_dir"
}

# Get the HEAD commit hash from a cloned repo.
resolve_commit() {
  local repo_dir="$1"
  git -C "$repo_dir" rev-parse HEAD
}

# Clean up a temp clone directory.
cleanup_temp() {
  local dir="$1"
  if [[ -d "$dir" ]] && [[ "$dir" == /tmp/* || "$dir" == *"/tmp/"* ]]; then
    rm -rf "$dir"
  fi
}

# For repos without manifest.yaml, generate a synthetic manifest from SKILL.md frontmatter.
# This enables compatibility with npx-skills-style repos.
generate_synthetic_manifest() {
  local item_dir="$1"
  local skill_md="$item_dir/SKILL.md"

  if [[ ! -f "$skill_md" ]]; then return 1; fi
  if [[ -f "$item_dir/manifest.yaml" ]]; then return 0; fi  # already has manifest

  # Read frontmatter from SKILL.md
  local name description
  local frontmatter
  frontmatter="$(sed -n '/^---$/,/^---$/p' "$skill_md" | sed '1d;$d')"

  name="$(echo "$frontmatter" | yaml_read_field name)"
  description="$(echo "$frontmatter" | yaml_read_field description)"

  # Fallback to directory name if no name in frontmatter
  [[ -z "$name" ]] && name="$(basename "$item_dir")"
  [[ -z "$description" ]] && description="Skill imported from external repository"

  # Write synthetic manifest
  cat > "$item_dir/manifest.yaml" <<EOF
name: $name
type: skill
description: $description
tags: []
targets:
  - claude-code
  - github-copilot
files:
  - SKILL.md
version: "0.0.0"
EOF
}

# Scan a cloned repo for skills/agents/instructions.
# Looks for manifest.yaml files in known locations.
# Outputs: newline-separated list of paths to directories containing manifest.yaml
scan_repo_for_items() {
  local repo_dir="$1"
  local found=()

  # Check standard directories
  for dir in skills agents instructions .claude/skills .agents/skills; do
    if [[ -d "$repo_dir/$dir" ]]; then
      for item_dir in "$repo_dir/$dir"/*/; do
        if [[ -f "${item_dir}manifest.yaml" ]]; then
          found+=("$item_dir")
        elif [[ -f "${item_dir}SKILL.md" ]]; then
          # Support repos that don't use manifest.yaml (npx skills style)
          generate_synthetic_manifest "${item_dir%/}"
          found+=("$item_dir")
        fi
      done
    fi
  done

  # Check root level
  if [[ -f "$repo_dir/manifest.yaml" ]]; then
    found+=("$repo_dir/")
  elif [[ -f "$repo_dir/SKILL.md" ]]; then
    generate_synthetic_manifest "$repo_dir"
    found+=("$repo_dir/")
  fi

  printf '%s\n' "${found[@]}" | sed '/^$/d'
}
