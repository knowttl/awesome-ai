---
name: baseline-agents
description: >
  Behavioral guidelines to reduce common LLM coding mistakes. Use when setting
  up agent rules for a new project, when the user asks for baseline behavioral
  standards, or when generating or updating an AGENTS.md file with core agent
  guidelines.
---

# Baseline Agent Guidelines

These rules reduce common LLM coding mistakes. Use them when creating a new
`AGENTS.md` or when the user asks for baseline agent behavior standards.
Always combine with project-specific rules discovered through investigation.

## Workflow

### 1. Check what exists

Read the target AGENTS.md file (at `~/AGENTS.md` for user profile, or
`<PROJECT_PATH>/AGENTS.md` for a project). If no file exists, treat it as
empty and proceed to step 3.

### 2. Compare against baseline

For each rule section below, check if the target file already covers the same
principle. Match on **semantic equivalence**, not keywords. A rule is
"present" if the file has a guideline that achieves the same behavioral
effect, even if worded differently.

### 3. Merge only missing rules

Append at the end of the file only the sections that are not already covered.
Do not duplicate or overwrite existing content. If all rules are already
covered, report "no changes needed" and stop — do not modify the file.

### 4. Report

List which sections were added, or state "all rules already present — no
changes made."

---

## Behavioral Rules

You MUST follow these rules.

### 1. Think Before Coding

- State assumptions explicitly. If uncertain, STOP and ask.
- Present all interpretations — NEVER pick one silently.
- Propose simpler alternatives when they exist.

### 2. Write the Minimum

- NEVER add unrequested features, abstractions, flexibility, or configurability.
- NEVER handle impossible scenarios.
- If 200 lines could be 50, rewrite to 50.

### 3. Touch Only What You Must

- NEVER "improve" adjacent code, comments, or formatting.
- ALWAYS match existing style.
- Notice dead code? Mention it. NEVER delete it.
- Remove only imports, variables, and functions YOUR changes orphaned.
- Fix unrelated lint failures, test failures, and flakiness when spotted.

### 4. Define Success, Then Verify

- Transform tasks into testable goals and loop until they pass.
- "Add validation"  → write tests for invalid inputs, make them pass.
- "Fix the bug"     → write a test that reproduces it, make it pass.
- "Refactor X"      → tests pass before and after.
- For multi-step work, state a plan: `1. [Step] → verify: [check]`.

### 5. Write for Local Reasoning

- Precise names. One term per concept.
- Small, focused functions. Commands separate from queries.
- Happy path readable. Isolate error handling, invalid states, and cleanup.
- Comments ONLY for rationale, constraints, warnings, or contracts.
- Tests are production code: readable, deterministic, behavior-aligned.

### 6. Earn Every Abstraction

- Every interface, wrapper, layer, and name MUST hide more complexity than it adds.
- Design interfaces around caller needs, not implementation details.
- Define away invalid states. Never make callers repeat defensive checks.

### 7. Refactor Safely

- Refactoring is behavior-preserving. NEVER rewrite or slip in features.
- Work in small, reversible, buildable, testable steps.
- Refactor ONLY the blocking smell. NEVER everything in sight.

### 8. Engineering Habits

- ONE authoritative representation per piece of system knowledge.
- Debug from facts: observe, isolate, explain, fix, verify. Never guess first.
- Fix or visibly contain small quality decay before it becomes normal.

### 9. Layer Boundaries

- Domain logic stays local. Extract shared mechanics only at 2+ callers.
- Shared code has explicit inputs/structured outputs and does not mutate domain state directly.
- Reject: god layers, leaky layers, inconsistent contracts, premature extraction.

### 10. Dependency Source Context

- Inspect third-party source only when docs and types are insufficient. NEVER edit it.

### 11. Personal Guidelines

- Never use the em dash. Use a plain dash instead.
- Never auto-add your agent name as a commit co-author.
- Never manually modify `CHANGELOG.md` files or files marked as auto-generated.
- In long Markdown files, put each full sentence on its own line.
- Prefer quality, simplicity, robustness, scalability, and long-term maintainability over development cost.
- Reproduce bugs end-to-end before fixing.
- Be picky about UI in end-to-end tests; fix obvious issues.
- Fix lint failures, test failures, and flakiness even if unrelated.
