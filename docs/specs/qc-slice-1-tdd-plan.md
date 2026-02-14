# TDD Plan: bee:qc Command -- Slice 1 (Full Codebase Mode)

## Execution Instructions
Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] -> [x]).
Continue until all items are done.
If stuck after 3 attempts, mark with a warning and move to the next independent step.

## Context
- **Source**: `docs/specs/qc-spec.md`
- **Slice**: Slice 1 -- Full Codebase Mode (analyze and plan)
- **Risk**: LOW
- **Files to create**: `bee/commands/qc.md`, `bee/agents/qc-planner.md`
- **Pattern to follow**: `bee/commands/review.md` (orchestrator), `bee/agents/review-behavioral.md` (agent frontmatter)

## Codebase Analysis

### File Structure
- Orchestrator commands live in: `bee/commands/`
- Agent definitions live in: `bee/agents/`
- Frontmatter format: `name`, `description`, `tools`, `model: inherit`
- Orchestrator pattern: determine scope, spawn agents in parallel via Task tool, collect results, produce output

### Key Patterns from review.md
- Scope resolution first, then parallel agent spawn
- Graceful degradation: if an agent fails, note the gap and continue
- Deterministic commands: agents receive specific git/bash commands, they do not invent their own
- Unified output: orchestrator merges agent results into a single deliverable

### Existing Agents Reused (not modified)
- `review-behavioral` -- hotspots (churn + complexity)
- `review-tests` -- test inventory and quality
- `review-coupling` -- structural coupling analysis

---

## Behavior 1: Orchestrator scaffolding with frontmatter and role

**Given** a developer invokes `/bee:qc` with no arguments
**When** the command file is read by Claude Code
**Then** it has valid frontmatter and establishes the QC orchestrator role

- [x] **WRITE**: Create `bee/commands/qc.md` with:
  - Frontmatter: `description` field (single line, matches the pattern in `review.md`)
  - Opening paragraph: "You are Bee doing a quality coverage analysis." Establishes that no args = full codebase mode
  - Reference to the spec for the plan output format

- [x] **VERIFY**: Frontmatter matches the pattern used by `bee/commands/review.md` (description field present, no extra fields)

---

## Behavior 2: Scope resolution -- full codebase, no args

**Given** `/bee:qc` is invoked with no arguments
**When** the orchestrator determines scope
**Then** it scopes to the entire codebase with default git history range

- [x] **WRITE**: Add a "Step 1: Determine Scope" section to `bee/commands/qc.md`:
  - No args = full codebase analysis
  - Use Glob to find all source files
  - Default git history range: last 6 months (same as review.md)
  - State interpretation before proceeding

- [x] **VERIFY**: The scope resolution instructions are unambiguous -- an LLM reading them would know exactly what to do with zero args

---

## Behavior 3: Parallel agent spawn with deterministic git commands

**Given** scope is resolved to the full codebase
**When** the orchestrator spawns review agents
**Then** it spawns review-behavioral, review-tests, and review-coupling in parallel, passing deterministic git commands

- [x] **WRITE**: Add a "Step 2: Spawn Review Agents" section to `bee/commands/qc.md`:
  - Spawn exactly 3 agents (not 7 like review.md -- only behavioral, tests, coupling)
  - Use Task tool, all 3 in a single message for parallelism
  - Pass scope context to each agent (files, git_range, project_root)
  - Include the specific git commands for hotspot detection:
    - Churn frequency: `git log --since="6 months ago" --format=format: --name-only | sort | uniq -c | sort -rn`
    - Author count per file: `git log --since="6 months ago" --format=format:%an --name-only` (parsed for unique author count)
    - Complexity: assessed by the behavioral agent via file reading (already in review-behavioral.md)
  - Agents must use these exact commands, not invent their own

- [x] **VERIFY**: The git commands are deterministic and complete. No room for agents to improvise different commands. The 3 agents match the spec exactly (behavioral, tests, coupling).

---

## Behavior 4: Graceful degradation when an agent fails

**Given** one of the three review agents fails or times out
**When** the orchestrator collects results
**Then** it notes which agent failed and continues with remaining outputs

- [x] **WRITE**: Add graceful degradation instructions to `bee/commands/qc.md`:
  - If an agent fails, note which dimension is missing (e.g., "Behavioral analysis unavailable")
  - Continue with the remaining agent outputs
  - Pass the gap information to the qc-planner so it knows what data is missing
  - Never fail the entire QC run because one agent had trouble

- [x] **VERIFY**: The degradation behavior matches the pattern in `review.md` line 74: "note which dimension was skipped and continue"

---

## Behavior 5: Hand off to qc-planner agent

**Given** all available agent outputs are collected
**When** the orchestrator has the results
**Then** it spawns the qc-planner agent with all outputs and receives the plan

- [x] **WRITE**: Add a "Step 3: Generate Plan" section to `bee/commands/qc.md`:
  - Spawn `qc-planner` agent via Task tool
  - Pass all three agent outputs (or note which are missing)
  - The qc-planner produces the plan content
  - Orchestrator writes the plan to `docs/specs/qc-plan.md`

- [x] **VERIFY**: The handoff is clean -- qc-planner receives structured input and the orchestrator handles file writing

---

## Behavior 6: QC Planner agent scaffolding

**Given** the qc-planner agent is spawned
**When** it receives the agent outputs
**Then** it has valid frontmatter and a clear role definition

