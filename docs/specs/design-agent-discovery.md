# Discovery: Design Agent

## Why

AI-generated UI is recognizably AI-generated. When Bee handles a UI task today, there is no design awareness anywhere in the pipeline -- no detection of existing design systems, no interview about visual preferences, no coherent design direction. The result is generic, inconsistent UI that misses the human intentionality that makes good design feel deliberate. The developer wants Bee to produce UI that looks like a human designed it: intentional color choices rooted in brand or preference, deliberate typography, consistent spacing -- not AI defaults.

## Who

Developers using Bee for any task that involves UI. This includes:
- Teams with existing design systems (Tailwind configs, CSS variables, component libraries) who want Bee to respect what they already have
- Solo developers or greenfield projects who want a coherent visual direction without hiring a designer or using a separate design tool

## Success Criteria

- When a UI task goes through Bee on a project with an existing design system, the design brief constrains all downstream work to that system -- no invented colors, no off-system components
- When a UI task goes through Bee on a greenfield project, the developer gets a deliberate design direction (colors, typography, spacing) based on their input (brand colors, logo, preferences) rather than AI defaults
- The spec-builder uses the design brief to write UI-aware acceptance criteria, and the resulting UI does not look "AI-generated"

## Problem Statement

Bee's pipeline has zero design awareness. When a developer asks for a UI feature, the spec-builder writes functional ACs ("user can see a list of orders") but has no basis for visual ACs -- what colors, what typography, what spacing, what component patterns. The executor then makes arbitrary visual choices that look generic and inconsistent. We need a design agent that sits in the pipeline alongside discovery, detects or establishes the project's visual language, and produces a design brief that gives downstream agents (spec-builder, executor) concrete design constraints. The brief should capture human-like design decisions so the output feels intentional, not generated.

## Hypotheses
<!-- @bee resolved: Split H1/H6 cleanly. H6 now defines the detection signals (what). H1 now defines the orchestrator routing (what happens after). No overlap. -->
- H1: When the context-gatherer flags "UI-involved", the orchestrator triggers the design agent. When the flag is absent, the design agent is skipped entirely — keeping prompts short for backend/infra work. The orchestrator routes based on this flag regardless of task size
- H7: The design agent should apply to ANY task size with UI involvement (TRIVIAL UI fix, SMALL UI tweak, FEATURE, EPIC) — not just FEATURE/EPIC. For TRIVIAL/SMALL, the agent produces a lightweight brief (just the detected palette + key constraints). For FEATURE/EPIC, it produces the full brief with interview
- H2: When an existing design system is detected (Tailwind config, CSS variables, component library), the design brief should document what exists and constrain to it, never suggest extensions or alternatives
- H3: For greenfield projects, the developer interview should offer concrete starting points (upload logo for color extraction, pick an industry/mood, choose from curated palettes) rather than open-ended "what colors do you want?"
- H4: The design brief is consumed by spec-builder the same way the discovery doc is -- as pre-existing context that shapes ACs -- not as a separate input format requiring spec-builder restructuring
- H5: Reusable design knowledge (accessibility rules, spacing scales, typography principles, color contrast ratios) belongs in a skill file (`skills/design-fundamentals/SKILL.md`), while detection and interview logic belongs in the agent (`agents/design-agent.md`)
- H6: The context-gatherer detects UI signals: frontend frameworks (React, Vue, Svelte, etc.), Tailwind config, CSS variables/custom properties, component libraries (shadcn, MUI, etc.), design tokens, template/view files. It flags "UI-involved: yes/no" and optionally "has design system: yes/no" in its output

## Out of Scope

- The design agent does not generate CSS, component code, or mockups -- it produces a markdown design brief only
- Logo and image analysis uses Claude Code's native multimodal capability (developer pastes image via ctrl+v). The design agent can extract colors, mood, and style direction from uploaded logos or reference screenshots — no external tools needed
- No runtime design system enforcement -- the brief is advisory context, not a linter or validator
- The design agent only triggers when the context-gatherer flags UI involvement -- non-UI tasks are unaffected regardless of size
- No extension or modification of detected design systems -- when one exists, the agent documents it and constrains to it
- Not building the ui-ux-pro-max-skill Python/CSV search engine -- we adapt its knowledge into pure markdown

## Milestone Map

### Phase 1: Design agent produces a brief for projects with existing design systems

- The context-gatherer detects UI signals (Tailwind config, CSS variables, component library, design tokens) and includes a "Design System" subsection in its output
- The orchestrator recognizes UI-involved tasks and triggers the design agent between context-gathering and spec-building (parallel to discovery when both are needed)
- The design agent reads the context-gatherer's design system findings and produces a design brief documenting: detected color palette, typography, spacing scale, component patterns, and accessibility constraints
- The spec-builder reads the design brief as additional context and uses it to write design-aware ACs (e.g., "uses the existing primary color for CTA buttons" rather than leaving visual decisions to the executor)
- A `skills/design-fundamentals/SKILL.md` skill file contains reusable design knowledge: accessibility rules (4.5:1 contrast, 44x44px touch targets), spacing principles, typography hierarchy, responsive breakpoints

### Phase 2: Design agent interviews developers for greenfield projects

- When no existing design system is detected, the design agent interviews the developer about visual preferences: brand colors, mood/style direction, industry context, reference sites
- The agent proposes a cohesive design direction (color palette, font pairing, spacing scale, component style) based on the developer's input and the design-fundamentals skill
- The design brief for greenfield includes the proposed palette, typography, spacing, and a "design personality" summary that downstream agents can reference
- The brief includes a quality checklist (adapted from ui-ux-pro-max-skill): color contrast passes WCAG AA, touch targets meet minimum size, transitions are in the 150-300ms range, responsive breakpoints are defined

## Revised Assessment

Size: FEATURE -- unchanged. Two phases, but each is a focused addition to the existing pipeline. Phase 1 is detection + documentation (mostly wiring). Phase 2 adds the interview flow. Both are well-scoped within FEATURE territory.
Greenfield: no -- this is brownfield, extending an existing agent/skill framework with established conventions.


[x] Reviewed

