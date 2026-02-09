# Bee

**The developer is the driver. Claude Code is the car. Bee is the GPS.**

Bee is a Claude Code plugin that navigates you through the right level of process for each task. A typo? Just fix it. A new feature? Spec it, plan it, TDD it, verify it. An epic? Break it into shippable phases and tackle them one at a time.

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

```
/bee add user authentication
```

Or start without a task:

```
/bee
```

Bee greets you with "Tell me what we're working on" and guides you from there.

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

## Workflow Phases

For features and epics, Bee walks you through up to 10 phases. Each one delegates to a specialist agent.

```
Triage → Context Gathering → Tidy (optional) → Discovery (when warranted)
  → Spec → Architecture → TDD Plan → Execute → Verify → Review
```

1. **Triage** — Assess size + risk, ask clarifying questions
2. **Context Gathering** — Scan the codebase for patterns, conventions, and the change area
3. **Tidy** — Clean up the area before building (separate commit, skipped if clean)
4. **Discovery** — Map out decisions and milestones when scope is uncertain or decisions are entangled
5. **Spec Building** — Interview the developer, produce a testable specification with acceptance criteria
6. **Architecture** — Evaluate architecture options (or confirm existing patterns). YAGNI check included
7. **TDD Planning** — Generate a step-by-step test-driven plan for each slice
8. **Execution** — Build it following the TDD plan (manually or via Ralph)
9. **Verification** — Tests pass, acceptance criteria met, patterns followed
10. **Review** — Holistic code review with a risk-aware ship recommendation

### Collaboration Loop

After discovery, spec, and TDD plan documents are produced, you can review them in your editor. Add `@bee` inline comments to request changes. Mark `[x] Reviewed` at the bottom to proceed. Bee reads your annotations, makes changes, and leaves comment cards so you can see what it did.

### Session Resume

Close your terminal mid-feature? No problem. Bee persists progress in `docs/specs/.bee-state.md`. Next time you run `/bee`, it picks up exactly where you left off.

## Agents

Bee ships with 13 specialist agents:

| Agent | Role |
|-------|------|
| `quick-fix` | Handle trivial fixes end-to-end |
| `context-gatherer` | Read codebase to understand patterns and conventions |
| `tidy` | Clean up the area before building |
| `discovery` | Explore requirements, produce milestone map |
| `spec-builder` | Interview developer, write testable spec |
| `architecture-advisor` | Evaluate architecture options, YAGNI check |
| `tdd-planner-onion` | Outside-in TDD for onion/hexagonal architecture |
| `tdd-planner-mvc` | Layer-by-layer TDD for MVC codebases |
| `tdd-planner-cqrs` | Split command/query TDD for CQRS systems |
| `tdd-planner-event-driven` | Contract-first TDD for event-driven systems |
| `tdd-planner-simple` | Straightforward test-implement-verify |
| `verifier` | Post-slice quality gate |
| `reviewer` | Final review with ship recommendation |

## Skills

Shared reference knowledge that agents draw on:

- **clean-code** — SRP, DRY, YAGNI, naming, error handling
- **tdd-practices** — Red-green-refactor, outside-in, test quality
- **architecture-patterns** — When to use onion vs MVC vs simple
- **spec-writing** — Acceptance criteria, vertical slicing, adaptive depth
- **ai-workflow** — Why spec-first TDD produces better AI-generated code
- **collaboration-loop** — Inline review with `@bee` annotations

## Project Structure

```
bee/
├── .claude-plugin/
│   └── plugin.json               # Plugin manifest
├── commands/
│   └── bee.md                    # /bee orchestrator
├── agents/
│   ├── quick-fix.md
│   ├── context-gatherer.md
│   ├── tidy.md
│   ├── discovery.md
│   ├── spec-builder.md
│   ├── architecture-advisor.md
│   ├── tdd-planner-onion.md
│   ├── tdd-planner-mvc.md
│   ├── tdd-planner-cqrs.md
│   ├── tdd-planner-event-driven.md
│   ├── tdd-planner-simple.md
│   ├── verifier.md
│   └── reviewer.md
├── skills/
│   ├── clean-code/
│   ├── tdd-practices/
│   ├── architecture-patterns/
│   ├── spec-writing/
│   ├── ai-workflow/
│   └── collaboration-loop/
├── docs/
│   ├── specs/                    # Generated specs, TDD plans, state
│   └── adrs/                    # Architecture Decision Records
├── CLAUDE.md                     # Bee personality + conventions
└── README.md
```

## Design Decisions

**Why `/bee` is a command, not an agent.** Claude Code subagents cannot spawn other subagents. Since the orchestrator delegates to 13 agents, it must run as a command in the main conversation context.

**Navigator, not enforcer.** Bee suggests the right process but never blocks. Say "just code it" and Bee asks one clarifying question, then proceeds.

**Risk flows downstream.** A HIGH risk triage means deeper specs, more defensive tests, and stricter review recommendations. LOW risk means lighter everything. The developer doesn't have to think about calibration — Bee handles it.

## License

Proprietary.
