# Incubyte Claude Code Plugins

A plugin marketplace for Claude Code by [Incubyte](https://incubyte.co).

## Installation

```bash
# In Claude Code, add the marketplace
/plugin marketplace add incubyte/claude-plugins

# Install a plugin
/plugin install bee@incubyte-plugins
```

## Available Plugins

| Plugin | Description |
|--------|-------------|
| **bee** | Spec-driven TDD workflow navigator. Guides developers through triage, spec building, architecture decisions, TDD planning, verification, and review. |

## Adding New Plugins

Add an entry to `.claude-plugin/marketplace.json` and point `source` to the plugin's GitHub repo.
