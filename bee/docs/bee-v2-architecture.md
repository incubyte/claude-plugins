# Bee v2: Architecture for an AI Development Workflow Navigator

## Built on the Claude Agent SDK

---

## Executive Summary

Bee is an orchestration layer built on the **Claude Agent SDK** that guides developers through an effective AI-assisted development workflow. It starts with "tell me what we're working on," assesses the task, and navigates the developer through the right level of process — from a one-line fix (just do it) to an epic (spec → architecture → TDD plans → iterative execution → review).

The developer is the driver. Claude Code is the car. **Bee is the GPS.**

### What Changed from v1

| Bee v1 | Bee v2 |
|---|---|
| Enforces spec-driven TDD mechanically | **Navigates** the right workflow for the task |
| Fixed 4-phase pipeline for every task | **Adaptive** — triage determines the workflow shape |
| Problem: "developers skip process" | Problem: **"developers don't have a workflow for AI"** |
| Hooks block writes until spec exists | Hooks **warn**, never block. Developer always has final say. |
| One architecture (onion) | **Architecture as a choice** — pluggable TDD planners |
| Custom autonomous loop | **Ralph Wiggum** as execution engine. Bee plans, Ralph builds. |
| Spec + TDD plan coupled | **Decoupled** — spec first, then plan(s). One plan per slice. |
| Teaches architecture inline | **Teaches the AI workflow** — why specs help AI, why tests define "done" |
| Target: enforce discipline | Target: **make every developer 10x with AI** |

---

## 1. Why the Claude Agent SDK

| Capability | What It Means for Bee |
|---|---|
| **AskUserQuestion** | Bee's primary interaction model. Structured choices with rationale. Developer steers via multi-choice. "Type something else" always available. |
| **Subagents** | Each phase (triage, context, spec, plan, review) runs isolated with scoped tools and context |
| **Built-in tools** (Read, Write, Edit, Bash, Glob, Grep) | Agents read codebases, run tests, edit files natively |
| **Hooks** (PreToolUse, Stop) | Lightweight guardrails — warn before writing code without a spec, but never block |
| **MCP servers** (in-process) | Custom tools for workflow state, plan tracking, architecture validation |
| **Sessions** | Pause and resume. Essential for large features that span multiple sittings. |
| **CLAUDE.md** | Project-level conventions respected. Bee learns from the project. |
| **Plugins** | Bee will ship as an installable plugin. Currently standalone `.claude/` for dogfooding. |

---

## 2. High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                       Bee CLI / Plugin                        │
│           "Tell me what we're working on"                     │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ON STARTUP: Check docs/specs/ for in-progress specs.    │ │
│  │ If found: "Found spec for [feature], 2/5 slices done.  │ │
│  │           Resume where we left off?" (AskUserQuestion)  │ │
│  │ If none: "Tell me what we're working on."               │ │
│  └─────────────────────────────────────────────────────────┘ │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────────┐
│                    ORCHESTRATOR                                │
│                                                               │
│  Workflow state: { size, risk, teachingLevel, workflow }       │
│  Risk assessed at triage, flows to ALL downstream agents.     │
│  Teaching level configurable: on | subtle | off               │
│                                                               │
│  ┌────────────┐                                               │
│  │ UNDERSTAND  │  Assess: size + risk + complexity             │
│  │  + TRIAGE   │  Quick codebase scan (Glob, Grep)            │
│  └─────┬──────┘  AskUserQuestion: recommend workflow          │
│        │                                                      │
│        │  ┌─ risk: low | moderate | high ─┐                   │
│        │  │  Flows to every phase below.   │                  │
│        │  │  Low → lighter everything      │                  │
│        │  │  High → thorough everything    │                  │
│        │  └────────────────────────────────┘                  │
│        │                                                      │
│        ├── Trivial ──► QUICK FIX ──► run tests ──► Done       │
│        │               (subagent)                             │
│        │               scoped write tools                     │
│        │               targets specific fix                   │
│        │                                                      │
│        ├── Small ──► Lightweight spec ──► Build ──► Done      │
│        │             (confirm via AskUserQuestion)             │
│        │                                                      │
│        ▼ Feature / Epic                                       │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │ Context │→ │  Tidy?  │→ │  Spec   │→ │  Arch   │         │
│  │ Gather  │  │  (opt)  │  │ Builder │  │ Advisor │         │
│  └─────────┘  └─────────┘  └─────────┘  └────┬────┘         │
│  (subagent)   (subagent)   (subagent)    (subagent)           │
│  read-only    full tools   read+write    read-only            │
│  flags tidy   separate     (spec files)  (+ write ADR)        │
│  opps +       commit                     + YAGNI check        │
│  cross-cuts                                                   │
│                                  │                            │
│       ┌──────────────────────────┘                            │
│       │                                                       │
│       ▼  PER SLICE:                                           │
│  ┌──────────┐  ┌─────────┐  ┌─────────┐                     │
│  │ Prepare  │→ │  Build  │→ │  Check  │──► [next slice]      │
│  │(TDD Plan)│  │ (Ralph) │  │(Verify) │                      │
│  └──────────┘  └─────────┘  └─────────┘                      │
│  (subagent)    (ralph)      (subagent)                        │
│  planner       full tools   read-only                         │
│  selected by                risk-aware:                       │
│  arch choice                high risk →                       │
│                             more thorough                     │
│                             checks                            │
│                                                               │
│       After all slices:                                       │
│  ┌─────────┐                                                  │
│  │ Review  │  risk-aware ship recommendation:                 │
│  └─────────┘  low → "ready to merge"                          │
│  (subagent)   moderate → "team review"                        │
│  read-only    high → "feature flag + QA"                      │
│                                                               │
└───────────────────────┬──────────────────────────────────────┘
                        │
           ┌────────────┼────────────┐
           ▼            ▼            ▼
    ┌──────────┐ ┌──────────┐ ┌──────────┐
    │  MCP:    │ │  MCP:    │ │  MCP:    │
    │  State   │ │  Plan    │ │  Arch    │
    │ Tracker  │ │ Manager  │ │ Educator │
    │          │ │          │ │          │
    │ +risk    │ │          │ │ +YAGNI   │
    │ +teaching│ │          │ │  check   │
    │  level   │ │          │ │          │
    └──────────┘ └──────────┘ └──────────┘
