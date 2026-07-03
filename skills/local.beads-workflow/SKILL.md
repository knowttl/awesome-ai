---
name: beads-workflow
description: "Use when setting up beads (bd), recalling context with bd prime, tracking issues, or recording lessons with bd remember."
---

# Beads Workflow

Detailed procedures for setting up and using **beads** (`bd`) — a dependency-aware
issue tracker that doubles as persistent agent memory. Source:
<https://github.com/gastownhall/beads>.

`bd` is a system-wide CLI (installed via Homebrew / npm / script), **not** file-copied
content. This skill orchestrates installing it, initializing it in a project, and using
its recall (`bd prime`) and memory (`bd remember`) features. The routine pre-task recall
and post-task learning discipline lives in the `local.beads` instruction; this skill is
the on-demand reference and the setup path.

Goal: track features/bugs/tasks as a graph instead of markdown TODO lists, and capture
high-signal lessons — gotchas, edge cases, and environment quirks — so future agents stop
repeating mistakes. Not every task produces a save-worthy lesson.

## When to Use

- Setting up beads in a project for the first time (install `bd`, `bd init`, agent hooks).
- The user approved recording a lesson (from the `local.beads` instruction).
- The user asks to create, inspect, or close tracked issues.
- The user asks to review or clean up stored memories.

Do NOT use this skill for the routine pre-task recall — that is handled inline by the
`local.beads` instruction (`bd prime` / `bd ready`).

## Deterministic Rules

- `bd` (the beads database under `.beads/`) is the single source of truth. Never create
  `.ai/memory/`, `MEMORY.md`, or markdown TODO lists alongside it.
- Recall with `bd prime` before work; record with `bd remember` only after work.
- On a similar lesson, prefer refining an existing memory over recording a near-duplicate.
- **Default to generalized, pattern-level memories.** Capture the reusable lesson, not the
  one-off incident. Keep specifics only when justified (see the Generalization Rule).
- Keep memory strings concise and actionable. Strip transient paths and one-time details.

## Operations

1. **Setup** — Install `bd` and initialize beads in the project
2. **Recall** — Load context and available work before a task
3. **Track** — Create, link, claim, and close issues
4. **Remember** — Record a durable lesson after a task
5. **Maintain** — Review memories and sync the database with teammates

---

## Operation 1: Setup (First Use)

Run when `bd` is missing or the project has no `.beads/` database.

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

### Step 2: Initialize beads in the project

```bash
bd init
```

`bd init` creates the `.beads/` directory (an embedded Dolt database), updates `AGENTS.md`
with the beads workflow, wires a Dolt `origin` remote when the git repo has one, and
installs agent integrations. Pass `--skip-agents` if the caller only wants the database.

### Step 3: Wire agent-specific hooks

Beads ships dedicated setup for some agents; map the registry's agent flags:

| Agent flag        | Command             |
|-------------------|---------------------|
| `claude-code`     | `bd setup claude`   |
| `codex`           | `bd setup codex`    |
| others            | rely on `bd init` writing `AGENTS.md` |

Run the matching command for each installed agent. `bd setup claude` installs Claude Code
hooks/settings; run `bd --help` / `bd setup --help` to confirm currently supported agents.

### Step 4: Verify

```bash
bd ready        # should run without error (empty list on a fresh project is fine)
bd prime        # should print workflow context
```

Confirm `.beads/` exists and is tracked appropriately (see Operation 5 for team sync).

---

## Operation 2: Recall (Before a Task)

The `local.beads` instruction handles the common recall path. Documented here for reference:

1. `bd prime` — load workflow context and persistent memories.
2. `bd ready` — list unblocked, available issues.
3. `bd show <id>` — read the full detail of an issue before working it.
4. `bd update <id> --claim` — atomically claim it (sets assignee + in-progress) so parallel
   agents don't collide.

Apply recalled lessons before continuing.

---

## Operation 3: Track Issues

Use instead of markdown TODO lists.

```bash
bd create "Add rate limiting to the login endpoint" -p 1   # create (p0 = highest priority)
bd dep add <blocked-id> <blocker-id>                        # mark a dependency
bd show <id>                                                # inspect details + audit trail
bd update <id> --claim                                      # claim before working
bd close <id>                                               # close when done
```

- Break large work into an epic plus child issues; link children with `bd dep add`.
- Hash-based IDs (e.g. `bd-a1b2`) are collision-safe across parallel agents and branches.
- Run `bd --help` for the full command set (blockers, relations, message threads, etc.).

---

## Operation 4: Remember (After a Task)

Triggered when the user approves recording a lesson (see the `local.beads` instruction for
when to propose). Recording is `bd remember "<insight>"`; the work is in phrasing the insight.

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

#### Decision Gate (run before every `bd remember`)

1. Is this a recurring pattern, or a one-off quirk of this specific task? (One-offs: skip.)
2. Can this be reframed as a reusable pattern?
3. Is this tied to a critical/shared component?
4. Does the component have unique logic that justifies specificity?
5. If specific details are present, is there also a generic takeaway?
6. Would another similar feature benefit from this memory as written?

If the lesson cannot pass (2) or (6), generalize it further before recording — or skip it entirely.

### Step 2: Phrase the insight

Write one self-contained sentence (or two) that reads as a reusable rule, not an incident log:

- Good: `bd remember "This repo's Bash scripts must stay zero-dependency — no jq/yq/node; parse YAML/JSON with awk/sed helpers in common.sh."`
- Bad:  `bd remember "Fixed the parse bug in list.sh on the auth ticket by removing jq."`

Include the root cause and the fix or rule; strip transient paths, ticket numbers, and
temporary debugging context unless a specific detail is essential to the lesson.

### Step 3: Record it

```bash
bd remember "<generalized lesson>"
```

The insight is stored in the beads database and surfaced to future agents via `bd prime`,
so it does not need to be re-read from a file. On a closely related existing memory, refine
that lesson rather than recording a near-duplicate.

---

## Operation 5: Maintain

User-invocable. Run when the user asks to review memories, prune stale lessons, or share the
tracker with teammates.

### Review stored memories

`bd prime` prints the accumulated memories that are injected into agent context. Use it to
audit what has been recorded and spot stale or contradictory lessons. Beads also compacts old
closed work via semantic summarization to conserve context — see `bd --help` for compaction
and memory-management subcommands.

### Team sync

The Dolt database under `.beads/` — not the exported `.beads/issues.jsonl` — is the source of
truth. When the git repo has an `origin` remote, share issues and memories across machines with:

```bash
bd dolt push        # publish local issues/memories
bd dolt pull        # fetch teammates' issues/memories
```

`.beads/issues.jsonl` is a human-readable export for diffing/interchange, not a full backup.
Follow the guidance `bd init` writes into `AGENTS.md` for what to commit vs. push.
