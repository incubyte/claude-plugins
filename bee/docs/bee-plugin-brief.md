# Bee Plugin Brief

## The One-Liner

Bee is a workflow navigator for developers using AI — it turns every developer into someone who knows how to get 10x outcomes from AI-assisted development.

---

## The Problem

AI coding tools are powerful. But there's a massive gap in how developers use them.

**The top 10%** have figured out a workflow: they write specs first, break work into slices, use TDD to give the AI clear success criteria, and review the output with care. They're getting 10x speed AND 10x quality. But their workflow lives in their head, maybe in a blog post, maybe in tribal knowledge shared with their team.

**The other 90%** are typing prompts like "add authentication to my app" and getting mediocre code that they spend hours debugging. Or they're not using AI at all because their first experience was underwhelming. They don't know what they don't know — they've never seen what a great AI-assisted workflow looks like.

The gap isn't in the AI. The gap is in the **workflow around the AI.**

---

## The Insight

The best developers using AI aren't doing anything magical. They're doing what great staff engineers have always done — but they've adapted it for AI:

1. **They start by understanding the problem** before touching code
2. **They break big things into small things** so the AI can succeed at each piece
3. **They give the AI clear success criteria** (tests, specs, acceptance criteria) so "done" is unambiguous
4. **They make architectural decisions upfront** so the AI puts code in the right places
5. **They review with intent** because AI-generated code has different failure modes than human code

This isn't revolutionary. It's just disciplined software engineering. But most developers skip these steps because they feel like overhead — especially when the AI makes it feel like you should just be able to say "build me X" and get a result.

**Bee makes the disciplined workflow the natural workflow.** It doesn't lecture. It doesn't enforce. It navigates — starting with "tell me what we're working on" and then smartly guiding the developer through the steps that make AI-assisted development actually work.

---

## What Bee Is

Bee is a **pair programming navigator** that sits inside Claude Code (as a plugin) and guides the developer through an effective AI-assisted development workflow.

Think of it like this: the developer is the driver. Claude Code is the car. **Bee is the GPS.**

- A GPS doesn't force you to take a specific route — but it knows the best routes
- A GPS adapts to where you are and where you're going — highway for long trips, side streets for quick errands
- A GPS tells you the next turn at the right time — not all the turns at once
- A GPS lets you ignore it — but you'd be slower without it

Bee works the same way:

- **"Tell me what we're working on"** — Bee starts every session by understanding the task
- **Navigates the right workflow** — a one-line fix gets a different route than a new feature
- **Presents decisions, not commands** — "Here are three approaches, here's why each works, which one fits?"
- **Makes the right thing the easy thing** — writing a spec before coding feels natural, not like overhead
- **Teaches as it goes** — "We're writing the test first because it gives the AI clear success criteria. Watch how much better the implementation comes out."

---

## Core Design Principles

### 1. Navigator, Not Enforcer

Bee suggests, presents options, and explains why. It never blocks the developer. If someone says "just code it," Bee says "Got it — let me ask one quick question so we build the right thing" and adapts. The developer always has the final say.

### 2. The Right Workflow for the Right Task

Not every task needs the same process. Bee assesses the work and navigates accordingly:

| Task | Bee's Navigation |
|---|---|
| Fix a typo | "I see it. Let me fix that." (No workflow needed) |
| Small UI change | "Quick spec: here's what I'll change. Sound right?" → implement |
| New feature | "Let me understand the requirements" → spec → plan → implement → review |
| Large feature | "Let's break this down into slices" → spec per slice → plan per slice → implement iteratively |

### 3. Teach by Doing, Not Lecturing

Bee doesn't explain TDD theory. It says: "I'm writing the test first — this gives the AI a clear definition of 'done' so the implementation comes out right. Watch." The developer learns the workflow by experiencing it, not by reading about it.

### 4. Developer as Driver

At every decision point, the developer sees structured options with rationale:

```
This feature touches the payment flow and has complex business rules.
Three approaches:

  ○ Quick build — implement directly, add tests after
     Fast, but we'll likely need to refactor the AI output
  ○ Spec first — write acceptance criteria, then implement with tests
     Takes 10 more minutes, but the AI output will be much closer to right
     (Recommended)
  ○ Full breakdown — spec → architecture decision → TDD plan per slice
     For when this needs to be bulletproof
  ○ Type something else...
```

The developer picks. Bee navigates from there.

