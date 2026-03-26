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
