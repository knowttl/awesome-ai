# AGENTS.md - skills-registry

## What This Project Is

A **curated catalog of AI coding skills**. Skills are installed with
[`npx skills`](https://github.com/vercel-labs/skills) (the `skills` CLI, which
supports 75+ agents). This repo does two things:

1. **Hosts local skills** under `skills/local.*` - installable from this repo
   with `npx skills add knowttl/awesome-ai --skill <name>`.
2. **Curates remote skills** in [`catalog.json`](catalog.json) - third-party
   skills that live in their own upstream repos and are fetched on demand, never
   vendored here.

`bin/skill` is a thin Node wrapper over `npx skills` that installs everything in
the catalog, a named bundle, or a single skill, and runs any per-skill `setup`
command (e.g. installing a companion npm package).

## Agent Rules

Rules that govern how the agent works on this project. **Self-updating**: when the user establishes a new behavioral rule (e.g. "always test after X", "from now on, when Y happens do Z", "never Q unless R"), add it as a bullet point below. Follow the format of existing rules. Do not ask for confirmation - just add it.

- After adding, removing, or renaming anything under `skills/`, update
  [`catalog.json`](catalog.json) to match, then run `bash tests/run-tests.sh`.
- Every local skill MUST have a `SKILL.md` with frontmatter `name:` and
  `description:`. The `name:` is the `skills` selector - it must match the
  skill's entry key in `catalog.json`.
- Keep local skills self-contained: bundle everything a skill needs under its
  own directory (e.g. `resources/`) and list those files in `manifest.yaml`.
- `bin/skill` is a single Node CLI (no `.ps1` twin). `catalog.json` is parsed
  with `JSON.parse` - no external parsing tools.
- When making structural changes (catalog schema, new commands, directory
  layout, naming), update this `AGENTS.md` to reflect the change.
- Never commit skill install output into this repo (`.agents/`, `.claude/skills/`,
  `.github/skills/`, `skills-lock.json`) - it is gitignored; this repo is the
  source, not an install target.

## File Map

```
catalog.json                       # Source of truth: items (local + remote) + bundles
bin/skill                          # Node CLI wrapper over `npx skills`
skills/local.<name>/SKILL.md       # Local skill content (frontmatter name = selector)
skills/local.<name>/manifest.yaml  # Local skill metadata (files list, tags, source)
skills/local.<name>/resources/     # Bundled resources a skill installs or reads
tests/test-catalog.js              # Validates catalog against skills/ + exercises bin/skill
tests/run-tests.sh                 # Test entry point (runs the Node test)
```

## Conventions

- **Catalog is authoritative.** Every installable skill - local or remote - has
  an entry in `catalog.json`. Bundles are named lists of entry keys.
- **Selectors.** An entry's key is the `skills` selector, which equals the
  skill's `SKILL.md` frontmatter `name`. Local dirs are `skills/local.<name>`;
  the `local.` prefix is on the directory, not the selector.
- **Remote skills are references, not copies.** A remote entry is just
  `{ "repo": "owner/repo" }`; `skills` fetches the latest from upstream.
- **Setup commands.** An entry may carry `"setup": "<shell command>"` (e.g. a
  companion npm package). `bin/skill` runs it after install, after confirmation
  (auto-yes with `-y` or `SKILL_YES=1`).
- **Node CLI.** `bin/skill` uses only Node builtins (`fs`, `path`,
  `child_process`). Color codes disabled when stdout is not a TTY.

## Common Commands

```bash
bash tests/run-tests.sh              # Validate catalog + wrapper
bin/skill list                       # List bundles and skills
bin/skill install                    # Install the entire catalog
bin/skill install <bundle>           # Install a bundle (e.g. local, superpowers, recommended)
bin/skill install <name>             # Install one skill (runs its setup command if any)
bin/skill install <name> --dry-run   # Print the `skills` commands without running
bin/skill install <name> -g          # Install globally (user-level)

# Under the hood, or to use skills directly:
npx skills add knowttl/awesome-ai --skill dox-framework   # a local skill from this repo
npx skills add obra/superpowers --skill brainstorming     # a remote skill
npx skills list                                           # what's installed here
npx skills update                                         # update installed skills
```

## Install System

Installation is delegated to `npx skills`, which auto-detects the agents present
in the target project and installs to each (symlinking into `.claude/skills/`
for Claude Code, universal copies for others). It maintains its own
`skills-lock.json` in the target project for restore (`skills experimental_install`).

- **Local skills** install from this repo: `knowttl/awesome-ai --skill <name>`.
- **Remote skills** install from their upstream repo, fetched live (latest).
- **Bundles** replace the old profiles: `bin/skill install <bundle>` loops
  `skills add` over the bundle's entries.
- **Companion packages** install via an entry's `setup` command - e.g. `atelier`
  runs `npm install -g atelier-axi && atelier-axi setup hooks` after the skill
  lands.

**Guided setup**: the `local.awesome-ai-usage` skill is the orchestration entry
point - it detects install vs. uninstall intent and runs the matching workflow
bundled at `skills/local.awesome-ai-usage/resources/`. The top-level
[`SETUP-PROMPT.md`](SETUP-PROMPT.md) and [`UNINSTALL-PROMPT.md`](UNINSTALL-PROMPT.md)
are thin bootstraps for first-time users.

## AGENTS.md-Installing Skills

Some local skills exist to add a block of instructions to a target project's own
`AGENTS.md` (rather than teaching a runtime tool). They bundle the block under
`resources/` and their `SKILL.md` appends it idempotently. Current ones:
`dox-framework`, `agentsmd-init`, `baseline-agents`, `beads-agents`,
`opensrc-agents`, `taste-setup` (see the `agents-md` bundle).

## Skill Naming Convention

- **Local skills**: directory `skills/local.<name>/`, `SKILL.md` frontmatter
  `name: <name>` (no `local.` prefix on the selector), catalog key `<name>`.
- **Remote skills**: not stored here - referenced in `catalog.json` by the
  upstream `owner/repo` and the skill's own selector name.

## Content Format

Each local skill has a `SKILL.md` (required) and a `manifest.yaml` (metadata).
`skills` reads the `SKILL.md` frontmatter; `manifest.yaml` and the catalog carry
our own metadata.

`SKILL.md` frontmatter:

```yaml
---
name: my-skill              # the skills selector - matches the catalog key
description: >
  What it does and when to use it (trigger phrases help discovery).
---
```

`manifest.yaml` (metadata + the file list `skills` should carry):

```yaml
name: local.my-skill        # matches the directory name
type: skill
description: One-line summary.
tags: [local, ...]
targets: [claude-code, github-copilot, ...]
files: [SKILL.md, resources/thing.md]
version: "1.0.0"
source: https://github.com/owner/repo   # omit for purely local skills
```

`catalog.json` entry (add one whenever you add a skill):

```json
"my-skill": { "repo": "knowttl/awesome-ai" }
```
