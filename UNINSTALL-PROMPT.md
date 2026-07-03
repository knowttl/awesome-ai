# Skills Registry Uninstall — Bootstrap Prompt

> **Copy and paste everything below the line into any AI coding assistant.** It ensures the **awesome-ai** orchestration skill is available, then hands off to that skill's guided uninstall workflow. If the skill is already installed, you don't need this file — just say "uninstall my skills" or run `/awesome-ai-usage uninstall`.

## What This Does

This is a thin **bootstrap**. The full removal workflow (inventory scan, selection, confirmation, uninstall, cleanup) lives inside the `awesome-ai-usage` skill, in `resources/uninstall.md`. This prompt just locates the registry and defers to it.

**Prerequisite:** You must be able to run shell commands and read files. If you cannot, stop and tell me.

---

You are running the **awesome-ai** guided uninstall for my project. Do this in order.

## Step 1: Locate the registry

The uninstall workflow needs the registry CLI. Find an existing clone:

```bash
REGISTRY_PATH=""
for dir in ~/skills-registry ~/awesome-ai ~/Projects/awesome-ai ~/.local/share/awesome-ai "$PWD"; do
  if [ -f "$dir/bin/skill" ] && [ -f "$dir/registry.json" ]; then
    REGISTRY_PATH="$dir"; break
  fi
done
echo "${REGISTRY_PATH:-NOT FOUND}"
```

If NOT found, ask me where the registry is cloned (or clone it from https://github.com/knowttl/awesome-ai). Set `REGISTRY_PATH` to that path.

## Step 2: Confirm the project

Run `pwd` to find my project root (`PROJECT_PATH`) and confirm it with me. Note which AI assistant(s) I use (Claude Code → `claude-code`, GitHub Copilot → `github-copilot`, Cursor → `cursor`, Cline → `cline`, OpenCode → `opencode`, Codex → `codex`, Windsurf → `windsurf`, Roo Code → `roo`).

## Step 3: Hand off to the guided uninstall workflow

Read the skill's full removal workflow and execute it step by step, reusing the `REGISTRY_PATH` and `PROJECT_PATH` you just established:

```
<REGISTRY_PATH>/skills/local.awesome-ai-usage/resources/uninstall.md
```

Follow `resources/uninstall.md` to completion — it scans what's installed, lets me select what to remove, confirms before deleting, and cleans up.
