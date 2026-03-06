# Requirement Architect: Before/After Examples

## Example 1: E-Commerce Discount System

### Original (Conditional Chain Smell)

```
When a customer places an order:
- If the customer is a Gold member and the order total is above $100, apply 15% discount
- If the customer is a Gold member and the order total is below $100, apply 10% discount
- If the customer is a Silver member, apply 5% discount regardless of order total
- If the customer has a coupon code, apply the coupon discount after membership discount
- If the customer is a new customer (first order), apply 10% welcome discount instead of membership discount
- If the total discount exceeds 25%, cap it at 25%
```

### Smells Detected

- **Conditional Chain:** Six branches on customer type × order conditions
- **Implicit State Machine:** "new customer" is really a lifecycle state, not a type
- **God Requirement:** Mixes membership rules, coupon rules, and discount caps

### Rewritten

```
The system supports multiple Membership Tiers (Gold, Silver, Standard). Each tier
defines its own discount policy, which determines the discount percentage based
on the tier's rules and the order context.

A Customer progresses through a lifecycle: New → Active. New customers receive
a Welcome Discount Policy that supersedes their tier's default policy for their
first order.

Coupon Discounts are a separate concern. A Coupon has a discount value and
applicability rules. Coupons are applied independently of membership discounts.

A Discount Resolver combines applicable discounts (membership + coupon) for a
given order, applying a Maximum Discount Cap (currently 25%) as a system-wide
constraint.
```

### Architectural Impact

The rewrite produces: a `DiscountPolicy` interface with per-tier implementations, a `CustomerLifecycle` state machine, a `CouponService` as a separate module, and a `DiscountResolver` that composes policies. Adding a new tier means adding one class, not touching existing if/else chains.

### Domain Model

- **MembershipTier** (Gold, Silver, Standard)
- **DiscountPolicy** (per-tier behavior)
- **CustomerLifecycle** (New → Active)
- **WelcomeDiscountPolicy**
- **Coupon**
- **DiscountResolver**
- **MaximumDiscountCap** (system constraint)

### Parallel Work Streams

**Stream 1: Membership Tier System**
- **Scope:** Tier definitions and their discount policies
- **Provides:** `DiscountPolicy` interface, tier implementations
- **Consumes:** Nothing (core domain)
- **Dependencies:** None
- **Acceptance Criteria:**
  - [ ] Gold tier provides 15% discount for orders $100+
  - [ ] Gold tier provides 10% discount for orders under $100
  - [ ] Silver tier provides 5% discount for all orders
  - [ ] Standard tier provides 0% discount

**Stream 2: Customer Lifecycle System**
- **Scope:** Customer state tracking (New/Active)
- **Provides:** `CustomerLifecycle` state machine, `WelcomeDiscountPolicy`
- **Consumes:** Nothing (core domain)
- **Dependencies:** None
- **Acceptance Criteria:**
  - [ ] New customers are identified correctly
  - [ ] Welcome policy provides 10% discount on first order
  - [ ] Customer transitions to Active after first order

**Stream 3: Coupon System**
- **Scope:** Coupon management and application
- **Provides:** `CouponService` with validation and discount calculation
- **Consumes:** Nothing (core domain)
- **Dependencies:** None
- **Acceptance Criteria:**
  - [ ] Valid coupons apply their discount value
  - [ ] Invalid coupons are rejected
  - [ ] Expired coupons are handled

**Stream 4: Discount Resolution**
- **Scope:** Combining all discount sources and applying caps
- **Provides:** `DiscountResolver.calculateDiscount(order, customer, coupon)`
- **Consumes:** `DiscountPolicy`, `CustomerLifecycle`, `CouponService`
- **Dependencies:** Streams 1, 2, 3 must complete first
- **Acceptance Criteria:**
  - [ ] Membership and coupon discounts combine correctly
  - [ ] Welcome policy supersedes membership for new customers
  - [ ] Total discount is capped at 25%

---

## Example 2: Notification System

### Original (God Requirement + Implementation Leaking)

