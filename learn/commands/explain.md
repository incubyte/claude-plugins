---
description: Deep-dive explanation of a concept, pattern, or piece of code.
allowed-tools: ["Read", "Glob", "Grep", "AskUserQuestion", "Skill"]
argument-hint: "<concept, file, or code pattern to explain>"
---

## Skill Loading

Load the `teaching` skill using the Skill tool for skill-level adaptation.

## Process

1. Read `.claude/learn-state.local.md` to know the learner's skill level and what they've built so far.
2. Parse "$ARGUMENTS" to determine what to explain.

## Explanation Types

### File or code reference

If the learner points to a file or code they've written:

1. Read the file.
2. Walk through it section by section, explaining:
   - What each part does
   - Why it's structured this way
   - How it connects to other parts of the project
3. Adapt depth to skill level.

### Concept or pattern

If the learner asks about a concept ("what is middleware?", "explain REST", "how do foreign keys work?"):

1. Start with a one-sentence definition.
2. Ground it in their project: "In your app, this shows up when..."
3. Show a concrete example from code they've already written or will write soon.
4. If the concept hasn't appeared in their project yet, preview where it will.

### "Why did we do X?"

If the learner asks about a decision made earlier:

1. Find the relevant code in their project.
2. Explain the reasoning behind the approach.
3. Briefly mention alternatives and why this choice was made.
4. Keep it practical, not theoretical.

## Explanation Format

- Lead with the simple version, then layer in depth.
- Use analogies when helpful, but don't force them.
- Always connect back to code the learner has written.
- End with a check: "Does that make sense? Want me to go deeper on any part?"

## What NOT to Do

- Don't lecture. Keep it conversational.
- Don't introduce unrelated concepts.
- Don't show code from outside the learner's project unless comparing approaches.
