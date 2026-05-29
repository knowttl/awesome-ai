#!/usr/bin/env bash
# agents.sh — agent path registry and detection

# Agent table: name|project_path|global_suffix|detection_dirs|detection_bins
# global_suffix is appended to $HOME
AGENT_TABLE=(
  "claude-code|.claude/skills|.claude/skills|.claude|claude"
  "github-copilot|.github/skills|.copilot/skills|.copilot,.github|copilot"
  "cursor|.agents/skills|.cursor/skills|.cursor|cursor"
  "cline|.agents/skills|.agents/skills|.cline|cline"
  "opencode|.agents/skills|.config/opencode/skills|.config/opencode|opencode"
  "codex|.agents/skills|.codex/skills|.codex|codex"
  "windsurf|.windsurf/skills|.codeium/windsurf/skills|.codeium/windsurf|windsurf"
  "roo|.roo/skills|.roo/skills|.roo|roo"
)

get_project_path() {
  local agent="$1"
  for entry in "${AGENT_TABLE[@]}"; do
    IFS='|' read -r name proj _rest <<< "$entry"
    if [[ "$name" == "$agent" ]]; then
      echo "$proj"
      return 0
    fi
  done
  echo ""
}

get_global_path() {
  local agent="$1"
  for entry in "${AGENT_TABLE[@]}"; do
    IFS='|' read -r name _proj global _rest <<< "$entry"
    if [[ "$name" == "$agent" ]]; then
      echo "$HOME/$global"
      return 0
    fi
  done
  echo ""
}

list_known_agents() {
  for entry in "${AGENT_TABLE[@]}"; do
    IFS='|' read -r name _rest <<< "$entry"
    echo "$name"
  done
}

detect_agents() {
  for entry in "${AGENT_TABLE[@]}"; do
    IFS='|' read -r name _proj _global detect_dirs detect_bins <<< "$entry"
    IFS=',' read -ra dirs <<< "$detect_dirs"
    for dir in "${dirs[@]}"; do
      if [[ -d "$HOME/$dir" ]]; then
        echo "$name"
        continue 2
      fi
    done
    IFS=',' read -ra bins <<< "$detect_bins"
    for bin in "${bins[@]}"; do
      if command -v "$bin" &>/dev/null; then
        echo "$name"
        continue 2
      fi
    done
  done
}

# Deduplicate agents: github-copilot reads from .claude/skills, so if both
# claude-code and github-copilot are selected, only install to claude-code.
dedupe_agents() {
  local agents_input="$1"
  local has_claude=false
  local has_copilot=false

  while IFS= read -r agent; do
    [[ -z "$agent" ]] && continue
    [[ "$agent" == "claude-code" ]] && has_claude=true
    [[ "$agent" == "github-copilot" ]] && has_copilot=true
  done <<< "$agents_input"

  if [[ "$has_claude" == "true" ]] && [[ "$has_copilot" == "true" ]]; then
    echo "$agents_input" | grep -v '^github-copilot$'
  else
    echo "$agents_input"
  fi
}

select_agents() {
  local compatible="$1"
  local detected
  detected="$(detect_agents)"

  echo -e "\n${BOLD}Detected agents:${RESET} $(echo "$detected" | tr '\n' ', ' | sed 's/,$//')"
  echo ""

  local selected=()
  while IFS= read -r agent; do
    local is_detected="n"
    if echo "$detected" | grep -qx "$agent"; then
      is_detected="y"
    fi

    if [[ "${SKILL_YES:-}" == "1" ]]; then
      if [[ "$is_detected" == "y" ]]; then
        selected+=("$agent")
      fi
    else
      local default_marker=""
      [[ "$is_detected" == "y" ]] && default_marker=" ${GREEN}(detected)${RESET}"
      echo -ne "  Install to ${BOLD}${agent}${RESET}?${default_marker} ${CYAN}(y/n)${RESET} "
      read -r answer
      if [[ "$answer" =~ ^[Yy] ]] || { [[ -z "$answer" ]] && [[ "$is_detected" == "y" ]]; }; then
        selected+=("$agent")
      fi
    fi
  done <<< "$compatible"

  printf '%s\n' "${selected[@]}"
}
