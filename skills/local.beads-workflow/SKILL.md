---
name: beads-workflow
description: "Use when setting up beads (bd), recalling context with scripts/bd prime, tracking issues, or recording lessons with scripts/bd remember."
---

# Beads Workflow

Detailed procedures for setting up and using **beads** (`bd`) — a dependency-aware
issue tracker that doubles as persistent agent memory. Source:
<https://github.com/gastownhall/beads>.

`bd` is a system-wide CLI (installed via Homebrew / npm / script), **not** file-copied
content. NexTrade invokes it only through `scripts/bd`, which resolves and locks the one
shared tracker home outside every working copy. This skill covers installing the real CLI,
bootstrapping that shared home, and using recall (`scripts/bd prime`) and memory
(`scripts/bd remember`). The routine pre-task recall and post-task learning discipline lives
in the `local.beads` instruction; this skill is the on-demand reference and the setup path.

Goal: track features/bugs/tasks as a graph instead of markdown TODO lists, and capture
high-signal lessons — gotchas, edge cases, and environment quirks — so future agents stop
repeating mistakes. Not every task produces a save-worthy lesson.

## When to Use

- Setting up beads on a machine for the first time (install `bd`, bootstrap the shared home,
  agent hooks).
- The user approved recording a lesson (from the `local.beads` instruction).
- The user asks to create, inspect, or close tracked issues.
- The user asks to review or clean up stored memories.

Do NOT use this skill for the routine pre-task recall — that is handled inline by the
`local.beads` instruction (`scripts/bd prime` / `scripts/bd ready`).

## Deterministic Rules

- The one shared database resolved by `scripts/bd` is the single source of truth. Never
  initialize or use a private `.beads/embeddeddolt`, and never create `.ai/memory/`,
  `MEMORY.md`, or markdown TODO lists alongside it.
- Run every tracker command through `scripts/bd`; bare `bd` can resolve a private database
  or the live deployment checkout.
- Recall with `scripts/bd prime` before work; record with `scripts/bd remember` only after work.
- On a similar lesson, prefer refining an existing memory over recording a near-duplicate.
- **Default to generalized, pattern-level memories.** Capture the reusable lesson, not the
  one-off incident. Keep specifics only when justified (see the Generalization Rule).
- Keep memory strings concise and actionable. Strip transient paths and one-time details.
- **Always use the Standard Memory Format** (see Operation 4, Step 2) so every memory is
  consistently searchable with `scripts/bd memories <keyword>` and dedup-able via a stable
  `--key`.

## Operations

1. **Setup** — Install `bd` and bootstrap the shared tracker home
2. **Recall** — Load context and available work before a task
3. **Track** — Create, link, claim, and close issues
4. **Remember** — Record a durable lesson after a task
5. **Maintain** — Review memories and sync the database with teammates

---

## Operation 1: Setup (First Use)

Run when `bd` is missing or this machine has no configured shared tracker home.

### Step 1: Ensure the `bd` CLI is installed

Check for it first:

```bash
command -v bd
```

If it is missing, install it (prefer the user's existing package manager, and confirm
before installing system-wide):

```bash
brew install beads                 # macOS / Linuxbrew (recommended)
npm install -g @beads/bd           # any environment with npm
curl -fsSL https://raw.githubusercontent.com/gastownhall/beads/main/scripts/install.sh | bash
```

If you cannot or should not install system software, print the commands and let the user
run them, then continue once `command -v bd` succeeds.

### Step 2: Bootstrap the shared tracker home

```bash
scripts/beads-home.sh bootstrap
```

This clones the shared database outside every working copy, copies the committed project
identity and sync configuration, and writes the machine-local pointer used by `scripts/bd`.
It refuses a target inside any git work tree.
Never initialize Beads directly in a checkout because that creates the private database
this project has retired.

### Step 3: Wire agent-specific hooks

Beads ships dedicated setup for some agents; map the registry's agent flags:

| Agent flag        | Command                        |
|-------------------|--------------------------------|
| `claude-code`     | `scripts/bd setup claude`      |
| `codex`           | `scripts/bd setup codex`       |
| others            | no agent-specific setup command |

Run the matching command for each installed agent. `scripts/bd setup claude` installs
Claude Code hooks/settings; run `scripts/bd --help` / `scripts/bd setup --help` to confirm
currently supported agents.

