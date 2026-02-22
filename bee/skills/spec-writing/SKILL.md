---
name: spec-writing
description: "This skill should be used when writing specs, acceptance criteria, or slicing features into vertical slices. Contains adaptive depth by risk and out-of-scope capture."
---

# Spec Writing

## What Makes Good Acceptance Criteria

Each criterion is a single, testable statement. It describes one observable behavior in one sentence.

**Good:**
```markdown
- [ ] User can create an account with email and password
- [ ] Shows error when email is already taken
- [ ] Password must be at least 8 characters
- [ ] Sends welcome email after successful signup
```

**Bad:**
```markdown
- [ ] Handle user registration (How? What happens? What does the user see?)
- [ ] The registration feature works correctly (What does "correctly" mean?)
- [ ] Use bcrypt for password hashing with 12 salt rounds (Implementation, not behavior)
```

**The test:** Can a developer write a test from this criterion without asking clarifying questions? If yes, it's good. If no, it needs more detail.

### Rules for Good ACs

- **One behavior per AC.** If you wrote "and" in the middle, split it into two.
- **Observable outcome.** Someone can look at the screen or the API response and verify it.
- **No implementation details.** Say "Shows error when email is taken", not "Returns 409 Conflict with JSON error body."
- **Include error cases explicitly.** "Shows error when..." ACs are first-class, not afterthoughts.
- **No vague qualifiers.** Never use "correctly", "properly", "well", "appropriate" without defining what that means.

## Code in Specs

Small indicative code is fine when it clarifies intent:

```markdown
GOOD — API shape:
  POST /api/orders
  { userId, items: [{ productId, qty }] }
  → 201 { orderId, total, status }

GOOD — Data structure:
  Order: { id, userId, items[], total, status, createdAt }

BAD — Implementation logic:
  const order = await db.insert('orders', { ... });
```

Use code to show contracts and shapes. Never use code to show logic — that's the TDD planner's job.

## Vertical Slicing and Outside-In Thinking

These principles apply at every size — SMALL, FEATURE, and EPIC. They are not optional techniques for large tasks.

**Always slice by user-visible capability, not by technical layer.**

**Vertical (correct):**
- Slice 1: User can register with email and password (UI + API + DB + validation)
- Slice 2: User can log in and receive a session token (UI + API + auth logic)
- Slice 3: User can reset their password via email (UI + API + email service)

**Horizontal (wrong):**
- Slice 1: Create all database tables (users, sessions, password_resets)
- Slice 2: Build all API endpoints
- Slice 3: Build the UI

Why vertical wins:
- Each slice is independently testable and shippable
- You get feedback early — Slice 1 works end-to-end before you build Slice 2
- If priorities change, you have something complete, not three half-finished layers

**A good slice is:** independently releasable, testable in isolation, small enough for one TDD plan, and delivers user-visible value.

**Ordering:** Start with the walking skeleton — the thinnest end-to-end path. Each subsequent slice adds capability. Later slices can assume earlier slices work.

**Outside-in within each slice:** Order ACs from what the user experiences inward — UI behavior first, then API contract, then data. This ensures the spec reads like a user journey, not a technical blueprint.

## Adaptive Depth by Risk

Not every spec needs the same rigor:

**Low risk (internal tool, easy to revert):**
- 3-5 acceptance criteria
- Focus on happy path + basic error handling
- Quick confirmation, move on

**Moderate risk (user-facing, business logic):**
- 5-8 acceptance criteria
- Happy path + edge cases + error scenarios
- Consider failure modes

**High risk (payments, auth, data migration):**
- 8-12 acceptance criteria
- Happy path + edge cases + failure modes + security
- Concurrency (what if two users act simultaneously?)
- Data integrity (what if the process fails halfway?)

## Capturing Out-of-Scope

Explicitly state what you are NOT doing. This prevents scope creep during implementation and gives the AI clear boundaries.

Examples:
- "Out of scope: social login (Google, GitHub). Email/password only for this slice."
- "Out of scope: email verification. Users can log in immediately after registration."
- "Out of scope: rate limiting on the login endpoint. Will be added in a follow-up."

Without an explicit out-of-scope list, the AI may build features you didn't ask for.

## Spec Structure

### Single-Slice Feature

```markdown
# Spec: [Feature Name]

## Overview
[1-2 sentences: what and why]

## Acceptance Criteria
- [ ] [Testable behavior]
- [ ] [Error case]
- [ ] [Edge case]

## API Shape (if applicable)
[Indicative code — endpoints, request/response shapes]

## Out of Scope
- [What we're explicitly not doing]

## Technical Context
- Patterns to follow: [from codebase]
- Key dependencies: [existing code this integrates with]
- Risk level: [LOW/MODERATE/HIGH]
```

### Multi-Slice Feature (EPIC)

```markdown
# Spec: [Feature Name]

## Overview
[1-2 sentences: what and why]

## Slice 1: [Name — the walking skeleton]
- [ ] [AC]
- [ ] [AC]

## Slice 2: [Name — builds on Slice 1]
- [ ] [AC]
- [ ] [AC]

## Out of Scope
- [What we're explicitly not doing]

## Technical Context
- Patterns to follow: [from codebase]
- Risk level: [LOW/MODERATE/HIGH]
```

Checkboxes (`- [ ]`) track progress. Each AC gets checked off `[x]` when the verifier confirms it has a passing test.
