---
description: Continue to the next step in your learning journey.
allowed-tools: ["Read", "Glob", "Grep", "Bash", "AskUserQuestion", "Skill"]
---

## Skill Loading

Load the `teaching` skill using the Skill tool.

## Process

1. Read `.claude/learn-state.local.md` to find the current position.
2. If no state file exists: "No learning session in progress. Run `/learn:start` to begin."
3. Read `docs/curriculum.md` to find the next unchecked step.
4. If all steps are checked: "You've completed the entire curriculum! Run `/learn:review` for a final code review, or `/learn:start` to begin a new project."

## Deliver the Next Step

Follow the teaching skill's step structure:

1. **Goal**: State what this step achieves in one sentence.
2. **Concept**: If this step introduces a new idea, explain it before showing code. Keep it conversational and grounded — relate it to something the learner already built.
3. **Action**: Show the file to create or modify with complete, runnable code. Use the exact format from CLAUDE.md — file path, fenced code block, explanation of why.
4. **Verification**: Tell them exactly how to test it. A command to run, a URL to visit, an output to expect.
5. **Wait**: Let the learner confirm they've completed it before proceeding.

## After the Step

1. Check off the completed step in `docs/curriculum.md`.
2. Update `.claude/learn-state.local.md` with the new current step.

## Comprehension Check

If this is the 3rd, 4th, or 5th step since the last comprehension check, ask a question using AskUserQuestion. Follow the teaching skill's question types: conceptual, predictive, diagnostic, or connective.

If the learner answers incorrectly, explain the right answer using code they've already written — not abstract theory.

## Module Transitions

When completing the last step of a module:
- Celebrate: "Module [N] done — [brief summary of what they built]."
- Preview: "Next up: Module [N+1] — [module name]. This is where we [brief preview]."
- Use AskUserQuestion: "Ready for the next module?"
  Options: "Let's go" / "I want to review what we built first" / "Take a break"

If "review": suggest running `/learn:review` on the current module's code.
If "break": confirm state is saved and they can resume anytime with `/learn:next`.
