# TDD Plan: Design Agent Phase 1 — Slice 3: Design Agent and Design Fundamentals Skill

## Execution Instructions
Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] -> [x]).
Continue until all items are done.
If stuck after 3 attempts, mark with a warning and move to the next independent step.

## Context
- **Source**: `docs/specs/design-agent-phase-1.md`
- **Slice**: Slice 3 — Design Agent and Design Fundamentals Skill
- **Risk**: LOW
- **Files to create**: `agents/design-agent.md`, `skills/design-fundamentals/SKILL.md`
- **Acceptance Criteria**:
  1. Agent file follows established agent format (YAML frontmatter, role, skills, inputs, steps, output, anti-patterns)
  2. Skill file contains reusable design knowledge (accessibility, spacing, typography, breakpoints)
  3. Agent references the skill file
  4. Agent reads context-gatherer output and extracts design system details
  5. Agent produces a brief documenting what exists — never suggests extensions
  6. Brief detail scales with design system complexity, not task size
  7. Brief follows the specified 7-section structure
  8. Brief saves to `.claude/DESIGN.md` in the target project
  9. Brief is created on first UI task, updated on subsequent runs
  10. Agent adds a reference to DESIGN.md in the project's CLAUDE.md
  11. Collaboration loop runs after the brief is produced

## Codebase Analysis

### File Structure
- New file: `agents/design-agent.md`
- New file: `skills/design-fundamentals/SKILL.md`
- No test files — these are markdown agent/skill definitions, not runnable code

### Format References
- Agent format: `agents/discovery.md`, `agents/context-gatherer.md`, `agents/spec-builder.md` — all share the same structure: YAML frontmatter (name, description, tools, model), role statement, skills section, inputs, numbered steps, output format, anti-patterns
- Skill format: `skills/clean-code/SKILL.md`, `skills/architecture-patterns/SKILL.md` — YAML frontmatter (name, description), then organized knowledge sections with principles, examples, and application guidance

### Key Design Decisions
- The agent documents what EXISTS — it never invents, extends, or suggests alternatives
- Detail scales with the design system's richness, not the task being worked on
- The brief is project-level context (persists across tasks), not feature-level
- Adapted from ui-ux-pro-max-skill patterns: priority-based rules, quality checklist values

---

## Behavior 1: Create the design fundamentals skill file

**Given** the skill file format established by `skills/clean-code/SKILL.md`
**When** the design agent needs reusable design knowledge to reference
**Then** `skills/design-fundamentals/SKILL.md` exists with organized design principles

Create the skill file FIRST because the agent will reference it.

- [x] **DEFINE EXPECTED CONTENT**: A skill file with YAML frontmatter (`name: design-fundamentals`, `description: ...`) followed by sections covering:
  - **Accessibility Rules**: 4.5:1 contrast ratio (WCAG AA), 44x44px minimum touch targets, focus visibility, ARIA landmark patterns
  - **Typography Hierarchy**: scale principles (not specific values — those come from the detected system), weight usage patterns, line-height guidance
  - **Spacing Principles**: consistent scale usage, relationship between spacing and hierarchy, whitespace purpose
  - **Responsive Breakpoints**: common breakpoints (375/768/1024/1440px), mobile-first vs desktop-first, when breakpoints matter
  - **Priority System**: accessibility (CRITICAL) > performance (HIGH) > typography/color (MEDIUM) > style (LOW) — adapted from ui-ux-pro-max-skill

- [x] **CREATE FILE**: Write `skills/design-fundamentals/SKILL.md`. Keep each section concise — principles and reference values, not tutorials. Follow the same tone as `skills/clean-code/SKILL.md` (direct, actionable, with brief examples).

- [x] **VERIFY**: Read the file back. Confirm:
  - YAML frontmatter has name and description
  - All five knowledge areas are present
  - Accessibility section includes the specific values (4.5:1, 44x44px)
  - Priority system is present
  - File reads as reference material, not as instructions for a specific task

---

## Behavior 2: Create the design agent file with correct frontmatter and role

**Given** the agent format established by `agents/discovery.md` and `agents/spec-builder.md`
**When** the design agent is created
**Then** it has proper YAML frontmatter and a clear role statement