```

### What the Diagram Shows (and Why)

**Session resume** — Bee checks for existing in-progress specs on startup. If found, offers to continue. No lost work across sessions.

**Risk flows everywhere** — Triage assesses risk once. That assessment travels to every downstream phase: lighter specs for low-risk, thorough TDD plans for high-risk, feature-flag recommendations for high-risk reviews.

**Tidy First** — Optional phase between Context and Spec. Triggered when context gathering flags messiness (broken tests, dead code, long functions). Always a separate commit. Can be skipped.

**Quick Fix agent** — Trivial tasks get a concrete subagent with scoped write tools. It makes the fix, runs tests, done. No spec, no plan, no ceremony.

**YAGNI in Architecture** — The Arch Educator MCP includes a YAGNI check: "How many implementations will this interface have? If one with no foreseeable reason to swap, skip the abstraction."

**Teaching level** — Configurable state (on/subtle/off) that flows to every subagent. On for juniors learning the workflow, off for seniors who just want navigation.

---

## 3. Implementation: Phase by Phase

### The Orchestrator

The orchestrator is the brain of Bee. Everything flows through it.

> **Implementation note:** The orchestrator is implemented as a **command** (`.claude/commands/build.md`), not a subagent. This is a deliberate divergence from the original design. Per the Claude Code docs, subagents cannot spawn other subagents. Since the orchestrator needs to delegate to agents like quick-fix, context-gatherer, and spec-builder, it must run in the main conversation context. A command achieves this — the `/bee:build` slash command injects the orchestrator prompt into the main conversation, which can then use the Task tool to spawn subagents.

**Responsibilities:**

- **Session resume**: On startup, scan `docs/specs/` for in-progress specs with unchecked slices. Offer to continue or start fresh.
- **Triage**: Listen to the developer, quick-scan the codebase, assess size (trivial/small/feature/epic) and risk (low/moderate/high). Store both in workflow state.
- **Route to workflow**: Based on triage, pick the right path — quick fix, lightweight confirm-and-build, or full spec→plan→build→review.
- **Compose phases**: Invoke subagents in the right order via the Task tool. Pass context between them. Track progress.
- **Navigate decisions**: Every fork is an `AskUserQuestion` with options and rationale. Developer always steers.
- **Manage teaching level**: Read teaching config (on/subtle/off), ensure subagents respect it.
- **Adapt when overridden**: If the developer says "just code it," don't argue. Ask one clarifying question and proceed.

**Tools:** All tools available in the main conversation context (Read, Glob, Grep, Task, AskUserQuestion). Does NOT write files directly — delegates to subagents via Task.

**Implementation:** `.claude/commands/build.md` — a slash command invoked with `/bee:build` or `/bee:build [task description]`. Supports `$ARGUMENTS` for inline task descriptions. The full orchestrator prompt lives in this file. See the actual file for the complete prompt.

**Subagents available to the orchestrator (spawned via Task):**

| Agent | Slice | Purpose |
|-------|-------|---------|
| quick-fix | 1 | Trivial fixes — make the change, run tests, done |
| context-gatherer | 2 | Read codebase patterns, flag tidy opportunities |
| tidy | 2 | Optional cleanup, separate commit |
| spec-builder | 3 | Interview developer, build testable spec |
| architecture-advisor | 3 | Evaluate architecture options, YAGNI check |
| tdd-planner-onion | 4 | Outside-in TDD plan for onion/hexagonal |
| tdd-planner-mvc | 4 | TDD plan for MVC codebases |
| tdd-planner-simple | 4 | Simple test-first plan |
| verifier | 5 | Post-slice quality gate |
| reviewer | 5 | Final review, ship recommendation |

---

### Quick Fix Agent

The fast path. For typos, config changes, and obvious one-liners where any workflow would be overhead.

**Responsibilities:**

- **Make the fix**: Apply the specific change the developer described. Nothing more.
- **Run tests**: Execute the relevant test suite to confirm the fix doesn't break anything.
- **Handle failures**: If tests fail, present options — fix the test, revert the change, or let the developer decide.
- **Stay scoped**: No spec, no plan, no review. This is a one-liner, treat it like one.

**Tools:** Full write access (Read, Write, Edit, Bash), but scoped intent — only touch the specific fix.

**When triggered:** Orchestrator triage classifies the task as TRIVIAL.

```typescript
const quickFix: AgentDefinition = {
  description: "Handles trivial fixes — typos, config changes, obvious one-liners. Makes the fix and runs tests.",
  prompt: `You are Bee handling a trivial fix.

    1. Make the specific fix the developer described.
    2. Run the relevant test suite (or full suite if quick).
    3. If tests pass: report success. Done.
    4. If tests fail: report what broke and ask the developer
       via AskUserQuestion:
       - "Fix the test too" / "Revert my change" / Type something else

    Keep it tight. No spec, no plan, no ceremony.
    This is a one-liner, treat it like one.`,
  tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "AskUserQuestion"],
};
```

---

### Context Gatherer

The eyes. Reads the codebase before any decisions are made so everything downstream is grounded in reality, not assumptions.

**Responsibilities:**

- **Map the project**: Identify tech stack, build system, folder layout, and dependency structure.
- **Detect architecture pattern**: Is this MVC, onion/hexagonal, event-driven, simple, or a mix? Describe what's actually there, not what should be there.
- **Identify test patterns**: What framework (Jest, Pytest, RSpec...)? Where do tests live? What's the naming convention? Integration vs unit split?
- **Read project conventions**: CLAUDE.md, linting rules, code style, commit conventions.
- **Scan the change area**: What already exists that relates to the task? What can we reuse (DRY)? What dependencies will the new code touch?
- **Flag tidy opportunities**: Broken/skipped tests, dead code, long functions (>50 lines) we're about to modify, confusing naming, missing test coverage in code we'll depend on. These feed the optional Tidy phase.
- **Flag cross-cutting concerns**: Does this change need logging? Auth checks? Caching? Audit trails? Rate limiting?

**Output:** Structured summary with sections for each of the above, plus a dedicated "Tidy Opportunities" section. Does NOT write any code.

**Tools:** Read-only (Read, Glob, Grep). No writes.

**When triggered:** Any task beyond TRIVIAL.

```typescript
const contextGatherer: AgentDefinition = {
  description: "Reads the codebase to understand patterns, conventions, and the area being changed. Run before planning.",
  prompt: `You are a codebase analyst. Quick and thorough.

    1. Project structure: package.json, build configs, folder layout
    2. Architecture pattern: MVC, onion, event-driven, simple, or mixed
       - Describe what you found in plain language
    3. Test framework and patterns: what's used, where tests live
    4. CLAUDE.md and project conventions
    5. The SPECIFIC AREA being changed:
       - What's already there? (DRY — don't rebuild what exists)
       - Is the area messy? Flag tidy opportunities.
       - Cross-cutting concerns? (logging, auth, caching, etc.)
    6. Existing specs, ADRs, documentation patterns

    ## TIDY OPPORTUNITIES

    Flag these specifically (they'll feed the optional Tidy phase):
    - Broken or skipped tests in the area
    - Dead code (unused imports, unreachable branches)
    - Long functions (>50 lines) that we're about to modify
    - Confusing naming that will make the new code harder to follow
    - Missing test coverage in code we're about to depend on

    Output a structured summary with a separate "Tidy Opportunities"
    section. Do NOT write any code.`,
  tools: ["Read", "Glob", "Grep"],
};
```

---

### Tidy Agent

The campground rule — leave the area cleaner than you found it. Optional phase, separate commit.

**Responsibilities:**

- **Fix broken tests**: Un-skip or fix any failing/skipped tests in the area we're about to build in.
- **Remove dead code**: Unused imports, unreachable branches, commented-out blocks.
- **Extract long functions**: If we're about to modify a 100-line function, extract it first so the new change is cleaner.
- **Improve naming**: Rename confusing variables/functions that will make the new code harder to follow.
- **Add missing coverage**: If we're about to depend on code with no tests, add basic coverage first.
- **Verify cleanup**: Run tests after tidying to confirm nothing broke.
- **Escalate risky tidy tasks**: If a cleanup is large or risky (e.g., major refactor), skip it and flag for the developer via AskUserQuestion.

**Rules:**
- Always a SEPARATE COMMIT. Cleanup and feature work never mix in the same commit.
- Only tidy what's in the flagged area. No refactoring sprees.
- If teaching=on, explain: "I'm tidying first so we start clean. Separate commit — cleanup and features should never mix."

**Tools:** Full write access (Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion).

**When triggered:** Context Gatherer flags tidy opportunities AND orchestrator presents the option to developer (who can skip).

```typescript
const tidyAgent: AgentDefinition = {
  description: "Cleans up the area before building. Separate commit. Optional — skipped if area is clean.",
  prompt: `You are Bee tidying up before building.

    The context gatherer flagged tidy opportunities. Address them:
    - Fix broken or skipped tests
    - Remove dead code and unused imports
    - Extract long functions if we're about to modify them
    - Rename confusing variables/functions
    - Add missing test coverage for code we'll depend on

    ## RULES
    - SEPARATE COMMIT. This is cleanup, not feature work.
    - Only tidy what's in the flagged area. Don't go on a refactoring spree.
    - Run tests after tidying to make sure nothing broke.
    - If a tidy task is risky (large refactor), skip it and flag
      it for the developer via AskUserQuestion.

    Teaching moment (if teaching=on): "I'm tidying the area first
    so we start clean. This goes in a separate commit — cleanup and
    features should never mix."`,
  tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "AskUserQuestion"],
};
```

---

### Spec Builder

The most leveraged phase in the entire workflow. A 10-minute spec saves hours of AI rework. This agent interviews the developer and produces a clear, testable specification.

**Responsibilities:**

- **Adapt depth to task size**: Small features get 3-5 acceptance criteria and a quick confirmation. Features get a full spec. Epics get a spec plus vertical slices.
- **Interview via structured choices**: ONE question at a time via AskUserQuestion. Smart defaults ("Most apps handle this with X — does that work?"). Focus on scope, edge cases, failure modes, and out-of-scope.
- **Adapt depth to risk level**: Low risk → fewer questions, focus on happy path. High risk → thorough interview including failure modes, auth edge cases, concurrent access, data integrity.
- **Slice epics vertically**: Break large features into slices where each slice delivers user-visible value (UI + backend + data for one capability). NOT horizontal layers.
- **Capture out-of-scope explicitly**: What are we NOT doing? This prevents scope creep during implementation.
- **Include technical context**: Architecture pattern (from context gathering), test patterns to follow, existing code to reuse.
- **Persist as markdown with checkboxes**: Save to `docs/specs/[feature-name].md`. Each acceptance criterion and each slice gets a checkbox for tracking.
- **Get developer confirmation**: Must confirm via AskUserQuestion before any downstream work begins.

**Spec depth by task size and risk:**

```
                        Low Risk          Moderate Risk       High Risk
                    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
  Small             │ 3-5 ACs      │  │ 5-7 ACs      │  │ 5-7 ACs      │
                    │ inline        │  │ inline        │  │ + failure     │
                    │ quick confirm │  │ confirm       │  │   modes       │
                    └──────────────┘  └──────────────┘  └──────────────┘
                    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
  Feature           │ Full spec     │  │ Full spec     │  │ Full spec     │
                    │ 3-5 questions │  │ 5-8 questions │  │ 8-12 questions│
                    │               │  │ + edge cases  │  │ + failure     │
                    │               │  │               │  │ + security    │
                    │               │  │               │  │ + concurrency │
                    └──────────────┘  └──────────────┘  └──────────────┘
                    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
  Epic              │ Full spec     │  │ Full spec     │  │ Full spec     │
                    │ + 2-4 slices  │  │ + 3-5 slices  │  │ + 3-5 slices  │
                    │ lightweight   │  │ thorough      │  │ + risk per    │
                    │               │  │               │  │   slice       │
                    └──────────────┘  └──────────────┘  └──────────────┘
