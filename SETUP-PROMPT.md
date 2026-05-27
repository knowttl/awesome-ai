# Skills Registry Setup Prompt

> **Copy and paste the prompt below into any AI coding assistant to get guided through installing skills and setting up AGENTS.md for your project.**

---

## Prompt

```
You are helping me set up AI coding skills and behavioral guidelines for my project. Guide me through this step-by-step, one section at a time. Wait for my response after each step before continuing.

## Context

The **skills-registry** (https://github.com/a-btsai/awesome-ai) is a collection of reusable skills, agents, and instructions for AI-assisted coding. It has a zero-dependency CLI (Bash + PowerShell) that installs content into project-local directories for any of these AI coding assistants:

- Claude Code → `.claude/skills/<name>/`
- GitHub Copilot → `.github/copilot/skills/<name>/`
- Cursor → `.agents/skills/<name>/`
- Cline → `.agents/skills/<name>/`
- OpenCode → `.agents/skills/<name>/`
- Codex → `.agents/skills/<name>/`
- Windsurf → `.windsurf/skills/<name>/`
- Roo Code → `.roo/skills/<name>/`

---

## Step 1: Environment Check

Ask me:
1. Which AI coding assistant(s) am I using? (Claude Code, GitHub Copilot, Cursor, Cline, OpenCode, Codex, Windsurf, Roo Code)
2. What is the path to my project's root directory?
3. Do I already have the skills-registry cloned locally? If so, what path? If not, offer two options:
   - **Option A**: Clone it locally for full CLI access: `git clone https://github.com/a-btsai/awesome-ai.git`
   - **Option B**: Install directly from the remote repo (no local clone needed, but fewer features)

---

## Step 2: Skill Selection

Present the available skills organized by category. Show each skill's name, a one-line description, and which assistants it supports. Let me select which ones I want.

### Workflow & Planning
| Skill | Description | Supports |
|-------|-------------|----------|
| `obra.superpowers.brainstorming` | Explores user intent, requirements and design before implementation | Claude Code, GitHub Copilot |
| `obra.superpowers.writing-plans` | Multi-step implementation planning from specs/requirements | Claude Code, GitHub Copilot |
| `obra.superpowers.executing-plans` | Execute written plans with review checkpoints | Claude Code, GitHub Copilot |
| `obra.superpowers.dispatching-parallel-agents` | Run 2+ independent tasks without shared state | Claude Code, GitHub Copilot |
| `obra.superpowers.subagent-driven-development` | Execute plans with independent sub-tasks | Claude Code, GitHub Copilot |
| `obra.superpowers.using-superpowers` | Establishes skill discovery at conversation start | Claude Code, GitHub Copilot |
| `local.context-sync` | Update project context files after structural changes | All 8 assistants |

### Code Quality & Testing
| Skill | Description | Supports |
|-------|-------------|----------|
| `obra.superpowers.test-driven-development` | TDD: write tests before implementation | Claude Code, GitHub Copilot |
| `obra.superpowers.systematic-debugging` | Disciplined debugging before proposing fixes | Claude Code, GitHub Copilot |
| `obra.superpowers.verification-before-completion` | Require evidence before claiming work is done | Claude Code, GitHub Copilot |
| `mattpocock.skills.tdd` | Red-green-refactor loop, one vertical slice at a time | All 8 assistants |
| `mattpocock.skills.diagnose` | Diagnosis loop for hard bugs and performance regressions | All 8 assistants |

### Code Review & Git
| Skill | Description | Supports |
|-------|-------------|----------|
| `obra.superpowers.requesting-code-review` | Verify work meets requirements before merging | Claude Code, GitHub Copilot |
| `obra.superpowers.receiving-code-review` | Handle review feedback with rigor, not blind agreement | Claude Code, GitHub Copilot |
| `obra.superpowers.finishing-a-development-branch` | Decide merge/PR/cleanup when implementation is done | Claude Code, GitHub Copilot |
| `obra.superpowers.using-git-worktrees` | Isolated git worktrees for feature work | Claude Code, GitHub Copilot |

### Architecture & Design
| Skill | Description | Supports |
|-------|-------------|----------|
| `mattpocock.skills.prototype` | Build throwaway prototypes for design exploration | All 8 assistants |
| `mattpocock.skills.grill-with-docs` | Challenge plans against domain model, update docs | All 8 assistants |
| `mattpocock.skills.improve-codebase-architecture` | Find deepening opportunities in a codebase | All 8 assistants |
| `mattpocock.skills.zoom-out` | Get broader context on unfamiliar code | All 8 assistants |

### Project Management
| Skill | Description | Supports |
|-------|-------------|----------|
| `mattpocock.skills.to-prd` | Generate product requirement documents | All 8 assistants |
| `mattpocock.skills.to-issues` | Break plans into independently-grabbable issues | All 8 assistants |
| `mattpocock.skills.triage` | Triage issues through a state machine workflow | All 8 assistants |

