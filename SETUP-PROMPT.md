# Skills Registry Setup Prompt

> **Copy and paste everything below the line into any AI coding assistant to get guided through installing skills and setting up AGENTS.md for your project.**

## What This Does

This prompt guides you through an interactive setup process with your AI coding assistant:

1. **Environment detection** — auto-detects your AI assistant, project path, registry location, and existing installations, then confirms with you
2. **Registry discovery** — reads the skills-registry to find available skills
3. **Skill selection** — presents compatible skills grouped by source, lets you pick
4. **Installation** — runs the CLI commands to install selected skills into your project
5. **User profile AGENTS.md** — optionally installs baseline behavioral guidelines to `~/AGENTS.md` for use across all projects
6. **Project AGENTS.md** — uses the agentsmd-init skill to generate or update a project-specific `AGENTS.md`
7. **Taste setup (optional)** — optionally installs the Taste Developer opt-in prompt for adaptive preference learning
8. **Agent memory** — optionally installs a persistent memory system so your AI learns from past mistakes
9. **OpenSrc source context (optional)** — optionally adds guidance for using `opensrc` to inspect dependency internals
10. **Summary** — confirms what was installed and provides maintenance commands

No manual CLI knowledge required — the AI detects your environment and handles everything based on your choices.

## Idempotent by Design

This setup is a **verification pass**, not a one-time install. Each step checks current state first and skips what's already done. Steps 5–9 always verify and report status (never silently skipped). If setup is interrupted, re-run the prompt — completed steps are detected and skipped cleanly. Re-run anytime to catch missing or new items.

## Sub-Agent Discipline

Your role is **orchestration, not execution.** To keep your context lean, **delegate each step's implementation to a sub-agent.** You handle only:

- Running lightweight detection commands (file existence checks, `pwd`)
- Presenting findings and prompts to the user
- Collecting user input
- Passing structured instructions to sub-agents
- Reporting final results

Each step below specifies what the sub-agent must do and what it must return. Launch sub-agents as the step dictates and wait for their results before presenting the next step to the user.

### Sub-Agent Output Format

Every sub-agent MUST return output in this structure:

```
**Step N: [step name]**
- **Success:** true/false (or a list of per-item results)
- **Added:** [what was created/installed]
- **Skipped:** [what was already present]
- **Errors:** [any failures with specific error messages, or "none"]
- **Details:** [additional context if needed]
```

This ensures the host agent can build accurate Step 10 summaries.

### Repeated Patterns

**Root instruction file resolution** (used in Steps 7b and 8b): resolve the first existing file among `AGENTS.md`, `.github/copilot-instructions.md`, `CLAUDE.md`. If none exist, create `<PROJECT_PATH>/AGENTS.md`.

**Error handling**: If a sub-agent reports failure on any operation, present the error to the user and ask whether to retry, skip that item, or abort setup. Never silently continue past a failure.

---

You are helping me set up AI coding skills and behavioral guidelines for my project. Guide me through this interactively, one step at a time. Do NOT proceed to the next step until I respond. Present each step clearly and wait for my input.

**Principle: Detect first, confirm second.** For every piece of information you need, attempt to auto-detect it from the filesystem before asking me. Present your findings and ask me to confirm or correct — do not make me manually provide information you can discover yourself.

## Context You Need

