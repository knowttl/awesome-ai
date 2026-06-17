# AGENTS.md

Behavioral guidelines to reduce common LLM coding mistakes. You MUST follow these rules and merge them with project-specific instructions.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment — but when in doubt, follow the rule.

## 1. Think Before Coding

**NEVER assume. NEVER hide confusion. ALWAYS surface tradeoffs.**

Before implementing, you MUST:
- State your assumptions explicitly. If uncertain, STOP and ask.
- If multiple interpretations exist, present them all — NEVER pick one silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, STOP. Name exactly what is confusing. Ask before proceeding.

## 2. Simplicity First

**Write the minimum code that solves the problem. NEVER add anything speculative.**

- NEVER add features beyond what was asked.
- NEVER create abstractions for single-use code.
- NEVER add "flexibility" or "configurability" that wasn't requested.
- NEVER add error handling for impossible scenarios.
- If you write 200 lines and it could be 50, you MUST rewrite it.

Always ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify before continuing.

## 3. Surgical Changes

**Touch ONLY what you must. Clean up ONLY your own mess.**

When editing existing code, you MUST:
- NEVER "improve" adjacent code, comments, or formatting.
- NEVER refactor things that aren't broken.
- ALWAYS match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — NEVER delete it.

When your changes create orphans:
- ALWAYS remove imports/variables/functions that YOUR changes made unused.
- NEVER remove pre-existing dead code unless explicitly asked.

The test: every changed line MUST trace directly to the user's request.

## 4. Goal-Driven Execution

**ALWAYS define success criteria. Loop until verified.**

You MUST transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, you MUST state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Code Quality

**Write for local reasoning. A reader MUST be able to understand the path without jumping elsewhere.**

Inspired by *Clean Code* (Robert C. Martin):
- ALWAYS use precise names. One term per concept. Rename when vocabulary hides intent or forces comments to compensate.
- ALWAYS keep functions small, focused, and at one level of abstraction. Tell the story top-down so intent appears before detail.
- ALWAYS separate commands from queries. A function that answers MUST NOT also mutate.
- ALWAYS keep the happy path readable. Isolate error handling, invalid-state handling, and cleanup.
- ALWAYS expose behavior rather than raw representation. NEVER write train-wreck access chains or utility dumping grounds.
- ALWAYS keep construction, framework, persistence, and vendor details outside business behavior.
- Use comments ONLY for rationale, constraints, warnings, or contracts. NEVER narrate code instead of improving it.
- ALWAYS treat tests as production code: readable, deterministic, and aligned with the behavior they protect.

## 6. Reduce Complexity

**Every interface, wrapper, layer, and name MUST hide enough complexity to justify its existence.**

Inspired by *A Philosophy of Software Design* (John Ousterhout):
- ALWAYS use reduced complexity as the primary success metric. Prefer the design that lowers cognitive load, change amplification, and hidden dependencies.
- ALWAYS prefer deep modules: small, semantic interfaces that hide meaningful internal complexity. NEVER add pass-through services, thin wrappers, or tiny split-outs that add names without reducing reader burden.
- ALWAYS design interfaces around what callers need to know, not how the implementation works.
- ALWAYS hide volatile decisions, internal representations, storage shape, protocols, and edge handling inside the module that owns the knowledge.
- ALWAYS pull complexity downward when the lower module owns the detail. A slightly more complex implementation is worth a simpler public contract.
- ALWAYS reduce exception surface by changing interfaces or invariants where possible. Define away invalid states instead of making every caller repeat defensive ceremony.
- ALWAYS treat names, consistency, and obviousness as design information. Surprising code is complexity even when short.

## 7. Refactoring Discipline

**Refactoring is behavior-preserving design work in small steps. It is NEVER a rewrite and NEVER a hidden feature change.**

Inspired by *Refactoring* (Martin Fowler):
- ALWAYS preserve observable behavior during refactoring. Isolate behavior changes from structural changes.
- ALWAYS work in small, reversible, buildable, testable steps. Split a patch when it is too large to reason about locally.
- ALWAYS establish a safety net before risky refactoring. Use characterization tests for unclear behavior.
- ALWAYS use preparatory refactoring: identify what makes the requested change awkward, reshape that structure first, then make the behavior change.
- Refactor ONLY the current blocking smell, NEVER every smell in sight.
- ALWAYS prefer the simplest named move: rename, extract, inline, move, split, or introduce a parameter object.
- ALWAYS put behavior and state with the concept that owns them. Separate business policy from formatting, transport, persistence, and I/O.
- STOP when the requested change is easy, the blocking smell is gone, and the next cleanup would be speculative.

## 8. Engineering Practices

**Own the outcome. Reduce duplicated knowledge. Keep concerns independent. Prove assumptions early.**

Inspired by *The Pragmatic Programmer* (Hunt & Thomas):
- ALWAYS keep one authoritative representation for each piece of system knowledge. Business rules, validation, schemas, and configuration MUST derive from or trace to one owner.
- ALWAYS preserve orthogonality: keep components independent, responsibilities non-overlapping, interfaces narrow, and collaborator knowledge small.
- ALWAYS keep volatile decisions reversible. NEVER hard-code vendors, platforms, databases, or deployment environments before evidence justifies the commitment.
- ALWAYS prefer thin end-to-end tracer bullets over piles of isolated pieces. The first slice MUST be simple but real enough to validate architecture and assumptions.
- ALWAYS shorten feedback loops with relevant tests, automated checks, and visible failures before late expensive surprises.
- ALWAYS make contracts, assumptions, invariants, and caller/callee obligations explicit and close to the abstraction they protect.
- ALWAYS automate repetitive, error-prone, or easy-to-forget work. Builds, tests, formatting, packaging, and deployment MUST be reproducible.
- ALWAYS debug from reproduced facts: observe, isolate, explain, fix, and verify before guessing.
- ALWAYS apply the broken windows rule: fix or visibly contain small quality decay before it becomes normal.

## 9. Service Layer Boundaries

**Keep product flow intent in actions. Keep reusable operational mechanics in services.**

- Keep domain orchestration in actions: business rules, auth/ownership checks, policy decisions, state transitions, retries, and user-facing error classification.
- Move shared mechanics to services: provider/SDK calls, command execution details, readiness/health checks, and operational sequencing reused across flows.
- Extract to a service only when operational logic repeats across 2+ callers, or when fixing one path should automatically fix equivalent paths.
- Do NOT extract domain-specific logic used by one caller; avoid over-abstraction and keep it local until repetition is real.
- Design service functions as composable capability blocks, not one "do everything" method.
- Require explicit inputs and structured outputs for services; avoid hidden globals and ambiguous return contracts.
- Services MUST NOT mutate domain persistence/state directly. Keep domain policy and state ownership in action/orchestration code.
- Migrate incrementally: extract one repeated block, replace one caller, verify behavior, then migrate remaining callers.
- Keep service APIs consistent across functions (argument style, result shape, and failure semantics).

Anti-patterns to reject:
- God service that hides control flow and policy.
- Leaky service that reaches into domain tables/state.
- Inconsistent service contracts across similar operations.
- Premature extraction for one-off logic.

## 10. Dependency Source Context (Optional)

**Use source internals only when needed. Keep third-party source read-only.**

When diagnosing library behavior that docs and types do not explain, you MAY use `opensrc` (if installed) to inspect dependency implementations.

- Prefer targeted inspection: `rg`, `cat`, and `find` against `$(opensrc path <package>)`.
- Use explicit versions when reproducing dependency bugs.
- Record which package/version/ref was inspected in your summary for reproducibility.
- NEVER propose edits inside cached third-party source trees.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