```

**Output format:**

```markdown
# Spec: [Feature Name]
## User Story
As a [who], I want [what], so that [why].

## Slice 1: [Name]
- [ ] AC1: Given [context], when [action], then [result]
- [ ] AC2: ...

## Slice 2: [Name]
- [ ] AC1: ...

## Out of Scope
- [Explicitly not doing]

## Technical Context
- Architecture: [from context gathering]
- Patterns to follow: [from codebase]
- Risk level: [from triage]
```

**Tools:** Read, Write (spec files only), Glob, Grep, AskUserQuestion, MCP state tools.

**When triggered:** Feature or Epic workflow, after Context Gathering (and optional Tidy).

```typescript
const specBuilder: AgentDefinition = {
  description: "Interviews the developer and builds a spec. Depth adapts to task size.",
  prompt: `You are Bee building a spec. Your goal: give the AI unambiguous targets.

    ## WHY SPECS MATTER FOR AI

    The #1 reason AI code misses the mark is ambiguous requirements.
    "Add authentication" forces the AI to guess 100 decisions.
    A spec with clear acceptance criteria means the AI nails it.

    ## ADAPTIVE DEPTH

    Based on the task assessment:
    - SMALL: 3-5 acceptance criteria. Quick confirmation. Done.
    - FEATURE: Full spec — user story, acceptance criteria, out of scope,
      technical context. Save to docs/specs/.
    - EPIC: Full spec PLUS break into vertical slices. Each slice
      delivers user-visible value independently.

    ## INTERVIEW VIA STRUCTURED CHOICES

    Use AskUserQuestion. ONE question at a time.
    Each question: 2-4 options with rationale.

    Smart defaults: "Most apps handle this with [X]. Does that work?"

    Focus on:
    - Scope: what changes? What does NOT change?
    - Edge cases: empty inputs, auth failures, concurrent access?
    - Failure modes: what happens when things go wrong?
    - Out of scope: what are we explicitly NOT doing?

    ## SLICING (for epics)

    Slices are VERTICAL — each includes UI + backend + data for
    one capability. NOT horizontal (all tables, then all APIs, then all UI).

    Each slice must be:
    - Independently releasable
    - Testable in isolation
    - Small enough for one TDD plan

    Teaching moment: "I'm slicing vertically because the AI works
    best with focused, complete tasks. Each slice gives us something
    we can test and ship."

    ## OUTPUT FORMAT

    Save to docs/specs/[feature-name].md:

    # Spec: [Feature Name]
    ## User Story
    As a [who], I want [what], so that [why].

    ## Slice 1: [Name]
    - [ ] AC1: Given [context], when [action], then [result]
    - [ ] AC2: ...

    ## Out of Scope
    - [Explicitly not doing]

    ## Technical Context
    - Architecture: [from context gathering]
    - Patterns to follow: [from codebase]

    Confirm with developer via AskUserQuestion:
    "Does this spec capture what you want?"
    - "Yes, let's proceed" / "Mostly — but change [X]" / Type something else

    MUST get confirmation before proceeding.`,
  tools: ["Read", "Write", "Glob", "Grep", "AskUserQuestion", "mcp__bee__*"],
};
```

---

### Architecture Advisor

Most of the time this agent says "follow existing patterns" and moves on. It only presents options when the task genuinely warrants a decision.

**Responsibilities:**

- **Follow existing patterns by default**: If the codebase is MVC and the feature fits MVC, say so and move on. No unnecessary decisions.
- **Present options when warranted**: New modules, complex domain logic that strains the current pattern, greenfield projects, or developer explicitly asks.
- **Present 2-3 options with concrete tradeoffs**: Each option gets a name, why it fits, and the tradeoff. Via AskUserQuestion.
- **YAGNI check**: Before recommending any abstraction (interface, port, adapter), ask: how many implementations will this have right now? If one with no foreseeable swap reason — skip it. Use the concrete implementation. Extract an interface later when the second implementation arrives.
- **Risk-aware recommendations**: Low risk → prefer simpler architecture. High risk → prefer more structure, testability, and clear boundaries.
- **Record the decision**: Store architecture choice in MCP state so the correct TDD planner is selected downstream.
- **Write ADRs for significant decisions**: If the decision deviates from existing patterns, write a brief ADR to `docs/adrs/`. Format: Context → Options → Decision → Consequences.

**Decision flow:**

```
Context Gatherer detected architecture: [pattern]
                  │
                  ▼
     Does this feature fit the existing pattern?
          │                    │
         YES                  NO
          │                    │
          ▼                    ▼
  "Following existing     Present 2-3 options
   [pattern]. No change   via AskUserQuestion
   needed."               with tradeoffs
          │                    │
          │                    ▼
          │              Developer picks
          │                    │
          │              ┌─────┴──────┐
          │              │ Deviates   │ Follows
          │              │ from       │ existing?
          │              │ existing?  │
          │              ▼            ▼
          │         Write ADR    No ADR needed
          │              │            │
          └──────────────┴────────────┘
                         │
                         ▼
              Store in MCP state →
              Planner selection uses this