```
The system should send notifications to users. For email notifications, use
SendGrid API to send HTML emails. For push notifications, use Firebase Cloud
Messaging. When a user's order ships, send both email and push notification
with tracking number. When a payment fails, send only email with retry link.
When a new promotion is available, send push notification only. The system
should check user preferences in the MySQL database to see which notification
channels they've opted into before sending.
```

### Smells Detected

- **Implementation Leaking:** SendGrid, Firebase, MySQL are all solution choices
- **God Requirement:** Mixes notification delivery, business events, and user preferences
- **Conditional Chain:** Implicit "if event type is X, send via channels Y"

### Rewritten

```
The system publishes Domain Events when significant actions occur. Three initial
events are: Order Shipped, Payment Failed, and Promotion Available.

Each Domain Event declares which Notification Channels are relevant to it:
- Order Shipped → Email, Push
- Payment Failed → Email
- Promotion Available → Push

Each Notification Channel is responsible for formatting and delivering messages
appropriate to its medium. A channel receives the event and a message template,
and handles delivery independently.

Users maintain Notification Preferences that specify which channels they consent
to receive. The Notification Dispatcher respects these preferences, filtering
out channels the user has not opted into before delegating to channels.

Each event type defines the data payload it carries (e.g., Order Shipped
includes: order ID, tracking number, carrier name, estimated delivery date).
```

### Architectural Impact

This produces: an event-driven architecture with a `DomainEvent` base, separate `NotificationChannel` implementations (swappable — SendGrid today, Postmark tomorrow), a `NotificationDispatcher` that orchestrates, and `UserPreferences` as its own bounded context. Adding a new event or channel requires no changes to existing code.

### Domain Model

- **DomainEvent** (OrderShipped, PaymentFailed, PromotionAvailable)
- **NotificationChannel** (Email, Push — extensible)
- **NotificationPreferences**
- **NotificationDispatcher**
- **MessageTemplate** (per event × channel)

### Parallel Work Streams

**Stream 1: Domain Events**
- **Scope:** Event definitions and payloads
- **Provides:** `DomainEvent` interface, event types with data contracts
- **Consumes:** Nothing (core domain)
- **Dependencies:** None
- **Acceptance Criteria:**
  - [ ] OrderShipped event contains orderId, trackingNumber, carrier, estimatedDelivery
  - [ ] PaymentFailed event contains orderId, failureReason, retryUrl
  - [ ] PromotionAvailable event contains promotionId, description, expiryDate

**Stream 2: Notification Channels**
- **Scope:** Channel implementations (Email, Push)
- **Provides:** `NotificationChannel` interface, channel implementations
- **Consumes:** `DomainEvent` interface
- **Dependencies:** Stream 1 (needs event interface)
- **Acceptance Criteria:**
  - [ ] Email channel formats messages as HTML
  - [ ] Push channel formats messages with title and body
  - [ ] Each channel handles delivery errors gracefully

**Stream 3: User Preferences**
- **Scope:** User notification preferences management
- **Provides:** `NotificationPreferences` API (get/set preferences)
- **Consumes:** Nothing (core domain)
- **Dependencies:** None
- **Acceptance Criteria:**
  - [ ] Users can opt in/out of email notifications
  - [ ] Users can opt in/out of push notifications
  - [ ] Preferences persist across sessions

**Stream 4: Notification Dispatcher**
- **Scope:** Event routing and preference enforcement
- **Provides:** `NotificationDispatcher.dispatch(event, userId)`
- **Consumes:** `DomainEvent`, `NotificationChannel`, `NotificationPreferences`
- **Dependencies:** Streams 1, 2, 3 must complete first
- **Acceptance Criteria:**
  - [ ] Dispatcher routes events to correct channels
  - [ ] Dispatcher filters channels based on user preferences
  - [ ] Dispatcher handles channel failures without affecting other channels

---

## Example 3: Document Approval Workflow

### Original (Implicit State Machine + Temporal Coupling)

```
When a document is submitted, it goes to the reviewer. The reviewer can approve
or reject it. If rejected, the author can edit and resubmit. If approved, it
goes to the manager for final approval. The manager can approve, reject, or
send back to reviewer. If the manager approves, the document is published. If
the manager rejects, it goes back to the author. If sent back to reviewer, the
reviewer reviews again. Documents older than 30 days without action should be
auto-archived. Admins can force-approve at any stage.
```

