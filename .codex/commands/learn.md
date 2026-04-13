---
description: Learn teaching workflow entry point (Codex-compatible)
arguments: ["request"]
---

# Learn (Codex Adapter)

Use this command as the Codex-compatible entry point for the Learn Claude plugin.

## How to run Learn in Codex

1. Read `learn/CLAUDE.md` to load Learn's teaching style and workflow.
2. Follow the orchestrator in `learn/commands/start.md` as the primary entry point for `/learn`.
3. When Learn routes to a subcommand (for example `/learn:next`, `/learn:explain`, `/learn:quiz`, `/learn:analyze`, `/learn:review`, `/learn:help`), open the matching file under `learn/commands/` and follow it directly.
4. Apply the substitutions in `CODEX_COMPATIBILITY.md` whenever a Learn command references Claude-only tools.

## Codex substitutions (summary)

- No `Task` or subagents: run steps sequentially.
- No `AskUserQuestion`: ask the user inline with the same options.
- No `Skill`: open `learn/skills/<skill>/SKILL.md` directly.

## Start

Ask the user what they want to learn if it was not provided, then begin with `learn/commands/start.md`.
