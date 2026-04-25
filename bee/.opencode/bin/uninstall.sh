#!/usr/bin/env bash
# Reverse the symlink install done by install.sh.
#
# Only removes bee- prefixed links that point into this plugin package, so
# user-authored agents/commands at the same paths are never touched.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
OPENCODE_DIR="$CONFIG_HOME/opencode"
AGENTS_DST="$OPENCODE_DIR/agents"
COMMANDS_DST="$OPENCODE_DIR/commands"
SKILLS_DST="$OPENCODE_DIR/skills/bee"
SCRIPTS_DST="$OPENCODE_DIR/bee/scripts"

# Remove $1 only if it is a symlink pointing into $PLUGIN_ROOT. Anything else
# is left untouched so we never delete user-owned content.
unlink_if_ours() {
    local dst="$1"
    [[ -L "$dst" ]] || return 0
    local target
    target="$(readlink "$dst")"
    if [[ "$target" == "$PLUGIN_ROOT"/* ]]; then
        rm "$dst"
        echo "    - $(basename "$dst")"
    else
        echo "    ~ $(basename "$dst") points outside plugin ($target) — leaving alone"
    fi
}

unlink_markdown_dir() {
    local dst_dir="$1" count=0
    shopt -s nullglob
    for link in "$dst_dir"/bee-*.md; do
        if [[ -L "$link" ]]; then
            unlink_if_ours "$link" && count=$((count + 1))
        fi
    done
    shopt -u nullglob
}

echo "Uninstalling Bee from $OPENCODE_DIR ..."
echo
echo "Agents:"
unlink_markdown_dir "$AGENTS_DST"
echo "Commands:"
unlink_markdown_dir "$COMMANDS_DST"
echo "Skills:"
unlink_if_ours "$SKILLS_DST"
echo "State scripts:"
unlink_if_ours "$SCRIPTS_DST"
# Clean up empty parent we created during install.
rmdir --ignore-fail-on-non-empty "$OPENCODE_DIR/bee" 2>/dev/null || true
echo
echo "Done."
