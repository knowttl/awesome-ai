---
name: dox-framework
description: >
  Install the DOX framework into a repository and build its AGENTS.md hierarchy.
  Use whenever the user wants to add, install, initialize, or set up DOX, adopt
  the DOX AGENTS.md contract, "initialize the DOX tree," or establish a
  hierarchical AGENTS.md structure where agents walk root-to-target docs before
  editing. In a new repo it installs the DOX rail into the root AGENTS.md; in an
  existing project it also reviews the full tree and scaffolds child AGENTS.md
  files with Child DOX Index entries for each durable boundary.
---

# DOX framework

Install [DOX](https://github.com/agent0ai/dox) into the current repository. DOX
is a hierarchy of `AGENTS.md` files that act as binding work contracts: a root
AGENTS.md holds project-wide rules and a Child DOX Index; child AGENTS.md files
own domain-specific rules for durable subfolders. Before any edit, an agent
walks the docs from the repo root down to the path it will touch; after a
meaningful change, it updates the affected docs.

This skill does two things:

1. **Install the rail** - put the canonical DOX framework instructions into the
   root `AGENTS.md` (in any repo), preserving whatever is already there.
2. **Build the tree** - in an existing project, review the whole repository and
   scaffold child `AGENTS.md` files plus the Child DOX Index for each durable
   boundary.

The canonical rail text is bundled with this skill at
[`resources/dox-rail.md`](resources/dox-rail.md). Read it from that path - do
not fetch it from the network or reconstruct it from memory.

## Workflow

Run these steps in order.

### 1. Locate the repo root and existing instruction files

Confirm the repository root (where the top-level `AGENTS.md` belongs). Then read
any instruction files that already exist, because their content must be
preserved when the rail is installed:

- `AGENTS.md` - the DOX rail target; may already hold project facts
- `CLAUDE.md`, `.cursorrules`, `.cursor/rules/`,
  `.github/copilot-instructions.md` - may hold rules to fold in or reference
- `opencode.json` - may reference instruction files via its `instructions` field

Note whether a root `AGENTS.md` already exists. This decides install vs. merge
in step 2, but the tree-building steps (3-5) run either way in an existing
project.

### 2. Install or merge the rail into the root AGENTS.md

Read the bundled rail from `resources/dox-rail.md`. It contains the framework
sections (Core Contract, Read Before Editing, Update After Editing, Hierarchy,
Child Doc Shape, Style, Closeout, User Preferences) and a Child DOX Index
placeholder.

**No root `AGENTS.md` exists** - write the rail verbatim as the new root
`AGENTS.md`. You will fill in the Child DOX Index in step 5.

**A root `AGENTS.md` already exists** - preserve its content and wrap it with the
rail. Never discard captured project facts. Produce a merged root with this
shape:

```
# DOX framework
<... the full rail from resources/dox-rail.md, through "User Preferences" ...>

# <existing project title / summary>
<existing project-wide instructions, agent rules, file map, conventions,
 commands - folded in below the rail, deduplicated and left intact>

## Child DOX Index
<generated in step 5>
```

Rules for the merge:

- Keep every rail section from `resources/dox-rail.md` **verbatim and first** -
  the root is the DOX rail and no existing text may weaken it.
- Move the existing project's durable instructions (agent rules, conventions,
  commands, file map) below the rail as project-specific content. Do not rewrite
  their meaning; only remove exact duplicates of what the rail already states.
- If the existing file has a self-updating "Agent Rules" section, keep it intact
  below the rail.
- The single Child DOX Index at the bottom is the top-level index; it is
  populated in step 5.

If the user only asked to install the rail (e.g. a brand-new or trivial repo, or
they explicitly said "root only"), stop after this step and run the closeout.

### 3. Review the project and identify durable boundaries

Survey the repository to find folders that qualify as durable boundaries - the
ones DOX says deserve their own child `AGENTS.md`. A folder qualifies when it has
its own purpose, rules, responsibilities, workflow, materials, or quality
standards. Strong signals:

- Workspace members / packages (`packages/*`, `apps/*`, `services/*`, monorepo
  members declared in workspace config or lockfiles)
- App or service entrypoints with their own build, test, or deploy story
- Modules with a distinct domain, owner, or contract (e.g. `api/`, `web/`,
  `infra/`, `docs/`, `tooling/`, `migrations/`)
- Directories with their own config, dependencies, or CI that differ from the
  root

Do **not** create child docs for shallow or incidental folders (build output,
`node_modules`, generated code, trivial single-file directories, or folders with
no rules of their own). When in doubt, leave it to the root - DOX prefers fewer,
meaningful docs over scattering files. The tree can grow later as edits touch
new areas.

For each candidate boundary, gather what its child doc would actually say:
purpose, what it owns, local contracts, current work guidance (only if real
standards exist), and verification (only if a real check exists). Leave Work
Guidance and Verification empty when nothing concrete exists yet - do not invent
them.

### 4. Propose the tree and confirm

Present the proposed hierarchy to the user before writing any child files. Show:

- Each proposed child `AGENTS.md` path
- One line on why that folder is a durable boundary and what its doc will cover
- Any candidate you deliberately left out and why

Ask the user to confirm, adjust, or drop entries. Do not create child docs the
user did not approve. If the repo has no real boundaries, say so and keep the
tree root-only.

### 5. Write the child docs and every Child DOX Index

For each approved boundary, create its `AGENTS.md` using the DOX child section
order from the rail: **Purpose, Ownership, Local Contracts, Work Guidance,
Verification, Child DOX Index**. Keep it concrete and local - parent docs hold
broad rules, child docs hold specific details. Leave Work Guidance and
Verification empty when no real standard or check exists yet.

Then wire up the indexes:

- Fill the **root** Child DOX Index with each direct child boundary: its path,
  what it covers, and what stays owned by the root. List root-owned top-level
  files and folders explicitly.
- If a child boundary itself contains deeper boundaries, give that child its own
  Child DOX Index pointing at its children, and continue recursively.
- Every parent must explain what its direct children cover and what the parent
  still owns.

Create parent directories as needed and write each file. Nested boundaries: each
level's index only lists its **direct** children, not the whole tree.

### 6. Closeout

Run the DOX closeout:

1. Re-check that every AGENTS.md path you created or edited is reachable from the
   root by following Child DOX Index entries.
2. Confirm each parent index lists its direct children, and no index is stale.
3. Remove any duplicated or contradictory text introduced during the merge.
4. Report to the user, specifically: the root file (created or merged), each
   child `AGENTS.md` created, and any boundary intentionally left without a doc
   and why.

Do not commit unless the user asks.

## Notes

- **This skill installs a contract, not facts.** If the user instead wants to
  capture high-signal, repo-specific commands and conventions into a single flat
  instruction file, that is the `agentsmd-init` skill's job. DOX can wrap the
  output of that skill - the two compose: `agentsmd-init` writes the facts, DOX
  installs the rail around them and builds the hierarchy.
- **Idempotent.** Re-running on a repo that already has the rail should detect it
  (the `# DOX framework` heading and Core Contract), skip re-installing, and only
  refresh boundaries and indexes that changed.
- **The rail is authoritative.** When merging, the bundled `resources/dox-rail.md`
  text wins over any conflicting existing wording of the same rules.