### Smells Detected

- **Implicit State Machine:** Six states and many transitions buried in prose
- **Temporal Coupling:** "first reviewer, then manager" baked in as fixed sequence
- **Ambiguous Boundaries:** Mixing workflow rules, timeout policies, and admin overrides

### Rewritten

```
A Document follows an Approval Workflow defined by an explicit state machine:

States: Draft, In Review, Reviewer Approved, Manager Review, Published,
Rejected, Archived

Transitions:
- Draft → In Review: triggered by Author submitting
- In Review → Reviewer Approved: triggered by Reviewer approving
- In Review → Rejected: triggered by Reviewer rejecting
- Rejected → Draft: triggered by Author editing and resubmitting
- Reviewer Approved → Manager Review: automatic on reviewer approval
- Manager Review → Published: triggered by Manager approving
- Manager Review → Rejected: triggered by Manager rejecting
- Manager Review → In Review: triggered by Manager requesting re-review
- Any active state → Archived: triggered by Inactivity Policy (30 days
  with no state transition)

Admin Override: An Admin can transition any document directly to Published
from any active state. This is an override that bypasses the normal workflow
and is logged as an administrative action.

The Inactivity Policy is a separate time-based rule that monitors documents
and triggers archival. It operates independently of the approval workflow.
```

### Architectural Impact

The rewrite produces: a proper State Machine pattern (State interface + transitions), an `InactivityPolicy` as a separate scheduled service, and `AdminOverride` as a distinct capability. The workflow is data-driven and can be modified without code changes. Adding a new approval stage means adding a state and transitions, not rewriting control flow.

### Domain Model

- **Document**
- **ApprovalWorkflow** (state machine definition)
- **DocumentState** (Draft, InReview, ReviewerApproved, etc.)
- **StateTransition** (from, to, trigger, guard conditions)
- **InactivityPolicy**
- **AdminOverride** (audit-logged action)

### Parallel Work Streams

**Stream 1: State Machine Core**
- **Scope:** State machine definition and transition logic
- **Provides:** `ApprovalWorkflow` with state and transition definitions
- **Consumes:** Nothing (core domain)
- **Dependencies:** None
- **Acceptance Criteria:**
  - [ ] All states are defined (Draft, InReview, ReviewerApproved, ManagerReview, Published, Rejected, Archived)
  - [ ] All transitions are defined with triggers
  - [ ] Illegal transitions are rejected
  - [ ] State transitions are atomic

**Stream 2: Inactivity Policy Service**
- **Scope:** Time-based archival of inactive documents
- **Provides:** Scheduled job that detects and archives inactive documents
- **Consumes:** `ApprovalWorkflow` (to trigger Archived transition)
- **Dependencies:** Stream 1 (needs workflow interface)
- **Acceptance Criteria:**
  - [ ] Documents with no state change for 30 days are detected
  - [ ] Detected documents transition to Archived state
  - [ ] Policy runs on configurable schedule

**Stream 3: Admin Override Capability**
- **Scope:** Administrative force-approve functionality
- **Provides:** `AdminOverride.forcePublish(documentId, adminId, reason)`
- **Consumes:** `ApprovalWorkflow` (to trigger Published transition)
- **Dependencies:** Stream 1 (needs workflow interface)
- **Acceptance Criteria:**
  - [ ] Admin can transition any document to Published
  - [ ] Override action is logged with admin ID and reason
  - [ ] Override bypasses normal workflow guards

**Stream 4: Document Management API**
- **Scope:** User-facing document operations
- **Provides:** `DocumentAPI` with submit, approve, reject operations
- **Consumes:** `ApprovalWorkflow`, `InactivityPolicy`, `AdminOverride`
- **Dependencies:** Streams 1, 2, 3 must complete first
- **Acceptance Criteria:**
  - [ ] Authors can submit documents
  - [ ] Reviewers can approve/reject
  - [ ] Managers can approve/reject/send-back
  - [ ] Admins can force-approve
  - [ ] All actions respect state machine rules