```

**Tools:** Read, Write (ADR files only), Glob, Grep, AskUserQuestion, MCP state tools.

**When triggered:** Feature or Epic workflow, after Spec is confirmed. Skipped when existing patterns clearly apply.

```typescript
const architectureAdvisor: AgentDefinition = {
  description: "Evaluates architecture options when the task warrants a decision. Most tasks: follow existing.",
  prompt: `You are Bee in architecture mode.

    ## FIRST RULE
    Follow existing codebase patterns unless there's a strong reason not to.
    If the codebase is MVC and this feature fits MVC: "The codebase uses MVC
    and this fits. No change needed." → Move on.

    ## WHEN TO PRESENT OPTIONS
    - New module or subsystem
    - Complex domain logic that the current pattern handles poorly
    - Developer explicitly asked
    - Greenfield project

    ## HOW TO PRESENT
    Use AskUserQuestion with 2-3 options. Each option includes:
    - What it is (1-2 words)
    - Why it fits (1 sentence)
    - The tradeoff (1 sentence)

    Example:
    "This feature has complex scoring rules. Three approaches:"
    - "MVC (current pattern) — Consistent. Rules live in services. Risk:
       service files grow as rules get complex."
    - "Onion / Hexagonal — Pure domain core. Rules are trivially testable.
       More structure upfront. (Recommended for complex rules)"
    - "Keep it simple — Inline logic. Fastest. Refactor when it hurts."

    ## YAGNI CHECK

    Before recommending abstractions, ask yourself:
    - How many implementations will this interface have RIGHT NOW?
    - Is there a concrete, foreseeable reason to swap implementations?
    - If the answer is "one implementation, no foreseeable swap":
      SKIP the interface/port. Just use the concrete implementation.
      You can always extract an interface later when the second
      implementation actually arrives.

    This is especially important with AI — the AI loves to generate
    interfaces and abstractions. Push back on unnecessary indirection.

    Teaching moment (if teaching=on): "I'm skipping the interface here
    — there's only one implementation and no reason to swap. We can
    always extract one later. YAGNI — You Aren't Gonna Need It."

    ## RISK-AWARE DECISIONS

    Read the risk level from workflow state:
    - Low risk: prefer simpler architecture. "Keep it simple" is a
      valid and often best choice.
    - High risk: prefer more structure. Testability and clear
      boundaries matter more when failure is expensive.

    ## ADR (for significant decisions)
    Write to docs/adrs/ if the decision deviates from existing patterns.
    Brief: Context → Options → Decision → Consequences.

    Teaching moment: "An ADR captures WHY we chose this, so future-us
    doesn't have to guess."`,
  tools: ["Read", "Write", "Glob", "Grep", "AskUserQuestion", "mcp__bee__*"],
};
```

---

### TDD Planners (Pluggable)

The step most developers skip — and the step that makes the biggest difference for AI-generated code quality. Each planner produces a checklisted, ordered plan that gives the AI unambiguous targets.

**Shared responsibilities (all planners):**

- **One plan per slice**: Never plan the whole feature at once. Each slice gets its own focused plan.
- **Checkbox convention**: Every step gets `- [ ]` for Ralph to mark `- [x]` as completed.
- **Execution header**: Every plan starts with instructions for Ralph (read in order, mark checkboxes, flag stuck items).
- **Persist as markdown**: Save to `docs/specs/[feature]-slice-N-tdd-plan.md`.
- **Risk-aware depth**: Low risk → happy path + basic edge cases. High risk → defensive tests, error handling, boundary conditions, security checks.
- **Present plan for approval**: Show the plan to the developer via AskUserQuestion before execution begins.

**Planner selection:**

The orchestrator selects the planner based on the architecture decision from the Architecture Advisor.

```
Architecture Decision
         │
         ├── onion / hexagonal ──────► Onion TDD Planner
         │                             (outside-in double-loop)
         │
         ├── mvc ────────────────────► MVC TDD Planner
         │                             (route → controller → service → model)
         │
         ├── event-driven ───────────► Event-Driven TDD Planner
         │                             (contract → producer → consumer)
         │
         └── simple / default ───────► Simple TDD Planner
                                       (test → implement → verify)
