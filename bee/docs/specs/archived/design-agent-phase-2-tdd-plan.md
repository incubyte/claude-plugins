# TDD Plan: Design Agent Phase 2 -- Greenfield Interview Flow

## Execution Instructions
Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] -> [x]).
Continue until all items are done.
If stuck after 3 attempts, mark with a warning and move to the next independent step.

**Note**: This is a markdown-only change -- no runnable code, no test files. Each "behavior" is a section added to `agents/design-agent.md`. Verification is manual: read the agent file and confirm the behavior is described clearly enough that an LLM following it would produce the correct output.

## Context
- **Source**: `docs/specs/design-agent-phase-2.md`
- **Slice**: Full spec (single slice)
- **Risk**: LOW
- **Only file to modify**: `agents/design-agent.md`

## Codebase Analysis

### Current Agent Structure
The existing agent at `agents/design-agent.md` has:
- YAML frontmatter (name, description, tools, model)
- Role statement: "document what exists. Never invent."
- Skills section (references design-fundamentals, clean-code)
- Inputs section
- Steps 1-6 (read context -> read files -> extract values -> check existing brief -> assemble/save -> update CLAUDE.md)
- Output format (7-section brief template)
- Anti-patterns section

### What Phase 2 Adds
A conditional branch: when "Has design system: no" but "UI-involved: yes", the agent follows a greenfield interview flow instead of the existing extraction flow. The existing flow stays untouched.

### Key Dependencies
- `skills/design-fundamentals/SKILL.md` -- provides accessibility rules, typography principles, spacing scales, visual quality checklist
- AskUserQuestion interaction pattern (same as spec-builder)

---

## Behavior 1: Update the Role Statement

The current role says "document what exists. Never invent." Phase 2 adds a second mode where the agent DOES propose a design direction for greenfield projects.

- [x] **WRITE**: Update the agent description and role statement
  - Location: `agents/design-agent.md` (frontmatter `description` field + opening paragraph)
  - The description should cover both modes: extraction for existing systems, interview + proposal for greenfield
  - Keep the "document what exists" rule for the existing-system path -- it still applies there
  - Add a clear sentence: when no design system exists, the agent interviews the developer and proposes a cohesive direction

- [x] **VERIFY**: Read the updated role statement. Does it clearly communicate two modes without contradicting itself?

---

## Behavior 2: Add Branching Logic to the Steps

The steps currently assume an existing design system. Add a decision point after Step 1 that routes to the correct flow.

- [x] **WRITE**: Modify Step 1 to include a branching decision
  - After reading the context-gatherer output, add: "If Has design system: yes -> continue to Step 2 (existing system extraction). If Has design system: no but UI-involved: yes -> jump to Step 7 (greenfield interview flow)."
  - Keep Steps 2-6 exactly as they are -- they are the existing-system path

- [x] **VERIFY**: The branch is unambiguous. An LLM reading the steps knows exactly which path to follow based on the two flags.

---

## Behavior 3: Auto-Detection of Partial Signals (Greenfield Pre-Scan)

Before interviewing, the agent should scan for partial signals to reduce questions.

- [x] **WRITE**: Add Step 7 -- "Scan for partial design signals"
  - Location: New step in `agents/design-agent.md`, after the existing Steps 1-6
  - What to scan: `package.json` dependencies (e.g., Tailwind, MUI, Chakra), any CSS files with color definitions, favicon/logo files, README mentions of brand/colors/design
  - Output: a list of detected signals with what information they provide (e.g., "Found Tailwind in dependencies -- framework choice is known, skip that question")
  - Explicit instruction: skip interview questions the agent can answer from detected signals

- [x] **VERIFY**: The scan targets are concrete (specific files, specific patterns). Not vague like "look for design clues."

---

## Behavior 4: Adaptive Interview Flow

The core of Phase 2 -- an interview that asks 1-10 questions based on what was auto-detected.

- [x] **WRITE**: Add Step 8 -- "Interview the developer"
  - Location: New step in `agents/design-agent.md`
  - Structure the interview with these topics (skip any answered by auto-detection):
    1. Mood/style direction -- offer concrete options ("Clean & Minimal", "Bold & Vibrant", "Warm & Approachable", "Corporate & Trustworthy", or describe your own)
    2. Industry context and reference sites -- ask when mood alone is insufficient
    3. Logo -- "Paste a logo if you have one (optional)" -- if pasted, extract dominant colors and style cues via multimodal; if skipped, continue
    4. Brand colors -- ask only when none auto-detected and no logo provided
    5. Font preferences -- ask if not detected
  - Use AskUserQuestion with concrete options (not open-ended)
  - Adaptive turn count: 1 turn if most is auto-detected, up to 10 for blank-slate

- [x] **VERIFY**: Each interview question offers concrete starting points. No question is "what do you want?" -- all have options. The flow explicitly says to skip questions answered by auto-detection.

---

## Behavior 5: Propose a Design Direction

After gathering inputs, the agent proposes a cohesive direction.

- [x] **WRITE**: Add Step 9 -- "Propose design direction"
  - Location: New step in `agents/design-agent.md`
  - The proposal includes:
    - Color palette: primary, secondary, accent, neutral, semantic colors (with hex values)
    - Font pairing: heading + body
    - Spacing scale
    - Component style direction
    - "Design personality" summary: 1-2 sentence description of intended visual feel
  - Ground the proposal in the design-fundamentals skill (accessibility, typography, spacing principles)
  - Color contrast between proposed text/background must pass WCAG AA (4.5:1 normal, 3:1 large)
  - Present the proposal to the developer for approval before saving

