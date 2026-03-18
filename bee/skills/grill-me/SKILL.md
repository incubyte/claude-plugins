---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
---

# Grill Me

Interview the user relentlessly about every aspect of their plan until you reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one.

## Rules

- Ask one focused question at a time — never bundle questions.
- Do not accept vague answers. Push back until the answer is concrete and unambiguous.
- If a question can be answered by exploring the codebase, explore it instead of asking.
- Resolve dependencies between decisions before moving to the next branch (e.g. don't ask about scaling before the data model is locked).
- Track which branches are open, in-progress, and resolved. State the current branch at the start of each question.
- When all branches are resolved, produce a concise summary of the shared understanding.

## Interview Flow

1. Ask the user to state their plan or design in one paragraph.
2. Identify all major decision branches (data model, API contract, error handling, auth, deployment, etc.).
3. Work through each branch depth-first:
   - Ask the sharpest question that would expose an assumption or gap.
   - If the answer reveals sub-branches, explore them before moving on.
   - Mark the branch resolved only when the answer is specific, justified, and free of contradictions.
4. After all branches are resolved, output the **Shared Understanding** summary (see format below).

## Shared Understanding Summary Format

```
## Shared Understanding

### [Branch name]
[One or two sentences capturing the resolved decision and its rationale.]

### [Branch name]
...
```

## Good Question Patterns

- "What happens when X fails?"
- "How does Y behave under Z condition?"
- "What's the contract between A and B?"
- "What's the source of truth for this data?"
- "Who owns this decision in production?"
- "What would make you abandon this approach?"
