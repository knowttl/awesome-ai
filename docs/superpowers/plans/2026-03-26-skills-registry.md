# Skills Registry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a CLI tool (Bash + PowerShell) that installs skills, agents, and instructions from a personal registry repo into any project for any AI coding assistant.

**Architecture:** Dispatcher + shared library pattern. A thin `skill` / `skill.ps1` entrypoint routes subcommands to per-command scripts in `bin/commands/`. Shared functions in `bin/lib/` handle agent detection, git operations, lock file management, and YAML parsing. Content lives in `skills/`, `agents/`, `instructions/` with `manifest.yaml` per item.

**Tech Stack:** Bash (macOS/Linux), PowerShell (Windows), Git, JSON (lock files, registry index), YAML (manifests, profiles)

---

## File Structure

### CLI scripts (created in this plan)

| File | Responsibility |
|---|---|
| `bin/skill` | Bash dispatcher — parses first arg, routes to `commands/<cmd>.sh` |
| `bin/skill.ps1` | PowerShell dispatcher — same logic |
| `bin/lib/common.sh` | Colors, `die()`, `info()`, `warn()`, `prompt_yn()`, YAML field reader |
| `bin/lib/common.ps1` | Same utilities for PowerShell |
| `bin/lib/agents.sh` | Agent path table + `detect_agents()` + `get_install_path()` |
| `bin/lib/agents.ps1` | Same for PowerShell |
| `bin/lib/git.sh` | `clone_shallow()`, `resolve_commit()`, `cleanup_temp()` |
| `bin/lib/git.ps1` | Same for PowerShell |
| `bin/lib/lock.sh` | `lock_read()`, `lock_write()`, `lock_add_entry()`, `lock_remove_entry()` |
| `bin/lib/lock.ps1` | Same for PowerShell |
| `bin/commands/sync.sh` | Scan content dirs, generate `registry.json` |
| `bin/commands/sync.ps1` | Same for PowerShell |
| `bin/commands/list.sh` | Read `registry.json`, filter, display table |
| `bin/commands/list.ps1` | Same for PowerShell |
| `bin/commands/search.sh` | Full-text search across registry |
| `bin/commands/search.ps1` | Same for PowerShell |
| `bin/commands/info.sh` | Display full manifest for one item |
| `bin/commands/info.ps1` | Same for PowerShell |
| `bin/commands/install.sh` | Resolve source, detect agents, copy files, update lock |
| `bin/commands/install.ps1` | Same for PowerShell |
| `bin/commands/uninstall.sh` | Remove files, update lock |
| `bin/commands/uninstall.ps1` | Same for PowerShell |

### Content and config files (created in this plan)

| File | Responsibility |
|---|---|
| `skills/example-skill/manifest.yaml` | Sample skill manifest |
| `skills/example-skill/SKILL.md` | Sample skill content |
| `instructions/example-instruction/manifest.yaml` | Sample instruction manifest |
| `instructions/example-instruction/example-instruction.instructions.md` | Sample instruction content |
| `profiles/example.yaml` | Sample profile |
| `registry.json` | Generated index (created by `skill sync`) |
| `.gitignore` | Ignore temp files |
| `README.md` | Usage docs and catalog |

### Test files

| File | Responsibility |
|---|---|
| `tests/run-tests.sh` | Bash test runner |
| `tests/test-common.sh` | Tests for `lib/common.sh` |
| `tests/test-agents.sh` | Tests for `lib/agents.sh` |
| `tests/test-lock.sh` | Tests for `lib/lock.sh` |
| `tests/test-sync.sh` | Tests for `commands/sync.sh` |
| `tests/test-install.sh` | Tests for `commands/install.sh` |
| `tests/test-uninstall.sh` | Tests for `commands/uninstall.sh` |
| `tests/fixtures/` | Test manifests and content for test cases |

---

## Task Overview

| Task | Component | Dependencies |
|---|---|---|
| 1 | Shared lib: `common.sh` + `common.ps1` | None |
| 2 | Shared lib: `agents.sh` + `agents.ps1` | Task 1 |
| 3 | Shared lib: `git.sh` + `git.ps1` (+ synthetic manifest) | Task 1 |
| 4 | Shared lib: `lock.sh` + `lock.ps1` | Task 1 |
| 5 | Dispatchers: `skill` + `skill.ps1` | Task 1 |
| 6 | Command: `sync` (registry generation) | Tasks 1, 5 |
| 7 | Command: `list` | Tasks 1, 5, 6 |
| 8 | Command: `search` | Tasks 1, 5, 6 |
| 9 | Command: `info` | Tasks 1, 5, 6 |
| 10 | Command: `install` (local source) | Tasks 1-6 |
| 11 | Verify: synthetic manifests + remote install | Task 3, 10 |
| 12 | Command: `install` (lock file restore) | Tasks 4, 10, 11 |
| 13 | Command: `install --profile` | Tasks 10, 11, 12 |
| 14 | Command: `uninstall` | Tasks 1, 2, 4, 5 |
| 15 | Sample content + profiles | Task 6 |
| 16 | README + .gitignore | Task 15 |
| 17 | Test runner + integration smoke test | Tasks 1-16 |

### Backlog (v2)

The following spec features are deferred to a future iteration to keep v1 focused:

- **Manifest validation** (Spec §3) — validate required fields on `sync` and `install`
- **Diff display on conflicts** (Spec §5.5) — `Overwrite? (y/n/diff)` with diff output; v1 uses simple `y/n` prompt
- **Per-agent file tracking in lock file** (Spec §5.7) — spec shows nested `files: { agent: [...] }`; v1 uses flat CSV for shell simplicity
- **Dependency auto-install** (Spec §5.2) — warn and offer to install missing dependencies
- **Update workflow** (Spec §6) — detect already-installed items and show diff before re-installing

---

## Tasks

### Task 1: Shared library — `common.sh` + `common.ps1`

**Files:**
- Create: `bin/lib/common.sh`
- Create: `bin/lib/common.ps1`
- Create: `tests/test-common.sh`

- [ ] **Step 1: Write test for common.sh utilities**

Create `tests/test-common.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bin/lib/common.sh"

TESTS_RUN=0
TESTS_PASSED=0

assert_eq() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  PASS: $label"
  else
    echo "  FAIL: $label"
    echo "    expected: '$expected'"
    echo "    actual:   '$actual'"
  fi
}

echo "=== test-common.sh ==="

# Test yaml_read_field
MANIFEST="$(cat <<'EOF'
name: test-skill
type: skill
description: A test skill for testing
tags:
  - testing
  - example
targets:
  - claude-code
  - github-copilot
files:
  - SKILL.md
version: "1.0.0"
EOF
)"

assert_eq "yaml_read_field name" "test-skill" "$(echo "$MANIFEST" | yaml_read_field name)"
assert_eq "yaml_read_field type" "skill" "$(echo "$MANIFEST" | yaml_read_field type)"
assert_eq "yaml_read_field version" "1.0.0" "$(echo "$MANIFEST" | yaml_read_field version)"
assert_eq "yaml_read_field missing returns empty" "" "$(echo "$MANIFEST" | yaml_read_field nonexistent)"

# Test yaml_read_list
TAGS="$(echo "$MANIFEST" | yaml_read_list tags)"
assert_eq "yaml_read_list tags line 1" "testing" "$(echo "$TAGS" | sed -n '1p')"
assert_eq "yaml_read_list tags line 2" "example" "$(echo "$TAGS" | sed -n '2p')"

TARGETS="$(echo "$MANIFEST" | yaml_read_list targets)"
assert_eq "yaml_read_list targets line 1" "claude-code" "$(echo "$TARGETS" | sed -n '1p')"
assert_eq "yaml_read_list targets line 2" "github-copilot" "$(echo "$TARGETS" | sed -n '2p')"

FILES="$(echo "$MANIFEST" | yaml_read_list files)"
assert_eq "yaml_read_list files" "SKILL.md" "$(echo "$FILES" | sed -n '1p')"

# Test is_url
assert_eq "is_url with https" "0" "$(is_url 'https://github.com/owner/repo' && echo 0 || echo 1)"
assert_eq "is_url with git@" "0" "$(is_url 'git@github.com:owner/repo.git' && echo 0 || echo 1)"
assert_eq "is_url with owner/repo" "1" "$(is_url 'owner/repo' && echo 0 || echo 1)"
assert_eq "is_url with plain name" "1" "$(is_url 'my-skill' && echo 0 || echo 1)"

# Test is_shorthand
assert_eq "is_shorthand owner/repo" "0" "$(is_shorthand 'owner/repo' && echo 0 || echo 1)"
assert_eq "is_shorthand plain name" "1" "$(is_shorthand 'my-skill' && echo 0 || echo 1)"
assert_eq "is_shorthand url" "1" "$(is_shorthand 'https://github.com/x/y' && echo 0 || echo 1)"

echo ""
echo "Results: $TESTS_PASSED / $TESTS_RUN passed"
[[ "$TESTS_PASSED" -eq "$TESTS_RUN" ]]
```

- [ ] **Step 2: Run test to verify it fails**

```bash
chmod +x tests/test-common.sh
bash tests/test-common.sh
```

Expected: FAIL — `common.sh` not found.

- [ ] **Step 3: Implement `bin/lib/common.sh`**

Create `bin/lib/common.sh`:

```bash
#!/usr/bin/env bash
# common.sh — shared utilities for skills-registry CLI

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  RED='' GREEN='' YELLOW='' CYAN='' BOLD='' RESET=''
fi

# Logging
info()  { echo -e "${GREEN}✓${RESET} $*"; }
warn()  { echo -e "${YELLOW}⚠${RESET} $*" >&2; }
die()   { echo -e "${RED}✗${RESET} $*" >&2; exit 1; }

# Prompt yes/no. Returns 0 for yes, 1 for no.
# Usage: prompt_yn "Overwrite file?" && do_thing
prompt_yn() {
  local prompt="$1"
  if [[ "${SKILL_YES:-}" == "1" ]]; then
    return 0
  fi
  echo -ne "$prompt ${CYAN}(y/n)${RESET} "
  read -r answer
  [[ "$answer" =~ ^[Yy] ]]
}

# Lightweight YAML parser — reads a scalar field value from stdin.
# Handles: `key: value`, `key: "value"`, `key: 'value'`
# Usage: cat manifest.yaml | yaml_read_field name
yaml_read_field() {
  local key="$1"
  sed -n "s/^${key}:[[:space:]]*[\"']\{0,1\}\([^\"']*\)[\"']\{0,1\}[[:space:]]*$/\1/p" | head -1
}

# Reads a YAML list field from stdin. Outputs one item per line.
# Handles: `  - item` lines under the given key.
# Usage: cat manifest.yaml | yaml_read_list tags
yaml_read_list() {
  local key="$1"
  awk -v key="$key:" '
    BEGIN { found=0 }
    $0 ~ "^"key { found=1; next }
    found && /^[[:space:]]*-[[:space:]]/ {
      sub(/^[[:space:]]*-[[:space:]]*/, "")
      gsub(/^["'\'']|["'\'']$/, "")
      print
      next
    }
    found && /^[^[:space:]]/ { found=0 }
  '
}

# Check if a string looks like a URL
is_url() {
  [[ "$1" =~ ^https?:// ]] || [[ "$1" =~ ^git@ ]]
}

# Check if a string looks like owner/repo shorthand (exactly one slash, no protocol)
is_shorthand() {
  ! is_url "$1" && [[ "$1" =~ ^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$ ]]
}

# Resolve REGISTRY_ROOT — the root of the skills-registry repo.
# Walks up from the script's location to find the repo root.
resolve_registry_root() {
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
  # Walk up until we find registry.json or bin/
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/bin/lib" ]] && [[ -d "$dir/skills" || -d "$dir/agents" || -d "$dir/instructions" ]]; then
      echo "$dir"
      return 0
    fi
    # Also accept if we find bin/ and the parent has the structure
    if [[ -f "$dir/bin/skill" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  die "Could not find skills-registry root directory"
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tests/test-common.sh
```

