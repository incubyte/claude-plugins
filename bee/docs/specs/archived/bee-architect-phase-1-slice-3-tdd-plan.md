# TDD Plan: Bee Architect Phase 1 -- Slice 3: Architect Command Orchestrator

## Execution Instructions
Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] -> [x]).
Continue until all items are done.
If stuck after 3 attempts, mark with a warning and move to the next independent step.

## Context
- **Source**: `docs/specs/bee-architect-phase-1.md`
- **Slice**: Command Orchestration (`commands/architect.md`)
- **Risk**: LOW
- **File to create**: `commands/architect.md`
- **Depends on**: Slice 1 (`agents/domain-language-extractor.md`) and Slice 2 (`agents/architecture-test-writer.md`)
- **Pattern references**: `commands/review.md` (parallel agent spawning), `commands/build.md` (collaboration loop, multi-step flow)
- **Acceptance Criteria**:
  1. Spawns context-gatherer, review-coupling, review-behavioral, and domain-language-extractor agents in parallel
  2. If any agent fails/times out, notes which dimension was skipped and continues
  3. Merges findings from all four agents into a single architecture assessment report
  4. Asks developer 2-3 targeted validation questions based on merged findings
  5. Validation questions use AskUserQuestion with concrete options
  6. Saves assessment report to `docs/architecture-assessment.md`
  7. Runs collaboration loop (developer reviews, `@bee` annotations, `[x] Reviewed`)
  8. Once reviewed, delegates to architecture-test-writer agent
  9. Reports summary of what was generated (test count, locations, pass vs fail)

## Codebase Analysis

### File Structure
- Implementation: `commands/architect.md` (new file)
- Pattern reference: `commands/review.md` (parallel spawn of 7 agents, graceful degradation, merge results)
- Pattern reference: `commands/build.md` (collaboration loop, AskUserQuestion flow, multi-step orchestration)
- Agents to spawn: `agents/context-gatherer.md`, `agents/review-coupling.md`, `agents/review-behavioral.md`, `agents/domain-language-extractor.md`
- Agent to delegate to post-review: `agents/architecture-test-writer.md`

### Command Pattern
All commands follow:
1. YAML frontmatter: `description` field
2. Persona statement ("You are Bee doing X")
3. Skills section (if applicable)
4. Step-by-step numbered flow
5. Parallel agent spawning via Task tool with `subagent_type`
6. Output format / report template
7. Rules section (constraints)

### Verification Method
Markdown command definition -- no compiled code. Each step is verified by reading the file and confirming the section exists, follows the pattern, and covers the relevant AC.

---

<!-- @bee: Replaced Given/When/Then with simple one-line descriptions per developer preference -->

## Behavior 1: YAML frontmatter and persona

Create the command file with YAML frontmatter (`description` field) and an orchestrator persona statement.

- [x] **DEFINE**: Frontmatter needs:
  - `description`: one sentence about assessing architectural health by comparing code structure against domain language
  - Persona line: "You are Bee running an architecture assessment..." establishing the orchestrator role
  - Mention that this command spawns agents and produces an assessment report

- [x] **APPLY**: Create `commands/architect.md` with frontmatter and persona only.

- [x] **VERIFY**: Read the file. Confirm frontmatter has `description`. Confirm persona line establishes the orchestrator role (not the analyst role -- that belongs to the agents).

---

## Behavior 2: Skills section

Add skills section referencing architecture-patterns and collaboration-loop.

- [x] **DEFINE**: Skills section should reference:
  - `skills/architecture-patterns/SKILL.md` -- for understanding the domain boundary concepts agents return
  - `skills/collaboration-loop/SKILL.md` -- for the review gate format

- [x] **APPLY**: Add the Skills section after the persona.

- [x] **VERIFY**: Read the file. Confirm both skill paths are listed.

---

## Behavior 3: Step 1 -- parallel agent spawning

Spawn all 4 agents in parallel via Task tool (context-gatherer, review-coupling, review-behavioral, domain-language-extractor).

- [x] **DEFINE**: Step 1 should:
  - Spawn all 4 agents in a single message (parallel execution, matching `review.md` pattern)
  - Pass each agent the project root and task context
  - List the `subagent_type` for each: `bee:context-gatherer`, `bee:review-coupling`, `bee:review-behavioral`, `bee:domain-language-extractor`
  - Include the scope context block (project_root, what to analyze)

