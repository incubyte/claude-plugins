# Incubyte Claude Code Plugins

A plugin marketplace for Claude Code by [Incubyte](https://incubyte.co).

## Installation

```bash
# In Claude Code, add the marketplace
/plugin marketplace add incubyte/claude-plugins

# Install plugins
/plugin install bee@incubyte-plugins
/plugin install learn@incubyte-plugins
```

## Available Plugins

| Plugin | Description |
|--------|-------------|
| **bee** | Spec-driven TDD workflow navigator. Guides developers through triage, spec building, architecture decisions, TDD planning, verification, and review. |
| **daily-insights** | Daily AI usage report — tokens, cost, sessions, and projects from your local Claude Code session data. Use `/daily-insights [today\|yesterday\|YYYY-MM-DD\|7d]`. |
| **learn** | Learn any technology by building real projects. Claude guides step-by-step — you write every line of code yourself. |

## Adding New Plugins

Add an entry to `.claude-plugin/marketplace.json` and point `source` to the plugin's GitHub repo.
