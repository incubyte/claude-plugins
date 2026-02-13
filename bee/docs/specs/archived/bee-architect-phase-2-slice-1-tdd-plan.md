# TDD Plan: Bee Architect Phase 2 -- Slice 1: Discovery Module Structure Output

## Execution Instructions
Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] -> [x]).
Continue until all items are done.
If stuck after 3 attempts, mark with a warning and move to the next independent step.

## Context
- **Source**: `docs/specs/bee-architect-phase-2.md`
- **Slice**: Discovery Module Structure Output (`agents/discovery.md`)
- **Risk**: LOW
- **File to modify**: `agents/discovery.md`
- **Acceptance Criteria**:
  1. When discovery detects a greenfield project, the PRD includes a "Module Structure" section after the Milestone Map
  2. Each module entry lists the module name, owned domain concepts, and allowed dependencies
  3. The Module Structure is derived from the Milestone Map capabilities (not invented independently)
  4. When non-greenfield, the Module Structure section is omitted

## Codebase Analysis

### File Structure
- Implementation: `agents/discovery.md` (existing file, modify in place)
- Pattern reference: existing PRD output format in `agents/discovery.md` lines 105-147
- Spec shape reference: `docs/specs/bee-architect-phase-2.md` lines 59-67

### Verification Method
Since this is a markdown agent definition, each step is verified by reading the file back and confirming the section exists, follows the established pattern, and covers the relevant acceptance criteria.

---

## Behavior 1: Add greenfield-conditional gate before Module Structure

The discovery agent already receives a greenfield signal in its inputs (from context-gatherer or inline answers). Add an explicit instruction that after writing the Milestone Map, the agent checks whether the project is greenfield before proceeding to Module Structure.

- [x] **DEFINE**: After the Milestone Map writing guidance (around line 139 in the current file), add a conditional step: "If the project is greenfield (from context-gatherer signal, empty repo, or Revised Assessment), proceed to write the Module Structure section. If non-greenfield, skip Module Structure entirely."

- [x] **APPLY**: Edit `agents/discovery.md` to add this conditional instruction between the Milestone Map and Open Questions sections of the Output Format.

- [x] **VERIFY**: Read the file. Confirm the greenfield check is present. Confirm it references the same greenfield signals already documented in the Inputs section. Confirm it clearly says to skip for non-greenfield.

---

## Behavior 2: Add Module Structure section to the PRD output template

Add the Module Structure section to the PRD markdown template, positioned after the Milestone Map and before Open Questions.

- [x] **DEFINE**: The new section in the output template should look like:
  - Heading: `## Module Structure`
  - Conditional note: only included for greenfield projects
  - Each entry: `` `modulename/` -- owns: Concept1, Concept2. Depends on: (none) or other module names ``

- [x] **APPLY**: Insert the Module Structure section into the PRD output format template in `agents/discovery.md`, between Milestone Map and Open Questions.

- [x] **VERIFY**: Read the output template. Confirm Module Structure appears after Milestone Map. Confirm the entry format matches the spec shape (module name, owned concepts, dependencies). Confirm the conditional note is present.

---

## Behavior 3: Add derivation instruction -- Module Structure comes from Milestone Map

Add explicit guidance that the module structure must be derived from the Milestone Map capabilities, not invented independently.

- [x] **DEFINE**: Add a writing guideline (alongside the existing ones like "Milestone map is vertical, not horizontal") that instructs:
  - Extract modules from the capabilities already listed in each milestone phase
  - Group related capabilities into module boundaries
  - Each module's "owns" list comes from the domain concepts mentioned in those capabilities
  - Dependencies are inferred from which modules need data or behavior from other modules
  - Do not invent modules that have no basis in the Milestone Map

- [x] **APPLY**: Add this derivation guidance. It can go either as a sub-instruction within the Module Structure template section, or as a new item in the Writing Guidelines.

- [x] **VERIFY**: Read the guidance. Confirm it explicitly ties modules back to Milestone Map capabilities. Confirm it prohibits inventing modules beyond what the milestones describe.

---

## Behavior 4: Add Module Structure to the Revised Assessment footer

The PRD ends with a Revised Assessment block that includes Size and Greenfield fields. The greenfield field is already there. No structural change needed, but confirm the existing greenfield field is sufficient for downstream agents to know whether Module Structure was included.

- [x] **DEFINE**: The existing `Greenfield: [yes/no]` field in Revised Assessment is the signal downstream agents (build.md) will use. Verify it is already present and no change is needed.

- [x] **VERIFY**: Read the Revised Assessment section of the output template. Confirm `Greenfield: [yes/no]` is present. If it is, no edit needed -- mark this step done.

---

## Edge Cases (LOW risk -- minimal)

- [x] **VERIFY**: The Module Structure section does not appear unconditionally in the template -- it is clearly marked as greenfield-only with a conditional instruction the agent can follow.

- [x] **VERIFY**: The file still has valid markdown structure after edits -- heading levels are consistent, no broken formatting, frontmatter fences intact.

- [x] **VERIFY**: No existing sections were accidentally removed or reordered. The original PRD structure (Why, Who, Success Criteria, Problem Statement, Hypotheses, Out of Scope, Milestone Map, Open Questions, Revised Assessment) is intact, with Module Structure inserted in the correct position.

---

## Final Check

- [x] Read `agents/discovery.md` top to bottom. Confirm:
  - Frontmatter and persona are unchanged
  - Skills, Inputs, Interview/Synthesis flow are unchanged
  - PRD output template now includes Module Structure between Milestone Map and Open Questions
  - Module Structure is conditional on greenfield
  - Module entry format matches spec: `` `name/` -- owns: X, Y. Depends on: Z ``
  - Derivation guidance ties modules to Milestone Map capabilities
  - Non-greenfield path explicitly omits Module Structure
  - File reads naturally -- the new section does not disrupt the existing flow

## Summary
| Step | Description | Status |
|------|------------|--------|
| Behavior 1 | Greenfield-conditional gate | done |
| Behavior 2 | Module Structure in PRD template | done |
| Behavior 3 | Derivation from Milestone Map | done |
| Behavior 4 | Revised Assessment field check | done |
| Edge cases | Conditional, valid markdown, no regressions | done |
| Final check | Full file review | done |
