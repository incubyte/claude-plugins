---
description: Bee adapter for /bee:qc (Codex-compatible)
arguments: ["request"]
---

# Bee /bee:qc (Codex Adapter)

This is the Codex-compatible adapter for the Bee command `/bee:qc`.

## How to run

1. Read `bee/CLAUDE.md` for Bee's role, workflow, and conventions.
2. Follow the command in `bee/commands/qc.md` directly.
3. Apply the substitutions in `CODEX_COMPATIBILITY.md` for any Claude-only tools.

## Codex substitutions (summary)

- No `Task` or subagents: run steps sequentially.
- No `AskUserQuestion`: ask the user inline with the same options.
- No `Skill`: open `bee/skills/<skill>/SKILL.md` directly.