### Step 4: Write the Standard Memory Format into the root instruction file

Beads setup can write a generic section into `AGENTS.md`, but it does **not** include our required
memory format — so agents won't follow the design unless we add it. Resolve the root instruction
file (first existing of `AGENTS.md`, `.github/copilot-instructions.md`, `CLAUDE.md`; otherwise create
`AGENTS.md`). If it does not already contain the marker `<!-- BEGIN: local.beads-memory-format -->`,
append this managed block verbatim (idempotent — never add a second copy):

```markdown
<!-- BEGIN: local.beads-memory-format -->
## Beads Memory Format (scripts/bd remember)

Record every lesson with `scripts/bd remember` in this exact shape so memories are searchable with `scripts/bd memories <keyword>` and dedup-able by key:

    scripts/bd remember "[<area>] <generalized lesson — root cause + rule/fix>. Keywords: <kw1>, <kw2>, <kw3>." --key <area>-<subject>

- `[<area>]` — one of: build, test, config, deps, api, arch, tooling, env, data, perf, security, workflow (workflow = catch-all).
- Lesson — one or two self-contained sentences that read as a reusable rule (root cause + fix). Strip transient paths, ticket numbers, and debugging noise.
- `Keywords:` — 3–6 lowercase search terms (tool/command names, file/component names, error tokens) a future agent would type into `scripts/bd memories`.
- `--key <area>-<subject>` — stable kebab-case slug; re-recording the same key updates the memory in place instead of duplicating.

Before recording, search with `scripts/bd memories <keyword>`; if a close memory exists, reuse its `--key` to refine it rather than adding a near-duplicate. Full procedure: the `local.beads-workflow` skill (Operation 4).
<!-- END: local.beads-memory-format -->
```

### Step 5: Use the committed team sync configuration

NexTrade shares the **full Dolt database** — issues and memories — over the existing git
remote. The committed `.beads/config.yaml` and `.beads/metadata.json` are bootstrap seeds,
not a working database. `scripts/beads-home.sh bootstrap` copies them into the shared home
and clones the database from the configured `sync.remote`.

Verify the wrapper can see the configured remote, then publish:

```bash
scripts/bd dolt remote list
scripts/bd dolt push
git ls-remote origin 'refs/dolt/*'    # should list refs/dolt/data
```

Append this managed block to the root instruction file if the marker
`<!-- BEGIN: local.beads-git-sync -->` is not already present (idempotent — never add a second
copy):

```markdown
<!-- BEGIN: local.beads-git-sync -->
## Beads Team Sync (Dolt over the git remote)

The beads database (issues + memories) is shared over the git `origin` via a `refs/dolt/data` ref — **not** the `.beads/issues.jsonl` export, which is for viewers/interchange only.

- **Before any task**, run `scripts/bd dolt pull` to merge teammates' latest issues/memories into the one shared machine-local database. Surface any conflict/error instead of forcing it. Then run `scripts/bd prime` / `scripts/bd ready`.
- **After any task that changes the database** (created/claimed/updated/closed an issue, or recorded a memory), run `scripts/bd dolt push` before finishing. If it reports a conflict or error, surface it instead of forcing it.
- **On a fresh machine**, run `scripts/beads-home.sh bootstrap` to clone the shared Dolt database outside every working copy and write the machine-local pointer.
- The committed `.beads/config.yaml` and `.beads/metadata.json` are bootstrap seeds. The working database lives only in the shared home. Never hand-edit the database or export; change data only via `scripts/bd` commands.
- **Multiple agents may work on this repo at once from different git worktrees or clones.** Every copy uses the same wrapper-locked database; pull-before/push-after publishes that database through the remote.
<!-- END: local.beads-git-sync -->
```

**Do not use `.beads/issues.jsonl` for sync.** It is an export for viewers/interchange, not the
source of truth; the database syncs via `refs/dolt/data`, not tracked files.

### Step 6: Review the root instruction file for duplicate entries

Each `scripts/bd setup <agent>` call (Step 3) can append content to the root instruction
file. Running setup for more than one agent in the same project (e.g.
`scripts/bd setup claude` and `scripts/bd setup codex` back to back) can leave overlapping
or duplicate beads sections behind. After Steps 2–5 complete, re-read the resolved root instruction file (`AGENTS.md`,
`.github/copilot-instructions.md`, or `CLAUDE.md`) in full and check for:

