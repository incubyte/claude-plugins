# Discovery: /bee:migrate Command

## Why

Developers migrating from a legacy codebase to a new one face a hard question: where do I start, and in what order? Today they eyeball the old system, guess at boundaries, and hope they pick the right module to move first. Migration isn't just code translation -- it's an opportunity to improve boundaries and align with the new system's patterns. Bee already has agents that understand codebases (context-gatherer), find structural seams (review-coupling), and identify what's actively maintained versus dead code (review-behavioral). This command composes those agents into a migration-specific workflow that replaces guesswork with data-driven prioritization.

## Who

**Developers leading a migration** -- they have a legacy system and a new system, and need to move functionality from one to the other incrementally. They want each migration step to be a clean, deployable PR that doesn't break anything and can serve production traffic.

## Success Criteria

- Developer can point the command at two codebases (legacy and new) and get a prioritized migration plan without manual analysis
- Each unit in the migration plan is independently shippable -- a clean PR that's also deployable to production
- Low-hanging fruit surfaces first, informed by coupling analysis (natural seams) and behavioral analysis (what's actively maintained vs. dead)
- The migration plan accounts for the new system's patterns, so migrated code lands in the right shape -- not a copy-paste of legacy structure
- The plan is saved in the new project's `docs/specs/migration-plan.md`, consistent with other Bee output

## Problem Statement

When migrating a legacy system to a new one, developers lack a structured way to identify what to move, in what order, and where the natural extraction points are. They end up either trying to move too much at once (big bang) or picking migration units arbitrarily. The result is wasted effort on code that turns out to be dead, tangled dependencies that force rework, and migrated code that carries over legacy patterns instead of adopting the new system's conventions. This command gives developers a data-informed migration roadmap where every unit is sized for safe, incremental delivery.

## Hypotheses

- H1: Running review-coupling on the legacy codebase will reliably surface natural seams -- modules with low afferent coupling that can be extracted without touching half the system.
- H2: Running review-behavioral on the legacy codebase will identify dead or near-dead code that can be skipped entirely, reducing migration scope significantly.
- H3: Running context-gatherer on the new codebase provides enough pattern information for the migration plan to recommend how migrated code should be structured (not just what to move, but how it should land).
- H4: A short developer interview (migration goals, what's already been moved, priorities) is sufficient to turn the analysis into a prioritized plan -- the command doesn't need deep domain knowledge beyond what the developer provides.

## Out of Scope

- Automated code translation or code generation -- this command produces a plan, not code
- Executing the migration -- each unit in the plan is a future task (could be handed to `/bee:build`)
- Database migration planning -- schema changes, data migration scripts, and data integrity concerns are a separate problem
- Runtime behavior analysis -- this uses static analysis and git history only, not production metrics or traffic patterns
- Multi-repo orchestration -- the command analyzes two paths the developer provides, but doesn't manage git operations across repos

## Milestone Map

### Phase 1: The core command -- analyze both codebases and produce a migration plan

- Developer invokes `/bee:migrate` with a prompt containing paths to the legacy and new codebases, plus any context about goals and priorities
- Command runs context-gatherer on both codebases to understand each independently (structure, patterns, conventions)
- Command runs review-coupling on the legacy codebase to find natural extraction seams and identify tightly coupled clusters
- Command runs review-behavioral on the legacy codebase to surface hotspots (actively maintained code) versus cold/dead code
- Command interviews the developer about migration goals, what's already been moved, and what matters most
- Command synthesizes all analysis into a prioritized migration plan saved to the new project's `docs/specs/migration-plan.md`
- Each migration unit in the plan includes: what to move, why it's prioritized where it is, what it depends on, and how it should land in the new system's patterns
- Migration units are ordered: low-coupling/high-value modules first, tightly coupled clusters later, dead code flagged as "skip"

### Phase 2: Refinements based on real-world usage

- Support for partial re-runs (developer has moved some units, wants to re-analyze what remains)
- Integration with `/bee:build` so a developer can pick a migration unit and immediately start a build workflow for it
- Richer "how it should land" recommendations using the new codebase's architecture patterns more deeply

## Open Questions

- How should the command handle monorepos where legacy and new code live in the same repository but different directories? The two-path model works, but the developer experience might need a hint.
- Should the migration plan include effort estimates per unit? The coupling and behavioral data could inform rough sizing, but it might create false precision.
- When the legacy codebase has no meaningful git history (e.g., vendor code, acqui-hire), the behavioral analysis degrades gracefully -- but should the command explicitly warn and adjust its prioritization strategy?

## Key Decisions Resolved

| Decision | Resolution | Rationale |
|----------|-----------|-----------|
| Where the migration plan is saved | New project's `docs/specs/migration-plan.md` | That's where work happens going forward |
| What "independently shippable" means | Each unit is both a clean PR and deployable to production | Each migration step must serve traffic safely -- no "move now, fix later" |
| New agents vs. composing existing ones | Compose existing agents (context-gatherer, review-coupling, review-behavioral) plus a migration-specific synthesis step | Reuse what works; the novel part is the synthesis, not the analysis |
| Command vs. agent boundary | `commands/migrate.md` orchestrates; no new agents needed for Phase 1 | The orchestrator runs existing agents on the right targets and synthesizes results -- same pattern as `/bee:review` |

## Revised Assessment

Size: FEATURE -- this is a single command file (`commands/migrate.md`) that orchestrates existing agents in a new combination. The analysis agents already exist; the new work is the orchestration logic, the developer interview flow, and the migration plan output format. One phase of real work, with Phase 2 as future refinement.

Greenfield: no -- this extends the existing Bee plugin with a new command, following established patterns.



[x] Reviewed

