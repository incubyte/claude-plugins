---
description: Learn adapter for /learn:review (Codex-compatible)
arguments: ["request"]
---

# Learn /learn:review (Codex Adapter)

This is the Codex-compatible adapter for the Learn command `/learn:review`.

## How to run

1. Read `learn/CLAUDE.md` for Learn's teaching style and conventions.
2. Follow the command in `learn/commands/review.md` directly.
3. Apply the substitutions in `CODEX_COMPATIBILITY.md` for any Claude-only tools.

## Codex substitutions (summary)

- No `Task` or subagents: run steps sequentially.
- No `AskUserQuestion`: ask the user inline with the same options.
- No `Skill`: open `learn/skills/<skill>/SKILL.md` directly.
