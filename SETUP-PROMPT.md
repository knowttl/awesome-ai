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

---

You are helping me set up AI coding skills and behavioral guidelines for my project. Guide me through this interactively, one step at a time. Do NOT proceed to the next step until I respond. Present each step clearly and wait for my input.

**Principle: Detect first, confirm second.** For every piece of information you need, attempt to auto-detect it from the filesystem before asking me. Present your findings and ask me to confirm or correct — do not make me manually provide information you can discover yourself.

## Context You Need

The **skills-registry** (https://github.com/knowttl/awesome-ai) is a CLI tool + content monorepo for managing reusable AI coding skills. It has a zero-dependency CLI (pure Bash + PowerShell) that installs skill files into project-local directories for multiple AI coding assistants.

You will clone this registry, read it to understand how it works, discover available skills dynamically, and guide me through installation.

**Prerequisite:** You must have the ability to run shell commands and read files to follow this prompt. If you cannot execute commands or access the filesystem, stop and tell me.

---

## Step 1: Environment Detection

**Detect first, then confirm.** Do NOT ask me questions you can answer yourself. Run detection commands, present your findings, and ask me to confirm or correct.

### 1a: Detect the AI assistant

You already know which AI assistant you are. State it:
> "I've detected that I'm running as **[assistant name]**."

If you support multiple assistant modes or the user might use others alongside you, ask: "Are there other AI assistants you also use for this project?"

### 1b: Detect the project directory

Run `pwd` (or equivalent) to determine the current working directory. Then verify it looks like a project root by checking for common indicators: `.git/`, `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Makefile`, `README.md`, or `src/`.

Present your finding:
> "Your current directory is `<path>`. This appears to be a project root (found `.git/`, `package.json`, etc.)."

Ask: "Is this the project you want to set up skills for, or is it a different path?"

### 1c: Detect the skills-registry

Search for an existing skills-registry clone by checking these locations in order:

```bash
# Check common clone locations
for dir in ~/skills-registry ~/awesome-ai /tmp/skills-registry ./; do
  if [[ -f "$dir/bin/skill" ]] && [[ -f "$dir/registry.json" ]]; then
    echo "Found: $dir"
    break
  fi
done
```

Also check if the current directory IS the skills-registry (if `bin/skill` exists in `pwd`).

**If found**, confirm:
> "I found the skills-registry at `<path>`."

**If NOT found**, tell me and explicitly ask where to clone it. Do NOT pick a location yourself — present both options and wait for my choice:
> "I couldn't find the skills-registry locally. Where would you like me to clone it? Please pick one:"
> - **Option A — Persistent (recommended):** `~/skills-registry` — kept on disk, reusable across projects and sessions, easy to `bin/skill update` later.
> - **Option B — Temporary:** `/tmp/skills-registry` — wiped on reboot, fine for a one-off trial install but you will have to re-clone next time.
> - **Option C — Custom path:** tell me a path and I will clone there instead.
>
> "Which would you like (A, B, or a custom path)?"

Wait for my explicit answer before running `git clone`. Do not assume the recommended option.

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
for f in AGENTS.md .github/copilot-instructions.md CLAUDE.md .cursorrules .windsurfrules .clinerules; do
  [[ -f "<PROJECT_PATH>/$f" ]] && echo "Found: $f"
done

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
- `AGENT_NAMES` = one or more agent identifiers
- `PROJECT_PATH` = my project root
- `REGISTRY_PATH` = path to the skills-registry clone

---

## Step 2: Discover the Registry

Once `REGISTRY_PATH` is available (either from an existing clone or after cloning), do the following **before presenting any skills to me**:

1. **Read the README** at `<REGISTRY_PATH>/README.md` to understand how the CLI works, what commands are available, and the project structure.

2. **Read the agent path registry** at `<REGISTRY_PATH>/bin/lib/agents.sh`. This file contains the `AGENT_TABLE` array that maps agent names to their `--agent` flag values and project install paths. Parse this to build the supported assistants table dynamically. The format is: `name|project_path|global_suffix|detection_dirs|detection_bins`. The `name` field is what you pass to `--agent`.

3. **Read `registry.json`** at `<REGISTRY_PATH>/registry.json`. This is the generated index of all available skills and instructions. If it doesn't exist, run:

       cd "<REGISTRY_PATH>" && bin/skill sync

4. **Parse each item** in `registry.json`. Each entry has:
   - `name`: the skill identifier used with `bin/skill install`
   - `type`: `skill`, `agent`, or `instruction`
   - `description`: one-line summary
   - `tags`: searchable keywords
   - `targets`: which AI assistants this item supports (these correspond to the `name` column in `AGENT_TABLE`)
   - `files`: what gets installed

5. **Filter for compatibility.** Cross-reference each item's `targets` array against my selected assistant(s) from Step 1. An item is installable only if my assistant appears in its `targets` list.

   **Important name mapping:** The `targets` values in `registry.json` do NOT always exactly match the `name` field in `AGENT_TABLE`. Known difference: targets use `roo-code` but the `--agent` flag value is `roo`. When filtering compatibility, treat `roo-code` in targets as matching the `roo` agent. For all other agents, the names match exactly between targets and AGENT_TABLE.

6. **Optionally read individual SKILL.md files** at `<REGISTRY_PATH>/<item.path>/SKILL.md` if I ask for more detail about a specific skill. These contain the full instructions that get installed.

7. **Build `ALREADY_INSTALLED` list.** Using the installation data detected in Step 1d (lock file + agent directories), cross-reference against `registry.json` to classify each installed item as known (in registry) or unrecognized (manually installed / old version). If everything compatible is already installed, tell me: "All compatible skills are already installed. You can still update them with `bin/skill update` or add new ones as they become available."

---

## Step 3: Skill Selection

**CRITICAL: Only present skills that actually exist in `registry.json`. Do NOT invent, fabricate, or hallucinate skill names. Every skill name you show must be an exact `name` value from the parsed JSON.**

**If existing installations were detected in Step 2**, present the results first:

> **Already installed:** List the items found, grouped by source (obra.superpowers, mattpocock.skills, local). Mark each as ✓ installed.
>
> **Not yet installed:** List compatible items that are NOT in `ALREADY_INSTALLED`. These are what you can add.

Then ask: "Would you like to install any of the items that aren't installed yet, or are you happy with your current setup?"

If I say I'm happy, proceed to Step 5 (User Profile AGENTS.md) — continue through all remaining steps for anything not yet configured. **Step 8 (Agent Memory) is required regardless of my answer here** unless both `local.agent-memory` AND `local.agent-memory-workflow` are already in `ALREADY_INSTALLED`. Do not silently skip the Agent Memory question.

**If nothing is installed yet (fresh project)**, present all compatible skills as before:

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

Based on my selections, generate and execute the install commands. **Skip any items that are already in `ALREADY_INSTALLED`** — only install new selections.

**Pre-flight (if the registry was just cloned or hasn't been synced):**

    cd "<REGISTRY_PATH>" && bin/skill sync

**Determine the correct `--agent` flag values.** Look up each of my selected assistants in the `AGENT_TABLE` from `agents.sh`. The first field (`name`) is what gets passed to `--agent`. Build the flags as `--agent <name>` repeated for each assistant. Remember: if the user said "Roo Code", the `--agent` value is `roo` (not `roo-code`).

**Deduplication note:** GitHub Copilot can read skills from both `.github/skills` and `.claude/skills`. The CLI automatically deduplicates: when both `claude-code` and `github-copilot` are selected, it only installs to `.claude/skills` (serving both agents) and skips `.github/skills` to avoid duplicated files. You should still pass both `--agent claude-code --agent github-copilot`; the CLI handles the dedup internally. If `github-copilot` is selected alone (without `claude-code`), it installs to `.github/skills` as normal.

**Install each selected skill individually.** This is safest because different skills may support different subsets of assistants:

    "<REGISTRY_PATH>/bin/skill" install <SKILL_NAME> --target "<PROJECT_PATH>" --agent <AGENT_1> --agent <AGENT_2> --yes

For each skill, only include `--agent` flags for assistants that appear in that skill's `targets` array from `registry.json`.

**Optional reusable profile:** Only suggest creating a profile if I explicitly ask for a reusable bundle. A profile applies the same agent flags to every item, so only use one when all selected skills share the same compatibility. The profile format is:

    name: my-setup
    description: Custom skill bundle.
    items:
      - name: <skill-name>
        source: local

Save to `<REGISTRY_PATH>/profiles/<name>.yaml` and install with:

    "<REGISTRY_PATH>/bin/skill" install --profile <name> --target "<PROJECT_PATH>" --agent <AGENT> --yes

**After running commands:** List the installed directories to confirm success. Show me what was created.

---

## Step 5: User Profile AGENTS.md

**Before setting up a project-local AGENTS.md**, ask whether the user wants a **user-level** `AGENTS.md` at `~/AGENTS.md`. This file applies baseline behavioral guidelines across all projects for this AI assistant, not just the current project.

### 5a) Detect existing user profile

Check if `~/AGENTS.md` already exists:

```bash
[[ -f "$HOME/AGENTS.md" ]] && echo "Found: ~/AGENTS.md"
```

### 5b) Ask the user

**If `~/AGENTS.md` does NOT exist:**

> Would you like to install a user profile `AGENTS.md` at `~/AGENTS.md`? This provides baseline behavioral guidelines (think before coding, write the minimum, touch only what you must, etc.) that apply across all projects you work on with AI assistants.

If the user says **YES**:
1. Read `<REGISTRY_PATH>/instructions/local.baseline-agents/AGENTS.md` in full.
2. Write the content to `~/AGENTS.md`.
3. Confirm: "User profile AGENTS.md installed at `~/AGENTS.md`."

**If `~/AGENTS.md` DOES exist:**

> A user profile AGENTS.md already exists at `~/AGENTS.md`. Would you like me to review it against the skills-registry baseline for any missing guidelines?

If the user says YES:
1. Read both `~/AGENTS.md` and `<REGISTRY_PATH>/instructions/local.baseline-agents/AGENTS.md`.
2. Compare and identify which baseline principles are NOT already covered (check for semantic equivalence, not just keywords).
3. Propose appending only the missing sections at the end.
4. Wait for approval before writing.

If the user says **NO** to installing or reviewing the user profile: skip to Step 6.

---

## Step 6: Project AGENTS.md Setup

### 6a) Ask whether to set up a project AGENTS.md

Detect whether any instruction file already exists in `<PROJECT_PATH>` — check `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, `.cursorrules`, `.github/copilot-instructions.md`, `opencode.json`. Present your finding, then ask:

> Would you like to set up or update a project `AGENTS.md`? This provides AI assistants with project-specific behavioral guidelines, conventions, and commands.

If the user says **NO**: skip to Step 7.

If the user says **YES**: continue below.

### 6b) Generate using the agentsmd-init skill

Do NOT manually copy the baseline-agents file. Load the `agentsmd-init` skill and follow its workflow to produce project-specific instructions.

1. Read the full `agentsmd-init` skill at `<REGISTRY_PATH>/skills/local.agentsmd-init/SKILL.md`.

2. Follow the skill's workflow exactly as written, including its branching logic:
   - **Step 1 (Check what exists):** Read any existing instruction files in `<PROJECT_PATH>` — `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, `.cursorrules`, `.github/copilot-instructions.md`, `opencode.json`.
   - **Step 2 (Init vs. update mode):** The skill branches on whether an `AGENTS.md` exists — follow its audit flow for update mode or investigation flow for init mode.
   - **Step 3 (Extract high-signal facts):** Investigate the repo following the skill's priority order. Extract only facts an agent would get wrong without help.
   - **Step 4 (Identify gaps, update mode only):** Compare found facts against the audited file.
   - **Step 5 (Ask questions):** Only if the repo cannot answer something important. Never ask about anything the repo already makes clear.
   - **Step 6 (Write or merge):** Write fresh in init mode or merge audit results in update mode. Apply the filter test to every line: "Would an agent likely miss this without help?"
   - **Step 7 (Verify and summarize):** Final pass for correctness, then summarize what was added, removed, or corrected.

3. After following the skill's workflow, confirm the final state of `<PROJECT_PATH>/AGENTS.md`.

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

If `TASTE_FULLY_INSTALLED` is `true`, do not ask; set `TASTE_ENABLED = true` and continue.

### 7b) Ensure both taste components are installed

When `TASTE_ENABLED = true`, install only missing items (idempotent behavior):

```bash
"<REGISTRY_PATH>/bin/skill" install local.taste-setup --target "<PROJECT_PATH>" --agent <AGENT_1> --agent <AGENT_2> --yes
"<REGISTRY_PATH>/bin/skill" install local.taste-developer --target "<PROJECT_PATH>" --agent <AGENT_1> --agent <AGENT_2> --yes
```

After installation commands, verify both now appear in `.skills-lock.json`. If either is still missing, report failure and stop.

### 7c) Explain runtime behavior clearly

When taste setup is enabled, explain:
- The taste-setup instruction will prompt once on first project interaction (detected by absence of `.ai/taste/taste.md` and `.ai/taste/SKIP`).
- If accepted, the Taste Developer skill begins learning preferences from user feedback.
- If declined, a `.ai/taste/SKIP` file is written to suppress future prompts.
- The user can manually enable later by saying "start taste" or "enable taste developer."

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

### 8b) Ensure both memory components are installed

When `MEMORY_ENABLED = true`, you MUST guarantee both items are installed. Install only missing items (idempotent behavior):

```bash
"<REGISTRY_PATH>/bin/skill" install local.agent-memory --target "<PROJECT_PATH>" --agent <AGENT_1> --agent <AGENT_2> --yes
"<REGISTRY_PATH>/bin/skill" install local.agent-memory-workflow --target "<PROJECT_PATH>" --agent <AGENT_1> --agent <AGENT_2> --yes
```

After installation commands, verify both now appear in `.skills-lock.json`. If either is still missing, report failure and stop instead of silently continuing.

### 8c) Scaffold initial memory vault structure

When `MEMORY_ENABLED = true`, scaffold the vault immediately (do not wait for first write). This must be idempotent:

```bash
mkdir -p "<PROJECT_PATH>/.ai/memory"
```

If `<PROJECT_PATH>/.ai/memory/index.md` does not exist, create it with:

```markdown
# Memory Index

> Auto-maintained by the agent. Do not edit manually.

| File | Category | Tags | Summary |
|------|----------|------|---------|
```

Then verify:
- `<PROJECT_PATH>/.ai/memory/` exists.
- `<PROJECT_PATH>/.ai/memory/index.md` exists and includes the table header.

If verification fails, report failure and stop.

### 8d) Guarantee always-on memory behavior from root instructions

The instruction in agent skill folders is not sufficient by itself for all assistants. You MUST merge memory instructions into the project's root instruction surface.

1. Read installed memory text from one of these paths (first existing path wins):
  - `<PROJECT_PATH>/.claude/skills/local.agent-memory/AGENTS.md`
  - `<PROJECT_PATH>/.github/skills/local.agent-memory/AGENTS.md`
  - `<PROJECT_PATH>/.agents/skills/local.agent-memory/AGENTS.md`
  - `<PROJECT_PATH>/.windsurf/skills/local.agent-memory/AGENTS.md`
  - `<PROJECT_PATH>/.roo/skills/local.agent-memory/AGENTS.md`

2. Resolve root instruction file with this priority:
  - Existing `AGENTS.md`
  - Existing `.github/copilot-instructions.md`
  - Existing `CLAUDE.md`
  - Otherwise create `<PROJECT_PATH>/AGENTS.md`

3. Upsert a managed block (replace if exists, append if missing) using exact markers:

```markdown
<!-- BEGIN: local.agent-memory -->
[memory instruction content copied from installed local.agent-memory/AGENTS.md]
<!-- END: local.agent-memory -->
```

4. Idempotency rule: there must be exactly one begin marker and one end marker after update.

5. Never duplicate free-form sections. On reruns, update the existing managed block in place.

### 8e) Explain runtime behavior clearly

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

When `OPENSRC_ENABLED = true`, ensure `local.opensrc-source-context` is installed. Install only if missing:

```bash
"<REGISTRY_PATH>/bin/skill" install local.opensrc-source-context --target "<PROJECT_PATH>" --agent <AGENT_1> --agent <AGENT_2> --yes
```

After installation, verify the item appears in `.skills-lock.json`. If it does not, report failure and stop.

### 9c) Ensure the `opensrc` CLI exists (if enabled)

When `OPENSRC_ENABLED = true`, check:

```bash
command -v opensrc
```

If missing, ask whether to install it now using npm:

```bash
npm install -g opensrc
```

- If the user approves, run the command and re-check `command -v opensrc`.
- If install fails, report the error and continue setup (do not fail the whole setup).
- If the user declines install, continue setup and note that only guidance was installed.

### 9d) Explain runtime behavior clearly

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

    "<REGISTRY_PATH>/bin/skill" install --target "<PROJECT_PATH>"

This reads the lock file and reinstalls everything listed in it.

**Ongoing maintenance tips:**
- View installed skills: `cat "<PROJECT_PATH>/.skills-lock.json"`
- Share with team: commit `.skills-lock.json`; teammates run `"<REGISTRY_PATH>/bin/skill" install --target "<PROJECT_PATH>"`
- Update skills from upstream: `cd "<REGISTRY_PATH>" && bin/skill update && bin/skill sync`
- Uninstall a skill: `"<REGISTRY_PATH>/bin/skill" uninstall <SKILL_NAME> --target "<PROJECT_PATH>"`
- Browse more skills: `"<REGISTRY_PATH>/bin/skill" list` or `"<REGISTRY_PATH>/bin/skill" search <KEYWORD>`

If I used the temporary clone option, ask whether I want to keep `/tmp/skills-registry`, move it to a permanent location, or delete it. Explain that future restore/update/uninstall commands require access to a skills-registry clone, so deleting means re-cloning later.
