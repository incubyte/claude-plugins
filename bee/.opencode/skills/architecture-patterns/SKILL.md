---
name: architecture-patterns
description: "This skill should be used when evaluating architecture options, checking dependency direction, or deciding between onion, MVC, and simple patterns. Contains YAGNI-based decision criteria."
---

# Architecture Patterns

## When to Use What

### Simple (No Layers)

**Use when:** Scripts, utilities, CLI tools, small services with minimal business logic, CRUD with no rules beyond validation.

**Structure:** Functions or modules organized by feature. No layers, no ports.

**Tradeoff:** Fastest to build. Hardest to extend if complexity grows. Refactor to layers when it hurts, not before.

### MVC (Model-View-Controller)

**Use when:** Web apps, APIs, most CRUD-heavy applications. The default for Rails, Django, Express, Spring.

**Structure:** Route -> Controller (thin, delegates) -> Service (business logic) -> Model/Repository (data).

**Dependency direction:** Controller depends on Service, Service depends on Model. Never the reverse.

**Tradeoff:** Familiar, well-tooled, lots of examples. Services can grow large as business logic gets complex. At that point, consider extracting a domain layer.

### Onion / Hexagonal

**Use when:** Complex domain logic with many business rules. Multiple input channels (HTTP, CLI, events). Need to swap infrastructure (different DB, different API provider).

**Structure:** Pure domain core (zero external dependencies) -> Use cases (orchestration) -> Adapters (HTTP, DB, messaging).

**Dependency direction:** Everything points inward. Outer layers depend on inner layers. Inner layers know nothing about outer layers. Ports (interfaces) define the boundaries.

**Tradeoff:** More structure upfront. Trivially testable domain. Worth it when business rules are complex. Overkill for simple CRUD.

## Dependency Direction Rules

The cardinal rule: **inner layers never import from outer layers.**

- Domain/business logic has zero external dependencies
- Use cases depend on domain, not on controllers or repos
- Controllers depend on use cases, not on repos directly
- Repos implement interfaces defined by the domain

Violations of this rule create coupling that makes testing hard and changes expensive.

## YAGNI: When NOT to Abstract

**You Aren't Gonna Need It.** Before creating any abstraction, ask:

1. **How many implementations exist RIGHT NOW?** If one — skip the interface.
2. **Is there a concrete, foreseeable reason to swap?** "Might need it someday" is not foreseeable. "We're migrating from Postgres to DynamoDB next quarter" is.
3. **Would the concrete implementation be simpler?** If yes — use it.

**The rule:** Extract an interface when the second implementation arrives. Not before.

**Why this matters for AI:** AI loves generating interfaces, abstract factories, and strategy patterns. It will create `IUserRepository`, `UserRepositoryImpl`, `UserRepositoryFactory` for a single Postgres query. Push back. Use the concrete class. Extract when you need to.

**Warranted abstractions:**
- Multiple implementations exist today (e.g., payment via Stripe AND PayPal)
- You need test doubles for slow external dependencies (wrap the external API in your own adapter)
- The interface is a genuine domain boundary (e.g., "notification sender" with email, SMS, push)

**Unwarranted abstractions:**
- "We might need a different database someday"
- "What if we want to swap logging frameworks"
- "Best practice says to use interfaces"
- Single implementation with no foreseeable swap reason

## How to Evaluate Architecture Decisions

1. **What's already there?** Follow existing patterns unless there's a strong reason not to. Consistency within a codebase beats theoretical perfection.
2. **How complex is the domain?** Simple rules -> simple architecture. Complex rules with many edge cases -> consider more structure.
3. **What's the risk?** Low risk -> prefer simpler. High risk -> prefer more testability and clear boundaries.
4. **Will this decision be easy to reverse?** If yes, pick the simpler option. You can always add structure later.
