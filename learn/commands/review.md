---
description: Review your code quality and get feedback on what you've built.
allowed-tools: ["Read", "Glob", "Grep", "Bash", "AskUserQuestion", "Task"]
argument-hint: "[file, directory, or module to review]"
---

## Skill Loading

Load the `teaching` skill using the Skill tool for skill-level-appropriate feedback.

## Process

1. Read `.claude/learn-state.local.md` for context — tech stack, skill level, current progress.
2. Determine review scope from "$ARGUMENTS":
   - If a file path: review that file
   - If a directory: review files in that directory
   - If a module number: review all files created in that module
   - If empty: review the entire project

## Review Approach

Delegate to the project-analyzer agent via Task, passing:
- The files to review
- The learner's skill level
- The tech stack
- Request for a code quality review focused on learning

## Feedback Format

Organize feedback into three categories:

### What's Working Well
Highlight 2-3 things the learner did right. Be specific — name the file and the pattern.
"Your route handlers in `server/routes/users.js` follow a clean request-validate-respond pattern."

### Opportunities to Improve
For each issue found:
1. **What**: Describe the issue concretely
2. **Where**: File and approximate location
3. **Why it matters**: Not "it's bad practice" — explain the real consequence
4. **How to improve**: Show what better code looks like
5. **Learning connection**: Link to a concept from the curriculum

Adapt feedback depth to skill level:
- **Beginner**: Focus on correctness and clarity. 2-3 items max.
- **Intermediate**: Add patterns, naming, structure. 3-5 items.
- **Experienced**: Include architecture, edge cases, performance. Full review.

### Next Level Challenge (optional)
For intermediate and experienced learners, suggest one stretch improvement:
"Want a challenge? Try extracting your database queries into a separate data access layer. It'll make testing easier later."

## Code Quality Checks

Review against these standards (adapted from the teaching skill):
- Meaningful variable and function names (domain-specific)
- Functions under 20 lines with single responsibility
- Real error handling (not swallowed errors)
- No dead code or unused imports
- Consistent formatting
- No security issues (SQL injection, XSS, hardcoded secrets)

## What NOT to Do

- Don't overwhelm beginners with advanced concerns
- Don't rewrite their code — suggest improvements they can make
- Don't be harsh — frame everything as growth opportunity
- Don't review generated config files (package.json, etc.) — focus on code they wrote
