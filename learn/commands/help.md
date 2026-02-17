---
description: Show available commands and current learning progress.
allowed-tools: ["Read", "Glob", "AskUserQuestion"]
---

## Process

1. Check for `.claude/learn-state.local.md`.

## If Active Session

Read the state file and `docs/curriculum.md`. Present:

**Current Project**: [project name]
**Tech Stack**: [stack]
**Progress**: Module [N] of [M], Step [X] of [Y] — [step description]

Then show the command reference.

## If No Active Session

"No active learning session. Start one with `/learn:start`."

Then show the command reference.

## Command Reference

**Getting Started:**
- `/learn:start` — Begin a new learning journey. Tell me what you want to learn and build.
  Example: `/learn:start Python + React + PostgreSQL by building a task manager`

**During Your Journey:**
- `/learn:next` — Continue to the next step in your curriculum
- `/learn:explain` — Deep-dive into a concept, file, or pattern
  Example: `/learn:explain middleware` or `/learn:explain src/routes/auth.js`
- `/learn:quiz` — Test your understanding with questions
  Example: `/learn:quiz` (latest module) or `/learn:quiz 2` (specific module)

**Getting Help:**
- `/learn:analyze` — Diagnose issues in your project when something isn't working
  Example: `/learn:analyze my server won't start`
- `/learn:review` — Get feedback on your code quality
  Example: `/learn:review src/routes/` or `/learn:review` (whole project)

**Tips:**
- Your progress saves automatically — close the terminal and come back anytime
- The curriculum is in `docs/curriculum.md` — peek ahead if you're curious
- Ask questions anytime — you don't need a command for that
