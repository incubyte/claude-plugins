---
name: ai-ergonomics
description: Principles for evaluating how well a codebase supports LLM-assisted development. Context window friendliness, explicitness, module boundaries, test-as-spec, and naming.
---

# AI Ergonomics

How comfortable is this codebase for an LLM to navigate, understand, and generate correct code in? Code that's ergonomic for AI is also better for humans — but the emphasis here is on what specifically helps or hinders LLM tools like Claude Code, Copilot, and Cursor.

## Context Window Friendliness

LLMs work with a finite context window. Every file they read consumes tokens. Large files are expensive, and when a file exceeds the context budget, the LLM works with a partial view — leading to hallucinations and missed dependencies.

**What to check:**
- Files over 500 lines deserve scrutiny. Over 1000 lines is a strong signal to split.
- Functions over 50 lines force the LLM to track too much state. It will lose track of variables, forget early conditions, or hallucinate return values.
- Deeply nested code (4+ levels) is hard for LLMs to reason about correctly — the same way it's hard for humans, but LLMs fail more silently.

**What to recommend:**
- Extract focused modules. A 1200-line `OrderService` could be `OrderCreation`, `OrderPricing`, `OrderFulfillment` — each fits in context and has a clear purpose.
- Break long functions into composed smaller functions. The LLM can then work on each piece independently.
- Flatten nesting with early returns and guard clauses.

## Explicit Over Implicit

LLMs generate better code when they can see the shape of data and contracts. Implicit conventions — patterns that exist only in developers' heads — are invisible to AI and cause hallucinations.

**What to check:**
- **Types and interfaces**: Are function parameters and return types explicit? `function process(data: any)` gives the LLM nothing to work with. `function calculateDiscount(order: Order): Money` tells it exactly what to generate.
- **Magic strings and numbers**: Does the code use `"active"` in 12 places instead of a `Status.ACTIVE` constant? LLMs will guess wrong strings.
- **Implicit conventions**: Is there an unwritten rule that "all services must call `validate()` before `save()`"? Unless it's in a type system, a base class, or documentation, the LLM won't know.
- **Configuration**: Are defaults buried in code instead of in config files or constants? LLMs can't discover them.

**What to recommend:**
- Add types to key interfaces, especially function signatures on public APIs.
- Extract constants for repeated values.
- Document implicit conventions in CLAUDE.md or code comments at the declaration site.
- Use the type system to enforce patterns when possible (e.g., a `ValidatedOrder` type that can only be created by calling `validate()`).

## Self-Documenting Module Boundaries

When an LLM needs to work on a module, it should be able to understand the module's purpose and interface without loading the entire codebase. Clear boundaries mean the LLM can work on isolated pieces — fewer files in context, faster and more accurate results.

**What to check:**
- **Index/barrel files**: Does each module export a clear public API? Or does everything leak?
- **Dependency direction**: Can the LLM understand what this module depends on and what depends on it? Circular dependencies force loading everything.
- **README or module docs**: Is there a one-paragraph description of what this module does and how to use it? LLMs read these.
- **Cohesion**: Does the module contain one concept, or is it a grab-bag? `src/utils/` with 30 unrelated functions is an anti-pattern for AI — the LLM has to read all 30 to find the one it needs.

**What to recommend:**
- Add index files that re-export the public API.
- Break `utils/` into focused modules (`utils/dates.ts`, `utils/money.ts`).
- Add a one-line comment at the top of each module describing its purpose.
- Eliminate circular dependencies.

## Test-as-Spec Coverage

Tests are the best specification an LLM can read. A well-named test suite tells the LLM what the code is supposed to do — it can then generate implementations that match. Missing or poorly-named tests mean the LLM is guessing at behavior.

**What to check:**
- **Coverage of critical paths**: Are the most important behaviors tested? The LLM uses tests as guardrails — no test means no guardrail.
- **Test names as requirements**: `test('should return 404 when user not found')` is a spec. `test('test1')` or `test('getUser')` tells the LLM nothing.
- **Test readability**: Can the LLM understand the expected behavior from the test alone? Tests with complex setup, shared state, or implicit assertions are opaque.
- **Test-to-code proximity**: Are tests colocated with the code they test, or buried in a separate tree? Colocated tests are easier for LLMs to discover.

**What to recommend:**
- Add tests for untested critical paths — frame it as "giving the LLM a specification."
- Rename vague test names to behavior descriptions.
- Simplify test setup so each test reads independently.

## CLAUDE.md and Documentation Quality

CLAUDE.md is the LLM's instruction manual for the project. If it's missing, outdated, or too vague, the LLM operates without project context and falls back to generic patterns that may not fit.

**What to check:**
- **Exists?** A missing CLAUDE.md means the LLM has zero project-specific guidance.
- **Accurate?** Do the conventions described match the actual code? Stale docs are worse than no docs — the LLM follows wrong instructions confidently.
- **Actionable?** Vague rules ("write clean code") don't help. Specific rules ("use camelCase for functions, PascalCase for types, kebab-case for file names") do.
- **Key patterns documented?** Architecture patterns, testing conventions, error handling approach, naming conventions — these are what LLMs need most.

**What to recommend:**
- Create a CLAUDE.md if missing, with at minimum: tech stack, file structure, naming conventions, testing approach, and any non-obvious patterns.
- Update stale rules.
- Add specific, actionable conventions rather than vague principles.

## Naming That Carries Context

LLMs rely heavily on names to understand code without reading every line. A function called `process()` forces the LLM to read the entire implementation. A function called `applyBulkDiscountToOrder()` tells it everything.

**What to check:**
- **Function names**: Do they describe what the function does AND what domain concept it operates on? `handle()` vs `handlePaymentWebhook()`.
- **Variable names**: Do they carry enough context to understand the value without tracing back to assignment? `x` vs `remainingRetryAttempts`.
- **File names**: Does the file name tell the LLM what's inside? `helpers.ts` vs `order-pricing.ts`.
- **Boolean names**: Do they read as questions? `active` vs `isOrderActive`.

**What to recommend:**
- Rename ambiguous names in high-traffic code (especially hotspot files where the LLM will interact most).
- Use domain language in names — match the team's vocabulary.
- File names should match the primary export or concept.

## Applying This Skill

When evaluating a codebase for AI ergonomics, prioritize findings by impact:

1. **High impact**: Missing types on public APIs, god files (1000+ lines), missing CLAUDE.md, untested critical paths. These cause the most AI failures.
2. **Medium impact**: Implicit conventions, vague naming in hot paths, deeply nested code. These cause frequent but recoverable AI mistakes.
3. **Low impact**: Test proximity, barrel files, minor naming improvements in stable code. Nice to have but not urgent.

Every finding should answer: "If this were fixed, what would the LLM be able to do better?" That's the WHY.
