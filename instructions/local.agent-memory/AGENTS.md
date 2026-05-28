# Agent Memory

This project uses a persistent memory vault at `.ai/memory/`.

## Before Starting Any Task

1. Read `.ai/memory/index.md` to scan for entries relevant to your current task.
2. If any entries look relevant based on title/tags, read those files in full.
3. Apply any applicable lessons to avoid known pitfalls.

If `.ai/memory/` does not exist yet, skip this step.

## After Completing a Task

If during this task you:
- Hit an error that required non-obvious debugging
- Discovered a project convention not documented elsewhere
- Found an environment-specific quirk or workaround
- Made an architectural decision with important rationale

Then propose a memory entry to the user:
> "I learned [summary]. Want me to save this to `.ai/memory/`?"

Only propose at task completion. Do not interrupt mid-task.
If the user approves, invoke the `agent-memory-workflow` skill for the detailed write procedure.

## Vault Health

If `.ai/memory/index.md` exceeds ~30 entries, suggest the user run a lint/audit to prune stale entries.
