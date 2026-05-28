# Agent Memory System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a two-tier agent memory system (instruction + skill) to the skills-registry that teaches AI agents to persist and retrieve lessons learned across tasks.

**Architecture:** Thin instruction package (brain stem content, intended to be enabled/loaded by the target agent) triggers memory check/write behavior. Fat skill (on-demand reference) provides templates, operations, and procedures. Both are registry items installed via `bin/skill install`; this plan does not change installer semantics or merge content into root context files.

**Tech Stack:** Markdown content files, YAML manifests, generated `registry.json`, README inventory update. No CLI behavior changes.

**Spec:** `docs/superpowers/specs/2026-05-27-agent-memory-system-design.md`

---

## File Structure

```
instructions/local.agent-memory/
├── manifest.yaml          # Registry metadata
└── AGENTS.md              # Brain stem instruction content

skills/local.agent-memory-workflow/
├── manifest.yaml          # Registry metadata
├── SKILL.md               # Full workflow reference (4 operations)
└── templates/
    ├── error-fix.md       # Template for error/fix memories
    ├── convention.md      # Template for convention memories
    ├── environment.md     # Template for environment quirk memories
    └── decision.md        # Template for architectural decision memories
```

No existing code files are modified. After creating these, `README.md` is updated for the inventory change and `bin/skill sync` regenerates `registry.json` to include the new items.

---

## Task 1: Create the Instruction Item

**Files:**
- Create: `instructions/local.agent-memory/manifest.yaml`
- Create: `instructions/local.agent-memory/AGENTS.md`

- [ ] **Step 1: Create manifest.yaml**

```yaml
name: local.agent-memory
type: instruction
description: "Procedural commands forcing the agent to search .ai/memory/ before tasks and propose entries after tasks."
tags:
  - memory
  - self-reflection
  - workflow
targets:
  - claude-code
  - github-copilot
  - cursor
  - cline
  - opencode
  - codex
files:
  - AGENTS.md
version: "1.0.0"
```

- [ ] **Step 2: Create AGENTS.md**

```markdown
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
```

- [ ] **Step 3: Commit**

```bash
git add instructions/local.agent-memory/
git commit -m "feat: add local.agent-memory instruction (brain stem)"
```

---

## Task 2: Create the Skill — Manifest and SKILL.md

**Files:**
- Create: `skills/local.agent-memory-workflow/manifest.yaml`
- Create: `skills/local.agent-memory-workflow/SKILL.md`

- [ ] **Step 1: Create manifest.yaml**

```yaml
name: local.agent-memory-workflow
type: skill
description: "Use when writing, searching, or maintaining entries in the project's .ai/memory/ vault."
tags:
  - memory
  - self-reflection
  - workflow
  - templates
targets:
  - claude-code
  - github-copilot
  - cursor
  - cline
  - opencode
  - codex
files:
  - SKILL.md
  - templates/error-fix.md
  - templates/convention.md
  - templates/environment.md
  - templates/decision.md
version: "1.0.0"
```

- [ ] **Step 2: Create SKILL.md**

````markdown
---
name: agent-memory-workflow
description: "Use when writing, searching, or maintaining entries in the project's .ai/memory/ vault."
---

# Agent Memory Workflow

Detailed procedures for writing, searching, and maintaining the project's `.ai/memory/` vault.

## Operations

1. **Bootstrap** — Create the vault on first use
2. **Write** — Add a new memory entry
3. **Search** — Find relevant memories for the current task
4. **Lint** — Audit and maintain vault health

---

## Operation 1: Bootstrap (First Use)

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

3. Proceed to Operation 2 to write the first entry.

---

## Operation 2: Write a Memory Entry

Triggered when the user approves a proposed memory entry.

### Step 1: Determine Category

Choose one:
- `error-fix` — An error that required non-obvious debugging
- `convention` — A project convention not documented elsewhere
- `environment` — An environment-specific quirk or workaround
- `decision` — An architectural decision with important rationale

### Step 2: Generate Filename

