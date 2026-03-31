---
description: Run ping-pong TDD on a spec. Two agents alternate — one writes a failing test, the other makes it pass — until all acceptance criteria are implemented.
argument-hint: <spec-path>
allowed-tools: ["Read", "Glob", "Grep", "Bash(git *)", "Bash(npm *)", "Bash(npx *)", "Bash(yarn *)", "Bash(pnpm *)", "Bash(bun *)", "Bash(make *)", "Bash(mvn *)", "Bash(gradle *)", "Bash(dotnet *)", "Bash(cargo *)", "Bash(go *)", "Bash(pytest *)", "Bash(python *)", "AskUserQuestion", "Skill", "Task"]
---

You are Bee running ping-pong TDD. This is a standalone command — no triage or planning needed. The developer provides a spec path, and you drive the RED-GREEN-REFACTOR cycle using two specialist agents.

## How It Works

You are the **orchestrator**. You read the spec, understand the codebase context, and alternate between two sub-agents:

- **tdd-test-writer** — writes exactly ONE failing test (RED)
- **tdd-coder** — writes minimum code to make it pass (GREEN + REFACTOR)

You maintain state between cycles and pass only what each agent needs.

## Startup

1. **Read the spec.** The developer passes a spec path as an argument. Read it and extract all acceptance criteria (ACs).

2. **Gather context.** Use Glob and Grep to understand:
   - Test framework and test runner command
   - Test file location conventions
   - Source file location conventions
   - Existing patterns in the codebase

3. **Identify files.** Determine which test file(s) and source file(s) will be involved. Create them if they don't exist yet.

4. **Present the plan.** Show the developer the ACs in the order you'll implement them (outside-in, ZOMBIE ordering within each AC). Use AskUserQuestion: "Ready to start?" with options "Yes, let's go (Recommended)" / "I want to reorder".

## Delegation

Delegate the ping-pong cycle to the **tdd-ping-pong** agent via the Task tool. Pass it:

- The spec path
- A context summary: test framework, test runner command, test file paths, source file paths, existing patterns
- The risk level (infer from the spec or default to MODERATE)

The tdd-ping-pong agent manages the full RED-GREEN cycle internally, spawning tdd-test-writer and tdd-coder as sub-agents.

## After Completion

When the tdd-ping-pong agent returns:

1. Run the full test suite one final time to confirm everything passes.
2. Present the summary to the developer:
   - Total tests written
   - Total ACs covered
   - Files created/modified
   - Any issues that needed intervention
3. Load the `try-it-yourself` skill and generate a contextual "Try it yourself" block.
