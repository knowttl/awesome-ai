# Skills Registry — Design Spec

> **Date:** 2026-03-25
> **Status:** Draft
> **Repo:** `awesome-ai` (skills-registry)

---

## 1. Architecture Overview

**skills-registry** is a personal monorepo that stores reusable skills, agents, and instructions for AI-assisted coding, plus a CLI tool to install them into any project. The CLI is implemented as dual Bash/PowerShell scripts using a dispatcher + shared library pattern: a thin `skill` entrypoint routes subcommands to per-command scripts, which share a common library for agent detection, git operations, and lock file management.

Content is organized by type (`skills/`, `agents/`, `instructions/`) with each item in its own directory containing a `manifest.yaml` and its native files (`SKILL.md`, `.agent.md`, or `.instructions.md`). A generated `registry.json` provides a queryable index for discovery. Installation works directly from any Git repo URL — no local cache — copying files into the correct agent-specific paths. A lock file in each target project enables reproducible installs and audit trails. Profiles define named bundles with fully-qualified references that can mix skills from any source.

### Key Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Relationship to `~/.agents/` | Independent — just one install target | Registry is a distribution tool, not tied to one machine's config |
| Content types | Three distinct: skill, agent, instruction | Each has different native formats and placement rules |
| CLI language | Bash + PowerShell (dual scripts) | Zero runtime dependencies, native on all platforms |
| Install target selection | Interactive prompt with auto-detect | Matches `npx skills` UX — detects installed agents, prompts user |
| File format in registry | Native format per type | SKILL.md, .agent.md, .instructions.md — no translation layer |
| Pull model | Direct install from URLs (shallow clone + copy) | No local cache to manage, pinned by commit hash |
| Repo scope | Content + CLI + discovery | Generated index enables browsability and sharing |
| Install method | Copy default, `--symlink` opt-in | Windows-safe default; symlinks require elevated permissions |
| Lock file | Audit trail + reproducible installs | Teammates can `skill install` from lock file to reproduce setup |
| Profiles | Mixed sources with fully-qualified refs | Maximum flexibility — bundle the best skills from anywhere |
| Script architecture | Dispatcher + shared library (hybrid) | Per-command scripts stay focused; shared lib avoids duplication |

---

## 2. Repository Structure

```
skills-registry/
├── bin/
│   ├── skill                     # Bash dispatcher — routes `skill <cmd>` to commands/
│   ├── skill.ps1                 # PowerShell dispatcher
│   ├── commands/
│   │   ├── install.sh            # skill install <name|url>
│   │   ├── install.ps1
│   │   ├── uninstall.sh          # skill uninstall <name>
│   │   ├── uninstall.ps1
│   │   ├── list.sh               # skill list [--type] [--tag]
│   │   ├── list.ps1
│   │   ├── sync.sh               # skill sync — regenerate registry.json
│   │   ├── sync.ps1
│   │   ├── search.sh             # skill search <query>
│   │   └── search.ps1
│   └── lib/
│       ├── common.sh             # Shared: colors, prompts, error handling
│       ├── common.ps1
│       ├── agents.sh             # Agent path registry (name → project/global paths)
│       ├── agents.ps1
│       ├── git.sh                # Git clone, shallow fetch, commit hash resolution
│       ├── git.ps1
│       ├── lock.sh               # Lock file read/write/merge
│       └── lock.ps1
├── skills/
│   └── <skill-name>/
│       ├── manifest.yaml         # Metadata: name, type, description, tags, targets, files
│       └── SKILL.md              # The skill content
├── agents/
│   └── <agent-name>/
│       ├── manifest.yaml
│       └── <agent-name>.agent.md # Agent definition
├── instructions/
│   └── <instruction-name>/
│       ├── manifest.yaml
│       └── <name>.instructions.md
├── profiles/
│   ├── python-dev.yaml           # Profile: named bundle from mixed sources
│   ├── frontend.yaml
│   └── security-review.yaml
├── registry.json                 # Generated index of all local content (skill sync)
├── README.md                     # Catalog + usage docs
└── .gitignore
```

### Directory responsibilities

