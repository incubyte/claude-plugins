---
description: Start a learning journey — pick a tech stack and a project to build.
allowed-tools: ["Read", "Glob", "Grep", "Bash", "AskUserQuestion", "Skill", "Task"]
argument-hint: "<what you want to learn and build>"
---

## Skill Loading

Load the `teaching` skill using the Skill tool before proceeding. It contains curriculum design, code presentation standards, and skill level adaptation rules.

## On Startup — Session Resume

Before anything, check for in-progress work:

1. Look for `.claude/learn-state.local.md`
2. If found, read it. It tells you the project, stack, skill level, and current step.
3. Use AskUserQuestion:
   "Welcome back! Last time we were working on **[project name]** — [current step description]. Pick up where we left off?"
   Options: "Yes, continue" / "Start something new"
4. If resuming: read `docs/curriculum.md`, find the next unchecked step, and continue from there. Use `/learn:next` flow.
5. If starting new: continue below.

## New Learning Journey

The learner wants to learn: "$ARGUMENTS"

### Step 1: Understand the Goal

Parse what the learner wants:
- **Tech stack**: Which languages, frameworks, databases?
- **Project idea**: What are they building?

If either is unclear from the arguments, ask using AskUserQuestion. One question at a time.

If no arguments provided, ask:
"What would you like to learn? Tell me the tech stack and what you'd like to build. For example: 'Python + React + PostgreSQL by building a task manager'"

### Step 2: Assess Skill Level

Use AskUserQuestion:
"What's your experience level with these technologies?"
Options:
- "Beginner — new to most of this stack" (description: "I'll explain everything from setup to concepts")
- "Intermediate — comfortable with basics" (description: "I'll focus on new concepts and patterns")
- "Experienced — learning a new stack" (description: "I'll focus on idioms, trade-offs, and architecture")

### Step 3: Confirm the Plan

Summarize in 3-4 sentences:
- What they're building
- The tech stack
- The skill level adaptation
- Roughly how many modules to expect

Use AskUserQuestion:
"Sound good?"
Options: "Let's go!" / "I want to adjust something"

### Step 4: Generate Curriculum

Design a curriculum following the teaching skill's module ordering:
1. Project setup and "hello world"
2. Core data model
3. Basic CRUD end-to-end
4. Business logic
5. Polish and improvements

Each module should have 5-15 concrete steps. Each step produces a visible result.

Save the curriculum to `docs/curriculum.md` using the format from the teaching skill. Tell the learner:
"I've saved the curriculum to `docs/curriculum.md`. You can peek at it anytime to see what's ahead."

### Step 5: Initialize State

Write `.claude/learn-state.local.md` with:
- Project description
- Tech stack
- Skill level
- Curriculum path
- Current step: Module 1, Step 1

### Step 6: Begin Module 1, Step 1

Start teaching the first step. Follow the teaching skill's step structure:
1. State the goal
2. Explain the concept (if new)
3. Show the action — file path + code + explanation
4. Tell them how to verify
5. Wait for them to confirm before moving on

After they confirm, update the curriculum (check off the step) and state file (advance current step).

Ask: "Ready for the next step?" or let them ask questions first.