### Meta
| Skill | Description | Supports |
|-------|-------------|----------|
| `obra.superpowers.writing-skills` | Create or edit skills for the registry | Claude Code, GitHub Copilot |

Ask me which skills I'd like to install. I can pick by name, by category ("all workflow skills"), or say "all" for everything.

---

## Step 3: Install Skills

Based on my selections and environment from Steps 1-2, run the install commands.

**If I have the registry cloned locally** (at `<REGISTRY_PATH>`):

```bash
# For each selected skill:
<REGISTRY_PATH>/bin/skill install <skill-name> --target <PROJECT_PATH> --agent <agent-name> --yes
```

Or if I selected many skills, suggest creating a profile:

```yaml
# Save as <REGISTRY_PATH>/profiles/my-setup.yaml
name: my-setup
description: My selected skills bundle.
items:
  - name: <skill-1>
    source: local
  - name: <skill-2>
    source: local
  # ... etc
```

Then install with: `<REGISTRY_PATH>/bin/skill install --profile my-setup --target <PROJECT_PATH> --yes`

**If I do NOT have the registry cloned** (Option B from Step 1):

```bash
# Clone just for install, then we can remove it:
git clone --depth 1 https://github.com/a-btsai/awesome-ai.git /tmp/skills-registry
cd /tmp/skills-registry && bin/skill sync

# Install each selected skill:
bin/skill install <skill-name> --target <PROJECT_PATH> --agent <agent-name> --yes

# Clean up if desired:
rm -rf /tmp/skills-registry
```

After installing, confirm what was installed and where by listing the created directories.

---

## Step 4: AGENTS.md Setup

Ask me:
1. Would you like to set up an `AGENTS.md` file for your project? (This provides behavioral guidelines that reduce common LLM coding mistakes — things like "think before coding", "simplicity first", "surgical changes", etc.)
2. Does your project already have an `AGENTS.md` file?

### If YES to AGENTS.md setup:

**If the project has NO existing AGENTS.md:**

Offer two options:
- **Option A: Start with the baseline** — Install the `local.baseline-agents` instruction which provides battle-tested guidelines covering:
  1. Think Before Coding (surface assumptions, don't hide confusion)
  2. Simplicity First (minimum code, nothing speculative)
  3. Surgical Changes (touch only what you must)
  4. Goal-Driven Execution (define success criteria, loop until verified)
  5. Code Quality (write for local reasoning)
  6. Reduce Complexity (deep modules, hide volatile decisions)
  7. Refactoring Discipline (small reversible steps)

  Then ask if they want to add project-specific sections.

- **Option B: Write custom guidelines** — Interview me about my project to create tailored guidelines. Ask about:
  - What language(s)/framework(s) does the project use?
  - What testing framework and conventions?
  - What's the preferred code style? (functional vs OOP, naming conventions, etc.)
  - Are there architectural patterns to follow? (clean architecture, DDD, etc.)
  - What should the AI NEVER do in this project?
  - Any domain-specific rules?

**If the project ALREADY HAS an AGENTS.md:**

1. Read the existing `AGENTS.md` file.
2. Read the baseline guidelines from the registry (the content below).
3. Identify which baseline guidelines are NOT already covered by the existing file.
4. Propose a merged version that:
   - Preserves ALL existing project-specific content and structure
   - Adds missing baseline guidelines as new sections (clearly marked)
   - Does NOT duplicate or override existing guidelines
   - Maintains the existing file's tone and formatting style
5. Show me the diff/proposed changes and ask for approval before writing.

### Baseline AGENTS.md Content (for reference during merge):

The baseline covers these principles:
- **Think Before Coding**: State assumptions, surface tradeoffs, ask when confused
- **Simplicity First**: No speculative features, no unnecessary abstractions
- **Surgical Changes**: Touch only what's needed, match existing style
- **Goal-Driven Execution**: Transform tasks into verifiable goals with success criteria
- **Code Quality**: Precise names, small functions, separate commands from queries
- **Reduce Complexity**: Deep modules, hide volatile decisions, pull complexity downward
- **Refactoring Discipline**: Behavior-preserving, small steps, safety nets

---

## Step 5: Confirmation & Next Steps

Summarize everything that was set up:
- Which skills were installed and where
- Whether AGENTS.md was created/updated
- The `.skills-lock.json` file (explain it can be committed to share with teammates)

Then provide these tips:
- To see what's installed: check `.skills-lock.json` in the project root
- To share with teammates: commit `.skills-lock.json`, they run the install command with no arguments to restore
- To update skills later: `bin/skill update` (if registry is cloned locally)
- To uninstall a skill: `bin/skill uninstall <name> --target <PROJECT_PATH>`
- To browse more skills: `bin/skill list` or `bin/skill search <keyword>`
```
