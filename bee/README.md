# Bee

Bee is a Claude Code plugin that brings spec-driven, test-first engineering discipline to AI-assisted development — automatically scaling process to match the task.

**Why this exists.** Incubyte is a 140+ engineer software consultancy built on eXtreme Programming and software craftsmanship. We noticed AI coding tools are fast but undisciplined — they skip specs, ignore architecture, and produce code without tests. Bee encodes the engineering discipline our team practices daily into a plugin any developer can use with Claude Code.

**What makes it different.** Bee is process-aware, not just code-aware. It triages every task by size and risk, then navigates you through exactly the right amount of rigor — a typo gets fixed immediately, a payment flow gets a full spec, architecture review, TDD plan, and verification. No other Claude Code plugin delivers triage → spec → architecture → TDD → verify → review as one coherent workflow.

**What you get.** 7 commands, 17 specialist agents, design system awareness, session resume, and artifacts that capture *why* things were built — not just *what*. From onboarding new devs to migrating legacy systems to coaching your AI workflow habits.

> The developer is the driver. Claude Code is the car. Bee is the GPS.

Bee doesn't enforce process — it suggests. The developer always has final say.

## Install

```bash
# Add the Incubyte marketplace
claude plugin marketplace add incubyte/claude-plugins

# Install Bee
claude plugin install bee@incubyte-plugins
```

### Optional: Autonomous Execution with Ralph

Bee can hand off TDD plan execution to [Ralph Wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum), a persistent loop plugin by Anthropic. When installed, Bee detects it automatically and offers autonomous execution during the build phase.

```bash
claude plugin install ralph-wiggum@incubyte-plugins
```

Without Ralph, you drive execution manually by following the TDD plan checklist. Both paths work — Ralph just lets you walk away while it builds.

## Usage

### `/bee:build` — The Main Event

**What it is:** An opinionated workflow that codifies engineering discipline as a command. Spec before code. Tests before shipping. Review before merging. That's the default path — not a hope.

**Why it matters:** AI writes better code when it has clear targets. A 10-minute spec means the AI doesn't guess your requirements. A TDD plan means every line of code has a reason. Bee makes that the path of least resistance.

**How it works:** Tell it what you want to build. Bee assesses size and risk, then navigates you through exactly the right amount of process — no more, no less.

| Task size | What Bee does |
|-----------|--------------|
| Typo / config fix | Just fixes it |
| Small bug / UI tweak | Quick confirmation, then builds |
| New feature | Spec, architecture, TDD plan, verify, review |
| Epic / new subsystem | Breaks into shippable phases, full workflow per phase |

```
/bee:build add user authentication
```

Or start without a task — Bee asks what you're working on:

```
/bee:build
```

Picks up where you left off across sessions. Close your terminal mid-feature, come back later, it resumes.

### Standalone Commands

```
/bee:discover
```

A PM persona that interviews you (or synthesizes from meeting transcripts) and produces a client-shareable PRD. Works standalone for early-stage requirement exploration, or let `/bee:build` invoke it automatically when decision density is high.

```
/bee:review
```

Standalone code review with hotspot analysis, tech debt prioritization, and developer coaching. Independent of the build workflow — no spec or triage needed. Point it at a file, directory, or PR.

```
/bee:architect
```

Architectural health assessment grounded in domain language. Compares how a product describes itself (README, docs, website, marketing copy) against how the code is structured. Produces an assessment report with domain vocabulary mapping, boundary analysis, and runnable ArchUnit-style boundary tests — some passing (documenting good boundaries) and some intentionally failing (flagging architecture leaks).

```
/bee:onboard
```

Interactive developer onboarding for existing projects. Analyzes the codebase and delivers an adaptive walkthrough — architecture, entry points, domain concepts, tribal knowledge, dragons, and how to run/test/deploy. Adapts to the developer's role, experience level, and focus area. Includes MCQ knowledge checks.

```
/bee:migrate /path/to/legacy /path/to/new-app
```

Analyze a legacy and new codebase to produce a prioritized, independently-shippable migration plan. Reads both codebases, interviews you about goals, and writes a plan where each unit is a clean PR. Read-only — produces a plan, not code.

```
/bee:coach
```

Analyze your Claude Code sessions and get actionable coaching insights — workflow adoption, prompt quality, session efficiency, and code quality signals. Tracks trends over time.

## How It Works

Bee assesses every task on two axes — **size** and **risk** — then recommends the right workflow.