### 5. Capture and Share What Works

The specs, plans, and decisions Bee helps create are saved as markdown files. This means:
- **The workflow is documented** — new team members can see how features were built
- **Sessions can be resumed** — pick up where you left off
- **Patterns emerge** — teams can see what workflow produces the best results
- **Knowledge transfers** — the "how" of great AI-assisted development becomes visible

---

## The Workflow

```
"Tell me what we're working on"
         │
         ▼
  ┌────────────┐
  │ UNDERSTAND │  What is this? How big? What's the risk?
  │            │  Quick scan of the codebase for context.
  └─────┬──────┘
        │
        │  Bee adapts the workflow to the task:
        │
        ├─ Trivial ───────────────────────────── Fix it → Done
        │
        ├─ Small ──► "Here's what I'll do" ──► Implement ──► Done
        │            (lightweight spec)
        │
        ▼ (Feature or larger)
  ┌────────────┐
  │  CONTEXT   │  Read the codebase. Understand patterns.
  │            │  Find what's already there. Spot opportunities.
  └─────┬──────┘
        │
        ▼
  ┌────────────┐
  │   PLAN     │  Build a spec (right-sized for the task).
  │            │  Choose architecture (when it matters).
  └─────┬──────┘  Break into slices (when it's big).
        │
        ▼
  ┌───────────────────────────────────────────────┐
  │  FOR EACH SLICE:                              │
  │                                               │
  │   ┌────────────┐                              │
  │   │  PREPARE   │  Create TDD plan / clear     │
  │   │            │  success criteria for the AI  │
  │   └─────┬──────┘                              │
  │         │                                      │
  │         ▼                                      │
  │   ┌────────────┐                              │
  │   │   BUILD    │  AI implements with clear     │
  │   │            │  criteria. Autonomous.        │
  │   └─────┬──────┘                              │
  │         │                                      │
  │         ▼                                      │
  │   ┌────────────┐                              │
  │   │   CHECK    │  Tests pass? Criteria met?   │
  │   │            │  Quality good?               │
  │   └─────┬──────┘                              │
  │         │                                      │
  │   [next slice]                                 │
  └───────────────────────────────────────────────┘
        │
        ▼
  ┌────────────┐
  │   REVIEW   │  Full picture. Ship recommendation.
  └────────────┘
```

---

## Phase Details

### "Tell Me What We're Working On"

Every Bee session starts the same way. Not with a command. Not with a flag. With a conversation.

The developer describes what they want — in whatever level of detail they have. Could be a Jira ticket. Could be "the login page is broken." Could be "we need a new analytics dashboard."

Bee listens, does a quick scan of the codebase to understand the context, and then navigates:

- **"This looks straightforward — I can see the fix. Want me to go ahead?"** (trivial)
- **"Got it. Let me make sure I understand the scope before I start."** (small)
- **"This is a meaty feature. Let me ask a few questions so we build it right."** (feature)
- **"This is big. Let's break it into pieces we can ship incrementally."** (epic)

The developer can always override: "Actually, just code it." Bee adapts.

---

### Understand (Context Gathering)

For anything beyond trivial, Bee reads the codebase to understand:

- What's the tech stack and architecture pattern?
- What test framework and patterns are in use?
- What conventions does the project follow?
- What's already there that's related to this task?
- Is there anything messy in the area we're about to work in?

This takes seconds. The developer doesn't even notice it's happening. But it means everything downstream is grounded in the actual codebase, not generic advice.

**Teaching moment (subtle):** "I see you have a service layer pattern with tests in `__tests__/`. I'll follow that same structure."

---

### Plan (Spec + Architecture)

Bee helps the developer think through what they're building before the AI starts coding. This is where most of the 10x leverage comes from.

**Why this matters for AI-assisted development:** The #1 reason AI-generated code misses the mark is ambiguous requirements. When you type "add user authentication," the AI has to guess hundreds of decisions. When you have a spec with clear acceptance criteria, the AI nails it.

**Bee makes this painless:**
- Asks ONE question at a time via structured choices
- Each question has smart defaults: "Most apps do X — does that work for you?"
- Adapts depth to the task — a small feature gets 3 questions, an epic gets a thorough interview
- Produces a clear, readable spec that serves as both the plan AND the documentation

**Architecture decisions (when they matter):**
- For most tasks: "Your codebase uses MVC. I'll follow that."
- For complex features: "This has significant business logic. Two approaches: keep it in the service layer (simpler) or extract a domain model (more testable). Here's the tradeoff..."

