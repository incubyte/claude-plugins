---
name: clean-code
description: "This skill should be used when writing, reviewing, or refactoring code. Contains SRP, DRY, YAGNI, naming, error handling, dependency direction, and Kent Beck's four rules of simple design."
---

# Clean Code Principles

These principles apply to ALL code Bee produces, evaluates, or cleans up — regardless of architecture pattern, language, or framework. They are non-negotiable defaults. The target project's CLAUDE.md may add project-specific conventions on top of these.

## YAGNI — You Aren't Gonna Need It

**Don't build what nothing asks for.**

Before writing any code, abstraction, or interface, ask: does a test or acceptance criterion require this RIGHT NOW?

- **One implementation? Skip the interface.** Extract the interface when a second implementation actually arrives.
- **No test demands it? Don't build it.** "Might need it someday" is not a reason.
- **Unused parameters, empty extension points, commented-out feature flags** — all YAGNI violations. Remove them.

## DRY — Don't Repeat Yourself

**Every piece of knowledge should have a single, authoritative representation.**

- **Extract on the third occurrence, not the second.** Two similar blocks might be coincidence. Three means there's a pattern.
- **DRY applies to knowledge, not syntax.** Two functions with similar-looking code that handle different domain concepts are NOT duplication.
- **Constants over magic values.** If the same number/string appears in multiple places and means the same thing, extract it.

## SRP — Single Responsibility Principle

**Each unit of code should have one reason to change.**

- **Functions do one thing.** If a function name has "and" in it, it does two things. Split it.
- **Classes/modules have one owner.** Ask "who would request a change to this?"
- **Files stay focused.** A 500-line file doing validation, HTTP handling, database queries, and email sending has at least four responsibilities.

## Small Functions

**Functions should be short enough to understand at a glance.**

- **5-20 lines is the sweet spot.** Over 30 lines, look for extraction opportunities. Over 50 is almost always too much.
- **If you need a comment to explain a block of code, that block should be a function.** The function name replaces the comment.

## One Level of Abstraction

**Every statement in a function should be at the same level of abstraction.**

Don't mix high-level orchestration with low-level details.

## Tidy First

**Clean up before building, not after.**

- Before adding a feature, tidy the area you're about to change. Separate commit.
- Small structural improvements make the feature change simpler and the diff reviewable.
- Don't tidy unrelated areas — scope tidying to the code you're about to touch.

## Meaningful Names

**Names should reveal intent. A reader should understand the code without needing comments.**

- **Variables:** say what they hold. `remainingAttempts` not `num`.
- **Functions:** say what they do with a verb. `calculateDiscount()` not `discount()`.
- **Booleans:** start with `is`, `has`, `can`, `should`.
- **Avoid meaningless names:** `data`, `info`, `temp`, `result` — unless scope is 1-2 lines.

## Error Handling

**Errors are not exceptional — they're expected. Handle them explicitly.**

- **Don't swallow errors.** `catch (e) {}` is almost never correct.
- **Fail fast and loud.** Reject invalid input immediately with a clear error message.
- **Use domain-specific errors.** `OrderNotFoundError` not `Error('not found')`.
- **Errors at boundaries.** Validate at the entry point. Inner layers can assume valid data.
- **Don't use exceptions for control flow.**

## Dependency Direction

**Dependencies always point inward — from less stable to more stable.**

- HTTP handlers depend on services, never the reverse.
- Services depend on domain logic, never the reverse.
- Domain logic depends on nothing external.
- If an inner module imports from an outer module, the dependency is inverted.

## Composition Over Inheritance

Prefer composing behavior from small, focused pieces over deep inheritance hierarchies. One level of inheritance is usually fine. Three levels — refactor.

## Principle of Least Surprise

**Code should do what its name says. Nothing more, nothing less.**

A function called `getUser()` should not modify the user or trigger side effects.

## Comments Are a Last Resort

**A comment is a failure to express intent in code.**

- Justified comments: legal headers, explanation of _why_, warnings, TODOs with ticket numbers.
- Noise comments: restating the code, mandated Javadoc, commented-out code.

## Kent Beck's Four Rules of Simple Design

**In priority order — the first rule wins when they conflict:**

1. **Passes the tests.** Working code is non-negotiable.
2. **Reveals intention.** Every name, structure, and grouping should make purpose obvious.
3. **No duplication.** Every piece of knowledge has a single representation.
4. **Fewest elements.** Remove anything that doesn't serve the first three rules.

## Applying These Principles

**When producing code** (TDD planners, quick-fix, programmer):
- The refactor step in RED-GREEN-REFACTOR is specifically for applying these principles.

**When evaluating code** (verifier, reviewer):
- SRP and dependency direction are the highest-priority checks.

**When cleaning code** (tidy):
- These principles define what "tidy" means. Focus on the change area.

**When the target project has its own CLAUDE.md:**
- Project conventions take precedence for project-specific rules.
- These Bee principles still apply for universal code quality.

## Additional Resources

### Reference Files

For detailed code examples illustrating each principle, consult:

- **`references/code-examples.md`** — Concrete code examples for YAGNI, DRY, SRP, abstraction levels, naming, error handling, and anti-patterns like feature envy, Law of Demeter violations, and null returns.
