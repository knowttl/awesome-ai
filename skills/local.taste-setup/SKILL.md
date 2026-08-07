---
name: taste-setup
description: >
  Install the Taste Developer opt-in setup prompt into this project's AGENTS.md.
  Use when the user wants agents to offer, on first interaction, to enable the
  Taste Developer skill that learns coding preferences and style over time, or
  asks to add the taste opt-in prompt to their agent instructions.
---

# Install the Taste Developer opt-in prompt into AGENTS.md

Append the bundled Taste Developer setup block into this project's root
`AGENTS.md` so future agents offer the opt-in once and honor the user's choice.

The block is bundled at
[`resources/taste-setup-block.md`](resources/taste-setup-block.md). Read it from
that path - do not reconstruct it from memory.

## Steps

1. **Locate the target.** Find the repository root and its `AGENTS.md`. If a
   `CLAUDE.md` (or other agent-instruction file) is a symlink to `AGENTS.md`,
   edit `AGENTS.md`; the symlink follows.
2. **Check idempotency.** If `AGENTS.md` already contains the taste block
   (look for the heading `Taste Developer`), stop and report that it is already
   installed. Do not duplicate it.
3. **Insert the block.**
   - If no `AGENTS.md` exists, create it with the block content as the file body.
   - If `AGENTS.md` exists, append the block as a new section at the end.
     Demote the block's top-level `#` heading to `##` so it nests as a section
     under the project's existing document, and shift its sub-headings down one
     level to match.
4. **Report** the exact file changed and the section added.

Do not commit unless the user asks. This skill only adds the opt-in prompt; the
`local.taste-developer` skill provides the actual preference-learning behavior.
