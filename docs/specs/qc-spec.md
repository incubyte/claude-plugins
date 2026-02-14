# Spec: /bee:qc — Quality Coverage Command

## Overview

A command that composes existing review agents to find high-risk untested code, produces a prioritized test plan targeting the riskiest hotspots first, and in PR mode auto-executes refactoring and test creation with verification at every step. Wingman, not bulldozer — small, digestible, explainable.

## Slice 1: Full Codebase Mode (analyze and plan)

Developer invokes `/bee:qc` with no arguments. Produces a plan at `docs/specs/qc-plan.md`.

### Orchestrator (bee/commands/qc.md)

- [x] `/bee:qc` (no args) triggers full codebase analysis
- [x] Spawns review-behavioral, review-tests, and review-coupling agents in parallel (same Task tool pattern as bee:review)
- [x] Passes deterministic git commands for hotspot detection (churn frequency, author count, complexity) — agents do not invent their own git commands
- [x] Collects all three agent outputs and passes them to the qc-planner agent
- [x] If an agent fails, notes the gap and continues with remaining outputs
- [x] Final output is the plan file at `docs/specs/qc-plan.md`

### QC Planner Agent (bee/agents/qc-planner.md)

- [x] Receives outputs from all three review agents
- [x] Cross-references hotspots against existing test inventory — never recommends tests that already exist
- [x] Computes hotspot score: churn frequency x complexity x author count
- [x] Caps plan at top 5-10 hotspots only
- [x] Assesses testability of each hotspot — flags files needing refactoring before they can be unit tested
- [x] Distinguishes test status: "no tests" vs "partial tests" vs "tests exist but implementation-coupled"
- [x] Follows test pyramid priority: unit tests first, integration tests where units are insufficient, contract tests for service boundaries
- [x] Produces plan in fixed format (summary table, priority queue table, detailed plan with checkboxes)
- [x] Extensive refactoring (4+ steps) links to a separate Ralph-executable file at `docs/specs/qc-refactor-<filename>.md`
- [x] Plan is self-contained — an autonomous agent (Ralph) can execute it without conversation context

### Plan Format

Fixed structure, does not vary between executions:

```markdown
# QC Plan: [project name]

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

## Detailed Plan
### [ ] 1. path/to/file.ext — Hotspot: HIGH
**Test status:** no tests / partial / implementation-coupled
**Refactoring needed:**
- [ ] [Specific refactoring] — [WHY]
**Tests to create:**
- [ ] [Behavior to verify] (Unit)
- [ ] [Behavior to verify] (Integration)
**Done when:** [exit criteria]
```

## Slice 2: PR Mode (analyze, refactor, verify, test)

Developer invokes `/bee:qc <PR-id>`. Scopes analysis to PR files, auto-executes the plan.

### PR Scoping

- [x] `/bee:qc <PR-id>` scopes analysis to files changed in the PR (via `gh pr diff <number>`)
- [x] Same parallel agent analysis as full mode, but scoped to PR files
- [x] qc-planner produces a PR-scoped plan

### Execution Loop

- [x] Runs full test suite before any changes (baseline)
- [x] For each refactoring step: makes the change, then runs the test suite
- [x] After each refactoring step: spawns verifier agent to review the diff for correctness and bug risk
- [x] If verification fails: rolls back the refactoring and flags to developer
- [x] If verification passes: commits with WHY message explaining what changed and why
- [x] One concern per commit — each refactoring step is its own atomic commit
- [x] After all refactoring commits: writes tests in separate commits
- [x] Refactoring commits are never mixed with test commits
- [x] Final verification pass on the complete changeset

### Error Cases

- [x] If the PR has no changed files, reports this and stops
- [x] If `gh` CLI is not available, reports this and stops
- [x] If baseline tests fail before any changes, warns developer and asks whether to continue

## Slice 3: Integration (CLAUDE.md, README, help)

### Updates

- [x] `bee/CLAUDE.md` lists `/bee:qc` as a command with one-line description
- [x] `bee/commands/help.md` includes `/bee:qc` in the tour with usage examples for both modes
- [x] `bee/README.md` lists `/bee:qc` in the command table (if a command table exists)
- ~~State tracking via `.qc-state.md`~~ — **Descoped.** Full codebase mode is read-only and idempotent (re-run to regenerate). PR mode commits incrementally so there's nothing to resume. Session state adds complexity without value here.

## Out of Scope

- Modifying existing review agents — they are reused as-is
- Code coverage tool integration (Istanbul, JaCoCo, etc.)
- E2E or UI test recommendations
- Performance or load testing
- CI/CD pipeline integration
- Analyzing files the PR imports but does not modify (future iteration)

## Technical Context

- **Patterns to follow:** `bee/commands/review.md` for orchestrator pattern (parallel agent spawn via Task tool, scope resolution, graceful degradation). `bee/agents/verifier.md` for verification loop pattern.
- **Key files to create:** `bee/commands/qc.md`, `bee/agents/qc-planner.md`
- **Key files to update:** `bee/CLAUDE.md`, `bee/commands/help.md`, `bee/README.md`
- **Existing agents reused:** review-behavioral, review-tests, review-coupling, verifier
- **Risk level:** LOW — internal tooling, markdown instruction files, no production code
[x] Reviewed
