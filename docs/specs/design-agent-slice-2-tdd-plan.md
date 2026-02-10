# TDD Plan: Design Agent Phase 1 — Slice 2: Orchestrator Routes to Design Agent

## Execution Instructions
Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] -> [x]).
Continue until all items are done.
If stuck after 3 attempts, mark with a warning and move to the next independent step.

## Context
- **Source**: `docs/specs/design-agent-phase-1.md`
- **Slice**: Slice 2 — Orchestrator Routes to Design Agent
- **Risk**: LOW
- **File to modify**: `commands/bee.md`
- **Acceptance Criteria**:
  1. Orchestrator reads the "UI-involved" flag from context-gatherer output
  2. When "UI-involved: yes", orchestrator triggers the design agent after context-gathering (parallel to discovery when both are needed)
  3. When "UI-involved: no", the design agent is skipped entirely
  4. Design agent triggers for any task size (TRIVIAL, SMALL, FEATURE, EPIC) when the flag is set
  5. Orchestrator passes context-gatherer output (including the Design System subsection) to the design agent

## Codebase Analysis

### File Structure
- Implementation: `commands/bee.md` (single file modification)
- No test files — this is a markdown orchestrator definition, not runnable code
- Related: `agents/context-gatherer.md` (already updated in Slice 1 with Design System subsection)

### What Exists Today
The orchestrator (`commands/bee.md`) has this flow for FEATURE/EPIC tasks:
1. Context Gathering — delegates to context-gatherer agent via Task
2. Tidy check — optional cleanup if context-gatherer flagged opportunities
3. Discovery Evaluation — decides whether discovery is needed, delegates if so
4. Build Cycle — spec, architecture, TDD plan, execute, verify, review

For SMALL tasks: context-gatherer runs, then a lightweight summary is given.

The design agent routing needs to slot in after context-gathering returns (since it reads the UI-involved flag from that output), parallel to discovery.

### Routing Pattern to Follow
Discovery routing (lines ~265-306) is the model. It:
- Reads context-gatherer output to make a decision (decision density)
- Has clear criteria for when to trigger vs. skip
- Delegates via Task with specific inputs listed
- Updates state after completion
- Runs the Collaboration Loop on the output document

The design agent routing should follow the same structure but is simpler — it is a binary flag check (UI-involved yes/no), not a judgment call.

---

## Behavior 1: Add design agent routing section after context-gathering

**Given** the context-gatherer returns output that includes a Design System subsection with "UI-involved: yes/no"
**When** the orchestrator processes the context-gatherer result
**Then** a new section checks the UI-involved flag and routes accordingly

- [x] **DEFINE EXPECTED CHANGE**: A new subsection titled "Design Agent Evaluation" placed after the tidy check and before "Discovery Evaluation". The section instructs Bee to:
  - Read the "UI-involved" flag from the context-gatherer output's Design System subsection
  - When "UI-involved: yes" — delegate to the design agent via Task
  - When "UI-involved: no" — skip the design agent entirely, no message needed

- [x] **APPLY CHANGE**: Insert the new subsection into `commands/bee.md` in the FEATURE/EPIC flow, after the tidy opportunity check (around line 258) and before "Discovery Evaluation" (around line 263).

- [x] **VERIFY**: Read the file back. Confirm the tidy check, design agent evaluation, and discovery evaluation appear in that order. Confirm the design agent section checks the "UI-involved" flag.

---

## Behavior 2: Design agent triggers for ALL task sizes when flag is set

**Given** the orchestrator handles TRIVIAL, SMALL, FEATURE, and EPIC differently
**When** the context-gatherer flags "UI-involved: yes"
**Then** the design agent is triggered regardless of task size

- [x] **DEFINE EXPECTED CHANGE**: The design agent routing should not be gated by task size. Currently the FEATURE/EPIC section is the only path that runs context-gathering. For SMALL tasks, context-gathering also runs (line ~248). The design agent check should appear in both flows. For TRIVIAL, context-gathering does not run, so the design agent also does not run (which is correct — no context output to read).

- [x] **APPLY CHANGE**: Add a design agent check in the SMALL task flow as well, after context-gatherer returns and before the summary. Keep the same pattern: check UI-involved flag, delegate if yes, skip if no.

- [x] **VERIFY**: Read the SMALL and FEATURE/EPIC sections. Confirm both check the UI-involved flag after context-gathering. Confirm TRIVIAL has no design agent mention (correct, since no context-gatherer runs).

---

## Behavior 3: Orchestrator passes context-gatherer output to design agent