Expected: All tests PASS.

- [ ] **Step 5: Implement `bin/lib/common.ps1`**

Create `bin/lib/common.ps1`:

```powershell
# common.ps1 — shared utilities for skills-registry CLI

# Colors
$script:UseColor = $Host.UI.SupportsVirtualTerminal -or $env:WT_SESSION
function Write-Info  { param([string]$Msg) if ($script:UseColor) { Write-Host "✓ $Msg" -ForegroundColor Green } else { Write-Host "OK $Msg" } }
function Write-Warn  { param([string]$Msg) if ($script:UseColor) { Write-Host "⚠ $Msg" -ForegroundColor Yellow } else { Write-Host "WARN $Msg" } }
function Write-Die   { param([string]$Msg) if ($script:UseColor) { Write-Host "✗ $Msg" -ForegroundColor Red } else { Write-Host "ERR $Msg" }; exit 1 }

function Confirm-Prompt {
    param([string]$Prompt)
    if ($env:SKILL_YES -eq "1") { return $true }
    $answer = Read-Host "$Prompt (y/n)"
    return $answer -match '^[Yy]'
}

function Read-YamlField {
    param([string]$Content, [string]$Key)
    $pattern = "^${Key}:\s*[`"']?([^`"']*)[`"']?\s*$"
    foreach ($line in $Content -split "`n") {
        if ($line -match $pattern) {
            return $Matches[1].Trim()
        }
    }
    return ""
}

function Read-YamlList {
    param([string]$Content, [string]$Key)
    $lines = $Content -split "`n"
    $found = $false
    $results = @()
    foreach ($line in $lines) {
        if ($line -match "^${Key}:") {
            $found = $true
            continue
        }
        if ($found -and $line -match '^\s*-\s+(.+)$') {
            $val = $Matches[1].Trim() -replace '^["'']|["'']$', ''
            $results += $val
            continue
        }
        if ($found -and $line -match '^\S') {
            $found = $false
        }
    }
    return $results
}

function Test-IsUrl {
    param([string]$Value)
    return $Value -match '^https?://' -or $Value -match '^git@'
}

function Test-IsShorthand {
    param([string]$Value)
    return (-not (Test-IsUrl $Value)) -and ($Value -match '^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$')
}

function Resolve-RegistryRoot {
    $dir = Split-Path -Parent $PSScriptRoot
    while ($dir -and $dir -ne [System.IO.Path]::GetPathRoot($dir)) {
        if ((Test-Path "$dir/bin/lib") -and ((Test-Path "$dir/skills") -or (Test-Path "$dir/agents") -or (Test-Path "$dir/instructions"))) {
            return $dir
        }
        if (Test-Path "$dir/bin/skill.ps1") {
            return $dir
        }
        $dir = Split-Path -Parent $dir
    }
    Write-Die "Could not find skills-registry root directory"
}
```

- [ ] **Step 6: Commit**

```bash
git add bin/lib/common.sh bin/lib/common.ps1 tests/test-common.sh
git commit -m "feat: add shared common library (bash + powershell)"
```

---

### Task 2: Shared library — `agents.sh` + `agents.ps1`

**Files:**
- Create: `bin/lib/agents.sh`
- Create: `bin/lib/agents.ps1`
- Create: `tests/test-agents.sh`

- [ ] **Step 1: Write test for agent detection and path resolution**

Create `tests/test-agents.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bin/lib/common.sh"
source "$SCRIPT_DIR/../bin/lib/agents.sh"

TESTS_RUN=0
TESTS_PASSED=0

assert_eq() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  PASS: $label"
  else
    echo "  FAIL: $label"
    echo "    expected: '$expected'"
    echo "    actual:   '$actual'"
  fi
}

echo "=== test-agents.sh ==="

# Test get_project_path
assert_eq "claude-code project path" ".claude/skills" "$(get_project_path claude-code)"
assert_eq "github-copilot project path" ".github/copilot/skills" "$(get_project_path github-copilot)"
assert_eq "cursor project path" ".agents/skills" "$(get_project_path cursor)"
assert_eq "unknown agent returns empty" "" "$(get_project_path unknown-agent)"

# Test get_global_path — should expand ~ but we just test the suffix
CLAUDE_GLOBAL="$(get_global_path claude-code)"
assert_eq "claude-code global path ends correctly" "0" "$([[ "$CLAUDE_GLOBAL" == *"/.claude/skills" ]] && echo 0 || echo 1)"

COPILOT_GLOBAL="$(get_global_path github-copilot)"
assert_eq "copilot global path ends correctly" "0" "$([[ "$COPILOT_GLOBAL" == *"/.copilot/skills" ]] && echo 0 || echo 1)"

# Test list_known_agents
KNOWN="$(list_known_agents)"
assert_eq "known agents includes claude-code" "0" "$(echo "$KNOWN" | grep -c 'claude-code')"
assert_eq "known agents includes github-copilot" "0" "$(echo "$KNOWN" | grep -c 'github-copilot')"
assert_eq "known agents includes cursor" "0" "$(echo "$KNOWN" | grep -c 'cursor')"

echo ""
echo "Results: $TESTS_PASSED / $TESTS_RUN passed"
[[ "$TESTS_PASSED" -eq "$TESTS_RUN" ]]
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tests/test-agents.sh
```

Expected: FAIL — `agents.sh` not found.

- [ ] **Step 3: Implement `bin/lib/agents.sh`**

Create `bin/lib/agents.sh`:

```bash
#!/usr/bin/env bash
# agents.sh — agent path registry and detection

# Agent table: name|project_path|global_suffix|detection_dirs|detection_bins
# global_suffix is appended to $HOME
AGENT_TABLE=(
  "claude-code|.claude/skills|.claude/skills|.claude|claude"
  "github-copilot|.github/copilot/skills|.copilot/skills|.copilot,.github|copilot"
  "cursor|.agents/skills|.cursor/skills|.cursor|cursor"
  "cline|.agents/skills|.agents/skills|.cline|cline"
  "opencode|.agents/skills|.config/opencode/skills|.config/opencode|opencode"
  "codex|.agents/skills|.codex/skills|.codex|codex"
  "windsurf|.windsurf/skills|.codeium/windsurf/skills|.codeium/windsurf|windsurf"
  "roo|.roo/skills|.roo/skills|.roo|roo"
)

# Get the project-level install path for an agent (relative to project root)
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

# Get the global install path for an agent (absolute)
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

# List all known agent names, one per line
list_known_agents() {
  for entry in "${AGENT_TABLE[@]}"; do
    IFS='|' read -r name _rest <<< "$entry"
    echo "$name"
  done
}

# Detect which agents are installed on this system.
# Checks for config directories and CLI binaries.
# Outputs one agent name per line.
detect_agents() {
  for entry in "${AGENT_TABLE[@]}"; do
    IFS='|' read -r name _proj _global detect_dirs detect_bins <<< "$entry"

    # Check config directories
    IFS=',' read -ra dirs <<< "$detect_dirs"
    for dir in "${dirs[@]}"; do
      if [[ -d "$HOME/$dir" ]]; then
        echo "$name"
        continue 2
      fi
    done

    # Check CLI binaries
    IFS=',' read -ra bins <<< "$detect_bins"
    for bin in "${bins[@]}"; do
      if command -v "$bin" &>/dev/null; then
        echo "$name"
        continue 2
      fi
    done
  done
}

# Interactive agent selection prompt.
# Args: compatible_agents (newline-separated list)
# Outputs: selected agents (newline-separated)
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
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tests/test-agents.sh
```

Expected: All tests PASS.

- [ ] **Step 5: Implement `bin/lib/agents.ps1`**

Create `bin/lib/agents.ps1`:

```powershell
# agents.ps1 — agent path registry and detection

$script:AgentTable = @(
    @{ Name="claude-code";     ProjectPath=".claude/skills";            GlobalSuffix=".claude/skills";               DetectDirs=@(".claude");             DetectBins=@("claude") }
    @{ Name="github-copilot";  ProjectPath=".github/copilot/skills";   GlobalSuffix=".copilot/skills";              DetectDirs=@(".copilot",".github");  DetectBins=@("copilot") }
    @{ Name="cursor";          ProjectPath=".agents/skills";            GlobalSuffix=".cursor/skills";               DetectDirs=@(".cursor");             DetectBins=@("cursor") }
    @{ Name="cline";           ProjectPath=".agents/skills";            GlobalSuffix=".agents/skills";               DetectDirs=@(".cline");              DetectBins=@("cline") }
    @{ Name="opencode";        ProjectPath=".agents/skills";            GlobalSuffix=".config/opencode/skills";      DetectDirs=@(".config/opencode");    DetectBins=@("opencode") }
    @{ Name="codex";           ProjectPath=".agents/skills";            GlobalSuffix=".codex/skills";                DetectDirs=@(".codex");              DetectBins=@("codex") }
    @{ Name="windsurf";        ProjectPath=".windsurf/skills";          GlobalSuffix=".codeium/windsurf/skills";     DetectDirs=@(".codeium/windsurf");   DetectBins=@("windsurf") }
    @{ Name="roo";             ProjectPath=".roo/skills";               GlobalSuffix=".roo/skills";                  DetectDirs=@(".roo");                DetectBins=@("roo") }
)

function Get-ProjectPath {
    param([string]$Agent)
    $entry = $script:AgentTable | Where-Object { $_.Name -eq $Agent }
    if ($entry) { return $entry.ProjectPath }
    return ""
}

function Get-GlobalPath {
    param([string]$Agent)
    $entry = $script:AgentTable | Where-Object { $_.Name -eq $Agent }
    if ($entry) { return Join-Path $HOME $entry.GlobalSuffix }
    return ""
}

function Get-KnownAgents {
    return $script:AgentTable | ForEach-Object { $_.Name }
}