- Multiple copies of the same bd-generated section from repeated
  `scripts/bd setup <agent>` calls.
- Near-duplicate prose that describes the same recall/track/remember workflow in different words.

Keep the `local.beads-memory-format` and `local.beads-git-sync` managed blocks intact by their
HTML-comment markers — they are already idempotent. For everything else, consolidate duplicates
into a single clean section and remove the redundant copies. If nothing is duplicated, no changes
are needed.

### Step 7: Verify

```bash
scripts/bd ready        # should run without error
scripts/bd prime        # should print workflow context
```

Confirm `scripts/beads-home.sh path` prints a home outside every git work tree.

---

## Operation 2: Recall (Before a Task)

The `local.beads` instruction handles the common recall path. Documented here for reference:

0. `scripts/bd dolt pull` — pull teammates' latest issues/memories into the shared database
   first. Surface any conflict/error to the user instead of forcing it.
1. `scripts/bd prime` — load workflow context and persistent memories.
2. `scripts/bd ready` — list unblocked, available issues.
3. `scripts/bd show <id>` — read the full detail of an issue before working it.
4. `scripts/bd update <id> --claim` — atomically claim it (sets assignee + in-progress) so parallel
   agents don't collide.

Apply recalled lessons before continuing.

---

## Operation 3: Track Issues

Use instead of markdown TODO lists.

```bash
scripts/bd create "Add rate limiting to the login endpoint" -p 1   # create (p0 = highest priority)
scripts/bd dep add <blocked-id> <blocker-id>                        # mark a dependency
scripts/bd show <id>                                                # inspect details + audit trail
scripts/bd update <id> --claim                                      # claim before working
scripts/bd close <id> --reason "Landed on main as <sha>"  # close: must cite landed work
```

- Break large work into an epic plus child issues; link children with `scripts/bd dep add`.
- Hash-based IDs (e.g. `bd-a1b2`) are collision-safe across parallel agents and branches.
- Run `scripts/bd --help` for the full command set (blockers, relations, message threads, etc.).
- The close guard refuses a close whose cited commit or PR is not on the remote default branch; an issue with nothing to land closes with `--reason "no-code-change: <at least 20 characters of why>"`. See `docs/architecture/beads-tracker-home.md`.

---

## Operation 4: Remember (After a Task)

Triggered when the user approves recording a lesson (see the `local.beads` instruction for
when to propose). Recording is `scripts/bd remember "<insight>"`; the work is in phrasing
the insight.

### Step 0: Run the Decision Gate (and consider skipping)

Before recording anything, run the Decision Gate below and decide whether the lesson is worth
saving at all. If it is a one-off or trivial, do not record it.

### Step 1: Generalization Rule

A memory should help future *similar* tasks. Decide whether the lesson stays generalized
(default) or keeps specific detail.

Keep specific details only when at least one is true:

1. The file/component is critical and broadly reused across the codebase.
2. The file/component has unique design constraints or non-obvious logic that must be preserved.
3. The issue cannot be accurately represented without exact implementation context.

When specifics are included, always pair them with a generic takeaway so the memory stays
reusable. You own this decision and must make it before recording.

#### Decision Gate (run before every `scripts/bd remember`)

1. Is this a recurring pattern, or a one-off quirk of this specific task? (One-offs: skip.)
2. Can this be reframed as a reusable pattern?
3. Is this tied to a critical/shared component?
4. Does the component have unique logic that justifies specificity?
5. If specific details are present, is there also a generic takeaway?
6. Would another similar feature benefit from this memory as written?

If the lesson cannot pass (2) or (6), generalize it further before recording — or skip it entirely.

### Step 2: Phrase the insight using the Standard Memory Format

Every memory MUST follow this shape so future agents can find it by keyword and so re-recording
updates in place instead of duplicating:

```bash
scripts/bd remember "[<area>] <generalized lesson — root cause + rule/fix>. Keywords: <kw1>, <kw2>, <kw3>." --key <area>-<subject>
```

**Fields:**

- **`[<area>]`** — a coarse category prefix from this controlled vocabulary (pick the closest;
  `workflow` is the catch-all):
  `build, test, config, deps, api, arch, tooling, env, data, perf, security, workflow`.
  It doubles as a search facet: `scripts/bd memories build`.
