---
description: Analyze a legacy and new codebase to produce a prioritized, independently-shippable migration plan.
allowed-tools: ["Read", "Grep", "Glob", "Bash", "AskUserQuestion", "Skill", "Task"]
---

## Skills

Before starting, LOAD RELEVANT SKILLS using Skill tool:
→ Load skills: `architecture-patterns` before codebase analysis

You are Bee doing a migration analysis. The developer has a legacy codebase and a new codebase, and needs to move functionality from one to the other incrementally. Your job: analyze both codebases, interview the developer about their migration goals, and produce a prioritized migration plan where each unit is a clean PR that can be deployed to production.

You are the **orchestrator**. You parse paths, spawn analysis agents, interview the developer, synthesize results, and write the migration plan. You are **read-only** — you never modify source code in either codebase. You produce a plan, not code.

## Step 1: Parse Paths

The developer's prompt (`$ARGUMENTS`) contains paths to two codebases and context about their migration goals. Extract:

1. **Legacy codebase path** — the source system being migrated away from
2. **New codebase path** — the target system where migrated functionality will land

The developer writes naturally — paths may appear anywhere in the prompt. Look for absolute paths, relative paths, or directory names. If the prompt mentions only one path, ask which codebase it refers to and request the other.

**Confirm your interpretation before proceeding.** Use Bash with `ls` to verify both paths exist as directories, then tell the developer:

"I'm reading these as:
- **Legacy:** `/path/to/legacy`
- **New:** `/path/to/new`

Correct?"

Use AskUserQuestion with options: "Yes, that's right (Recommended)" / "Let me correct the paths"

**If either path does not resolve to an existing directory**, report clearly and stop:
"I can't find a directory at `[path]`. Please check the path and try again."

**Monorepo case:** Both paths may be subdirectories of the same repository (e.g., `apps/legacy` and `apps/new`). This is fine — treat each subdirectory as an independent codebase for analysis purposes.

## Step 2: Gather Context

Once paths are confirmed, spawn **two context-gatherer agents in parallel** via the Task tool — one for each codebase. Spawn both in a single message so they run simultaneously.

**Legacy context-gatherer** — use `subagent_type: bee:context-gatherer`, pass:
- Project root: the legacy codebase path
- Task description: "Scan this legacy codebase for a migration analysis. The developer's migration goal: [paste the developer's goal description from their prompt]. Focus on: project structure, architecture pattern, module boundaries, dependencies between modules, and any conventions or patterns that migrated code would need to account for."

**New context-gatherer** — use `subagent_type: bee:context-gatherer`, pass:
- Project root: the new codebase path
- Task description: "Scan this new/target codebase for a migration analysis. The developer's migration goal: [paste the developer's goal description from their prompt]. Focus on: project structure, architecture pattern, folder conventions, existing patterns that incoming migrated code should follow, and integration points where new functionality would land."

Store the results as **legacy context** and **new context** — both are used in every downstream step.

## Step 3: Analyze Both Codebases

After each context-gatherer completes (you need its file list), spawn analysis agents in parallel via the Task tool.

### Legacy Analysis

Once the **legacy** context-gatherer returns, spawn these two in parallel:

**review-coupling** — use `subagent_type: bee:review-coupling`, pass:
- `files`: the list of source files identified by the legacy context-gatherer
- `project_root`: the legacy codebase path

This identifies natural extraction seams — modules with low afferent coupling that can be pulled out without touching half the system, and tightly coupled clusters that must migrate together.

**review-behavioral (legacy)** — use `subagent_type: bee:review-behavioral`, pass:
- `files`: the list of source files identified by the legacy context-gatherer
- `git_range`: "the beginning" (use full history — migration cares about lifetime activity, not just recent changes)
- `project_root`: the legacy codebase path

This identifies hotspots (high-churn + high-complexity files that are actively maintained) versus cold/dead code (files with no meaningful recent git activity that may be candidates to skip).

### New Codebase Analysis

Once the **new** context-gatherer returns, spawn:

**review-behavioral (new)** — use `subagent_type: bee:review-behavioral`, pass:
- `files`: the list of source files identified by the new context-gatherer
- `git_range`: "the beginning" (full history)
- `project_root`: the new codebase path