---

## Example 4: Access Control

### Original (Conditional Chain — classic)

```
When a user tries to access a resource:
- If the user is an admin, allow access to everything
- If the user is a manager, allow access to their department's resources and reports
- If the user is an employee, allow access only to their own resources
- If the user is a contractor, allow access only to resources explicitly shared with them
- If the user is inactive, deny all access
- If the resource is marked public, allow access regardless of role
```

### Smells Detected

- **Conditional Chain:** Six branches on role type
- **Missing Domain Language:** "resource" is too generic — what kinds?
- **Ambiguous Boundaries:** Mixes role-based access, resource visibility, and account status

### Rewritten

```
The system uses Role-Based Access Control (RBAC) where each Role defines an
Access Policy that determines what Resources a user with that role can reach.

Roles and their access scopes:
- Admin: unrestricted access across all organizational boundaries
- Manager: access scoped to their Department and its contained resources
- Employee: access scoped to resources they own
- Contractor: access scoped to resources in their explicit Access Grant list

Each role's Access Policy is a self-contained rule. The Authorization Service
evaluates access by delegating to the user's role-specific policy.

Account Status is a separate concern from role-based access. An Inactive
account has all access suspended regardless of role. Account status is
evaluated before role-based policies.

Resource Visibility is an independent attribute. A Resource marked as Public
bypasses role-based evaluation entirely. Visibility is evaluated before
role-based policies.

Evaluation order: Account Status → Resource Visibility → Role Access Policy.
```

### Architectural Impact

Each role's access policy becomes its own class implementing an `AccessPolicy` interface. Account status and resource visibility are evaluated as separate middleware/guards before role policies. Adding a new role = adding one policy class and registering it. No existing code changes.

### Domain Model

- **Role** (Admin, Manager, Employee, Contractor — extensible)
- **AccessPolicy** (per-role implementation)
- **Resource** (with Visibility attribute: Public, Restricted)
- **AccountStatus** (Active, Inactive)
- **AccessGrant** (for explicit sharing)
- **AuthorizationService** (composes status check + visibility check + role policy)
- **Department** (organizational boundary for scoping)

### Parallel Work Streams

**Stream 1: Access Policy Framework**
- **Scope:** Core RBAC interfaces and policy definitions
- **Provides:** `AccessPolicy` interface, `Role` enum, policy implementations
- **Consumes:** Nothing (core domain)
- **Dependencies:** None
- **Acceptance Criteria:**
  - [ ] Admin policy allows all access
  - [ ] Manager policy scopes to department
  - [ ] Employee policy scopes to owned resources
  - [ ] Contractor policy checks access grants

**Stream 2: Account Status Guard**
- **Scope:** Account status checking
- **Provides:** `AccountStatusGuard.isActive(userId)`
- **Consumes:** Nothing (user data)
- **Dependencies:** None
- **Acceptance Criteria:**
  - [ ] Active accounts pass the guard
  - [ ] Inactive accounts fail the guard
  - [ ] Guard executes before policy evaluation

**Stream 3: Resource Visibility**
- **Scope:** Public resource handling
- **Provides:** `ResourceVisibility.isPublic(resourceId)`
- **Consumes:** Nothing (resource data)
- **Dependencies:** None
- **Acceptance Criteria:**
  - [ ] Public resources bypass policy checks
  - [ ] Restricted resources require policy evaluation
  - [ ] Visibility check executes after status guard

**Stream 4: Authorization Service**
- **Scope:** Authorization orchestration
- **Provides:** `AuthorizationService.canAccess(userId, resourceId)`
- **Consumes:** `AccountStatusGuard`, `ResourceVisibility`, `AccessPolicy`
- **Dependencies:** Streams 1, 2, 3 must complete first
- **Acceptance Criteria:**
  - [ ] Evaluation follows correct order (status → visibility → policy)
  - [ ] Inactive users are denied regardless of role
  - [ ] Public resources are accessible to all active users
  - [ ] Role policies are evaluated for restricted resources
