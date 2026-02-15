# Spec: Collaboration Loop

## Overview
Add an inline review loop after every document-producing agent completes. The developer can annotate documents with `@bee` comments, get Bee's responses as comment cards, and mark `[x] Reviewed` to proceed. This is additive -- existing agent confirmation flows are unchanged.

## Acceptance Criteria

- [ ] After a document-producing agent returns, the orchestrator appends a centered `[ ] Reviewed` checkbox to the end of the document
- [ ] Orchestrator shows the file path and invites the developer to review the document in their editor
- [ ] When the developer adds `@bee [comment]` anywhere in the document, Bee reads it, makes the requested change, and replaces the annotation with a comment card
- [ ] Comment card format uses HTML comment delimiters, quotes the original developer comment, includes Bee's response, and has a `[ ] mark as resolved` checkbox
- [ ] The loop continues re-reading the file until `[x] Reviewed` is found (the only gate for proceeding)
- [ ] Unresolved comment cards do not block proceeding -- only `[x] Reviewed` matters
- [ ] A shared skill file defines the annotation format, comment card format, and reviewed-gate behavior so all 7 document-producing agent paths use identical logic
- [ ] The 7 existing agent files are not modified -- the loop lives entirely in the orchestrator

## Comment Card Format

```
<!-- -------- bee-comment -------- -->
> **@developer**: [original comment]
> **@bee**: [what Bee changed and why]
> - [ ] mark as resolved
<!-- -------- /bee-comment -------- -->
```

## Reviewed Checkbox Format

```html
<div align="center">

- [ ] Reviewed

</div>
```

## Out of Scope
- Changing how agents confirm documents internally (existing AskUserQuestion flow stays)
- Auto-resolving comment cards
- Notifications or reminders if the developer walks away mid-loop
- Any changes to non-document-producing agents (quick-fix, context-gatherer, tidy, verifier, reviewer)

## Technical Context
- Patterns to follow: orchestrator logic in `commands/build.md`, shared skills in `skills/[name]/SKILL.md`
- Files to create: `skills/collaboration-loop/SKILL.md`
- Files to modify: `commands/build.md`, `CLAUDE.md`
- Key integration: the loop inserts at step 3.5 in the orchestrator, between agent return and next-step routing
- Risk level: LOW
