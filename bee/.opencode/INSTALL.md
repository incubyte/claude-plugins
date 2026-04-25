# Bee on opencode — install

Bee is primarily an [opencode](https://opencode.ai) / Claude Code plugin for spec-driven development. On opencode it installs by symlinking its agents, commands, skills, and state script into your opencode config dir — opencode then discovers them through its standard scanners.

## One-time install

From a checkout of this repo:

```bash
bash bee/.opencode/bin/install.sh
```

**Then restart opencode.** Opencode loads its agent/command/skill registry once at server startup; it does not rescan the config dir on file changes. If you have `opencode web` or `opencode tui` already running, quit it (Ctrl+C) and start it again — bee won't appear until then. After the restart, every new session in that opencode process picks up bee.

This creates symlinks under `$XDG_CONFIG_HOME/opencode` (default `~/.config/opencode`):

- `agents/bee-<name>.md` — 35 subagents (e.g. `bee-slice-coder`, `bee-review-coupling`)
- `commands/bee-<name>.md` — 12 commands (e.g. `/bee-sdd`, `/bee-review`, `/bee-brainstorm`)
- `skills/bee` — the 20 bee skills, as a directory symlink
- `bee/scripts` — the state-tracking script directory, referenced by commands

The installer is **idempotent** (safe to re-run) and **non-destructive** (refuses to overwrite anything it did not create). Pulling a new plugin version propagates automatically — the symlinks resolve through to the updated files, no re-install needed.

## Uninstall

```bash
bash bee/.opencode/bin/uninstall.sh
```

Only removes symlinks that point back into this plugin directory. User-authored agents/commands at the same paths are left untouched.

## Using Bee

Open opencode in any project. You'll see Bee's commands in the `/` menu.

- `/bee-sdd <spec-or-task>` — run the full spec-driven development loop
- `/bee-brainstorm <topic>` — idea generation session
- `/bee-discover <task>` — PRD discovery interview
- `/bee-qc` — quality coverage analysis with hotspots
- `/bee-review` — multi-agent code review (spawns 7 specialists in parallel)
- `/bee-help` — guided tour of bee's features
- `/bee-architect`, `/bee-coach`, `/bee-ping-pong`, `/bee-onboard`, `/bee-migrate`, `/bee-browser-test` — focused commands

Subagents are referenced with `@bee-<name>` in prose, or spawned via the `task` tool with `subagent_type: bee-<name>`.

## How it works (quick peek)

Opencode does not auto-discover files inside plugin packages — it only scans a fixed set of config directories (`~/.config/opencode/`, `.opencode/` in the project tree, `~/.opencode/`, `$OPENCODE_CONFIG_DIR`). The install script's only job is to make Bee's content visible at those paths.

Per-file symlinks for agents and commands (rather than a directory symlink) produce clean flat names (`bee-slice-coder` vs. `bee/slice-coder`) because opencode derives names by stripping the first `agents/` or `commands/` path segment. Skills keep their `name:` from frontmatter, so a single directory symlink is enough there.

For the full architecture, see [`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md) §3.5.

## Troubleshooting

- **`/bee-*` commands don't appear** — most likely you ran the installer while opencode was already running. Quit opencode (Ctrl+C in its terminal) and start it again; the registry is only built at server start. To confirm symlinks exist: `ls -la $XDG_CONFIG_HOME/opencode/commands/bee-sdd.md`.
- **Skills don't load** — the `bee` symlink at `~/.config/opencode/skills/bee` must exist and point into this plugin's `bee/skills/`. Re-run the installer.
- **State script fails** — commands invoke `$HOME/.config/opencode/bee/scripts/update-bee-state.sh`. That symlink is created by the installer; if you moved the plugin, re-run it.
- **"refusing to overwrite" during install** — a file already exists at one of the target paths. Inspect it; if it's yours, pick a different name or remove it. If it's a stale link from an older install, delete it and re-run.
