---
description: Start a Bee workflow navigation session. Assesses your task and recommends the right level of process.
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/update-bee-state.sh:*)", "Bash(git:*)", "Bash(npm:*)", "Bash(npx:*)", "Bash(yarn:*)", "Bash(pnpm:*)", "Bash(bun:*)", "Bash(make:*)", "Bash(mvn:*)", "Bash(gradle:*)", "Bash(dotnet:*)", "Bash(cargo:*)", "Bash(go:*)", "Bash(pytest:*)", "Bash(python:*)", "AskUserQuestion", "Skill", "Task", "TaskCreate", "TaskUpdate", "TaskList"]
---

## Delegation

This command delegates to `bee:sdd`. All workflow navigation — triage, context gathering, spec building, architecture, coding, testing, verification, and review — is handled by the SDD command.

Invoke `bee:sdd` via the Skill tool, passing `$ARGUMENTS`.
