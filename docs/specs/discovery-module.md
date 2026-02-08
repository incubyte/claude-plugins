# Spec: Discovery Module

## Overview

A discovery agent that sits between context gathering and spec building, producing a lightweight discovery document (milestone map + problem statement with hypotheses) when the requirement is vague or the scope is large. Helps the spec-builder ask better questions and prevents the AI from guessing at ambiguous requirements.

## Acceptance Criteria

- [ ] Discovery agent file exists at `agents/discovery.md` with YAML frontmatter matching existing agent conventions (name, description, tools, model: inherit)
- [ ] Discovery agent receives triage assessment, context-gatherer output, and the developer's task description as inputs
- [ ] Discovery agent produces a discovery document saved to `docs/specs/[feature-name]-discovery.md` with two sections: milestone map (vertical slices) and problem statement with hypotheses
- [ ] Milestone map uses vertical slices ordered outside-in (user-verifiable features first), with a walking skeleton as phase one when context-gatherer output indicates a greenfield project
- [ ] Hypotheses are written as confirmable/rejectable prompts that the spec-builder can address during its interview
- [ ] Orchestrator (`commands/bee.md`) evaluates two signals after context gathering -- requirement clarity and scope size -- and recommends discovery when either signal indicates high uncertainty
- [ ] Inline discovery Q&A (the "DISCOVERY — CLARIFY BEFORE DOING" section in `bee.md`) remains as the lightweight path; the discovery agent is recommended only when deeper exploration is warranted
- [ ] Discovery can revise the triage size assessment (e.g., FEATURE to EPIC or vice versa) and the state file reflects the updated size
- [ ] State file (`docs/specs/.bee-state.md`) tracks a "discovery" phase between "context gathered" and "spec confirmed", including the path to the discovery document
- [ ] Spec-builder receives the discovery document path as an additional input alongside existing inputs (task description, triage, context summary, inline Q&A answers)

## Discovery Document Format

```markdown
# Discovery: [Feature Name]

## Problem Statement
[What problem are we solving? 2-3 sentences max.]

## Hypotheses
- H1: [Statement to confirm or reject during spec building]
- H2: ...

## Milestone Map
### Phase 1: [Walking skeleton / simplest end-to-end path]
- [Capability 1]
- [Capability 2]

### Phase 2: [Next increment]
- [Capability 3]
- [Capability 4]

## Revised Assessment
Size: [unchanged or revised from triage]
Greenfield: [yes/no, detected from context-gatherer]
```

## Out of Scope

- Discovery does not replace the spec-builder interview -- it feeds into it
- No automated hypothesis validation (prototyping, data analysis) -- hypotheses are prompts for the developer
- No changes to TRIVIAL or SMALL workflows -- discovery only applies to FEATURE and EPIC
- No MCP server changes -- state tracking uses the existing `.bee-state.md` markdown file
- Not updating `docs/bee-v2-architecture.md` -- that is a reference doc, not a live config (can be updated separately)

## Technical Context

- **Patterns to follow**: Agent files use markdown with YAML frontmatter (`agents/spec-builder.md` is the closest reference). Orchestrator routing follows the existing pattern in `commands/bee.md` lines 160-200 (FEATURE/EPIC path).
- **Key dependencies**: Context-gatherer output (provides greenfield detection, scope signals). Spec-builder inputs (must accept discovery document path). State file format (needs new "discovery" phase marker).
- **Files to create**: `agents/discovery.md`
- **Files to modify**: `commands/bee.md` (trigger logic + routing), `CLAUDE.md` (add discovery to workflow phases list), `agents/spec-builder.md` (accept discovery doc as input)
- **Risk level**: LOW