```

**Comparison of planner strategies:**

```
┌─────────────────────────────────────────────────────────────────────┐
│                     ONION TDD PLANNER                                │
│                                                                      │
│  Outer Integration Test (RED — stays red until fully wired)          │
│       │                                                              │
│       ▼                                                              │
│  Inbound Adapter (controller/handler)                                │
│  Test: HTTP request → correct use-case call                          │
│       │                                                              │
│       ▼                                                              │
│  Use Case + Domain                                                   │
│  Test: business rules with mocked outbound ports                     │
│  Domain is PURE — zero external dependencies                         │
│  Mock shapes BECOME the port interfaces                              │
│       │                                                              │
│       ▼                                                              │
│  Outbound Adapter (repo, gateway, client)                            │
│  Test: real integration (DB, API, filesystem)                        │
│       │                                                              │
│       ▼                                                              │
│  Wiring / Composition Root                                           │
│  Outer integration test goes GREEN                                   │
│                                                                      │
│  Key insight: architecture EMERGES from the tests.                   │
│  The mocks define the contracts. The contracts become ports.         │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      MVC TDD PLANNER                                 │
│                                                                      │
│  Outer Integration Test (RED)                                        │
│       │                                                              │
│       ▼                                                              │
│  Route / Controller                                                  │
│  Test: request → correct service call → correct response shape       │
│  Controller is THIN — delegates to service                           │
│       │                                                              │
│       ▼                                                              │
│  Service                                                             │
│  Test: business logic + orchestration (mock repo/model)              │
│       │                                                              │
│       ▼                                                              │
│  Model / Repository                                                  │
│  Test: data access + validation (integration test, real DB)          │
│       │                                                              │
│       ▼                                                              │
│  Wire — outer test goes GREEN                                        │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                   SIMPLE TDD PLANNER                                 │
│                                                                      │
│  For each behavior:                                                  │
│    Write failing test → Implement minimum to pass → Refactor         │
│                                                                      │
│  Then: Edge case tests → Run full suite                              │
│                                                                      │
│  No layers. No ports. Just test → implement → verify.                │
└─────────────────────────────────────────────────────────────────────┘
```

**Tools (all planners):** Read, Write (plan files), Glob, Grep, AskUserQuestion, MCP state tools.

**When triggered:** After Spec is confirmed and Architecture is decided. One invocation per slice.

```typescript
function selectPlanner(architecture: string): string {
  switch (architecture) {
    case "onion":
    case "hexagonal":    return "tdd-planner-onion";
    case "mvc":          return "tdd-planner-mvc";
    case "event-driven": return "tdd-planner-event";
    default:             return "tdd-planner-simple";
  }
}
```

**Onion TDD Planner** (the attached `tdd-requirement-planner` agent):

```typescript
const onionTDDPlanner: AgentDefinition = {
  description: "Generates outside-in TDD plan for onion/hexagonal architecture. One plan per slice.",
  prompt: `[Full tdd-requirement-planner prompt from the attached agent definition]

    ADDITIONAL:
    - Generate ONE plan per spec slice
    - Save to docs/specs/[feature]-slice-N-tdd-plan.md
    - Every step has a checkbox [ ] for Ralph to mark [x]
    - Include execution header:

      ## Execution Instructions
      Read this plan. Work on every item in order.
      Mark each checkbox done as you complete it ([ ] → [x]).
      Continue until all items are done.
      If stuck after 3 attempts, mark ⚠️ and move to next independent step.

    Teaching moment: "This plan starts from the outside — the user-facing
    boundary — and works inward. Each test drives out the interface for the
    next layer. The architecture emerges from the tests."`,
  tools: ["Read", "Write", "Glob", "Grep", "AskUserQuestion", "mcp__bee__*"],
};
```

**MVC TDD Planner:**

```typescript
const mvcTDDPlanner: AgentDefinition = {
  description: "Generates TDD plan for MVC architecture. One plan per slice.",
  prompt: `You are a TDD planner for MVC codebases.

    Generate a checklisted TDD plan following MVC layer order:

    ## Outer Test
    - [ ] Integration test for the user journey (stays RED until wired)

    ## Route / Controller
    - [ ] Test: request → correct service call → correct response shape
    - [ ] Implement controller (thin — delegates to service)

    ## Service
    - [ ] Test: business logic and orchestration (mock model/repo)
    - [ ] Implement service

    ## Model / Repository
    - [ ] Test: data access and validation (integration test, real DB)
    - [ ] Implement model + migration if needed

    ## Wire
    - [ ] Connect layers. Outer test should pass.

    Same file format and checkbox conventions as other planners.`,
  tools: ["Read", "Write", "Glob", "Grep", "AskUserQuestion", "mcp__bee__*"],
};
```

**Simple TDD Planner** (for straightforward tasks):

```typescript
const simpleTDDPlanner: AgentDefinition = {
  description: "Generates a simple test-first plan. For small features and utilities.",
  prompt: `Generate a straightforward test-first plan:

    For each behavior in the acceptance criteria:
    - [ ] Write failing test for [behavior]
    - [ ] Implement minimum code to pass
    - [ ] Refactor if needed

    Then:
    - [ ] Edge case tests
    - [ ] Run full suite

    Keep it tight. No layers, no ports. Just test → implement → verify.`,
  tools: ["Read", "Write", "Glob", "Grep", "AskUserQuestion", "mcp__bee__*"],
};
```

---

### Execution: Ralph Wiggum

The hands. Bee plans, Ralph builds. Clean separation — Bee produces the highest-quality prompt (a checklisted TDD plan) and Ralph executes it mechanically.

**Responsibilities:**

- **Execute the TDD plan in order**: Read the plan file, work through each step sequentially.
- **Mark progress**: Update checkboxes as each step completes (`[ ]` → `[x]`).
- **Handle stuck items**: If stuck on a step after 3 attempts, mark `⚠️` and move to the next step that doesn't depend on the stuck one.
- **Stay autonomous**: No questions to the developer during execution. The plan should be unambiguous enough that Ralph doesn't need clarification.
- **Respect safety limits**: Max 50 iterations per slice to prevent runaway execution.

**What Ralph does NOT do:**
- Make architectural decisions (those are in the plan)
- Skip steps or reorder them (follow the plan exactly)
- Ask the developer questions (that's Bee's job)
- Generate its own tests (the plan specifies them)

Bee does NOT implement its own autonomous loop. It delegates to Ralph.

```typescript
async function executeSlice(planPath: string) {
  // Feed the TDD plan to Ralph
  const prompt =
    `Read ${planPath} and work on every item in the exact order listed. ` +
    `As you complete each step, mark the checkbox done ([ ] → [x]). ` +
    `Continue until all items are marked done. ` +
    `If stuck on a step after 3 attempts, mark ⚠️ and move to ` +
    `the next step that doesn't depend on the stuck one.`;

  await invokeRalph(prompt, { maxIterations: 50 });
}
```

---

### Verifier

The quality gate between slices. Runs after Ralph completes a slice to confirm everything is solid before moving on.

**Responsibilities:**

- **Check plan completion**: All checkboxes marked `[x]`? Any `⚠️` stuck items that need attention?
- **Run full test suite**: Everything green? Any regressions in existing tests?
- **Validate acceptance criteria**: Does the implementation actually meet this slice's AC from the spec? If yes, mark the slice checkbox `[x]` in the spec file.
- **Check project patterns**: New files follow naming conventions? In the right directories?
- **Risk-aware additional checks**:
  - MODERATE+ risk: Error handling covered with tests? Edge cases tested? Layer boundaries respected?
  - HIGH risk: Input validation present? Auth checks in place? No N+1 queries? No unbounded loops?
- **Report clearly**: If all good, report success and ready for next slice. If issues, describe what needs fixing with specific file and line references.

**Tools:** Read, Write (spec checkboxes only), Edit, Bash (run tests), Glob, Grep, MCP state.

**When triggered:** After Ralph completes a slice. If verification fails, the orchestrator loops back to Ralph with fix instructions.

```typescript
const verifier: AgentDefinition = {
  description: "Verifies a completed slice — tests pass, criteria met, patterns followed. Risk-aware.",
  prompt: `A slice just completed. Verify:

    ## ALWAYS CHECK
    1. TDD plan: all checkboxes marked [x]? Any ⚠️ (stuck items)?
    2. Run full test suite — everything green?
    3. Check spec — this slice's acceptance criteria met?
       If yes, mark the slice checkbox [x] in the spec file.
    4. Quick pattern check — new files follow project conventions?

    ## RISK-AWARE CHECKS (read risk from workflow state)
    If MODERATE or HIGH risk, also check:
    5. Error handling: are failure modes covered with tests?
    6. Edge cases: are boundary conditions tested?
    7. Dependencies: does the new code respect layer boundaries?
       (No inner layer importing from outer layer)

    If HIGH risk, also check:
    8. Security: input validation, auth checks, SQL injection?
    9. Performance: N+1 queries, unbounded loops, missing pagination?

    If all good: report success, ready for next slice.
    If issues: describe what needs fixing. Be specific.`,
  tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "mcp__bee__*"],
};
```

---

### Reviewer

The final check. Steps back from the slices and looks at the complete body of work as a whole.

**Responsibilities:**

- **Spec coverage**: Every acceptance criterion across all slices has a passing test?
- **Pattern compliance**: Code follows project conventions? Dependency direction correct (no inner layer importing outer)?
- **Code quality**: Naming consistency, duplication, unnecessary complexity.
- **Test quality**: Tests describe behavior, not implementation details? Would they survive a refactor?
- **Commit story**: Is the git history reviewable? Could a teammate follow the progression?
- **Observability check**: How will we know this works in production? Are there log statements at key decision points? Are errors surfaced clearly (not swallowed)? For high-risk features: are there metrics or alerts to add?
- **Risk-aware ship recommendation**:
  - LOW risk → "Ready to merge. Tests pass, patterns followed. Ship it."
  - MODERATE risk → "Recommend team review before merging." + flag what another pair of eyes should check.
  - HIGH risk → "Recommend feature flag + team review." For data changes: "Consider canary deployment." For auth/payments: "Manual QA recommended."

**Tone:** Conversational, not bureaucratic. "Nice work. The domain logic is clean. Two things I'd change: [specific]. Everything else is solid."

**Tools:** Read-only (Read, Glob, Grep, Bash for running tests), MCP state.

**When triggered:** After all slices are verified complete.

```typescript
const reviewer: AgentDefinition = {
  description: "Reviews the complete body of work. Risk-aware ship recommendation.",
  prompt: `All slices complete. Review the full body of work.

    ## ALWAYS REVIEW
    1. SPEC COVERAGE: Every acceptance criterion has a passing test?
    2. PATTERNS: Code follows project conventions? Dependencies correct?
    3. QUALITY: Naming, duplication, complexity.
    4. TEST QUALITY: Tests describe behavior, not implementation?
    5. COMMIT STORY: Is the git history reviewable?

    ## OBSERVABILITY CHECK
    6. How will we know this works in production?
       - Are there log statements at key decision points?
       - Are errors surfaced clearly (not swallowed)?
       - For high-risk: are there metrics/alerts we should add?

    ## RISK-AWARE SHIP RECOMMENDATION

    Read risk from workflow state:

    LOW risk:
    - Default: "Ready to merge. Tests pass, patterns followed. Ship it."
    - Only escalate if something actually looks wrong.

    MODERATE risk:
    - Default: "Recommend a team review before merging."
    - Flag anything that another pair of eyes should check.

    HIGH risk:
    - Default: "Recommend feature flag + team review."
    - If it touches data: "Consider canary deployment or staged rollout."
    - If it touches auth/payments: "Manual QA recommended."

    ## TONE
    Be conversational: "Nice work. The domain logic is clean. Two things
    I'd change: [specific]. Everything else is solid."

    End with a clear, actionable recommendation.`,
  tools: ["Read", "Glob", "Grep", "Bash", "mcp__bee__*"],
};
```

---

## 4. Hooks: Smart Guardrails

Hooks warn. They don't block. The developer always has final say.

```typescript
async function softGuardrail(inputData: any) {
  const filePath = inputData.tool_input?.file_path || "";

  // Always allow: spec files, ADRs, test files, config
  const isSpecOrADR = filePath.startsWith("docs/");
  const isTest = filePath.includes(".test.") || filePath.includes(".spec.") || filePath.includes("__tests__");
  if (isSpecOrADR || isTest) return {};

  // For feature/epic workflows without a confirmed spec: WARN (not block)
  if (beeState.workflow !== "trivial" && beeState.workflow !== "small" && !beeState.specConfirmed) {
    return {
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        userFacingMessage:
          "💡 Writing production code before the spec is confirmed. " +
          "This is fine if intentional — just checking.",
      },
    };
  }

  return {}; // Allow everything else
}

