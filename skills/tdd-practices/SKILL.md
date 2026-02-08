---
name: tdd-practices
description: TDD patterns and practices for AI-assisted development. Red-green-refactor, outside-in double-loop, test quality, isolation, and when to use integration vs unit tests.
---

# TDD Practices

## Red-Green-Refactor

The fundamental TDD cycle:

1. **RED** — Write a failing test that describes the behavior you want. Run it. Watch it fail. This confirms the test is actually testing something.
2. **GREEN** — Write the minimum code to make the test pass. No more. Resist the urge to build ahead.
3. **REFACTOR** — Clean up duplication, improve naming, extract patterns. Tests protect you from breaking anything.

Each cycle should take minutes, not hours. Small cycles build confidence and momentum.

## Outside-In Double-Loop (Onion/Hexagonal)

For architectures with clear layer boundaries:

**Outer loop:** Integration test at the boundary (HTTP request in, response out). Stays RED until all inner layers are wired.

**Inner loop:** Unit tests for each layer, working inward:
- Inbound adapter (controller/handler): test request parsing, response shaping
- Use case + domain: test business rules with mocked outbound ports. Domain is PURE — zero external dependencies.
- Outbound adapter (repo, gateway): test real integration (DB, API)
- Wire the composition root. Outer test goes GREEN.

Key insight: the mocks you write in domain tests define the contracts. Those contracts become port interfaces. Architecture emerges from the tests.

## What Makes a Good Test

**Test behavior, not implementation.** A good test survives a refactor. If you rename a private method and a test breaks, the test was testing implementation.

Good test: "When a user submits a valid order, the total reflects the discount."
Bad test: "The calculateDiscount private method returns 0.15 for orders over $100."

**Each test should have one reason to fail.** If a test can fail for three different reasons, it's three tests pretending to be one.

**Test names describe the scenario:**
- `rejects_expired_discount_codes`
- `applies_bulk_pricing_for_orders_over_ten_items`
- `returns_404_when_product_not_found`

## Test Isolation

Unit tests should not depend on:
- Database state
- File system
- Network calls
- Other tests running first
- System clock

Use test doubles (mocks, stubs, fakes) to isolate the unit under test. But don't mock what you don't own — wrap external dependencies in your own adapter and mock that.

## Integration vs Unit Tests

**Unit tests:** Fast, isolated, test one behavior. Run hundreds per second. Use for business logic, validation, data transformation.

**Integration tests:** Slower, test real connections. Use for database queries, API calls, file I/O, end-to-end user journeys.

**The split:** Most of your tests should be unit tests. Integration tests confirm the wiring works. A typical ratio: 80% unit, 20% integration.

**When to go integration-first:** If the feature is primarily about connecting things (CRUD endpoint, data pipeline, API gateway), start with an integration test. If the feature has complex business rules, start with unit tests for the rules.

## Risk-Aware Test Depth

- **Low risk:** Happy path + one or two edge cases. Basic error handling.
- **Moderate risk:** Happy path + edge cases + error scenarios. Boundary conditions.
- **High risk:** All of the above + failure modes + security checks + concurrent access + data integrity. Defensive tests that verify the system fails safely.
