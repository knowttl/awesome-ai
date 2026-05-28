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
| Target agents | Claude Code, GitHub Copilot, Cursor, Cline, OpenCode, Codex, Windsurf, Roo Code | All CLI-capable agents |
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

Two items. Both target: `claude-code`, `github-copilot`, `cursor`, `cline`, `opencode`, `codex`, `windsurf`, `roo-code`.

| Item | Type | Files |
|------|------|-------|
| `local.agent-memory` | instruction | `AGENTS.md` |
| `local.agent-memory-workflow` | skill | `SKILL.md`, `templates/{error-fix,convention,environment,decision}.md` |

Full manifest YAML, `AGENTS.md` body, and `SKILL.md` body are defined in the implementation plan. The spec defines the contract; the plan is the source of truth for content.

## Skill Operations

The skill defines four operations. Detailed step-by-step procedures live in `SKILL.md` (authored in the plan's Task 2).

| Operation | Trigger | Purpose |
|-----------|---------|---------|
| Bootstrap | First write when `.ai/memory/` is missing | Create the vault directory and seed `index.md` with the header + table skeleton |
| Write | User approves a proposed entry | Pick category, generate kebab-case filename, apply template, write entry, append to index, `git add` (no commit) |
| Search | Brain stem pre-task hook | Read `index.md`, scan for keyword matches, optionally `grep -ril` for deep search, read matched files, apply lessons silently |
| Lint | User-invocable | Find stale/duplicate/contradictory/orphan/ghost entries, propose changes (never auto-delete), rebuild index if drifted, report counts |

**Naming conventions for entries:**
- Filenames: kebab-case, no date prefix, max ~50 chars
- Date lives in the file's metadata block

**Search keyword sources:** technology names, error message fragments, tool names, concept names.

## Templates

Four templates, one per category. Each file is plain Markdown beginning with a metadata block:

```
# <Title>

**Category:** <category>
**Tags:** <comma-separated keywords>
**Date:** <YYYY-MM-DD>
```

Body sections per category:

| Category | Body Sections |
|----------|--------------|
| `error-fix` | Symptom · Failed Approaches · Root Cause · Fix |
| `convention` | Rule · Rationale · Examples |
| `environment` | Context · Quirk · Workaround |
| `decision` | Decision · Alternatives Considered · Consequences |

Canonical template content is defined in the implementation plan (Task 3).

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

The skills-registry installer copies content to the paths defined in `bin/lib/agents.sh` and `bin/lib/agents.ps1`. The instruction installs to `<agent-skills-dir>/local.agent-memory/AGENTS.md`; the skill installs to `<agent-skills-dir>/local.agent-memory-workflow/`.

| Agent | `<agent-skills-dir>` |
|-------|----------------------|
| Claude Code | `.claude/skills` |
| GitHub Copilot | `.github/copilot/skills` |
| Cursor, Cline, OpenCode, Codex | `.agents/skills` |
| Windsurf | `.windsurf/skills` |
| Roo Code | `.roo/skills` |

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
