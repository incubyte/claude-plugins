---
name: collaboration-loop
description: Inline review loop for discovery docs, specs, and TDD plans. Defines @bee annotation processing, comment card format, and the [ ] Reviewed gate.
---

# Collaboration Loop

After every document-producing agent (discovery, spec-builder, TDD planners) completes and returns to the orchestrator, the developer gets a chance to review and refine the document before Bee moves to the next step.

This is additive — the agent's own AskUserQuestion confirmation flow is unchanged. The collaboration loop is an additional gate in the orchestrator.

---

## The Reviewed Gate

Every document produced by an agent gets a `[ ] Reviewed` checkbox appended at the very end:

```html
<div align="center">

- [ ] Reviewed

</div>
```

This checkbox is the **only gate** for proceeding to the next step. Bee re-reads the file and checks for `[x] Reviewed`. Until it's marked, Bee stays in the loop.

---

## @bee Annotations

The developer can add `@bee` comments anywhere in the document to request changes:

```markdown
@bee This acceptance criterion is too vague, can we make it more specific?
```

When Bee finds an `@bee` annotation, it:
1. Reads the comment to understand what the developer wants
2. Makes the requested change to the document
3. Replaces the `@bee` annotation with a comment card

---

## Comment Card Format

```markdown
<!-- -------- bee-comment -------- -->
> **@developer**: [original comment]
> **@bee**: [what Bee changed and why]
> - [ ] mark as resolved
<!-- -------- /bee-comment -------- -->
```

The HTML comment delimiters (`<!-- -->`) make the card boundaries machine-readable. The blockquote formatting makes it visually distinct. The `[ ] mark as resolved` checkbox is for the developer's tracking — it does NOT affect the gate.

---

## What Blocks Progression

Only `[x] Reviewed` blocks progression. These do NOT block:
- Unresolved comment cards (`[ ] mark as resolved` still unchecked)
- Open `@bee` annotations that haven't been processed yet (Bee processes them first, then re-checks `[x] Reviewed`)

---

## The Loop

1. Agent writes document and confirms via AskUserQuestion (existing flow)
2. Agent returns to orchestrator
3. Orchestrator appends the `[ ] Reviewed` checkbox to the document
4. Orchestrator shows the file path: "Here's the doc: `[path]`. Take a look in your editor — add `@bee` comments on anything you want changed, and mark `[x] Reviewed` when you're ready to move on."
5. Developer messages Bee (any message triggers a re-read of the file)
6. Bee re-reads the file:
   - **`@bee` annotations found** → process each one, make changes, replace with comment cards, write updated file, tell the developer what changed, wait for next message
   - **`[x] Reviewed` found** → proceed to the next workflow step
   - **Neither** → remind: "The document is at `[path]`. Add `@bee` comments or mark `[x] Reviewed` to continue."

---

## Applies To

This loop applies after these agents return:
- Discovery agent → `docs/specs/[feature]-discovery.md`
- Spec-builder → `docs/specs/[feature].md` or `docs/specs/[feature]-phase-N.md`
- TDD planner (all 5 variants) → `docs/specs/[feature]-slice-N-tdd-plan.md`

It does NOT apply to: quick-fix, context-gatherer, tidy, architecture-advisor, verifier, reviewer.
