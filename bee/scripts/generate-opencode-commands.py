#!/usr/bin/env python3
"""Generate .opencode/commands/*.md from bee/commands/*.md.

Single source of truth = Claude command files in bee/commands/. This script
keeps the opencode twins in sync by:
  - stripping Claude-only frontmatter (argument-hint, allowed-tools, model)
  - keeping only opencode-supported fields (description, agent, subtask)
  - rewriting body references that differ between platforms:
      * ${CLAUDE_PLUGIN_ROOT}/scripts/... -> $HOME/.config/opencode/bee/scripts/...
        (opencode install symlinks bee/scripts/ there)
      * bee:<agent-name> -> bee-<agent-name> (install symlinks use bee- prefix
        because opencode derives agent names from filenames, not a namespace)

Run after editing any Claude command file. Both files should be committed.

Usage:
    python3 bee/scripts/generate-opencode-commands.py              # regenerate all
    python3 bee/scripts/generate-opencode-commands.py <name>       # regenerate one
"""
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))
from opencode_subs import BODY_SUBS

REPO_ROOT = SCRIPT_DIR.parent.parent
SRC_DIR = REPO_ROOT / "bee" / "commands"
OUT_DIR = REPO_ROOT / "bee" / ".opencode" / "commands"

# Opencode CommandConfig frontmatter keys (from opencode/src/config/command.ts).
# Everything else is dropped silently.
OPENCODE_KEYS = {"description", "agent", "model", "subtask"}


def parse_frontmatter(text: str) -> tuple[dict, str]:
    """Parse minimal frontmatter. Same contract as the agent generator.

    Returns (frontmatter_dict, body).
    """
    m = re.match(r"^---\n(.*?)\n---\n?(.*)", text, re.DOTALL)
    if not m:
        return {}, text
    raw, body = m.group(1), m.group(2)

    fm: dict = {}
    current_list_key = None
    for line in raw.split("\n"):
        if not line.strip():
            current_list_key = None
            continue
        list_m = re.match(r"^\s+-\s+(.*)$", line)
        if list_m and current_list_key:
            fm[current_list_key].append(list_m.group(1).strip())
            continue
        key_m = re.match(r"^([A-Za-z_][A-Za-z0-9_-]*):\s*(.*)$", line)
        if key_m:
            key, val = key_m.group(1), key_m.group(2)
            val = val.strip()
            if val == "":
                fm[key] = []
                current_list_key = key
            else:
                fm[key] = val
                current_list_key = None
            continue
        current_list_key = None
    return fm, body


def transform(fm: dict, body: str) -> tuple[dict, str]:
    """Keep only opencode-supported frontmatter keys; rewrite body refs."""
    new_fm: dict = {k: v for k, v in fm.items() if k in OPENCODE_KEYS}
    # Default command to run under the build agent so file edits etc. work.
    # Individual commands can override by setting `agent:` in their frontmatter.
    new_fm.setdefault("agent", "build")

    new_body = body
    for pattern, replacement in BODY_SUBS:
        new_body = pattern.sub(replacement, new_body)
    return new_fm, new_body


def render_frontmatter(fm: dict) -> str:
    lines = ["---"]
    # Stable key order: description first, then agent, then everything else.
    order = ["description", "agent", "model", "subtask"]
    for k in order:
        if k not in fm:
            continue
        v = fm[k]
        if isinstance(v, list):
            lines.append(f"{k}:")
            for item in v:
                lines.append(f"  - {item}")
        else:
            sval = str(v)
            if ":" in sval or "#" in sval or sval.startswith(("'", '"')):
                esc = sval.replace("\\", "\\\\").replace('"', '\\"')
                lines.append(f'{k}: "{esc}"')
            else:
                lines.append(f"{k}: {sval}")
    lines.append("---")
    return "\n".join(lines)


def generate_one(src: Path) -> Path:
    fm, body = parse_frontmatter(src.read_text())
    new_fm, new_body = transform(fm, body)

    out = OUT_DIR / src.name
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(render_frontmatter(new_fm) + "\n\n" + new_body.lstrip("\n"))
    return out


def main() -> None:
    if not SRC_DIR.is_dir():
        sys.exit(f"source not found: {SRC_DIR}")

    filter_name = sys.argv[1] if len(sys.argv) > 1 else None
    sources = sorted(p for p in SRC_DIR.glob("*.md") if p.is_file())
    if filter_name:
        sources = [p for p in sources if p.stem == filter_name]
        if not sources:
            sys.exit(f"no command named: {filter_name}")

    for src in sources:
        out = generate_one(src)
        print(f"  {src.name} -> {out.relative_to(REPO_ROOT)}")
    print(f"\nGenerated {len(sources)} opencode command file(s).")


if __name__ == "__main__":
    main()
