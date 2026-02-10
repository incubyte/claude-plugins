# TDD Plan: Design Agent Phase 1 — Slice 1: Context-Gatherer Detects UI Signals

## Execution Instructions
Read this plan. Work on every item in order.
Mark each checkbox done as you complete it ([ ] -> [x]).
Continue until all items are done.
If stuck after 3 attempts, mark with a warning and move to the next independent step.

## Context
- **Source**: `docs/specs/design-agent-phase-1.md`
- **Slice**: Slice 1 — Context-Gatherer Detects UI Signals
- **Risk**: LOW
- **File to modify**: `agents/context-gatherer.md`
- **Acceptance Criteria**:
  1. Context-gatherer scans for UI signals: frontend frameworks, Tailwind config, CSS variables, component libraries, design tokens, template/view files
  2. Output includes a "Design System" subsection with "UI-involved: yes/no" and "Has design system: yes/no" flags
  3. When UI signals found, lists what was detected with locations
  4. When no UI signals found, says "No UI signals detected" and both flags are "no"
  5. Existing output format remains unchanged

## Codebase Analysis

### File Structure
- Implementation: `agents/context-gatherer.md` (single file modification)
- No test files — this is a markdown agent definition, not runnable code

### What Exists Today
The context-gatherer has 7 numbered scan sections (Project Structure through Tidy Opportunities) and an Output Format section with 7 subsections (Project Structure through Tidy Opportunities). The new "Design System" subsection must slot in without disrupting either.

---

## Behavior 1: Add UI signal scanning instructions

**Given** the context-gatherer's numbered scan sections (1-7)
**When** the agent runs on any project
**Then** it should also scan for UI signals as part of its analysis

- [x] **DEFINE EXPECTED CHANGE**: A new numbered section (Section 8) titled "Design System Signals" that instructs the agent to scan for:
  - Frontend frameworks: React, Vue, Svelte, Angular, SolidJS, Qwik (package.json deps, framework config files, file extensions like .jsx, .tsx, .vue, .svelte)
  - Tailwind: tailwind.config.ts/js, @tailwind directives in CSS
  - CSS custom properties: :root blocks with --color-*, --spacing-*, etc.
  - Component libraries: shadcn (components.json), MUI (@mui/*), Chakra (@chakra-ui/*), Radix, Ant Design, etc.
  - Design tokens: token files (tokens.json, tokens.css, style-dictionary config)
  - Template/view files: .ejs, .hbs, .pug, .blade.php, .erb

- [x] **APPLY CHANGE**: Add Section 8 to `agents/context-gatherer.md` after Section 7 (Tidy Opportunities) and before the Output Format section. Keep it concise — a short paragraph of instruction plus a bullet list of what to look for.

- [x] **VERIFY**: Read the file back. Confirm sections 1-7 are unchanged. Confirm section 8 exists with the scanning instructions.

---

## Behavior 2: Add Design System subsection to output format

**Given** the output format template in context-gatherer.md
**When** UI signals ARE found
**Then** the output includes a "Design System" subsection with flags and detection details

- [x] **DEFINE EXPECTED CHANGE**: A new subsection in the Output Format markdown block, placed after "Tidy Opportunities" and before the closing code fence. Structure:
  ```
  ### Design System
  - **UI-involved**: [yes / no]
  - **Has design system**: [yes / no]
  - **Detected signals**: [list of what was found with file paths]
  ```
  The "Has design system" flag is "yes" when there is evidence of a cohesive system (Tailwind config, design tokens, component library). Individual CSS files alone would be "UI-involved: yes" but "Has design system: no".

- [x] **APPLY CHANGE**: Add the Design System subsection to the output format template in `agents/context-gatherer.md`.

- [x] **VERIFY**: Read the output format section. Confirm all 7 existing subsections are intact. Confirm the new Design System subsection appears with both flags and the detected signals field.

---

## Behavior 3: Define the "no signals" output

**Given** the output format template
**When** no UI signals are found
**Then** the subsection shows "No UI signals detected" with both flags as "no"

- [x] **DEFINE EXPECTED CHANGE**: Add a note in the scanning section (Section 8) that when no UI signals are detected, the output should read:
  ```
  ### Design System
  - **UI-involved**: no
  - **Has design system**: no
  - **Detected signals**: No UI signals detected
  ```

- [x] **APPLY CHANGE**: Include this guidance in the Section 8 instructions — tell the agent what to output when nothing is found.

- [x] **VERIFY**: Read Section 8. Confirm it covers both the "found signals" and "no signals" cases.

---

## Behavior 4: Register Design System as a downstream consumer

**Given** the "consumed by" list at the bottom of context-gatherer.md
**When** the design agent is added to the pipeline (Slice 2+)
**Then** the context-gatherer documents that the Design System subsection feeds the design agent

- [x] **DEFINE EXPECTED CHANGE**: Add a bullet to the "This format is consumed directly by" list:
  - **design-agent**: uses Design System subsection to determine whether to activate and what signals to investigate further

- [x] **APPLY CHANGE**: Add the bullet to the consumer list.

- [x] **VERIFY**: Read the consumer list. Confirm all existing consumers (spec-builder, architecture-advisor, TDD planners, verifier/reviewer) are unchanged. Confirm the new design-agent entry is present.

---

## Edge Cases (LOW risk — minimal)

- [x] **VERIFY**: The new Section 8 does not duplicate anything already in Section 1 (Project Structure). Section 1 covers tech stack broadly; Section 8 focuses specifically on UI/design signals. If there is overlap, adjust Section 8 to reference Section 1 findings rather than re-scanning.

- [x] **VERIFY**: The output format remains valid markdown. The new subsection uses the same heading level (###) and bullet style (- **Bold**: value) as existing subsections.

---

## Final Check

- [x] Read `agents/context-gatherer.md` top to bottom. Confirm:
  - Sections 1-7 are unchanged in content
  - Section 8 (Design System Signals) is present with clear scanning instructions
  - Output format has all 7 original subsections plus the new Design System subsection
  - Both "signals found" and "no signals" cases are covered
  - Consumer list includes design-agent
  - File reads naturally — no awkward transitions between sections

## Summary
| Step | Description | Status |
|------|------------|--------|
| Behavior 1 | Scanning instructions for UI signals | Done |
| Behavior 2 | Design System subsection in output format | Done |
| Behavior 3 | No-signals output case | Done |
| Behavior 4 | Downstream consumer registration | Done |
| Edge cases | No duplication, valid markdown | Done |
| Final check | Full file review | Done |

---

[x] Reviewed
