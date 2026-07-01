---
name: design-system
description: Generate a design system (design.md, design-guidelines.md, design-components.md, design-preview.html) from reference materials — images, PDFs, links, descriptions — or reverse-engineer one from an existing codebase and flag UI drift for remediation.
---

# Design System Generator

Analyze the user's design references, an existing codebase, or both, and produce design system documentation another agent or developer can build against.

## Modes

| Mode | Trigger | Output |
|------|---------|--------|
| **Reference-based** | User supplies images, PDFs, links, text descriptions, or existing code as the source of truth | `design.md`, `design-guidelines.md`, `design-components.md`, `design-preview.html` |
| **Codebase audit** | User asks to derive/document a design system *from* their existing project, with no other references given | Same 3 docs + preview, derived from dominant patterns in the code, **plus** `design-remediation.md` flagging drift |
| **Hybrid** | User supplies references (or already has the docs) *and* wants the existing codebase checked against them | The 3 docs + preview (from references) **plus** `design-remediation.md` auditing the codebase against them |

If the user's request is ambiguous about which mode, ask.

## Inputs

Accept ANY combination of:
- **Images**: Screenshots of UIs, mockups, design tool exports
- **PDFs**: Brand guidelines, style guides, design specs
- **Links**: URLs to design system documentation, component libraries, or live websites
- **Text descriptions**: Written descriptions of the design language
- **Existing code**: CSS files, theme configs, Tailwind configs, design tokens, component source — as a direct reference (Reference-based) or as the scan target (Codebase audit / Hybrid)

If the user provides a link, use WebFetch to retrieve the content. If they provide a file path, read the file.

## Output

Generate files inside a `DESIGN/` folder at the project root. Create the folder if it does not exist.

1. **DESIGN/design.md** — Token Reference
2. **DESIGN/design-guidelines.md** — Accessibility & Do's/Don'ts
3. **DESIGN/design-components.md** — Component Specs
4. **DESIGN/design-preview.html** — Living style guide: a browsable HTML rendering of the tokens and components, generated in every mode
5. **DESIGN/design-remediation.md** — Drift Report (Codebase audit / Hybrid mode only)

## Workflow

1. **Determine mode** — Reference-based, Codebase audit, or Hybrid (see Modes above). This governs every step below.
2. **Gather source material**:
   - *Reference-based*: Collect all materials from the user (read files, fetch URLs). If `DESIGN/design.md` etc. already exist and the user is updating rather than starting fresh, read those as references too.
   - *Codebase audit / Hybrid*: Glob the project for style sources — CSS/SCSS/LESS, Tailwind/PostCSS config, CSS-in-JS (styled-components, Emotion), CSS custom properties, component files, and any existing token files (JSON/YAML). Read every match. If the user hasn't scoped it, scan the whole repo excluding `node_modules`, build output, and vendored code.
3. **Derive or confirm the system**:
   - *Reference-based*: the provided references are the system.
   - *Codebase audit*: for every category in [`references/token-spec.md`](references/token-spec.md) (colors, typography, spacing, shape, elevation, motion), tally every distinct value found and its occurrence count. The most-frequent value per category becomes the canonical token; note its frequency so the choice is auditable.
   - *Hybrid*: the references define the canonical system regardless of what's more common in the code — the codebase tally is used only for drift comparison in the next step, never to override a reference-defined token.
