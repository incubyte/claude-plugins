# Incubyte AI Plugins

A collection of AI development plugins by [Incubyte](https://incubyte.co). Runs on [Claude Code](https://www.anthropic.com/claude-code) and [opencode](https://opencode.ai).

## Plugins

### [Bee](bee/) — AI Development Workflow Navigator

Spec-driven development that scales process to match the task. Triages by size and risk, then navigates you through the right workflow: triage, context gathering, spec, architecture, code, test, verify, review.

- 12 commands, 35 specialist agents, 20 skills
- Runs on Claude Code and opencode
- Session resume across conversations
- Design system awareness for UI work
- Collaboration loop with `@bee` inline annotations

Entry point: `/bee:sdd` (Claude Code) or `/bee-sdd` (opencode)

### [Learn](learn/) — Build to Learn

Learn any technology by building real projects. Claude guides you step-by-step — you write every line of code yourself.

- Project-based curriculum generation
- Adaptive pacing by skill level
- Progress tracking across sessions
- Knowledge checks with quizzes

Entry point: `/learn:start`

## Install

### On Claude Code

```bash
# Add the Incubyte marketplace
/plugin marketplace add incubyte/claude-plugins

# Install a plugin
/plugin install bee@incubyte-plugins
/plugin install learn@incubyte-plugins
```

### On opencode

Bee runs on opencode via per-file symlinks into `~/.config/opencode/`. From a clone of this repo:

```bash
git clone https://github.com/incubyte/ai-plugins.git
cd ai-plugins
bash bee/.opencode/bin/install.sh
```

Then **restart opencode** — it builds its agent/command registry once at server startup, so any running `opencode web` or `opencode tui` needs to be restarted before bee shows up. Use `/bee-sdd`, `/bee-brainstorm`, `/bee-review`, etc. from the slash menu in any session.

Full install guide, troubleshooting, and uninstall: [`docs/opencode-install.md`](docs/opencode-install.md). Implementation notes (discovery surfaces, generators, gotchas): [`docs/opencode-port-findings.md`](docs/opencode-port-findings.md).

## License

See individual plugin directories for license details.