function Find-InstalledAgents {
    $found = @()
    foreach ($entry in $script:AgentTable) {
        $detected = $false
        foreach ($dir in $entry.DetectDirs) {
            if (Test-Path (Join-Path $HOME $dir)) {
                $detected = $true
                break
            }
        }
        if (-not $detected) {
            foreach ($bin in $entry.DetectBins) {
                if (Get-Command $bin -ErrorAction SilentlyContinue) {
                    $detected = $true
                    break
                }
            }
        }
        if ($detected) { $found += $entry.Name }
    }
    return $found
}

function Select-Agents {
    param([string[]]$Compatible)
    $detected = Find-InstalledAgents
    Write-Host "`nDetected agents: $($detected -join ', ')" -ForegroundColor Cyan
    Write-Host ""

    $selected = @()
    foreach ($agent in $Compatible) {
        $isDetected = $agent -in $detected
        if ($env:SKILL_YES -eq "1") {
            if ($isDetected) { $selected += $agent }
        } else {
            $suffix = if ($isDetected) { " (detected)" } else { "" }
            $answer = Read-Host "  Install to $agent$suffix? (y/n)"
            if ($answer -match '^[Yy]' -or ($answer -eq '' -and $isDetected)) {
                $selected += $agent
            }
        }
    }
    return $selected
}
```

- [ ] **Step 6: Commit**

```bash
git add bin/lib/agents.sh bin/lib/agents.ps1 tests/test-agents.sh
git commit -m "feat: add agent path registry and detection (bash + powershell)"
```

---

### Task 3: Shared library — `git.sh` + `git.ps1`

**Files:**
- Create: `bin/lib/git.sh`
- Create: `bin/lib/git.ps1`

- [ ] **Step 1: Implement `bin/lib/git.sh`**

Create `bin/lib/git.sh`:

```bash
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
```

- [ ] **Step 2: Implement `bin/lib/git.ps1`**

Create `bin/lib/git.ps1`:

```powershell
# git.ps1 — git operations for remote skill fetching

function ConvertTo-RepoUrl {
    param([string]$Shorthand)
    return "https://github.com/$Shorthand.git"
}

function Resolve-RepoUrl {
    param([string]$Input)
    if (Test-IsUrl $Input) { return $Input }
    if (Test-IsShorthand $Input) { return ConvertTo-RepoUrl $Input }
    Write-Die "Cannot resolve '$Input' as a URL or owner/repo shorthand"
}

function Invoke-ShallowClone {
    param([string]$Url, [string]$Commit = "")
    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "skills-registry-$(Get-Random)"
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

    if ($Commit) {
        git init $tmpDir --quiet
        git -C $tmpDir remote add origin $Url
        $fetched = $false
        try {
            git -C $tmpDir fetch --depth 1 origin $Commit --quiet 2>$null
            git -C $tmpDir checkout FETCH_HEAD --quiet 2>$null
            $fetched = $true
        } catch { }
        if (-not $fetched) {
            Remove-Item -Recurse -Force $tmpDir
            $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "skills-registry-$(Get-Random)"
            git clone --depth 1 $Url $tmpDir --quiet
        }
    } else {
        git clone --depth 1 $Url $tmpDir --quiet
        if ($LASTEXITCODE -ne 0) { Write-Die "Failed to clone $Url" }
    }
    return $tmpDir
}

function Get-RepoCommit {
    param([string]$RepoDir)
    return (git -C $RepoDir rev-parse HEAD).Trim()
}

function Remove-TempClone {
    param([string]$Dir)
    $tempRoot = [System.IO.Path]::GetTempPath()
    if ($Dir.StartsWith($tempRoot) -and (Test-Path $Dir)) {
        Remove-Item -Recurse -Force $Dir
    }
}

function Find-RepoItems {
    param([string]$RepoDir)
    $found = @()
    foreach ($subdir in @("skills", "agents", "instructions", ".claude/skills", ".agents/skills")) {
        $fullPath = Join-Path $RepoDir $subdir
        if (Test-Path $fullPath) {
            foreach ($itemDir in Get-ChildItem -Path $fullPath -Directory) {
                if (Test-Path (Join-Path $itemDir.FullName "manifest.yaml")) {
                    $found += $itemDir.FullName
                } elseif (Test-Path (Join-Path $itemDir.FullName "SKILL.md")) {
                    New-SyntheticManifest -ItemDir $itemDir.FullName | Out-Null
                    $found += $itemDir.FullName
                }
            }
        }
    }
    if (Test-Path (Join-Path $RepoDir "manifest.yaml")) {
        $found += $RepoDir
    } elseif (Test-Path (Join-Path $RepoDir "SKILL.md")) {
        New-SyntheticManifest -ItemDir $RepoDir | Out-Null
        $found += $RepoDir
    }
    return $found
}

function New-SyntheticManifest {
    param([string]$ItemDir)
    $skillMd = Join-Path $ItemDir "SKILL.md"
    $manifestPath = Join-Path $ItemDir "manifest.yaml"

    if (-not (Test-Path $skillMd)) { return $false }
    if (Test-Path $manifestPath) { return $true }

    $content = Get-Content $skillMd -Raw
    # Extract frontmatter
    if ($content -match '(?s)^---\r?\n(.+?)\r?\n---') {
        $fm = $Matches[1]
        $name = Read-YamlField -Content $fm -Key "name"
        $description = Read-YamlField -Content $fm -Key "description"
    }
    if (-not $name) { $name = Split-Path $ItemDir -Leaf }
    if (-not $description) { $description = "Skill imported from external repository" }

    @"
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
"@ | Set-Content -Path $manifestPath -Encoding UTF8
    return $true
}
```

- [ ] **Step 3: Commit**

```bash
git add bin/lib/git.sh bin/lib/git.ps1
git commit -m "feat: add git operations library (bash + powershell)"
```

---

### Task 4: Shared library — `lock.sh` + `lock.ps1`

**Files:**
- Create: `bin/lib/lock.sh`
- Create: `bin/lib/lock.ps1`
- Create: `tests/test-lock.sh`

- [ ] **Step 1: Write test for lock file operations**

Create `tests/test-lock.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bin/lib/common.sh"
source "$SCRIPT_DIR/../bin/lib/lock.sh"

TESTS_RUN=0
TESTS_PASSED=0

assert_eq() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  PASS: $label"
  else
    echo "  FAIL: $label"
    echo "    expected: '$expected'"
    echo "    actual:   '$actual'"
  fi
}

echo "=== test-lock.sh ==="

TMP_DIR="$(mktemp -d)"
LOCK_FILE="$TMP_DIR/.skills-lock.json"

# Test: new lock file creation
lock_init "$LOCK_FILE"
assert_eq "lock file created" "0" "$([[ -f "$LOCK_FILE" ]] && echo 0 || echo 1)"

CONTENT="$(cat "$LOCK_FILE")"
assert_eq "lock file has version" "0" "$(echo "$CONTENT" | grep -c '"version": 1')"
assert_eq "lock file has installed" "0" "$(echo "$CONTENT" | grep -c '"installed"')"

# Test: add an entry
lock_add_entry "$LOCK_FILE" \
  "test-skill" "skill" "1.0.0" \
  "local" "" "" \
  "claude-code,github-copilot" ""

CONTENT="$(cat "$LOCK_FILE")"
assert_eq "entry added" "0" "$(echo "$CONTENT" | grep -c '"test-skill"')"
assert_eq "entry has type" "0" "$(echo "$CONTENT" | grep -c '"type": "skill"')"
assert_eq "entry has source" "0" "$(echo "$CONTENT" | grep -c '"source": "local"')"

# Test: check if entry exists
assert_eq "lock_has_entry true" "0" "$(lock_has_entry "$LOCK_FILE" "test-skill" && echo 0 || echo 1)"
assert_eq "lock_has_entry false" "1" "$(lock_has_entry "$LOCK_FILE" "nonexistent" && echo 0 || echo 1)"

# Test: remove entry
lock_remove_entry "$LOCK_FILE" "test-skill"
assert_eq "entry removed" "0" "$(lock_has_entry "$LOCK_FILE" "test-skill" && echo 1 || echo 0)"

rm -rf "$TMP_DIR"

echo ""
echo "Results: $TESTS_PASSED / $TESTS_RUN passed"
[[ "$TESTS_PASSED" -eq "$TESTS_RUN" ]]
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tests/test-lock.sh
```

Expected: FAIL — `lock.sh` not found.

- [ ] **Step 3: Implement `bin/lib/lock.sh`**

The lock file is JSON. We use `sed`/`awk` for reads and template-based string building for writes to avoid requiring `jq`.

Create `bin/lib/lock.sh`:

```bash
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
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tests/test-lock.sh
```

Expected: All tests PASS.

- [ ] **Step 5: Implement `bin/lib/lock.ps1`**

Create `bin/lib/lock.ps1`:

```powershell
# lock.ps1 — .skills-lock.json management

function Initialize-LockFile {
    param([string]$Path)
    @{ version = 1; installed = @{} } | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
}

function Confirm-LockFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { Initialize-LockFile -Path $Path }
}

function Test-LockEntry {
    param([string]$Path, [string]$Name)
    if (-not (Test-Path $Path)) { return $false }
    $lock = Get-Content $Path -Raw | ConvertFrom-Json
    return $null -ne $lock.installed.PSObject.Properties[$Name]
}

function Add-LockEntry {
    param(
        [string]$Path, [string]$Name, [string]$Type, [string]$Version,
        [string]$Source, [string]$SourceUrl, [string]$SourceCommit,
        [string[]]$Agents, [string]$Profile
    )
    Confirm-LockFile -Path $Path
    $lock = Get-Content $Path -Raw | ConvertFrom-Json

    $entry = [ordered]@{
        type = $Type; version = $Version; source = $Source
        sourceUrl = if ($SourceUrl) { $SourceUrl } else { $null }
        sourceCommit = if ($SourceCommit) { $SourceCommit } else { $null }
        installedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        agents = $Agents
        profile = if ($Profile) { $Profile } else { $null }
    }

    if ($lock.installed.PSObject.Properties[$Name]) {
        $lock.installed.PSObject.Properties.Remove($Name)
    }
    $lock.installed | Add-Member -NotePropertyName $Name -NotePropertyValue ([PSCustomObject]$entry)
    $lock | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
}

function Remove-LockEntry {
    param([string]$Path, [string]$Name)
    if (-not (Test-Path $Path)) { return }
    $lock = Get-Content $Path -Raw | ConvertFrom-Json
    if ($lock.installed.PSObject.Properties[$Name]) {
        $lock.installed.PSObject.Properties.Remove($Name)
    }
    $lock | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
}

function Get-LockEntries {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return @() }
    $lock = Get-Content $Path -Raw | ConvertFrom-Json
    return $lock.installed.PSObject.Properties | ForEach-Object { $_.Name }
}

