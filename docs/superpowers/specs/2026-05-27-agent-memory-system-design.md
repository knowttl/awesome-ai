# Agent Memory System — Design Spec

**Date:** 2026-05-27  
**Status:** Approved for implementation
**Approach:** Thin Instruction + Fat Skill (Approach 1)

## Summary

A lightweight, file-based memory system and self-reflection loop for AI coding agents. Prevents agents from repeating mistakes across long-running or complex projects by capturing "lessons learned" and forcing retrieval before new work.

Implemented as two registry items:
- **Instruction** (`local.agent-memory`): Short "brain stem" content intended to be loaded by the target agent — procedural commands forcing memory check before tasks and entry proposal after tasks.
- **Skill** (`local.agent-memory-workflow`): On-demand detailed reference for writing, searching, linting, and maintaining the memory vault.

The current installer copies both items into agent-specific install directories (for example, `.claude/skills/<name>/`). It does not rewrite `CLAUDE.md`, `.github/copilot-instructions.md`, or other root context files. Agents or setup flows that require explicit root-file merging must enable the installed instruction content separately.

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Form | Instruction + Skill | Progressive disclosure — tiny brain stem trigger, detailed reference on-demand |
| Scope | Per-project `.ai/memory/` | Project-specific lessons, git-committed, no cross-project complexity |
| Write trigger | Agent proposes at task end, user approves | Balanced quality vs. friction; no mid-task interruptions |
| File format | Multiple templates by category | Expressive for different memory types |
| Retrieval | Index file + grep | Reliable discovery without infrastructure |
| Target agents | Claude Code, GitHub Copilot, Cursor, Cline, OpenCode, Codex | All CLI-capable agents |
| Lint operation | Yes, user-invocable | Keeps vault healthy as it grows |
| Vault structure | Flat (no subdirectories) | Simple grep, categories via visible metadata lines/tags |

## Architecture

```
Two-Tier Progressive Disclosure:

┌─────────────────────────────────────────────────────┐
│  Tier 1: Brain Stem (instruction package)           │
│  instructions/local.agent-memory/AGENTS.md          │
│  ~25 lines — procedural commands only               │
│  "Check memory before task. Propose entry after."   │
└──────────────────────────┬──────────────────────────┘
                           │ invokes on write/lint
                           ▼
┌─────────────────────────────────────────────────────┐
│  Tier 2: Workflow Skill (on-demand)                 │
│  skills/local.agent-memory-workflow/SKILL.md        │
│  Full reference: templates, operations, procedures  │
│  Only loaded when agent needs to write/search/lint  │
└─────────────────────────────────────────────────────┘
                           │ operates on
                           ▼
┌─────────────────────────────────────────────────────┐
│  Tier 3: Memory Vault (in target project)           │
│  <project>/.ai/memory/                              │
│  ├── index.md        (catalog of all entries)       │
│  └── *.md            (individual memory files)      │
└─────────────────────────────────────────────────────┘
```

## Self-Reflection Workflow

```
[User gives task]
       │
       ▼
1. Agent has loaded the brain stem instruction package
       │
       ▼
2. Agent reads .ai/memory/index.md
   Scans titles, tags, summaries for relevance
       │
       ▼
3. Agent reads matched memory files in full
   (+ optional: grep -ril "keywords" .ai/memory/)
       │
       ▼
4. Agent executes task (applying known lessons)
       │
       ▼
5. Task complete — agent evaluates:
   "Did I hit a non-obvious problem?"
       │
       ├── No → Done
       │
       └── Yes → Proposes memory entry to user
                      │
                      ├── User rejects → Done
                      │
                      └── User approves → Agent invokes skill,
                          writes entry + updates index
```

## Registry Items

### Item 1: Instruction — `local.agent-memory`

**Directory:** `instructions/local.agent-memory/`

**Files:**
```
instructions/local.agent-memory/
├── manifest.yaml
└── AGENTS.md
```

**manifest.yaml:**
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

**AGENTS.md content:**

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

### Item 2: Skill — `local.agent-memory-workflow`

**Directory:** `skills/local.agent-memory-workflow/`

**Files:**
```
skills/local.agent-memory-workflow/
├── manifest.yaml
├── SKILL.md
└── templates/
    ├── error-fix.md
    ├── convention.md
    ├── environment.md
    └── decision.md
```

**manifest.yaml:**
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

## Skill Operations

### Operation 1: Bootstrap (First Use)

If `.ai/memory/` does not exist:

1. Create directory `.ai/memory/`
2. Create `.ai/memory/index.md` with:

```markdown
# Memory Index

> Auto-maintained by the agent. Do not edit manually.

| File | Category | Tags | Summary |
|------|----------|------|---------|
```

3. Proceed to write the first entry (Operation 2).

### Operation 2: Write a Memory Entry

