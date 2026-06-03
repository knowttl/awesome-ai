# Skills Registry Setup Prompt

> **Copy and paste everything below the line into any AI coding assistant to get guided through installing skills and setting up AGENTS.md for your project.**

## What This Does

This prompt guides you through an interactive setup process with your AI coding assistant:

1. **Environment detection** — auto-detects your AI assistant, project path, registry location, and existing installations, then confirms with you
2. **Registry discovery** — reads the skills-registry to find available skills
3. **Skill selection** — presents compatible skills grouped by source, lets you pick
4. **Installation** — runs the CLI commands to install selected skills into your project
5. **AGENTS.md setup** — optionally creates or merges behavioral guidelines for your AI assistant
6. **Agent memory** — optionally installs a persistent memory system so your AI learns from past mistakes
7. **Summary** — confirms what was installed and provides maintenance commands

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

If I say I'm happy, skip to Step 5 (AGENTS.md setup) — but you MUST still proceed through Steps 5 and 6 for anything not yet configured. **Step 6 (Agent Memory) is required regardless of my answer here** unless both `local.agent-memory` AND `local.agent-memory-workflow` are already in `ALREADY_INSTALLED`. Do not silently skip the Agent Memory question.

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

## Step 5: AGENTS.md Setup

**If an existing AGENTS.md (or equivalent) was detected in Step 2**, tell me what was found and ask whether I want to review it against the baseline for any missing guidelines. If I say no, skip to Step 6.

**If no instruction file was detected**, ask me:

1. Would you like to set up an `AGENTS.md` file for your project? This provides behavioral guidelines that make AI coding assistants produce better code.
2. Does your project already have an `AGENTS.md` (or `.github/copilot-instructions.md`, `CLAUDE.md`, or similar instruction file)?

Before creating or merging instructions, review the current project context. At minimum, inspect existing instruction files, the README, package/build/test configuration files, and any architecture docs. Use that context to avoid generic or contradictory guidance.

**If I say NO to question 1 (don't want AGENTS.md):** Skip to Step 6 (Agent Memory).

**If I say YES to question 1:**

First, read the baseline AGENTS.md file from the registry at this path:

`<REGISTRY_PATH>/instructions/local.baseline-agents/AGENTS.md`

This is the source of truth for the baseline guidelines. Read it in full before proceeding.

**If the project has NO existing AGENTS.md:**

If equivalent instruction files exist, read them first and ask whether I want a new root `AGENTS.md` that complements them or merge guidance into the existing file. Do not duplicate.

Present two options:

- **Option A: Start with the baseline** — Write the content from `local.baseline-agents/AGENTS.md` to `<PROJECT_PATH>/AGENTS.md`. Then ask if I want to add project-specific sections by interviewing me about my language/framework, testing conventions, code style, architecture, and constraints.

- **Option B: Write fully custom guidelines** — Interview me to create tailored guidelines from scratch:
  1. What language(s) and framework(s) does this project use?
  2. What testing framework and conventions?
  3. Preferred code style? (functional vs OOP, naming, file organization)
  4. Architectural patterns? (clean architecture, DDD, hexagonal, etc.)
  5. What should the AI absolutely NEVER do?
  6. Domain-specific rules?

  Then generate an AGENTS.md incorporating my answers with the baseline principles.

**If the project ALREADY HAS an AGENTS.md (or equivalent):**

1. Read the existing file in full.
2. Review the project context.
3. Compare the existing file against the baseline from the registry.
4. Identify which baseline principles are NOT already covered (check for semantic equivalence, not just keywords).
5. Propose appending only the missing sections at the end under a heading like `## Additional Guidelines (from skills-registry baseline)`.
6. Show me exactly what will be added (just the new sections, not the full file).
7. Ask for my approval before writing.

---

## Step 6: Agent Memory (Required Checkpoint)

**This step is mandatory on every setup run.** You MUST always execute Step 6 logic, even if the user skipped installs in Step 3 or skipped AGENTS.md work in Step 5.

Use this deterministic state model:

- `MEMORY_ITEMS = ["local.agent-memory", "local.agent-memory-workflow"]`
- `HAS_MEMORY_INSTRUCTION = "local.agent-memory" in ALREADY_INSTALLED`
- `HAS_MEMORY_WORKFLOW = "local.agent-memory-workflow" in ALREADY_INSTALLED`
- `MEMORY_FULLY_INSTALLED = HAS_MEMORY_INSTRUCTION && HAS_MEMORY_WORKFLOW`

### 6a) Decide enablement

If `MEMORY_FULLY_INSTALLED` is `false`, ask exactly once:

> Would you like to enable **Agent Memory** for this project? It helps agents avoid repeat failures by checking prior lessons before tasks and proposing new memory entries after non-obvious issues are solved.

- If user says **NO**: set `MEMORY_ENABLED = false` and go to Step 7.
- If user says **YES**: set `MEMORY_ENABLED = true` and continue.

If `MEMORY_FULLY_INSTALLED` is `true`, do not ask; set `MEMORY_ENABLED = true` and continue.

### 6b) Ensure both memory components are installed

When `MEMORY_ENABLED = true`, you MUST guarantee both items are installed. Install only missing items (idempotent behavior):

```bash
"<REGISTRY_PATH>/bin/skill" install local.agent-memory --target "<PROJECT_PATH>" --agent <AGENT_1> --agent <AGENT_2> --yes
"<REGISTRY_PATH>/bin/skill" install local.agent-memory-workflow --target "<PROJECT_PATH>" --agent <AGENT_1> --agent <AGENT_2> --yes
```

After installation commands, verify both now appear in `.skills-lock.json`. If either is still missing, report failure and stop instead of silently continuing.

### 6c) Guarantee always-on memory behavior from root instructions

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

### 6d) Explain runtime behavior clearly

When memory is enabled, explain:
- Agents must check `.ai/memory/index.md` before task work and read relevant entries.
- Agents must propose memory writeback only after task completion when a non-obvious lesson was learned.
- `.ai/memory/` is created automatically on first write.
- Memory files are Markdown and should be committed so the team shares lessons.

This ensures memory behavior is loaded from the root instruction surface and cannot be silently skipped.

---

## Step 7: Summary & Next Steps

After completing all steps, provide a clear summary:

**Installed skills:** List each skill name and where it was installed (full path).

**AGENTS.md:** State whether it was created, merged, or skipped.

**Agent Memory:** State whether it was enabled or skipped. If enabled, include:
- whether both `local.agent-memory` and `local.agent-memory-workflow` are installed,
- which root instruction file was updated,
- whether the `local.agent-memory` managed block was appended or updated in place,
- and that `.ai/memory/` is created automatically on first write.

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
