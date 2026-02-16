---
name: collaboration-loop
description: "This skill should be used when processing @bee annotations in documents or managing [ ] Reviewed gates. Contains the exact comment card format and review loop rules. Load before handling any @bee comment."
---

# Collaboration Loop

After every document-producing agent (discovery, spec-builder, TDD planners) completes and returns to the orchestrator, the developer gets a chance to review and refine the document before Bee moves to the next step.

This is additive — the agent's own AskUserQuestion confirmation flow is unchanged. The collaboration loop is an additional gate in the orchestrator.

---

## The Reviewed Gate

Every document produced by an agent gets a `[ ] Reviewed` checkbox appended at the very end of the file, on its own line:

```markdown
[ ] Reviewed
```

The developer marks it `[x] Reviewed` when satisfied. This checkbox is the **only gate** for proceeding to the next step. Bee re-reads the file and checks for `[x] Reviewed`. Until it's marked, Bee stays in the loop.

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

### Concrete Example

**Before** (developer writes):
```markdown
## Success Criteria
- App loads in under 2 seconds
@bee this needs to specify what network conditions — 2s on 3G is very different from 2s on fiber
- User can log in with email/password
```

**After** (Bee processes the annotation):
```markdown
## Success Criteria
- App loads in under 2 seconds on a 4G connection (simulated with Chrome DevTools "Fast 3G" throttle)
<!-- -------- bee-comment -------- -->
> **@developer**: this needs to specify what network conditions — 2s on 3G is very different from 2s on fiber
> **@bee**: Added "on a 4G connection" with a specific measurement method (Chrome DevTools throttle profile) so the criterion is testable.
> - [ ] mark as resolved
<!-- -------- /bee-comment -------- -->
- User can log in with email/password
```

**This format must be used exactly as shown.** Every `@bee` annotation becomes a comment card with:
1. Opening delimiter: `<!-- -------- bee-comment -------- -->`
2. Developer's original comment as a blockquote with `**@developer**:` prefix
3. Bee's response as a blockquote with `**@bee**:` prefix explaining what changed
4. A `- [ ] mark as resolved` checkbox inside the blockquote
5. Closing delimiter: `<!-- -------- /bee-comment -------- -->`

Do not vary this structure. Consistency across all documents (discovery, specs, TDD plans) is required.

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
4. Orchestrator shows the file path: "I've saved the doc to `[path]`. You can review it in your editor — if anything needs changing, add `@bee` followed by your comment on the line you want to change (e.g., `@bee this AC is too vague`). I'll read your annotations, make the changes, and leave a comment card so you can see what I did. When you're happy with the doc, mark `[x] Reviewed` at the bottom to move on."
5. Developer messages Bee. Tell them: "Type `check` when you're ready for me to re-read, or just keep chatting." Any message triggers a re-read of the file.
6. Bee re-reads the file:
   - **`@bee` annotations found** → process each one, make changes, replace with comment cards, write updated file, tell the developer what changed, wait for next message
   - **`[x] Reviewed` found** → proceed to the next workflow step
   - **Neither** → if the developer's message is about something else (a question, discussion, unrelated topic), respond to it normally, then gently remind: "Whenever you're ready, the doc is at `[path]` — mark `[x] Reviewed` to continue." Don't block the conversation on the review gate.

---

## Applies To

This loop applies after these agents return:
- Discovery agent → `docs/specs/[feature]-discovery.md`
- Spec-builder → `docs/specs/[feature].md` or `docs/specs/[feature]-phase-N.md`
- TDD planner (all 5 variants) → `docs/specs/[feature]-slice-N-tdd-plan.md`

It does NOT apply to: quick-fix, context-gatherer, tidy, architecture-advisor, verifier, reviewer.
