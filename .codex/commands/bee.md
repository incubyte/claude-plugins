---
description: Bee workflow navigator entry point (Codex-compatible)
arguments: ["request"]
---

# Bee (Codex Adapter)

Use this command as the Codex-compatible entry point for the Bee Claude plugin.

## How to run Bee in Codex

1. Read `bee/CLAUDE.md` to load Bee's role, workflow, and conventions.
2. Follow the orchestrator in `bee/commands/build.md` as the primary entry point for `/bee`.
3. When Bee routes to a subcommand (for example `/bee:review`, `/bee:qc`, `/bee:discover`, `/bee:architect`, `/bee:onboard`, `/bee:browser-test`, `/bee:migrate`), open the matching file under `bee/commands/` and follow it directly.
4. Apply the substitutions in `CODEX_COMPATIBILITY.md` whenever a Bee command references Claude-only tools.

## Codex substitutions (summary)

- No `Task` or subagents: run steps sequentially.
- No `AskUserQuestion`: ask the user inline with the same options.
- No `Skill`: open `bee/skills/<skill>/SKILL.md` directly.

## Start

Ask the user for their request if it was not provided, then begin the Bee workflow using `bee/commands/build.md`.