The **skills-registry** (https://github.com/knowttl/awesome-ai) is a CLI tool + content monorepo for managing reusable AI coding skills. It has a zero-dependency CLI (pure Bash + PowerShell) that installs skill files into project-local directories for multiple AI coding assistants.

You will clone this registry, read it to understand how it works, discover available skills dynamically, and guide me through installation.

**Prerequisite:** You must have the ability to run shell commands and read files to follow this prompt. If you cannot execute commands or access the filesystem, stop and tell me.

## Agent Name Reference

Map user-facing agent names to `--agent` flag values:

| When user says | Use `--agent` |
|---|---|
| Claude Code | `claude-code` |
| GitHub Copilot | `github-copilot` |
| Cursor | `cursor` |
| Cline | `cline` |
| OpenCode | `opencode` |
| Codex | `codex` |
| Windsurf | `windsurf` |
| Roo Code | `roo` |

**Shorthand**: throughout this prompt, `<CLI>` means `"<REGISTRY_PATH>/bin/skill"`.

---

## Step 1: Environment Detection

**Detect first, then confirm.** Do NOT ask me questions you can answer yourself. Run detection commands, present your findings, and ask me to confirm or correct.

### 1a: Detect the AI assistant

You already know which AI assistant you are. State it:
> "I've detected that I'm running as **[assistant name]**."

If you support multiple assistant modes or the user might use others alongside you, ask: "Are there other AI assistants you also use for this project?"

### 1b: Detect the project directory

Run `pwd` (or equivalent) to determine the current working directory. Then verify it looks like a project root:

```bash
# Check for common project root indicators
PROJECT_INDICATORS=0
for f in .git package.json Cargo.toml go.mod pyproject.toml Makefile README.md src; do
  [[ -e "$f" ]] && ((PROJECT_INDICATORS++))
done
echo "Found $PROJECT_INDICATORS project indicators in $(pwd)"
```

Present your finding:
> "Your current directory is `<path>`. This appears to be a project root (found `.git/`, `package.json`, etc.)."

If `PROJECT_INDICATORS` is 0, say: "Your current directory is `<path>`. I didn't find common project indicators. Is this still the project you want to set up?"

Ask: "Is this the project you want to set up skills for, or is it a different path?"

### 1c: Detect the skills-registry

Search for an existing skills-registry clone by checking these locations in order:

```bash
# Check common clone locations + current directory
REGISTRY_FOUND=""
for dir in ~/skills-registry ~ ~/awesome-ai /tmp/skills-registry; do
  if [[ -f "$dir/bin/skill" ]] && [[ -f "$dir/registry.json" ]]; then
    REGISTRY_FOUND="$dir"
    break
  fi
done
if [[ -z "$REGISTRY_FOUND" ]] && [[ -f "./bin/skill" ]] && [[ -f "./registry.json" ]]; then
  REGISTRY_FOUND="$PWD"
fi
if [[ -n "$REGISTRY_FOUND" ]]; then
  echo "Found: $REGISTRY_FOUND"
else
  echo "Not found"
fi
```

If the output is "Not found", proceed to the "If NOT found" branch below.
If "Found: <path>", proceed to the "If found" branch.

**If found**, confirm and delegate the refresh to a sub-agent:
> "I found the skills-registry at `<path>`."
>
> Run a sub-agent with these instructions:
>
> > Refresh the skills-registry at `<REGISTRY_PATH>`:
> > ```bash
> > cd "<REGISTRY_PATH>" && git pull && bin/skill sync
> > ```
> > "Already up to date" is NOT a failure — `bin/skill sync` MUST still run. If `git pull` fails (network error, upstream changed), report the specific error. Return success/failure and the sync output.
> If the sub-agent reports a `git pull` failure (no network, upstream changed), ask me whether to continue with the current version or abort.
>
> When successful, confirm: "Registry refreshed to latest version."

**If NOT found**, tell me and explicitly ask where to clone it. Do NOT pick a location yourself — present both options and wait for my choice:
> "I couldn't find the skills-registry locally. I'll clone it from **https://github.com/knowttl/awesome-ai**. Where would you like me to put it? Please pick one:"
> - **Option A — Persistent (recommended):** `~/skills-registry` — kept on disk, reusable across projects and sessions, easy to `bin/skill update` later.
> - **Option B — Temporary:** `/tmp/skills-registry` — wiped on reboot, fine for a one-off trial install but you will have to re-clone next time.
> - **Option C — Custom path:** tell me a path and I will clone there instead.
>
> "Which would you like (A, B, or a custom path)?"

Wait for my explicit answer before running `git clone https://github.com/knowttl/awesome-ai`. Do not assume the recommended option.

After cloning, run `bin/skill sync` in the new clone to ensure the registry index is current:
```bash
cd "<REGISTRY_PATH>" && bin/skill sync
```

### 1d: Detect existing installations

If `PROJECT_PATH` has been confirmed, immediately scan for existing skill installations:

```bash
# Check for lock file
[[ -f "<PROJECT_PATH>/.skills-lock.json" ]] && echo "Lock file found"

# Check for common agent skill directories
for dir in .claude/skills .github/skills .agents/skills .windsurf/skills .roo/skills; do
  [[ -d "<PROJECT_PATH>/$dir" ]] && ls "<PROJECT_PATH>/$dir"
done

# Check for AGENTS.md or equivalents
for f in AGENTS.md .github/copilot-instructions.md CLAUDE.md .cursorrules .windsurfrules .clinerules opencode.json; do
  [[ -f "<PROJECT_PATH>/$f" ]] && echo "Found: $f"
done
# Also check for .cursor/rules/ directory
[[ -d "<PROJECT_PATH>/.cursor/rules" ]] && echo "Found: .cursor/rules/"

# Check for agent memory
[[ -d "<PROJECT_PATH>/.ai/memory" ]] && echo "Agent memory vault found"
```

Present a summary of findings:
> **Environment detected:**
> - Assistant: GitHub Copilot
> - Project: `/home/user/my-project` (Node.js project)
> - Registry: `~/skills-registry`
> - Installed skills: 5 items (from `.skills-lock.json`)
> - AGENTS.md: found
> - Agent Memory: not installed
>
> "Does this look right? Anything to correct?"

Wait for my confirmation before proceeding.

Store confirmed values:
- `AGENT_NAMES` = one or more agent identifiers (user-facing names like "Roo Code", "Claude Code")
- `AGENT_FLAGS` = the corresponding `--agent` flag values (use the Agent Name Reference table to map: "Roo Code" → `roo`, "Claude Code" → `claude-code`, etc.)
- `PROJECT_PATH` = my project root
- `REGISTRY_PATH` = path to the skills-registry clone

---

## Step 2: Discover the Registry

**Delegate this entire step to a sub-agent.** Run the sub-agent with these instructions:

> You are discovering the skills-registry for setup. The user's agents are: `<AGENT_FLAGS>` (these are the exact values used in `registry.json` targets). Return a structured summary with the sections below:
>
> 1. Read `<REGISTRY_PATH>/README.md`. Summarize only the key CLI commands and project structure.
>
> 2. Parse `<REGISTRY_PATH>/bin/lib/agents.sh` and extract the `AGENT_TABLE` (format: `name|project_path|global_suffix|detection_dirs|detection_bins`). Return a table mapping each agent name to its `--agent` flag value, project install path, and global install path.
>
> 3. Read `<REGISTRY_PATH>/registry.json`. Parse every entry: name, type, description, targets, files, path.
>
> 4. Cross-reference the detected installations from Step 1d against `registry.json`. Build:
>    - `COMPATIBLE_SKILLS`: items whose `targets` includes any of the user's agent flags: `<AGENT_FLAGS>`.
>    - `ALREADY_INSTALLED`: compatible items already present (found in lock file or agent dirs).
>    - `NOT_INSTALLED`: compatible items not yet installed.
>
> 5. For every item in `NOT_INSTALLED`, read its first 40 lines from `<REGISTRY_PATH>/<item.path>/SKILL.md` (or `<REGISTRY_PATH>/<item.path>/AGENTS.md` if SKILL.md does not exist). Return a one-sentence summary of what each skill does. This enables accurate recommendations in Step 3.
>
> Return output in this structure:
>
> **AGENT TABLE:**
> [table mapping name → flag, project path, global path]
>
> **COMPATIBLE_SKILLS (N items):**
> - name | type | description | targets
>
> **ALREADY_INSTALLED (N items):**
> - name | description
>
> **NOT_INSTALLED (N items):**
> - name | description | one-sentence SKILL.md summary

When the sub-agent returns, consolidate results in your main context. If `NOT_INSTALLED` is empty, tell me: "All compatible skills are already installed. You can still update them with `bin/skill update` or add new ones as they become available."

If I ask for more detail on a specific skill, delegate a separate sub-agent to read `<REGISTRY_PATH>/<item.path>/SKILL.md` and return a summary.

---

## Step 3: Skill Selection

**CRITICAL: Only present skills that actually exist in `registry.json`. Do NOT invent, fabricate, or hallucinate skill names. Every skill name you show must be an exact `name` value from the parsed JSON.**

**If existing installations were detected in Step 2**, present the results first:

> **Already installed:** List the items found, grouped by source (obra.superpowers, mattpocock.skills, local). Mark each as ✓ installed.
>
> **Not yet installed:** List compatible items that are NOT in `ALREADY_INSTALLED`. These are what you can add.

Then ask: "Would you like to install any of the items that aren't installed yet, or are you happy with your current setup?"

If I say I'm happy, proceed to Step 5 (User Profile AGENTS.md) — continue through all remaining steps for anything not yet configured. **The Agent Memory question in Step 8 MUST always be asked** unless both `local.agent-memory` AND `local.agent-memory-workflow` are already in `ALREADY_INSTALLED`. Do not silently skip the Agent Memory question.

**If nothing is installed yet (fresh project)**, present all compatible skills:

Present the discovered skills to me in a clear, organized format. Group them logically (by tags or by name prefix like `obra.superpowers.*`, `mattpocock.skills.*`, `local.*`). For each skill show:
- Name
- Description (from registry.json)
- Compatibility with my assistant(s)

Only show skills compatible with at least one of my selected assistants. If a skill is compatible with some but not all of my assistants, note which ones.

Tell me I can select by:
- Individual names or keywords (e.g., "brainstorming, tdd") — you will match these to the full skill names from registry.json
- Group prefix (e.g., "all obra.superpowers skills")
- "all" for everything compatible
- "recommend" if I want your suggestion

When I select by shorthand or keyword, map my input to the exact full `name` values from `registry.json`. The install command requires the exact full name (e.g., `obra.superpowers.brainstorming`, not just `brainstorming`).

**If I say "recommend":** Based on what you read in the SKILL.md files, suggest a balanced starter set covering design/planning, testing, debugging, and quality verification. Prefer skills with broader assistant compatibility when possible. Explain briefly why you chose each one.

**OpenSrc recommendation rule (dependency debugging):**
- If my request/history mentions dependency internals, third-party library bugs, "how does this package work", source-level investigation, or edge-case behavior inside npm/PyPI/crates/GitHub dependencies, explicitly include `local.opensrc-source-context` in your recommendation.
- If these signals are not present, keep OpenSrc optional and ask one quick follow-up: "Do you often debug dependency internals or inspect third-party source code?" If yes, include it.

---

## Step 4: Install Skills

Based on my selections, generate the install commands. **Skip any items that are already in `ALREADY_INSTALLED`** — only install new selections.

**Determine the correct `--agent` flag values.** Use the Agent Name Reference table above to map each user-facing agent name to its `--agent` flag. Cross-reference with the `AGENT_TABLE` from Step 2 for confirmation. Build the flags as `--agent <name>` repeated for each assistant.

**Deduplication note:** When both `claude-code` and `github-copilot` are selected, pass `--agent claude-code --agent github-copilot` — the CLI handles dedup internally (installs only to `.claude/skills/`). If `github-copilot` is selected alone, it installs to `.github/skills/`.

**Delegate the install execution to a sub-agent.** Run the sub-agent with these instructions:

> Install the following skills into the project. Run each command individually and report success or failure for each:
>
> ```
> <CLI> install <SKILL_NAME> --target "<PROJECT_PATH>" --agent <AGENT_1> --agent <AGENT_2> --yes
> ```
>
> (repeat for each skill in the selection list)
>
> For each skill, only include `--agent` flags for assistants that appear in that skill's `targets` array from `registry.json`.
>
> After running all commands, list the installed directories to confirm success. Return the list of what was created.

When the sub-agent returns, show me what was installed.

**After presenting, update your in-memory state:** add every successfully installed item to `ALREADY_INSTALLED`. This is critical — Steps 5–9 reference `ALREADY_INSTALLED` to decide what to ask about. If you skip this, the agent will re-ask about items just installed.

---

## Step 5: User Profile AGENTS.md (user profile only)

**This step only installs to `~/AGENTS.md` (user profile).** Baseline behavioral guidelines span across projects; they do NOT belong in a single project's AGENTS.md. Project-level AGENTS.md is handled separately in Step 6 via the agentsmd-init skill.

Ask whether the user wants a **user-level** `AGENTS.md` at `~/AGENTS.md`. This file applies baseline behavioral guidelines across all projects for this AI assistant.

### 5a) Detect existing user profile (lightweight check)

Check if `~/AGENTS.md` already exists:

```bash
[[ -f "$HOME/AGENTS.md" ]] && echo "Found: ~/AGENTS.md"
```

### 5b) Act based on state

**If `~/AGENTS.md` does NOT exist:**

> Would you like to install a user profile `AGENTS.md` at `~/AGENTS.md`? This provides baseline behavioral guidelines (think before coding, write the minimum, touch only what you must, etc.) that apply across all projects you work on with AI assistants.

If the user says **YES**:
**Delegate to a sub-agent:**

> Follow the workflow in `<REGISTRY_PATH>/skills/local.baseline-agents/SKILL.md`:
>
> 1. Read `~/AGENTS.md` (treat as empty if it does not exist).
> 2. Compare each rule section against the content of `~/AGENTS.md` using semantic equivalence.
> 3. Append only the missing rule sections to `~/AGENTS.md`. Do not duplicate existing content.
> 4. Return which sections were added, or "all rules already present — no changes made."

Confirm what was added (or that everything was already present).

**If `~/AGENTS.md` DOES exist (re-run path):**

> User profile AGENTS.md already exists at `~/AGENTS.md`. Setup complete for this step.

Lightweight check only — do not deep-compare content unless the user explicitly asks: "Would you also like me to review it against the skills-registry baseline for any missing guidelines?"

If the user says YES to review:
**Delegate to a sub-agent:**

> Review `~/AGENTS.md` against the baseline:
> 1. Read `~/AGENTS.md` and `<REGISTRY_PATH>/skills/local.baseline-agents/SKILL.md`.
> 2. Identify which baseline principles are NOT already covered (semantic equivalence, not keywords).
> 3. Present the list of missing sections to the user with a brief summary of each. Wait for user approval.
> 4. After approval, append only the missing sections to `~/AGENTS.md`.
> 5. Return which sections were added, or "all rules already present — no changes made."

If the user says **NO** to installing or reviewing the user profile: skip to Step 6.

---

## Step 6: Project AGENTS.md Setup

### 6a) Ask whether to set up a project AGENTS.md

Detect whether any instruction file already exists in `<PROJECT_PATH>` — check `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, `.cursorrules`, `.github/copilot-instructions.md`, `.windsurfrules`, `.clinerules`, `opencode.json`. Present your finding, then ask:

> Would you like to set up or update a project `AGENTS.md`? This provides AI assistants with project-specific behavioral guidelines, conventions, and commands.

If the user says **NO**: skip to Step 7.

If the user says **YES**: continue below.

### 6b) Generate using the agentsmd-init skill

Do NOT manually copy the baseline-agents file or run the workflow yourself. **Delegate this entire step to a sub-agent:**

> You are executing the agentsmd-init workflow for the project at `<PROJECT_PATH>`. Do not ask the user questions that the filesystem can answer. Return a summary of what you did and what changed.
>
> 1. Read the full agentsmd-init skill at `<REGISTRY_PATH>/skills/local.agentsmd-init/SKILL.md`.
>
> 2. Follow the skill's workflow exactly as written:
>    - **Step 1 (Check what exists):** Read any existing instruction files in `<PROJECT_PATH>` — `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, `.cursorrules`, `.github/copilot-instructions.md`, `opencode.json`.
>    - **Step 2 (Init vs. update mode):** Branch on whether `AGENTS.md` exists — follow the audit flow for update mode or investigation flow for init mode.
>    - **Step 3 (Extract high-signal facts):** Investigate the repo following the skill's priority order. Extract only facts an agent would get wrong without help.
>    - **Step 4 (Identify gaps, update mode only):** Compare found facts against the audited file.
>    - **Step 5 (Ask questions):** Only if the repo cannot answer something important. Never ask about anything the repo already makes clear.
>    - **Step 6 (Write or merge):** Write fresh in init mode or merge audit results in update mode. Apply the filter test: "Would an agent likely miss this without help?"
>    - **Step 7 (Verify and summarize):** Final pass for correctness. Return what was added, removed, or corrected.

When the sub-agent returns, confirm the final state of `<PROJECT_PATH>/AGENTS.md` with me.

---

## Step 7: Taste Setup (Optional)

Run this step after Step 6.

Use this deterministic state model:

- `TASTE_ITEMS = ["local.taste-setup", "local.taste-developer"]`
- `HAS_TASTE_SETUP = "local.taste-setup" in ALREADY_INSTALLED`
- `HAS_TASTE_DEVELOPER = "local.taste-developer" in ALREADY_INSTALLED`
- `TASTE_FULLY_INSTALLED = HAS_TASTE_SETUP && HAS_TASTE_DEVELOPER`

### 7a) Ask whether to enable Taste setup

If `TASTE_FULLY_INSTALLED` is `false`, ask exactly once:

> Would you like to enable **Taste Developer** setup? This adds a one-time opt-in prompt that asks whether to activate adaptive preference learning — the agent observes which outputs you accept, reject, or edit over time and auto-adjusts.

- If user says **NO**: set `TASTE_ENABLED = false` and go to Step 8.
- If user says **YES**: set `TASTE_ENABLED = true` and continue.

If `TASTE_FULLY_INSTALLED` is `true`, do not ask; set `TASTE_ENABLED = true` and skip to 7c (no install needed). The managed block was created during the initial install.

### 7a1) Ask where to install Taste

When `TASTE_ENABLED = true` and `TASTE_FULLY_INSTALLED` is `false` (fresh install), ask exactly once:

> Where would you like to install Taste?
> - **Project only** — Taste learns from your feedback in this project. Skills go into `<PROJECT_PATH>`.
> - **User profile (global)** — Taste learns across all projects. Skills go into your home directory (`~/.claude/skills/`, etc.).
> - **Both** (recommended) — install in both places.

Set `TASTE_SCOPE` to `project`, `global`, or `both` based on the answer.

### 7b) Ensure taste components are installed at the chosen scope

When `TASTE_ENABLED = true`, install only missing items at the chosen scope. **Delegate to a sub-agent:**

> Install taste components into the requested scope(s). Only install items that are missing from the respective lock files:
>
> 1. **Install for project scope** (if scope includes project):
> ```bash
> <CLI> install local.taste-setup --target "<PROJECT_PATH>" --agent <AGENT_1> --agent <AGENT_2> --yes
> <CLI> install local.taste-developer --target "<PROJECT_PATH>" --agent <AGENT_1> --agent <AGENT_2> --yes
> ```
> Verify both appear in `<PROJECT_PATH>/.skills-lock.json`.
>
> 2. **Install for global scope** (if scope includes global):
> ```bash
> <CLI> install local.taste-setup --global --agent <AGENT_1> --agent <AGENT_2> --yes
> <CLI> install local.taste-developer --global --agent <AGENT_1> --agent <AGENT_2> --yes
> ```
> Verify both appear in `$HOME/.skills-lock.json`.
>
> 3. **No managed block for taste-setup.** The user already opted in during this setup session. The full `local.taste-setup/AGENTS.md` is the opt-in prompt — it has no ongoing runtime value once the user has opted in. Do NOT create a managed block in the root instruction file. If a `<!-- BEGIN: local.taste-setup -->` block already exists from a previous run, leave it in place (removing it would break determinism on re-runs).
>
> Return: which items were installed at which scope. If any install fails, report the specific command and its error.

If the sub-agent reports failure, stop and tell me.

### 7c) Explain runtime behavior clearly

When taste setup is enabled (opted in during this session), explain:
- Taste Developer is already enabled. The agent will learn preferences from accepted/rejected/edited outputs over time.
- A taste profile is maintained at `.ai/taste/taste.md`.
- If taste was installed but declined earlier, the user can enable later by saying "start taste" or "enable taste developer."
- The setup prompt (`local.taste-setup/AGENTS.md`) is NOT folded into the project's root instruction file — it has no ongoing value once opted in. The installation itself (skill files in agent directories) is sufficient for the "start taste" fallback path.

---

## Step 8: Agent Memory (Required Checkpoint)

**This step is mandatory on every setup run.** You MUST always execute Step 8 logic, even if the user skipped installs in Step 3 or skipped project AGENTS.md work in Step 6.

Use this deterministic state model:

- `MEMORY_ITEMS = ["local.agent-memory", "local.agent-memory-workflow"]`
- `HAS_MEMORY_INSTRUCTION = "local.agent-memory" in ALREADY_INSTALLED`
- `HAS_MEMORY_WORKFLOW = "local.agent-memory-workflow" in ALREADY_INSTALLED`
- `MEMORY_FULLY_INSTALLED = HAS_MEMORY_INSTRUCTION && HAS_MEMORY_WORKFLOW`

### 8a) Decide enablement

If `MEMORY_FULLY_INSTALLED` is `false`, ask exactly once:

> Would you like to enable **Agent Memory** for this project? It helps agents avoid repeat failures by checking prior lessons before tasks and proposing new memory entries after non-obvious issues are solved.

- If user says **NO**: set `MEMORY_ENABLED = false` and go to Step 9.
- If user says **YES**: set `MEMORY_ENABLED = true` and continue.

If `MEMORY_FULLY_INSTALLED` is `true`, do not ask; set `MEMORY_ENABLED = true` and continue.

### 8b) Full memory setup (install, scaffold, managed block)

When `MEMORY_ENABLED = true`, **delegate all memory work to a single sub-agent:**

> Set up agent memory for `<PROJECT_PATH>`. Do everything below and return what was done:
>
> 1. **Install memory items** (skip if already in `.skills-lock.json`):
> ```bash
> <CLI> install local.agent-memory --target "<PROJECT_PATH>" --agent <AGENT_1> --agent <AGENT_2> --yes
> <CLI> install local.agent-memory-workflow --target "<PROJECT_PATH>" --agent <AGENT_1> --agent <AGENT_2> --yes
> ```
> Verify both appear in `.skills-lock.json`. If either is missing after install, return failure.
>
> 2. **Scaffold vault** (idempotent — only create if missing):
> ```bash
> mkdir -p "<PROJECT_PATH>/.ai/memory"
> ```
> If `<PROJECT_PATH>/.ai/memory/index.md` does not exist, create it with:
> ```markdown
> # Memory Index
> 
> > Auto-maintained by the agent. Do not edit manually.
> 
> | File | Category | Tags | Summary |
> |------|----------|------|---------|
> ```
> Verify the directory and index.md exist with the table header.
>
> 3. **Managed block — lightweight check.** Check if the root instruction file already contains `<!-- BEGIN: local.agent-memory -->` and `<!-- END: local.agent-memory -->` markers. If both markers exist, report "managed block already present" and skip. Only create the block if it does not exist:
>
> First, resolve the root instruction file (see Sub-Agent Discipline).
>
> Then read the installed memory text from the first existing path:
> - `<PROJECT_PATH>/.claude/skills/local.agent-memory/AGENTS.md`
> - `<PROJECT_PATH>/.github/skills/local.agent-memory/AGENTS.md`
> - `<PROJECT_PATH>/.agents/skills/local.agent-memory/AGENTS.md`
> - `<PROJECT_PATH>/.windsurf/skills/local.agent-memory/AGENTS.md`
> - `<PROJECT_PATH>/.roo/skills/local.agent-memory/AGENTS.md`
>
> Append the managed block to the resolved root instruction file:
> ```markdown
> <!-- BEGIN: local.agent-memory -->
> [memory instruction content copied from the installed local.agent-memory/AGENTS.md]
> <!-- END: local.agent-memory -->
> ```
>
> Return a summary of what was installed, scaffolded, and whether the managed block was created or already present.

If the sub-agent reports failure, stop and tell me.

### 8c) Explain runtime behavior clearly

When memory is enabled, explain:
- Agents must check `.ai/memory/index.md` before task work and read relevant entries.
- Agents must propose memory writeback only after task completion when a non-obvious lesson was learned.
- `.ai/memory/` and `.ai/memory/index.md` were scaffolded during setup.
- Memory files are Markdown and should be committed so the team shares lessons.

This ensures memory behavior is loaded from the root instruction surface and cannot be silently skipped.

---

## Step 9: OpenSrc Source Context (Optional)

Run this step after Step 8.

Use this deterministic state model:

- `OPENSRC_ITEM = "local.opensrc-source-context"`
- `HAS_OPENSRC_ITEM = "local.opensrc-source-context" in ALREADY_INSTALLED`
- `HAS_OPENSRC_BIN = command -v opensrc succeeds`

### 9a) Ask whether to enable OpenSrc guidance

If `HAS_OPENSRC_ITEM` is `false`, ask exactly once:

> Would you like to enable **OpenSrc source context guidance**? This adds optional instructions for using `opensrc` to fetch and inspect dependency source code when docs and types are not enough.

- If user says **NO**: set `OPENSRC_ENABLED = false` and go to Step 10.
- If user says **YES**: set `OPENSRC_ENABLED = true` and continue.

If `HAS_OPENSRC_ITEM` is `true`, do not ask; set `OPENSRC_ENABLED = true` and continue.

### 9b) Install OpenSrc instruction item (if enabled)

When `OPENSRC_ENABLED = true`, **delegate to a sub-agent:**

> Set up OpenSrc for `<PROJECT_PATH>`:
>
> 1. Install the instruction item (skip if already in `.skills-lock.json`):
> ```bash
> <CLI> install local.opensrc-source-context --target "<PROJECT_PATH>" --agent <AGENT_1> --agent <AGENT_2> --yes
> ```
> Verify it appears in `.skills-lock.json`. If missing, return failure.
>
> 2. Check if the `opensrc` CLI is available:
> ```bash
> command -v opensrc
> ```
>
> Return whether the item was installed (or already present) and whether `opensrc` is in PATH.

If the sub-agent reports the item failed to install, stop and tell me.

If `opensrc` is not in PATH, ask me whether to install it:

```bash
npm install -g opensrc
```

- If I approve, **delegate the install to a sub-agent** and re-check `command -v opensrc`.
- If install fails, report the error and continue setup (do not fail the whole setup).
- If I decline install, continue setup and note that only guidance was installed.

### 9c) Explain runtime behavior clearly

When OpenSrc guidance is enabled, explain:
- Use `opensrc` only when dependency internals are needed.
- `opensrc path <package>` can be used inside shell substitutions for `rg`, `cat`, and `find`.
- Third-party cached source should be treated as read-only analysis context.

---

## Step 10: Summary & Next Steps

After completing all steps, provide a clear summary:

**Installed skills:** List each skill name and where it was installed (full path).

**User Profile AGENTS.md:** State whether `~/AGENTS.md` was created, merged, or skipped.

**Project AGENTS.md:** State whether `<PROJECT_PATH>/AGENTS.md` was created or updated by the agentsmd-init skill.

**Taste Setup:** State whether it was enabled or skipped. If enabled, include:
- whether both `local.taste-setup` and `local.taste-developer` are installed.

**Agent Memory:** State whether it was enabled or skipped. If enabled, include:
- whether both `local.agent-memory` and `local.agent-memory-workflow` are installed,
- which root instruction file was updated,
- whether the `local.agent-memory` managed block was appended or updated in place,
- and that `.ai/memory/` plus `.ai/memory/index.md` were scaffolded.

**OpenSrc Source Context:** State whether it was enabled or skipped. If enabled, include:
- whether `local.opensrc-source-context` is installed,
- whether the `opensrc` CLI is available in PATH,
- and whether CLI install was run or deferred.

**Lock file:** Explain that `.skills-lock.json` was created in `<PROJECT_PATH>` and can be committed to version control so teammates can restore the same skills with:

    <CLI> install

This reads the lock file and reinstalls everything listed in it.

**Ongoing maintenance tips:**
- View installed skills: `cat "<PROJECT_PATH>/.skills-lock.json"`
- Share with team: commit `.skills-lock.json`; teammates run `<CLI> install`
- Update skills from upstream: `cd "<REGISTRY_PATH>" && bin/skill update && bin/skill sync`
- Uninstall a skill: `<CLI> uninstall <SKILL_NAME> --target "<PROJECT_PATH>"`
- Browse more skills: `<CLI> list` or `<CLI> search <KEYWORD>`

If I used the temporary clone option, ask whether I want to keep `/tmp/skills-registry`, move it to a permanent location, or delete it. Explain that future restore/update/uninstall commands require access to a skills-registry clone, so deleting means re-cloning later.
