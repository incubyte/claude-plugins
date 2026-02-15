---
name: clean-code
description: Code quality principles that all Bee agents follow when producing, evaluating, or cleaning up code. YAGNI, DRY, SRP, naming, error handling, and dependency direction.
---

# Clean Code Principles

These principles apply to ALL code Bee produces, evaluates, or cleans up — regardless of architecture pattern, language, or framework. They are non-negotiable defaults. The target project's CLAUDE.md may add project-specific conventions on top of these.

---

## YAGNI — You Aren't Gonna Need It

**Don't build what nothing asks for.**

Before writing any code, abstraction, or interface, ask: does a test or acceptance criterion require this RIGHT NOW?

- **One implementation? Skip the interface.** Don't create `IUserRepository` when there's only `PostgresUserRepository`. Extract the interface when a second implementation actually arrives.
- **No test demands it? Don't build it.** "Might need it someday" is not a reason. A failing test is.
- **Unused parameters, empty extension points, commented-out feature flags** — all YAGNI violations. Remove them.

```typescript
// YAGNI violation: nobody asked for configurable strategies
class OrderService {
  constructor(
    private pricingStrategy: PricingStrategy,  // only one implementation exists
    private discountEngine: DiscountEngine,    // only one implementation exists
    private taxCalculator: TaxCalculator,      // only one implementation exists
  ) {}
}

// Clean: use the concrete implementations directly
class OrderService {
  calculateTotal(items: OrderItem[]): number {
    const subtotal = items.reduce((sum, i) => sum + i.price * i.qty, 0);
    const discount = calculateBulkDiscount(subtotal);
    return subtotal - discount;
  }
}
```

## DRY — Don't Repeat Yourself

**Every piece of knowledge should have a single, authoritative representation.**

- **Extract on the third occurrence, not the second.** Two similar blocks might be coincidence. Three means there's a pattern. Premature extraction creates wrong abstractions.
- **DRY applies to knowledge, not syntax.** Two functions with similar-looking code that handle different domain concepts are NOT duplication — they have different reasons to change.
- **Constants over magic values.** If the same number/string appears in multiple places and means the same thing, extract it.

```typescript
// Duplication of knowledge — same rule in two places
function validateOrder(order) {
  if (order.items.length === 0) throw new Error('Order must have items');
}
function processOrder(order) {
  if (order.items.length === 0) return; // same rule, different handling
}

// DRY — single source of truth
function assertHasItems(order) {
  if (order.items.length === 0) throw new Error('Order must have items');
}
```

## SRP — Single Responsibility Principle

**Each unit of code should have one reason to change.**

- **Functions do one thing.** If a function name has "and" in it (`validateAndSave`, `fetchAndTransform`), it does two things. Split it.
- **Classes/modules have one owner.** Ask "who would request a change to this?" If the answer is two different stakeholders (e.g., "the billing team AND the UI team"), it has two responsibilities.
- **Files stay focused.** A 500-line file doing validation, HTTP handling, database queries, and email sending has at least four responsibilities.

```typescript
// SRP violation: this function has three responsibilities
async function handleOrderRequest(req: Request) {
  // 1. Parse and validate (HTTP concern)
  const body = await req.json();
  if (!body.items?.length) return new Response('No items', { status: 400 });

  // 2. Calculate pricing (business logic)
  const total = body.items.reduce((s, i) => s + i.price * i.qty, 0);
  const discount = total > 100 ? total * 0.1 : 0;

  // 3. Persist (data concern)
  await db.insert('orders', { items: body.items, total: total - discount });
  return new Response(JSON.stringify({ total: total - discount }), { status: 201 });
}

// Clean: each concern is separate
async function handleOrderRequest(req: Request) {
  const command = parseOrderRequest(req);        // HTTP → domain translation
  const order = createOrder(command.items);       // pure business logic
  await orderRepository.save(order);              // data access
  return formatOrderResponse(order);              // domain → HTTP translation
}
```

## Small Functions

**Functions should be short enough to understand at a glance.**

- **5-20 lines is the sweet spot.** Over 30 lines, look for extraction opportunities. Over 50 lines is almost always too much.
- **One level of abstraction per function.** Don't mix high-level orchestration with low-level details.
- **If you need a comment to explain a block of code, that block should be a function.** The function name replaces the comment.

```typescript
// The comment tells you this should be a function
// Calculate discount based on quantity tiers
let discount = 0;
if (qty >= 100) discount = 0.2;
else if (qty >= 50) discount = 0.1;
else if (qty >= 10) discount = 0.05;

// Clean: the function name IS the documentation
const discount = calculateTierDiscount(qty);
```

## Meaningful Names