- **`bin/`** — All CLI code. `skill` and `skill.ps1` are the only user-facing entrypoints.
- **`bin/commands/`** — One script pair per subcommand. Each is self-contained and sources from `lib/`.
- **`bin/lib/`** — Shared functions. `agents.sh`/`.ps1` contains the agent path table. `git.sh`/`.ps1` handles cloning and hash resolution. `lock.sh`/`.ps1` manages the lock file. `common.sh`/`.ps1` provides colors, prompts, and error handling.
- **`skills/`, `agents/`, `instructions/`** — Content directories. One subdirectory per item, each with `manifest.yaml` and native content file(s).
- **`profiles/`** — YAML files defining named bundles.
- **`registry.json`** — Generated by `skill sync`. Aggregates all manifests for fast querying.

---

## 3. Manifest Schema

Every skill, agent, and instruction directory contains a `manifest.yaml` with this schema:

### Schema definition

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | Yes | Unique identifier, kebab-case |
| `type` | enum | Yes | One of: `skill`, `agent`, `instruction` |
| `description` | string | Yes | What it does, when to use it |
| `tags` | list[string] | No | Categories for filtering (e.g., `python`, `testing`) |
| `targets` | list[string] | Yes | Supported AI tools: `claude-code`, `github-copilot`, `cursor`, etc. |
| `files` | list[string] | Yes | Files to copy on install, relative to this directory |
| `dependencies` | list[string] | No | Other items this requires, referenced by name |
| `version` | string | No | Semver string for tracking updates. Default: `"0.0.0"` |

### Skill example

```yaml
name: test-driven-development
type: skill
description: >-
  Use when implementing any feature or bugfix. Guides RED-GREEN-REFACTOR
  workflow with verification at each step.
tags:
  - testing
  - workflow
  - python
  - typescript
targets:
  - claude-code
  - github-copilot
files:
  - SKILL.md
dependencies:
  - verification-before-completion
version: "1.0.0"
```

### Agent example

```yaml
name: security-reviewer
type: agent
description: >-
  Agent mode that restricts tool access and focuses on security review.
  Limits file writes, enforces read-only analysis.
tags:
  - security
  - review
targets:
  - github-copilot
files:
  - security-reviewer.agent.md
version: "1.0.0"
```

### Instruction example

```yaml
name: python-style-guide
type: instruction
description: >-
  Project-level Python coding standards. Injected as persistent context
  for all conversations in the project.
tags:
  - python
  - style
targets:
  - claude-code
  - github-copilot
files:
  - python-style-guide.instructions.md
version: "1.0.0"
```

### Design notes

- **`targets` is a list** — a skill can support multiple agents.
- **`files` is explicit** — the manifest declares exactly what gets copied. No implicit glob.
- **`dependencies` are by name** — resolved at install time. If a dependency isn't installed, the CLI warns and offers to install it.
- **`version`** is optional and defaults to `"0.0.0"`. Used in lock files for reproducibility, not for semver resolution.

---

## 4. CLI Command Reference

### Commands

| Command | Arguments / Flags | Description | Example |
|---|---|---|---|
| `skill list` | `--type <skill\|agent\|instruction>`, `--tag <tag>`, `--for <agent>` | List all items in the local registry. Filters are combinable. | `skill list --type skill --tag python` |
| `skill search <query>` | `--type`, `--tag`, `--for` (same filters) | Full-text search across names, descriptions, and tags. | `skill search "testing"` |
| `skill install <name\|url>` | `--target <project-path>`, `--global` / `-g`, `--agent <agents...>` / `-a`, `--skill <names...>` / `-s`, `--symlink`, `--yes` / `-y` | Install by name (local) or Git URL (remote). Prompts for agent selection. | `skill install test-driven-development` |
| `skill install --profile <name>` | `--target <project-path>`, `--global`, `--agent`, `--symlink`, `--yes` | Install all items in a named profile. | `skill install --profile python-dev` |
| `skill install` | *(no args — reads lock file)* | Reproducible install from `.skills-lock.json`. | `skill install` |
| `skill uninstall <name>` | `--target <project-path>`, `--global`, `--agent <agents...>`, `--yes` | Remove a previously installed item. Updates lock file. | `skill uninstall python-style-guide` |
| `skill sync` | *(none)* | Regenerate `registry.json` by scanning content directories. | `skill sync` |
| `skill info <name>` | *(none)* | Show full manifest details for a single item. | `skill info test-driven-development` |