### Size

| Size | What it looks like | Bee's approach |
|------|-------------------|----------------|
| TRIVIAL | Typo, config change, one-liner | Fix it immediately |
| SMALL | Single-file bug, UI tweak | Quick confirmation, then build |
| FEATURE | New endpoint, new screen, multi-file | Spec, architecture, TDD plan, verify, review |
| EPIC | New subsystem, cross-cutting concern | Discovery, phased delivery, full workflow per phase |

### Risk

| Risk | Examples | Effect on workflow |
|------|----------|-------------------|
| LOW | Internal tool, easy to revert | Lighter spec, simpler plan |
| MODERATE | User-facing, business logic | Standard spec, proper TDD, team review recommended |
| HIGH | Payments, auth, data migration | Thorough spec, defensive tests, feature flag + QA recommended |

## The Workflow

For features and epics, Bee navigates you through these phases:

```
"Tell me what we're working on"
         |
         v
   [ TRIAGE ]        Assess size + risk. Route to the right workflow.
         |
         v
   [ CONTEXT ]       Read the codebase. Understand patterns, conventions,
         |            and design system signals.
         v
   [ TIDY ]          (Optional) Clean up the area before building. Separate commit.
         |
         v
   [ DESIGN ]        (When UI involved) Produce a design brief from the existing
         |            design system or interview for greenfield projects.
         v
   [ DISCOVERY ]     (When needed) Explore requirements when scope is uncertain.
         |
         v
   [ SPEC ]          Interview the developer. Build testable, design-aware
         |            acceptance criteria.
         v
   [ ARCHITECTURE ]  Evaluate options when warranted. Most tasks: follow existing patterns.
         |
         v
   [ TDD PLAN ]      Generate a step-by-step test-first implementation plan.
         |
         v
   For each slice:
   [ EXECUTE ]  -->  [ VERIFY ]  -->  [ next slice ]
         |
         v
   [ REVIEW ]        Full picture. Risk-aware ship recommendation.
```

### Design Awareness

Bee detects UI signals in the codebase — frontend frameworks, Tailwind configs, CSS custom properties, component libraries, design tokens. When UI work is detected:

- **Existing design system**: Bee extracts the color palette, typography, spacing, component patterns, and accessibility constraints into a design brief (`.claude/DESIGN.md`). All downstream work is constrained to the existing system — no invented colors, no off-system components.
- **Greenfield**: Bee interviews the developer about visual preferences (mood, brand colors, reference sites, logo) and proposes a cohesive design direction grounded in accessibility and design principles.

The design brief is a project-level artifact. It's created once and referenced by every subsequent UI task, so the project maintains a consistent visual language.

### Collaboration Loop

After discovery, spec, design brief, and TDD plan documents are produced, you can review them in your editor. Add `@bee` inline comments to request changes. Mark `[x] Reviewed` at the bottom to proceed. Type `check` when you're ready for Bee to re-read, or just keep chatting — Bee won't block the conversation while you review.

### Session Resume

Close your terminal mid-feature? No problem. Bee persists progress in `docs/specs/.bee-state.md`. Next time you run `/bee:build`, it picks up exactly where you left off — including design brief status, discovery doc path, current phase, and slice progress.

## Artifacts Produced

| Artifact | Location | Purpose |
|----------|----------|---------|
| Design Brief | `.claude/DESIGN.md` | Project-level visual constraints for UI work |
| Specs | `docs/specs/[feature].md` | Requirements with acceptance criteria |
| Discovery Docs | `docs/specs/[feature]-discovery.md` | Problem statement, hypotheses, milestone map |
| TDD Plans | `docs/specs/[feature]-slice-N-tdd-plan.md` | Step-by-step implementation plans with checkboxes |
| ADRs | `docs/adrs/NNN-[decision].md` | Architecture decisions with rationale |
| State | `docs/specs/.bee-state.md` | Session resume tracking |

These artifacts are knowledge capture — when a new developer joins, they can read the specs, discovery docs, and design brief to understand not just what was built, but why and how.

## Agents

Bee ships with 17 specialist agents:

