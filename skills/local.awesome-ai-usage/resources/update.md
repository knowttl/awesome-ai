# Update Workflow

> **Orchestration resource for the `awesome-ai-usage` skill.** Loaded when the user asks to update installed skills or check their setup's health (`/awesome-ai-usage update`, "update my skills", "is my skills setup healthy?"). Follow it interactively.

## Model

Skills are managed by [`skills`](https://github.com/vercel-labs/skills) (`npx skills`). Remote skills track their upstream's latest; local skills track this registry. Run commands **from inside the project root** (`PROJECT`, default `pwd`; confirm with the user).

## Step 1: Update installed skills

```bash
cd "$PROJECT"
npx skills list           # show current state first
npx skills update         # update all installed skills to latest
```

`npx skills update` pulls the latest version of each installed skill from its source (local skills from `knowttl/awesome-ai`, remote skills from their upstream). Report what changed.

To update a single skill: `npx skills update <selector>`.

## Step 2: Health check

Verify the setup is consistent:

- **Installed vs. expected** - `npx skills list` against what the user expects. Re-add anything missing with `npx skills add knowttl/awesome-ai --skill <selector> -y` (or the remote repo).
- **Lock file** - `skills-lock.json` should exist in `PROJECT`. If it drifted from what's installed, `npx skills experimental_install` restores from it.
- **Companion packages** - for skills that need a CLI (e.g. `atelier` → `atelier-axi`), confirm the tool is on PATH; re-run its setup command if not (`npm install -g atelier-axi && atelier-axi setup hooks`).
- **AGENTS.md blocks** - for `dox-framework`/`baseline-agents`/`beads-agents`/`opensrc-agents`/`taste-setup`, confirm their section is still present in `AGENTS.md`; re-invoke the skill to re-append if it was lost.
- **Beads** - if `.beads/` exists, `bd ready` should run and (if a sync remote is configured) `bd dolt pull` should succeed. Surface any conflict instead of forcing it.

Fix issues only with the user's confirmation.

## Step 3: Summary & commit

Summarize what was updated and any health issues found/fixed. If files changed, ask **"Commit these changes to git?"** If yes, stage only what this run touched and commit with a concise message. Never commit without an explicit yes.
