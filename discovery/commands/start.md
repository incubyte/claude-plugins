---
description: Start an end-to-end product discovery flow that produces a structured PRD. Runs ten guided phases — context, scope, competition with kill gate, user journeys, wireframes, mockups, epics, technical overview, metrics framework, and GTM — assembling everything into a single PRD.md at the end. Resumable across sessions via discovery-state.md.
argument-hint: <product idea or "" to be prompted>
allowed-tools: ["Read", "Write", "Edit", "Skill", "AskUserQuestion", "WebSearch", "WebFetch"]
---

# /discovery:start

Run the product-discovery skill to take a raw product idea through ten guided phases and produce a fully-structured PRD.

## Behavior

1. **Load the `product-discovery` skill** using the Skill tool. The skill encodes the methodology and runs the interview phase by phase.
2. **Check for existing state.** If `discovery-state.md` exists in the project root, the skill offers to resume from the last completed phase. If not, it starts at Phase 0.
3. **Pass the user's product idea** (from the command argument, if provided) into Phase 1. If no argument, the skill prompts for it.
4. **Honor the seven core principles** documented in the skill, especially: kill gate at end of Phase 2, assumptions inventory at end of Phase 1, push back on vague metrics, reconcile timeline vs. scope before delivery.

## Natural-language alternative

This command is equivalent to saying any of:

- *"start product discovery for [idea]"*
- *"build a PRD from scratch for [idea]"*
- *"PM this for me — [idea]"*
- *"validate this idea: [idea]"*

The skill's description triggers on those phrases automatically. The `/discovery:start` command provides a discoverable entry point that matches the convention used by other Incubyte plugins (`/bee:sdd`, `/learn:start`).

## Output

- **`PRD.md`** — the deliverable, written to the project root after Phase 10 completes.
- **`discovery-state.md`** — internal state file tracking phase progress and answers. The user can edit it directly between sessions; the skill reads it on resume.

## Revision

After the PRD is delivered, the user can revise sections by saying *"revise the [section name]"*. The skill enters revision mode and edits both files in lockstep.

## Notes

- The flow is deliberately long — typically 1-3 hours of focused work for a real product. Resumability is essential for engagements that span multiple sessions.
- The skill pushes back on vague success metrics, refuses to write PRDs for ideas that should be killed, and forces precise user goals and non-goals. This friction is deliberate.
- See the discovery plugin's README for the full phase reference and what to expect at each checkpoint.