function Get-LockEntryField {
    param([string]$Path, [string]$Name, [string]$Field)
    if (-not (Test-Path $Path)) { return "" }
    $lock = Get-Content $Path -Raw | ConvertFrom-Json
    $entry = $lock.installed.PSObject.Properties[$Name]
    if ($entry) { return $entry.Value.$Field }
    return ""
}
```

- [ ] **Step 6: Commit**

```bash
git add bin/lib/lock.sh bin/lib/lock.ps1 tests/test-lock.sh
git commit -m "feat: add lock file management library (bash + powershell)"
```

---

### Task 5: Dispatchers — `skill` + `skill.ps1`

**Files:**
- Create: `bin/skill`
- Create: `bin/skill.ps1`

- [ ] **Step 1: Implement Bash dispatcher `bin/skill`**

Create `bin/skill`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_DIR="$SCRIPT_DIR/commands"
source "$SCRIPT_DIR/lib/common.sh"

VERSION="0.1.0"

usage() {
  cat <<EOF
${BOLD}skill${RESET} — AI skills registry CLI (v${VERSION})

${BOLD}Usage:${RESET}
  skill <command> [options]

${BOLD}Commands:${RESET}
  list          List all items in the registry
  search        Search items by keyword
  info          Show details for a single item
  install       Install items into a project
  uninstall     Remove installed items
  sync          Regenerate the registry index

${BOLD}Options:${RESET}
  --help, -h    Show this help message
  --version     Show version

Run ${CYAN}skill <command> --help${RESET} for command-specific help.
EOF
}

if [[ $# -eq 0 ]]; then
  usage
  exit 0
fi

CMD="$1"; shift

case "$CMD" in
  list|search|info|install|uninstall|sync)
    CMD_SCRIPT="$COMMANDS_DIR/${CMD}.sh"
    [[ -f "$CMD_SCRIPT" ]] || die "Command script not found: $CMD_SCRIPT"
    source "$CMD_SCRIPT" "$@"
    ;;
  --help|-h) usage; exit 0 ;;
  --version) echo "skill v${VERSION}"; exit 0 ;;
  *) die "Unknown command: $CMD\nRun 'skill --help' for usage." ;;
esac
```

- [ ] **Step 2: Implement PowerShell dispatcher `bin/skill.ps1`**

Create `bin/skill.ps1`:

```powershell
#Requires -Version 5.1
param([Parameter(ValueFromRemainingArguments)]$CmdArgs)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$CommandsDir = Join-Path $ScriptDir "commands"
. (Join-Path $ScriptDir "lib/common.ps1")

$Version = "0.1.0"

function Show-Usage {
    Write-Host "skill — AI skills registry CLI (v$Version)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:  skill <command> [options]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  list, search, info, install, uninstall, sync"
    Write-Host ""
    Write-Host "Run 'skill <command> --help' for command-specific help."
}

if ($CmdArgs.Count -eq 0) { Show-Usage; exit 0 }

$Cmd = $CmdArgs[0]
$Rest = @()
if ($CmdArgs.Count -gt 1) { $Rest = $CmdArgs[1..($CmdArgs.Count - 1)] }

switch ($Cmd) {
    { $_ -in @("list","search","info","install","uninstall","sync") } {
        $script = Join-Path $CommandsDir "$Cmd.ps1"
        if (-not (Test-Path $script)) { Write-Die "Command script not found: $script" }
        & $script @Rest
    }
    { $_ -in @("--help","-h") } { Show-Usage; exit 0 }
    "--version" { Write-Host "skill v$Version"; exit 0 }
    default { Write-Die "Unknown command: $Cmd`nRun 'skill --help' for usage." }
}
```

- [ ] **Step 3: Make bash dispatcher executable and test both**

```bash
chmod +x bin/skill
bin/skill --help
pwsh bin/skill.ps1 --help
```

Expected: Both print usage help.

- [ ] **Step 4: Commit**

```bash
git add bin/skill bin/skill.ps1
git commit -m "feat: add CLI dispatchers (bash + powershell)"
```

---

### Task 6: Command — `sync` (registry generation)

**Files:**
- Create: `bin/commands/sync.sh`
- Create: `bin/commands/sync.ps1`
- Create: `tests/test-sync.sh`
- Create: `tests/fixtures/sample-skill/manifest.yaml`
- Create: `tests/fixtures/sample-skill/SKILL.md`
- Create: `tests/fixtures/sample-instruction/manifest.yaml`
- Create: `tests/fixtures/sample-instruction/sample-instruction.instructions.md`

- [ ] **Step 1: Create test fixtures**

Create `tests/fixtures/sample-skill/manifest.yaml`:

```yaml
name: sample-skill
type: skill
description: A sample skill for testing the sync command.
tags:
  - testing
  - sample
targets:
  - claude-code
  - github-copilot
files:
  - SKILL.md
version: "1.0.0"
```

Create `tests/fixtures/sample-skill/SKILL.md`:

```markdown
# Sample Skill

This is a sample skill for testing.
```

Create `tests/fixtures/sample-instruction/manifest.yaml`:

```yaml
name: sample-instruction
type: instruction
description: A sample instruction for testing.
tags:
  - testing
targets:
  - claude-code
files:
  - sample-instruction.instructions.md
version: "0.1.0"
```

Create `tests/fixtures/sample-instruction/sample-instruction.instructions.md`:

```markdown
# Sample Instruction

Follow these instructions.
```

- [ ] **Step 2: Write test for sync command**

Create `tests/test-sync.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bin/lib/common.sh"

TESTS_RUN=0
TESTS_PASSED=0

assert_eq() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  PASS: $label"
  else
    echo "  FAIL: $label"
    echo "    expected: '$expected'"
    echo "    actual:   '$actual'"
  fi
}

echo "=== test-sync.sh ==="

TMP_DIR="$(mktemp -d)"
mkdir -p "$TMP_DIR/skills/sample-skill"
mkdir -p "$TMP_DIR/instructions/sample-instruction"
mkdir -p "$TMP_DIR/bin/lib" "$TMP_DIR/bin/commands"

cp "$SCRIPT_DIR/fixtures/sample-skill/manifest.yaml" "$TMP_DIR/skills/sample-skill/"
cp "$SCRIPT_DIR/fixtures/sample-skill/SKILL.md" "$TMP_DIR/skills/sample-skill/"
cp "$SCRIPT_DIR/fixtures/sample-instruction/manifest.yaml" "$TMP_DIR/instructions/sample-instruction/"
cp "$SCRIPT_DIR/fixtures/sample-instruction/sample-instruction.instructions.md" \
   "$TMP_DIR/instructions/sample-instruction/"
cp "$SCRIPT_DIR/../bin/lib/common.sh" "$TMP_DIR/bin/lib/"
cp "$SCRIPT_DIR/../bin/commands/sync.sh" "$TMP_DIR/bin/commands/"

REGISTRY_ROOT="$TMP_DIR" bash "$TMP_DIR/bin/commands/sync.sh"

assert_eq "registry.json exists" "0" "$([[ -f "$TMP_DIR/registry.json" ]] && echo 0 || echo 1)"

REGISTRY="$(cat "$TMP_DIR/registry.json")"
assert_eq "contains sample-skill" "0" "$(echo "$REGISTRY" | grep -c '"sample-skill"')"
assert_eq "contains sample-instruction" "0" "$(echo "$REGISTRY" | grep -c '"sample-instruction"')"
assert_eq "has type skill" "0" "$(echo "$REGISTRY" | grep -c '"type": "skill"')"
assert_eq "has type instruction" "0" "$(echo "$REGISTRY" | grep -c '"type": "instruction"')"
assert_eq "total 2 items" "2" "$(echo "$REGISTRY" | grep -c '"name":')"

rm -rf "$TMP_DIR"

echo ""
echo "Results: $TESTS_PASSED / $TESTS_RUN passed"
[[ "$TESTS_PASSED" -eq "$TESTS_RUN" ]]
```

- [ ] **Step 3: Run test to verify it fails**

```bash
bash tests/test-sync.sh
```

Expected: FAIL — `sync.sh` not found.

- [ ] **Step 4: Implement `bin/commands/sync.sh`**

Create `bin/commands/sync.sh`:

```bash
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
      tags_json="[$(echo "$mc" | yaml_read_list tags | sed 's/.*/"&"/' | paste -sd, -)]"
      targets_json="[$(echo "$mc" | yaml_read_list targets | sed 's/.*/"&"/' | paste -sd, -)]"
      files_json="[$(echo "$mc" | yaml_read_list files | sed 's/.*/"&"/' | paste -sd, -)]"
      deps_json="[$(echo "$mc" | yaml_read_list dependencies | sed 's/.*/"&"/' | paste -sd, -)]"

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
```

- [ ] **Step 5: Run test to verify it passes**

```bash
bash tests/test-sync.sh
```

Expected: All tests PASS.

- [ ] **Step 6: Implement `bin/commands/sync.ps1`**

Create `bin/commands/sync.ps1`:

```powershell
# sync.ps1 — regenerate registry.json

$CmdDir = $PSScriptRoot
. (Join-Path $CmdDir "../lib/common.ps1")

$RegistryRoot = if ($env:REGISTRY_ROOT) { $env:REGISTRY_ROOT } else { Resolve-RegistryRoot }
$OutputFile = Join-Path $RegistryRoot "registry.json"

$items = @()
foreach ($contentDir in @("skills", "agents", "instructions")) {
    $dirPath = Join-Path $RegistryRoot $contentDir
    if (-not (Test-Path $dirPath)) { continue }

    foreach ($itemDir in Get-ChildItem -Path $dirPath -Directory) {
        $mp = Join-Path $itemDir.FullName "manifest.yaml"
        if (-not (Test-Path $mp)) { continue }

        $c = Get-Content $mp -Raw
        $version = Read-YamlField -Content $c -Key "version"
        if (-not $version) { $version = "0.0.0" }

        $items += [ordered]@{
            name         = Read-YamlField -Content $c -Key "name"
            type         = Read-YamlField -Content $c -Key "type"
            description  = Read-YamlField -Content $c -Key "description"
            tags         = @(Read-YamlList -Content $c -Key "tags")
            targets      = @(Read-YamlList -Content $c -Key "targets")
            files        = @(Read-YamlList -Content $c -Key "files")
            dependencies = @(Read-YamlList -Content $c -Key "dependencies")
            version      = $version
            path         = "$contentDir/$($itemDir.Name)"
        }
    }
}

[ordered]@{
    version     = 1
    generatedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    items       = $items
} | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputFile -Encoding UTF8

Write-Info "Registry updated: $($items.Count) items -> registry.json"
```

- [ ] **Step 7: Commit**

```bash
git add bin/commands/sync.sh bin/commands/sync.ps1 tests/test-sync.sh tests/fixtures/
git commit -m "feat: add sync command — generates registry.json (bash + powershell)"
```

---

### Task 7: Command — `list`

**Files:**
- Create: `bin/commands/list.sh`
- Create: `bin/commands/list.ps1`

- [ ] **Step 1: Implement `bin/commands/list.sh`**

Create `bin/commands/list.sh`:

```bash
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
```

- [ ] **Step 2: Implement `bin/commands/list.ps1`**

Create `bin/commands/list.ps1`:

```powershell
# list.ps1 — list all items in the registry

param(
    [string]$Type,
    [string]$Tag,
    [string]$For
)

