# Discovery: /bee:qc Command

## Why

Developers working in existing codebases don't know where to invest in test coverage. They either write tests for whatever they touched last, or try to boil the ocean with blanket coverage goals. Neither approach targets the code that actually hurts -- the files that change constantly and break things. The "code as a crime scene" insight is that git history reveals where the risk lives: high-churn, high-complexity files are where bugs cluster. Bee already has agents that find hotspots (review-behavioral), assess test quality (review-tests), and detect coupling (review-coupling). This command composes those agents into a quality coverage workflow that answers: "where should I write tests next, and what needs refactoring before I can?"

## Who

**Developers maintaining existing codebases** -- they want to improve test coverage strategically, not randomly. They have limited time and need to know which files give the highest return on testing investment.

**Tech leads doing PR reviews** -- they want incoming PRs to include tests for the code they change, and they want the tests to be meaningful (behavior-based, not implementation-coupled). The PR mode gives them a tool that improves PR quality automatically.

## Design Philosophy

bee:qc is a wingman, not a bulldozer. It should feel like a helpful teammate, not a tool that dumps 50 changes on you. Everything it does should reduce cognitive load, not increase it. If a developer feels overwhelmed by the output, we've failed. Small, digestible, explainable.

## Success Criteria

- Developer can run `/bee:qc` on any codebase and get a prioritized test plan that targets the highest-risk code first, not just the easiest-to-test code
- The plan never recommends creating tests that already exist -- existing coverage is inventoried before planning
- When code isn't testable, the plan includes specific refactoring steps (extract method, inject dependency) before the test steps
- For PR mode (`/bee:qc <PR-id>`), refactoring and tests are written automatically, and the developer can trace every change back to a clear rationale
- The plan file is self-contained enough that an autonomous agent (Ralph) can pick it up and execute it without conversation context
- In PR mode, every refactoring step is reviewed by a separate agent before being committed -- qc must never introduce a bug

<!-- -------- bee-comment -------- -->
> **@developer**: i would like an additional agent to review code that gets written after a PR is raised for sanity and bug check. The last thing we want is our refactoring to introduce a bug. So each refactoring should be reviewed by another agent before it gets pushed
> **@bee**: Added as a success criterion and baked into the agent flow (step 4b: verification loop). Each refactoring step gets reviewed by the verifier agent before commit. If verification fails, the refactoring is rolled back.
> - [x] mark as resolved
<!-- -------- /bee-comment -------- -->

## Problem Statement

Systems without test coverage inevitably drift toward a **test cone** (inverted pyramid) -- they compensate with end-to-end tests because there are no unit tests to catch regressions at the source. This is expensive, slow, and fragile. The right fix isn't more E2E tests; it's building the unit and integration test layers that should have existed from the start.

Test coverage efforts are usually either random ("write tests for what you touched") or blanket ("get to 80% coverage"). Both waste effort. Random testing misses the riskiest code. Blanket coverage treats stable, never-changing utility files the same as volatile business logic that breaks every sprint. Meanwhile, the code that most needs tests is often the hardest to test -- it's tightly coupled, has hidden dependencies, and resists unit testing without refactoring first. Developers need a tool that finds the risky code, assesses what's already tested, identifies what needs refactoring to become testable, and produces a plan they can follow or hand to an autonomous agent.

<!-- -------- bee-comment -------- -->
> **@developer**: other angle i would like to add to this is, most systems which are not covered with tests then start depending on end to end test cases and end up with a test cone, not test pyramid
> **@bee**: Added the test cone / inverted pyramid problem as the opening paragraph of the problem statement. This is the structural root cause that qc addresses.
> - [x] mark as resolved
<!-- -------- /bee-comment -------- -->

## Hypotheses

- H1: Composing the existing review-behavioral, review-tests, and review-coupling agents provides sufficient analysis to produce a quality test plan -- no new analysis agents are needed.
- H2: Hotspot score (churn x complexity x author count) is a better prioritization signal for test coverage than code coverage percentage alone.
- H3: Most untested hotspot code needs some refactoring before it can be meaningfully unit tested -- the refactoring plan is not an edge case, it's the common case.
- H4: For PR-scoped work, automatically performing refactoring + test creation is acceptable to developers IF every change is verified by a review agent and committed atomically with a clear rationale.

<!-- -------- bee-comment -------- -->
> **@developer**: while churn and complexity are top measures, there is a secondary measure (number of authors in a file). More authors = more bugs. Can we address it here or better leave it for now?
> **@bee**: Added author count as a factor in H2. The review-behavioral agent already has access to git log -- adding `git shortlog -s <file>` to count distinct authors is low effort and high signal. Included it in the hotspot scoring formula rather than deferring.
> - [x] mark as resolved
<!-- -------- /bee-comment -------- -->

## Out of Scope

