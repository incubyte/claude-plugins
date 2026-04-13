# TDD Plan: /bee:migrate Command

## Execution Instructions
Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] -> [x]).
Continue until all items are done.
If stuck after 3 attempts, mark with a warning and move to the next independent step.

## Context
- **Source**: `docs/specs/bee-migrate-command.md`
- **Deliverable**: Single file `bee/commands/migrate.md`
- **Risk**: LOW
- **Architecture**: Simple -- markdown command file with YAML frontmatter + prompt body
- **Pattern reference**: `bee/commands/review.md` (parallel agent spawning, graceful degradation), `bee/commands/build.md` (interview flow with AskUserQuestion)
- **Agents used**: `agents/context-gatherer.md`, `agents/review-coupling.md`, `agents/review-behavioral.md`

## Codebase Conventions

### Command File Structure
- YAML frontmatter with `description` field
- Prompt body in markdown sections
- Agents spawned via Task tool
- AskUserQuestion for developer interaction
- Existing commands: `review.md` (182 lines), `build.md` (525 lines), `discover.md`, `bee-coach.md`

### Verification Method
No test framework exists. Each step is verified by reading the file and confirming it matches the acceptance criteria. "Test" = manual inspection that the section exists, is coherent, and follows conventions.

---

## Step 1: Frontmatter and Role Declaration

**AC**: Command file has frontmatter with `description` field matching existing conventions. Command declares itself as read-only and states its purpose.

- [x] **CREATE** the file `bee/commands/migrate.md`
  - YAML frontmatter with `description` field (one-liner, similar style to review.md and discover.md)
  - Opening paragraph: role declaration -- "You are Bee doing a migration analysis..."
  - State read-only rule: this command produces a plan, never modifies source code

- [x] **VERIFY**: Frontmatter `description` field exists and is a single sentence. Opening paragraph establishes role and read-only constraint. Compare style against `review.md` line 1-6.

---

## Step 2: Path Parsing Section

**AC**: Command extracts legacy and new codebase paths from the developer's prompt, confirms interpretation, handles errors and monorepo case.

- [x] **ADD** a "Step 1: Parse Paths" section to the command
  - Instruct the LLM to extract two paths from `$ARGUMENTS` (natural language)
  - Confirm interpretation with the developer before proceeding: "I'm reading legacy: /path/a, new: /path/b"
  - Error handling: if either path cannot be resolved, report clearly and stop
  - Monorepo note: both paths may be subdirectories of the same repo -- handle gracefully

- [x] **VERIFY**: Section covers all four path-parsing ACs. Confirmation step uses a clear quoted format. Error case is explicit (stop, do not proceed). Monorepo case is mentioned.

---

## Step 3: Agent Orchestration -- Context Gathering (Parallel)

**AC**: Runs context-gatherer on both codebases in parallel. Each agent receives project root path and migration goal description. Spawned via Task tool.

- [x] **ADD** a "Step 2: Gather Context" section
  - Spawn two context-gatherer agents in parallel via Task tool (one per codebase)
  - Each receives: project root path + developer's migration goal description
  - Pattern: match `review.md` Step 2 style (spawn in a single message for parallelism)
  - Store results as "legacy context" and "new context" for downstream use

- [x] **VERIFY**: Two parallel Task spawns described. Inputs match the Agent Inputs AC. Style matches review.md parallel spawning pattern.

---

## Step 4: Agent Orchestration -- Coupling and Behavioral Analysis (Parallel, After Legacy Context)

**AC**: review-coupling and review-behavioral run in parallel with each other, but after context-gatherer on legacy completes. Each receives correct inputs. Graceful degradation on failure.

- [x] **ADD** a "Step 3: Analyze Legacy Codebase" section
  - Wait for legacy context-gatherer to complete (need its file list)
  - Spawn review-coupling and review-behavioral in parallel via Task tool
  - review-coupling receives: legacy project root + source file list from context-gatherer
  - review-behavioral receives: legacy project root + source files + git range (default: full history)
  - Graceful degradation: if any agent fails, report which analysis was skipped and continue

- [x] **VERIFY**: Dependency ordering is correct (after context-gatherer, not before). Both agents spawn in parallel. Inputs match the Agent Inputs ACs. Git range default is "full history." Failure handling matches review.md graceful degradation pattern.

---

## Step 5: Developer Interview Flow

**AC**: Interview happens after all analysis completes. Dynamic questions informed by analysis results. Uses AskUserQuestion with concrete options.

- [x] **ADD** a "Step 4: Interview Developer" section covering these question areas:
  - Migration goals -- what outcome, what business drivers
  - Already migrated -- what to exclude from the plan
  - Priorities -- which modules or capabilities should move first
  - Constraints -- what must NOT be migrated, external dependencies, timeline pressure
  - Dynamic behavior: number and depth of questions adapts to what the developer shares
  - AskUserQuestion with concrete options drawn from analysis results (e.g., "The coupling analysis found these loosely-coupled modules: [A, B, C]. Which area matters most?")