$CmdDir = $PSScriptRoot
. (Join-Path $CmdDir "../lib/common.ps1")

$RegistryRoot = if ($env:REGISTRY_ROOT) { $env:REGISTRY_ROOT } else { Resolve-RegistryRoot }
$RegistryFile = Join-Path $RegistryRoot "registry.json"

# Parse args
$i = 0
while ($i -lt $args.Count) {
    switch ($args[$i]) {
        "--type" { $Type = $args[++$i] }
        "--tag"  { $Tag = $args[++$i] }
        "--for"  { $For = $args[++$i] }
        { $_ -in @("--help","-h") } {
            Write-Host "Usage: skill list [--type <type>] [--tag <tag>] [--for <agent>]"
            exit 0
        }
    }
    $i++
}

if (-not (Test-Path $RegistryFile)) {
    Write-Warn "No registry.json found. Run 'skill sync' first."
    exit 1
}

$registry = Get-Content $RegistryFile -Raw | ConvertFrom-Json
$items = $registry.items

if ($Type) { $items = $items | Where-Object { $_.type -eq $Type } }
if ($Tag)  { $items = $items | Where-Object { $_.tags -contains $Tag } }
if ($For)  { $items = $items | Where-Object { $_.targets -contains $For } }

$items | Format-Table @(
    @{Label="NAME"; Expression={$_.name}; Width=30}
    @{Label="TYPE"; Expression={$_.type}; Width=12}
    @{Label="VERSION"; Expression={$_.version}; Width=8}
    @{Label="DESCRIPTION"; Expression={
        if ($_.description.Length -gt 50) { $_.description.Substring(0,47) + "..." } else { $_.description }
    }}
) -AutoSize
```

- [ ] **Step 3: Test manually**

```bash
# Ensure registry.json exists first (from a previous sync)
bin/skill list
bin/skill list --type skill
```

Expected: Table output showing items filtered correctly.

- [ ] **Step 4: Commit**

```bash
git add bin/commands/list.sh bin/commands/list.ps1
git commit -m "feat: add list command with type/tag/agent filtering"
```

---

### Task 8: Command — `search`

**Files:**
- Create: `bin/commands/search.sh`
- Create: `bin/commands/search.ps1`

- [ ] **Step 1: Implement `bin/commands/search.sh`**

Create `bin/commands/search.sh`:

```bash
#!/usr/bin/env bash
# search.sh — full-text search across registry items

CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CMD_DIR/../lib/common.sh"

REGISTRY_ROOT="${REGISTRY_ROOT:-$(resolve_registry_root)}"
REGISTRY_FILE="$REGISTRY_ROOT/registry.json"

QUERY=""
FILTER_TYPE=""
FILTER_TAG=""
FILTER_FOR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)  FILTER_TYPE="$2"; shift 2 ;;
    --tag)   FILTER_TAG="$2"; shift 2 ;;
    --for)   FILTER_FOR="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: skill search <query> [--type <type>] [--tag <tag>] [--for <agent>]"
      exit 0 ;;
    -*)
      die "Unknown flag: $1" ;;
    *)
      QUERY="$1"; shift ;;
  esac
done

if [[ -z "$QUERY" ]]; then
  die "Usage: skill search <query>"
fi

if [[ ! -f "$REGISTRY_FILE" ]]; then
  warn "No registry.json found. Run 'skill sync' first."
  exit 1
fi

# Convert query to lowercase for case-insensitive matching
QUERY_LOWER="$(echo "$QUERY" | tr '[:upper:]' '[:lower:]')"

awk -v query="$QUERY_LOWER" -v filter_type="$FILTER_TYPE" -v filter_tag="$FILTER_TAG" -v filter_for="$FILTER_FOR" '
BEGIN {
  in_item=0; name=""; type=""; desc=""; version=""; tags=""; targets=""; count=0
}

