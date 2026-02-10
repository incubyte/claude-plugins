# Discovery: /bee:discover Command

## Why

Every new client engagement starts with scattered requirements — ad-hoc notes, call transcripts, half-remembered conversations. There's no standard intake tool. The team wants a PM persona built into the Bee workflow that interviews stakeholders (or synthesizes from transcripts), produces a structured PRD, and outputs something polished enough to share directly with clients for review and sign-off.

The existing discovery agent inside `/bee:bee` already does requirement exploration, but it's developer-focused and embedded in the build workflow. The team wants to promote this to a first-class, standalone command that works both independently and as part of `/bee:bee`.

## Who

- **Primary user**: Developers/consultants running client intake sessions
- **Primary user**: Clients themselves, self-service via Claude Desktop
- **Internal consumer**: `/bee:bee` workflow, which delegates to the same discover logic

## Success Criteria

- Every new client engagement can start with `/bee:discover` as the standard intake tool
- The PRD output is polished enough to share with clients without manual editing
- The interview flow adapts: deep questioning when no transcript is provided, synthesis mode when a transcript is pasted in
- Sessions can be resumed across conversations via state tracking
- Clients can run `/bee:discover` themselves and produce a useful PRD without developer hand-holding

## Problem Statement

Client requirements gathering is ad-hoc — notes scattered across calls, transcripts, and memory. There's no structured process that produces a client-shareable artifact. We need a PM persona that can either interview stakeholders interactively or synthesize requirements from raw transcripts, then produce a professional PRD that serves as the single source of truth for the engagement.

## Hypotheses

- H1: Users will want to paste raw transcripts upfront and have the PM persona synthesize rather than re-ask everything
- H2: The interview should ask one question at a time (not batched) to keep it conversational and thorough
- H3: The client-shareable PRD needs sections beyond the internal format — Executive Summary, Assumptions & Risks, Open Questions — and should avoid internal jargon
- H4: When invoked from `/bee:bee`, the same agent should run the same deep interview — no "lighter" version
- H5: State tracking via `.bee-state.md` is needed for both standalone and `/bee:bee` invocations so sessions can resume
- H6: Since clients may use this directly, the persona must be warm and professional — not developer-jargon-heavy

## Out of Scope

- Docx/PDF export (markdown first — revisit if pandoc or similar is available)
- Integration with external tools (Jira, Linear, Notion)
- Multi-project tracking / discovery dashboard
- Technical scoping (stack, architecture, deployment — that's spec-builder and architecture-advisor territory)

## Milestone Map

### Phase 1: /bee:discover command with PM persona + /bee:bee integration

- User can invoke `/bee:discover` with initial context (description, transcript, or both)
- PM persona interviews the user one question at a time until satisfied
- Produces a structured, client-shareable PRD (Executive Summary, Problem, Users, Success Criteria, Scope, Assumptions & Risks, Milestones, Open Questions)
- Collaboration loop applies — user can annotate with `@bee` and mark `[x] Reviewed`
- State tracked in `.bee-state.md` for session resume
- `/bee:bee` delegates to the same enhanced discover agent
- Existing discovery evaluation logic in `bee.md` updated to use the new agent
- Context from triage and context-gatherer flows into the discover interview as enrichment

## Revised Assessment

Size: FEATURE — single phase, collapsed from two
Greenfield: no — existing discovery agent and command patterns to build on

- [x] Reviewed