| Agent | Role |
|-------|------|
| `quick-fix` | Handle trivial fixes end-to-end |
| `context-gatherer` | Read codebase — patterns, conventions, and design system signals |
| `tidy` | Clean up the area before building |
| `design-agent` | Produce a design brief from existing design systems or greenfield interviews |
| `discovery` | PM persona that interviews users and produces a client-shareable PRD. Works standalone or inside `/bee:build` |
| `spec-builder` | Interview developer, write testable and design-aware specs |
| `architecture-advisor` | Evaluate architecture options, YAGNI check |
| `tdd-planner-onion` | Outside-in TDD for onion/hexagonal architecture |
| `tdd-planner-mvc` | Layer-by-layer TDD for MVC codebases |
| `tdd-planner-cqrs` | Split command/query TDD for CQRS systems |
| `tdd-planner-event-driven` | Contract-first TDD for event-driven systems |
| `tdd-planner-simple` | Straightforward test-implement-verify |
| `verifier` | Post-slice quality gate |
| `reviewer` | Final review with ship recommendation |
| `domain-language-extractor` | Extract domain vocabulary from docs, website, and code; flag vocabulary drift and boundary mismatches |
| `architecture-test-writer` | Generate runnable ArchUnit-style boundary tests from an architecture assessment report |
| `onboard` | Interactive developer onboarding — codebase walkthrough adapted to role, experience, and focus area |

## Skills

Shared reference knowledge that agents draw on:

- **clean-code** — SRP, DRY, YAGNI, naming, error handling
- **tdd-practices** — Red-green-refactor, outside-in, test quality
- **architecture-patterns** — When to use onion vs MVC vs simple
- **spec-writing** — Acceptance criteria, vertical slicing, adaptive depth
- **ai-workflow** — Why spec-first TDD produces better AI-generated code
- **collaboration-loop** — Inline review with `@bee` annotations
- **code-review** — Review methodology, hotspot analysis, coupling detection, effort sizing
- **design-fundamentals** — Accessibility rules, typography, spacing, responsive breakpoints, visual quality checklist

## Project Structure

```
bee/
├── .claude-plugin/
│   └── plugin.json               # Plugin manifest
├── commands/
│   ├── build.md                   # /bee:build orchestrator
│   ├── coach.md                   # /bee:coach session coaching insights
│   ├── architect.md              # /bee:architect architecture assessment
│   ├── discover.md               # /bee:discover standalone discovery
│   ├── help.md                    # /bee:help interactive guided tour
│   ├── migrate.md                 # /bee:migrate migration planning
│   ├── onboard.md                # /bee:onboard interactive developer onboarding
│   └── review.md                 # /bee:review standalone code review
├── agents/
│   ├── quick-fix.md
│   ├── context-gatherer.md
│   ├── tidy.md
│   ├── design-agent.md
│   ├── discovery.md
│   ├── spec-builder.md
│   ├── architecture-advisor.md
│   ├── tdd-planner-onion.md
│   ├── tdd-planner-mvc.md
│   ├── tdd-planner-cqrs.md
│   ├── tdd-planner-event-driven.md
│   ├── tdd-planner-simple.md
│   ├── verifier.md
│   ├── reviewer.md
│   ├── domain-language-extractor.md
│   ├── architecture-test-writer.md
│   └── onboard.md
├── skills/
│   ├── clean-code/
│   ├── tdd-practices/
│   ├── architecture-patterns/
│   ├── spec-writing/
│   ├── ai-workflow/
│   ├── collaboration-loop/
│   ├── code-review/
│   └── design-fundamentals/
├── docs/
│   ├── specs/                    # Generated specs, TDD plans, state
│   └── adrs/                    # Architecture Decision Records
├── CLAUDE.md                     # Bee personality + conventions
└── README.md
```

## Design Decisions

**Why `/bee:build` is a command, not an agent.** Claude Code subagents cannot spawn other subagents. Since the orchestrator delegates to 14 agents, it must run as a command in the main conversation context.

**Navigator, not enforcer.** Bee suggests the right process but never blocks. Say "just code it" and Bee asks one clarifying question, then proceeds.

**Risk flows downstream.** A HIGH risk triage means deeper specs, more defensive tests, and stricter review recommendations. LOW risk means lighter everything. The developer doesn't have to think about calibration — Bee handles it.

**Design is project-level, not task-level.** The design brief (`.claude/DESIGN.md`) is created once and persists across features. A TRIVIAL CSS fix and an EPIC redesign reference the same brief. This keeps the project visually consistent without re-deriving the design system every time.

**Design and discovery are independent.** Both consume the context-gatherer output, but neither blocks the other. Design triggers on UI involvement. Discovery triggers on decision density. A task can need both, one, or neither.

## License

Proprietary.