- [x] **DEFINE EXPECTED CONTENT**: YAML frontmatter with:
  - `name: design-agent`
  - `description:` — one sentence about reading existing design systems and producing a brief
  - `tools: Read, Write, Glob, Grep` (needs to read project files and write the brief)
  - `model: inherit`

  Role statement: one paragraph establishing that this agent reads what exists and documents it. Emphasize: document, never invent.

- [x] **CREATE FILE**: Write `agents/design-agent.md` with the frontmatter and role statement. Do not add steps or output format yet — those come in subsequent behaviors.

- [x] **VERIFY**: Read the file. Confirm frontmatter matches the pattern from other agents. Confirm the role statement clearly states "document what exists, never suggest alternatives."

---

## Behavior 3: Add skills reference and inputs section

**Given** the agent needs to reference the design-fundamentals skill and receive context-gatherer output
**When** the skills and inputs sections are added
**Then** the agent knows where to find design principles and what data it receives

- [x] **DEFINE EXPECTED CONTENT**:
  - Skills section referencing `skills/design-fundamentals/SKILL.md` for design principles and `skills/clean-code/SKILL.md` for general quality
  - Inputs section listing what the agent receives: developer's task description, triage assessment (size + risk), full context-gatherer output (especially the Design System subsection with detected signals and file paths)

- [x] **APPLY CHANGE**: Add the Skills and Inputs sections to `agents/design-agent.md` after the role statement.

- [x] **VERIFY**: Read the file. Confirm skills reference points to the correct path. Confirm inputs list matches what the orchestrator passes (established in Slice 2).

---

## Behavior 4: Add numbered steps for design system extraction

**Given** the agent receives context-gatherer output with detected UI signals
**When** the agent processes a UI-involved task
**Then** it follows numbered steps to read project files and extract design system details

- [x] **DEFINE EXPECTED CONTENT**: Numbered steps that instruct the agent to:
  1. Read the context-gatherer output's Design System subsection to identify what was detected and where
  2. Read the detected files (Tailwind config, CSS custom properties, component library configs, design token files, etc.) to extract concrete values
  3. For each brief section, extract ONLY what the files contain — color values, font families, spacing scale, component names, layout patterns, accessibility patterns, token structure
  4. Check for existing `.claude/DESIGN.md` — if it exists, this is an update (compare and note changes); if not, this is the first run
  5. Assemble the design brief following the output format
  6. Save to `.claude/DESIGN.md` in the target project
  7. Check the project's CLAUDE.md for a "Design System" reference — if absent, add a section pointing to `.claude/DESIGN.md`

  Key instruction within steps: detail scales with what the design system contains. A project with Tailwind defaults gets a brief brief. A project with custom tokens, component library, and accessibility patterns gets a detailed brief. Task size is irrelevant.

- [x] **APPLY CHANGE**: Add the numbered steps section to `agents/design-agent.md`.

- [x] **VERIFY**: Read the steps. Confirm:
  - Step ordering makes sense (read context first, then files, then assemble, then save)
  - The "document, don't invent" principle is reinforced in the extraction steps
  - The update-vs-create logic is present
  - The CLAUDE.md reference step is present
  - Detail-scales-with-complexity instruction is explicit

---

## Behavior 5: Add the design brief output format

**Given** the spec requires a 7-section brief structure
**When** the agent produces its output
**Then** the brief follows the exact structure specified in the AC

- [x] **DEFINE EXPECTED CONTENT**: An output format section showing the brief template with all 7 sections:
  - **Color Palette**: detected colors with names/variables
  - **Typography**: font families, size scale, weight usage
  - **Spacing**: scale system
  - **Component Patterns**: detected UI library and conventions
  - **Layout**: grid/flex patterns, container widths, responsive breakpoints
  - **Accessibility Constraints**: contrast ratios, focus styles, ARIA patterns
  - **Design Tokens**: token structure if present (note: this section is conditional — omit if no tokens found)

  Include a brief example showing what a populated section looks like (e.g., a Tailwind + shadcn project) and a note about sparse sections: if a design system does not define something (e.g., no explicit tokens), omit that section rather than writing "not detected."

  Include the `[ ] Reviewed` gate at the end of the brief template for the collaboration loop.

- [x] **APPLY CHANGE**: Add the output format section to `agents/design-agent.md`.

- [x] **VERIFY**: Read the output format. Confirm all 7 sections are present. Confirm the save location is `.claude/DESIGN.md`. Confirm the Reviewed gate is included.

