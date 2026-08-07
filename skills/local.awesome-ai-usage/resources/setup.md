# Setup Workflow

> **Orchestration resource for the `awesome-ai-usage` skill.** Loaded when the user asks to install or set up skills (`/awesome-ai-usage install`, "set up skills for this project", "onboard this project"). Follow it as an interactive, step-by-step workflow - present each step and wait for the user before proceeding.

## Model

Skills install with [`skills`](https://github.com/vercel-labs/skills) (`npx skills`), which auto-detects the AI assistants in the project and installs to each. You do **not** clone the registry or pass agent flags for single skills.

- Install a local skill: `npx skills add knowttl/awesome-ai --skill <selector> -y`
- Install a remote skill: `npx skills add <owner/repo> --skill <selector> -y`
- Run these **from inside the project root** so `skills` targets the right project.
- `skills` writes a `skills-lock.json` in the project; restore with `npx skills experimental_install`.

**`PROJECT`** = the project root (default `pwd`; confirm with the user). Prerequisite: you can run shell commands (including `npx`) and read files. If not, stop and say so.

## Idempotent by design

Each step checks current state first and skips what's already done. `npx skills list` shows what's installed. Re-running is safe.

---

## Step 1: Confirm environment

- State which AI assistant you are, and ask whether the user uses others alongside it (that's fine - `skills` installs for all detected agents automatically).
- Run `pwd`; confirm it's the project root the user wants (`PROJECT`).
- Scan current state:

```bash
npx skills list 2>/dev/null || echo "nothing installed yet"
for f in AGENTS.md CLAUDE.md .cursorrules .github/copilot-instructions.md; do [ -e "$PROJECT/$f" ] && echo "found: $f"; done
[ -d "$PROJECT/.beads" ] && echo "beads database present"; command -v bd >/dev/null && echo "bd on PATH"
```

Present findings and confirm before continuing.

## Step 2: Present the catalog and let the user choose

Show what's available. If you have a registry clone, `bin/skill list`; otherwise describe the bundles and skills from memory / the repo's README, or run `npx skills find`. Key local skills:

| Selector | What it does |
|---|---|
| `agentsmd-init` | Generate/audit the project's `AGENTS.md` |
| `baseline-agents` | Baseline behavioral guidelines for `AGENTS.md` |
| `dox-framework` | Install the DOX hierarchical `AGENTS.md` contract |
| `mind-clear` | Interview to produce a spec before building |
| `create-glossary`, `design-system` | Glossary / design-system skills |
| `beads-agents`, `beads-workflow` | Beads issue-tracking + memory (see Step 5) |
| `taste-setup`, `taste-developer` | Adaptive preference learning (see Step 6) |
| `opensrc-agents` | Dependency-source inspection guidance |

Remote bundles: `superpowers` (obra/superpowers), `anthropic`, `axi` (atelier, chrome-devtools, lavish).

Ask which skills or bundles the user wants. Map their answer to selectors. If they say "recommend", suggest a balanced set (e.g. `dox-framework` or `baseline-agents`, `brainstorming`, `systematic-debugging`, `verification-before-completion`).

## Step 3: Install the selected skills

From inside `PROJECT`, install each selected skill:

```bash
cd "$PROJECT"
npx skills add knowttl/awesome-ai --skill <selector> -y     # local skills
npx skills add obra/superpowers --skill <selector> -y       # e.g. superpowers skills
```

For a skill with a companion package (e.g. `atelier`), after installing the skill run its setup command - confirm with the user first:

```bash
npm install -g atelier-axi && atelier-axi setup hooks
```

Verify with `npx skills list`. Report what was installed.

## Step 4: Project AGENTS.md

Ensure the project has an `AGENTS.md` (canonical AI-instructions file), with a `CLAUDE.md` symlink:

```bash
[ -f "$PROJECT/AGENTS.md" ] || echo "# $(basename "$PROJECT")" > "$PROJECT/AGENTS.md"
[ -e "$PROJECT/CLAUDE.md" ] || (cd "$PROJECT" && ln -s AGENTS.md CLAUDE.md)
```

If `CLAUDE.md`/`.cursorrules` already exist as real files, don't overwrite - offer to consolidate into `AGENTS.md` and symlink.

Then, if the user wants richer project instructions, invoke the installed skills that append blocks to `AGENTS.md`:

- **`dox-framework`** - installs the DOX hierarchical contract and (in an existing project) scaffolds child `AGENTS.md` files. Recommended when the user wants agents to walk a docs tree before editing.
- **`baseline-agents`** - appends baseline behavioral guidelines.
- **`agentsmd-init`** - investigates the repo and writes/audits high-signal facts (commands, conventions).

Invoke whichever the user chose; each is idempotent and appends its own section.

## Step 5: Beads - issue tracking & memory (always offer)

Beads (`bd`) gives agents a dependency-aware issue graph plus persistent memory (`bd prime` / `bd remember`). Ask once (skip only if `beads-agents` and `beads-workflow` are already installed):

> Set up **Beads**? Your AI will track features/bugs as a graph and recall prior lessons with `bd prime` before tasks / record them with `bd remember` after, so it avoids repeat failures.

If yes:

1. Install the skills: `npx skills add knowttl/awesome-ai --skill beads-agents -y` and `--skill beads-workflow -y`.
2. Invoke the **`beads-agents`** skill to append its instruction block to `AGENTS.md`.
3. Ensure the `bd` CLI (ask before a system install): `brew install beads`, or `npm install -g @beads/bd`, or the install script at https://github.com/gastownhall/beads. If declined, note it's deferred.
4. `cd "$PROJECT" && bd init` (idempotent - skip if `.beads/` exists). This creates `.beads/` and wires a Dolt `origin` remote when the git repo has one.
5. Wire agent hooks as available: `bd setup claude`, `bd setup codex`, etc. (`bd setup --help` to see which exist).
6. **Team sync (ask first).** Beads shares the full database (issues + memories) over the git remote via a `refs/dolt/data` ref - not the `.beads/issues.jsonl` export. If the user wants it and origin exists: register the Dolt-over-git remote (`bd dolt remote add origin git+ssh://git@github.com/org/repo.git`), gitignore `.beads/issues.jsonl`, then `bd dolt push` and verify `git ls-remote origin 'refs/dolt/*'`.
7. Verify: `bd ready` runs and `bd prime` prints context.

Explain runtime behavior: agents `bd dolt pull` + `bd prime` + `bd ready` before tasks, track work as beads (not TODO lists), and propose `bd remember` only after a real lesson. Follow the memory format in the `beads-workflow` skill. `.beads/issues.jsonl` is an export only - gitignored, never the sync source.

## Step 6: Taste (optional)

Ask once (skip if `taste-setup` and `taste-developer` are already installed):

> Enable **Taste Developer**? It learns your preferences from outputs you accept/reject/edit and auto-adjusts over time.

If yes: install `taste-setup` and `taste-developer` (add `-g` for global/all-projects if the user wants). Invoke `taste-setup` to append its opt-in prompt to `AGENTS.md`. A taste profile lives at `.ai/taste/taste.md`; the user can also say "start taste" later.

## Step 7: OpenSrc (optional)

Ask once (skip if `opensrc-agents` is installed):

> Add **OpenSrc** guidance for inspecting dependency source when docs/types aren't enough?

If yes: `npx skills add knowttl/awesome-ai --skill opensrc-agents -y`, invoke it to append its block to `AGENTS.md`, and check `command -v opensrc` (offer `npm install -g opensrc` if missing).

## Step 8: Summary & commit

Summarize: skills installed (`npx skills list`), `AGENTS.md` changes, beads/taste/opensrc status, and that `skills-lock.json` was created (commit it so teammates restore with `npx skills experimental_install`; the curated set lives in the registry's `catalog.json`).

Then ask explicitly: **"Commit these changes to git?"** If yes, `git status`, stage only what this run touched (`skills-lock.json`, `AGENTS.md`, `.gitignore`, `.beads/config.yaml`, etc.), and commit with a concise message following the project's own conventions. Never commit without an explicit yes, and never stage files this run didn't touch.
