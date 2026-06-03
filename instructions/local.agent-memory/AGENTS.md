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

Use this exact prompt:

> "I learned [summary]. Want me to save this to `.ai/memory/`?"

Rules:

- Do not propose memory writes mid-task.
- If approved, invoke `local.agent-memory-workflow` and follow its write/update procedure.
- If declined, do not write files.

## Reinforcement Rule

When a memory entry prevented a mistake or repeated failure in the current task, mention that briefly in the task summary.

## Vault Health Trigger

If `.ai/memory/index.md` grows beyond about 30 entries, suggest a memory lint/audit.
