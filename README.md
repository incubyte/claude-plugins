# Bee

Bee is an AI development workflow navigator for Claude Code. It guides developers through the right level of process for each task — from a one-line fix (just do it) to an epic (spec, architecture, TDD plans, iterative execution, review). The developer is the driver, Claude Code is the car, and Bee is the GPS.

## Usage

Copy the `.claude/` directory and `CLAUDE.md` into any project, then invoke with:

```
/bee add user authentication
```

Or just:

```
/bee
```

Bee will greet you with "Tell me what we're working on" and guide you from there.

## Current Status

**Slice 0** — Project skeleton with orchestrator triage only.

The `/bee` command performs task assessment (size + risk) and recommends a workflow. Downstream phases (context gathering, spec building, TDD planning, execution, verification, review) are defined as placeholder agents that will be implemented in subsequent slices.

## What's Coming

| Slice | What |
|-------|------|
| 1 | Quick Fix agent — the fast path for trivial tasks |
| 2 | Context Gatherer + Tidy agents |
| 3 | Spec Builder + Architecture Advisor |
| 4 | TDD Planners (onion, MVC, simple) |
| 5 | Verifier + Reviewer |

See [docs/bee-v2-architecture.md](docs/bee-v2-architecture.md) for the full design.

## Structure

```
bee/
├── .claude/
│   ├── commands/
│   │   └── bee.md              # /bee slash command (orchestrator entry point)
│   ├── agents/                 # Subagent definitions
│   │   ├── quick-fix.md
│   │   ├── context-gatherer.md
│   │   ├── tidy.md
│   │   ├── spec-builder.md
│   │   ├── architecture-advisor.md
│   │   ├── tdd-planner-onion.md
│   │   ├── tdd-planner-mvc.md
│   │   ├── tdd-planner-simple.md
│   │   ├── verifier.md
│   │   └── reviewer.md
│   └── settings.json           # Hooks and permissions
├── docs/
│   ├── bee-v2-architecture.md  # Full design document
│   ├── specs/                  # Feature specifications
│   └── adrs/                   # Architecture Decision Records
├── CLAUDE.md                   # Bee personality + project conventions
└── README.md
```

## Design Decisions

**Why `/bee` is a command, not an agent:** Per Claude Code docs, subagents cannot spawn other subagents. Since the orchestrator needs to delegate to agents like quick-fix, context-gatherer, spec-builder, etc., it runs as a command (in the main conversation context) rather than a subagent. Commands can use the Task tool to spawn agents.

**Why standalone, not plugin (for now):** We're starting with standalone `.claude/` configuration for quick iteration during dogfooding. Once stable, Bee will be converted to a distributable plugin with `.claude-plugin/plugin.json`.
