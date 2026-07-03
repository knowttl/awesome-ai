# Beads Issue Tracking & Memory

This project uses **beads** (`bd`) for issue tracking and persistent agent memory.
`bd` is a dependency-aware issue graph that also stores durable lessons so agents
stop repeating mistakes. Source: <https://github.com/gastownhall/beads>.

**Do not** use markdown TODO lists, `.ai/memory/`, or `MEMORY.md` files for tracking
work or lessons — beads is the source of truth. If `bd` is not yet initialized in
this project, invoke the `local.beads-workflow` skill to set it up.

## Mandatory Pre-Task Recall

Before starting implementation or debugging on any task:

1. Run `bd prime` to load workflow context and prior lessons (persistent memories).
2. Run `bd ready` to see unblocked, available work.
3. Read the details of any issue you will work on: `bd show <id>`.
4. Claim it before starting so parallel agents don't collide: `bd update <id> --claim`.
5. Apply the recalled lessons during the task.

If `bd` is unavailable or the project has no beads database yet, continue normally
and note that beads setup is pending.

## Track Work as Issues

- Capture features, bugs, and follow-ups as beads instead of inline TODO lists:
  `bd create "Title" -p <priority>` (priority `0` = highest).
- Record dependencies so blocked work is hidden until it's ready:
  `bd dep add <blocked-id> <blocker-id>`.
- Inspect with `bd show <id>`; close finished work with `bd close <id>`.

## Mandatory Post-Task Learning (bd remember)

After task completion, evaluate whether a memory should be recorded. **Default: do not record.**
Only record when you encountered a high-signal lesson that would genuinely prevent a future
repeat failure or wasted cycle.

Propose recording exactly one lesson when at least one is true:

- A command or operation consistently fails in this project for a non-obvious reason (e.g., environment quirk, tool version mismatch, missing config) — record the root cause and fix so future agents skip the trial-and-error.
- A project gotcha or subtle edge case was discovered that is easy to miss or misunderstand on re-reading.
- An environment-specific quirk (tool version, OS behavior, config requirement) caused issues and the fix is non-trivial or non-obvious.
- An architectural decision was made with durable rationale that affects future work.

**Do NOT record memory for:**

- One-off typos or trivial fixes that are obvious in hindsight.
- Normal setup steps that only apply to this exact task.
- Anything that could be easily rediscovered by re-reading the error message.
- Details that won't matter to a future agent working on a different task.

**Default to a generalized lesson.** Frame it as a reusable pattern, not a one-off incident.
Strip transient debugging context, temporary paths, and one-time ticket details unless they
are essential to understanding the lesson.

Prompt the user first, using this exact wording:

> "I learned [generalized lesson]. Want me to save it with `bd remember`?"

Rules:

- Do not record mid-task — only after completion.
- If approved, run `bd remember "[generalized lesson]"`. For the phrasing and generalization
  procedure, follow the `local.beads-workflow` skill.
- If declined, do not record anything.

## High-Signal Only + Generalization-First Rule

**Most tasks should not produce a memory.** `bd remember` captures durable gotchas, edge cases,
and environment quirks that would trip up a future agent — not every error or discovery. If the
lesson is obvious, transient, or one-off, skip it.

Before proposing or recording, decide whether the lesson is worth saving at all, and if so
whether it should be generalized or kept specific. **You own this decision and must make it
before saving.**

- **Default:** skip, or record a generalized, pattern-level lesson.
- **Keep specific details only when at least one is true:**
  1. The file/component is critical and broadly reused across the codebase.
  2. The file/component has unique design constraints or non-obvious logic that must be preserved.
  3. The issue cannot be accurately represented without exact implementation context.
- **If specifics are included, always pair them with a generic takeaway** so the lesson stays reusable.
- **Avoid noise:** exclude transient debugging context, temporary paths, or one-time ticket
  details unless essential.

## Reinforcement Rule

When a recalled memory (from `bd prime`) prevented a mistake or repeated failure in the current
task, mention that briefly in the task summary.
