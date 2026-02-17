---
description: Analyze your project's current state and help debug issues.
allowed-tools: ["Read", "Glob", "Grep", "Bash", "AskUserQuestion", "Task"]
argument-hint: "[specific issue or area to analyze]"
---

## Process

1. Read `.claude/learn-state.local.md` to understand the project context, tech stack, and current step.
2. If no state file: "No learning session found. What project would you like me to analyze?"

## Analysis Mode

Determine the analysis type from "$ARGUMENTS":

### If the learner describes a specific problem:

"Something is not working", "I'm getting an error", "my app crashes"

1. Ask: "What error or unexpected behavior are you seeing?" (if not already described)
2. Delegate to the project-analyzer agent via Task, passing:
   - The learner's error description
   - The tech stack from state
   - The current step in the curriculum
3. Share the diagnosis in learner-friendly terms:
   - What went wrong
   - Why it happened
   - Where to look (specific file + line)
   - How to fix it — but guide, don't just give the answer
4. Turn it into a learning moment: "This is a common mistake with [concept]. The key thing to remember is..."

### If no specific problem — general analysis:

1. Delegate to the project-analyzer agent via Task, passing:
   - The project's tech stack
   - The current curriculum step
   - Request for a general health check
2. Report findings as a friendly summary:
   - What's working well
   - What could be improved
   - Any issues that might cause problems later
3. For each issue, explain the "why" — this is a teaching opportunity.

## Guidance Style

Never just fix the problem. Always:
1. Explain what's wrong
2. Explain why it's wrong
3. Guide the learner to the fix
4. Connect it to a concept they've learned or will learn

Use AskUserQuestion if there are multiple possible fixes:
"There are a couple of ways to fix this:"
Options with brief descriptions of each approach and their trade-offs.
