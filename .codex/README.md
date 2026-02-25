# Bee + Learn + Codex CLI

This directory provides Codex-compatible command prompts for the Bee and Learn Claude plugins.

## Install (cross-platform)

Use the installer script from the repo root:

- macOS/Linux:
  - `python3 .codex/scripts/install_prompts.py`
- Windows (PowerShell):
  - `py .codex/scripts/install_prompts.py`

The script installs Bee prompt files into:

- `$CODEX_HOME/prompts` (if `CODEX_HOME` is set), or
- `~/.codex/prompts` (default)

### Useful options

- Dry run:
  - `python3 .codex/scripts/install_prompts.py --dry-run`
- Overwrite existing prompts:
  - `python3 .codex/scripts/install_prompts.py --force`
- Custom target directory:
  - `python3 .codex/scripts/install_prompts.py --target /path/to/prompts`

## Usage

After install, invoke commands by filename, for example:

- `/bee`
- `/bee-review`
- `/bee-qc`
- `/learn`
- `/learn-start`
- `/learn-next`

## Notes

- These prompts reference Claude plugin files under `bee/` and `learn/`.
- Codex does not support Claude-only tools (`Task`, `AskUserQuestion`, `Skill`). See `.codex/commands/CODEX_COMPATIBILITY.md` for substitutions.
- The Bee and Learn plugins remain unchanged; Codex commands are adapters only.
