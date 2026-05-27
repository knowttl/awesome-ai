# AGENTS.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Code Quality

**Write for local reasoning. A reader should understand the path without jumping elsewhere.**

Inspired by *Clean Code* (Robert C. Martin):
- Use precise names. One term per concept. Rename when vocabulary hides intent or forces comments to compensate.
- Keep functions small, focused, and at one level of abstraction. Tell the story top-down so intent appears before detail.
- Separate commands from queries. A function that answers should not also mutate.
- Keep the happy path readable. Isolate error handling, invalid-state handling, and cleanup.
- Expose behavior rather than raw representation. Avoid train-wreck access chains and utility dumping grounds.
- Keep construction, framework, persistence, and vendor details outside business behavior.
- Use comments only for rationale, constraints, warnings, or contracts. Do not narrate code instead of improving it.
- Treat tests as production code: readable, deterministic, and aligned with the behavior they protect.

## 6. Reduce Complexity

**Every interface, wrapper, layer, and name must hide enough complexity to justify its existence.**

Inspired by *A Philosophy of Software Design* (John Ousterhout):
- Use reduced complexity as the primary success metric. Prefer the design that lowers cognitive load, change amplification, and hidden dependencies.
- Prefer deep modules: small, semantic interfaces that hide meaningful internal complexity. Reject pass-through services, thin wrappers, and tiny split-outs that add names without reducing reader burden.
- Design interfaces around what callers need to know, not how the implementation works.
- Hide volatile decisions, internal representations, storage shape, protocols, and edge handling inside the module that owns the knowledge.
- Pull complexity downward when the lower module owns the detail. A slightly more complex implementation is worth a simpler public contract.
- Reduce exception surface by changing interfaces or invariants where possible. Define away invalid states instead of making every caller repeat defensive ceremony.
- Treat names, consistency, and obviousness as design information. Surprising code is complexity even when short.

## 7. Refactoring Discipline

**Refactoring is behavior-preserving design work in small steps. Not a rewrite. Not a hidden feature change.**

Inspired by *Refactoring* (Martin Fowler):
- Preserve observable behavior during refactoring. Isolate behavior changes from structural changes.
- Work in small, reversible, buildable, testable steps. Split a patch when it is too large to reason about locally.
- Establish a safety net before risky refactoring. Use characterization tests for unclear behavior.
- Use preparatory refactoring: identify what makes the requested change awkward, reshape that structure first, then make the behavior change.
- Refactor the current blocking smell, not every smell in sight.
- Prefer the simplest named move: rename, extract, inline, move, split, or introduce a parameter object.
- Put behavior and state with the concept that owns them. Separate business policy from formatting, transport, persistence, and I/O.
- Stop when the requested change is easy, the blocking smell is gone, and the next cleanup would be speculative.

## 8. Engineering Practices

**Own the outcome. Reduce duplicated knowledge. Keep concerns independent. Prove assumptions early.**

Inspired by *The Pragmatic Programmer* (Hunt & Thomas):
- Keep one authoritative representation for each piece of system knowledge. Business rules, validation, schemas, and configuration should derive from or trace to one owner.
- Preserve orthogonality: keep components independent, responsibilities non-overlapping, interfaces narrow, and collaborator knowledge small.
- Keep volatile decisions reversible. Do not hard-code vendors, platforms, databases, or deployment environments before evidence justifies the commitment.
- Prefer thin end-to-end tracer bullets over piles of isolated pieces. The first slice should be simple but real enough to validate architecture and assumptions.
- Shorten feedback loops with relevant tests, automated checks, and visible failures before late expensive surprises.
- Make contracts, assumptions, invariants, and caller/callee obligations explicit and close to the abstraction they protect.
- Automate repetitive, error-prone, or easy-to-forget work. Builds, tests, formatting, packaging, and deployment should be reproducible.
- Debug from reproduced facts: observe, isolate, explain, fix, and verify before guessing.
- Apply the broken windows rule: fix or visibly contain small quality decay before it becomes normal.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
