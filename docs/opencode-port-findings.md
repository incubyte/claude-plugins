---
date: 2026-04-25
topic: porting Bee plugin from Claude Code to opencode
project: incubyte/ai-plugins
status: working v1, demo in progress
---

# Bee on opencode — port findings

Cross-platform port of [`incubyte/ai-plugins`](https://github.com/incubyte/ai-plugins) Bee plugin (originally Claude Code) to also run on [opencode](https://opencode.ai). This log captures the *what worked* and *why* so a future session (or PR description) can recover the reasoning without re-reading 200 turns of source-spelunking.

## The starting confusion

Three platforms in the air made approach selection slow:

- **Bee** — 35 agents, 12 commands, 20 skills, hooks, state script. Works on Claude Code via `.claude-plugin/`.
- **Superpowers** (`obra/superpowers`) — opencode plugin. Skills-only philosophy, ~80 LOC plugin.
- **omo / oh-my-opencode** (`code-yeongyu/oh-my-openagent`) — full opencode-native harness, TypeScript agents, multi-model category routing, background agents.

We initially planned a borrowed-omo refactor (skills + thin platform wrappers + category routing). After ~2 hours of design work we dropped that scope when the user clarified the real goal: **"i want bee to work exactly how it works in claude code, like how it is able to spawn sub-agents parallely. also more like how it calls tools correct and more"** — i.e., faithful Claude-parity port, not a power-tool rewrite.

That reframing made the actual job small. The architecture doc at `docs/ARCHITECTURE.md` still has the broader vision; v1 implementation is much narrower.

## Opencode discovery surfaces — what we learned reading the source

Source-of-truth: `anomalyco/opencode` repo on GitHub (the ex-`sst/opencode`, currently 148k stars). Files we read live:

| File | What it tells us |
|---|---|
| `packages/opencode/src/config/paths.ts` | The 4 directories opencode scans: global config, walked-up `.opencode/` from cwd, `~/.opencode/`, `$OPENCODE_CONFIG_DIR`. **No plugin install paths.** |
| `packages/opencode/src/config/config.ts` (lines 569-571) | `ConfigCommand.load(dir)`, `ConfigAgent.load(dir)`, `ConfigAgent.loadMode(dir)` are called over those 4 dirs only. |
| `packages/opencode/src/config/agent.ts` | Glob `{agent,agents}/**/*.md`, recursive. Path patterns recognized as agent roots: `/.opencode/agent/`, `/.opencode/agents/`, `/agent/`, `/agents/`. Same shape for commands. |
| `packages/opencode/src/config/entry-name.ts` | `configEntryNameFromPath` derives the agent/command name by **stripping the first matching pattern from the path**. Crucial detail. |
| `packages/opencode/src/skill/index.ts` | Skills scanned recursively in `~/.claude/skills/`, `~/.agents/skills/`, walked-up `.claude/`/`.agents/` dirs, and `{skill,skills}/**/SKILL.md` under config dirs. Skill name comes from **frontmatter `name:`**, not filename or path. |
| `packages/plugin/src/index.ts` (Hooks interface) | Plugins can register: `tool`, `auth`, `provider`, event hooks, chat hooks, permission/tool execute hooks, experimental hooks. **No agent/command registration hook exists.** |
| `packages/web/src/content/docs/agents.mdx` | Official docs: markdown agents go in `~/.config/opencode/agents/` (global) or `.opencode/agents/` (project). Same for commands. **Plugin dirs are not mentioned.** |

### The killer fact

> Opencode does not auto-discover agents/commands/skills bundled inside plugin packages. The only legal install location is the user's opencode config dir.

The `config(cfg)` plugin hook returns `Promise<void>` (notification only) and is fired *after* the agent service has already read `cfg.agent`, so even if you mutated config there, nothing observes the mutation. Confirmed.

## The approach that worked: symlink installer

Plugin ships content under `bee/.opencode/` (and `bee/skills/`, `bee/scripts/`). An install script creates per-file symlinks into `~/.config/opencode/`:

```
~/.config/opencode/
├── agents/
│   ├── bee-slice-coder.md      → <plugin>/bee/.opencode/agents/slice-coder.md
│   └── ... (35 per-file symlinks)
├── commands/
│   ├── bee-sdd.md              → <plugin>/bee/.opencode/commands/sdd.md
│   └── ... (12 per-file symlinks)
├── skills/
│   └── bee                     → <plugin>/bee/skills/                 (directory symlink)
└── bee/
    └── scripts                 → <plugin>/bee/scripts/                (directory symlink)
```

### Why per-file symlinks (not a directory symlink) for agents/commands

`configEntryNameFromPath` strips the first `/agent(s)/` or `/command(s)/` segment from the path and keeps the rest. So a directory symlink `agents/bee/` would yield names like `bee/slice-coder` (with a slash), which uglifies `@` mentions and `task(subagent_type=...)` calls. Per-file symlinks with `bee-` prefix produce clean flat names: `bee-slice-coder`, `/bee-sdd`.

### Why a directory symlink works for skills

Skills are keyed on frontmatter `name:`, not on path or filename. Recursive glob `{skill,skills}/**/SKILL.md` finds them at any depth.

### Why we don't prefix skills with `bee-`

Discussed and rejected. Renaming all 20 skills' `name:` to `bee-*` would require ~50 cross-reference updates inside agents/commands, and it'd be visible on Claude Code too (skills are platform-shared files). Skills with bare names work fine on opencode (`/clean-code`, `/tdd-practices`); the inconsistency with prefixed agents/commands is a small cosmetic blemish, not a functional issue.

## Generator transformations — what gets rewritten

Two Python generators turn Claude Code's source files into opencode twins:

- `bee/scripts/generate-opencode-agents.py` — `bee/agents/<name>.md` → `bee/.opencode/agents/<name>.md`
- `bee/scripts/generate-opencode-commands.py` — `bee/commands/<name>.md` → `bee/.opencode/commands/<name>.md`

Body substitutions applied (in order, regex-based):

| From (Claude) | To (opencode) | Reason |
|---|---|---|
| `${CLAUDE_PLUGIN_ROOT}/scripts/` | `$HOME/.config/opencode/bee/scripts/` | install symlinks scripts/ to a fixed path |
| `bee:<agent-name>` | `bee-<agent-name>` | opencode names agents from filename, prefix added by install symlinks |
| `**IMPORTANT — Deferred Tool Loading:** ...paragraph...` | (stripped) | opencode has no `ToolSearch`/deferred-tool concept, all tool schemas always available |
| `AskUserQuestion` | `question` | opencode tool name |
| `TodoWrite`, `TaskCreate`, `TaskUpdate`, `TaskList`, `TaskGet`, `TaskStop`, `TaskOutput` | `todowrite` | opencode unifies under one tool |
| `WebSearch` | `websearch` | opencode tool name |
| `WebFetch` | `webfetch` | opencode tool name |
| `ToolSearch` | `tool schema search (not needed on opencode)` | leftover ref scrub |
| `\n{3,}` | `\n\n` | collapse blanks left by stripped paragraphs |

### The `name:` field in agent frontmatter — the bug we hit

Generator initially wrote `name: <original>` in the opencode agent frontmatter. Opencode's `ConfigAgent` parses agents via `{ name: <filename-derived>, ...md.data, prompt }` — so a frontmatter `name:` **overrides the filename-derived name**. Result: install symlinks `bee-slice-coder.md → slice-coder.md` registered the agent as `slice-coder` (unprefixed), and every cross-reference in commands/agents that said `bee-slice-coder` failed to resolve.

**Fix:** generator strips the `name:` field. Filename wins. With `bee-` prefixed symlinks, opencode names the agent `bee-slice-coder`. Verified against `/agent` API: 35/35 prefixed correctly.

This is the single most fragile thing in the port. Any future generator change that puts `name:` back will silently break subagent dispatch.

### The `model:` field — also intentionally never written

Pinning a model in agent frontmatter overrides the user's TUI/session model choice. We never want that. The `category:` field is metadata only; the design doc reserves a future opt-in `routing.json` for users who want per-category routing.

## Opencode runtime behavior gotchas (what bit us)

### Config is cached at server startup

Opencode does **not** rescan disk on session creation, file change, or any HTTP API call. The agent/command/skill registry is built once when `opencode web` (or `opencode tui`) starts, and reused for the lifetime of the process. Implications:

- After running `install.sh`, you must restart opencode for the new content to appear.
- Editing a command body? Restart needed (the body is part of the cached `template`).
- Renaming an agent? Restart.
- Tracked in `bee/.opencode/INSTALL.md` troubleshooting section.

This is significantly more aggressive caching than Claude Code, which reads plugin files on demand.

### Variants are CLI-only

`opencode --variant max` works on the CLI. The web UI's variant dropdown shows only what's registered in the provider config. For `kimi-for-coding/k2p6`, `variants: []` — so opencode web can only run k2p6 in default mode. Confirmed via `/config/providers` endpoint.

### Slash menu shows skills *and* commands together

Skills with a `description:` field appear in the slash menu as `/skillname` (skill badge in description). Commands appear without the badge. They share namespace — collisions are possible. Bee's commands are `bee-*` prefixed (no collision risk) but skills are bare names (low risk in practice).

## Plugin API capabilities — what we don't use

For completeness, here's what `Hooks` exposes (`packages/plugin/src/index.ts`):

```ts
event, config, tool, auth, provider,
"chat.message", "chat.params", "chat.headers",
"permission.ask",
"command.execute.before", "tool.execute.before", "tool.execute.after",
"shell.env",
"experimental.chat.messages.transform", "experimental.chat.system.transform",
"experimental.session.compacting", "experimental.compaction.autocontinue",
"experimental.text.complete",
"tool.definition"
```

A v2 bee.js could:

- `experimental.chat.system.transform` — inject a "you are Bee" preamble on first message
- `tool` — register a `bee_state` custom tool to replace the shell script
- `tool.definition` — modify tool descriptions (probably not useful for bee)

**v1 ships no JS plugin.** Markdown + state script suffices for Claude-parity.

## End-to-end verification (proof)

After the generator name-field fix and a server restart:

```
GET /agent  → 42 total = 7 built-in + 35 bee-* (verified via curl + python)
GET /command → 70 total includes 12 bee-* commands
GET /skill   → 55 total includes all 20 bee skills (clean-code, tdd-practices, ...)
```

Real subagent dispatch test (session `ses_23e51f761ffeMoDSfK9TexnLY9`):

```
user: "Use the task tool with subagent_type 'bee-context-gatherer' ..."
assistant message 1:
  [tool:task] status=completed title=Gather project context
    subagent_type=bee-context-gatherer
    description=Gather project context
assistant message 2:
  [text] **AV-Campus** is a monorepo for a film/media equipment management platform...
```

The build agent looked up `bee-context-gatherer`, ran it as a subagent, the subagent read CLAUDE.md and returned a summary, the parent summarized back to the user. Bee's defining feature (parallel subagent dispatch) works on opencode unchanged.

`/bee-help` also runs end-to-end: command body delivered as user prompt, model invokes `question` tool with the exact options the markdown specified.

## Files in the port (deliverables)

```
incubyte-ai-plugins/
├── bee/
│   ├── scripts/
│   │   ├── generate-opencode-agents.py        ← NEW
│   │   └── generate-opencode-commands.py      ← NEW
│   └── .opencode/
│       ├── agents/*.md                         ← 35 generated
│       ├── commands/*.md                       ← 12 generated
│       ├── bin/install.sh                      ← idempotent symlink installer
│       ├── bin/uninstall.sh                    ← bee-only-aware uninstaller
│       └── INSTALL.md                          ← user-facing instructions
├── docs/
│   ├── ARCHITECTURE.md                         ← updated (§3.5 install mechanism)
│   ├── brainstorms/
│   │   ├── opencode-advanced-integration-brainstorm.md
│   │   └── pilot-phase-0-findings.md           ← documents the failed include-mechanism
│   └── demos/opencode-port/
│       └── screenshots/                         ← PR artifacts (in progress)
```

## Things explicitly out of scope for v1

- **`bee/.opencode/plugin/bee.js`** — deferred. Auto-install on first session, custom `bee_state` tool, prompt injection. None of these are required for Claude-parity. The shell-script state mechanism works.
- **Routing config** (`routing.json` for category → model mapping) — Phase 2.
- **Hook port** (`stop-session.sh`) — opencode has no equivalent shell hook surface; would need a JS plugin.

## What surprised us / future-Claude warnings

1. **Don't believe documentation about plugin discovery.** Even after reading the docs, the only way to know what opencode actually scans is to read `paths.ts`. Docs only describe the user-facing config dirs.
2. **`--variant max` is a global CLAUDE.md preference but doesn't exist on opencode web.** The variant dropdown is bound to provider-registered variants only.
3. **Opencode config caching is aggressive.** Plugin development on opencode requires `Ctrl+C; opencode web` after every meaningful change. Plan for it.
4. **`sst/opencode` redirects to `anomalyco/opencode`** as of mid-2026. The Go-flavored `opencode-ai/opencode` is a different project (older name).
5. **The generator's regex for the deferred-tool paragraph** assumes a particular markdown shape (the `**IMPORTANT — Deferred Tool Loading:**` heading + paragraph until the next blank line). If a future agent adds a similar but differently-worded paragraph, the strip won't catch it.
6. **`name:` in agent frontmatter is a footgun.** Anyone editing the generator should add a comment guard / test.

## Cross-references

- Plugin repo: `~/codes/ai/tools/incubyte-ai-plugins/`
- Architecture doc: `incubyte-ai-plugins/docs/ARCHITECTURE.md` §3.5 has the install mechanism in canonical form
- Demo project: `~/codes/ai/testing/tinyurl/` (built using bee on opencode for the PR)
- Opencode source: <https://github.com/anomalyco/opencode> (default branch `dev`)
