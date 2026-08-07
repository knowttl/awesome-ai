# Skills Registry Setup - Bootstrap Prompt

> **Copy and paste everything below the line into any AI coding assistant.** It installs the **awesome-ai** orchestration skill, then hands off to that skill's guided setup workflow. Once the skill is installed, you never need this file again - just say "set up skills for this project" or run `/awesome-ai-usage install`.

## What This Does

This is a thin **bootstrap**. The full onboarding workflow (environment detection, skill selection, install, AGENTS.md, beads, taste) lives inside the `awesome-ai-usage` skill, in `resources/setup.md`. This prompt just gets that skill installed and then defers to it.

**Prerequisite:** You must be able to run shell commands (including `npx`) and read files. If you cannot, stop and tell me.

---

You are bootstrapping the **awesome-ai** skills-registry for my project, then running its guided setup. Do this in order and keep me informed at each step.

## Step 1: Install the orchestration skill

The registry lives at https://github.com/knowttl/awesome-ai. Skills are installed with [`skills`](https://github.com/vercel-labs/skills) (`npx skills`), which auto-detects the AI assistants present in my project. Install the orchestration skill directly from the registry repo:

```bash
npx -y skills add knowttl/awesome-ai --skill awesome-ai-usage -y
```

Confirm it landed (e.g. `.claude/skills/awesome-ai-usage/` for Claude Code, or the equivalent for my assistant).

## Step 2: Get the setup workflow

The full workflow file ships inside the skill you just installed. Read it from the installed location - look for `awesome-ai-usage/resources/setup.md` under my project's skills directory (e.g. `.claude/skills/awesome-ai-usage/resources/setup.md`). If you can't find it there, clone the registry and read it from `skills/local.awesome-ai-usage/resources/setup.md`:

```bash
git clone https://github.com/knowttl/awesome-ai /tmp/awesome-ai 2>/dev/null || true
```

## Step 3: Confirm the project

Run `pwd` to find my project root and confirm it with me. State which AI assistant you are, and ask whether I use others alongside it.

## Step 4: Hand off to the guided setup workflow

Read the setup workflow (`resources/setup.md`) and execute it step by step, reusing the project path you just established. From here on, everything is driven by the `awesome-ai-usage` skill. Follow `resources/setup.md` to completion.