1. **Determine category** from: `error-fix`, `convention`, `environment`, `decision`
2. **Generate filename** — kebab-case, descriptive, e.g., `docker-compose-port-conflict.md`
3. **Apply template** — read the appropriate template from the skill's `templates/` directory
4. **Fill template** — populate all sections with specific, actionable content
5. **Write file** to `.ai/memory/<filename>.md`
6. **Update index** — append a row to the table in `.ai/memory/index.md`
7. **Git add** both files: `git add .ai/memory/<filename>.md .ai/memory/index.md` (stage only — do not commit; the user will commit with their broader task changes)

**Naming conventions:**
- Filenames: kebab-case, no date prefix (date is in the file's metadata block)
- Max ~50 characters for the filename
- Descriptive enough to be meaningful in the index

### Operation 3: Search Memory (Detailed)

When the brain stem instruction triggers a memory check:

1. **Read index** — `cat .ai/memory/index.md`
2. **Scan for relevance** — match task keywords against file names, tags, and summaries in the index
3. **Deep search** (if index scan is insufficient) — `grep -ril "<keywords>" .ai/memory/`
4. **Read matched files** in full
5. **Summarize** applicable lessons internally before proceeding with the task

The agent should extract 2-3 keywords from the current task context for searching. Consider:
- Technology names (docker, postgres, typescript)
- Error message fragments
- Tool names
- Concept names (permissions, ports, migrations)

### Operation 4: Lint / Maintain

User-invocable. Triggered by explicit request (e.g., "lint my memory vault" or "audit .ai/memory").

1. **Read all entries** — read every `.md` file in `.ai/memory/` (excluding `index.md`)
2. **Read index** — compare against actual files
3. **Check for issues:**
   - **Stale entries** — fixes for dependencies/tools no longer in the project
   - **Duplicates** — multiple entries covering the same issue
   - **Contradictions** — entries that give conflicting advice
   - **Orphans** — files not listed in the index
   - **Ghost entries** — index rows pointing to deleted files
4. **Propose changes** to the user — never delete without approval:
   - "Remove `<file>` — references removed dependency X?"
   - "Merge `<file1>` and `<file2>` — both cover the same topic?"
   - "Entry `<file>` contradicts `<other>` — which is correct?"
5. **Rebuild index** if drifted — regenerate from actual files
6. **Report summary:**
   - Total entries, entries by category
   - Issues found and resolved
   - Last-modified dates of oldest entries

## Templates

### Template: `error-fix.md`

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

### Template: `convention.md`

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

### Template: `environment.md`

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

### Template: `decision.md`

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

## Index Format Specification

The index file uses a Markdown table with four columns:

| Column | Content |
|--------|---------|
| File | Filename (without path), serves as human-readable identifier |
| Category | One of: `error-fix`, `convention`, `environment`, `decision` |
| Tags | Comma-separated keywords for grep matching |
| Summary | One-line description (max ~80 chars) |

Entries are appended in chronological order (newest at bottom). During lint, the agent may reorder or rebuild the table.

## Target Agent Compatibility

All target agents can:
- Read files (to load index and entries)
- Run terminal commands (for `grep -ril` searches)
- Write files (to create entries)
- Run `git add` (to stage changes)

The skills-registry installer copies content to the paths defined in `bin/lib/agents.sh` and `bin/lib/agents.ps1`:

| Agent | Installed Instruction Path | Installed Skill Path |
|-------|----------------------------|----------------------|
| Claude Code | `.claude/skills/local.agent-memory/AGENTS.md` | `.claude/skills/local.agent-memory-workflow/` |
| GitHub Copilot | `.github/copilot/skills/local.agent-memory/AGENTS.md` | `.github/copilot/skills/local.agent-memory-workflow/` |
| Cursor | `.agents/skills/local.agent-memory/AGENTS.md` | `.agents/skills/local.agent-memory-workflow/` |
| Cline | `.agents/skills/local.agent-memory/AGENTS.md` | `.agents/skills/local.agent-memory-workflow/` |
| OpenCode | `.agents/skills/local.agent-memory/AGENTS.md` | `.agents/skills/local.agent-memory-workflow/` |
| Codex | `.agents/skills/local.agent-memory/AGENTS.md` | `.agents/skills/local.agent-memory-workflow/` |

This implementation does not change installer semantics. If a target agent does not automatically load installed instruction packages, the setup flow or user must merge/enable `AGENTS.md` in that agent's always-loaded context file.

## Out of Scope

- Cross-project/global memory vault
- Embedding-based semantic search
- Automatic write (no user approval)
- Web UI or dashboard
- MCP server integration
- Subdirectory organization within the vault
- Changing installer semantics to merge instruction content into root context files

## Success Criteria

1. Instruction package installs to the expected agent-specific path and contains the pre-task memory check
2. Agent proposes memory entries only at task completion, only for non-obvious learnings
3. Memory files follow the correct template for their category
4. Index stays in sync with actual files
5. Lint operation catches stale/duplicate/contradictory entries
6. Zero infrastructure required — plain Markdown + grep + git