- Use kebab-case
- Be descriptive (e.g., `docker-compose-port-conflict.md`, `use-strict-typescript.md`)
- Max ~50 characters
- No date prefix (date goes in the file's metadata)

### Step 3: Apply Template

Read the appropriate template from this skill's `templates/` directory:
- `templates/error-fix.md`
- `templates/convention.md`
- `templates/environment.md`
- `templates/decision.md`

### Step 4: Fill and Write

Populate all template sections with specific, actionable content. Write to `.ai/memory/<filename>.md`.

### Step 5: Update Index

Append a row to `.ai/memory/index.md`:

```
| <filename>.md | <category> | <tag1, tag2, tag3> | <one-line summary max ~80 chars> |
```

### Step 6: Stage Files

```bash
git add .ai/memory/<filename>.md .ai/memory/index.md
```

Stage only — do not commit. The user will commit with their broader task changes.

---

## Operation 3: Search Memory

The brain stem instruction handles the common search path (read index → match keywords → read files). This operation documents the fallback for large vaults only:

```bash
grep -ril "<keyword>" .ai/memory/
```

Use when the index scan alone is insufficient. Extract 2-3 keywords from: technology names, error fragments, tool names, concepts. Read matched files in full, apply lessons silently.

---

## Operation 4: Lint / Maintain

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
````

- [ ] **Step 3: Commit**

```bash
git add skills/local.agent-memory-workflow/manifest.yaml skills/local.agent-memory-workflow/SKILL.md
git commit -m "feat: add local.agent-memory-workflow skill (main workflow)"
```

---

## Task 3: Create the Templates

**Files:**
- Create: `skills/local.agent-memory-workflow/templates/error-fix.md`
- Create: `skills/local.agent-memory-workflow/templates/convention.md`
- Create: `skills/local.agent-memory-workflow/templates/environment.md`
- Create: `skills/local.agent-memory-workflow/templates/decision.md`

- [ ] **Step 1: Create templates/error-fix.md**

```markdown
# <Title>

**Category:** error-fix
**Tags:** <comma-separated keywords>
**Date:** <YYYY-MM-DD>

## Symptom

What went wrong. Error messages, observed behavior.

## Failed Approaches

What was tried that didn't work (so the agent doesn't retry them).

## Root Cause

Why it happened.

## Fix

The correct solution. Commands, config changes, or code.
```

- [ ] **Step 2: Create templates/convention.md**

```markdown
# <Title>

**Category:** convention
**Tags:** <comma-separated keywords>
**Date:** <YYYY-MM-DD>

## Rule

The convention to follow.

## Rationale

Why this convention exists.

## Examples

Correct and incorrect usage.
```

- [ ] **Step 3: Create templates/environment.md**

```markdown
# <Title>

**Category:** environment
**Tags:** <comma-separated keywords>
**Date:** <YYYY-MM-DD>

## Context

What environment/setup this applies to.

## Quirk

The non-obvious behavior or requirement.

## Workaround

How to handle it.
```

- [ ] **Step 4: Create templates/decision.md**

```markdown
# <Title>

**Category:** decision
**Tags:** <comma-separated keywords>
**Date:** <YYYY-MM-DD>

## Decision

What was decided.

## Alternatives Considered

Other options and why they were rejected.

## Consequences

What this decision implies for future work.
```

- [ ] **Step 5: Commit**

```bash
git add skills/local.agent-memory-workflow/templates/
git commit -m "feat: add memory entry templates (error-fix, convention, environment, decision)"
```

---

## Task 4: Update README Inventory

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update item counts**

Replace:

```markdown
The registry ships with **25 skills** and **1 instruction** from multiple sources:
```

With:

```markdown
The registry ships with **26 skills** and **2 instructions** from multiple sources:
```

- [ ] **Step 2: Update the Local table**

Replace the current Local table with:

```markdown
### Local

| Item | Type | When to Use |
|------|------|-------------|
| `agent-memory` | instruction | Brain stem instructions that prompt agents to check `.ai/memory/` before tasks and propose memory entries after tasks |
| `agent-memory-workflow` | skill | Detailed workflow for writing, searching, linting, and maintaining `.ai/memory/` entries |
| `context-sync` | skill | When you need to update project context files (CLAUDE.md, copilot-instructions.md, etc.) to reflect the current codebase |
| `example-skill` | skill | Reference template showing the manifest format |
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: update local inventory for agent memory items"
```

---

## Task 5: Sync Registry and Verify

**Files:**
- Modify: `registry.json` (regenerated by sync)

- [ ] **Step 1: Run sync**

```bash
bin/skill sync
```

Expected: `bin/skill sync` succeeds and updates `registry.json`.

- [ ] **Step 2: Verify new items appear in registry**

```bash
grep '"local.agent-memory"' registry.json
grep '"local.agent-memory-workflow"' registry.json
```

Expected: Both lines found.

- [ ] **Step 3: Verify targets and files are correct**

```bash
for file in \
  'templates/error-fix.md' \
  'templates/convention.md' \
  'templates/environment.md' \
  'templates/decision.md'; do
  grep -q "\"$file\"" registry.json || exit 1
done
echo "PASS: all template files listed"
```

Expected: `PASS: all template files listed`.

- [ ] **Step 4: Run existing tests**

```bash
bash tests/run-tests.sh
```

Expected: All 51 tests pass. No regressions.

- [ ] **Step 5: Commit registry**

```bash
git add registry.json
git commit -m "chore: regenerate registry.json with agent-memory items"
```

---

## Task 6: Verify Install Works End-to-End

**Files:** None modified — validation only.

- [ ] **Step 1: Test instruction install to a temp directory**

```bash
TMP=$(mktemp -d)
bin/skill install local.agent-memory --target "$TMP" --agent claude-code --yes
```

Expected: Success. Instruction files copied to `$TMP/.claude/skills/local.agent-memory/`.

- [ ] **Step 2: Test skill install**

```bash
bin/skill install local.agent-memory-workflow --target "$TMP" --agent claude-code --yes
```

Expected: Success. Skill files copied to `$TMP/.claude/skills/local.agent-memory-workflow/`.

- [ ] **Step 3: Verify installed content**

```bash
grep -q "ai/memory" "$TMP/.claude/skills/local.agent-memory/AGENTS.md" && echo "PASS: instruction installed" || echo "FAIL"
ls "$TMP/.claude/skills/local.agent-memory-workflow/SKILL.md" && echo "PASS: skill installed" || echo "FAIL"
ls "$TMP/.claude/skills/local.agent-memory-workflow/templates/error-fix.md" && echo "PASS: templates installed" || echo "FAIL"
```

Expected: All PASS.

- [ ] **Step 4: Clean up**

```bash
rm -rf "$TMP"
```
