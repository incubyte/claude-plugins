# Clean Code — Code Examples

Concrete examples illustrating each principle from SKILL.md.

## YAGNI Examples

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

## DRY Examples

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

## SRP Examples

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

## Abstraction Levels

```typescript
// Mixed abstraction levels
async function processOrder(order: Order) {
  const isValid = order.items.length > 0 && order.items.every(i => i.price > 0);  // low-level
  await notifyWarehouse(order);                                                      // high-level
  const tax = order.items.reduce((sum, i) => sum + i.price * 0.08, 0);             // low-level
  await chargeCustomer(order.customerId, order.total + tax);                         // high-level
}

// Clean: all at the same level
async function processOrder(order: Order) {
  validateOrder(order);
  const total = calculateTotal(order);
  await chargeCustomer(order.customerId, total);
  await notifyWarehouse(order);
}
```

## Small Functions — Comment Extraction

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

## Error Handling

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

## Fewer Function Arguments

- Zero or one argument is ideal. Two is acceptable. Three — question it.
- **Flag arguments are bad.** `render(true)` — split into `renderForPrint()` and `renderForScreen()`.
- **Group related arguments.** `createUser(name, email, role, department)` becomes `createUser(userRequest)`.

## Command-Query Separation

- Commands change state but return nothing (`saveOrder(order)`).
- Queries return data but change nothing (`getOrderTotal(orderId)`).
- A function that sets a value AND returns whether it succeeded mixes the two.

## Law of Demeter

- Don't chain: `order.getCustomer().getAddress().getCity()`.
- Fix by asking the object to do the work: `order.getShippingCity()`.

## Don't Return Null

- Return empty collections instead of null for lists.
- Use Optional/Maybe types when a value might be absent.
- Throw a domain-specific error when absence is exceptional.

## Feature Envy

```typescript
// Feature envy: OrderPrinter reaches into Order's internals
class OrderPrinter {
  formatSummary(order: Order) {
    return `${order.customer.name}: ${order.items.length} items, $${order.total - order.discount}`;
  }
}

// Clean: Order formats its own summary
class Order {
  formatSummary(): string {
    return `${this.customer.name}: ${this.items.length} items, $${this.netTotal}`;
  }
}
```
