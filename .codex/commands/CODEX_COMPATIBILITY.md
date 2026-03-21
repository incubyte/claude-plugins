# Codex Compatibility Guide (Bee + Learn)

Codex CLI cannot invoke Claude-specific tools (`Task`, `AskUserQuestion`, `Skill`, `TodoWrite`) or spawn subagents. Use the substitutions below when running Bee or Learn commands via Codex.

## Tool substitutions

- `Task` / subagents: Execute the described steps yourself, sequentially. Note intended parallelism but do not call Task.
- `AskUserQuestion`: Ask the user inline with the same options and proceed based on the answer.
- `Skill(name)`: Open the skill file directly from the active plugin path and follow its SOP manually (`bee/skills/<skill>/SKILL.md` for Bee commands, `learn/skills/<skill>/SKILL.md` for Learn commands).
- `TodoWrite`: Edit the referenced file directly (if any), keeping updates atomic.

## Command mapping

- `/bee` entry point: Follow `bee/commands/build.md` as the primary orchestrator.
- `/bee:<command>`: Open the matching command in `bee/commands/` and follow it directly.
- `/learn` entry point: Follow `learn/commands/start.md` as the primary orchestrator.
- `/learn:<command>`: Open the matching command in `learn/commands/` and follow it directly.

## When a Bee command says…

- “Spawn agents in parallel” -> Run them one-by-one in the same session.
- “Use AskUserQuestion” -> Ask the question in chat with the listed options.
- “Use Skill tool” -> Read the skill file from disk and apply its guidance.