4. **Detect drift** (Codebase audit / Hybrid only): any category or component where more than one value serves the same semantic purpose is drift. Compare every non-canonical value against the token it should map to. Follow [`references/remediation-spec.md`](references/remediation-spec.md) for how to size severity and write this up.
5. **Clarify unknowns** — Identify critical gaps using the Clarification Step below. Ask before generating. Skip questions you can confidently infer (see step 3) — note "(inferred)" instead.
6. **Detect platform context** — Determine target platform (web, mobile, or both). This governs which sections to include (gestures vs. pointer interaction, dp vs. px/rem, touch targets).
7. **Check for existing files** — If any of the `DESIGN/*` output files (including `design-preview.html`) already exist, ask the user whether to overwrite or skip each conflicting file individually. Do not silently overwrite.
8. **Generate all files** — Follow [`references/token-spec.md`](references/token-spec.md), [`references/guidelines-spec.md`](references/guidelines-spec.md), and [`references/components-spec.md`](references/components-spec.md) first — `design-preview.html` renders their output, so generate it last, per [`references/preview-spec.md`](references/preview-spec.md). In Codebase audit / Hybrid mode, also follow [`references/remediation-spec.md`](references/remediation-spec.md).
9. **Confirm before writing** — Present a brief pre-write summary: file names, output paths, section count per file, and (if applicable) drift-issue count. Ask the user to confirm before saving anything to disk.
10. **Write confirmed files** to the specified directory.
11. **Update AGENTS.md** if it exists — see [`references/agentsmd-integration.md`](references/agentsmd-integration.md).
12. **Summarize** — Report: system name, token count, component count, files written (including the preview), drift-issue count by severity (if a remediation file was generated), whether AGENTS.md was updated. If no `AGENTS.md` was found, note it and tell the user they can add the design system rules manually.

## Clarification Step

Before generating, scan the references/codebase for the following. If any are missing or ambiguous, ask the user. If a value can be confidently inferred, use it and note "(inferred)" — do not ask unnecessarily.

| Unknown | Question to ask |
|---------|----------------|
| System name | "What should the design system be named?" |
| Primary brand color | "What is the primary brand color (hex)?" |
| Target platform | "Is this for web, mobile (iOS/Android), or both?" |
| Unit system | "Should measurements use dp/sp (mobile) or px/rem (web)?" |
| Dark mode support | "Does this design system support dark mode?" |
| Scan scope (Codebase audit / Hybrid only) | "Which directories or file types should I scan for existing design patterns? Default: the whole repo, excluding `node_modules` and build output." |

## File Specifications

Each generated file must begin with a metadata comment on line 1:

```
<!-- Generated by design-system skill | [YYYY-MM-DD] | Sources: [comma-separated filenames/URLs, or "codebase scan"] -->
```

Full per-file specs are disclosed reference — read the one you need at Workflow step 8, not before:

- [`references/token-spec.md`](references/token-spec.md) — `design.md` sections, tables, and required token categories
- [`references/guidelines-spec.md`](references/guidelines-spec.md) — `design-guidelines.md` sections (accessibility, gestures/pointer, content, do's/don'ts)
- [`references/components-spec.md`](references/components-spec.md) — `design-components.md` structure and the full component checklist
- [`references/preview-spec.md`](references/preview-spec.md) — `design-preview.html` structure, token→CSS mapping, and the theme toggle
- [`references/remediation-spec.md`](references/remediation-spec.md) — `design-remediation.md` structure and severity scale (Codebase audit / Hybrid only)

## General Rules

- Be specific: measurements in dp/sp/px, hex colors, CSS box-shadow values
- If a value cannot be determined from the source material (references or codebase scan), make a reasonable inference based on the design language and note it with "(inferred)"
- Use tables over prose — keep scannable
- Prioritize completeness over brevity — do not truncate sections to meet an arbitrary line count; files may exceed 400 lines for complex design systems
- Each file must cross-reference the others in its opening blockquote
- Separate components with horizontal rules (`---`)

## AGENTS.md Integration

See [`references/agentsmd-integration.md`](references/agentsmd-integration.md) for the full procedure — updating an existing `## Design System` section, appending a new one, and the case where `AGENTS.md` doesn't exist.

## Reviewing & Editing the Preview

`design-preview.html` is a rendering of the doc files, not an independent artifact — it has no authority of its own. When the user reviews it and asks for a change ("make the primary color darker", "this button looks too small"):

1. Edit the underlying source first: `design.md` for tokens, `design-components.md` for component specs/measurements, `design-guidelines.md` for rules.
2. Regenerate `design-preview.html` from the updated source per [`references/preview-spec.md`](references/preview-spec.md).

Never hand-edit the HTML/CSS in `design-preview.html` directly — that would fork the preview from the documented system and the two would silently drift apart.
