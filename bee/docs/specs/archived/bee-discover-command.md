# Spec: /bee:discover Command

## Overview

A standalone `/bee:discover` command with a PM persona that interviews users (developers or clients) and produces a client-shareable PRD. The same agent serves both standalone invocation and internal `/bee:build` delegation, replacing the current discovery agent with a richer format and warmer persona.

## Acceptance Criteria

### Command Definition

- [ ] A command file exists at `commands/discover.md` with YAML frontmatter (`description` field) matching the convention used by `commands/build.md`
- [ ] Invoking `/bee:discover` starts with a warm, professional greeting and asks the user what they are working on
- [ ] The command works without any arguments -- users paste context inline during the conversation

### Agent: PM Persona and Interview Flow

- [ ] The enhanced agent file at `agents/discovery.md` replaces the current content with the PM persona, richer PRD format, and dual-mode interview flow
- [ ] The persona is warm and professional -- no developer jargon, no internal terminology (suitable for clients using Claude Desktop directly)
- [ ] When the user provides a transcript or raw notes upfront, the agent synthesizes them into a draft PRD and asks targeted follow-up questions only for gaps -- it does not re-ask what is already covered in the provided material
- [ ] When the user provides no transcript, the agent conducts a deep interview one question at a time using AskUserQuestion until it has enough to write the PRD
- [ ] The agent asks about motivation, users, success criteria, scope, and constraints -- not about tech stack, architecture, or implementation details

### PRD Output

- [ ] The agent produces a PRD saved to `docs/specs/[feature-name]-discovery.md` with these sections: Why, Who, Success Criteria, Problem Statement, Hypotheses, Out of Scope, Milestone Map, Revised Assessment
- [ ] The PRD is readable by someone who has never seen the project -- a client, a PM, or an LLM picking up the work cold
- [ ] Hypotheses are written as confirmable/rejectable statements that the spec-builder can use during its interview
- [ ] The milestone map uses vertical slices ordered outside-in with a walking skeleton as phase one
- [ ] The agent can revise the triage size assessment (e.g., FEATURE to EPIC) based on what it learns during the interview

### Session Resume

- [ ] The agent reads `.claude/bee-state.local.md` on startup and offers to resume an in-progress discovery session if one exists
- [ ] The agent updates `.claude/bee-state.local.md` after producing the PRD (adds discovery doc path, sets phase to "discovery complete")
- [ ] Standalone and `/bee:build` invocations use the same state file

### Error and Edge Cases

- [ ] When the user provides contradictory information (e.g., two conflicting scope statements), the agent surfaces the contradiction and asks the user to resolve it rather than guessing
- [ ] When the user wants to stop mid-interview, the agent saves progress to the state file so the session can resume later
- [ ] When the user provides extremely vague input ("build an app"), the agent asks grounding questions before attempting any synthesis

### Integration with /bee:build

- [ ] The orchestrator in `commands/build.md` delegates to the same enhanced discovery agent -- no separate internal-mode agent or lighter format
- [ ] Context from triage and context-gatherer (when available via `/bee:build`) flows into the discover interview as enrichment
- [ ] The collaboration loop applies after the PRD is produced (appends `[ ] Reviewed` checkbox, supports `@bee` annotations)
- [ ] `CLAUDE.md` workflow phases list references the updated discovery agent and mentions `/bee:discover` as a standalone entry point

## PRD Output Format

```markdown
# Discovery: [Feature Name]

## Why
[2-3 sentences: what triggered this, what is the pain, why now]

## Who
[Who are the users? Who benefits?]

## Success Criteria
- [High-level outcome 1]
- [High-level outcome 2]

## Problem Statement
[2-3 sentences grounded in the why]

## Hypotheses
- H1: [Confirmable/rejectable statement]
- H2: ...

## Out of Scope
- [What we are explicitly not building]

## Milestone Map

### Phase 1: [Name -- walking skeleton]
- [Capability 1]
- [Capability 2]

### Phase 2: [Name -- builds on Phase 1]
- [Capability 3]

## Revised Assessment
Size: [FEATURE/EPIC]
Greenfield: [yes/no]
```

## Out of Scope

- PDF/Docx export -- markdown only
- Integration with external tools (Jira, Linear, Notion)
- Multi-project tracking or a discovery dashboard
- Technical scoping (stack, architecture, deployment) -- that belongs to spec-builder and architecture-advisor
- Changes to TRIVIAL or SMALL workflows -- discover only applies to FEATURE and EPIC
- A separate "lite" format for internal `/bee:build` usage -- one format for all paths

## Technical Context

- **Patterns to follow**: Command files use markdown with YAML frontmatter (`description` field). Agent files use markdown with YAML frontmatter (`name`, `description`, `tools`, `model: inherit`). See `commands/build.md` and `agents/spec-builder.md` as references.
- **Files to create**: `commands/discover.md`
- **Files to modify**: `agents/discovery.md` (replace with enhanced PM persona + richer PRD format), `commands/build.md` (update discovery delegation to reference enhanced agent), `CLAUDE.md` (add `/bee:discover` as standalone entry point in workflow phases)
- **Key dependencies**: Collaboration loop skill (`skills/collaboration-loop/SKILL.md`), state file (`.claude/bee-state.local.md`), spec-builder agent (already accepts discovery doc path as input -- no changes needed)
- **Risk level**: LOW

- [x] Reviewed