- [x] **VERIFY**: All four question areas are covered. Questions reference analysis results (not generic). AskUserQuestion is used with options. Dynamic interview is described (no fixed question count). Style matches build.md interview pattern.

---

## Step 6: Migration Plan Synthesis Logic

**AC**: Combines all inputs into a prioritized plan. Orders by low-coupling + high-value first. Dead code goes to Skip section. Each unit's priority is justified.

- [x] **ADD** a "Step 5: Synthesize Migration Plan" section
  - Combine: coupling analysis (seams), behavioral analysis (activity vs dead code), context from both codebases, interview answers
  - Ordering rule: low-coupling + high-value modules first, tightly-coupled clusters later
  - Dead code handling: modules with no meaningful recent git activity go to "Skip" section, not migration units
  - Justification requirement: each unit explains WHY it is ordered where it is, referencing coupling data, activity data, or developer-stated priority

- [x] **VERIFY**: Synthesis combines all four data sources. Ordering logic is explicit. Dead code rule is clear. Justification requirement is stated.

---

## Step 7: Migration Unit Detail Template

**AC**: Each unit has discovery-level summary and spec-level detail. Each unit is independently shippable. Ordering dependencies are stated explicitly.

- [x] **ADD** unit detail requirements within Step 5
  - Discovery-level summary: what module is being moved, why it is prioritized here, what it depends on in the legacy system
  - Spec-level detail: acceptance criteria for "done", how the migrated functionality lands in the new codebase (referencing patterns/folders/integration points from new codebase context-gatherer), known risks
  - Independently shippable: each unit is a single clean PR that can deploy without depending on other units
  - Ordering dependencies: if B requires A first, state it explicitly

- [x] **VERIFY**: Both detail levels are described. New codebase patterns are referenced (not just legacy). Independence constraint is clear. Dependency notation is specified.

---

## Step 8: Output Format and Confirmation

**AC**: Plan saved to `docs/specs/migration-plan.md` in the new project. Follows the markdown structure from the spec's API Shape. Command confirms with developer before saving.

- [x] **ADD** a "Step 6: Output" section
  - Include the output template matching the API Shape from the spec (Context, Migration Units with Priority/Effort/Depends-on/Summary/AC/Landing-guidance/Risks, Skip table, Open Questions)
  - Confirm the plan with the developer via AskUserQuestion before writing to disk
  - Save location: new project's `docs/specs/migration-plan.md`

- [x] **VERIFY**: Output template matches the API Shape section from the spec. Confirmation step exists before save. Save path is correct.

---

## Step 9: Graceful Degradation and Edge Cases

**AC**: Agent failures are reported and skipped. Command is read-only.

- [x] **ADD** a "Rules" section at the end of the command file
  - Read-only: never modify source code in either codebase
  - Graceful degradation: if any agent fails, report which analysis was skipped and continue with remaining results
  - Parallel first: spawn agents simultaneously where possible
  - Confirm before saving: always get developer approval before writing the plan file

- [x] **VERIFY**: Rules section covers read-only, graceful degradation, parallel-first, and confirm-before-save. Matches review.md Rules section style.

---

## Step 10: Full File Review

- [x] **READ** the complete `bee/commands/migrate.md` and verify end-to-end flow:
  - Frontmatter has `description` field
  - Path parsing extracts two paths and confirms
  - Context-gatherer runs on both codebases in parallel
  - review-coupling and review-behavioral run in parallel after legacy context completes
  - All agent inputs match the spec's Agent Inputs section
  - Interview happens after analysis, is dynamic, uses AskUserQuestion with analysis-informed options
  - Synthesis combines all four data sources with correct ordering logic
  - Each migration unit has both detail levels and is independently shippable
  - Output follows the API Shape template
  - Plan is confirmed before saving
  - Rules enforce read-only, graceful degradation, and parallel execution

- [x] **VERIFY**: All acceptance criteria from the spec are covered. (Spec has 33 ACs across 8 groups; all verified present in migrate.md.) No spec AC is missing. No section contradicts another.

---

## Summary
| Category | # Steps | Status |
|----------|---------|--------|
| Frontmatter + role | 1 | |
| Path parsing | 1 | |
| Context gathering | 1 | |
| Legacy analysis | 1 | |
| Developer interview | 1 | |
| Plan synthesis | 1 | |
| Unit detail | 1 | |
| Output format | 1 | |
| Edge cases / rules | 1 | |
| Full file review | 1 | |
| **Total** | **10** | |

<p align="center">[x] Reviewed</p>
