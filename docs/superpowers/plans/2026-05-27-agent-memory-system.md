# Agent Memory System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a two-tier agent memory system (instruction + skill) to the skills-registry that teaches AI agents to persist and retrieve lessons learned across tasks.

**Architecture:** Thin instruction (brain stem, always loaded) triggers memory check/write behavior. Fat skill (on-demand reference) provides templates, operations, and procedures. Both are registry items installed via `bin/skill install`.

**Tech Stack:** Markdown content files, YAML manifests. No code changes to CLI.

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

No existing files are modified. After creating these, `bin/skill sync` regenerates `registry.json` to include the new items.

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

Create at: `instructions/local.agent-memory/manifest.yaml`

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
```

Create at: `instructions/local.agent-memory/AGENTS.md`

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

Create at: `skills/local.agent-memory-workflow/manifest.yaml`

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

## Operation 3: Search Memory (Detailed)

Used when the brain stem instruction triggers a memory check at task start.

### Step 1: Read the Index

```bash
cat .ai/memory/index.md
```

### Step 2: Scan for Relevance

Extract 2-3 keywords from the current task context:
- Technology names (docker, postgres, typescript)
- Error message fragments
- Tool names (webpack, eslint, terraform)
- Concept names (permissions, ports, migrations, auth)

Match keywords against file names, tags, and summaries in the index table.

### Step 3: Deep Search (if needed)

If the index scan is insufficient or the vault is large:

```bash
grep -ril "<keyword>" .ai/memory/
```

### Step 4: Read Matched Files

Read matched files in full to understand the lessons.

### Step 5: Apply

Summarize applicable lessons internally before proceeding with the task. Do not output the summary to the user unless asked.

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

```
Memory Vault Health:
- Total entries: N
- By category: error-fix (X), convention (Y), environment (Z), decision (W)
- Issues found: N (M resolved)
- Oldest entry: YYYY-MM-DD
- Newest entry: YYYY-MM-DD
```
````

Create at: `skills/local.agent-memory-workflow/SKILL.md`

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

Create at: `skills/local.agent-memory-workflow/templates/error-fix.md`

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

Create at: `skills/local.agent-memory-workflow/templates/convention.md`

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

Create at: `skills/local.agent-memory-workflow/templates/environment.md`

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

Create at: `skills/local.agent-memory-workflow/templates/decision.md`

- [ ] **Step 5: Commit**

```bash
git add skills/local.agent-memory-workflow/templates/
git commit -m "feat: add memory entry templates (error-fix, convention, environment, decision)"
```

---

## Task 4: Sync Registry and Verify

**Files:**
- Modify: `registry.json` (regenerated by sync)

- [ ] **Step 1: Run sync**

```bash
bin/skill sync
```

Expected: Success message. `registry.json` should now contain entries for `local.agent-memory` and `local.agent-memory-workflow`.

- [ ] **Step 2: Verify new items appear in registry**

```bash
grep -c '"name":' registry.json
```

Expected: Previous count + 2 (one instruction, one skill).

```bash
grep '"local.agent-memory"' registry.json
grep '"local.agent-memory-workflow"' registry.json
```

Expected: Both lines found.

- [ ] **Step 3: Verify targets and files are correct**

```bash
grep -A 20 '"local.agent-memory-workflow"' registry.json | grep -c '"templates/'
```

Expected: 4 (the four template files listed).

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

## Task 5: Verify Install Works End-to-End

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

- [ ] **Step 5: Final commit (if any fixes needed)**

If any issues were found and fixed in earlier tasks, ensure everything is committed. Otherwise, this step is a no-op.

```bash
git log --oneline -5
```

Expected output shows the commits from Tasks 1-4.
