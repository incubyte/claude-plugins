---
description: Test your understanding with questions about what you've built.
allowed-tools: ["Read", "Glob", "Grep", "AskUserQuestion", "Skill"]
argument-hint: "[module number or topic]"
---

## Skill Loading

Load the `teaching` skill using the Skill tool.

## Process

1. Read `.claude/learn-state.local.md` for skill level and progress.
2. Read `docs/curriculum.md` to see completed steps.
3. Determine quiz scope from "$ARGUMENTS":
   - If a module number: quiz on that module
   - If a topic: quiz on that topic across the project
   - If empty: quiz on the most recently completed module

## Quiz Format

Generate 3-5 questions. Present them one at a time using AskUserQuestion.

### Question Types

Mix these types based on what the learner has built:

**Conceptual**: Test understanding of why something works.
"What's the purpose of the `next()` call in your authentication middleware?"

**Predictive**: Test mental model of code behavior.
"If you send a POST to `/api/users` without a name field, what will happen?"

**Diagnostic**: Test debugging instinct.
"A user reports they can't log in even with correct credentials. Looking at your auth flow, what's the first thing you'd check?"

**Connective**: Test understanding of how parts relate.
"How does the User model you defined in step 2.3 connect to the login route you wrote in step 3.1?"

### Answer Handling

For each question:
- Present 3-4 options via AskUserQuestion
- If correct: brief affirmation + optionally deepen understanding
- If incorrect: explain the right answer using their actual code. "Look at `server/middleware/auth.js` line 8 — that's where..."

## After the Quiz

Summarize: "You got [X/Y] right."

If all correct: "Solid understanding. Ready to keep building?"
If some wrong: "Let's review [topic]. Want me to explain [concept] in more detail?" Offer `/learn:explain` for weak areas.

Track quiz results in the state file under a `## Quiz Results` section for the learner's reference.