**Names should reveal intent. A reader should understand the code without needing comments.**

- **Variables:** say what they hold, not what type they are. `remainingAttempts` not `num` or `count`. `eligibleOrders` not `list` or `data`.
- **Functions:** say what they do with a verb. `calculateDiscount()` not `discount()`. `isExpired()` not `checkDate()`.
- **Booleans:** start with `is`, `has`, `can`, `should`. `isActive` not `active`. `hasPermission` not `permission`.
- **Avoid meaningless names:** `data`, `info`, `temp`, `result`, `item`, `thing`, `stuff`, `obj` — unless the scope is 1-2 lines.
- **Avoid abbreviations:** `repository` not `repo`. `configuration` not `cfg`. Exception: universally understood abbreviations like `id`, `url`, `api`.

## Error Handling

**Errors are not exceptional — they're expected. Handle them explicitly.**

- **Don't swallow errors.** `catch (e) {}` is almost never correct. At minimum, log the error.
- **Fail fast and loud.** If input is invalid, reject it immediately with a clear error message. Don't let bad data propagate through the system.
- **Use domain-specific errors, not generic ones.** `OrderNotFoundError` is more useful than `Error('not found')`.
- **Errors at boundaries.** Validate at the entry point (controller, handler). Inner layers can assume valid data because the boundary already checked.
- **Don't use exceptions for control flow.** Exceptions are for exceptional situations. Expected outcomes (user not found, item out of stock) should be return values or result types.

```typescript
// Bad: swallowed error
try { await sendEmail(user); } catch (e) { /* ignore */ }

// Bad: generic error
throw new Error('Failed');

// Good: explicit handling with domain error
try {
  await sendEmail(user);
} catch (error) {
  logger.warn('Email delivery failed', { userId: user.id, error });
  await markNotificationFailed(user.id, 'email', error.message);
}
```

## Use Proper Loggers

**`print`, `console.log`, and `System.out.println` are not logging.**

- Use the project's logging framework (`logger.info`, `logger.warn`, `logger.error`) — not print statements.
- Loggers provide levels, timestamps, structured context, and can be filtered. Print statements are noise that can't be turned off.
- If the project doesn't have a logger, that's a setup task — not an excuse to use print.
- Remove debug print statements before committing. If the information is worth logging, use a logger at the appropriate level.

## No Dead Code

**If code isn't executing, delete it.**

- **Commented-out code:** delete it. Git remembers.
- **Unused imports:** remove them.
- **Unused parameters:** remove them (or prefix with `_` if required by an interface).
- **Unreachable branches:** delete them.
- **TODO comments without tickets:** either create the ticket or delete the TODO.
- **Feature flags that are permanently on/off:** remove the flag and the dead branch.

## Dependency Direction

**Dependencies always point inward — from less stable to more stable.**

- HTTP handlers depend on services, never the reverse.
- Services depend on domain logic, never the reverse.
- Domain logic depends on nothing external.
- Outer layers (adapters, controllers, infrastructure) are allowed to change frequently.
- Inner layers (domain, business rules) should change rarely.

If you find an inner module importing from an outer module, the dependency is inverted and needs fixing.

## Composition Over Inheritance

**Prefer composing behavior from small, focused pieces over deep inheritance hierarchies.**

- **Inheritance creates coupling.** A change to a base class ripples to all subclasses.
- **Favor function composition** or **dependency injection** over `extends`.
- **One level of inheritance is usually fine.** Two levels, question it. Three levels, refactor.
- **Use interfaces for polymorphism** when you actually need multiple implementations (and only then — see YAGNI).

## Principle of Least Surprise

**Code should do what its name says. Nothing more, nothing less.**

- A function called `getUser()` should not modify the user or trigger side effects.
- A function called `saveOrder()` should not also send an email.
- If a function has an important side effect, the name should reflect it: `saveOrderAndNotify()` — or better, split it into two functions.

---

## Applying These Principles

**When producing code** (TDD planners, quick-fix, executor):
- Every test step should produce code that follows these principles.
- The refactor step in RED-GREEN-REFACTOR is specifically for applying these principles.
- If the AI generates code that violates these principles, the refactor step catches it.

**When evaluating code** (verifier, reviewer):
- Check for violations as part of the quality gate.
- SRP and dependency direction are the highest-priority checks.
- Dead code and naming issues are lower priority but still flagged.

**When cleaning code** (tidy):
- These principles define what "tidy" means.
- Focus on the change area, not the whole codebase.

**When the target project has its own CLAUDE.md:**
- Project conventions take precedence for project-specific rules (naming conventions, file organization, commit format).
- These Bee principles still apply for universal code quality. They don't conflict — they complement.
