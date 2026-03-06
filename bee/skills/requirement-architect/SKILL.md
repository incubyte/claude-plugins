---
name: requirement-architect
description: "Rewrites software requirements to lead to better code design and architecture. Use this skill whenever a user shares requirements, user stories, feature specs, acceptance criteria, or PRDs and wants them improved before development begins. Also trigger when a user says 'review my requirements', 'improve this spec', 'make this requirement better', 'rewrite this for better design', 'architecture-aware requirements', or asks how to write requirements that produce cleaner code. Trigger even when users paste requirements without explicitly asking for review — if the requirements contain design-limiting patterns (conditional chains, implementation details, ambiguous boundaries), proactively suggest improvements."
---

# Requirement Architect

A skill that rewrites software requirements so they naturally lead to better software design, architecture, and code quality.

## Why This Matters

Research by Perry & Wolf (1992) established that software architecture = elements + form + rationale, and that requirements directly constrain architectural choices. Boehm's empirical work showed that requirements errors cost 50-200x more to fix when caught late. But there's a subtler problem: even "correct" requirements can lead to poor architecture if they're written in ways that embed implementation assumptions.

The key insight: **how you describe behavior in a requirement shapes how a developer implements it in code.** A requirement full of if/else conditional logic produces code full of if/else branches. A requirement that describes distinct types and their behaviors produces polymorphic, extensible code. The requirement is a mold — the code takes its shape.

## Core Principles

### 1. Requirements Shape Code Structure

When you read a requirement, ask: "If a developer translates this literally into code, what would the code look like?" Then rewrite so that literal translation produces good design.

**Conditional logic in requirements → conditional logic in code:**

Bad: "If the user is a premium member, show price with 20% discount. If the user is a trial member, show price with no discount but add a banner. If the user is an expired member, redirect to renewal page."

→ Developer writes: `if (user.type === 'premium') ... else if (user.type === 'trial') ... else if ...`

**Type-based requirements → polymorphic code:**

Better: "Each membership tier defines its own pricing display behavior and page experience. The system supports Premium, Trial, and Expired tiers, each responsible for determining how pricing is presented to the user."

→ Developer creates: `MembershipTier` interface with `displayPricing()` method, separate implementations per tier.

### 2. The Seven Requirement Smells

Detect and fix these patterns:

#### Smell 1: Conditional Chains

- **Signal:** "If [condition] then [behavior], else if [condition] then [behavior]..."
- **Problem:** Produces branching code that's hard to extend (violates Open-Closed Principle)
- **Fix:** Describe distinct types/categories, each with their own behavior profile

#### Smell 2: Implementation Leaking

- **Signal:** References to databases, APIs, specific technologies, UI components
- **Problem:** Couples requirements to a solution, blocks alternative architectures
- **Fix:** Describe what the system does, not how. Use domain language, not tech language

#### Smell 3: God Requirement

- **Signal:** One requirement that touches authentication, business logic, notifications, and reporting
- **Problem:** Produces god classes/modules with no clear boundaries
- **Fix:** Decompose by domain concern — each requirement should map to one bounded context

#### Smell 4: Missing Domain Language

- **Signal:** Generic terms like "the system", "the data", "the process", "the user"
- **Problem:** No ubiquitous language → developers invent their own terms → inconsistent model
- **Fix:** Name the domain concepts explicitly. Not "the data" but "the Patient Record" or "the Order"

#### Smell 5: Temporal Coupling

- **Signal:** "First do X, then do Y, then do Z"
- **Problem:** Forces sequential implementation even when steps are independent
- **Fix:** Describe what triggers each action and what each action needs — let architecture decide ordering

#### Smell 6: Ambiguous Boundaries

- **Signal:** One requirement that says "the system handles orders, payments, and shipping"
- **Problem:** No module boundaries → monolithic implementation
- **Fix:** Describe each capability as a separate concern with explicit inputs/outputs between them

#### Smell 7: Implicit State Machine

- **Signal:** Scattered mentions of status changes across multiple requirements
- **Problem:** State logic gets spread across the codebase with no single source of truth
- **Fix:** Explicitly describe the states, transitions, and what triggers each transition as one cohesive requirement

### 3. Rewrite Strategy

For each requirement, apply this sequence:

**Step 1: Identify the domain model**
What are the core nouns (entities)? What are their relationships? Name them with precision.

**Step 2: Replace conditionals with types**
Every "if type is X" should become "X does [behavior]". Push behavior to the type, not to the caller.

**Step 3: Separate concerns**
If a requirement mentions more than one bounded context (e.g., billing AND notifications), split it. Each requirement should have one reason to change.

