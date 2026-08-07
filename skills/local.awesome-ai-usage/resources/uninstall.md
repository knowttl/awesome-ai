# Uninstall Workflow

> **Orchestration resource for the `awesome-ai-usage` skill.** Loaded when the user asks to remove skills (`/awesome-ai-usage uninstall`, "remove my skills", "uninstall everything"). Follow it interactively - scan, let the user select, confirm, then remove.

## Model

Skills are managed by [`skills`](https://github.com/vercel-labs/skills) (`npx skills`). Removal uses `npx skills remove`, run **from inside the project root** (`PROJECT`, default `pwd`; confirm with the user).

## Step 1: Inventory what's installed

```bash
cd "$PROJECT"
npx skills list
```

Also note any skills that added blocks to `AGENTS.md` (`dox-framework`, `baseline-agents`, `beads-agents`, `opensrc-agents`, `taste-setup`) and any project state they created (`.beads/`, `.ai/taste/`), since removing a skill does not automatically revert those edits.

Present the full list grouped clearly. If nothing is installed, say so and stop.

## Step 2: Let the user select what to remove

Ask which skills to remove - specific names, a group, or "all". Map the answer to selectors. Confirm the exact list back to the user before doing anything.

## Step 3: Confirm, then remove

After explicit confirmation:

```bash
npx skills remove <selector>          # one skill
npx skills remove --all               # everything (shorthand for --skill '*' --agent '*' -y)
```

Report what was removed and re-run `npx skills list` to confirm.

## Step 4: Offer to clean up side effects

Removing a skill leaves its edits/state behind. Offer, only with explicit confirmation for each:

- **`AGENTS.md` blocks** - if the user removed `dox-framework`/`baseline-agents`/`beads-agents`/`opensrc-agents`/`taste-setup`, offer to delete the corresponding section from `AGENTS.md`. Show the section first; never edit `AGENTS.md` without a yes.
- **Beads** - `.beads/` holds the issue/memory database. Do **not** delete it unless the user is certain; it may hold shared history synced over the git remote. Deleting is destructive and hard to reverse.
- **Taste** - `.ai/taste/` holds the learned profile. Offer to remove only on explicit request.

## Step 5: Summary & commit

Summarize what was removed and what was intentionally left. Ask **"Commit these changes to git?"** If yes, stage only what this run touched and commit with a concise message. Never commit without an explicit yes.