---

## Behavior 6: Add anti-patterns section

**Given** the agent must stay in "document, don't invent" mode
**When** the anti-patterns section is written
**Then** it guards against the most likely failure modes

- [x] **DEFINE EXPECTED CONTENT**: Anti-patterns section covering:
  - **Suggesting alternatives**: "The project uses MUI but you could also try shadcn" — never. Document what exists.
  - **Inventing missing pieces**: If no spacing scale is detected, do NOT suggest one. Just omit.
  - **Over-detailing simple systems**: A Tailwind project with zero customization should produce a short brief, not an exhaustive Tailwind reference.
  - **Under-detailing rich systems**: A project with custom tokens, theme config, and component library deserves thorough documentation.
  - **Ignoring the existing brief**: On subsequent runs, read the existing `.claude/DESIGN.md` first. Update it, do not replace it without reason.
  - **Task-size scaling**: Do NOT write more detail because the task is an EPIC. Brief detail reflects the design system, not the task.

- [x] **APPLY CHANGE**: Add the anti-patterns section to `agents/design-agent.md`.

- [x] **VERIFY**: Read the anti-patterns. Confirm each one is actionable (tells the agent what NOT to do and why). Confirm the "document, don't invent" theme is the throughline.

---

## Behavior 7: Add CLAUDE.md reference instruction

**Given** the agent saves the brief to `.claude/DESIGN.md`
**When** the project's CLAUDE.md does not yet reference the design brief
**Then** the agent adds a "Design System" section to CLAUDE.md pointing to the file

- [x] **VERIFY this is covered in Step 7 of Behavior 4**: Read the numbered steps and confirm the CLAUDE.md reference logic is present. It should:
  - Read the project's CLAUDE.md (if it exists)
  - Check for an existing "Design System" reference
  - If absent, append a short section like: `## Design System\nSee .claude/DESIGN.md for the detected design system brief.`
  - If present, leave it unchanged
  - If no CLAUDE.md exists, note this but do not create one (that is the project's responsibility)

- [x] **ADJUST if needed**: If the instruction in Step 7 is too brief, expand it to cover these cases.

---

## Edge Cases (LOW risk — minimal)

- [x] **VERIFY**: The skill file does not duplicate content from other skills. Cross-check with `skills/clean-code/SKILL.md` — no overlap in principles. The design skill is about visual/UI principles, clean-code is about code structure.

- [x] **VERIFY**: The agent file uses consistent markdown formatting with other agents. Same heading levels, same frontmatter fields, same section ordering (role, skills, inputs, steps, output, anti-patterns).

- [x] **VERIFY**: The output format's conditional sections (Design Tokens) are clearly marked as "include only if detected." An executor following this agent should not write empty sections.

---

## Final Check

- [x] Read `skills/design-fundamentals/SKILL.md` top to bottom. Confirm:
  - YAML frontmatter is valid
  - All five knowledge areas are present (accessibility, typography, spacing, breakpoints, priority system)
  - Specific values are included (4.5:1, 44x44px, breakpoint sizes)
  - Reads as a reference, not as task instructions

- [x] Read `agents/design-agent.md` top to bottom. Confirm:
  - YAML frontmatter matches the established pattern (name, description, tools, model)
  - Role statement emphasizes "document what exists"
  - Skills section references design-fundamentals
  - Inputs section lists what the orchestrator passes
  - Numbered steps cover: read context, read files, extract values, check existing brief, assemble, save, update CLAUDE.md
  - Output format has all 7 brief sections
  - Anti-patterns guard against inventing, suggesting, and wrong scaling
  - File reads naturally — an LLM following this agent definition could produce the correct brief

## Summary
| Step | Description | Status |
|------|------------|--------|
| Behavior 1 | Design fundamentals skill file | Done |
| Behavior 2 | Agent frontmatter and role | Done |
| Behavior 3 | Skills reference and inputs | Done |
| Behavior 4 | Numbered extraction steps | Done | 
| Behavior 5 | Design brief output format | Done |
| Behavior 6 | Anti-patterns | Done |
| Behavior 7 | CLAUDE.md reference instruction | Done |
| Edge cases | No duplication, consistent format, conditional sections | Done |
| Final check | Both files reviewed top to bottom | Done |

---

[x] Reviewed
