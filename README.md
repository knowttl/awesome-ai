# skills-registry

A curated catalog of reusable **skills** for AI-assisted coding, installed with
[`npx skills`](https://github.com/vercel-labs/skills). Local skills live in this
repo; third-party skills are referenced in [`catalog.json`](catalog.json) and
fetched live from their upstreams - never vendored here.

> **How it works.** `npx skills` (the `skills` CLI, 75+ agents) does the actual
> installing. This repo curates *which* skills, groups them into bundles, and
> ships a thin Node wrapper (`bin/skill`) to install them in one command.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Guided Setup (AI-Assisted)](#guided-setup-ai-assisted)
- [What's Inside](#whats-inside)
- [CLI Reference](#cli-reference)
- [Installing With `skills` Directly](#installing-with-skills-directly)
- [Adding Your Own Skill](#adding-your-own-skill)
- [Bundles](#bundles)
- [Reproducibility & Team Sharing](#reproducibility--team-sharing)
- [Project Structure](#project-structure)
- [Running Tests](#running-tests)

---

## Quick Start

Requires Node (for `npx`). From a clone of this repo:

```bash
# Browse what's available
bin/skill list

# Install one skill into the current project (runs its setup command, if any)
bin/skill install dox-framework

# Install a bundle
bin/skill install recommended

# Install the entire catalog
bin/skill install

# Preview the underlying `skills` commands without running them
bin/skill install recommended --dry-run
```

You don't strictly need a clone - any skill can be installed directly with
`npx skills` (see [below](#installing-with-skills-directly)). The wrapper's value
is installing bundles / the whole catalog and running companion-package setup
commands in one step.

---

## Guided Setup (AI-Assisted)

For a guided, interactive experience, copy [`SETUP-PROMPT.md`](SETUP-PROMPT.md)
into any AI coding assistant with terminal access. It installs the
`awesome-ai-usage` orchestration skill, then hands off to that skill's setup
workflow, which walks you through selecting and installing skills, optionally
seeding an `AGENTS.md`, and optionally setting up Beads (`bd`).

Once `awesome-ai-usage` is installed you don't need the bootstrap file again -
just tell your assistant "set up skills for this project" or run
`/awesome-ai-usage install`. To remove skills, use
[`UNINSTALL-PROMPT.md`](UNINSTALL-PROMPT.md) or `/awesome-ai-usage uninstall`.

---

## What's Inside

Run `bin/skill list` for the live list. Skills are grouped into **bundles**:

| Bundle | Contents |
|--------|----------|
| `local` | All skills maintained in this repo (below) |
| `superpowers` | The full [obra/superpowers](https://github.com/obra/superpowers) set |
| `anthropic` | `frontend-design`, `skill-creator` from [anthropics/skills](https://github.com/anthropics/skills) |
| `axi` | `atelier`, `chrome-devtools-axi`, `lavish` |
| `agents-md` | Skills that add instruction blocks to a project's `AGENTS.md` |
| `recommended` | A small opinionated starter set |

### Local skills (this repo)

| Skill | When to Use |
|-------|-------------|
| `agentsmd-init` | Initialize, refresh, or audit a repo's `AGENTS.md`/`CLAUDE.md`/cursor rules |
| `awesome-ai-usage` | Orchestrate this registry - guided install / uninstall / update |
| `baseline-agents` | Drop in a baseline `AGENTS.md` of behavioral guidelines |
| `beads-agents` | Add beads (`bd`) recall/remember instructions to `AGENTS.md` |
| `beads-workflow` | Set up beads (`bd`), track issues, record lessons with `bd remember` |
| `create-glossary` | Create/update `GLOSSARY.md` and wire `AGENTS.md` to it |
| `design-system` | Generate (or reverse-engineer) a design system and flag UI drift |
| `dox-framework` | Install the [DOX](https://github.com/agent0ai/dox) hierarchical `AGENTS.md` contract |
| `example-skill` | Reference template showing the skill structure |
| `mind-clear` | Interview to uncover the real goal and produce a spec-generation prompt |
| `opensrc-agents` | Add `opensrc` dependency-source guidance to `AGENTS.md` |
| `taste-developer` | Learn your preferences from accepted/rejected/edited outputs |
| `taste-setup` | Add the Taste Developer opt-in prompt to `AGENTS.md` |

### Remote skills (referenced, fetched live)

The `superpowers`, `anthropic`, and `axi` bundles plus `grill-with-docs`,
`drawio-skill`, `prompt-builder`, and `improve` are all defined in
[`catalog.json`](catalog.json) as references to their upstream repos.

---

## CLI Reference

`bin/skill` is a thin Node wrapper over `npx skills`.

```
bin/skill install                 Install every skill in the catalog
bin/skill install <bundle>        Install a named bundle
bin/skill install <name>          Install a single skill (+ its setup command)
bin/skill list                    List bundles and skills
bin/skill help                    Show help
```

| Flag | Description |
|------|-------------|
| `-a, --agent <agents>` | Target agents passed to `skills -a` (e.g. `'*'`, `claude-code`). Default: `skills` auto-detects |
| `-g, --global` | Install globally (user-level) instead of project-level |
| `-y, --yes` | Auto-confirm setup commands (or set `SKILL_YES=1`) |
| `--dry-run` | Print the `skills` commands without running them |

**Companion packages.** Some skills need a runtime tool. Their catalog entry
carries a `setup` command that `bin/skill` offers to run after install. For
example, `atelier` installs the skill, then (on confirmation) runs
`npm install -g atelier-axi && atelier-axi setup hooks`.

---

## Installing With `skills` Directly

Every catalog entry maps to a plain `skills` command:

```bash
# A local skill from this repo
npx skills add knowttl/awesome-ai --skill dox-framework

# A remote skill from its upstream
npx skills add obra/superpowers --skill brainstorming

# What's installed here / update / remove
npx skills list
npx skills update
npx skills remove brainstorming
```

`skills` auto-detects the agents in your project and installs to each
(symlinking into `.claude/skills/` for Claude Code, universal copies for others).

---

## Adding Your Own Skill

1. Create the skill directory and `SKILL.md`:

   ```bash
   mkdir -p skills/local.my-skill
   ```

   ```markdown
   ---
   name: my-skill
   description: What it does and when to use it.
   ---

   # My Skill

   Instructions for the AI agent go here.
   ```

2. Add a `manifest.yaml` (metadata + the files `skills` should carry):

   ```yaml
   name: local.my-skill
   type: skill
   description: One-line summary.
   tags: [local]
   targets: [claude-code, github-copilot]
   files: [SKILL.md]
   version: "1.0.0"
   ```

3. Register it in [`catalog.json`](catalog.json) and add it to any bundles:

   ```json
   "my-skill": { "repo": "knowttl/awesome-ai" }
   ```

4. Verify:

   ```bash
   bash tests/run-tests.sh
   ```

The `SKILL.md` frontmatter `name`, the `catalog.json` key, and the bundle
references must all use the same selector (`my-skill`). The `local.` prefix is
only on the directory name.

---

## Bundles

Bundles are named lists of catalog entries - they replace the old profiles.
Define them under `"bundles"` in `catalog.json`:

```json
"bundles": {
  "my-workflow": ["brainstorming", "systematic-debugging", "verification-before-completion"]
}
```

```bash
bin/skill install my-workflow
```

---

## Reproducibility & Team Sharing

Two layers:

- **`catalog.json`** (this repo) is the curated source of truth for *what the
  team installs*. Commit it; teammates run `bin/skill install <bundle>` to get
  the same set.
- **`skills-lock.json`** (created by `skills` in each target project) pins what
  was actually installed there. Restore it with `npx skills experimental_install`.

Remote skills track their upstream's latest by default, so the set is
reproducible even though individual skills stay current.

---

## Project Structure

```
skills-registry/
├── catalog.json            # Source of truth: items (local + remote) + bundles
├── bin/skill               # Node CLI wrapper over `npx skills`
├── skills/local.<name>/    # Local skill dirs (SKILL.md + manifest.yaml + resources/)
├── tests/
│   ├── run-tests.sh        # Test entry point
│   └── test-catalog.js     # Validates catalog against skills/ + exercises bin/skill
├── AGENTS.md               # Project instructions (CLAUDE.md symlinks to it)
├── SETUP-PROMPT.md         # Guided-setup bootstrap
└── UNINSTALL-PROMPT.md     # Guided-uninstall bootstrap
```

---

## Running Tests

```bash
bash tests/run-tests.sh
```

The suite validates `catalog.json` against the `skills/` tree (every entry
resolves, no orphans, manifest files exist) and exercises the `bin/skill`
wrapper (list, dry-run, unknown-target handling).