/"name":/ {
  gsub(/[",]/, ""); sub(/.*: /, ""); name=$0
}
/"type":/ {
  gsub(/[",]/, ""); sub(/.*: /, ""); type=$0
}
/"description":/ {
  gsub(/"/, ""); sub(/.*: /, ""); desc=$0
}
/"version":/ {
  gsub(/[",]/, ""); sub(/.*: /, ""); version=$0
}
/"tags":/ { tags=$0 }
/"targets":/ { targets=$0 }

/"path":/ {
  # Check filters
  show=1
  if (filter_type != "" && type != filter_type) show=0
  if (filter_tag != "" && index(tags, filter_tag) == 0) show=0
  if (filter_for != "" && index(targets, filter_for) == 0) show=0

  # Check search query against name, description, tags
  if (show) {
    searchable = tolower(name " " desc " " tags)
    if (index(searchable, query) == 0) show=0
  }

  if (show) {
    if (count == 0) {
      printf "%-30s %-12s %-8s %s\n", "NAME", "TYPE", "VERSION", "DESCRIPTION"
      printf "%-30s %-12s %-8s %s\n", "----", "----", "-------", "-----------"
    }
    if (length(desc) > 50) desc = substr(desc, 1, 47) "..."
    printf "%-30s %-12s %-8s %s\n", name, type, version, desc
    count++
  }
  name=""; type=""; desc=""; version=""; tags=""; targets=""
}

END {
  if (count == 0) print "No items found matching: " query
}
' "$REGISTRY_FILE"
```

- [ ] **Step 2: Implement `bin/commands/search.ps1`**

Create `bin/commands/search.ps1`:

```powershell
# search.ps1 — full-text search across registry

$CmdDir = $PSScriptRoot
. (Join-Path $CmdDir "../lib/common.ps1")

$RegistryRoot = if ($env:REGISTRY_ROOT) { $env:REGISTRY_ROOT } else { Resolve-RegistryRoot }
$RegistryFile = Join-Path $RegistryRoot "registry.json"

$Query = ""; $Type = ""; $Tag = ""; $For = ""
$i = 0
while ($i -lt $args.Count) {
    switch ($args[$i]) {
        "--type" { $Type = $args[++$i] }
        "--tag"  { $Tag = $args[++$i] }
        "--for"  { $For = $args[++$i] }
        { $_ -in @("--help","-h") } {
            Write-Host "Usage: skill search <query> [--type <type>] [--tag <tag>] [--for <agent>]"
            exit 0
        }
        default { if (-not $_.StartsWith("-")) { $Query = $_ } else { Write-Die "Unknown flag: $_" } }
    }
    $i++
}

if (-not $Query) { Write-Die "Usage: skill search <query>" }
if (-not (Test-Path $RegistryFile)) { Write-Warn "No registry.json found. Run 'skill sync' first."; exit 1 }

$registry = Get-Content $RegistryFile -Raw | ConvertFrom-Json
$items = $registry.items

if ($Type) { $items = $items | Where-Object { $_.type -eq $Type } }
if ($Tag)  { $items = $items | Where-Object { $_.tags -contains $Tag } }
if ($For)  { $items = $items | Where-Object { $_.targets -contains $For } }

$ql = $Query.ToLower()
$items = $items | Where-Object {
    $searchable = "$($_.name) $($_.description) $($_.tags -join ' ')".ToLower()
    $searchable.Contains($ql)
}

if ($items.Count -eq 0) {
    Write-Host "No items found matching: $Query"
} else {
    $items | Format-Table @(
        @{Label="NAME"; Expression={$_.name}; Width=30}
        @{Label="TYPE"; Expression={$_.type}; Width=12}
        @{Label="VERSION"; Expression={$_.version}; Width=8}
        @{Label="DESCRIPTION"; Expression={
            if ($_.description.Length -gt 50) { $_.description.Substring(0,47) + "..." } else { $_.description }
        }}
    ) -AutoSize
}
```

- [ ] **Step 3: Commit**

```bash
git add bin/commands/search.sh bin/commands/search.ps1
git commit -m "feat: add search command with full-text matching"
```

---

### Task 9: Command — `info`

**Files:**
- Create: `bin/commands/info.sh`
- Create: `bin/commands/info.ps1`

- [ ] **Step 1: Implement `bin/commands/info.sh`**

Create `bin/commands/info.sh`:

```bash
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
found && /"description":/ { gsub(/"/, ""); sub(/.*: /, ""); desc=$0 }
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
  gsub(/[\[\]"]/, "", tags_line); sub(/.*: /, "", tags_line)
  printf "  Tags:         %s\n", tags_line

  gsub(/[\[\]"]/, "", targets_line); sub(/.*: /, "", targets_line)
  printf "  Targets:      %s\n", targets_line

  gsub(/[\[\]"]/, "", files_line); sub(/.*: /, "", files_line)
  printf "  Files:        %s\n", files_line

  gsub(/[\[\]"]/, "", deps_line); sub(/.*: /, "", deps_line)
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
```

- [ ] **Step 2: Implement `bin/commands/info.ps1`**

Create `bin/commands/info.ps1`:

```powershell
# info.ps1 — show full details for a single item

$CmdDir = $PSScriptRoot
. (Join-Path $CmdDir "../lib/common.ps1")

$RegistryRoot = if ($env:REGISTRY_ROOT) { $env:REGISTRY_ROOT } else { Resolve-RegistryRoot }
$RegistryFile = Join-Path $RegistryRoot "registry.json"

if ($args.Count -eq 0 -or $args[0] -in @("--help", "-h")) {
    Write-Host "Usage: skill info <name>"
    exit 0
}

$Name = $args[0]

if (-not (Test-Path $RegistryFile)) {
    Write-Warn "No registry.json found. Run 'skill sync' first."
    exit 1
}

$registry = Get-Content $RegistryFile -Raw | ConvertFrom-Json
$item = $registry.items | Where-Object { $_.name -eq $Name }

if (-not $item) {
    Write-Die "Item not found: $Name"
}

Write-Host ""
Write-Host "  $($item.name)  ($($item.type) v$($item.version))" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Description:  $($item.description)"
Write-Host "  Path:         $($item.path)"
Write-Host "  Tags:         $($item.tags -join ', ')"
Write-Host "  Targets:      $($item.targets -join ', ')"
Write-Host "  Files:        $($item.files -join ', ')"
if ($item.dependencies.Count -gt 0) {
    Write-Host "  Dependencies: $($item.dependencies -join ', ')"
}
Write-Host ""
```

- [ ] **Step 3: Commit**

```bash
git add bin/commands/info.sh bin/commands/info.ps1
git commit -m "feat: add info command — display single item details"
```

---

### Task 10: Command — `install` (local source)

The install command is the most complex. We build it in three tasks: local install (this task), remote install (Task 11), and lock-file restore (Task 12).

**Files:**
- Create: `bin/commands/install.sh`
- Create: `bin/commands/install.ps1`
- Create: `tests/test-install.sh`

- [ ] **Step 1: Write test for local install**

Create `tests/test-install.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bin/lib/common.sh"
source "$SCRIPT_DIR/../bin/lib/agents.sh"
source "$SCRIPT_DIR/../bin/lib/lock.sh"

TESTS_RUN=0
TESTS_PASSED=0

assert_eq() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  PASS: $label"
  else
    echo "  FAIL: $label"
    echo "    expected: '$expected'"
    echo "    actual:   '$actual'"
  fi
}

echo "=== test-install.sh ==="

# Set up temp registry with a skill
REG_DIR="$(mktemp -d)"
mkdir -p "$REG_DIR/skills/sample-skill"
mkdir -p "$REG_DIR/bin/lib" "$REG_DIR/bin/commands"

cp "$SCRIPT_DIR/fixtures/sample-skill/manifest.yaml" "$REG_DIR/skills/sample-skill/"
cp "$SCRIPT_DIR/fixtures/sample-skill/SKILL.md" "$REG_DIR/skills/sample-skill/"
cp "$SCRIPT_DIR/../bin/lib/"*.sh "$REG_DIR/bin/lib/"
cp "$SCRIPT_DIR/../bin/commands/sync.sh" "$REG_DIR/bin/commands/"
cp "$SCRIPT_DIR/../bin/commands/install.sh" "$REG_DIR/bin/commands/"

# Generate registry
REGISTRY_ROOT="$REG_DIR" bash "$REG_DIR/bin/commands/sync.sh" >/dev/null

# Set up target project directory
TARGET_DIR="$(mktemp -d)"

# Install with explicit agent and --yes to skip prompts
export SKILL_YES=1
REGISTRY_ROOT="$REG_DIR" bash "$REG_DIR/bin/commands/install.sh" \
  "sample-skill" --target "$TARGET_DIR" --agent claude-code --agent github-copilot

# Verify files were copied
assert_eq "claude-code skill dir exists" "0" \
  "$([[ -d "$TARGET_DIR/.claude/skills/sample-skill" ]] && echo 0 || echo 1)"
assert_eq "claude-code SKILL.md copied" "0" \
  "$([[ -f "$TARGET_DIR/.claude/skills/sample-skill/SKILL.md" ]] && echo 0 || echo 1)"
assert_eq "copilot skill dir exists" "0" \
  "$([[ -d "$TARGET_DIR/.github/copilot/skills/sample-skill" ]] && echo 0 || echo 1)"
assert_eq "copilot SKILL.md copied" "0" \
  "$([[ -f "$TARGET_DIR/.github/copilot/skills/sample-skill/SKILL.md" ]] && echo 0 || echo 1)"

# Verify lock file
LOCK_FILE="$TARGET_DIR/.skills-lock.json"
assert_eq "lock file created" "0" "$([[ -f "$LOCK_FILE" ]] && echo 0 || echo 1)"
assert_eq "lock has entry" "0" "$(lock_has_entry "$LOCK_FILE" "sample-skill" && echo 0 || echo 1)"

# Clean up
rm -rf "$REG_DIR" "$TARGET_DIR"
unset SKILL_YES

echo ""
echo "Results: $TESTS_PASSED / $TESTS_RUN passed"
[[ "$TESTS_PASSED" -eq "$TESTS_RUN" ]]
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tests/test-install.sh
```

Expected: FAIL — `install.sh` not found.

- [ ] **Step 3: Implement `bin/commands/install.sh`**

Create `bin/commands/install.sh`:

```bash
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

# --- Profile install (delegates to Task 13) ---
if [[ -n "$PROFILE" ]]; then
  source "$CMD_DIR/../lib/profile.sh" 2>/dev/null || die "Profile support not yet implemented"
  install_profile "$PROFILE" "$TARGET_DIR" "$GLOBAL_INSTALL" "$USE_SYMLINK" "${AGENTS[*]}"
  exit $?
fi

# --- Lock-file restore (no args) ---
if [[ -z "$POSITIONAL" ]]; then
  LOCK_FILE="$TARGET_DIR/.skills-lock.json"
  if [[ ! -f "$LOCK_FILE" ]]; then
    die "No item specified and no .skills-lock.json found in $TARGET_DIR"
  fi
  # Delegate to lock restore logic (Task 12)
  source "$CMD_DIR/../lib/lock-restore.sh" 2>/dev/null || die "Lock restore not yet implemented"
  restore_from_lock "$LOCK_FILE" "$TARGET_DIR" "$USE_SYMLINK"
  exit $?
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
[[ -n "$TEMP_CLONE" ]] && cleanup_temp "$TEMP_CLONE"
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tests/test-install.sh
```

Expected: All tests PASS.

- [ ] **Step 5: Implement `bin/commands/install.ps1`**

Create `bin/commands/install.ps1`:

```powershell
# install.ps1 — install skills/agents/instructions into a target project

$CmdDir = $PSScriptRoot
. (Join-Path $CmdDir "../lib/common.ps1")
. (Join-Path $CmdDir "../lib/agents.ps1")
. (Join-Path $CmdDir "../lib/git.ps1")
. (Join-Path $CmdDir "../lib/lock.ps1")

$RegistryRoot = if ($env:REGISTRY_ROOT) { $env:REGISTRY_ROOT } else { Resolve-RegistryRoot }
$RegistryFile = Join-Path $RegistryRoot "registry.json"

# Parse arguments
$TargetDir = Get-Location | Select-Object -ExpandProperty Path
$GlobalInstall = $false
$UseSymlink = $false
$AgentArgs = @()
$SkillArgs = @()
$Profile = ""
$Ref = ""
$Positional = ""

$i = 0
while ($i -lt $args.Count) {
    switch ($args[$i]) {
        "--target"   { $TargetDir = $args[++$i] }
        { $_ -in @("--global","-g") } { $GlobalInstall = $true }
        "--symlink"  { $UseSymlink = $true }
        { $_ -in @("--agent","-a") }  { $AgentArgs += $args[++$i] }
        { $_ -in @("--skill","-s") }  { $SkillArgs += $args[++$i] }
        "--profile"  { $Profile = $args[++$i] }
        "--ref"      { $Ref = $args[++$i] }
        { $_ -in @("--yes","-y") }    { $env:SKILL_YES = "1" }
        { $_ -in @("--help","-h") }   {
            Write-Host "Usage: skill install [<name|url>] [options]"; exit 0
        }
        default {
            if ($_.StartsWith("-")) { Write-Die "Unknown flag: $_" }
            else { $Positional = $_ }
        }
    }
    $i++
}

# Lock-file restore (no args)
if (-not $Positional -and -not $Profile) {
    $lockPath = Join-Path $TargetDir ".skills-lock.json"
    if (-not (Test-Path $lockPath)) {
        Write-Die "No item specified and no .skills-lock.json found in $TargetDir"
    }
    # Delegate to lock restore (Task 12)
    Write-Die "Lock restore not yet implemented"
}

# Profile install (Task 13)
if ($Profile) { Write-Die "Profile install not yet implemented" }

# Resolve source
$ItemName = ""; $ItemDir = ""; $SourceType = "local"
$SourceUrl = ""; $SourceCommit = ""; $TempClone = ""

if ((Test-IsUrl $Positional) -or (Test-IsShorthand $Positional)) {
    $SourceType = "remote"
    $SourceUrl = Resolve-RepoUrl $Positional
    Write-Host "Cloning $SourceUrl..."
    $TempClone = Invoke-ShallowClone -Url $SourceUrl -Commit $Ref
    $SourceCommit = Get-RepoCommit -RepoDir $TempClone

    $foundItems = Find-RepoItems -RepoDir $TempClone
    if ($foundItems.Count -eq 0) {
        Remove-TempClone $TempClone
        Write-Die "No items found in $Positional"
    }

    if ($SkillArgs.Count -gt 0) {
        $foundItems = $foundItems | Where-Object {
            $manifest = Join-Path $_ "manifest.yaml"
            if (Test-Path $manifest) {
                $n = Read-YamlField -Content (Get-Content $manifest -Raw) -Key "name"
                $n -in $SkillArgs
            } else { (Split-Path $_ -Leaf) -in $SkillArgs }
        }
    }

    $ItemDir = $foundItems | Select-Object -First 1
    $manifest = Join-Path $ItemDir "manifest.yaml"
    if (Test-Path $manifest) {
        $ItemName = Read-YamlField -Content (Get-Content $manifest -Raw) -Key "name"
    } else { $ItemName = Split-Path $ItemDir -Leaf }
} else {
    $ItemName = $Positional
    if (-not (Test-Path $RegistryFile)) { Write-Die "No registry.json. Run 'skill sync' first." }

    $reg = Get-Content $RegistryFile -Raw | ConvertFrom-Json
    $item = $reg.items | Where-Object { $_.name -eq $ItemName }
    if (-not $item) { Write-Die "Item not found: $ItemName" }
    $ItemDir = Join-Path $RegistryRoot $item.path
}

# Read manifest
$manifestPath = Join-Path $ItemDir "manifest.yaml"
if (-not (Test-Path $manifestPath)) { Write-Die "No manifest.yaml in $ItemDir" }

$mc = Get-Content $manifestPath -Raw
$ItemType = Read-YamlField -Content $mc -Key "type"
$ItemVersion = Read-YamlField -Content $mc -Key "version"
if (-not $ItemVersion) { $ItemVersion = "0.0.0" }
$ItemTargets = Read-YamlList -Content $mc -Key "targets"
$ItemFiles = Read-YamlList -Content $mc -Key "files"

# Select agents
if ($AgentArgs.Count -eq 0) {
    $Selected = Select-Agents -Compatible $ItemTargets
} else {
    $Selected = $AgentArgs
}

if ($Selected.Count -eq 0) {
    Write-Warn "No agents selected."
    if ($TempClone) { Remove-TempClone $TempClone }
    exit 0
}

# Install files
$lockPath = if ($GlobalInstall) { Join-Path $HOME ".skills-lock.json" } else { Join-Path $TargetDir ".skills-lock.json" }

foreach ($agent in $Selected) {
    $basePath = if ($GlobalInstall) { Get-GlobalPath $agent } else { Join-Path $TargetDir (Get-ProjectPath $agent) }
    if (-not $basePath) { Write-Warn "Unknown agent: $agent"; continue }

    $destDir = Join-Path $basePath $ItemName
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null

    foreach ($file in $ItemFiles) {
        $src = Join-Path $ItemDir $file
        $dst = Join-Path $destDir $file
        if (-not (Test-Path $src)) { Write-Warn "File not found: $src"; continue }

        if (Test-Path $dst) {
            if ((Get-FileHash $src).Hash -eq (Get-FileHash $dst).Hash) { continue }
            if (-not (Confirm-Prompt "File exists and differs: $dst. Overwrite?")) { continue }
        }

        $dstParent = Split-Path $dst -Parent
        New-Item -ItemType Directory -Path $dstParent -Force | Out-Null

        if ($UseSymlink) {
            New-Item -ItemType SymbolicLink -Path $dst -Target $src -Force | Out-Null
        } else {
            Copy-Item $src $dst -Force
        }
    }

    $relDest = if ($GlobalInstall) { $destDir } else { $destDir.Replace("$TargetDir\", "").Replace("\", "/") }
    Write-Host "  -> ${agent}: $relDest"
}

# Update lock
Add-LockEntry -Path $lockPath -Name $ItemName -Type $ItemType -Version $ItemVersion `
    -Source $SourceType -SourceUrl $SourceUrl -SourceCommit $SourceCommit `
    -Agents $Selected -Profile ""

Write-Info "Installed $ItemName ($ItemType v$ItemVersion)"
Write-Host "  Lock file updated: $(Split-Path $lockPath -Leaf)"

if ($TempClone) { Remove-TempClone $TempClone }
```

- [ ] **Step 6: Commit**

```bash
git add bin/commands/install.sh bin/commands/install.ps1 tests/test-install.sh
git commit -m "feat: add install command — local and remote sources"
```

---

### Task 11: Verify — synthetic manifests + remote install

> **Note:** The `generate_synthetic_manifest` / `New-SyntheticManifest` functions were integrated into Task 3 (git.sh / git.ps1). This task is a verification checkpoint.

**Files:** None (verification only)

- [ ] **Step 1: Create a test repo without manifest.yaml**

```bash
TMP_REPO="$(mktemp -d)"
mkdir -p "$TMP_REPO/skills/no-manifest-skill"
cat > "$TMP_REPO/skills/no-manifest-skill/SKILL.md" <<'EOF'
---
name: no-manifest-skill
description: Test skill without a manifest.yaml
---

# No Manifest Skill

This skill has no manifest.yaml — the CLI should generate one.
EOF
git -C "$TMP_REPO" init --quiet
git -C "$TMP_REPO" add -A
git -C "$TMP_REPO" commit -m "init" --quiet
```

- [ ] **Step 2: Verify `scan_repo_for_items` generates a synthetic manifest**

```bash
source bin/lib/common.sh
source bin/lib/git.sh

ITEMS="$(scan_repo_for_items "$TMP_REPO")"
echo "Found items: $ITEMS"

# Verify manifest was generated
MANIFEST="$TMP_REPO/skills/no-manifest-skill/manifest.yaml"
[[ -f "$MANIFEST" ]] && echo "PASS: synthetic manifest created" || echo "FAIL: no manifest"
cat "$MANIFEST"

rm -rf "$TMP_REPO"
```

Expected: Synthetic manifest exists with name, type, description, targets, files populated.

- [ ] **Step 3: Verify remote install works end-to-end (manual)**

If a public test repo is available, run:

```bash
bin/skill install <owner/repo-without-manifests> --skill <name> --target /tmp/test-project -a claude-code -y
```

Confirm that the skill is installed and the lock file is created.

---

### Task 12: Command — `install` (lock file restore)

When `skill install` is run with no arguments in a project with `.skills-lock.json`, restore all entries.

**Files:**
- Modify: `bin/commands/install.sh` — implement lock restore inline (remove placeholder)
- Modify: `bin/commands/install.ps1` — same

- [ ] **Step 1: Replace lock restore placeholder in `bin/commands/install.sh`**

Replace the lock-file restore section in `install.sh`:

```bash
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
```

- [ ] **Step 2: Replace lock restore placeholder in `bin/commands/install.ps1`**

Replace the lock restore section:

```powershell
if (-not $Positional -and -not $Profile) {
    $lockPath = Join-Path $TargetDir ".skills-lock.json"
    if (-not (Test-Path $lockPath)) {
        Write-Die "No item specified and no .skills-lock.json found in $TargetDir"
    }

    Write-Host "Restoring from .skills-lock.json..."
    $entries = Get-LockEntries -Path $lockPath
    $count = 0

    foreach ($entryName in $entries) {
        $source = Get-LockEntryField -Path $lockPath -Name $entryName -Field "source"
        $url = Get-LockEntryField -Path $lockPath -Name $entryName -Field "sourceUrl"
        $commit = Get-LockEntryField -Path $lockPath -Name $entryName -Field "sourceCommit"

        $restoreArgs = @("--target", $TargetDir, "--yes")
        $agents = Get-LockEntryField -Path $lockPath -Name $entryName -Field "agents"
        # Parse agents from the stored value
        if ($agents -is [array]) {
            foreach ($a in $agents) { $restoreArgs += @("--agent", $a) }
        }

        if ($source -eq "remote" -and $url) {
            $refArgs = @()
            if ($commit) { $refArgs = @("--ref", $commit) }
            & (Join-Path $CmdDir "install.ps1") $url @restoreArgs @refArgs --skill $entryName
        } else {
            & (Join-Path $CmdDir "install.ps1") $entryName @restoreArgs
        }
        $count++
    }

    Write-Info "Restored $count items from lock file"
    exit 0
}
```

- [ ] **Step 3: Commit**

```bash
git add bin/commands/install.sh bin/commands/install.ps1
git commit -m "feat: add lock file restore — skill install with no args"
```

---

### Task 13: Command — `install --profile`

**Files:**
- Create: `bin/lib/profile.sh`
- Create: `bin/lib/profile.ps1`
- Modify: `bin/commands/install.sh` — wire up profile support
- Modify: `bin/commands/install.ps1` — same

- [ ] **Step 1: Implement `bin/lib/profile.sh`**

Create `bin/lib/profile.sh`:

```bash
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

    # Update the lock entry to record the profile
    local lock_file="$target_dir/.skills-lock.json"
    [[ "$global_install" == "true" ]] && lock_file="$HOME/.skills-lock.json"

    # The lock entry is already created by the recursive install call.
    # Profile name is not stored in the lock entry for v1 — see Backlog.

    count=$((count + 1))
  done <<< "$items"

  echo ""
  info "Profile '$profile_name' installed: $count items"
}
```

- [ ] **Step 2: Implement `bin/lib/profile.ps1`**

Create `bin/lib/profile.ps1`:

```powershell
# profile.ps1 — profile loading and installation

function Install-Profile {
    param(
        [string]$ProfileName, [string]$TargetDir,
        [bool]$GlobalInstall, [bool]$UseSymlink, [string[]]$AgentsOverride
    )

    $RegistryRoot = if ($env:REGISTRY_ROOT) { $env:REGISTRY_ROOT } else { Resolve-RegistryRoot }
    $profileFile = Join-Path $RegistryRoot "profiles/$ProfileName.yaml"
    if (-not (Test-Path $profileFile)) { Write-Die "Profile not found: $ProfileName" }

    $content = Get-Content $profileFile -Raw
    $description = Read-YamlField -Content $content -Key "description"

    Write-Host "`nInstalling profile: $ProfileName" -ForegroundColor Cyan
    if ($description) { Write-Host "  $description" }
    Write-Host ""

    # Parse items
    $lines = $content -split "`n"
    $inItems = $false; $items = @()
    $currentItem = @{}

    foreach ($line in $lines) {
        if ($line -match '^items:') { $inItems = $true; continue }
        if ($inItems -and $line -match '^\S' -and $line -notmatch '^items:') { break }
        if ($inItems -and $line -match '^\s+-\s+name:\s*(.+)') {
            if ($currentItem.Count -gt 0) { $items += [PSCustomObject]$currentItem }
            $currentItem = @{ name = $Matches[1].Trim(); source = ""; ref = "" }
        }
        if ($inItems -and $line -match '^\s+source:\s*(.+)') { $currentItem.source = $Matches[1].Trim() }
        if ($inItems -and $line -match '^\s+ref:\s*(.+)') { $currentItem.ref = $Matches[1].Trim() }
    }
    if ($currentItem.Count -gt 0) { $items += [PSCustomObject]$currentItem }

    $installScript = Join-Path $PSScriptRoot "install.ps1"
    $count = 0

    foreach ($item in $items) {
        Write-Host "  Installing: $($item.name) (from $($item.source))..."

        $installArgs = @("--target", $TargetDir, "--yes")
        if ($GlobalInstall) { $installArgs += "--global" }
        if ($UseSymlink) { $installArgs += "--symlink" }
        foreach ($a in $AgentsOverride) { $installArgs += @("--agent", $a) }

        if ($item.source -eq "local") {
            & $installScript $item.name @installArgs
        } else {
            & $installScript $item.source @installArgs --skill $item.name
        }
        $count++
    }

    Write-Host ""
    Write-Info "Profile '$ProfileName' installed: $count items"
}
```

- [ ] **Step 3: Wire profile support into install.sh**

In `bin/commands/install.sh`, replace the profile placeholder:

```bash
# --- Profile install ---
if [[ -n "$PROFILE" ]]; then
  source "$CMD_DIR/../lib/profile.sh"
  install_profile "$PROFILE" "$TARGET_DIR" "$GLOBAL_INSTALL" "$USE_SYMLINK" "${AGENTS[*]}"
  exit $?
fi
```

In `bin/commands/install.ps1`, replace the profile placeholder:

```powershell
if ($Profile) {
    . (Join-Path $CmdDir "../lib/profile.ps1")
    Install-Profile -ProfileName $Profile -TargetDir $TargetDir `
        -GlobalInstall $GlobalInstall -UseSymlink $UseSymlink -AgentsOverride $AgentArgs
    exit 0
}
```

- [ ] **Step 4: Commit**

```bash
git add bin/lib/profile.sh bin/lib/profile.ps1 bin/commands/install.sh bin/commands/install.ps1
git commit -m "feat: add profile install support"
```

---

### Task 14: Command — `uninstall`

**Files:**
- Create: `bin/commands/uninstall.sh`
- Create: `bin/commands/uninstall.ps1`
- Create: `tests/test-uninstall.sh`

- [ ] **Step 1: Write test for uninstall**

Create `tests/test-uninstall.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bin/lib/common.sh"
source "$SCRIPT_DIR/../bin/lib/agents.sh"
source "$SCRIPT_DIR/../bin/lib/lock.sh"

TESTS_RUN=0
TESTS_PASSED=0

assert_eq() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  PASS: $label"
  else
    echo "  FAIL: $label"
    echo "    expected: '$expected'"
    echo "    actual:   '$actual'"
  fi
}

echo "=== test-uninstall.sh ==="

# Setup: create a fake installed state
TARGET_DIR="$(mktemp -d)"
mkdir -p "$TARGET_DIR/.claude/skills/sample-skill"
echo "# Test" > "$TARGET_DIR/.claude/skills/sample-skill/SKILL.md"
mkdir -p "$TARGET_DIR/.github/copilot/skills/sample-skill"
echo "# Test" > "$TARGET_DIR/.github/copilot/skills/sample-skill/SKILL.md"

# Create lock file
LOCK_FILE="$TARGET_DIR/.skills-lock.json"
lock_init "$LOCK_FILE"
lock_add_entry "$LOCK_FILE" \
  "sample-skill" "skill" "1.0.0" \
  "local" "" "" \
  "claude-code,github-copilot" ""

assert_eq "setup: lock entry exists" "0" "$(lock_has_entry "$LOCK_FILE" "sample-skill" && echo 0 || echo 1)"
assert_eq "setup: files exist" "0" "$([[ -f "$TARGET_DIR/.claude/skills/sample-skill/SKILL.md" ]] && echo 0 || echo 1)"

# Run uninstall
export SKILL_YES=1
REG_DIR="$(mktemp -d)"
mkdir -p "$REG_DIR/bin/lib" "$REG_DIR/bin/commands" "$REG_DIR/skills"
cp "$SCRIPT_DIR/../bin/lib/"*.sh "$REG_DIR/bin/lib/"
cp "$SCRIPT_DIR/../bin/commands/uninstall.sh" "$REG_DIR/bin/commands/"

REGISTRY_ROOT="$REG_DIR" bash "$REG_DIR/bin/commands/uninstall.sh" \
  "sample-skill" --target "$TARGET_DIR"

# Verify removal
assert_eq "claude-code dir removed" "1" "$([[ -d "$TARGET_DIR/.claude/skills/sample-skill" ]] && echo 0 || echo 1)"
assert_eq "copilot dir removed" "1" "$([[ -d "$TARGET_DIR/.github/copilot/skills/sample-skill" ]] && echo 0 || echo 1)"
assert_eq "lock entry removed" "1" "$(lock_has_entry "$LOCK_FILE" "sample-skill" && echo 0 || echo 1)"

rm -rf "$TARGET_DIR" "$REG_DIR"
unset SKILL_YES

echo ""
echo "Results: $TESTS_PASSED / $TESTS_RUN passed"
[[ "$TESTS_PASSED" -eq "$TESTS_RUN" ]]
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tests/test-uninstall.sh
```

Expected: FAIL — `uninstall.sh` not found.

- [ ] **Step 3: Implement `bin/commands/uninstall.sh`**

Create `bin/commands/uninstall.sh`:

```bash
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
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tests/test-uninstall.sh
```

Expected: All tests PASS.

- [ ] **Step 5: Implement `bin/commands/uninstall.ps1`**

Create `bin/commands/uninstall.ps1`:

```powershell
# uninstall.ps1 — remove an installed item

$CmdDir = $PSScriptRoot
. (Join-Path $CmdDir "../lib/common.ps1")
. (Join-Path $CmdDir "../lib/agents.ps1")
. (Join-Path $CmdDir "../lib/lock.ps1")

$TargetDir = Get-Location | Select-Object -ExpandProperty Path
$GlobalInstall = $false; $AgentArgs = @(); $Name = ""

$i = 0
while ($i -lt $args.Count) {
    switch ($args[$i]) {
        "--target"   { $TargetDir = $args[++$i] }
        { $_ -in @("--global","-g") } { $GlobalInstall = $true }
        { $_ -in @("--agent","-a") }  { $AgentArgs += $args[++$i] }
        { $_ -in @("--yes","-y") }    { $env:SKILL_YES = "1" }
        { $_ -in @("--help","-h") }   {
            Write-Host "Usage: skill uninstall <name> [--target <path>] [--global] [--agent <agent>]"
            exit 0
        }
        default {
            if ($_.StartsWith("-")) { Write-Die "Unknown flag: $_" }
            else { $Name = $_ }
        }
    }
    $i++
}

if (-not $Name) { Write-Die "Usage: skill uninstall <name>" }

$lockPath = if ($GlobalInstall) { Join-Path $HOME ".skills-lock.json" } else { Join-Path $TargetDir ".skills-lock.json" }

# Determine agents
if ($AgentArgs.Count -gt 0) {
    $removeAgents = $AgentArgs
} elseif (Test-LockEntry -Path $lockPath -Name $Name) {
    $agents = Get-LockEntryField -Path $lockPath -Name $Name -Field "agents"
    $removeAgents = if ($agents -is [array]) { $agents } else { @($agents) }
} else {
    $removeAgents = Get-KnownAgents
}

$removed = $false
foreach ($agent in $removeAgents) {
    $basePath = if ($GlobalInstall) { Get-GlobalPath $agent } else { Join-Path $TargetDir (Get-ProjectPath $agent) }
    if (-not $basePath) { continue }

    $skillDir = Join-Path $basePath $Name
    if (Test-Path $skillDir) {
        if (Confirm-Prompt "Remove $skillDir?") {
            Remove-Item -Recurse -Force $skillDir
            $relPath = if ($GlobalInstall) { $skillDir } else { $skillDir.Replace("$TargetDir\","").Replace("\","/") }
            Write-Host "  -> Removed: $relPath"
            $removed = $true
        }
    }
}

if ($removed -and (Test-LockEntry -Path $lockPath -Name $Name)) {
    Remove-LockEntry -Path $lockPath -Name $Name
    Write-Info "Uninstalled $Name"
    Write-Host "  Lock file updated: $(Split-Path $lockPath -Leaf)"
} elseif (-not $removed) {
    Write-Warn "No installed files found for: $Name"
}
```

- [ ] **Step 6: Commit**

```bash
git add bin/commands/uninstall.sh bin/commands/uninstall.ps1 tests/test-uninstall.sh
git commit -m "feat: add uninstall command — remove items and update lock"
```

---

### Task 15: Sample content + profiles

**Files:**
- Create: `skills/example-skill/manifest.yaml`
- Create: `skills/example-skill/SKILL.md`
- Create: `instructions/example-instruction/manifest.yaml`
- Create: `instructions/example-instruction/example-instruction.instructions.md`
- Create: `profiles/example.yaml`

- [ ] **Step 1: Create sample skill**

Create `skills/example-skill/manifest.yaml`:

```yaml
name: example-skill
type: skill
description: An example skill demonstrating the manifest format and skill structure.
tags:
  - example
  - getting-started
targets:
  - claude-code
  - github-copilot
files:
  - SKILL.md
version: "1.0.0"
```

Create `skills/example-skill/SKILL.md`:

```markdown
---
name: example-skill
description: Use when you need a reference for how skills-registry skills are structured
---

# Example Skill

This is an example skill that demonstrates the skills-registry format.

## When to Use

Refer to this skill when creating new skills for the registry.

## Structure

Every skill needs:
1. A `manifest.yaml` with name, type, description, tags, targets, and files
2. A `SKILL.md` with YAML frontmatter (name + description) and markdown content
```

- [ ] **Step 2: Create sample instruction**

Create `instructions/example-instruction/manifest.yaml`:

```yaml
name: example-instruction
type: instruction
description: An example instruction demonstrating the instruction format.
tags:
  - example
targets:
  - claude-code
  - github-copilot
files:
  - example-instruction.instructions.md
version: "1.0.0"
```

Create `instructions/example-instruction/example-instruction.instructions.md`:

```markdown
# Example Instruction

This is an example instruction. Instructions are static context injected into
every conversation or session. Use them for coding standards, project conventions,
or persistent guidelines.

## Convention

- Use conventional commits: `type(scope): description`
- Prefer small, focused functions
- Write tests before implementation
```

- [ ] **Step 3: Create sample profile**

Create `profiles/example.yaml`:

```yaml
name: example
description: Example profile demonstrating the profile format with mixed sources.
items:
  - name: example-skill
    source: local
  - name: example-instruction
    source: local
```

- [ ] **Step 4: Run sync to generate registry.json**

```bash
bin/skill sync
```

Expected: `✓ Registry updated: 2 items → registry.json`

- [ ] **Step 5: Commit**

```bash
git add skills/ instructions/ profiles/ registry.json
git commit -m "feat: add sample content and example profile"
```

---

### Task 16: README + .gitignore

**Files:**
- Create: `README.md`
- Create: `.gitignore`

- [ ] **Step 1: Create `.gitignore`**

Create `.gitignore`:

```
# OS
.DS_Store
Thumbs.db

# Temp
*.tmp
*.bak

# Editor
.vscode/
.idea/
*.swp

# Generated (optionally track registry.json — it's regenerable)
# registry.json
```

- [ ] **Step 2: Create `README.md`**

Create `README.md`:

```markdown
# skills-registry

A personal monorepo of reusable **skills**, **agents**, and **instructions** for AI-assisted coding, with a CLI tool to install them into any project for any AI coding assistant.

## Quick Start

```bash
# List available skills
bin/skill list

# Install a skill into the current project
bin/skill install example-skill

# Install from an external repo
bin/skill install owner/repo --skill skill-name

# Install a profile (named bundle)
bin/skill install --profile example

# Restore all skills from lock file (team sharing)
bin/skill install
```

## Commands

| Command | Description |
|---|---|
| `skill list` | List all items with optional `--type`, `--tag`, `--for` filters |
| `skill search <query>` | Full-text search across the registry |
| `skill info <name>` | Show full details for a single item |
| `skill install <name\|url>` | Install a skill, agent, or instruction |
| `skill install --profile <name>` | Install a named bundle |
| `skill install` | Restore from `.skills-lock.json` |
| `skill uninstall <name>` | Remove an installed item |
| `skill sync` | Regenerate `registry.json` |

## Supported Agents

The CLI auto-detects installed AI coding agents and prompts you to choose where to install:

- Claude Code
- GitHub Copilot
- Cursor
- Cline
- OpenCode
- Codex
- Windsurf
- Roo Code

## Adding Your Own Skills

1. Create a directory under `skills/`, `agents/`, or `instructions/`
2. Add a `manifest.yaml` (see `skills/example-skill/manifest.yaml` for the format)
3. Add your content file(s) (`SKILL.md`, `.agent.md`, or `.instructions.md`)
4. Run `bin/skill sync` to update the registry index

## Profiles

Define named bundles in `profiles/`. Example:

```yaml
name: my-setup
description: My essential skills for every project.
items:
  - name: example-skill
    source: local
  - name: brainstorming
    source: obra/superpowers
```

Install with: `bin/skill install --profile my-setup`

## Cross-Platform

- **macOS/Linux:** Use `bin/skill` (Bash)
- **Windows:** Use `bin/skill.ps1` (PowerShell)

## Lock File

When you install skills into a project, a `.skills-lock.json` is created tracking what was installed, from where, and at which version. Commit this file to share your skill setup with teammates — they can run `skill install` to reproduce it.
```

- [ ] **Step 3: Commit**

```bash
git add README.md .gitignore
git commit -m "docs: add README and .gitignore"
```

---

### Task 17: Test runner + integration smoke test

**Files:**
- Create: `tests/run-tests.sh`

- [ ] **Step 1: Create test runner**

Create `tests/run-tests.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILED=0
PASSED=0

echo "==============================="
echo "  skills-registry test suite"
echo "==============================="
echo ""

for test_file in "$SCRIPT_DIR"/test-*.sh; do
  echo "--- $(basename "$test_file") ---"
  if bash "$test_file"; then
    PASSED=$((PASSED + 1))
  else
    FAILED=$((FAILED + 1))
    echo "  ^^^ FAILED ^^^"
  fi
  echo ""
done

echo "==============================="
echo "  $PASSED passed, $FAILED failed"
echo "==============================="

exit $FAILED
```

- [ ] **Step 2: Run all tests**

```bash
chmod +x tests/run-tests.sh
bash tests/run-tests.sh
```

Expected: All test files pass (test-common, test-agents, test-lock, test-sync, test-install, test-uninstall).

- [ ] **Step 3: Commit**

```bash
git add tests/run-tests.sh
git commit -m "feat: add test runner and verify all tests pass"
```
