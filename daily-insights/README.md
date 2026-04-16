# AI Usage Insights — Claude Code Plugin

A Claude Code plugin that generates daily AI usage reports from your local session data.
No API key needed — uses your existing Claude Code authentication.

## What it tracks

- **Tokens** — input, output, and cache reads per session
- **Cost** — estimated spend per day / project / model
- **Sessions** — how many, how long, which projects
- **Tool calls** — Read, Edit, Bash, etc.
- **Models** — Opus vs Sonnet vs Haiku usage breakdown

## Requirements

| Platform | Dependency | Install |
|----------|-----------|---------|
| macOS | `jq` | `brew install jq` |
| Linux | `jq` | `sudo apt install jq` / `sudo dnf install jq` |
| Windows + WSL | `jq` | `sudo apt install jq` (inside WSL) |
| Windows native | Nothing | PowerShell 5.1+ is built-in |

## Install

```bash
claude plugin install daily-insights@incubyte-plugins
```

Then in any Claude Code session:

```
/daily-insights              # today's report
/daily-insights yesterday    # yesterday
/daily-insights 7d           # last 7 days
/daily-insights 2026-02-14   # specific date
```

## How it works

Reads two local sources Claude Code already maintains:

| Source | What it provides |
|--------|-----------------|
| `~/.claude/stats-cache.json` | Historical tokens, sessions, tool calls, peak hours |
| `~/.claude/projects/**/*.jsonl` | Per-project breakdown, session durations |

Claude detects your OS automatically and runs the right script — bash+jq on macOS/Linux/WSL, PowerShell on Windows native.

## Example output

```
## AI Usage Insights — Today (2026-02-23)

### Summary
Active across 4 sessions today spending ~$0.16...

### Metrics
| Sessions       | 4     |
| Tool Calls     | 38    |
| Tokens         | 10,864 |
| Est. Cost      | $0.16 |

### Projects
- ai-report-generator: 3 sessions, heavy tool use (38 calls)...

### Patterns
- 99% of token spend is cache reads — very efficient
- Tool/message ratio of 0.5 indicates complex file operations
```
