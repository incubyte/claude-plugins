# Bee: Slice 0 — Project Skeleton

## What This Slice Delivers

A working project structure that you can drop into any repo. After this slice:
- `CLAUDE.md` exists with Bee's personality and navigation rules
- Agent definition files exist in `.claude/agents/` as placeholders
- Bee's orchestrator agent works as the entry point
- You can test it by saying `/bee` in Claude Code and getting the "Tell me what we're working on" experience

## What to Tell Claude Code

Copy this into Claude Code:

---

```
Read the attached architecture document at docs/bee-v2-architecture.md.

We are building Bee — an AI development workflow navigator plugin for Claude Code. 
We're starting with Slice 0: the project skeleton.

Here's what I need:

1. PROJECT STRUCTURE
   Create this folder structure:

   bee/
   ├── docs/
   │   ├── bee-v2-architecture.md    (I'll place this — it's our design doc)
   │   ├── specs/                    (empty — specs will go here)
   │   └── adrs/                     (empty — ADRs will go here)
   ├── .claude/
   │   ├── agents/
   │   │   ├── bee.md                (main orchestrator agent)
   │   │   ├── quick-fix.md          (placeholder — "Coming in Slice 1")  
   │   │   ├── context-gatherer.md   (placeholder)
   │   │   ├── tidy.md               (placeholder)
   │   │   ├── spec-builder.md       (placeholder)
   │   │   ├── architecture-advisor.md (placeholder)
   │   │   ├── tdd-planner-onion.md  (placeholder)
   │   │   ├── tdd-planner-mvc.md    (placeholder)
   │   │   ├── tdd-planner-simple.md (placeholder)
   │   │   ├── verifier.md           (placeholder)
   │   │   └── reviewer.md           (placeholder)
   │   └── settings.json             (agent configuration)
   ├── CLAUDE.md                     (Bee personality + project conventions)
   └── README.md

2. CLAUDE.md — THE BRAIN
   This is the most important file. It should contain:
   
   - Bee's identity: "You are Bee, a workflow navigator for AI-assisted development."
   - The GPS metaphor: developer is driver, Claude Code is car, Bee is GPS
   - Navigation rules: how to assess tasks (trivial/small/feature/epic)
   - Risk assessment: how to classify risk (low/moderate/high)
   - The core principle: navigator not enforcer, suggest don't block
   - AskUserQuestion rules: structured choices, 2-4 options, rationale, one question at a time
   - Teaching level config: default to "subtle"
   - Personality: warm, direct, collaborative, uses "we"
   - The full workflow overview so Bee knows what phases exist
   - Reference to agent files: "For [phase], use the /[agent-name] agent"
   
   Pull the specific wording from the orchestrator prompt in the architecture doc 
   (Section 3, "The Orchestrator"). Adapt it for CLAUDE.md format.

3. bee.md — THE ORCHESTRATOR AGENT  
   This is the main agent. When invoked via /bee, it should:
   
   a) Check for in-progress specs in docs/specs/ (session resume)
   b) If none, greet with "Tell me what we're working on"
   c) Listen to the developer's description
   d) Quick-scan the codebase (Glob, Grep) to understand scope
   e) Assess size (trivial/small/feature/epic) and risk (low/moderate/high)
   f) Present the workflow recommendation via AskUserQuestion
   g) For now, after triage, say "Triage complete. The next phases 
      (context gathering, spec building, etc.) are coming in future slices. 
      For now, here's my assessment: [size], [risk], recommended workflow: [X]"
   
   Use the full orchestrator prompt from the architecture doc Section 3.
   Add a note at the end: "Note: Phases beyond triage are placeholders. 
   They will be implemented in subsequent slices."

4. PLACEHOLDER AGENTS
   For each agent file that isn't bee.md, create a minimal placeholder:
   
   ```markdown
   # [Agent Name]
   
   **Status:** Placeholder — coming in Slice [N]
   
   ## Purpose
   [One-line description from the architecture doc]
   
   ## Responsibilities  
   [Bullet list of responsibilities from the architecture doc]
   
   ## Implementation
   This agent will be fully implemented in Slice [N].
   For now, the orchestrator will note when this phase would be triggered.
   ```

5. README.md
   Brief readme explaining:
   - What Bee is (one paragraph)
   - How to use it: copy .claude/ and CLAUDE.md into your project
   - Current status: Slice 0 — orchestrator with triage only
   - What's coming: link to architecture doc

6. VERIFY
   After creating everything:
   - List the directory tree to confirm structure
   - Read back CLAUDE.md and bee.md to confirm they capture the full 
     orchestrator behavior from the architecture doc
   - Confirm all placeholder agents exist with correct slice numbers
```

---

## Slice Numbers for Placeholders

Use these when creating placeholder agents:

| Agent File | Slice | Purpose (from architecture) |
|---|---|---|
| quick-fix.md | Slice 1 | Handles trivial fixes — typos, config, one-liners. Makes fix, runs tests, done. |
| context-gatherer.md | Slice 2 | Reads codebase to understand patterns, conventions, test setup. Flags tidy opportunities and cross-cutting concerns. |
| tidy.md | Slice 2 | Optional cleanup before building. Separate commit. Fix broken tests, remove dead code, extract long functions. |
| spec-builder.md | Slice 3 | Interviews developer via AskUserQuestion, produces spec with acceptance criteria and checkboxes. Adaptive depth based on size and risk. |
| architecture-advisor.md | Slice 3 | Presents architecture options when warranted. YAGNI check. Writes ADRs for significant decisions. |
| tdd-planner-simple.md | Slice 4 | Generates simple test-first plan: test → implement → verify. For straightforward features. |
| tdd-planner-onion.md | Slice 5 | Generates outside-in double-loop TDD plan for onion/hexagonal architecture. |
| tdd-planner-mvc.md | Slice 5 | Generates MVC TDD plan: route → controller → service → model. |
| verifier.md | Slice 6 | Post-slice verification: tests pass, criteria met, patterns followed. Risk-aware checks. |
| reviewer.md | Slice 6 | Post-feature review: spec coverage, code quality, commit story, risk-aware ship recommendation. |

## What "Done" Looks Like for Slice 0

- [ ] Project structure exists with all folders
- [ ] CLAUDE.md captures Bee's full personality, navigation rules, and workflow overview
- [ ] bee.md agent works: invoking /bee starts the "tell me what we're working on" flow
- [ ] bee.md does triage: assesses size + risk and presents workflow recommendation
- [ ] bee.md handles session resume: checks docs/specs/ for in-progress work
- [ ] All 10 placeholder agent files exist with correct descriptions and slice numbers
- [ ] README.md explains what Bee is and how to use it
- [ ] Architecture doc is placed in docs/

## Pre-requisite

Before giving Claude Code the prompt above, place the `bee-v2-architecture.md` file 
in your project at `docs/bee-v2-architecture.md` so Claude Code can reference it 
while building.