**Slicing (for large features):**
- Bee breaks epics into vertical slices — each delivers user-visible value
- "Instead of building all the database tables, then all the APIs, then all the UI — let's build one complete flow at a time. Slice 1: user can see their dashboard. Slice 2: user can filter by date."

**Teaching moment:** "I'm breaking this into slices because the AI works best with focused, well-defined tasks. A slice with 5 clear acceptance criteria will produce better code than a vague 'build the whole feature' prompt."

---

### Prepare (Success Criteria for the AI)

This is the step most developers skip — and it's the step that makes the biggest difference.

Before the AI writes production code, Bee creates clear success criteria. Depending on the architecture and task, this might be:

- **A TDD plan** — ordered test cases that define exactly what "done" looks like
- **Acceptance criteria with test scenarios** — less formal but still clear
- **A simple checklist** — for straightforward tasks

**Why this matters:** When you give an AI a test to make pass, the implementation is dramatically better than when you give it a vague description. The test IS the spec. There's no ambiguity about what "working" means.

**Pluggable planning strategies:**

| Approach | When Bee Suggests It | What It Produces |
|---|---|---|
| Outside-in TDD (onion) | Complex domain logic, hexagonal codebase | Double-loop TDD plan: integration test → adapters → use cases → domain → wiring |
| MVC TDD | Standard web app features | Route test → controller → service → model |
| Simple test-first | Small features, utilities | Unit test → implementation → edge cases |
| No formal plan | Trivial changes, bug fixes | Just go — the change is obvious |

The developer always picks. Bee recommends based on context.

**Teaching moment:** "I'm writing the integration test first. It'll fail — that's the point. Each step we take will fix one part of the failure. By the time all our tests pass, the feature works. This is called outside-in TDD, and it's especially powerful with AI because each test gives the AI an unambiguous target."

---

### Build (AI Implementation)

This is where the AI does what AI does best — writes code. But now it's writing code with:

- Clear success criteria (tests to pass, criteria to meet)
- Architectural context (where files go, what patterns to follow)
- A defined scope (one slice, not the whole feature)

Bee feeds the plan to the execution engine (Ralph Wiggum) as a checklisted document:

```
Read the TDD plan. Work on every item in order.
Mark each checkbox as you complete it.
Continue until all items are done.
```

The AI implements autonomously. Bee monitors progress.

**Teaching moment (after completion):** "Notice how the AI put the repository interface in the use-case layer, not the domain? That's because the TDD plan had it mock the persistence — the mock's shape became the interface. The architecture emerged from the tests."

---

### Check (Verification)

After each slice, Bee verifies:

- All tests pass
- Acceptance criteria are met
- The code follows project patterns
- No regressions in existing tests

If something's off, Bee loops back with specific guidance.

---

### Review (Full Picture)

After all slices are complete, Bee reviews the full body of work:

- Does every acceptance criterion have a test?
- Is the code consistent with project conventions?
- Is there unnecessary complexity?
- What's the commit story?
- How should this ship? (Ready to merge? Feature flag? Manual QA?)

**Teaching moment:** "I'm checking dependency direction — making sure no inner layer imports from an outer layer. This catches the #1 architecture mistake AI makes: taking shortcuts across boundaries."

---

## The Teaching Layer

Bee doesn't just navigate — it teaches. But subtly. Not lectures. Not links to articles. **Brief, contextual explanations at the moment they're relevant.**

| Moment | What Bee Says |
|---|---|
| Writing a spec | "The spec gives the AI unambiguous targets. Watch how much better the output is compared to a free-form prompt." |
| Writing test first | "The test defines 'done.' The AI will aim for this exact behavior instead of guessing." |
| Breaking into slices | "The AI works best with focused tasks. One slice at a time means fewer mistakes and easier review." |
| Placing a file | "This goes in the service layer because it orchestrates — it doesn't know about HTTP or databases." |
| Creating an interface | "This interface is the contract between layers. The AI can't take a shortcut across the boundary." |
| Choosing architecture | "MVC works great here — the business rules are simple. We'd reach for onion architecture if the domain logic were more complex." |

**Configurable:** Teams can turn teaching moments up (for juniors) or off (for seniors who just want navigation).

---

## What Bee Produces (Artifacts)