- [x] **WRITE**: Create `bee/agents/qc-planner.md` with:
  - Frontmatter matching the agent pattern: `name: qc-planner`, `description`, `tools: Read, Glob, Grep`, `model: inherit`
  - Role: "You are a specialist agent that synthesizes review outputs into a prioritized test plan."
  - Inputs section: describes what it receives (behavioral output, test output, coupling output, plus any gap notes)

- [x] **VERIFY**: Frontmatter matches the pattern in `bee/agents/review-behavioral.md`

---

## Behavior 7: Hotspot scoring and ranking

**Given** the qc-planner receives behavioral, test, and coupling data
**When** it processes the hotspot data
**Then** it computes hotspot score and caps at top 5-10

- [x] **WRITE**: Add hotspot scoring instructions to `bee/agents/qc-planner.md`:
  - Hotspot score formula: `churn_frequency x complexity x author_count`
  - Rank all hotspots by score
  - Cap the plan at top 5-10 hotspots only -- do not plan for the entire codebase
  - If fewer than 5 hotspots exist, include all of them

- [x] **VERIFY**: The formula is explicit and deterministic. The cap is enforced.

---

## Behavior 8: Cross-reference against existing test inventory

**Given** the qc-planner has hotspot rankings and test inventory data
**When** it builds the plan
**Then** it never recommends tests that already exist

- [x] **WRITE**: Add cross-referencing instructions to `bee/agents/qc-planner.md`:
  - Use the review-tests output to identify what tests already exist
  - For each hotspot, determine test status: "no tests", "partial tests", or "tests exist but implementation-coupled"
  - Never recommend writing a test that already exists and is behavior-based
  - For "implementation-coupled" tests: recommend rewriting, not adding duplicates

- [x] **VERIFY**: The three test status categories match the spec exactly. The "never recommend existing tests" rule is explicit.

---

## Behavior 9: Testability assessment and refactoring flags

**Given** the qc-planner is evaluating a hotspot
**When** the hotspot has code that cannot be unit tested as-is
**Then** it flags the file as needing refactoring before testing

- [x] **WRITE**: Add testability assessment instructions to `bee/agents/qc-planner.md`:
  - For each hotspot, assess: can this file be unit tested right now?
  - If not, identify what blocks testability (tight coupling, side effects in constructors, global state, etc.)
  - Flag these files with specific refactoring steps needed
  - If refactoring is extensive (4+ steps), link to a separate file at `docs/specs/qc-refactor-<filename>.md`
  - The planner does NOT write the refactor files -- it just references where they would go

- [x] **VERIFY**: The 4-step threshold for separate refactor files is explicit. The refactor file path pattern matches the spec.

---

## Behavior 10: Test pyramid priority ordering

**Given** the qc-planner is recommending tests for a hotspot
**When** it decides what type of test to recommend
**Then** it follows test pyramid priority: unit first, integration where units are insufficient, contract for service boundaries

- [x] **WRITE**: Add test type guidance to `bee/agents/qc-planner.md`:
  - Default recommendation: unit tests
  - Integration tests: only when the behavior spans multiple components and a unit test would require excessive mocking
  - Contract tests: only for service boundaries (API contracts, message schemas)
  - Each test recommendation is tagged with its type: (Unit), (Integration), (Contract)

- [x] **VERIFY**: The pyramid priority is explicit and matches the spec.

---

## Behavior 11: Fixed output format

**Given** the qc-planner has completed its analysis
**When** it produces the plan
**Then** the output follows the exact fixed format from the spec

- [x] **WRITE**: Add the output format template to `bee/agents/qc-planner.md`:
  - Analysis Summary table (files analyzed, hotspots identified, already tested, needing tests, needing refactoring first)
  - Priority Queue table (rank, file, hotspot score, complexity, effort, reward, reasoning)
  - Detailed Plan section with checkboxes for each hotspot:
    - Test status line
    - Refactoring needed (with WHY for each step)
    - Tests to create (with type tag)
    - Done-when exit criteria
  - Plan must be self-contained: an autonomous agent (Ralph) can execute it without conversation context

- [x] **VERIFY**: The format matches the spec's "Plan Format" section exactly. All table columns are present. Checkbox format is correct.

---

## Edge Cases (Low Risk)

- [x] **EDGE CASE**: What if the codebase has no git history?
  - Add a note to `bee/commands/qc.md`: if git history is insufficient, behavioral agent will report this. The qc-planner works with whatever data is available, even if only coupling and test data.

- [x] **EDGE CASE**: What if zero hotspots are found?
  - Add a note to `bee/agents/qc-planner.md`: if no hotspots are identified, produce a summary-only plan stating the codebase has no high-risk untested code. Do not produce an empty priority queue.

---

## Final Check

- [x] **Review `bee/commands/qc.md`**: Read it end to end. Does it follow the same structure and tone as `bee/commands/review.md`? Is every step unambiguous?
- [x] **Review `bee/agents/qc-planner.md`**: Read it end to end. Does the frontmatter match `bee/agents/review-behavioral.md`? Are the instructions self-contained?
- [x] **Cross-reference with spec**: Walk through every acceptance criterion in `docs/specs/qc-spec.md` Slice 1 and confirm each one is addressed in the two files.
- [x] **Verify agent reuse**: Confirm that no existing agents (review-behavioral, review-tests, review-coupling) are modified.

## Deliverables Summary
| File | Purpose | Status |
|------|---------|--------|
| `bee/commands/qc.md` | Orchestrator -- scope, spawn, collect, output | DONE |
| `bee/agents/qc-planner.md` | Planner -- score, rank, format plan | DONE |
[x] reviewed