const hooks: ClaudeAgentOptions["hooks"] = {
  PreToolUse: [
    HookMatcher({ matcher: "Write|Edit|MultiEdit", hooks: [softGuardrail] }),
  ],
};
```

---

## 5. MCP Server: State & Plan Tracking

```typescript
const beeServer = createSdkMcpServer({
  name: "bee",
  version: "2.0.0",
  tools: [
    tool("get_workflow_state", "Get current Bee workflow state — including risk and teaching level", {},
      async () => ({
        content: [{
          type: "text",
          text: JSON.stringify({
            workflow: beeState.workflow,        // trivial | small | feature | epic
            risk: beeState.risk,               // low | moderate | high
            teachingLevel: beeState.teaching,   // on | subtle | off
            phase: beeState.currentPhase,
            specConfirmed: beeState.specConfirmed,
            architecture: beeState.architecture,
            slices: beeState.slices,            // { id, status }[]
            currentSlice: beeState.currentSlice,
            tidyOpportunities: beeState.tidyOpportunities, // string[] from context gather
          })
        }]
      })
    ),

    tool("set_workflow_state", "Set workflow size and risk after triage.",
      {
        workflow: z.enum(["trivial", "small", "feature", "epic"]),
        risk: z.enum(["low", "moderate", "high"]),
      },
      async (args) => {
        beeState.workflow = args.workflow;
        beeState.risk = args.risk;
        return { content: [{ type: "text",
          text: `Workflow: ${args.workflow} | Risk: ${args.risk}`
        }] };
      }
    ),

    tool("set_teaching_level", "Configure teaching moment verbosity.",
      { level: z.enum(["on", "subtle", "off"]) },
      async (args) => {
        beeState.teaching = args.level;
        return { content: [{ type: "text",
          text: `Teaching level: ${args.level}`
        }] };
      }
    ),

    tool("flag_tidy_opportunities", "Record tidy opportunities from context gathering.",
      { opportunities: z.array(z.string()) },
      async (args) => {
        beeState.tidyOpportunities = args.opportunities;
        return { content: [{ type: "text",
          text: `Flagged ${args.opportunities.length} tidy opportunities`
        }] };
      }
    ),

    tool("confirm_spec", "Mark spec as confirmed by developer.",
      { sliceCount: z.number() },
      async (args) => {
        beeState.specConfirmed = true;
        beeState.slices = Array.from({ length: args.sliceCount }, (_, i) => ({
          id: i + 1, status: "pending" as const,
        }));
        return { content: [{ type: "text",
          text: `✅ Spec confirmed. ${args.sliceCount} slice(s) to implement.`
        }] };
      }
    ),

    tool("update_slice", "Update slice progress.",
      { sliceId: z.number(), status: z.enum(["pending","planning","building","checking","complete","blocked"]) },
      async (args) => {
        beeState.updateSlice(args.sliceId, args.status);
        const done = beeState.slices.filter(s => s.status === "complete").length;
        return { content: [{ type: "text",
          text: `Slice ${args.sliceId}: ${args.status} | ${done}/${beeState.slices.length} complete`
        }] };
      }
    ),

    tool("set_architecture", "Record the architecture choice.",
      { architecture: z.string(), adrPath: z.string().optional() },
      async (args) => {
        beeState.architecture = args.architecture;
        return { content: [{ type: "text",
          text: `Architecture: ${args.architecture}` + (args.adrPath ? ` | ADR: ${args.adrPath}` : "")
        }] };
      }
    ),

    tool("yagni_check", "Check if an abstraction is warranted. Returns recommendation.",
      {
        abstraction: z.string().describe("The interface/port/abstraction being considered"),
        implementationCount: z.number().describe("How many implementations exist or are planned"),
        swapReason: z.string().optional().describe("Why would we swap implementations?"),
      },
      async (args) => {
        const warranted = args.implementationCount > 1 ||
          (args.swapReason && args.swapReason !== "none" && args.swapReason !== "");
        return { content: [{ type: "text",
          text: warranted
            ? `✅ Abstraction warranted: ${args.implementationCount} implementations, reason: ${args.swapReason}`
            : `⚠️ YAGNI: Only ${args.implementationCount} implementation, no clear swap reason. Skip the abstraction — use the concrete implementation directly. Extract an interface later when you actually need it.`
        }] };
      }
    ),
  ],
});
```

---

## 6. The AskUserQuestion Pattern

Bee's primary interaction model. Every decision point uses this.

### SDK Schema

```typescript
// Per Claude Agent SDK / Claude Code
{
  questions: [{
    question: string,        // Full question with context
    header: string,          // Short label, max 12 chars
    multiSelect: boolean,    // Usually false for Bee
    options: [{
      label: string,         // 1-5 words, concise
      description: string,   // Tradeoff / rationale
    }],                      // 2-4 options
    // "Type something else" auto-added by SDK
  }]                         // 1-4 questions per call
}
```

### Decision Points

| Phase | Question | Example Options |
|---|---|---|
| **Understand** | "Here's my read. How should we approach this?" | Quick fix / Spec first (Rec) / Full breakdown |
| **Context** | "Found some messiness. Tidy first?" | Tidy (Rec) / Skip / Type something else |
| **Plan: Scope** | "What should this include?" | Core only (Rec) / Core + edge cases / Full feature |
| **Plan: Edge case** | "How should [X] be handled?" | [2-3 approaches with tradeoffs] |
| **Plan: Confirm** | "Does this spec capture it?" | Yes / Mostly but [change] |
| **Architecture** | "This has complex rules. Approach?" | MVC / Onion (Rec) / Simple |
| **Prepare** | "Here's the TDD plan. Ready?" | Yes / Adjust [X] first |
| **Review** | "How should this ship?" | Merge / Feature flag / Team review |

### Rules

- If Bee recommends: that option goes first with "(Recommended)" in label
- ONE question at a time during spec interviews (don't overwhelm)
- Options include just enough rationale to decide (1 sentence descriptions)
- Developer can ALWAYS type something else — never a locked path

---

## 7. The Slice Loop

Core execution flow for feature and epic workflows:

```typescript
async function executeFeature(spec: Spec) {
  const architecture = beeState.architecture || "simple";
  const plannerName = selectPlanner(architecture);

  for (const slice of spec.slices) {
    // 1. PREPARE — Generate TDD plan for this slice
    beeState.updateSlice(slice.id, "planning");
    const planResult = await runSubagent(plannerName, {
      specPath: spec.path,
      sliceId: slice.id,
      architecture,
    });

    // 2. BUILD — Ralph executes the plan
    beeState.updateSlice(slice.id, "building");
    await executeSlice(planResult.planPath);

    // 3. CHECK — Verify the slice
    beeState.updateSlice(slice.id, "checking");
    const verification = await runSubagent("verifier", {
      planPath: planResult.planPath,
      specPath: spec.path,
      sliceId: slice.id,
    });

    if (verification.passed) {
      beeState.updateSlice(slice.id, "complete");
      // Teaching moment: "Slice 1 done ✅ 2 of 3 to go."
    } else {
      // Re-run with specific fixes
      await executeSlice(planResult.planPath, { fixes: verification.issues });
    }
  }

  // All slices done — full review
  await runSubagent("reviewer", { specPath: spec.path });
}
```

---

## 8. The Teaching Layer

Not a separate system. Woven into every subagent via shared skills.

### How It Works

The teaching content lives in `.claude/skills/ai-workflow/SKILL.md` — the single source of truth for why spec-first, TDD-driven workflows produce better AI output. Agents don't duplicate this knowledge in their prompts; they reference the skill, and Claude Code auto-loads it into context.

The other skills (tdd-practices, architecture-patterns, spec-writing) provide domain knowledge that agents draw on contextually. This keeps agent prompts focused on behavior while skills provide the underlying reasoning.

Each subagent surfaces teaching moments as **brief, contextual comments** tied to specific actions:

```
When you write a spec:
  "This spec took 10 minutes but means the AI won't have to
   guess any of these decisions."

