# Spec: Design Agent Phase 2 -- Greenfield Interview Flow

## Overview

Add a greenfield path to the existing design agent. When the context-gatherer flags "UI-involved: yes" but "Has design system: no", the agent interviews the developer about visual preferences and proposes a cohesive design direction -- saving the result to `.claude/DESIGN.md` just like Phase 1.

Discovery doc: `docs/specs/design-agent-discovery.md`

## Acceptance Criteria

### Detection and Auto-Extraction

- [x] When "Has design system: no" but "UI-involved: yes", the design agent enters the greenfield interview flow instead of the existing-system extraction flow
- [x] Before interviewing, the agent scans for partial signals (package.json dependencies, any CSS files, favicon/logo files, README mentions of brand) and uses them to reduce the number of questions
- [x] The agent skips questions it can answer from auto-detected signals (e.g., if a CSS file already defines brand colors, don't ask about colors)

### Interview Flow

- [x] The interview is adaptive: 1 turn if most information is auto-detected, up to 10 turns for a truly blank-slate project
- [x] The agent offers concrete starting points for mood/style direction (e.g., "Clean & Minimal", "Bold & Vibrant", "Warm & Approachable") rather than open-ended "what style do you want?"
- [x] The agent asks about industry context and reference sites when mood/style alone is insufficient to propose a direction
- [x] The agent mentions "paste a logo if you have one" as an optional input -- if a logo is pasted, the agent extracts dominant colors and style cues via Claude's multimodal capability; if nothing is pasted, the interview continues without it
- [x] The agent asks about brand colors when none are auto-detected and no logo is provided

### Design Proposal

- [x] After gathering inputs, the agent proposes a cohesive design direction including: color palette (primary, secondary, accent, neutral, semantic colors), font pairing (heading + body), spacing scale, and component style direction
- [x] The proposal includes a "design personality" summary -- a 1-2 sentence description of the intended visual feel that downstream agents can reference (e.g., "Professional and clean with warm accent tones. Prioritizes readability and generous whitespace.")
- [x] The proposal is grounded in the design-fundamentals skill -- accessibility rules, typography principles, and spacing scales inform the choices
- [x] Color contrast between proposed text and background colors passes WCAG AA (4.5:1 normal text, 3:1 large text)

### Quality Checklist in Brief

- [x] The saved brief includes a quality checklist section: color contrast passes WCAG AA, touch targets meet 44x44px minimum, transitions are 150-300ms, responsive breakpoints are defined
- [x] The quality checklist values come from the design-fundamentals skill, not hardcoded in the agent

### Output and Integration

- [x] The greenfield brief saves to `.claude/DESIGN.md` -- same location as the existing-system brief from Phase 1
- [x] The brief format is compatible with the existing spec-builder consumption -- no spec-builder changes needed
- [x] The brief includes the `[ ] Reviewed` collaboration loop gate -- the developer can adjust values via `@bee` annotations before proceeding
- [x] If a `.claude/DESIGN.md` already exists from a previous greenfield interview, the agent reads it and offers to update rather than starting from scratch

### Error Cases

- [x] If the developer skips all interview questions (declines to answer), the agent produces a minimal brief using sensible defaults from the design-fundamentals skill and flags it as "default -- consider reviewing"
- [x] If the developer provides conflicting inputs (e.g., "bold and vibrant" mood but pastes a muted corporate logo), the agent acknowledges the tension and asks which direction to prioritize

## Out of Scope

- Generating CSS, component code, or mockups -- the agent produces a markdown design brief only
- Modifying the spec-builder -- Phase 1 already wired brief consumption
- Modifying the orchestrator or context-gatherer -- Phase 1 already wired routing and detection
- External tools for color extraction or palette generation -- Claude's native multimodal handles logo analysis
- Runtime enforcement of the design brief

## Technical Context

- **Patterns to follow**: The existing design agent at `agents/design-agent.md` -- Phase 2 adds a conditional branch for the greenfield path within the same agent file
- **Key skill dependency**: `skills/design-fundamentals/SKILL.md` provides accessibility rules, typography principles, spacing scales, and the visual quality checklist
- **Output location**: `.claude/DESIGN.md` in the target project (same as Phase 1)
- **Interview pattern**: AskUserQuestion with concrete options, same interaction style as the spec-builder interview
- **Files to modify**: `agents/design-agent.md` (add greenfield interview flow alongside the existing extraction flow)
- **Files NOT modified**: `commands/build.md`, `agents/context-gatherer.md`, `agents/spec-builder.md` -- all already wired in Phase 1
- **Risk level**: LOW

---

[x] Reviewed
