# AGENTS.md

Behavioral guidelines to reduce common LLM coding mistakes. You MUST follow these rules alongside project-specific instructions.

**Tradeoff:** These bias toward caution. On trivial tasks use judgment. When uncertain, follow the rule.

## 1. Think Before Coding

**NEVER assume. NEVER hide confusion. ALWAYS surface tradeoffs.**

Before implementing, you MUST:
- State assumptions explicitly. If uncertain, STOP and ask.
- Present all interpretations — NEVER pick one silently.
- Propose simpler alternatives when they exist. Push back when warranted.
- Name exactly what is unclear before proceeding.

## 2. Write the Minimum

**Solve the problem. Add nothing else.**

- NEVER add unrequested features, abstractions, flexibility, or configurability.
- NEVER handle impossible scenarios.
- If 200 lines could be 50, rewrite to 50.

## 3. Touch Only What You Must

**Every changed line MUST trace to the user's request.**

- NEVER "improve" adjacent code, comments, or formatting.
- ALWAYS match existing style.
- Notice dead code? Mention it. NEVER delete it.
- Remove ONLY imports, variables, and functions YOUR changes orphaned.

## 4. Define Success, Then Verify

**Transform tasks into testable goals. Loop until they pass.**

```
"Add validation"  → Write tests for invalid inputs. Make them pass.
"Fix the bug"     → Write a test that reproduces it. Make it pass.
"Refactor X"      → Tests pass before and after.
```

For multi-step work, state a plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
```

## 5. Write for Local Reasoning

**A reader MUST understand without jumping elsewhere.**

- Precise names. One term per concept. Rename when vocabulary hides intent.
- Small, focused functions at one abstraction level. Intent before detail.
- Commands separate from queries. A function that answers MUST NOT mutate.
- Happy path readable. Error handling, invalid states, and cleanup isolated.
- Expose behavior, not raw representation. No train-wreck access chains.
- Construction, framework, persistence, and vendor concerns outside business logic.
- Comments ONLY for rationale, constraints, warnings, or contracts. NEVER narrate code.
- Tests are production code: readable, deterministic, behavior-aligned.

## 6. Earn Every Abstraction

**Every interface, wrapper, layer, and name MUST hide more complexity than it adds.**

- Prefer deep modules: small interfaces hiding meaningful internals.
- Design interfaces around what callers need, not how implementations work.
- Hide volatile decisions, internal representations, and edge handling inside the owning module.
- Pull complexity downward. A richer implementation for a simpler contract is a good trade.
- Define away invalid states. Never make callers repeat defensive checks.
- Names, consistency, and obviousness are design currency. Surprise is complexity.

## 7. Refactor in Small, Safe Steps

**Refactoring is behavior-preserving. It is NEVER a rewrite and NEVER a stealth feature change.**

- Isolate structural changes from behavior changes.
- Work in small, reversible, buildable, testable steps.
- Establish a safety net before risky moves. Characterization tests for unclear behavior.
- Preparatory refactoring: reshape the awkward structure first, then change behavior.
- Refactor ONLY the blocking smell. NEVER everything in sight.
- Prefer the simplest named move: rename, extract, inline, move, split.
- Put behavior and state with the concept that owns them.
- STOP when the requested change is easy and the blocking smell is gone.

## 8. Own the Outcome

- ONE authoritative representation per piece of system knowledge.
- Orthogonal components: independent, non-overlapping responsibilities, narrow interfaces.
- Volatile decisions stay reversible. NEVER hard-code a vendor, platform, or database without evidence.
- Thin end-to-end slices over piles of isolated pieces. The first slice validates architecture.
- Short feedback loops: relevant tests, automated checks, visible failures.
- Contracts, assumptions, and invariants: explicit and near the abstraction they protect.
- Automate repetitive work. Builds, tests, formatting, packaging, deployment MUST be reproducible.
- Debug from facts: observe, isolate, explain, fix, verify. Never guess first.
- Broken windows rule: fix or contain small decay before it normalizes.

## 9. Layer Boundaries

**Keep domain policy where intent lives. Extract only when reuse justifies it.**

- Domain logic stays local: business rules, auth checks, policy decisions, state transitions, error semantics.
- Extract to a shared layer ONLY when the same operational logic repeats across 2+ callers, or fixing one path must fix all equivalent paths.
- Do NOT extract domain-specific logic used once. Keep it local until repetition is real.
- Design shared functions as composable capabilities, not monolithic "do everything" methods.
- Require explicit inputs and structured outputs. No hidden globals. No ambiguous return contracts.
- Shared code MUST NOT mutate domain state directly. Policy and state ownership stay with the caller.
- Migrate incrementally: extract one repeated block, replace one caller, verify, then migrate remaining callers.
- Keep shared APIs consistent across functions.

Anti-patterns:
- God layer hiding control flow and policy.
- Leaky layer reaching into domain tables/state.
- Inconsistent contracts across similar operations.
- Premature extraction of one-off logic.

## 10. Dependency Source Context (Optional)

**Use source internals only when needed. Keep third-party source read-only.**

When docs and types don't explain library behavior, you MAY inspect source with `opensrc`.

- Prefer: `rg`, `cat`, `find` against `$(opensrc path <package>)`.
- Use explicit versions when reproducing bugs.
- Record package/version/ref inspected.
- NEVER edit third-party source.

---

**Working guidelines mean:** fewer unnecessary diffs, fewer rewrites, and clarifying questions before implementation, not after.
