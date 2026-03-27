---
name: context-sync
description: "Use when you need to update project context files to reflect the current state of the codebase, or after making significant changes to the project structure, conventions, or architecture."
---

# Context Sync — Keep AI Context Files Current

Explore the current project and update all AI assistant context files so they accurately reflect the project's current state, structure, conventions, and tooling.

## When to Use

- **On demand**: User asks to update or sync context files
- **After structural changes**: New directories, renamed modules, added/removed commands, changed architecture
- **After convention changes**: New coding patterns, updated build steps, changed testing approach
- **After dependency changes**: Added/removed tools, changed build system, new integrations
- **Periodically**: When context files may have drifted from reality

## Context Files to Maintain

Scan the project root and common locations for AI assistant context files. These typically include:

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Claude Code project context |
| `.github/copilot-instructions.md` | GitHub Copilot instructions |
| `.cursorrules` | Cursor editor rules |
| `.windsurfrules` | Windsurf editor rules |
| `.clinerules` | Cline rules |
| `.opencode/instructions.md` | OpenCode instructions |
| `AGENTS.md` | Generic agent instructions |
| `.github/AGENTS.md` | GitHub-scoped agent instructions |
| `codex.md` | Codex instructions |

Not all projects will have all of these. Only update files that already exist — do not create new context files unless the user explicitly asks.

## Process

### Step 1: Discover Existing Context Files

Search the project for all known context file patterns:

```
CLAUDE.md
.github/copilot-instructions.md
.cursorrules
.windsurfrules
.clinerules
.opencode/instructions.md
AGENTS.md
.github/AGENTS.md
codex.md
```

List which ones exist. Note any that are missing if the project targets multiple AI assistants.

### Step 2: Explore Current Project State

Gather the following information by reading files and exploring the directory structure:

1. **Project purpose** — README, package.json, Cargo.toml, or equivalent
2. **Directory structure** — Top-level and key nested directories
3. **Architecture patterns** — Entry points, module organization, dependency patterns
4. **Build & run commands** — How to build, test, run, lint
5. **Coding conventions** — Naming, error handling, formatting, language-specific patterns
6. **Key files** — Configuration files, entry points, generated files
7. **Testing approach** — Test framework, test location, how to run tests
8. **Dependencies & tooling** — Language runtime, package manager, external tools

### Step 3: Compare and Update

For each existing context file:

1. **Read the current content** carefully
2. **Compare** against the actual project state discovered in Step 2
3. **Identify gaps**: new directories, changed commands, outdated descriptions, missing conventions
4. **Update the file** to reflect reality, preserving the existing format and style
5. **Do not remove** information that is still accurate
6. **Do not change** the file's overall structure or tone unless it's clearly wrong

### Step 4: Report Changes

After updating, provide a brief summary:
- Which files were updated and what changed
- Any context files that are missing but might be useful to create
- Any inconsistencies found between context files

## Rules

- **Preserve existing format**: Each context file has its own style (markdown, JSON, etc.). Match it.
- **Be conservative**: Only change what's actually wrong or missing. Don't rewrite files that are mostly correct.
- **Don't fabricate**: Only include information you verified by reading actual project files.
- **Keep it concise**: Context files should be brief and scannable, not exhaustive documentation.
- **Maintain consistency**: If the same information appears in multiple context files, ensure they agree.

## Ongoing Maintenance Reminder

After completing any significant project changes (adding commands, changing architecture, modifying build steps, updating conventions), check whether the context files need updating. A quick scan takes seconds and prevents context drift.

Key triggers that should prompt a context file update:
- Adding or removing top-level directories
- Changing build, test, or run commands
- Adding or removing CLI commands or API endpoints
- Changing coding conventions or error handling patterns
- Adding or removing dependencies or tooling
- Modifying the project's architecture or module structure
