---
name: agent-memory-workflow
description: "Use when writing, searching, or maintaining entries in the .ai/memory/ vault."
---

# Agent Memory Workflow

Detailed procedures for writing, searching, and maintaining the project's `.ai/memory/` vault.

Goal: capture lessons that prevent repeated mistakes.

## When to Use

- User approved a proposed memory entry (from the brain stem instruction)
- User asks to search or query memories explicitly
- User asks to lint, audit, or clean up the memory vault

Do NOT use this skill for the routine pre-task memory check — that is handled inline by the brain stem instruction (`local.agent-memory`).

## Deterministic Rules

- Keep one index at `.ai/memory/index.md`.
- Keep exactly one table row per entry file.
- On similar incidents, prefer updating an existing entry over creating a near-duplicate.
- Keep summaries concise and actionable.

## Operations

1. **Pre-check** — Read existing memory before task work (fallback path)
2. **Bootstrap** — Create the vault on first use
3. **Write/Update** — Add or update a memory entry
4. **Search** — Find relevant memories for the current task
5. **Lint** — Audit and maintain vault health

---

## Operation 1: Pre-check (Fallback)

Use only when the pre-task check from `local.agent-memory` was skipped or unavailable.

1. If `.ai/memory/index.md` exists, read it.
2. Select relevant entries by matching task keywords.
3. Read selected entries fully.
4. Apply lessons before continuing.

If `.ai/memory/index.md` does not exist, continue.

## Operation 2: Bootstrap (First Use)

If `.ai/memory/` does not exist, create it before writing the first entry.

1. Create the directory:
   ```bash
   mkdir -p .ai/memory
   ```

2. Create `.ai/memory/index.md`:
   ```markdown
   # Memory Index

   > Auto-maintained by the agent. Do not edit manually.

   | File | Category | Tags | Summary |
   |------|----------|------|---------|
   ```

3. Proceed to Operation 3 to write the first entry.

---

## Operation 3: Write or Update a Memory Entry

Triggered when the user approves a proposed memory entry.

### Step 0: Decide Update vs New Entry

Before creating a new file, scan `index.md` for related entries.

- If an existing entry covers the same root cause, update that entry file and keep the same filename.
- If no entry covers it, create a new file.

### Step 1: Determine Category

Choose one:
- `error-fix` — An error that required non-obvious debugging
- `convention` — A project convention not documented elsewhere
- `environment` — An environment-specific quirk or workaround
- `decision` — An architectural decision with important rationale

### Step 2: Generate Filename (new entries only)

- Use kebab-case
- Be descriptive (e.g., `docker-compose-port-conflict.md`, `use-strict-typescript.md`)
- Max ~50 characters
- No date prefix (date goes in the file's metadata)

### Step 3: Apply Template

Read the appropriate template from the `templates/` directory adjacent to this `SKILL.md` file:
- `templates/error-fix.md`
- `templates/convention.md`
- `templates/environment.md`
- `templates/decision.md`

### Step 4: Fill and Write

Populate all template sections with specific, actionable content.

- New entry: write `.ai/memory/<filename>.md`.
- Update entry: modify existing file in place, preserving useful prior context.

### Step 5: Update Index

Maintain one row per file in `.ai/memory/index.md`:

```
| <filename>.md | <category> | <tag1, tag2, tag3> | <one-line summary max ~80 chars> |
```

- New entry: append one row.
- Updated entry: update existing row (do not append a duplicate row).

### Step 6: Stage Files

```bash
git add .ai/memory/<filename>.md .ai/memory/index.md
```

Stage only — do not commit. The user will commit with their broader task changes.

---

## Operation 4: Search Memory

The brain stem instruction handles the common search path (read index → match keywords → read files). This operation documents the fallback for large vaults only:

```bash
grep -ril "<keyword>" .ai/memory/
```

Use when the index scan alone is insufficient. Extract 2-3 keywords from: technology names, error fragments, tool names, concepts. Read matched files in full, apply lessons silently.

---

## Operation 5: Lint / Maintain

User-invocable. Run when the user explicitly requests it (e.g., "lint my memory vault", "audit .ai/memory", "clean up memories").

### Step 1: Inventory

Read every `.md` file in `.ai/memory/` (excluding `index.md`). Read `index.md` separately.

### Step 2: Check for Issues

| Issue | Detection |
|-------|-----------|
| Stale entries | References tools/dependencies no longer in `package.json`, `Cargo.toml`, etc. |
| Duplicates | Multiple entries covering the same root issue |
| Contradictions | Entries giving conflicting advice |
| Orphan files | `.md` files in the vault not listed in `index.md` |
| Ghost entries | Index rows pointing to files that don't exist |

### Step 3: Propose Changes

Present findings to the user. **Never delete without approval.** Format:

> **Memory Lint Results:**
> - Remove `old-webpack-loader-fix.md`? — project no longer uses webpack
> - Merge `port-conflict-docker.md` and `docker-port-5432.md`? — same topic
> - `index.md` has 2 ghost entries — rebuild index?

### Step 4: Execute Approved Changes

For each approved change:
- Delete files: `rm .ai/memory/<file>.md`
- Merge files: combine content into one, delete the other
- Rebuild index: regenerate table from actual files in the directory

### Step 5: Report

Report: total entries, counts by category, issues found/resolved, oldest/newest entry dates.
