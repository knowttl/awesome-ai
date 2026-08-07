---
name: awesome-ai-usage
description: >
  Orchestration skill for the awesome-ai skills-registry. Use when the user
  wants to install/set up, uninstall/remove, update, or list skills; browse what
  is available; install a bundle; seed a project's AGENTS.md; or run the guided
  onboarding, removal, or update/health-check workflows. Also use when the user
  says things like "/awesome-ai-usage install", "/awesome-ai-usage uninstall",
  "/awesome-ai-usage update", "set up skills for this project", "onboard this
  project", "what skills are available?", "add the brainstorming skill", "remove
  create-glossary", "update my skills", "is my skills setup healthy?", or "how do
  I share my skill setup with my team?".
---

# Awesome-AI Skills-Registry Orchestration

You are an AI assistant in a project that uses the **awesome-ai** skills-registry.
Skills are installed by [`skills`](https://github.com/vercel-labs/skills)
(`npx skills`), which auto-detects the AI assistants present in a project and
installs to each. This skill teaches you to onboard a project, install/remove/
update skills, and share setups.

## Intent Dispatch (read this first)

| The user's request | What to do |
|---|---|
| `/awesome-ai-usage install`, "set up skills", "onboard this project", first-time setup | Load and follow **`resources/setup.md`**. |
| `/awesome-ai-usage uninstall`, "remove my skills", "uninstall everything" | Load and follow **`resources/uninstall.md`**. |
| `/awesome-ai-usage update`, "update my skills", "is my setup healthy?", "health check" | Load and follow **`resources/update.md`**. |
| A single concrete action ("add the brainstorming skill", "remove create-glossary", "list skills") | Stay in this file - use the [Command Reference](#command-reference). Do **not** run a full workflow for a single action. |

The `resources/*.md` files live next to this `SKILL.md`. Read the relevant one in
full and execute it step by step. When the intent is ambiguous - e.g. the user
types `/awesome-ai-usage` with no argument - ask whether they want to
**install**, **uninstall**, **update / health-check**, or a specific action.

## How Installing Works

Two entry points:

- **`npx skills`** - needs no clone. Best for single skills.
  - `npx skills add knowttl/awesome-ai --skill <name> -y` - a local skill from this registry
  - `npx skills add <owner/repo> --skill <name> -y` - a remote skill from its upstream
- **`bin/skill`** (a clone of this registry) - a thin Node wrapper for **bundles**
  and the **whole catalog**, and for running companion-package `setup` commands.
  - `bin/skill install <bundle>` - install a named bundle
  - `bin/skill install` - install the entire catalog
  - `bin/skill list` - list bundles and skills

`skills` installs project-level by default (auto-detecting agents), or globally
with `-g`. It maintains its own `skills-lock.json` in the target project.

**`PROJECT`** - the target project root (default: `pwd`; confirm if the user
names another). Install commands run from inside `PROJECT` so `skills` detects
its agents and writes there.

To locate a registry clone for bundle installs, check `$HOME/awesome-ai`,
`$HOME/Projects/awesome-ai`, `$HOME/skills-registry`, or the current tree for a
`bin/skill` + `catalog.json` pair. If none exists and the user wants a bundle,
either clone `https://github.com/knowttl/awesome-ai` or install the bundle's
skills one-by-one with `npx skills add knowttl/awesome-ai --skill <name>`.

## Command Reference

### List what's available

```bash
bin/skill list                       # bundles + skills (needs a clone)
npx skills find                      # search skills interactively (no clone)
```

### Install

```bash
# Single skill (no clone needed) - run from inside PROJECT
npx skills add knowttl/awesome-ai --skill dox-framework -y   # a local skill
npx skills add obra/superpowers --skill brainstorming -y     # a remote skill

# A bundle or the whole catalog (needs a clone)
bin/skill install recommended -y
bin/skill install                    # entire catalog

# Global instead of project-level
npx skills add knowttl/awesome-ai --skill dox-framework -g -y
```

Some skills need a companion package. Their catalog entry carries a `setup`
command (e.g. `atelier` → `npm install -g atelier-axi && atelier-axi setup hooks`).
`bin/skill install` offers to run it after install; if you installed the skill
directly with `npx skills`, run the setup command yourself.

### List installed / update / remove

```bash
npx skills list                      # what's installed in PROJECT
npx skills update                    # update installed skills to latest
npx skills remove <name>             # remove a skill
npx skills experimental_install      # restore from skills-lock.json
```

## Project AGENTS.md Setup

Every project should have an `AGENTS.md` as the canonical AI-instructions file,
with symlinks for tools that read other names.

```bash
if [ ! -f "$PROJECT/AGENTS.md" ]; then
  echo "# $(basename "$PROJECT")" > "$PROJECT/AGENTS.md"
fi
[ -e "$PROJECT/CLAUDE.md" ]   || ln -s AGENTS.md "$PROJECT/CLAUDE.md"
```

Do this when onboarding. If `CLAUDE.md`/`.cursorrules` already exist as regular
files, don't overwrite without asking - offer to consolidate into `AGENTS.md`
and replace with symlinks. Several local skills (`dox-framework`,
`baseline-agents`, `beads-agents`, `opensrc-agents`, `taste-setup`) install
instruction blocks into `AGENTS.md`; invoke them when the user wants those.

## Common Workflows

- **"what skills are available?"** → `bin/skill list` (or `npx skills find`).
- **"install the brainstorming skill"** → `npx skills add obra/superpowers --skill brainstorming -y` from inside `PROJECT`.
- **"remove create-glossary"** → `npx skills remove create-glossary`.
- **"what's installed here?"** → `npx skills list`.
- **"update my skills"** → `npx skills update`.
- **"share my setup with my team"** → commit `catalog.json` (curated set) and/or the project's `skills-lock.json`; teammates run `bin/skill install <bundle>` or `npx skills experimental_install`.

## Guided Workflows

- **`resources/setup.md`** - onboarding: detect environment, select skills,
  install, seed `AGENTS.md`, optionally set up beads / taste.
- **`resources/uninstall.md`** - scan installed skills, select, confirm, remove.
- **`resources/update.md`** - update installed skills and run a health check.

For a single concrete action, use the [Command Reference](#command-reference)
directly - don't launch a workflow.

## Safety Rules

- Pass `-y` when acting on the user's behalf - they already gave the intent.
- Run install commands from inside `PROJECT` so `skills` targets the right project.
- Never modify this registry's own files (under `skills/`, `bin/`, `catalog.json`)
  unless the user is developing the registry itself.
- Confirm before running a `setup` command that installs a global package.