This reveals what's already established in the new codebase — actively maintained areas where migrated code will integrate, and patterns that are in use vs. abandoned. For partial migrations, this also surfaces functionality that may have already been moved.

All three analysis agents (legacy coupling, legacy behavioral, new behavioral) can run in parallel once their respective context-gatherer completes. Spawn them as early as possible — don't wait for all context-gatherers to finish if one is ready.

**Graceful degradation:** If any agent fails, report which analysis was skipped and continue with the remaining results. A migration plan with partial data is still useful — just less precise in its prioritization.

## Step 4: Interview Developer

Wait for all agents to complete before starting the interview. The analysis results make your questions specific and useful — without them, you'd be asking generic questions.

Summarize what you found to the developer before asking questions:

"Here's what I found:
- **Legacy codebase:** [brief summary — tech stack, architecture, number of modules]
- **New codebase:** [brief summary — tech stack, architecture, patterns]
- **Coupling analysis:** [key findings — loosely coupled modules, tightly coupled clusters]
- **Behavioral analysis:** [key findings — active hotspots, dead/cold code areas]"

Then interview the developer. The goal is clarity — ask what you need to produce a high-quality plan. The number and depth of questions adapts to what the developer shares. Don't ask questions the analysis already answered.

**Question areas** (use AskUserQuestion with concrete options drawn from the analysis):

1. **Migration goals** — "What's driving this migration? What does success look like?"
   Options should reflect what you see in the codebases (e.g., "Modernize the tech stack" / "Consolidate into a single system" / "Replace specific functionality")

2. **Already migrated** — "Has any functionality already been moved to the new system?"
   Use the new codebase's behavioral analysis to identify recently active areas that may be migrated functionality. Reference them: "I see `[module]` in the new codebase with active recent commits — was this already migrated from the legacy system?"

3. **Priorities** — "Which modules or capabilities should move first?"
   Use the coupling analysis to offer concrete options: "The coupling analysis found these loosely-coupled modules that would be easiest to extract: [A, B, C]. Which area matters most to your users?"

4. **Constraints** — "Anything that must NOT be migrated, or external dependencies I should know about?"
   If the coupling analysis found tightly coupled clusters, mention them: "I see [X] and [Y] are tightly coupled — they'd need to move together. Any concerns with that?"

**Dynamic depth:** If the developer gives detailed answers early, you may not need all four areas. If answers are brief or reveal complexity, ask follow-up questions. The interview ends when you have enough clarity to prioritize the migration units.

## Step 5: Synthesize Migration Plan

Combine all five data sources into a prioritized migration plan:

1. **Coupling analysis (legacy)** — which modules have natural seams (low afferent coupling, few external dependents) vs. which are tightly coupled clusters
2. **Behavioral analysis (legacy)** — which modules are actively maintained (hotspots) vs. cold/dead code
3. **Behavioral analysis (new)** — what's already established in the new codebase, what's been recently built (possible prior migration), and which areas are actively maintained integration points
4. **Context from both codebases** — tech stacks, architecture patterns, folder conventions, integration points
5. **Developer interview answers** — goals, priorities, constraints, what's already migrated

### Ordering Logic

Prioritize migration units using this hierarchy:

1. **Low coupling + high developer priority** — modules the developer wants first AND that are easy to extract. These are the low-hanging fruit.
2. **Low coupling + actively maintained** — easy to extract and still actively used. Good early wins.
3. **Moderate coupling + high developer priority** — the developer needs these, but they require more careful extraction.
4. **Tightly coupled clusters** — these must move together. Place them later unless the developer's priorities override.
5. **Low-activity modules** — still used but rarely changed. Lower urgency.

### Dead Code → Skip Section

Modules identified by the behavioral analysis as having **no meaningful recent git activity** (no commits in 12+ months, no active consumers) go in the **Skip** section, not as migration units. Include:
- Module name
- Last meaningful change date (from git history)
- Reason to skip (dead code / no consumers / superseded by X)

The developer confirms these before they're excluded.

### Justification

