---
name: opensrc-agents
description: >
  Install optional `opensrc` dependency-source guidance into this project's
  AGENTS.md. Use when the user wants agents to fetch and read npm, PyPI,
  crates.io, or GitHub source for deeper implementation context, or asks to add
  opensrc usage rules to their agent instructions.
---

# Install opensrc guidance into AGENTS.md

Append the bundled opensrc instruction block into this project's root
`AGENTS.md` so future agents know to use `opensrc` for dependency internals when
docs and types are not enough.

The block is bundled at
[`resources/opensrc-agents-block.md`](resources/opensrc-agents-block.md). Read it
from that path - do not reconstruct it from memory.

## Steps

1. **Locate the target.** Find the repository root and its `AGENTS.md`. If a
   `CLAUDE.md` (or other agent-instruction file) is a symlink to `AGENTS.md`,
   edit `AGENTS.md`; the symlink follows.
2. **Check idempotency.** If `AGENTS.md` already contains the opensrc block
   (look for the heading `OpenSrc Source Context`), stop and report that it is
   already installed. Do not duplicate it.
3. **Insert the block.**
   - If no `AGENTS.md` exists, create it with the block content as the file body.
   - If `AGENTS.md` exists, append the block as a new section at the end.
     Demote the block's top-level `#` heading to `##` so it nests as a section
     under the project's existing document, and shift its sub-headings down one
     level to match.
4. **Report** the exact file changed and the section added.

Do not commit unless the user asks.