- [x] **APPLY**: Add Step 1 to the command file.

- [x] **VERIFY**: Read step 1. Confirm all 4 agents are listed. Confirm it says "single message" or "simultaneously" (not sequential). Confirm each has a `subagent_type` identifier.

---

## Behavior 4: Graceful degradation on agent failure

Handle agent failures gracefully — note which dimension was skipped and continue with remaining results.

- [x] **DEFINE**: After step 1, add failure handling that:
  - If an agent fails or times out, records which analysis dimension was skipped (e.g., "behavioral analysis skipped -- no git history" or "coupling analysis timed out")
  - Continues with remaining results
  - The skipped dimension is noted in the final report
  - Matches the pattern from `review.md`: "If an agent fails or times out, note which dimension was skipped and continue"

- [x] **APPLY**: Add failure handling to the spawn step (or as a sub-section of step 1).

- [x] **VERIFY**: Read the section. Confirm it covers agent failure, timeout, and partial results. Confirm it does NOT say "abort" or "fail the command."

---

## Behavior 5: Step 2 -- merge findings into assessment report

Merge findings from all agents into the assessment report format (Domain Vocabulary, Boundary Map, Healthy Boundaries, Mismatches).

- [x] **DEFINE**: Step 2 should:
  - Take outputs from all 4 agents (or whichever returned successfully)
  - Merge into the assessment report format from the spec (Domain Vocabulary, Boundary Map, Healthy Boundaries, Mismatches, Vocabulary Drift, Boundary Violations)
  - Use domain-language-extractor output as the primary source for vocabulary and boundary sections
  - Use review-coupling output for structural coupling findings
  - Use review-behavioral output for hotspot/temporal coupling context
  - Use context-gatherer output for project structure and test infrastructure details
  - Reference the report shape from the spec (do not duplicate the full template -- point to it or include a brief outline)

- [x] **APPLY**: Add Step 2 to the command file.

- [x] **VERIFY**: Read step 2. Confirm it describes how each agent's output maps to report sections. Confirm it references the assessment report shape. Confirm skipped dimensions are noted in the report.

---

## Behavior 6: Step 3 -- validation questions

Ask 2-3 targeted validation questions via AskUserQuestion with concrete options derived from findings.

- [x] **DEFINE**: Step 3 should:
  - Generate 2-3 validation questions based on the merged findings (not generic questions)
  - Each question uses AskUserQuestion with concrete options derived from the findings
  - Give examples of the kind of questions to ask: "Is Orders really separate from Shipments in your domain?", "Should 'delivery' be renamed to 'shipment' to match domain language?"
  - Options are specific to the findings, not open-ended (e.g., "Yes, they're separate bounded contexts" / "No, they belong together" / "It's complicated -- let me explain")
  - Record validation answers in the report under "Validation Notes"

- [x] **APPLY**: Add Step 3 to the command file.

- [x] **VERIFY**: Read step 3. Confirm it says 2-3 questions. Confirm it requires AskUserQuestion with concrete options. Confirm it includes examples. Confirm answers are recorded in the report.

---

## Behavior 7: Step 4 -- save report and collaboration loop

Save report to `docs/architecture-assessment.md` and run the collaboration loop (`@bee` annotations, `[x] Reviewed` gate).

- [x] **DEFINE**: Step 4 should:
  - Save the merged and validated assessment report to `docs/architecture-assessment.md`
  - Append `[ ] Reviewed` checkbox at the end of the report
  - Enter the collaboration loop (matching `build.md` pattern):
    - Tell developer where the report is saved
    - Explain they can add `@bee` annotations and mark `[x] Reviewed` to proceed
    - Wait for developer input; re-read file on "check"
    - Process `@bee` annotations if found
    - Proceed when `[x] Reviewed` is found
  - Reference `skills/collaboration-loop/SKILL.md` for the full format

- [x] **APPLY**: Add Step 4 to the command file.

- [x] **VERIFY**: Read step 4. Confirm it saves to the correct path. Confirm it includes the `[ ] Reviewed` gate. Confirm it references or describes the collaboration loop. Confirm it matches the pattern from `build.md`.

---

## Behavior 8: Step 5 -- delegate to architecture-test-writer

After `[x] Reviewed`, delegate to architecture-test-writer agent with confirmed report and test infrastructure details.