### Global flags

| Flag | Short | Description |
|---|---|---|
| `--agent <agents...>` | `-a` | Specify target agents explicitly. Skips interactive prompt. Repeatable. |
| `--global` | `-g` | Install to user-level directory instead of project-level. |
| `--symlink` | — | Create symlinks instead of copying. Opt-in. |
| `--yes` | `-y` | Skip all confirmation prompts. For scripting/CI. |
| `--target <path>` | — | Path to target project. Defaults to current working directory. |
| `--skill <names...>` | `-s` | When installing from a URL, select specific items by name. |

### Dispatcher behavior

- `skill` (no args) → prints usage help.
- `skill <unknown>` → prints "Unknown command" + usage help.
- All commands source `lib/common.sh` (or `.ps1`) on startup for shared utilities.

---

## 5. Install Behavior

Step-by-step flow when `skill install <name|url>` runs:

### 5.1 Resolve source

- **Name** (no `/` or URL): look up in local `registry.json`. Resolve to the local directory path.
- **URL or `owner/repo` shorthand**: shallow-clone (`git clone --depth 1`) to a temp directory. Scan for items. If `--skill` flag given, select those; otherwise prompt.
- **Not found**: error with fuzzy-match suggestion.

### 5.2 Read manifest

- Parse `manifest.yaml` from the resolved directory.
- Validate required fields (`name`, `type`, `description`, `targets`, `files`).
- Check `dependencies` — if any are not already installed (per lock file), warn and offer to install them.

### 5.3 Detect installed agents

If `--agent` not specified:

1. Scan the system for known AI coding agents:
   - Check for config directories (`~/.claude/`, `~/.config/opencode/`, etc.)
   - Check for CLI binaries in PATH (`claude`, `cursor`, etc.)
2. Cross-reference detected agents with the item's `targets` list.
3. Present an interactive checkbox prompt with detected + compatible agents pre-checked.

If `--agent` was provided, skip the prompt.

### 5.4 Determine install paths

Agent path table (in `lib/agents.sh` / `lib/agents.ps1`):

| Agent | Project path | Global path |
|---|---|---|
| `claude-code` | `.claude/skills/<name>/` | `~/.claude/skills/<name>/` |
| `github-copilot` | `.github/copilot/skills/<name>/` | `~/.copilot/skills/<name>/` |
| `cursor` | `.agents/skills/<name>/` | `~/.cursor/skills/<name>/` |
| `cline` | `.agents/skills/<name>/` | `~/.agents/skills/<name>/` |
| `opencode` | `.agents/skills/<name>/` | `~/.config/opencode/skills/<name>/` |
| `codex` | `.agents/skills/<name>/` | `~/.codex/skills/<name>/` |

This table is extensible — adding a new agent means adding one entry.

- `--global` → use global path.
- Otherwise → use project path relative to `--target` (default: cwd).

### 5.5 Handle conflicts

- File exists, content identical → skip silently.
- File exists, content differs → prompt "Overwrite? (y/n/diff)". Show diff if requested.
- `--yes` flag → overwrite without prompting.

### 5.6 Copy files

- Copy each file from `manifest.yaml` `files` array to the destination.
- `--symlink` → create symlinks instead.
- Preserve subdirectory structure within the item directory.

### 5.7 Update lock file

Read or create `.skills-lock.json` in the target project root (or `~/.skills-lock.json` for global installs). Add/update entry:

```json
{
  "version": 1,
  "installed": {
    "test-driven-development": {
      "type": "skill",
      "version": "1.0.0",
      "source": "local",
      "sourceUrl": null,
      "sourceCommit": null,
      "installedAt": "2026-03-25T10:30:00Z",
      "agents": ["claude-code", "github-copilot"],
      "files": {
        "claude-code": [".claude/skills/test-driven-development/SKILL.md"],
        "github-copilot": [".github/copilot/skills/test-driven-development/SKILL.md"]
      },
      "profile": null
    }
  }
}
```

