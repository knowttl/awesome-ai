# Skills Registry Setup — Bootstrap Prompt

> **Copy and paste everything below the line into any AI coding assistant.** It installs the **awesome-ai** orchestration skill, then hands off to that skill's guided setup workflow. Once the skill is installed, you never need this file again — just say "set up skills for this project" or run `/awesome-ai-usage install`.

## What This Does

This is a thin **bootstrap**. The full onboarding workflow (environment detection, skill selection, install, AGENTS.md, beads, taste, OpenSrc) lives inside the `awesome-ai-usage` skill, in `resources/setup.md`. This prompt just gets that skill installed and then defers to it.

**Prerequisite:** You must be able to run shell commands and read files. If you cannot, stop and tell me.

---

You are bootstrapping the **awesome-ai** skills-registry for my project, then running its guided setup. Do this in order and keep me informed at each step.

## Step 1: Locate or clone the registry

The **skills-registry** (https://github.com/knowttl/awesome-ai) is a zero-dependency CLI (pure Bash + PowerShell) that installs AI coding skills into project-local directories.

Search for an existing clone, then fall back to cloning:

```bash
REGISTRY_PATH=""
for dir in ~/skills-registry ~/awesome-ai ~/Projects/awesome-ai ~/.local/share/awesome-ai "$PWD"; do
  if [ -f "$dir/bin/skill" ] && [ -f "$dir/registry.json" ]; then
    REGISTRY_PATH="$dir"; break
  fi
done
echo "${REGISTRY_PATH:-NOT FOUND}"
```

- **If found**, refresh it: `cd "$REGISTRY_PATH" && git pull && bin/skill sync` ("Already up to date" is fine; `sync` must still run).
- **If NOT found**, ask me where to clone it (offer `~/skills-registry` as a persistent default, `/tmp/skills-registry` as a throwaway, or a custom path). Wait for my choice, then `git clone https://github.com/knowttl/awesome-ai <path>` and run `bin/skill sync` in it. Set `REGISTRY_PATH` to that path.

## Step 2: Detect environment

- You already know which AI assistant you are — state it, and ask if I use others alongside it. Map each to its `--agent` flag: Claude Code → `claude-code`, GitHub Copilot → `github-copilot`, Cursor → `cursor`, Cline → `cline`, OpenCode → `opencode`, Codex → `codex`, Windsurf → `windsurf`, Roo Code → `roo`.
- Run `pwd` to find my project root (`PROJECT_PATH`). Confirm it with me.

## Step 3: Install the orchestration skill

Install `local.awesome-ai-usage` into my project for each detected agent:

```bash
"$REGISTRY_PATH/bin/skill" install local.awesome-ai-usage --target "<PROJECT_PATH>" --agent <AGENT_1> --agent <AGENT_2> --yes
```

Always pass `--agent` explicitly (never rely on auto-detection). Confirm it appears in `<PROJECT_PATH>/.skills-lock.json`.

## Step 4: Hand off to the guided setup workflow

Now read the skill's full onboarding workflow and execute it step by step, reusing the `REGISTRY_PATH` and `PROJECT_PATH` you already established (skip its re-detection of those):

```
<REGISTRY_PATH>/skills/local.awesome-ai-usage/resources/setup.md
```

From here on, everything is driven by the `awesome-ai-usage` skill. Follow `resources/setup.md` to completion.
