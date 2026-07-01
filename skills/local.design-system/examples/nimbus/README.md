# Nimbus — Worked Example

A complete, realistic sample output for a fictional web app ("Nimbus", a project management tool), generated in **Reference-based mode** from a short brand brief. Use this to calibrate tone, depth, and format before generating a real design system — not as a source of values to copy.

| File | What to notice |
|------|-----------------|
| [`design.md`](design.md) | Every required token category is present and populated with real values, not placeholders. Note how Colors are grouped by semantic role (Accent, Surface & Neutral, Semantic/Status), and how the Design Tokens table names map to the CSS custom properties actually used in `design-preview.html`. |
| [`design-guidelines.md`](design-guidelines.md) | Web-only project, so it has a **Pointer & Interaction** section instead of a Gestures table — see [`references/guidelines-spec.md`](../../references/guidelines-spec.md) for when to make that call. Do's/Don'ts are grouped by the same categories as `design.md`. |
| [`design-components.md`](design-components.md) | 12 components across all 6 categories (2 per category) — enough to show the pattern for every category, though a real project may have many more per category. Each entry follows the exact structure in [`references/components-spec.md`](../../references/components-spec.md): type/size line, property table, Do/Don't. |
| [`design-preview.html`](design-preview.html) | Open this directly in a browser. Every CSS custom property traces back to a row in `design.md`'s Design Tokens table — that traceability is the whole point, not just visual polish. The theme toggle in the header swaps `data-theme` and every color updates because components reference `var(--color-*)` rather than hardcoded hex values. Every component renders as real semantic HTML (`<button>`, `<input>`, `<table>`) with working `:hover`/`:focus-visible`/`:disabled` states. |

This is **not** a Codebase-audit or Hybrid example — since those modes also produce `design-remediation.md`, see [`references/remediation-spec.md`](../../references/remediation-spec.md) for that file's structure; a worked example wasn't generated for it here because drift reports are inherently specific to one real codebase's scan results, not something a fictional brief can meaningfully illustrate.
