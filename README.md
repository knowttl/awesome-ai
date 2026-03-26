# skills-registry

A personal monorepo of reusable **skills**, **agents**, and **instructions** for AI-assisted coding, with a zero-dependency CLI to install them into any project for any AI coding assistant.

> **Zero dependencies.** Pure Bash + PowerShell. No Node, Python, or package manager required.

---

## Table of Contents

- [Quick Start](#quick-start)
- [What's Inside](#whats-inside)
- [CLI Reference](#cli-reference)
- [Installing Skills Into a Project](#installing-skills-into-a-project)
- [Adding Your Own Content](#adding-your-own-content)
- [Profiles](#profiles)
- [Lock File & Team Sharing](#lock-file--team-sharing)
- [Project Structure](#project-structure)
- [Cross-Platform Usage](#cross-platform-usage)
- [Running Tests](#running-tests)

---

## Quick Start

```bash
# 1. Browse what's available
bin/skill list                       # show all items
bin/skill search debugging           # find by keyword
bin/skill info systematic-debugging  # full details for one item

# 2. Install a skill into your project
bin/skill install brainstorming

# 3. Install from a remote GitHub repo
bin/skill install owner/repo --skill skill-name

# 4. Install a bundle of skills at once
bin/skill install --profile example

# 5. Restore everything from a lock file (for teammates)
bin/skill install
```

On **Windows PowerShell**, replace `bin/skill` with `bin/skill.ps1`:

```powershell
.\bin\skill.ps1 list
.\bin\skill.ps1 install brainstorming
```

---

## What's Inside

The registry ships with **15 skills** and **1 instruction**, including the full [obra/superpowers](https://github.com/obra/superpowers) skill set:

| Skill | When to Use |
|-------|-------------|
| `brainstorming` | Before any creative work — explores intent and design before implementation |
| `dispatching-parallel-agents` | When facing 2+ independent tasks with no shared state |
| `executing-plans` | When you have a written plan to execute with review checkpoints |
| `finishing-a-development-branch` | When implementation is done and you need to decide merge/PR/cleanup |
| `receiving-code-review` | When receiving feedback — requires rigor, not blind agreement |
| `requesting-code-review` | When completing tasks or before merging to verify quality |
| `subagent-driven-development` | When executing plans with independent tasks in the current session |
| `systematic-debugging` | When encountering any bug or unexpected behavior |
| `test-driven-development` | When implementing any feature or bugfix |
| `using-git-worktrees` | When starting feature work that needs workspace isolation |
| `using-superpowers` | When starting any conversation — establishes skill discovery |
| `verification-before-completion` | Before claiming work is complete — evidence before assertions |
| `writing-plans` | When you have a spec and need a multi-step implementation plan |
| `writing-skills` | When creating or editing skills for the registry |
| `example-skill` | Reference template showing the manifest format |

---

## CLI Reference

### `skill list`

List all items in the registry with optional filters.

```bash
bin/skill list                    # all items
bin/skill list --type skill       # only skills (also: agent, instruction)
bin/skill list --tag debugging    # filter by tag
bin/skill list --for claude-code  # items targeting a specific agent
```

### `skill search <query>`

Case-insensitive full-text search across names, descriptions, and tags.

```bash
bin/skill search debugging
bin/skill search review --type skill
```

### `skill info <name>`

Show full details for a single item (description, path, tags, targets, files).

```bash
bin/skill info systematic-debugging
```

### `skill install`

The most powerful command — installs content into your project with multiple modes:

```bash
# Install from the local registry
bin/skill install brainstorming

# Install from a GitHub repo (owner/repo shorthand)
bin/skill install obra/superpowers --skill brainstorming

# Install from any Git URL
bin/skill install https://github.com/owner/repo.git --skill my-skill

# Install a profile (named bundle of skills)
bin/skill install --profile example

# Restore from lock file (no arguments)
bin/skill install
```

**Options:**

| Flag | Description |
|------|-------------|
| `--target <path>` | Target project directory (default: current directory) |
| `--global`, `-g` | Install to the agent's global/user directory |
| `--agent`, `-a <name>` | Target specific agent(s) — repeatable |
| `--skill`, `-s <name>` | Select specific item(s) from a remote repo |
| `--profile <name>` | Install a named profile bundle |
| `--ref <commit>` | Pin to a specific Git commit, tag, or branch |
| `--symlink` | Symlink files instead of copying |
| `--yes`, `-y` | Skip confirmation prompts |

**Examples:**

```bash
# Install to specific agents only
bin/skill install brainstorming -a claude-code -a github-copilot

# Install globally (applies to all projects)
bin/skill install brainstorming --global

# Pin to a specific version
bin/skill install obra/superpowers --skill brainstorming --ref v1.2.0

# Symlink instead of copy (changes update automatically)
bin/skill install brainstorming --symlink
```

### `skill uninstall <name>`

Remove an installed item from all target agent directories and update the lock file.

```bash
bin/skill uninstall brainstorming
bin/skill uninstall brainstorming --agent claude-code  # remove from one agent only
```

### `skill sync`

Regenerate `registry.json` by scanning all `skills/`, `agents/`, and `instructions/` directories. Run this after adding or modifying content.

```bash
bin/skill sync
```

---

## Installing Skills Into a Project

When you run `bin/skill install`, the CLI:

1. Looks up the item in `registry.json` (or clones a remote repo)
2. Reads its `manifest.yaml` to find which files to install and which agents it supports
3. Prompts you to select target agents (or auto-selects if you pass `--agent`)
4. Copies files to the correct agent-specific directory in your project
5. Records the installation in `.skills-lock.json`

### Supported Agents & Install Paths

| Agent | Project Path | Global Path |
|-------|-------------|-------------|
| Claude Code | `.claude/skills/<name>/` | `~/.claude/skills/<name>/` |
| GitHub Copilot | `.github/copilot/skills/<name>/` | (varies by OS) |
| Cursor | `.cursor/skills/<name>/` | `~/.cursor/skills/<name>/` |
| Cline | `.cline/skills/<name>/` | `~/.cline/skills/<name>/` |
| OpenCode | `.opencode/skills/<name>/` | `~/.opencode/skills/<name>/` |
| Codex | `.codex/skills/<name>/` | `~/.codex/skills/<name>/` |
| Windsurf | `.windsurf/skills/<name>/` | `~/.windsurf/skills/<name>/` |
| Roo Code | `.roo/skills/<name>/` | `~/.roo/skills/<name>/` |

---

## Adding Your Own Content

### Create a Skill

```bash
mkdir -p skills/my-new-skill
```

Create `skills/my-new-skill/manifest.yaml`:

```yaml
name: my-new-skill
type: skill
description: A brief description of what this skill does.
tags:
  - my-tag
targets:
  - claude-code
  - github-copilot
files:
  - SKILL.md
version: "1.0.0"
```

Create `skills/my-new-skill/SKILL.md`:

```markdown
---
name: my-new-skill
description: A brief description of what this skill does.
---

# My New Skill

Instructions for the AI agent go here.
```

Then regenerate the index:

```bash
bin/skill sync
```

### Create an Instruction

Same structure, but under `instructions/` with type `instruction`:

```yaml
name: my-instruction
type: instruction
description: Persistent guidelines injected into every session.
tags:
  - conventions
targets:
  - claude-code
files:
  - my-instruction.instructions.md
version: "1.0.0"
```

### Manifest Reference

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier (lowercase, hyphens) |
| `type` | Yes | `skill`, `agent`, or `instruction` |
| `description` | Yes | One-line summary |
| `tags` | No | List of searchable tags |
| `targets` | Yes | Which AI agents this item supports |
| `files` | Yes | List of files to install (relative to item dir) |
| `version` | No | Semver string (defaults to `0.0.0`) |

---

## Profiles

Profiles are named bundles that install multiple items at once. Define them in `profiles/`:

```yaml
# profiles/my-workflow.yaml
name: my-workflow
description: My standard development workflow skills.
items:
  - name: brainstorming
    source: local
  - name: test-driven-development
    source: local
  - name: systematic-debugging
    source: local
  - name: verification-before-completion
    source: local
```

Items can come from the local registry (`source: local`) or remote repos (`source: owner/repo`).

Install a profile:

```bash
bin/skill install --profile my-workflow
bin/skill install --profile my-workflow -a claude-code  # target specific agent
```

---

## Lock File & Team Sharing

Every `skill install` creates or updates `.skills-lock.json` in the target project, recording:

- What was installed (name, type, version)
- Where it came from (local registry or remote URL + commit hash)
- Which agents it was installed for
- When it was installed

**To share your skill setup with a team:**

1. Commit `.skills-lock.json` to your project repo
2. Teammates clone the project and run:

```bash
bin/skill install
```

This restores all skills from the lock file, pinned to the exact same versions.

---

## Project Structure

```
skills-registry/
├── bin/
│   ├── skill              # Bash CLI entry point
│   ├── skill.ps1          # PowerShell CLI entry point
│   ├── commands/           # Command implementations (.sh + .ps1)
│   │   ├── info.sh / .ps1
│   │   ├── install.sh / .ps1
│   │   ├── list.sh / .ps1
│   │   ├── search.sh / .ps1
│   │   ├── sync.sh / .ps1
│   │   └── uninstall.sh / .ps1
│   └── lib/                # Shared libraries (.sh + .ps1)
│       ├── agents.sh / .ps1     # Agent path registry & detection
│       ├── common.sh / .ps1     # Colors, YAML parsing, utilities
│       ├── git.sh / .ps1        # Shallow clone, repo scanning
│       ├── lock.sh / .ps1       # Lock file CRUD
│       └── profile.sh / .ps1    # Profile parsing & install
├── skills/                 # Skill definitions (each with manifest.yaml + SKILL.md)
├── instructions/           # Instruction definitions
├── profiles/               # Named bundles (YAML)
├── tests/                  # Test suites
│   ├── run-tests.sh        # Test runner
│   ├── test-common.sh      # Tests for lib/common.sh
│   ├── test-agents.sh      # Tests for lib/agents.sh
│   ├── test-lock.sh        # Tests for lib/lock.sh
│   ├── test-sync.sh        # Tests for sync command
│   ├── test-install.sh     # Tests for install command
│   ├── test-uninstall.sh   # Tests for uninstall command
│   └── fixtures/           # Test data
└── registry.json           # Generated index (created by `skill sync`)
```

---

## Cross-Platform Usage

Every script has dual implementations:

| Platform | CLI | Libraries |
|----------|-----|-----------|
| macOS / Linux | `bin/skill` | `bin/lib/*.sh` |
| Windows (PowerShell) | `bin/skill.ps1` | `bin/lib/*.ps1` |

Both produce identical behavior. Use whichever matches your shell.

---

## Running Tests

```bash
# Run all tests
bash tests/run-tests.sh

# Run a single test suite
bash tests/test-common.sh
bash tests/test-install.sh
```

The test suite covers 51 tests across 6 suites: common utilities, agent paths, lock file management, sync, install, and uninstall.