For remote sources: `"source": "remote"`, `"sourceUrl"` is the repo URL, `"sourceCommit"` is the pinned commit hash.

### 5.8 Print summary

```
✓ Installed test-driven-development (skill v1.0.0)
  → claude-code:     .claude/skills/test-driven-development/SKILL.md
  → github-copilot:  .github/copilot/skills/test-driven-development/SKILL.md
  Lock file updated: .skills-lock.json
```

### 5.9 Reproducible installs

Running `skill install` with no arguments in a project that has `.skills-lock.json`:

1. Read the lock file.
2. For each entry: resolve source (local by name, remote by URL + commit hash).
3. Install to the same agents listed in each entry.
4. Result: exact same file state as the original install.

---

## 6. External Skills Strategy

### Approach: Shallow clone + copy with pinned commit hashes

When `skill install owner/repo` or a full URL runs:

1. **Shallow clone** (`git clone --depth 1`) to a temp directory.
2. **Scan** for items using discovery patterns: check `skills/`, `agents/`, `instructions/`, `.claude/skills/`, `.agents/skills/`, root `SKILL.md`, `manifest.yaml` files.
3. **Prompt** which items to install (if the repo has multiple and `--skill` not specified).
4. **Resolve commit hash** via `git rev-parse HEAD`.
5. **Copy** selected files to target project.
6. **Delete** the temp clone.

For lock-file-based reproducible installs, the `sourceUrl` + `sourceCommit` are used to clone at the exact commit.

### Trade-off analysis

| Approach | Versioning | Update ease | Disk footprint | Simplicity |
|---|---|---|---|---|
| **Shallow clone + copy** (chosen) | Pinned commit hash | Re-run install | Zero (temp only) | High |
| Git submodules | Pinned commit | `git submodule update` | Full clone persists | Medium |
| Git subtree | Merged into history | `git subtree pull` | In repo history | Low |
| Raw URL download | No versioning | Re-download | Zero | High but no integrity |

### Why shallow clone + copy

- **No persistent state**: temp clone deleted after install.
- **Pinned reproducibility**: commit hash in lock file.
- **Works with any Git host**: GitHub, GitLab, self-hosted.
- **No git-in-git complexity**: avoids submodule/subtree operational burden.
- **Disk-efficient**: `--depth 1` fetches only the latest snapshot.

### Update workflow

1. `skill install owner/repo --skill <name>` — re-clones latest.
2. Detects item already installed via lock file, shows diff of changed files.
3. Prompts to update.
4. Updates lock file with new commit hash and timestamp.

---

## 7. Profile System

### Format

Profiles are YAML files in the `profiles/` directory. Each declares a named bundle of items from any source.

```yaml
# profiles/python-dev.yaml
name: python-dev
description: Python development essentials — linting, testing, and docstring generation.
items:
  - name: test-driven-development
    source: local
  - name: pytest-helper
    source: obra/superpowers
  - name: docstring-agent
    source: https://github.com/someone/ai-skills
    ref: v2.1.0
```

### Field definitions

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | Yes | Profile identifier (matches filename without `.yaml`) |
| `description` | string | Yes | What this profile is for |
| `items` | list | Yes | Items to install |
| `items[].name` | string | Yes | Item name (must match `name` in its manifest) |
| `items[].source` | string | Yes | `local` for this repo, or Git URL / `owner/repo` shorthand |
| `items[].ref` | string | No | Git ref to pin (tag, branch, commit hash). Defaults to HEAD. |

### Profile install behavior

When `skill install --profile python-dev` runs:

1. Read `profiles/python-dev.yaml`.
2. For each item: resolve source (`local` → local registry, URL → shallow clone).
3. Prompt for agent selection once (applies to all items; skip incompatible items with a note).
4. Install each item using the standard install flow.
5. Lock file entries include `"profile": "python-dev"`.

### Multiple profiles