**Given** the design agent needs the full context-gatherer output (especially the Design System subsection)
**When** the orchestrator delegates to the design agent
**Then** the Task delegation includes the context-gatherer output as input

- [x] **DEFINE EXPECTED CHANGE**: The delegation instruction should explicitly list what to pass to the design agent:
  - The developer's task description
  - The full context-gatherer output (including the Design System subsection with detected signals, file paths, and flags)
  - The triage assessment (size + risk)

- [x] **APPLY CHANGE**: Update the design agent delegation instructions in both the SMALL and FEATURE/EPIC sections to include these inputs.

- [x] **VERIFY**: Read the delegation instructions. Confirm the context-gatherer output is explicitly mentioned as an input, particularly the Design System subsection.

---

## Behavior 4: Design agent runs parallel to discovery when both are needed

**Given** a FEATURE/EPIC task where both "UI-involved: yes" and discovery is warranted
**When** the orchestrator routes to both agents
**Then** the design agent and discovery can run in parallel (not sequentially gated)

- [x] **DEFINE EXPECTED CHANGE**: The design agent section should state that when discovery is also needed, the design agent runs independently — it does not wait for discovery, and discovery does not wait for it. Both read context-gatherer output directly. Add a note like: "The design agent and discovery are independent — neither blocks the other. Both consume the context-gatherer output."

- [x] **APPLY CHANGE**: Add the parallelism note to the design agent section in the FEATURE/EPIC flow.

- [x] **VERIFY**: Read the design agent and discovery sections together. Confirm there is no dependency chain between them — both follow context-gathering, neither requires the other's output.

---

## Behavior 5: Update state tracking for design agent

**Given** the state tracking section in bee.md
**When** the design agent completes
**Then** state is updated to reflect design agent completion

- [x] **DEFINE EXPECTED CHANGE**: Add a state transition note to the design agent section: after the design agent returns, update state with the design brief path. This mirrors how discovery adds its doc path to state.

- [x] **APPLY CHANGE**: Add the state update instruction to the design agent routing section.

- [x] **VERIFY**: Read the state tracking section ("When to Update State" list). Confirm a design-agent-related transition is present or can be inferred from the routing section's inline state update.

---

## Behavior 6: Register design-agent in the "WHAT'S IMPLEMENTED" list

**Given** the "WHAT'S IMPLEMENTED" section at the bottom of bee.md
**When** the design agent is added to the pipeline
**Then** it appears in the implemented agents list

- [x] **DEFINE EXPECTED CHANGE**: Add a bullet to the list:
  `- design-agent: **live** — produces design brief for UI-involved tasks, reads context-gatherer Design System signals`

- [x] **APPLY CHANGE**: Add the bullet in alphabetical position (after "discovery" and before "quick-fix").

- [x] **VERIFY**: Read the WHAT'S IMPLEMENTED section. Confirm design-agent appears in the list with the correct description.

---

## Edge Cases (LOW risk — minimal)

- [x] **VERIFY**: The new sections do not break the existing SMALL task flow. The SMALL flow currently ends with a summary message — the design agent check should not change this behavior when UI-involved is "no".

- [x] **VERIFY**: The new sections use the same markdown heading levels and formatting style as neighboring sections (e.g., `###` for subsections within the FEATURE/EPIC flow).

---

## Final Check

- [x] Read `commands/bee.md` top to bottom. Confirm:
  - TRIVIAL flow is unchanged (no design agent mention)
  - SMALL flow checks UI-involved after context-gatherer, delegates to design agent if yes
  - FEATURE/EPIC flow has Design Agent Evaluation after tidy and before Discovery Evaluation
  - Design agent delegation explicitly passes context-gatherer output including Design System subsection
  - Parallel execution note exists for design agent + discovery
  - State update instruction present
  - WHAT'S IMPLEMENTED list includes design-agent
  - File reads naturally — no awkward transitions between sections

## Summary
| Step | Description | Status |
|------|------------|--------|
| Behavior 1 | Design agent routing section in FEATURE/EPIC flow | Done |
| Behavior 2 | Trigger for all sizes (SMALL + FEATURE/EPIC) | Done |
| Behavior 3 | Pass context-gatherer output to design agent | Done |
| Behavior 4 | Parallel to discovery | Done |
| Behavior 5 | State tracking update | Done |
| Behavior 6 | WHAT'S IMPLEMENTED registration | Done |
| Edge cases | No breakage, consistent formatting | Done |
| Final check | Full file review | Done |

---

[ ] Reviewed
