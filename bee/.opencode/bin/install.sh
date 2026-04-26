#!/usr/bin/env bash
# Install the Bee plugin into opencode by creating symlinks from the user's
# opencode config dir into this plugin package.
#
# Run directly:   bash bee/.opencode/bin/install.sh
# Re-runs:        safe and idempotent — re-linking an already-correct link is a no-op.
# Uninstall:      bash bee/.opencode/bin/uninstall.sh
#
# Opencode does not auto-discover markdown agents/commands/skills bundled inside
# a plugin package; it only scans ~/.config/opencode/{agents,commands,skills}
# (and a few peer dirs). So we materialize bee's content in the user's config
# dir via symlinks. Updates to the plugin flow through transparently; uninstall
# removes only the bee-prefixed links.

set -euo pipefail

# --- locate the plugin package ------------------------------------------------
# $0 lives at  <plugin>/.opencode/bin/install.sh
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"   # <...>/bee/
OPENCODE_SRC="$PLUGIN_ROOT/.opencode"

# --- locate the opencode config dir ------------------------------------------
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
OPENCODE_DIR="$CONFIG_HOME/opencode"

AGENTS_DST="$OPENCODE_DIR/agents"
COMMANDS_DST="$OPENCODE_DIR/commands"
SKILLS_DST="$OPENCODE_DIR/skills"
SCRIPTS_DST="$OPENCODE_DIR/bee/scripts"

mkdir -p "$AGENTS_DST" "$COMMANDS_DST" "$SKILLS_DST" "$(dirname "$SCRIPTS_DST")"

# --- helpers -----------------------------------------------------------------

# Link $2 -> $1. If $2 already points at $1, no-op. If $2 exists but points
# elsewhere (or is a regular file), refuse and print a clear error so we never
# clobber user-owned content.
link_one() {
    local src="$1" dst="$2"
    if [[ -L "$dst" ]]; then
        local current
        current="$(readlink "$dst")"
        if [[ "$current" == "$src" ]]; then
            return 0
        fi
        echo "    ! $dst already points to $current — refusing to overwrite" >&2
        return 1
    fi
    if [[ -e "$dst" ]]; then
        echo "    ! $dst exists and is not a symlink — refusing to overwrite" >&2
        return 1
    fi
    ln -s "$src" "$dst"
    echo "    + $(basename "$dst")"
}

# Link all <src-dir>/*.md into <dst-dir>/bee-<name>.md.
link_markdown_dir() {
    local src_dir="$1" dst_dir="$2" count=0 skipped=0
    shopt -s nullglob
    for file in "$src_dir"/*.md; do
        local name
        name="$(basename "$file")"
        if link_one "$file" "$dst_dir/bee-$name"; then
            count=$((count + 1))
        else
            skipped=$((skipped + 1))
        fi
    done
    shopt -u nullglob
    echo "  linked $count (skipped $skipped) into $dst_dir"
}

echo "Installing Bee into $OPENCODE_DIR ..."
echo
echo "Agents:"
link_markdown_dir "$OPENCODE_SRC/agents" "$AGENTS_DST"
echo
echo "Commands:"
link_markdown_dir "$OPENCODE_SRC/commands" "$COMMANDS_DST"
echo
echo "Skills:"
link_one "$OPENCODE_SRC/skills" "$SKILLS_DST/bee" && \
    echo "  skills/ directory linked" || \
    echo "  skills link skipped"
echo
echo "State scripts:"
link_one "$PLUGIN_ROOT/scripts" "$SCRIPTS_DST" && \
    echo "  scripts/ directory linked" || \
    echo "  scripts link skipped"
echo
echo "Done. Open opencode — you should see /bee-* commands and @bee-* agents."
