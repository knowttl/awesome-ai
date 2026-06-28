# Agent Memory

Use the project memory vault at `.ai/memory/` to prevent repeat failures.

## Mandatory Pre-Task Check

Before starting implementation or debugging on any task:

1. If `.ai/memory/index.md` exists, read it.
2. Select entries relevant to the current task by matching title/tags to the task topic, tools, and error terms.
3. Read each selected entry fully before proceeding.
4. Apply relevant lessons during the task.

If `.ai/memory/index.md` does not exist, continue normally.

## Mandatory Post-Task Writeback Proposal

After task completion, evaluate whether a memory should be proposed. **Default: do not propose.**
Only propose when you encountered a high-signal lesson that would genuinely prevent a future
repeat failure or wasted cycle.

Propose exactly one prompt when at least one is true:

- A command or operation consistently fails in this project for a non-obvious reason (e.g., environment quirk, tool version mismatch, missing config) — save the root cause and the fix so future agents skip the trial-and-error.
- A project gotcha or subtle edge case was discovered that is easy to miss or misunderstand on re-reading.
- An environment-specific quirk (tool version, OS behavior, config requirement) caused issues and the fix is non-trivial or non-obvious.
- An architectural decision was made with durable rationale that affects future work.

**Do NOT propose memory for:**
- One-off typos or trivial fixes that are obvious in hindsight.
- Normal setup steps that only apply to this exact task.
- Anything that could be easily rediscovered by re-reading the error message.
- Details that won't matter to a future agent working on a different task.

**Default to a generalized lesson.** Frame the summary as a reusable pattern, not a one-off
incident. Strip transient debugging context, temporary paths, and one-time ticket details
unless they are essential to understanding the lesson.

Use this exact prompt:

> "I learned [generalized lesson]. Want me to save this to `.ai/memory/`?"

Rules:

- Do not propose memory writes mid-task.
- If approved, invoke `local.agent-memory-workflow` and follow its write/update procedure.
- If declined, do not write files.

## High-Signal Only + Generalization-First Rule

**Most tasks should not produce a memory entry.** Memory exists to capture durable gotchas,
edge cases, and environment quirks that would trip up a future agent — not to log every error
or discovery. If the lesson is obvious, transient, or one-off, skip it.

Before proposing or writing, decide whether the lesson is worth saving at all, and if so
whether it should be generalized or kept specific. **You own this decision and must make it
before saving.**

- **Default:** skip, or store a generalized, pattern-level entry.
- **Store specific details only when at least one is true:**
  1. The file/component is critical and broadly reused across the codebase.
  2. The file/component has unique design constraints or non-obvious logic that must be preserved.
  3. The issue cannot be accurately represented without exact implementation context.
- **If specifics are included, always pair them with a generic takeaway** so the entry stays reusable.
- **Avoid noise:** exclude transient debugging context, temporary paths, or one-time ticket
  details unless essential.

## Decision Gate (run before every save)

Run this checklist before writing any memory entry. The detailed write procedure lives in
`local.agent-memory-workflow`, but the decision to generalize vs. keep specific happens here first.

1. Is this a recurring pattern, or a one-off quirk of this specific task? (One-offs: skip.)
2. Can this be reframed as a reusable pattern?
3. Is this tied to a critical/shared component?
4. Does the component have unique logic that justifies specificity?
5. If specific details are present, is there also a generic takeaway?
6. Would another similar feature benefit from this entry as written?

If the entry cannot pass (2) or (6), generalize it further before saving — or skip it entirely.

## Reinforcement Rule

When a memory entry prevented a mistake or repeated failure in the current task, mention that briefly in the task summary.

## Vault Health Trigger

If `.ai/memory/index.md` grows beyond about 30 entries, suggest a memory lint/audit.
