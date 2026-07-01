# AGENTS.md Integration Block

Read this when executing the Workflow step "Update AGENTS.md".

**If `AGENTS.md` exists:**

Check if it already contains a `## Design System` section.

- **Section already exists:** Preserve all custom rules the user has written beneath it. Only update the file links at the top of the section (three links normally, four if a `DESIGN/design-remediation.md` exists — see below). Do not remove or replace any content below the links.
- **Section does not exist:** Append the block below to the end of the file.

```markdown
## Design System

All front-end work **must** follow the project design system. Before writing any UI code, read these files:

- [`DESIGN/design.md`](DESIGN/design.md) — color, typography, spacing, elevation, motion, and layout tokens
- [`DESIGN/design-guidelines.md`](DESIGN/design-guidelines.md) — accessibility requirements, interaction rules, content writing, and do's & don'ts
- [`DESIGN/design-components.md`](DESIGN/design-components.md) — full component specs including variants, measurements, and states

### Rules for Front-End Work

- Use only colors, type scales, spacing values, and shape tokens defined in `DESIGN/design.md`
- Follow the accessibility contrast ratios and touch target sizes in `DESIGN/design-guidelines.md`
- Match component variants, states, and measurements from `DESIGN/design-components.md` exactly
- Do not introduce new visual patterns, ad-hoc spacing, or one-off color values not present in the design system
- If a needed component or token is missing from the design system, flag it to the user before implementing a custom solution
```

**If a `DESIGN/design-remediation.md` file was also generated** (codebase-audit or hybrid mode), add one more bullet to the file list and one more rule:

```markdown
- [`DESIGN/design-remediation.md`](DESIGN/design-remediation.md) — known drift between the current UI and the design system, with standardization guidance
```

```markdown
- Before adding new UI code in an area flagged in `DESIGN/design-remediation.md`, fix the flagged drift first rather than adding to it
```

**If `AGENTS.md` does not exist:** do not create it. Note in the summary that no `AGENTS.md` was found, and tell the user they can add the block above manually if needed.