- [x] **VERIFY**: The proposal structure is concrete (specific sections with specific content). The design-fundamentals skill is explicitly referenced as the source for accessibility and typography decisions.

---

## Behavior 6: Quality Checklist Section in the Brief

The saved brief includes a quality checklist.

- [x] **WRITE**: Add a "Quality Checklist" section to the greenfield output format
  - Location: In the output format section of `agents/design-agent.md`
  - The checklist references values from `skills/design-fundamentals/SKILL.md` (Visual Quality Checklist section), not hardcoded values
  - Items: color contrast WCAG AA, touch targets 44x44px, transitions 150-300ms, responsive breakpoints defined, focus states visible, prefers-reduced-motion respected
  - Explicit instruction: "Pull checklist items from the design-fundamentals skill -- do not hardcode values in this agent"

- [x] **VERIFY**: The checklist section exists in the output format. The agent is instructed to source values from the skill file, not duplicate them.

---

## Behavior 7: Greenfield Output Format

The greenfield brief saves to the same location and format as Phase 1, with additions.

- [x] **WRITE**: Add greenfield-specific sections to the output format
  - Location: Output format section of `agents/design-agent.md`
  - Add "Design Personality" section (1-2 sentence summary)
  - Add "Quality Checklist" section (from Behavior 6)
  - Keep the same header, file location (`.claude/DESIGN.md`), and collaboration loop gate (`[ ] Reviewed`)
  - Note that the greenfield brief uses `> Proposed by Bee's design agent` instead of `> Auto-generated by Bee's design agent. Documents the project's existing design system.`

- [x] **VERIFY**: The output format is compatible with Phase 1 consumption. The brief includes the `[ ] Reviewed` gate. The header distinguishes proposed from extracted.

---

## Behavior 8: Handle Existing Brief on Re-Run

If `.claude/DESIGN.md` already exists from a previous greenfield interview, offer to update.

- [x] **WRITE**: Add re-run handling to the greenfield flow
  - Location: Within the greenfield steps (before the interview)
  - Check for existing `.claude/DESIGN.md` -- if found, read it and offer: "A design brief already exists. Update it with new inputs, or start fresh?"
  - This mirrors the existing Step 4 behavior but for the greenfield path

- [x] **VERIFY**: The re-run case is handled. The agent does not silently overwrite an existing brief.

---

## Behavior 9: Error Case -- Developer Skips All Questions

- [x] **WRITE**: Add fallback behavior for skipped questions
  - Location: Within the interview step
  - If the developer declines to answer all questions, produce a minimal brief using sensible defaults from design-fundamentals
  - Flag the brief clearly: "Default values -- consider reviewing before proceeding"

- [x] **VERIFY**: The fallback is explicit. The brief is marked as default. Defaults come from the skill file, not invented values.

---

## Behavior 10: Error Case -- Conflicting Inputs

- [x] **WRITE**: Add conflict resolution behavior
  - Location: Within the proposal step
  - If inputs conflict (e.g., "bold and vibrant" mood but muted corporate logo), the agent acknowledges the tension and asks which direction to prioritize
  - Use AskUserQuestion with the two directions as options

- [x] **VERIFY**: The conflict case is described with a concrete example. The resolution mechanism is interactive (asks the developer), not autonomous.

---

## Behavior 11: Greenfield Anti-Patterns

- [x] **WRITE**: Add greenfield-specific anti-patterns
  - Location: Anti-patterns section of `agents/design-agent.md`
  - Add: "Don't propose without gathering input" -- always interview first, even if the agent has opinions
  - Add: "Don't ignore partial signals" -- if a CSS file already defines colors, use them as a starting point rather than asking from scratch
  - Add: "Don't present open-ended questions" -- always offer concrete options

- [x] **VERIFY**: The new anti-patterns are distinct from the existing ones (which are about the extraction flow). They address greenfield-specific failure modes.

---

## Final Check

- [x] **Read the complete agent file** top to bottom. Does it flow logically? Can an LLM follow it without ambiguity?
- [x] **Verify the existing extraction flow (Steps 1-6) is untouched** -- Phase 2 adds alongside, never modifies
- [x] **Verify the branching point is clear** -- no scenario where the agent doesn't know which path to follow
- [x] **Verify all spec acceptance criteria are covered**:
  - [x] Detection and Auto-Extraction (3 criteria) -- Behaviors 2, 3
  - [x] Interview Flow (5 criteria) -- Behavior 4
  - [x] Design Proposal (4 criteria) -- Behavior 5
  - [x] Quality Checklist (2 criteria) -- Behavior 6
  - [x] Output and Integration (4 criteria) -- Behaviors 7, 8
  - [x] Error Cases (2 criteria) -- Behaviors 9, 10

## Summary
| Category | # Behaviors | Status |
|----------|-------------|--------|
| Core flow (branch, scan, interview, propose) | 5 | Done |
| Output format (personality, checklist, brief) | 2 | Done |
| Edge cases (re-run, skip-all, conflicts) | 3 | Done |
| Anti-patterns | 1 | Done |
| **Total** | **11** | **Done** |
[x] reviewed
