# Incubyte Claude Plugins

A collection of Claude Code plugins by [Incubyte](https://incubyte.co).

## Plugins

### [Bee](bee/) — AI Development Workflow Navigator

Spec-driven development that scales process to match the task. Triages by size and risk, then navigates you through the right workflow: triage, context gathering, spec, architecture, code, test, verify, review.

- 10 commands, 26 specialist agents
- Session resume across conversations
- Design system awareness for UI work
- Collaboration loop with `@bee` inline annotations

Entry point: `/bee:sdd`

### [Learn](learn/) — Build to Learn

Learn any technology by building real projects. Claude guides you step-by-step — you write every line of code yourself.

- Project-based curriculum generation
- Adaptive pacing by skill level
- Progress tracking across sessions
- Knowledge checks with quizzes

Entry point: `/learn:start`

## Install

```bash
# Add the Incubyte marketplace
/plugin marketplace add incubyte/claude-plugins

# Install a plugin
/plugin install bee@incubyte-plugins
/plugin install learn@incubyte-plugins
```

## License

See individual plugin directories for license details.