- Generating code coverage reports or integrating with coverage tools (Istanbul, JaCoCo, etc.) -- the plan uses qualitative assessment from review-tests, not coverage percentages
- Modifying the existing review agents -- they stay read-only analysts; the new qc-planner agent consumes their output
- End-to-end or UI tests -- the test pyramid preference is unit first, integration second; E2E is out of scope
- Performance or load testing -- this is about functional correctness, not performance
- Running in CI/CD pipelines -- this is a developer-invoked command, not an automated gate

## Agent Architecture

### Composed flow (decided during discovery)

The qc command reuses existing review agents rather than building new analysis agents. The flow is:

1. **Parallel analysis phase** -- spawn review-behavioral, review-tests, and review-coupling simultaneously (same pattern as bee:review orchestrator)
2. **Synthesis phase** -- feed all three agent outputs into a new **qc-planner** agent that cross-references hotspots against existing test coverage and coupling data to produce the plan
3. **Output phase** -- qc-planner writes the plan to `docs/specs/qc-plan.md`
4. **Execution phase** (PR mode only):
   a. For each refactoring step: make the change, run tests
   b. **Verification loop**: delegate to verifier agent to review the refactoring for correctness and bug risk. If verification fails, roll back and flag to developer
   c. Only after verification passes: commit with WHY message
   d. After all refactoring: write tests in separate commits
   e. Final verification pass on the complete changeset

<!-- -------- bee-comment -------- -->
> **@developer**: my earlier comment about reviewing the generated code for PR mode will change the above flow. I want to make sure that our code change NEVER introduces a bug. What needs to change for that?
> **@bee**: Added step 4b — a verification loop where each refactoring step is reviewed by the verifier agent before being committed. Also added a final verification pass (4e) on the complete changeset. The flow is now: refactor → test → verify → commit (or rollback).
> - [x] mark as resolved
<!-- -------- /bee-comment -------- -->

### Deterministic hotspot analysis

The review-behavioral agent (or qc orchestrator) should use prescribed git commands for hotspot detection rather than reasoning about which commands to run each time. This makes the analysis reproducible:

```bash
# Churn frequency (file change count over last 6 months)
git log --since="6 months ago" --format=format: --name-only | sort | uniq -c | sort -rn

# Complexity proxy (indentation-weighted line count)
# Handled by agent reading files and scoring

# Author count (distinct contributors per file)
git shortlog -sn -- <file>

# Temporal coupling (files that change together)
git log --since="6 months ago" --format=format: --name-only | # grouped by commit
```

<!-- -------- bee-comment -------- -->
> **@developer**: in review agent, we may want to tell it exactly what commands to execute to find hotspots instead of it having to think about it every time. That way we will know our hotspot analysis logic is more deterministic than anything else.
> **@bee**: Added a "Deterministic hotspot analysis" section with the exact git commands to use. These will be baked into the orchestrator or agent instructions so the analysis is reproducible across runs.
> - [x] mark as resolved
<!-- -------- /bee-comment -------- -->

### Why compose instead of build new

- The review agents already encode the analysis techniques (git log hotspot detection, test quality assessment, coupling mapping)
- Composing means improvements to review agents automatically improve qc analysis
- The new work is concentrated in one agent (qc-planner) that does the novel part: turning analysis into an executable plan

## Refactoring Trust Model (PR Mode)

When `/bee:qc <PR-id>` performs refactoring automatically, trust comes from verification + transparency:

1. **Tests pass before AND after** -- run the test suite before any refactoring. Run it again after each refactoring step. If tests break, the refactoring is wrong. This is the non-negotiable baseline.
2. **Verification agent reviews each step** -- after each refactoring, the verifier agent reviews the diff for correctness, unintended behavior changes, and bug risk. Only verified changes get committed.
3. **One concern per commit** -- each refactoring step is its own atomic commit. "Extract method for testability" is one commit. "Inject dependency to decouple" is another. The developer can revert any single step.
4. **WHY in every commit message** -- each refactoring commit explains what was changed and why (e.g., "Extract calculateDiscount into standalone function so it can be unit tested without instantiating OrderService").
5. **Refactoring commits separate from test commits** -- refactoring and test creation are distinct commit groups. The developer sees: first N commits are refactoring (behavior preserved, each verified), then M commits are new tests. No mixed concerns.

## Plan Format for Autonomous Execution

The plan at `docs/specs/qc-plan.md` must be self-contained, consistently structured, and digestible. The format is fixed -- it should not vary from execution to execution.

**Scope:** Full codebase mode produces a plan for the **top 5-10 hotspots only**. Not the entire codebase. This keeps the plan digestible and actionable.

### Fixed plan structure

```markdown
# QC Plan: [project name or PR scope]

## Analysis Summary

| Metric | Value |
|--------|-------|
| Files analyzed | [count] |
| Hotspots identified | [count] |
| Already tested | [count] |
| Needing tests | [count] |
| Needing refactoring first | [count] |

## Priority Queue

| # | File | Hotspot Score | Complexity | Effort | Reward | Reasoning |
|---|------|---------------|------------|--------|--------|-----------|
| 1 | path/to/file.ext | HIGH | deep nesting, 5 authors | Medium | High | 47 changes in 6mo, 0 tests |
| 2 | ... | ... | ... | ... | ... | ... |

## Detailed Plan

### [ ] 1. path/to/file.ext -- Hotspot: HIGH

**Test status:** no tests / partial tests / tests exist but implementation-coupled
**Refactoring needed:**
- [ ] [Specific refactoring] -- [WHY this enables testing]
**Tests to create:**
- [ ] [Test description -- behavior to verify] (Unit)
- [ ] [Test description] (Integration)
**Done when:** [concrete exit criteria]

### [ ] 2. ...
```