- **Lesson** — one or two self-contained sentences that read as a reusable rule (root cause +
  the fix/rule). Not an incident log. Strip transient paths, ticket numbers, and debugging noise.
- **`Keywords:`** — 3–6 concrete, lowercase search terms: tool/command names, file/component
  names, error tokens, domain nouns. Include the words a future agent would actually type into
  `scripts/bd memories <keyword>`, even if they already appear in the sentence. This is what makes
  full-text search reliable regardless of how the prose is phrased.
- **`--key <area>-<subject>`** — a stable, predictable kebab-case slug. Re-recording the same
  lesson with the same key **updates it in place** (natural dedup), and enables exact retrieval
  via `scripts/bd recall <area>-<subject>`.

**Examples:**

- Good: `scripts/bd remember "[build] This repo's Bash scripts must stay zero-dependency — parse YAML/JSON with awk/sed helpers in common.sh, never jq/yq/node. Keywords: bash, yaml, zero-dependency, common.sh, parsing." --key build-zero-dependency`
- Bad:  `scripts/bd remember "Fixed the parse bug in list.sh on the auth ticket by removing jq."` (no area, no keywords, no key; reads as a one-off incident)

### Step 3: Search first, then record

Before recording, check for an existing memory on the same topic so you refine rather than
duplicate:

```bash
scripts/bd memories <keyword>          # full-text search existing memories
scripts/bd recall <area>-<subject>     # fetch a specific memory by its key, if you expect one
```

If a close memory exists, re-run `scripts/bd remember` with **the same `--key`** to update it in place.
Otherwise record the new one:

```bash
scripts/bd remember "[<area>] <generalized lesson>. Keywords: <kw1>, <kw2>, <kw3>." --key <area>-<subject>
```

The insight is stored in the beads database and surfaced to future agents via
`scripts/bd prime`, and is searchable anytime with `scripts/bd memories <keyword>`.

---

## Operation 5: Maintain

User-invocable. Run when the user asks to review memories, prune stale lessons, or share the
tracker with teammates.

### Review, search, and prune stored memories

```bash
scripts/bd memories                    # list all persistent memories
scripts/bd memories <keyword>          # full-text search (e.g. scripts/bd memories yaml)
scripts/bd recall <area>-<subject>     # fetch a specific memory by its key
scripts/bd forget <area>-<subject>     # remove a stale or superseded memory by key
```

`scripts/bd prime` prints the accumulated memories injected into agent context;
`scripts/bd memories` is the searchable audit view. Use them to spot stale, contradictory,
or off-format lessons — when you find a memory that doesn't follow the Standard Memory
Format (Operation 4), re-record it with the same `--key` to fix it in place. Beads also
compacts old closed work via semantic summarization to conserve context — see
`scripts/bd --help` for compaction and memory-management subcommands.

### Team sync (Dolt database over the git remote)

The **Dolt database** is the source of truth, and it syncs over the project's existing git `origin`
via a custom `refs/dolt/data` ref — not via the `.beads/issues.jsonl` export. Configuration is done
once in Operation 1, Step 5; day-to-day it is just push/pull:

```bash
scripts/bd dolt push        # publish shared issues + memories to refs/dolt/data on origin
scripts/bd dolt pull        # fetch teammates' issues + memories (Operation 2 step 0)
```

**Onboarding a new machine:**

```bash
scripts/beads-home.sh bootstrap
```

Bootstrap clones the database outside every working copy and writes the machine-local
pointer. After bootstrap, `scripts/bd dolt push`/`pull` use the committed sync configuration.

- **Tracked in git:** `.beads/config.yaml` and `.beads/metadata.json` seed bootstrap. The working
  database lives only in the shared home and publishes through `refs/dolt/data`.
- **`.beads/issues.jsonl` is an export only** — for viewers (`bv`) and interchange, never the sync
  source of truth. Do not commit it as a sync mechanism, and never hand-edit it; change data through
  `scripts/bd` commands.
- **Advanced remotes:** `scripts/bd dolt remote add <name> <url>` accepts DoltHub/DoltLab, S3, GCS,
  or a local path instead of a git remote — see the beads `docs/DOLT.md`. Prefer the git-remote
  default (`git+ssh://…` / `git+https://…`) since it reuses the repo you already push to.