| Artifact | Where | Purpose |
|---|---|---|
| Spec | `docs/specs/[feature].md` | Requirements with acceptance criteria and checklists |
| TDD Plan | `docs/specs/[feature]-slice-N-tdd-plan.md` | Step-by-step implementation plan with checkboxes |
| ADR | `docs/adrs/NNN-[decision].md` | Architecture decisions with rationale (when significant) |
| Progress | Checkboxes in spec and plan files | Resumable state, visible progress |

These artifacts are the **knowledge capture**. When a new developer joins, they can read the specs and ADRs to understand not just what was built, but WHY and HOW.

---

## The AskUserQuestion UX

Bee's primary interaction model is structured choices via Claude Code's `AskUserQuestion`. This is what makes it a navigator, not a lecturer.

**Why structured choices matter:**
- Forces Bee to present clear, thought-through options
- Gives the developer just enough context to decide
- Makes the workflow feel collaborative, not prescriptive
- "Type something else" always available — never a locked path

**Examples:**

```
How should failed API calls be handled?

  ○ Fail fast — Return error immediately. Simple, easy to debug.
  ○ Retry with backoff — Retry up to 3 times. Better UX but more complex.
     (Recommended)
  ○ Queue for later — Store and retry async. Best UX but needs infrastructure.
  ○ Type something else...
```

```
This is a significant feature. How do you want to approach it?

  ○ Spec first — Let me understand the full scope, then we build
     methodically. ~15 min planning, saves hours of rework. (Recommended)
  ○ Start building — Jump in, figure it out as we go.
     Faster start, but we might need to backtrack.
  ○ Type something else...
```

---

## Technical Foundation

### Built on Claude Agent SDK

- **Subagents:** Each phase runs as an isolated agent with scoped tools
- **AskUserQuestion:** Native structured-choice UI
- **Hooks:** Lightweight guardrails (warnings, not blocks)
- **MCP servers:** State tracking, plan management
- **Sessions:** Resume long workflows
- **CLAUDE.md:** Project conventions respected
- **Plugin system:** One install, works on any repo

### Distribution

```bash
claude plugin install bee
```

### Execution Engine

Bee produces plans. Ralph Wiggum executes them. Clean separation of navigation and execution.

---

## Who This Is For

**Primary:** Developers who want to get more from AI-assisted development but don't have a workflow. Bee gives them one — immediately, without training.

**Secondary:** Teams who want consistent AI-assisted development practices. Bee provides a shared workflow that every developer follows, producing specs, TDD plans, and ADRs as natural byproducts.

**Tertiary:** Experienced developers who already have a workflow. Bee automates the parts they already do manually (spec writing, TDD planning, architecture decisions) and lets them focus on the creative decisions.

---

## What Bee Is Not

- **Not a replacement for the developer.** Bee navigates. The developer drives.
- **Not a process enforcer.** Bee suggests, explains, and adapts. Never blocks.
- **Not opinionated about one way.** Multiple architecture patterns, multiple planning strategies. The developer chooses.
- **Not always needed.** For a one-line fix, Bee says "I see it, let me fix that" and stays out of the way.
- **Not a training course.** Bee teaches by doing, in context, at the moment it matters. Not slides. Not videos. Just better outcomes that the developer experiences firsthand.

---

## Productization Path

| Phase | What | Timeline |
|---|---|---|
| **1. Internal dogfood** | Core navigator with onion TDD planner. Use on Incubyte projects. | 2-3 weeks |
| **2. Multiple planners** | Add MVC, event-driven, simple planners. Test on diverse codebases. | Month 2 |
| **3. Open-source core** | GitHub release. Community feedback and contributions. | Month 2-3 |
| **4. Team features** | Configurable teaching level, team analytics, shared conventions. | Month 3-4 |
| **5. CodeAid integration** | Bee as workflow layer, CodeAid as acceleration layer. | Month 4+ |
| **6. Client offering** | "AI-Assisted Craftsmanship" — install Bee + train the team. | Ongoing |

---

## Success Metrics

How we know Bee is working:

- **Adoption:** Developers keep using Bee after initial setup (not just trying it once)
- **Quality:** AI-generated code needs fewer revision cycles
- **Speed:** Features ship faster WITH tests and specs, not without them
- **Knowledge:** Specs and ADRs exist as natural byproducts, not extra work
- **Learning curve:** New developers get to productive AI-assisted workflow in hours, not weeks
