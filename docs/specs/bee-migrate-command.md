# Spec: /bee:migrate Command

## Overview

A new command (`commands/migrate.md`) that helps developers incrementally migrate functionality from a legacy codebase to a new one. It composes existing agents (context-gatherer, review-coupling, review-behavioral) to analyze both codebases, interviews the developer about migration goals, and produces a prioritized migration plan where each unit is independently shippable and detailed enough to feed directly into `/bee:build`.

## Acceptance Criteria

### Path Parsing

- [x] Command extracts legacy and new codebase paths from the developer's natural-language prompt
- [x] Command confirms its interpretation of both paths before proceeding (e.g., "I'm reading legacy: /path/a, new: /path/b")
- [x] Shows a clear error when either path cannot be resolved to an existing directory
- [x] Handles the monorepo case where both paths are subdirectories of the same repository

### Agent Orchestration

- [x] Runs context-gatherer on both codebases (legacy and new) in parallel
- [x] Runs review-coupling on the legacy codebase to identify natural extraction seams
- [x] Runs review-behavioral on the legacy codebase to identify hotspots vs. dead/cold code
- [x] review-coupling and review-behavioral run in parallel with each other (but after context-gatherer on legacy completes, since they need its output for scope)
- [x] If any agent fails, the command reports which analysis was skipped and continues with remaining results

### Agent Inputs

- [x] context-gatherer receives the project root path and the developer's migration goal description
- [x] review-coupling receives the legacy project root and the full list of source files from context-gatherer's scan
- [x] review-behavioral receives the legacy project root, source files, and a git range (default: full history, since migration cares about lifetime activity not just recent)
- [x] Each agent is spawned via Task tool, consistent with the review.md orchestration pattern

### Developer Interview

- [x] Interview happens after all agent analysis completes (so the command can reference findings in its questions)
- [x] Asks about the developer's migration goals -- what outcome they want and what business drivers matter
- [x] Asks what has already been migrated (so it is excluded from the plan)
- [x] Asks about priorities -- what modules or capabilities should move first from a business perspective
- [x] Asks about constraints -- anything that must NOT be migrated, dependencies on external systems, timeline pressure
- [x] Interview is dynamic -- number and depth of questions adapts to what the developer shares (no fixed count)
- [x] Interview uses AskUserQuestion with concrete options where possible, informed by the analysis results (e.g., "The coupling analysis found these loosely-coupled modules: [A, B, C]. Which area matters most to your users?")

### Migration Plan Synthesis

- [x] Combines coupling analysis (seams), behavioral analysis (activity vs. dead code), context from both codebases, and developer interview answers into a single prioritized plan
- [x] Orders migration units: low-coupling + high-value modules first, tightly coupled clusters later
- [x] Dead or near-dead code (identified by behavioral analysis as having no meaningful recent git activity) is listed in a separate "Skip" section rather than as migration units
- [x] Each migration unit's priority is justified -- the plan explains WHY it is ordered where it is, referencing coupling data, activity data, or developer-stated priority

### Migration Unit Detail (Two Levels)

- [x] Each unit has a discovery-level summary: what module/capability is being moved, why it is prioritized here, and what it depends on in the legacy system
- [x] Each unit has spec-level detail: acceptance criteria describing what "done" looks like, how the migrated functionality should land in the new codebase (referencing specific patterns, folder conventions, and integration points from the new codebase's context-gatherer output), and known risks or edge cases
- [x] Each unit is scoped to be independently shippable -- a single clean PR that can be deployed to production without depending on other units being completed first
- [x] Units that have ordering dependencies (B requires A to be migrated first) state that dependency explicitly

### Output

- [x] Migration plan is saved to the new project's `docs/specs/migration-plan.md`
- [x] Plan follows a consistent markdown structure (see API Shape below)
- [x] Command confirms the plan with the developer before saving

### Command File Format

- [x] `commands/migrate.md` has frontmatter with `description` field, matching existing command conventions
- [x] Command file is read-only -- it analyzes and produces a plan, never modifies source code in either codebase

## API Shape

The migration plan output structure:

```
# Migration Plan: [Legacy Project] -> [New Project]

## Context
[Summary of both codebases -- tech stacks, patterns, key differences]
[Developer's stated goals and priorities]

## Migration Units

### Unit 1: [Name]
**Priority:** [1-N] | **Effort:** [S/M/L] | **Depends on:** [none or Unit N]

**Summary:** [What this module does, why it's first -- references coupling/behavioral data]

**Acceptance Criteria:**
- [ ] [Testable behavior that defines "done" for this unit]
- [ ] [Error/edge case]
- [ ] ...

**Landing guidance:** [How this should be structured in the new codebase -- specific folders, patterns, integration points from context-gatherer output]

**Risks:** [Known complications, external dependencies, data concerns]

### Unit 2: [Name]
...

## Skip (Candidates for Removal)
| Module | Last meaningful change | Reason to skip |
|--------|----------------------|----------------|
| [name] | [date/timeframe]     | [dead code / no consumers / superseded by X] |

## Open Questions
[Anything the developer should resolve before starting execution]
```

## Out of Scope

- Automated code translation or code generation -- this command produces a plan, not code
- Executing the migration -- each unit is a future task for `/bee:build`
- Database migration planning -- schema changes, data migration scripts, data integrity
- Runtime behavior analysis -- static analysis and git history only, no production metrics
- Multi-repo git operations -- the command reads two paths but does not manage branches, merges, or deployments
- New agent creation -- all analysis is done by composing existing agents
- Effort estimation with time units -- effort is sized as S/M/L, not hours or days

## Technical Context

- **Patterns to follow:** `commands/review.md` for agent orchestration via Task tool (parallel spawning, graceful degradation on failure, result merging). `commands/build.md` for interview flow with AskUserQuestion and state awareness.
- **Key dependencies:** Three existing agents -- `agents/context-gatherer.md`, `agents/review-coupling.md`, `agents/review-behavioral.md`. No new agents needed.
- **Deliverable:** Single file `bee/commands/migrate.md` with frontmatter matching existing command conventions.
- **Risk level:** LOW -- this is a new command composing existing, tested agents. No changes to existing code.

---

<p align="center">[x ] Reviewed</p>
