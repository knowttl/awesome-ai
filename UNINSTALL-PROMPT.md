# Skills Registry Uninstall - Bootstrap Prompt

> **Copy and paste everything below the line into any AI coding assistant.** It ensures the **awesome-ai** orchestration skill is available, then hands off to that skill's guided uninstall workflow. If the skill is already installed, you don't need this file - just say "uninstall my skills" or run `/awesome-ai-usage uninstall`.

## What This Does

This is a thin **bootstrap**. The full removal workflow (inventory scan, selection, confirmation, uninstall, cleanup) lives inside the `awesome-ai-usage` skill, in `resources/uninstall.md`. This prompt just makes that workflow available and defers to it.

**Prerequisite:** You must be able to run shell commands (including `npx`) and read files. If you cannot, stop and tell me.

---

You are running the **awesome-ai** guided uninstall for my project. Do this in order.

## Step 1: Find the uninstall workflow

If the `awesome-ai-usage` skill is already installed in my project, read its workflow from the installed location (e.g. `.claude/skills/awesome-ai-usage/resources/uninstall.md`).

If it is not installed, either install it or read the workflow from a clone of the registry:

```bash
npx -y skills add knowttl/awesome-ai --skill awesome-ai-usage -y
# or, without installing:
git clone https://github.com/knowttl/awesome-ai /tmp/awesome-ai 2>/dev/null || true
# then read skills/local.awesome-ai-usage/resources/uninstall.md
```

## Step 2: Confirm the project

Run `pwd` to find my project root and confirm it with me. Note which AI assistant(s) I use.

## Step 3: Hand off to the guided uninstall workflow

Read the removal workflow (`resources/uninstall.md`) and execute it step by step, reusing the project path you just established. It scans what's installed (via `npx skills list`), lets me select what to remove (`npx skills remove <name>`), confirms before deleting, and cleans up. Follow it to completion.
