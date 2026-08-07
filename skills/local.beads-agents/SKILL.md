---
name: beads-agents
description: >
  Install the beads (bd) issue-tracking and agent-memory instructions into this
  project's AGENTS.md. Use when the user wants agents to recall context with
  `bd prime` before tasks and record durable lessons with `bd remember` after
  them, or asks to add beads/bd workflow rules to their agent instructions.
---

# Install beads instructions into AGENTS.md

Append the bundled beads instruction block into this project's root `AGENTS.md`
so future agents follow the beads (`bd`) recall-before / remember-after workflow.

The block is bundled at
[`resources/beads-agents-block.md`](resources/beads-agents-block.md). Read it
from that path - do not reconstruct it from memory.

## Steps

1. **Locate the target.** Find the repository root and its `AGENTS.md`. If a
   `CLAUDE.md` (or other agent-instruction file) is a symlink to `AGENTS.md`,
   edit `AGENTS.md`; the symlink follows.
2. **Check idempotency.** If `AGENTS.md` already contains the beads block
   (look for the heading `Beads Issue Tracking & Memory`), stop and report that
   it is already installed. Do not duplicate it.
3. **Insert the block.**
   - If no `AGENTS.md` exists, create it with the block content as the file body.
   - If `AGENTS.md` exists, append the block as a new section at the end.
     Demote the block's top-level `#` heading to `##` so it nests as a section
     under the project's existing document, and shift its sub-headings down one
     level to match.
4. **Report** the exact file changed and the section added.

Do not commit unless the user asks. This skill only adds the instructions; run
the `local.beads-workflow` skill to actually initialize `bd` in the project.
