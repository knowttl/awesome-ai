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

After task completion, evaluate whether a memory should be proposed. Propose exactly one prompt when at least one is true:

- A non-obvious error required debugging or a workaround.
- A project convention was discovered that is not documented elsewhere.
- An environment-specific quirk changed expected behavior.
- An architectural decision was made with durable rationale.

**Default to a generalized lesson.** Frame the summary as a reusable pattern, not a one-off
incident. Strip transient debugging context, temporary paths, and one-time ticket details
unless they are essential to understanding the lesson.

Use this exact prompt:

> "I learned [generalized lesson]. Want me to save this to `.ai/memory/`?"

Rules:

- Do not propose memory writes mid-task.
- If approved, invoke `local.agent-memory-workflow` and follow its write/update procedure.
- If declined, do not write files.

## Generalization-First Rule

Memory exists to help future, *similar* tasks — not to log this exact one. Before proposing
or writing, decide whether the lesson should be generalized or kept specific. **You own this
decision and must make it before saving.**

- **Default:** store a generalized, pattern-level entry.
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

1. Can this be reframed as a reusable pattern?
2. Is this tied to a critical/shared component?
3. Does the component have unique logic that justifies specificity?
4. If specific details are present, is there also a generic takeaway?
5. Would another similar feature benefit from this entry as written?

If the entry cannot pass (1) or (5), generalize it further before saving.

## Reinforcement Rule

When a memory entry prevented a mistake or repeated failure in the current task, mention that briefly in the task summary.

## Vault Health Trigger

If `.ai/memory/index.md` grows beyond about 30 entries, suggest a memory lint/audit.
