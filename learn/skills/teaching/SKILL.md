---
name: Teaching Methodology
description: This skill should be used when guiding a learner through building a project, explaining code, creating curriculum steps, adapting to skill levels, or producing code examples for learners. It should be loaded when the user asks to "learn", "teach me", "walk me through", "explain this code", "build a project to learn", or when generating any instructional code content.
version: 0.1.0
---

# Teaching Methodology

Guidance for teaching programming through project-based learning. Every instruction produces code the learner types themselves.

## Curriculum Design

Break every project into modules. Each module covers one cohesive concern (e.g., "database setup", "user authentication", "API endpoints"). Each module contains 5-15 steps.

### Step Structure

Every step follows this pattern:

1. **Goal** — one sentence describing what the learner achieves
2. **Concept** — brief explanation of the new idea being introduced (skip if no new concept)
3. **Action** — the file to create or modify, with complete code
4. **Verification** — how to confirm it works (run a command, visit a URL, check output)
5. **Checkpoint** — after every 3-5 steps, ask a comprehension question

### Step Sizing

Each step should produce a visible, testable result. If a step requires more than 30 lines of new code, split it. If a step introduces more than one new concept, split it.

### Module Ordering

Order modules so each builds on the previous:
1. Project setup and "hello world" — immediate visible result
2. Core data model — define what the app works with
3. Basic CRUD — make data flow end-to-end
4. Business logic — add the interesting behavior
5. Polish — error handling, validation, UI improvements

## Code Presentation

### File Instructions

Always specify the full file path relative to the project root:

```
Create `server/routes/users.js`:
```

For modifications to existing files, specify what to change:

```
In `server/routes/users.js`, add this route after the existing GET route:
```

### Code Quality Standards

All code shown to learners must meet these standards:

**Naming**: Use domain-specific names. `fetchUserProfile` not `getData`. `orderItems` not `list`. `isEmailVerified` not `flag`.

**Structure**: Functions under 20 lines. One responsibility per function. Group related functions in the same file.

**No AI tells**: Avoid patterns that signal AI-generated code:
- No `// TODO: implement` placeholders
- No `// This function does X` comments restating the function name
- No `handleError(err)` that just logs and swallows
- No unnecessary abstractions for single-use cases
- No `utils.js` catch-all files
- No over-parameterized functions
- No `data`, `result`, `response` as variable names when a domain term exists

**Error handling**: Show real error handling from the start. Real messages, real recovery paths. Not `catch(e) { console.log(e) }`.

**Incremental completeness**: Every code block shown must be complete and runnable in context. Never show partial code with "fill in the rest" — that teaches nothing.

## Skill Level Adaptation

### Beginner

- Define every technical term on first use
- Show exact terminal commands: `npm init -y`, `pip install flask`
- Explain file system structure: "Create a folder called `src` inside your project root"
- Explain what each line does in the first few files
- Use `console.log` or `print()` liberally for visibility
- After each step, confirm: "Run `node server.js` — do you see 'Server running on port 3000'?"

### Intermediate

- Explain new concepts, skip fundamentals
- Point out patterns: "Notice this is the same request-validate-respond pattern from the users route"
- Introduce best practices naturally: "We extract this into a separate module because..."
- Offer brief trade-off context: "We could also use X here, but Y is simpler for our case"

### Experienced

- Focus on stack-specific idioms and conventions
- Discuss architecture decisions: "For this scale, a simple MVC layout works. If this grew to 50+ models, we'd consider..."
- Point out ecosystem conventions: "In the Flask community, this pattern is called..."
- Skip obvious explanations, focus on the non-obvious

## Comprehension Checks

After every 3-5 steps, pause with a question. Use AskUserQuestion with 3-4 options.

Question types:
- **Conceptual**: "What would happen if we removed the middleware from this route?"
- **Predictive**: "Before we run this, what do you think the output will be?"
- **Diagnostic**: "If a user sees a 404 error on this page, what's the most likely cause?"
- **Connective**: "How does this database query relate to the route we wrote earlier?"

If the learner gets it wrong, explain the correct answer grounded in the code they just wrote — not generic theory.

## Debugging Guidance

When a learner's code doesn't work:

1. Ask them what error they see (exact message)
2. Read their file to check for common issues
3. Guide them to the fix — don't just give the answer. "Look at line 12 — compare the function name with how you're calling it on line 25"
4. Explain why it broke — turn errors into learning moments

## Session Continuity

Track where the learner is in `.claude/learn-state.local.md`. On resume:
- Greet warmly: "Welcome back! Last time we got your API routes working."
- Briefly recap: "You have a working Express server with user registration. Next up: login and sessions."
- Continue from the exact next step.

## Curriculum File Format

Save the curriculum to `docs/curriculum.md`:

```markdown
# [Project Name] Curriculum

## Tech Stack
[Stack details]

## Module 1: [Name]
Goal: [What the learner achieves]
- [ ] Step 1.1: [Brief description]
- [ ] Step 1.2: [Brief description]
...

## Module 2: [Name]
...
```

Check off steps as the learner completes them.
