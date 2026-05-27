# Skills Registry Setup Prompt

> **Copy and paste everything below the line into any AI coding assistant to get guided through installing skills and setting up AGENTS.md for your project.**

---

You are helping me set up AI coding skills and behavioral guidelines for my project. Guide me through this interactively, one step at a time. Do NOT proceed to the next step until I respond. Present each step clearly and wait for my input.

## Context You Need

The **skills-registry** (https://github.com/knowttl/awesome-ai) is a CLI tool + content monorepo for managing reusable AI coding skills. It has a zero-dependency CLI (pure Bash + PowerShell) that installs skill files into project-local directories for multiple AI coding assistants.

You will clone this registry, read it to understand how it works, discover available skills dynamically, and guide me through installation.

**Prerequisite:** You must have the ability to run shell commands and read files to follow this prompt. If you cannot execute commands or access the filesystem, stop and tell me.

---

## Step 1: Environment Check

Ask me these questions (present them as a numbered list and wait for my answers):

1. Which AI coding assistant(s) am I using? (Common options: Claude Code, GitHub Copilot, Cursor, Cline, OpenCode, Codex, Windsurf, Roo Code)
2. What is the absolute path to my project's root directory?
3. Do I already have the skills-registry cloned locally?
   - If YES: ask for the path to the clone.
   - If NO: present these two options and ask which I prefer:
     - **Option A** — Clone it locally for full CLI access (recommended): `git clone https://github.com/knowttl/awesome-ai.git ~/skills-registry`
     - **Option B** — Temporary clone just for this setup (clone to `/tmp/skills-registry`, keep it through AGENTS.md setup, then ask before deleting it)

Store my answers as variables for later steps:
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

---

## Step 3: Skill Selection

**CRITICAL: Only present skills that actually exist in `registry.json`. Do NOT invent, fabricate, or hallucinate skill names. Every skill name you show must be an exact `name` value from the parsed JSON.**

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

Based on my selections, generate and execute the install commands.

**Pre-flight (if the registry was just cloned or hasn't been synced):**

    cd "<REGISTRY_PATH>" && bin/skill sync

**Determine the correct `--agent` flag values.** Look up each of my selected assistants in the `AGENT_TABLE` from `agents.sh`. The first field (`name`) is what gets passed to `--agent`. Build the flags as `--agent <name>` repeated for each assistant. Remember: if the user said "Roo Code", the `--agent` value is `roo` (not `roo-code`).

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

Ask me:

1. Would you like to set up an `AGENTS.md` file for your project? This provides behavioral guidelines that make AI coding assistants produce better code.
2. Does your project already have an `AGENTS.md` (or `.github/copilot-instructions.md`, `CLAUDE.md`, or similar instruction file)?

Before creating or merging instructions, review the current project context. At minimum, inspect existing instruction files, the README, package/build/test configuration files, and any architecture docs. Use that context to avoid generic or contradictory guidance.

**If I say NO to question 1 (don't want AGENTS.md):** Skip to Step 6.

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

## Step 6: Summary & Next Steps

After completing all steps, provide a clear summary:

**Installed skills:** List each skill name and where it was installed (full path).

**AGENTS.md:** State whether it was created, merged, or skipped.

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
