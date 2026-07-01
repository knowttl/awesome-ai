---
name: create-glossary
description: >
  Create or update GLOSSARY.md to document project-specific terms and jargon,
  and wire AGENTS.md to point agents at it. Use when the user wants to create
  a glossary, update an existing one, or just implemented a feature that
  introduces new domain vocabulary worth capturing.
---

# Create Glossary

Maintain `GLOSSARY.md` at the repository root: a short reference of
project-specific terms so agents stop guessing at jargon and stop asking the
user to re-explain it. Two entry points, decided by whether the file exists.

## Workflow

### 1. Determine mode

Check the repo root for `GLOSSARY.md`.

- Missing → **Init mode** (step 2).
- Present → **Update mode** (step 5).

Completion criterion: mode is decided (init or update) before any other step
runs.

### 2. Init mode: survey the project

Read, in this order: `README*`, `AGENTS.md`/`CLAUDE.md`, package manifests,
top-level directory structure, and a small number of representative
domain/model files (the ones that name core concepts, not random leaf files).
Draft a candidate term list from what you find.

Filter every candidate through the **term-worthiness filter** (Reference,
below). Drop anything that fails it before continuing.

Completion criterion: every surviving candidate is labeled either
**confident** (its meaning is clear from context) or **uncertain**.

### 3. Init mode: interview on uncertain terms only

Ask the user about **uncertain** terms in one batched question — never
individually, and never re-confirm terms you're already confident about.
Drop a candidate if the user says it isn't worth documenting.

Completion criterion: every uncertain candidate is resolved — either has a
user-confirmed definition, or was dropped.

### 4. Init mode: write GLOSSARY.md

Write the file using the **template** (Reference, below): every confirmed
term included, alphabetically sorted, one line each. Then go to step 6.

Completion criterion: `GLOSSARY.md` exists, matches the template shape, and
contains every confirmed term.

### 5. Update mode: detect and add new terms

Trigger this step two ways: right after finishing a feature or change in the
current session, or on direct request ("update the glossary").

Scan what actually changed (git diff, files touched this session) for new
project-specific vocabulary. Run each candidate through the same
**term-worthiness filter**.

For each surviving candidate, check whether it already exists in
`GLOSSARY.md`:
- **New term** → add it now, alphabetically, without asking permission first.
- **Existing term, same meaning** → skip; it's already documented.
- **Existing term, conflicting meaning** → do not overwrite or duplicate.
  Flag the conflict to the user and let them decide.

Completion criterion: every new project-specific term introduced by the
change is either written to the file or deliberately excluded, and every
naming conflict is flagged — not one silently guessed.

Immediately after writing, tell the user what you added in a single batched
message — even if several terms were introduced — not one message per term:
("Added **X**, **Y** to GLOSSARY.md — let me know if the definitions need
adjusting"). Write first, review after — don't gate the write on a
pre-approval round-trip.

### 6. Wire AGENTS.md (both modes, run once)

Check `AGENTS.md` for a `## Glossary` section.

- **Section already present** → skip. This step is idempotent; never insert
  a second one.
- **`AGENTS.md` exists, no section** → append the exact block from the
  Reference below.
- **`AGENTS.md` doesn't exist** → create it containing only that block.

Completion criterion: the repo has exactly one `## Glossary` section in
`AGENTS.md`, pointing at `GLOSSARY.md`.

## Reference

### Term-worthiness filter

Include a candidate only if it is **project-specific**: business jargon,
custom concepts, internal names, or acronyms that only make sense in this
codebase. Exclude generic technical vocabulary that any developer already
knows — "API", "database", "function", "endpoint" — even if it appears
often. A term earns a slot by being confusing *without* this project's
context, not by being important in general.

### GLOSSARY.md template

```markdown
# Glossary

Project-specific terms. Check here before guessing at unfamiliar
terminology, or ask the user to add a missing term.

## Terms

- **Term**: One- or two-sentence definition, in plain language.
- **Another Term**: Definition here.
```

Entries are a single alphabetically-sorted list under `## Terms` — no
letter-group sub-headings, no extra metadata fields (aliases, categories,
provenance).

### AGENTS.md Glossary section (exact text)

```markdown
## Glossary

This project maintains a `GLOSSARY.md` at the repository root defining
project-specific terms. If you encounter a term you're unsure about, or
that seems to carry a project-specific meaning, check `GLOSSARY.md` before
guessing or asking the user. If your work introduces new domain
terminology, invoke the `create-glossary` skill to capture it.
```

Insert this as its own top-level section — distinct from an "Agent Rules"
section if one exists. Do not paraphrase or shorten it; use it verbatim so
future runs of this skill can detect it by exact heading match.

### Worked example: init mode

> Survey finds "tenant", "shard key", and "playbook" used repeatedly in
> `README.md` and `src/models/`. "Tenant" and "shard key" are used
> consistently and defined by context — confident. "Playbook" is used in
> two different files with what looks like two different meanings —
> uncertain. Ask the user only about "playbook"; write the other two
> straight into `GLOSSARY.md`.

### Worked example: update mode after a feature

> You just implemented a "cooldown window" rate-limiting feature. It
> introduces the term "cooldown window", which is project-specific (not a
> generic term). `GLOSSARY.md` exists and has no entry for it. Add:
> `- **Cooldown Window**: The period after a rate-limited request during
> which further requests from the same client are rejected.` Then tell the
> user: "Added **Cooldown Window** to GLOSSARY.md — let me know if that
> definition needs adjusting."

### Worked example: conflicting definition

> `GLOSSARY.md` already defines "Worker" as "a background job processor."
> The new feature introduces a "Worker" meaning a physical warehouse
> employee record. Do not overwrite the existing entry or add a duplicate
> heading. Flag it: "The new feature uses 'Worker' to mean a warehouse
> employee, but GLOSSARY.md already defines it as a background job
> processor. How should I disambiguate these — rename one, or note both
> meanings under one entry?"