- [x] **DEFINE**: Step 5 should:
  - After `[x] Reviewed`, delegate to `architecture-test-writer` agent via Task tool
  - Pass: the confirmed assessment report path (`docs/architecture-assessment.md`), the context-gatherer's test infrastructure details, and the project root
  - Use `subagent_type`: `bee:architecture-test-writer`
  - Handle the case where no test framework is detected (from error handling AC): produce report but skip test generation with a clear message

- [x] **APPLY**: Add Step 5 to the command file.

- [x] **VERIFY**: Read step 5. Confirm it spawns `architecture-test-writer` with correct inputs. Confirm it passes test infrastructure details. Confirm it handles the no-framework fallback.

---

## Behavior 9: Step 6 -- summary report

Output summary: test count, file locations, pass vs fail breakdown, run command.

- [x] **DEFINE**: Step 6 should:
  - Report to the developer: how many tests were generated, where they live, how many are expected to pass vs fail
  - Use the output from the architecture-test-writer agent (which returns file list, passing count, failing count, run command)
  - Format as a brief, readable summary (not a wall of text)

- [x] **APPLY**: Add Step 6 to the command file.

- [x] **VERIFY**: Read step 6. Confirm it includes test count, file locations, and pass/fail breakdown. Confirm it matches the output format from `agents/architecture-test-writer.md`.

---

## Behavior 10: Error handling section

Cover all three error scenarios (no docs, no test framework, no git history) plus general orchestrator constraints.

- [x] **DEFINE**: Rules/error handling should cover:
  - No README, no docs, no website: fall back to code-only analysis, ask developer for domain vocabulary
  - No test framework and developer declines to specify: produce assessment report but skip test generation with clear message
  - No git history: skip review-behavioral agent, note in report
  - General: read the target project codebase (not the bee plugin itself), only the orchestrator spawns agents, agents cannot spawn sub-agents

- [x] **APPLY**: Add the error handling / rules section.

- [x] **VERIFY**: Read the section. Confirm all three spec error scenarios are addressed. Confirm the command never silently fails -- every degradation is communicated to the developer.

---

## Edge Cases (LOW risk -- minimal)

- [x] **VERIFY**: The command file does NOT include a `tools` field in frontmatter (commands use `description` only, unlike agents which list tools). Compare against `commands/review.md` frontmatter.

- [x] **VERIFY**: All agent `subagent_type` identifiers match the actual agent names from their frontmatter: `context-gatherer`, `review-coupling`, `review-behavioral`, `domain-language-extractor`, `architecture-test-writer`.

- [x] **VERIFY**: The collaboration loop section references or aligns with `skills/collaboration-loop/SKILL.md` rather than inventing a different format.

- [x] **VERIFY**: The report output path is `docs/architecture-assessment.md` (matching the spec), not some other path.

---

## Final Check

- [x] Read `commands/architect.md` top to bottom. Confirm:
  - YAML frontmatter has `description` (no `tools` or `name` -- it is a command, not an agent)
  - Persona establishes the orchestrator role
  - Skills reference architecture-patterns and collaboration-loop
  - Step 1: parallel spawn of 4 agents with subagent_type identifiers
  - Graceful degradation on agent failure (note and continue)
  - Step 2: merge findings into assessment report matching spec shape
  - Step 3: 2-3 validation questions via AskUserQuestion with concrete options
  - Step 4: save to `docs/architecture-assessment.md` + collaboration loop with `[ ] Reviewed`
  - Step 5: delegate to architecture-test-writer after review
  - Step 6: summary of generated tests (count, location, pass/fail)
  - Error handling covers all three spec scenarios
  - File reads naturally as a step-by-step flow a developer (or LLM) can follow

## Summary
| Step | Description | Status |
|------|------------|--------|
| Behavior 1 | YAML frontmatter and persona | done |
| Behavior 2 | Skills section | done |
| Behavior 3 | Parallel agent spawning | done |
| Behavior 4 | Graceful degradation on failure | done |
| Behavior 5 | Merge findings into report | done |
| Behavior 6 | Validation questions | done |
| Behavior 7 | Save report and collaboration loop | done |
| Behavior 8 | Delegate to test writer | done |
| Behavior 9 | Summary report | done |
| Behavior 10 | Error handling / rules | done |
| Edge cases | Frontmatter, subagent names, paths | done |
| Final check | Full file review | done |

---

[x] Reviewed