When you write a test first:
  "The test defines 'done.' Watch how much better the AI's
   implementation is when it has a clear target."

When you choose architecture:
  "MVC works great here — simple rules, simple structure.
   Onion would be overkill."

When you slice an epic:
  "The AI works best with focused tasks. One slice at a time."
```

### Configurable

```typescript
// In CLAUDE.md or plugin config
bee:
  teaching: "on"       # on | subtle | off
  # on: explain at every decision point
  # subtle: explain only at major decisions
  # off: just navigate, no explanations
```

---

## 9. Project Structure

> **Implementation note:** The original design described a TypeScript `src/` directory with a `plugin.json` manifest. During Slice 0 implementation, we diverged to a **standalone `.claude/` configuration** — pure markdown, no TypeScript, no build step. This follows the Claude Code docs recommendation: "Start with standalone configuration in `.claude/` for quick iteration, then convert to a plugin when you're ready to share." The plugin conversion will happen during the open-source phase (see Productization Path).

### Current Structure (Standalone)

```
bee/
├── .claude/
│   ├── commands/
│   │   └── build.md                # /bee:build slash command (orchestrator entry point)
│   ├── agents/                     # Subagent definitions (YAML frontmatter + markdown)
│   │   ├── quick-fix.md            # Slice 1: trivial fixes
│   │   ├── context-gatherer.md     # Slice 2: read codebase, flag tidy + cross-cuts
│   │   ├── tidy.md                 # Slice 2: optional cleanup, separate commit
│   │   ├── spec-builder.md         # Slice 3: interview → spec document
│   │   ├── architecture-advisor.md # Slice 3: options, YAGNI check, ADRs
│   │   ├── tdd-planner-onion.md    # Slice 4: outside-in double-loop TDD
│   │   ├── tdd-planner-mvc.md      # Slice 4: route → controller → service → model
│   │   ├── tdd-planner-simple.md   # Slice 4: test → implement → verify
│   │   ├── verifier.md             # Slice 5: post-slice quality gate
│   │   └── reviewer.md             # Slice 5: final review + ship recommendation
│   ├── skills/                     # Shared reference knowledge (auto-loaded into context)
│   │   ├── ai-workflow/SKILL.md    # Why spec-first + TDD improves AI output
│   │   ├── tdd-practices/SKILL.md  # Red-green-refactor, outside-in, test quality
│   │   ├── architecture-patterns/SKILL.md  # Onion vs MVC vs simple, YAGNI
│   │   └── spec-writing/SKILL.md   # Acceptance criteria, vertical slicing, adaptive depth
│   └── settings.json               # Hooks and permissions configuration
├── docs/
│   ├── bee-v2-architecture.md      # This document
│   ├── specs/                      # Feature specifications (generated by spec-builder)
│   └── adrs/                       # Architecture Decision Records
├── CLAUDE.md                       # Bee personality + project conventions (at project root)
└── README.md
```

### Key Structural Decisions

**`/bee` is a command, not an agent.** Lives in `.claude/commands/build.md`. Commands run in the main conversation context and can spawn subagents via Task. Agents (`.claude/agents/`) are subagents that Claude delegates to — they run in isolated context and cannot spawn other subagents.

**`CLAUDE.md` at project root, not inside `.claude/`.** Per Claude Code conventions, `CLAUDE.md` at the project root is automatically loaded into every conversation. It contains Bee's identity, navigation rules, and personality.

**Agent config via YAML frontmatter, not `settings.json`.** Each agent `.md` file has its own `name`, `description`, `tools`, and `model` fields in YAML frontmatter. `settings.json` is reserved for hooks and permission configuration.

**No TypeScript source.** The standalone configuration is pure markdown. Agent behavior is defined entirely through prompts in markdown files. MCP servers and hooks (described in Sections 4-5) will be revisited when converting to a plugin.

**Skills for shared knowledge, not duplicated prompts.** `.claude/skills/` contains reference knowledge (ai-workflow, tdd-practices, architecture-patterns, spec-writing) that Claude Code auto-loads into context. Agents reference these skills for domain knowledge rather than duplicating content in each agent prompt. This keeps agent prompts focused on behavior while skills provide the underlying "why."

### Future Structure (Plugin)

When converting to a distributable plugin, the structure will follow the Claude Code plugin format:

```
bee/
├── .claude-plugin/
│   └── plugin.json                 # Plugin manifest (name, version, description)
├── commands/
│   └── build.md                    # /bee:build slash command
├── agents/                         # Subagent definitions
│   └── ...
├── skills/                         # Shared reference knowledge
│   └── ...
├── hooks/
│   └── hooks.json                  # Guardrail hooks
├── .mcp.json                       # MCP server configuration (state tracking)
└── README.md
```

---

## 10. Distribution

### Current: Standalone (Slice 0 — Dogfooding)

Copy `.claude/`, `CLAUDE.md`, and `docs/` into any project:

```bash
cp -r bee/.claude /path/to/your-project/
cp bee/CLAUDE.md /path/to/your-project/
cp -r bee/docs /path/to/your-project/
```

Then invoke with `/bee` in Claude Code.

### Future: Plugin (Post-Dogfooding)

Once stable, Bee will be packaged as a Claude Code plugin with `.claude-plugin/plugin.json`:

```json
{
  "name": "bee",
  "version": "2.0.0",
  "description": "AI development workflow navigator — guides developers through effective AI-assisted development."
}
```

Skills will be namespaced as `/bee:build`. Installation via marketplace or `--plugin-dir`.

---

## 11. Key Design Decisions

1. **Navigator, not enforcer.** Bee suggests and explains. Never blocks. The developer always has final say. This is a philosophical choice: developers adopt tools that help them, not tools that constrain them.

2. **Triage-first.** The workflow shape emerges from the task, not from a fixed pipeline. A one-liner skips everything. An epic gets the full treatment. This is what makes Bee feel like a smart colleague, not a bureaucratic process.

3. **Risk flows everywhere.** Triage assesses risk once. That assessment influences every downstream phase: spec depth, TDD plan rigor, verification thoroughness, ship recommendation. A staff engineer's risk assessment changes everything about how they approach a task — Bee should too.

4. **AskUserQuestion as primary UX.** Structured choices with rationale. Forces Bee to think through options clearly. Gives the developer just enough to decide. "Type something else" as escape hatch. This is how a staff engineer communicates with their team — presenting options, not dictating.

5. **Spec and plan decoupled.** Different artifacts, different audiences, different cadences. A spec can be confirmed before any plan exists. A plan can be revised without changing the spec. This enables the workflow to flex.

6. **Pluggable TDD planners.** Architecture determines the TDD approach. Onion gets double-loop. MVC gets route-first. Simple gets test-implement-verify. New planners can be added without changing the orchestrator.

7. **Ralph as execution engine.** Bee plans, Ralph builds. Clean separation. Bee produces the highest-quality prompt (a checklisted TDD plan) and lets Ralph execute autonomously. No reinventing the autonomous loop.

8. **Hooks warn, never block.** A soft "💡 Writing code before spec is confirmed" is better than a hard block. The developer might have good reasons. Trust them.

9. **Teaching by doing, configurable.** No lectures, no links, no theory. Brief, contextual explanations at the moment they matter. Configurable via MCP state: "on" for juniors learning the workflow, "subtle" for mid-level (major decisions only), "off" for seniors who just want navigation.

10. **Artifacts as knowledge capture.** Specs, TDD plans, and ADRs are the natural byproducts of the workflow. They persist, they're readable, they transfer knowledge. The workflow produces documentation without anyone feeling like they're writing documentation.

11. **Tidy first, separate commit.** When the area is messy, clean it before building. Always a separate commit. Optional — Bee flags opportunities, developer decides. This prevents "while I'm in here" scope creep and keeps the git history clean.

12. **YAGNI as a first-class check.** AI loves generating interfaces and abstractions. Bee actively pushes back: "One implementation, no swap reason? Skip the interface." The abstraction can always be extracted later when the second implementation actually arrives.

13. **Session resume.** Specs and plans persist as markdown with checkboxes. On startup, Bee checks for in-progress work and offers to continue. No lost work across sessions. This is critical for features that span multiple sittings.

14. **Quick fix as a real path.** Trivial tasks get a concrete subagent — not a hand-wave. The most common task type deserves a defined, efficient path: fix it, run tests, done.

15. **Orchestrator as command, not subagent.** Per Claude Code docs, subagents cannot spawn other subagents. The orchestrator needs to delegate to quick-fix, context-gatherer, spec-builder, etc. — so it must run in the main conversation context. A command (`.claude/commands/build.md`) achieves this: it's user-invokable via `/bee:build` and can use the Task tool to spawn subagents. This is a divergence from the original design (which modeled the orchestrator as a `ClaudeAgentOptions` agent) driven by a platform constraint.

16. **Standalone first, plugin later.** The Claude Code docs recommend: "Start with standalone configuration in `.claude/` for quick iteration, then convert to a plugin when you're ready to share." During dogfooding, Bee uses standalone `.claude/` configuration — pure markdown, no build step, no TypeScript. This enables rapid iteration. Plugin conversion happens when we're ready to distribute.

---

## 12. Productization Path

| Phase | What | Timeline |
|---|---|---|
| **1. Internal dogfood** | Core navigator + onion planner. Incubyte projects. | 2-3 weeks |
| **2. Multiple planners** | MVC, event-driven, simple. Diverse codebases. | Month 2 |
| **3. Open-source core** | GitHub. Community feedback. | Month 2-3 |
| **4. Team features** | Configurable teaching, team analytics, shared conventions. | Month 3-4 |
| **5. CodeAid integration** | Bee = workflow, CodeAid = acceleration. | Month 4+ |
| **6. Client offering** | "AI-Assisted Craftsmanship" package. | Ongoing |