When a file needs **extensive refactoring** (4+ steps), the detailed refactoring spec goes in a linked file (`docs/specs/qc-refactor-<filename>.md`) rather than cluttering the main plan. The main plan links to it. The linked file is Ralph-executable — step-by-step instructions the developer can run with `/ralph-loop`.

<!-- -------- bee-comment -------- -->
> **@developer**: i am thinking every time the plan should only include top 5 to 10 code areas. That way the plan remains digestible for humans. I would also make sure that the plan has formatted tables and communicates risk vs rewards ratio in a simpler way. Also, we want to clearly define how our plan looks like, the plan should not vary execution to execution in terms of structure and format.
> **@bee**: Capped at top 5-10 hotspots, added a summary table with effort/reward/reasoning columns, and made the format fixed (not variable). Structure is now prescriptive.
> - [x] mark as resolved
<!-- -------- /bee-comment -------- -->

<!-- -------- bee-comment -------- -->
> **@developer**: i would create a todo and link it with a separate file, that file will have step by step spec on what and how should the file be refactored. If the developer wants they should be able to execute the plan in one go using Ralph
> **@bee**: Added: extensive refactoring (4+ steps) gets its own linked file (`docs/specs/qc-refactor-<filename>.md`) that's Ralph-executable. The main plan links to it, keeping the plan clean.
> - [x] mark as resolved
<!-- -------- /bee-comment -------- -->

<!-- -------- bee-comment -------- -->
> **@developer**: i would use your judgement for the following question — Should the plan distinguish between "no tests" vs "tests exist but implementation-coupled"?
> **@bee**: Yes — included as the "Test status" field in each plan item. The distinction matters: "no tests" means write from scratch, "implementation-coupled tests" means the tests exist but test the wrong thing (mocking internals, asserting on implementation details). The plan should call this out because the fix is different, and a developer should know whether they're building or rebuilding.
> - [x] mark as resolved
<!-- -------- /bee-comment -------- -->

## Milestone Map

### Phase 1: Full codebase mode -- analyze and produce the plan

- Developer invokes `/bee:qc` (no arguments)
- Command orchestrator spawns review-behavioral, review-tests, and review-coupling in parallel against the full codebase
- New qc-planner agent receives all three outputs and cross-references: hotspot files without adequate tests are prioritized highest
- qc-planner assesses testability of each hotspot -- flags files that need refactoring first (using coupling and code quality signals)
- qc-planner produces the plan at `docs/specs/qc-plan.md` following the fixed format above, capped at top 5-10 hotspots
- Plan follows test pyramid: unit tests preferred, integration tests where units aren't sufficient, contract tests for service boundaries
- Developer can hand the plan to Ralph for autonomous execution or follow it manually

### Phase 2: PR mode -- analyze PR changes, refactor, verify, and write tests

- Developer invokes `/bee:qc <PR-id>`
- Command scopes analysis to files changed in the PR (via `gh pr diff <number>`)
- Same parallel analysis, but scoped to PR files and their immediate dependencies
- qc-planner produces a PR-scoped plan
- Command auto-executes the plan:
  - Refactoring first: each step → test suite → verifier agent review → commit (or rollback)
  - Then test creation: separate commits
  - Final verification pass on complete changeset
- PR is updated with the new commits
- Developer sees: verified refactoring commits, then test commits, each with clear WHY

<!-- -------- bee-comment -------- -->
> **@developer**: our goal is to do the work in a way that developer thinks of qc-bee as a friend, more like a wingman. If we made a lot of changes I fear they will just not use the command. Idea is to do a bunch of things that does not increase the cognitive load of devs
> **@bee**: Added "Design Philosophy" section at the top — wingman, not bulldozer. This principle now shapes: plan capped at 5-10 items, tables for quick scanning, extensive refactoring linked out to separate files, and PR mode producing small verified commits. Everything is about keeping the developer's cognitive load low.
> - [x] mark as resolved
<!-- -------- /bee-comment -------- -->

## Open Questions

- For PR mode, should the command also analyze files that the PR touches but doesn't modify (imported dependencies)? These might be undertested and relevant to the PR's correctness. Recommendation: start with changed files only, expand to direct imports in a future iteration.

## Revised Assessment

Size: FEATURE -- two phases, but each is well-scoped. Phase 1 is one orchestrator + one new agent (qc-planner). Phase 2 adds execution + verification loop to the orchestrator. The review agents are reused as-is.
Greenfield: no -- this builds on existing agent patterns and the review command's orchestration model.

[x] Reviewed