**Step 4: Make boundaries explicit**
Where two concerns interact, state the contract: "The Order system notifies the Fulfillment system when an order is confirmed, providing: order ID, line items, and shipping address."

**Step 5: Surface the state machine**
If entities change status, describe the full lifecycle: states, transitions, guards, and side effects.

**Step 6: Remove implementation bias**
Strip out technology references, UI specifics, and solution assumptions. Keep only the what and why.

**Step 7: Add extension points**
Where future variation is likely, make the requirement say "the system supports multiple [X]" rather than enumerating a fixed list with conditionals.

## Output Format

When rewriting requirements, produce this structure:

```markdown
## Requirement Review

### Original Requirement
[paste the original]

### Smells Detected
- [Smell name]: [brief explanation of where it appears]

### Rewritten Requirement
[the improved version]

### Architectural Impact
[1-2 sentences on how the rewrite leads to better code structure]

### Domain Model Suggested
[list the key entities/types/concepts that emerged from the rewrite]
```

## Agentic Coding: Parallel Work Streams

When rewriting requirements for agentic coding (multiple agents working in parallel), apply these additional principles:

### Independence Detection

Look for naturally independent concerns that can be developed simultaneously:

- **Separate bounded contexts** (e.g., Order Management, Payment Processing, Notification Service)
- **Independent features within the same context** (e.g., user registration, password reset, profile editing)
- **Orthogonal quality attributes** (e.g., feature implementation vs. monitoring/observability)

### Parallel Work Structure

For each independent work stream, specify:

1. **Clear boundaries:** What does this stream own?
2. **Explicit contracts:** What does it consume from others? What does it provide?
3. **Integration points:** Where/how do streams connect?
4. **Dependency ordering:** Which streams must complete before others can start?

### Example: E-Commerce System

**Sequential (traditional):**
```
Build the entire checkout flow: cart → address → payment → confirmation
```

**Parallel (agentic):**
```
Stream 1: Cart Management
- Add/remove items, quantity updates, cart persistence
- Provides: CartAPI with getCart(), updateItem() endpoints

Stream 2: Address Validation
- Address entry, validation against service, saved addresses
- Provides: AddressAPI with validateAddress(), saveAddress() endpoints

Stream 3: Payment Processing
- Payment method selection, charge processing, receipt generation
- Consumes: CartAPI (for total), AddressAPI (for shipping)
- Provides: PaymentAPI with processPayment() endpoint

Stream 4: Order Orchestration
- Coordinates cart, address, and payment into complete order flow
- Consumes: CartAPI, AddressAPI, PaymentAPI
- Provides: CheckoutAPI with completeOrder() endpoint
```

Streams 1, 2, and 3 can be built in parallel. Stream 4 depends on all three completing.

### Rewriting for Parallel Work

When rewriting requirements, explicitly identify:

```markdown
### Parallel Work Streams

**Stream [N]: [Name]**
- **Scope:** [What this stream owns]
- **Provides:** [APIs/interfaces/contracts it exposes]
- **Consumes:** [APIs/interfaces it depends on]
- **Dependencies:** [Which streams must complete first, if any]
- **Acceptance Criteria:**
  - [ ] [Testable criterion]
  - [ ] [Testable criterion]
```

### Integration Strategy

After identifying parallel streams, specify how they integrate:

- **Contract-first:** Define interfaces before implementation
- **Stub dependencies:** Stream 4 can start with mocked versions of Streams 1-3
- **Integration tests:** Define cross-stream tests that verify contracts hold
- **Integration order:** Which streams integrate first? (Start with high-risk integrations)

## Important Notes

- This skill rewrites requirements for architectural quality. It does NOT validate whether requirements are functionally correct or complete — that's a separate concern.
- Not every conditional in a requirement is bad. Simple binary conditions ("if the cart is empty, show empty state") are fine. Target chains of 3+ conditions on the same dimension — those are the ones that produce brittle code.
- The goal is NOT to make requirements abstract or vague. Good architecture-aware requirements are MORE precise, not less. They're precise about the domain model rather than about implementation details.
- When the original requirement is from a non-technical stakeholder, preserve the intent and business context while restructuring for architectural clarity. Add a plain-language summary alongside the rewritten version.
- For Claude Code usage: this skill is designed to be invoked BEFORE coding begins. The output should feed into spec files, TDD plans, or architecture decisions.

## Additional Resources

### Reference Files

For detailed before/after examples showing how requirement rewrites lead to different code architectures, consult:

- **`references/examples.md`** — Concrete examples of the seven smells and their fixes, including parallel work stream decompositions
