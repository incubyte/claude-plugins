---
description: Start a brainstorming session. Open-ended, collaborative idea generation for product, architecture, UX, or any problem space. Researches online, builds on your ideas, and helps narrow to the best path forward.
argument-hint: <problem or topic to brainstorm>
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash(git:*)", "Bash(mkdir:*)", "Bash(cat:*)", "AskUserQuestion", "Skill", "ToolSearch", "WebSearch", "WebFetch"]
---

**IMPORTANT — Deferred Tool Loading:** Before calling `AskUserQuestion`, `WebSearch`, or `WebFetch`, call `ToolSearch` with query `"select:AskUserQuestion,WebSearch,WebFetch"` to load them. Do this once at the start.

Load the `brainstorming` skill using the Skill tool before proceeding.

## On Startup

1. Load the brainstorming skill.
2. Load deferred tools via ToolSearch.
3. If `$ARGUMENTS` is provided, use it as the brainstorming topic.
4. If no arguments, greet and ask:
   "What should we brainstorm? Could be a product idea, an architecture question, a UX problem, or anything you want to think through."

## Running the Session

Follow the brainstorming skill's two-phase process:

### Phase 1: Diverge

1. **Research first.** Before generating ideas, use WebSearch to understand the problem space. Look for how others solve similar problems, emerging patterns, known pitfalls. Share findings with the user as brainstorming fuel.

2. **Explore the codebase** if relevant. Read existing code to understand constraints and opportunities. Don't ask questions that reading could answer.

3. **Riff back and forth.** Use AskUserQuestion to present options, build on the user's ideas, and explore cross-domain connections. One question at a time. Keep it energetic.

4. **Think cross-domain.** Actively surface when changing the product could simplify the tech, or when a UX change could eliminate an architectural layer. These cross-domain insights are often the most valuable brainstorming outcomes.

### Phase 2: Converge

5. When ideas start repeating or there are 5-10 options on the table, shift to convergence. Group, evaluate, and present the top 2-3 options with a recommendation.

## After the Session

6. Produce the final brainstorm summary and append it to `.claude/bee-context.local.md` (the skill's incremental writes have been building this file throughout the session — the summary closes it out).

7. If standalone (no bee-state), also save the full structured summary to `docs/brainstorms/[topic]-brainstorm.md` (create the directory if needed).

8. Offer next steps via AskUserQuestion:
   "Nice session! Where to next?"
   Options: "Run /bee:sdd to build this (Recommended)" / "Run /bee:discover to write a PRD" / "Run /bee:brainstorm to explore another angle" / "I'm done for now"