A project can have multiple profiles. Running a second profile adds to (doesn't replace) the lock file. If an item appears in multiple profiles, it's installed once — the lock file records all referencing profiles.

### Additional example

```yaml
# profiles/security-review.yaml
name: security-review
description: Security-focused review and analysis tools.
items:
  - name: security-reviewer
    source: local
  - name: owasp-checklist
    source: local
  - name: dependency-audit
    source: secureteam/ai-security-skills
    ref: main
```

---

## 8. Example Walkthrough

End-to-end: starting from scratch, adding 3 items (1 local, 2 external), creating a profile, installing into a new project for both Claude Code and GitHub Copilot.

### Step 1: Create a local instruction

```bash
mkdir -p instructions/commit-message-style
```

`instructions/commit-message-style/manifest.yaml`:
```yaml
name: commit-message-style
type: instruction
description: Enforces conventional commit message format across all AI assistants.
tags: [git, style, conventions]
targets: [claude-code, github-copilot]
files: [commit-message-style.instructions.md]
version: "1.0.0"
```

`instructions/commit-message-style/commit-message-style.instructions.md`:
```markdown
# Commit Message Style

Always use conventional commits format: `type(scope): description`
```

Regenerate the index:
```bash
skill sync
# ✓ Registry updated: 1 item (1 instruction)
```

### Step 2: Install two external items

```bash
skill install obra/superpowers --skill brainstorming \
  --target ~/projects/my-app -a claude-code -a github-copilot

# Cloning obra/superpowers (shallow)...
# ✓ Installed brainstorming (skill)
#   → claude-code:     .claude/skills/brainstorming/SKILL.md
#   → github-copilot:  .github/copilot/skills/brainstorming/SKILL.md

skill install secureteam/ai-security-skills --skill security-reviewer \
  --target ~/projects/my-app -a claude-code -a github-copilot

# Cloning secureteam/ai-security-skills (shallow)...
# ✓ Installed security-reviewer (agent)
#   → claude-code:     .claude/skills/security-reviewer/security-reviewer.agent.md
#   → github-copilot:  .github/copilot/skills/security-reviewer/security-reviewer.agent.md
```

### Step 3: Create a profile

`profiles/my-essentials.yaml`:
```yaml
name: my-essentials
description: My essential setup for any new project.
items:
  - name: commit-message-style
    source: local
  - name: brainstorming
    source: obra/superpowers
  - name: security-reviewer
    source: secureteam/ai-security-skills
```

### Step 4: Install profile into a new project

```bash
cd ~/projects/new-project
skill install --profile my-essentials
```

```
Installing profile: my-essentials (3 items)

Detected agents: claude-code, github-copilot, cursor

? Which agents should these be installed to?
  [x] claude-code
  [x] github-copilot
  [ ] cursor

Resolving sources...
  commit-message-style  → local registry
  brainstorming         → cloning obra/superpowers (shallow)...
  security-reviewer     → cloning secureteam/ai-security-skills (shallow)...

Installing 3 items...
  ✓ commit-message-style (instruction v1.0.0)
    → claude-code:     .claude/skills/commit-message-style/commit-message-style.instructions.md
    → github-copilot:  .github/copilot/skills/commit-message-style/commit-message-style.instructions.md
  ✓ brainstorming (skill)
    → claude-code:     .claude/skills/brainstorming/SKILL.md
    → github-copilot:  .github/copilot/skills/brainstorming/SKILL.md
  ✓ security-reviewer (agent)
    → claude-code:     .claude/skills/security-reviewer/security-reviewer.agent.md
    → github-copilot:  .github/copilot/skills/security-reviewer/security-reviewer.agent.md

Lock file written: .skills-lock.json (3 items, profile: my-essentials)
```

### Step 5: Teammate reproduces the setup

```bash
git clone https://github.com/me/new-project
cd new-project
skill install

# Reading .skills-lock.json...
# Installing 3 items from lock file...
#   ✓ commit-message-style (local → v1.0.0)
#   ✓ brainstorming (obra/superpowers @ abc1234)
#   ✓ security-reviewer (secureteam/ai-security-skills @ def5678)
# Done. 3 items installed.
```
