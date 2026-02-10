# Spec: Design Agent Phase 1 -- Existing Design Systems

## Overview
Add design awareness to Bee's pipeline for projects that already have a design system. The context-gatherer detects UI signals, the orchestrator routes to a new design agent, and the agent produces a persistent design brief (`.claude/DESIGN.md`) that constrains all downstream work to the existing system.

Discovery doc: `docs/specs/design-agent-discovery.md`

## Slice 1: Context-Gatherer Detects UI Signals

Wire detection into the existing context-gatherer so it flags UI involvement and design system presence.

- [x] Context-gatherer scans for UI signals: frontend frameworks (React, Vue, Svelte, Angular, etc.), Tailwind config, CSS variables/custom properties, component libraries (shadcn, MUI, Chakra, etc.), design tokens, template/view files
- [x] Context-gatherer output includes a "Design System" subsection with two flags: "UI-involved: yes/no" and "Has design system: yes/no"
- [x] When UI signals are found, the Design System subsection lists what was detected (e.g., "Tailwind config at tailwind.config.ts, shadcn components in src/components/ui/")
- [x] When no UI signals are found, the subsection says "No UI signals detected" and both flags are "no"
- [x] Detection does not break the existing output format -- all current subsections remain unchanged

## Slice 2: Orchestrator Routes to Design Agent

Update `commands/bee.md` to trigger the design agent when the context-gatherer flags UI involvement.

- [x] Orchestrator reads the "UI-involved" flag from context-gatherer output
- [x] When "UI-involved: yes", orchestrator triggers the design agent after context-gathering (parallel to discovery when both are needed)
- [x] When "UI-involved: no", the design agent is skipped entirely
- [x] Design agent triggers for any task size (TRIVIAL, SMALL, FEATURE, EPIC) when the flag is set
- [x] Orchestrator passes context-gatherer output (including the Design System subsection) to the design agent

## Slice 3: Design Agent and Design Fundamentals Skill

Create the design agent and its companion skill file. The agent reads context-gatherer findings for existing design systems and produces a design brief.

- [x] `agents/design-agent.md` follows the established agent format: YAML frontmatter (name, description, tools, model), role statement, skills section, inputs, numbered steps, output format, anti-patterns
- [x] `skills/design-fundamentals/SKILL.md` contains reusable design knowledge: accessibility rules (4.5:1 contrast ratio, 44x44px touch targets), spacing principles, typography hierarchy, responsive breakpoints
- [x] The design agent references the design-fundamentals skill for principles
- [x] The agent reads context-gatherer output and extracts: color palette, typography, spacing scale, component patterns, accessibility constraints from the detected design system
- [x] The agent produces a design brief documenting what exists -- it never suggests extensions or alternatives to the detected system
- [x] Brief detail scales naturally with the design system's complexity, not with task size
- [x] The design brief follows this structure:
  - **Color Palette**: detected colors with names/variables (e.g., `--color-primary: #3B82F6`, Tailwind `primary-500`)
  - **Typography**: font families, size scale, weight usage (e.g., "Inter for body, font-semibold for headings")
  - **Spacing**: scale system (e.g., Tailwind default 4px base, or custom spacing tokens)
  - **Component Patterns**: detected UI library and conventions (e.g., "shadcn Button, Card, Dialog — uses `cn()` utility for class merging")
  - **Layout**: grid/flex patterns, container widths, responsive breakpoints in use
  - **Accessibility Constraints**: contrast ratios found, focus styles, ARIA patterns detected
  - **Design Tokens**: if the project uses a token system, document the token structure
- [x] The brief saves to `.claude/DESIGN.md` in the target project (not in Bee's docs/specs/)
- [x] The brief is created on the first UI task and updated on subsequent runs
- [x] After saving the brief, the agent automatically adds a reference to `.claude/DESIGN.md` in the project's CLAUDE.md (a "Design System" section pointing to the file)

## Slice 4: Spec-Builder Consumes the Design Brief

Update the spec-builder to read the design brief and use it for design-aware acceptance criteria.

- [x] Spec-builder checks for `.claude/DESIGN.md` in the target project when handling a UI-involved task
- [x] When the brief exists, the spec-builder reads it as additional context (same consumption pattern as the discovery doc -- pre-existing context that shapes ACs)
- [x] The spec-builder uses the brief to write design-aware ACs (e.g., "uses the existing primary color for CTA buttons" instead of leaving visual decisions to the executor)
- [x] When no brief exists, the spec-builder proceeds as it does today -- no degradation
- [x] After the design agent produces the brief, the collaboration loop runs: the brief gets a `[ ] Reviewed` gate, the developer can add `@bee` annotations, and the agent processes them before proceeding to spec-building

## Out of Scope

- Greenfield projects (no existing design system) -- that is Phase 2
- Generating CSS, component code, or mockups -- the agent produces markdown only
- Runtime design system enforcement or linting
- Extending or modifying detected design systems
- Building the ui-ux-pro-max-skill search engine -- we adapt knowledge into pure markdown
- Image/logo analysis for color extraction -- in scope for the agent's capabilities via Claude's multimodal, but the interview flow for greenfield is Phase 2

## Technical Context

- **Patterns to follow**: Existing agent format (see `agents/discovery.md`, `agents/context-gatherer.md` for structure). Existing skill format (see `skills/clean-code/SKILL.md`). All files are markdown with YAML frontmatter.
- **Files to modify**: `agents/context-gatherer.md` (add Design System subsection), `commands/bee.md` (add routing logic), `agents/spec-builder.md` (add brief consumption)
- **Files to create**: `agents/design-agent.md`, `skills/design-fundamentals/SKILL.md`
- **Key integration**: The design brief is project-level context (`.claude/DESIGN.md` in the target project), not feature-level. It persists across features and sessions, and works outside Bee too.
- **Risk level**: LOW

---

[x] Reviewed
