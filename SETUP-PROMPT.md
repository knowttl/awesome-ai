# Skills Registry Setup Prompt

> **Copy and paste everything below the line into any AI coding assistant to get guided through installing skills and setting up AGENTS.md for your project.**

---

You are helping me set up AI coding skills and behavioral guidelines for my project. Guide me through this interactively, one step at a time. Do NOT proceed to the next step until I respond. Present each step clearly and wait for my input.

## Context You Need

The **skills-registry** (https://github.com/a-btsai/awesome-ai) is a CLI tool + content monorepo for managing reusable AI coding skills. It installs skill files into project-local directories for 8 AI coding assistants.

**Supported assistants and their `--agent` flag values:**

| Assistant | `--agent` value | Project Install Path |
|-----------|----------------|---------------------|
| Claude Code | `claude-code` | `.claude/skills/<name>/` |
| GitHub Copilot | `github-copilot` | `.github/copilot/skills/<name>/` |
| Cursor | `cursor` | `.agents/skills/<name>/` |
| Cline | `cline` | `.agents/skills/<name>/` |
| OpenCode | `opencode` | `.agents/skills/<name>/` |
| Codex | `codex` | `.agents/skills/<name>/` |
| Windsurf | `windsurf` | `.windsurf/skills/<name>/` |
| Roo Code | `roo` | `.roo/skills/<name>/` |

---

## Step 1: Environment Check

Ask me these questions (present them as a numbered list and wait for my answers):

1. Which AI coding assistant(s) am I using? (List: Claude Code, GitHub Copilot, Cursor, Cline, OpenCode, Codex, Windsurf, Roo Code)
2. What is the absolute path to my project's root directory?
3. Do I already have the skills-registry cloned locally?
   - If YES: ask for the path to the clone.
   - If NO: present these two options and ask which I prefer:
     - **Option A** — Clone it locally for full CLI access (recommended): `git clone https://github.com/a-btsai/awesome-ai.git ~/skills-registry`
     - **Option B** — Temporary clone just for this setup (clone to `/tmp/skills-registry`, keep it through AGENTS.md setup, then ask before deleting it)

Store my answers as variables for later steps:
- `AGENT_NAMES` = one or more `--agent` values from the table above
- `AGENT_FLAGS` = repeated flags built from `AGENT_NAMES`, e.g. `--agent claude-code --agent github-copilot`
- `PROJECT_PATH` = my project root
- `REGISTRY_PATH` = path to the skills-registry clone

---

## Step 2: Skill Selection

Present the skill catalog below. Ask me which skills I want to install. Tell me I can select by:
- Individual names (e.g., "brainstorming, tdd")
- Category (e.g., "all workflow skills")
- "all" for everything
- "recommend" if I want your suggestion based on common workflows

If I say "recommend", suggest this starter set:
- `local.context-sync` (keep project docs current)
- For Claude Code or GitHub Copilot: `obra.superpowers.brainstorming`, `obra.superpowers.test-driven-development`, `obra.superpowers.systematic-debugging`, `obra.superpowers.verification-before-completion`
- For other assistants: `mattpocock.skills.prototype`, `mattpocock.skills.tdd`, `mattpocock.skills.diagnose`, `mattpocock.skills.zoom-out`

If I use multiple assistants, recommend the compatible starter skills for each assistant and explain any differences.

### Workflow & Planning
| # | Skill | Description | Supports |
|---|-------|-------------|----------|
| 1 | `obra.superpowers.brainstorming` | Explore intent, requirements, and design before implementation | Claude Code, GitHub Copilot |
| 2 | `obra.superpowers.writing-plans` | Multi-step implementation planning from specs/requirements | Claude Code, GitHub Copilot |
| 3 | `obra.superpowers.executing-plans` | Execute written plans with review checkpoints | Claude Code, GitHub Copilot |
| 4 | `obra.superpowers.dispatching-parallel-agents` | Run 2+ independent tasks without shared state | Claude Code, GitHub Copilot |
| 5 | `obra.superpowers.subagent-driven-development` | Execute plans with independent sub-tasks | Claude Code, GitHub Copilot |
| 6 | `obra.superpowers.using-superpowers` | Establish skill discovery at conversation start | Claude Code, GitHub Copilot |
| 7 | `local.context-sync` | Update project context files after structural changes | All 8 assistants |

### Code Quality & Testing
| # | Skill | Description | Supports |
|---|-------|-------------|----------|
| 8 | `obra.superpowers.test-driven-development` | TDD: write tests before implementation | Claude Code, GitHub Copilot |
| 9 | `obra.superpowers.systematic-debugging` | Disciplined debugging before proposing fixes | Claude Code, GitHub Copilot |
| 10 | `obra.superpowers.verification-before-completion` | Require evidence before claiming work is done | Claude Code, GitHub Copilot |
| 11 | `mattpocock.skills.tdd` | Red-green-refactor loop, one vertical slice at a time | All 8 assistants |
| 12 | `mattpocock.skills.diagnose` | Diagnosis loop for hard bugs and performance regressions | All 8 assistants |

### Code Review & Git
| # | Skill | Description | Supports |
|---|-------|-------------|----------|
| 13 | `obra.superpowers.requesting-code-review` | Verify work meets requirements before merging | Claude Code, GitHub Copilot |
| 14 | `obra.superpowers.receiving-code-review` | Handle review feedback with rigor, not blind agreement | Claude Code, GitHub Copilot |
| 15 | `obra.superpowers.finishing-a-development-branch` | Decide merge/PR/cleanup when implementation is done | Claude Code, GitHub Copilot |
| 16 | `obra.superpowers.using-git-worktrees` | Isolated git worktrees for feature work | Claude Code, GitHub Copilot |

### Architecture & Design
| # | Skill | Description | Supports |
|---|-------|-------------|----------|
| 17 | `mattpocock.skills.prototype` | Build throwaway prototypes for design exploration | All 8 assistants |
| 18 | `mattpocock.skills.grill-with-docs` | Challenge plans against domain model, update docs | All 8 assistants |
| 19 | `mattpocock.skills.improve-codebase-architecture` | Find deepening opportunities in a codebase | All 8 assistants |
| 20 | `mattpocock.skills.zoom-out` | Get broader context on unfamiliar code | All 8 assistants |

### Project Management
| # | Skill | Description | Supports |
|---|-------|-------------|----------|
| 21 | `mattpocock.skills.to-prd` | Generate product requirement documents | All 8 assistants |
| 22 | `mattpocock.skills.to-issues` | Break plans into independently-grabbable issues | All 8 assistants |
| 23 | `mattpocock.skills.triage` | Triage issues through a state machine workflow | All 8 assistants |

### Meta
| # | Skill | Description | Supports |
|---|-------|-------------|----------|
| 24 | `obra.superpowers.writing-skills` | Create or edit skills for the registry | Claude Code, GitHub Copilot |

**Important compatibility note:** Skills marked "Claude Code, GitHub Copilot" only support those two assistants. If my assistant is different, filter the list to show only "All 8 assistants" skills and note which ones I can't use. If I use multiple assistants, install each selected skill only to the compatible subset of assistants.

---

## Step 3: Install Skills

Based on my answers from Steps 1 and 2, generate and execute the install commands.

**Pre-flight (if the registry was just cloned or hasn't been synced):**

    cd "<REGISTRY_PATH>" && bin/skill sync

When executing shell commands, replace `<REGISTRY_PATH>`, `<PROJECT_PATH>`, `SKILL_NAME`, and `AGENT_FLAGS` with actual values. Quote paths that may contain spaces. Do not run commands with the literal placeholder text still present.

**Default install method: install each selected skill individually.** This is safest because some skills support all assistants while others support only Claude Code and GitHub Copilot.

    "<REGISTRY_PATH>/bin/skill" install SKILL_NAME --target "<PROJECT_PATH>" AGENT_FLAGS --yes

For each selected skill, build `AGENT_FLAGS` from only the agents compatible with that skill. For example:

    # All-assistant skill installed to Claude Code and Cursor
    "<REGISTRY_PATH>/bin/skill" install mattpocock.skills.tdd --target "<PROJECT_PATH>" --agent claude-code --agent cursor --yes

    # Claude/GitHub-only skill installed only to Claude Code
    "<REGISTRY_PATH>/bin/skill" install obra.superpowers.brainstorming --target "<PROJECT_PATH>" --agent claude-code --yes

**Optional reusable profile:** Only suggest creating a profile if I explicitly want a reusable bundle. Do not create or overwrite a profile without asking. A single profile install applies the same agent flags to every item, so only use one profile when every selected skill is compatible with every selected assistant; otherwise install skills individually or create separate profiles by compatibility group.

Create file `<REGISTRY_PATH>/profiles/user-setup.yaml`:

    name: user-setup
    description: Custom skill bundle for <PROJECT_PATH>.
    items:
      - name: SKILL_1
        source: local
      - name: SKILL_2
        source: local

Then install:

    "<REGISTRY_PATH>/bin/skill" install --profile user-setup --target "<PROJECT_PATH>" AGENT_FLAGS --yes

**If using temporary clone (Option B from Step 1):**

    git clone --depth 1 https://github.com/a-btsai/awesome-ai.git /tmp/skills-registry
    cd /tmp/skills-registry && bin/skill sync
    bin/skill install SKILL_NAME --target "<PROJECT_PATH>" AGENT_FLAGS --yes
    # Repeat for each skill...
    # Keep /tmp/skills-registry available until AGENTS.md setup is complete.

**After running commands:** List the installed directories to confirm success. Show me what was created.

---

## Step 4: AGENTS.md Setup

Ask me these questions:

1. Would you like to set up an `AGENTS.md` file for your project? This provides behavioral guidelines that make AI coding assistants produce better code (think before coding, simplicity first, surgical changes, etc.)
2. Does your project already have an `AGENTS.md` (or `.github/copilot-instructions.md`, `CLAUDE.md`, or similar instruction file)?

Before creating or merging instructions, review the current project context. At minimum, inspect existing instruction files (`AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, `.github/instructions/*.md`), the README, package/build/test configuration files, and any obvious architecture docs. Use that context to avoid generic or contradictory guidance.

**If I say NO to setting up AGENTS.md:** Skip to Step 5.

**If I say YES and the project has NO existing AGENTS.md:**

If equivalent instruction files exist, read them first and ask whether I want to create a new root `AGENTS.md` that complements them or merge the baseline guidance into the existing instruction file instead. Do not duplicate guidance across files without asking.

Present two options:

- **Option A: Start with the battle-tested baseline** — Use the full baseline content provided in the "Baseline AGENTS.md Reference" section below. Write it to `<PROJECT_PATH>/AGENTS.md`. Then ask if I want to add project-specific sections (language/framework conventions, testing rules, architectural constraints, etc.) by interviewing me.

- **Option B: Write fully custom guidelines** — Interview me to create tailored guidelines from scratch. Ask these questions one at a time:
  1. What language(s) and framework(s) does this project use?
  2. What testing framework and conventions do you follow?
  3. What's your preferred code style? (functional vs OOP, naming conventions, file organization)
  4. Are there architectural patterns to follow? (clean architecture, DDD, hexagonal, etc.)
  5. What should the AI absolutely NEVER do in this project?
  6. Any domain-specific rules or constraints?

  Then generate an AGENTS.md incorporating their answers with the baseline principles.

**If I say YES and the project ALREADY HAS an AGENTS.md (or equivalent):**

1. Read the existing file in full.
2. Review the current project context files listed above.
3. Compare the existing instruction file against the baseline content below.
4. Identify which baseline principles are NOT already covered (even if worded differently - check for semantic equivalence, not just keyword matching).
5. Generate a proposed merged version that:
   - Preserves ALL existing content unchanged in its original position
   - Appends only the missing baseline sections at the end, under a clear heading like `## Additional Guidelines (from skills-registry baseline)`
   - Does NOT reword, reorder, or duplicate existing content
   - Matches the existing file's markdown style (heading levels, list format, etc.)
6. Show me exactly what will be added (not the full file - just the new sections).
7. Ask for my approval before writing.

### Baseline AGENTS.md Reference

If `REGISTRY_PATH` is available, prefer reading the current baseline from `<REGISTRY_PATH>/instructions/local.baseline-agents/AGENTS.md`. If that file is unavailable, use the embedded baseline below. Use the baseline when installing Option A or when identifying missing principles for merge:

---

# AGENTS.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Code Quality

**Write for local reasoning. A reader should understand the path without jumping elsewhere.**

Inspired by *Clean Code* (Robert C. Martin):
- Use precise names. One term per concept. Rename when vocabulary hides intent or forces comments to compensate.
- Keep functions small, focused, and at one level of abstraction. Tell the story top-down so intent appears before detail.
- Separate commands from queries. A function that answers should not also mutate.
- Keep the happy path readable. Isolate error handling, invalid-state handling, and cleanup.
- Expose behavior rather than raw representation. Avoid train-wreck access chains and utility dumping grounds.
- Keep construction, framework, persistence, and vendor details outside business behavior.
- Use comments only for rationale, constraints, warnings, or contracts. Do not narrate code instead of improving it.
- Treat tests as production code: readable, deterministic, and aligned with the behavior they protect.

## 6. Reduce Complexity

**Every interface, wrapper, layer, and name must hide enough complexity to justify its existence.**

Inspired by *A Philosophy of Software Design* (John Ousterhout):
- Use reduced complexity as the primary success metric. Prefer the design that lowers cognitive load, change amplification, and hidden dependencies.
- Prefer deep modules: small, semantic interfaces that hide meaningful internal complexity. Reject pass-through services, thin wrappers, and tiny split-outs that add names without reducing reader burden.
- Design interfaces around what callers need to know, not how the implementation works.
- Hide volatile decisions, internal representations, storage shape, protocols, and edge handling inside the module that owns the knowledge.
- Pull complexity downward when the lower module owns the detail. A slightly more complex implementation is worth a simpler public contract.
- Reduce exception surface by changing interfaces or invariants where possible. Define away invalid states instead of making every caller repeat defensive ceremony.
- Treat names, consistency, and obviousness as design information. Surprising code is complexity even when short.

## 7. Refactoring Discipline

**Refactoring is behavior-preserving design work in small steps. Not a rewrite. Not a hidden feature change.**

Inspired by *Refactoring* (Martin Fowler):
- Preserve observable behavior during refactoring. Isolate behavior changes from structural changes.
- Work in small, reversible, buildable, testable steps. Split a patch when it is too large to reason about locally.
- Establish a safety net before risky refactoring. Use characterization tests for unclear behavior.
- Use preparatory refactoring: identify what makes the requested change awkward, reshape that structure first, then make the behavior change.
- Refactor the current blocking smell, not every smell in sight.
- Prefer the simplest named move: rename, extract, inline, move, split, or introduce a parameter object.
- Put behavior and state with the concept that owns them. Separate business policy from formatting, transport, persistence, and I/O.
- Stop when the requested change is easy, the blocking smell is gone, and the next cleanup would be speculative.

## 8. Engineering Practices

**Own the outcome. Reduce duplicated knowledge. Keep concerns independent. Prove assumptions early.**

Inspired by *The Pragmatic Programmer* (Hunt & Thomas):
- Keep one authoritative representation for each piece of system knowledge. Business rules, validation, schemas, and configuration should derive from or trace to one owner.
- Preserve orthogonality: keep components independent, responsibilities non-overlapping, interfaces narrow, and collaborator knowledge small.
- Keep volatile decisions reversible. Do not hard-code vendors, platforms, databases, or deployment environments before evidence justifies the commitment.
- Prefer thin end-to-end tracer bullets over piles of isolated pieces. The first slice should be simple but real enough to validate architecture and assumptions.
- Shorten feedback loops with relevant tests, automated checks, and visible failures before late expensive surprises.
- Make contracts, assumptions, invariants, and caller/callee obligations explicit and close to the abstraction they protect.
- Automate repetitive, error-prone, or easy-to-forget work. Builds, tests, formatting, packaging, and deployment should be reproducible.
- Debug from reproduced facts: observe, isolate, explain, fix, and verify before guessing.
- Apply the broken windows rule: fix or visibly contain small quality decay before it becomes normal.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

## Step 5: Summary & Next Steps

After completing all steps, provide a clear summary:

**Installed skills:** List each skill name and where it was installed (the full path).

**AGENTS.md:** State whether it was created, merged, or skipped.

**Lock file:** Explain that `.skills-lock.json` was created in `<PROJECT_PATH>` and can be committed to version control so teammates can restore the same skills by running the install command with no item name.

**Ongoing maintenance tips:**
- View installed skills: `cat "<PROJECT_PATH>/.skills-lock.json"`
- Share with team: commit `.skills-lock.json`; teammates run `"<REGISTRY_PATH>/bin/skill" install --target "<PROJECT_PATH>"`
- Update skills from upstream: `cd "<REGISTRY_PATH>" && bin/skill update && bin/skill sync`
- Uninstall a skill: `"<REGISTRY_PATH>/bin/skill" uninstall SKILL_NAME --target "<PROJECT_PATH>"`
- Browse more skills: `"<REGISTRY_PATH>/bin/skill" list` or `"<REGISTRY_PATH>/bin/skill" search KEYWORD`

If I used the temporary clone option, ask whether I want to keep `/tmp/skills-registry`, move it to a permanent location, or delete it. Explain that future restore/update/uninstall commands require access to a skills-registry clone, so deleting the temporary clone means re-cloning later.
