---
name: agent-memory-workflow
description: "Use when writing, searching, or maintaining entries in the .ai/memory/ vault."
---

# Agent Memory Workflow

Detailed procedures for writing, searching, and maintaining the project's `.ai/memory/` vault.

Goal: capture high-signal lessons — gotchas, edge cases, and environment quirks — that prevent repeated mistakes and wasted cycles. Not every task produces a save-worthy lesson.

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
- **Default to generalized, pattern-level entries.** Capture the reusable lesson, not the one-off incident.
- **Keep specifics only when justified** (see the Generalization Rule below), and always pair them with a generic takeaway.
- Exclude transient debugging context, temporary paths, and one-time ticket details unless essential.

## Generalization Rule

A memory entry should help future *similar* tasks. Before writing, decide whether the lesson
stays generalized (default) or keeps specific detail.

Store specific details only when at least one is true:

1. The file/component is critical and broadly reused across the codebase.
2. The file/component has unique design constraints or non-obvious logic that must be preserved.
3. The issue cannot be accurately represented without exact implementation context.

When specifics are included, always pair them with a generic takeaway so the entry stays reusable.
The agent owns this decision and must make it before saving.

### Decision Gate (run before every write)

Run this checklist before writing or updating any entry:

1. Is this a recurring pattern, or a one-off quirk of this specific task? (One-offs: skip.)
2. Can this be reframed as a reusable pattern?
3. Is this tied to a critical/shared component?
4. Does the component have unique logic that justifies specificity?
5. If specific details are present, is there also a generic takeaway?
6. Would another similar feature benefit from this entry as written?

If the entry cannot pass (2) or (6), generalize it further before saving — or skip it entirely.
Record specifics only when (3) or (4) is true; otherwise leave the `Specific Context` section empty.

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

### Step 0: Run the Decision Gate (and consider skipping)

Before touching any file, run the Decision Gate (see the Generalization Rule above) and decide
whether this entry is worth saving at all. If it's a one-off or trivial, do not write it.
Only proceed if it passes the gate.

- Whether the lesson is stored generalized (default) or with justified specifics.
- Whether to update an existing entry or create a new one.

Scan `index.md` for related entries.

- If an existing entry covers the same root-cause class, update that entry file and keep the same filename.
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

Populate template sections following the Generalization Rule:

- Write the **Title** as a short, reusable lesson statement (not "Bug in foo.ts on 2026-01-02").
- Write **Pattern** and **Reusable Guidance** so they apply to any similar case.
- Fill **Specific Context** only when the Decision Gate justifies it; otherwise leave it empty or omit it.
- If specifics are present, ensure **Reusable Guidance** still reads as a standalone generic takeaway.
- Set **Confidence** (High/Medium/Low) based on how broadly the lesson has been validated.

Then:

- New entry: write `.ai/memory/<filename>.md`.
- Update entry: modify existing file in place, preserving useful prior context.

### Step 5: Update Index

Maintain one row per file in `.ai/memory/index.md`:

```
| <filename>.md | <category> | <tag1, tag2, tag3> | <one-line summary max ~80 chars> |
```

- Write the summary as a reusable lesson statement, not a one-off incident description.
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
| Overly-specific entries | Entries tied to one-off detail with no reusable guidance, where specificity is not justified by a critical/shared/unique component |

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