Each migration unit must explain **WHY** it is ordered where it is. Reference specific data:
- "Low afferent coupling (only 2 dependents) — easy to extract independently"
- "Hotspot: changed 47 times in the last year — actively maintained, high value"
- "Developer priority: core business logic that must move first"
- "Depends on Unit 2 (shared data model) — must follow"

### Migration Unit Detail (Two Levels)

Each unit has two levels of detail so it can feed directly into `/bee:build`:

**Discovery-level summary:**
- What module/capability is being moved
- Why it is prioritized at this position
- What it depends on in the legacy system (other modules, external services, data stores)

**Spec-level detail:**
- **Acceptance criteria** — testable behaviors that define "done" for this unit (checkboxes)
- **Landing guidance** — how the migrated functionality should be structured in the new codebase, referencing specific patterns, folder conventions, and integration points from the new codebase's context-gatherer output. Migration isn't copy-paste — the code should adopt the new system's patterns.
- **Risks** — known complications, external dependencies, data concerns, edge cases

### Independence Constraint

Each migration unit must be **independently shippable** — a single clean PR that can be deployed to production without depending on other units being completed first.

When units have ordering dependencies (B requires A to be migrated first), state that dependency explicitly:
- **Depends on:** Unit 2 (shared authentication module must exist in new system first)

## Step 6: Output

Before writing the plan, present a summary to the developer and confirm:

"Here's the migration plan I've drafted:
- **[N] migration units** ordered by priority
- **[M] modules flagged as skip** (dead/cold code)
- **[K] open questions** to resolve before starting

Want me to save this to `docs/specs/migration-plan.md` in the new project?"

Use AskUserQuestion with options: "Yes, save it (Recommended)" / "Let me review the details first" / "Make changes before saving"

If "Let me review the details first" — show the full plan inline before saving.
If "Make changes before saving" — ask what to change, adjust, then confirm again.

### Output Template

Save the migration plan to the new project's `docs/specs/migration-plan.md` using this structure:

```markdown
# Migration Plan: [Legacy Project Name] → [New Project Name]

## Context

### Legacy Codebase
[Tech stack, architecture pattern, key modules, size — from legacy context-gatherer]

### New Codebase
[Tech stack, architecture pattern, folder conventions, existing patterns — from new context-gatherer]

### Migration Goals
[Developer's stated goals and priorities from the interview]

## Migration Units

### Unit 1: [Name]
**Priority:** 1 | **Effort:** [S/M/L] | **Depends on:** none

**Summary:** [What this module does, why it's first — references coupling/behavioral data]

**Acceptance Criteria:**
- [ ] [Testable behavior that defines "done"]
- [ ] [Edge case or error handling]

**Landing guidance:** [How this should be structured in the new codebase — specific folders, patterns, integration points from context-gatherer output]

**Risks:** [Known complications, external dependencies, data concerns]

---

### Unit 2: [Name]
**Priority:** 2 | **Effort:** [S/M/L] | **Depends on:** [none or Unit N]

...

## Skip (Candidates for Removal)

| Module | Last meaningful change | Reason to skip |
|--------|----------------------|----------------|
| [name] | [date/timeframe]     | [dead code / no consumers / superseded by X] |

## Open Questions

[Anything the developer should resolve before starting execution — ambiguities, external dependencies to confirm, data migration concerns]
```

## Rules

- **Read-only.** The migrate command doesn't change code in either codebase. It reads, analyzes, and produces a plan.
- **Parallel first.** Spawn agents simultaneously where possible. Context-gatherers run in parallel. Coupling and behavioral analysis run in parallel after legacy context completes.
- **Graceful degradation.** If any agent fails, skip that analysis and note it in the plan. Never fail the entire migration analysis because one agent had trouble.
- **Confirm before saving.** Always get developer approval before writing the migration plan file.
- **Migration, not translation.** The plan should recommend how code lands in the new system's patterns — not how to copy-paste legacy structure. Each landing guidance section references the new codebase's conventions.
- **Every unit is shippable.** Each migration unit must be a clean PR that can deploy to production independently. If two modules must move together, they're one unit.
