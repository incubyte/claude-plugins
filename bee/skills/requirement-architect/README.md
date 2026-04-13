# Requirement Architect Skill

## Overview

This skill helps rewrite software requirements to naturally lead to better code design and architecture. It detects common requirement "smells" that produce poor code structure and rewrites them to guide developers toward cleaner, more maintainable implementations.

## Files

- **SKILL.md** - Main skill definition with principles, smells, and rewrite strategy
- **references/examples.md** - Four detailed before/after examples showing requirement rewrites in action

## Key Capabilities

### 7 Requirement Smells Detected

1. **Conditional Chains** - "If X then Y, else if Z..." → Type-based behavior
2. **Implementation Leaking** - Database/API references → Domain language
3. **God Requirement** - Multiple concerns mixed → Separate bounded contexts
4. **Missing Domain Language** - Generic terms → Precise domain concepts
5. **Temporal Coupling** - Fixed sequences → Independent triggers
6. **Ambiguous Boundaries** - Unclear module boundaries → Explicit contracts
7. **Implicit State Machine** - Scattered status changes → Explicit states/transitions

### Agentic Coding Support

The skill includes guidance for decomposing requirements into **parallel work streams** for multi-agent development:

- Identifies independent concerns that can be built simultaneously
- Defines clear boundaries and contracts between streams
- Specifies dependencies and integration points
- Structures acceptance criteria per stream

### Example Domains Covered

- E-Commerce (discount systems, pricing tiers)
- Notifications (event-driven, multi-channel)
- Workflows (state machines, approval flows)
- Access Control (RBAC, policies)

## Usage

Invoke this skill when:
- User shares requirements, user stories, specs, or PRDs
- Requirements contain conditional chains or implementation details
- Requirements mix multiple concerns without clear boundaries
- Planning parallel development work across multiple agents
- User asks to "review my requirements" or "improve this spec"

## Output Format

```markdown
## Requirement Review

### Original Requirement
[original text]

### Smells Detected
- [Smell name]: [explanation]

### Rewritten Requirement
[improved version with domain model]

### Architectural Impact
[how the rewrite improves code structure]

### Domain Model Suggested
[key entities/types/concepts]

### Parallel Work Streams (when applicable)
[independent development streams with boundaries and contracts]
```

## Integration with Bee Workflow

This skill is designed to be used:
- **Before spec-building** - Clean requirements before turning them into specs
- **During discovery** - Improve requirements as they emerge from stakeholder interviews
- **During architecture advising** - Ensure requirements don't constrain design choices

## Credits

Based on research by:
- Perry & Wolf (1992) - Architecture definition framework
- Boehm - Cost of requirements errors
- Domain-Driven Design principles (Evans)
- Open-Closed Principle (Meyer)
