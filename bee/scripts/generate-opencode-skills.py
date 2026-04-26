#!/usr/bin/env python3
"""Generate .opencode/skills/*/SKILL.md from bee/skills/*/SKILL.md.

Single source of truth = skill files in bee/skills/. This script keeps
the opencode twins in sync by applying the same body substitutions used
by the agent and command generators (platform-specific path rewrites,
tool name changes, etc.).

Skills have minimal frontmatter (just name + description) so we pass
through the body with substitutions only.

Run after editing any skill file. Both files should be committed.

Usage:
    python3 bee/scripts/generate-opencode-skills.py              # regenerate all
    python3 bee/scripts/generate-opencode-skills.py <name>       # regenerate one
"""
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))
from opencode_subs import BODY_SUBS

REPO_ROOT = SCRIPT_DIR.parent.parent
SRC_DIR = REPO_ROOT / "bee" / "skills"
OUT_DIR = REPO_ROOT / "bee" / ".opencode" / "skills"


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
            # Strip surrounding YAML quotes so re-serialization doesn't double-wrap.
            if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
                val = val[1:-1]
            if val == "":
                fm[key] = []
                current_list_key = key
            else:
                fm[key] = val
                current_list_key = None
            continue
        current_list_key = None
    return fm, body


def transform(body: str) -> str:
    """Apply platform-specific body substitutions."""
    new_body = body
    for pattern, replacement in BODY_SUBS:
        new_body = pattern.sub(replacement, new_body)
    return new_body


def generate_one(skill_dir: Path) -> Path:
    """Generate opencode skill from Claude skill directory."""
    src = skill_dir / "SKILL.md"
    if not src.is_file():
        print(f"  skipping {skill_dir.name}: no SKILL.md", file=sys.stderr)
        return skill_dir / "SKILL.md"

    text = src.read_text()
    fm, body = parse_frontmatter(text)
    new_body = transform(body)

    # Re-encode frontmatter — opencode reads name from directory structure,
    # but we keep it in frontmatter for consistency.
    name = fm.get("name", skill_dir.name)
    description = fm.get("description", "")

    lines = ["---"]
    lines.append(f"name: {name}")
    # Description may contain colons/quotes — wrap in double quotes.
    if description:
        esc = description.replace("\\", "\\\\").replace('"', '\\"')
        lines.append(f'description: "{esc}"')
    lines.append("---")

    out_dir = OUT_DIR / skill_dir.name
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / "SKILL.md"
    out.write_text("\n".join(lines) + "\n\n" + new_body.lstrip("\n"))
    return out


def main() -> None:
    if not SRC_DIR.is_dir():
        sys.exit(f"source not found: {SRC_DIR}")

    filter_name = sys.argv[1] if len(sys.argv) > 1 else None
    sources = sorted(p for p in SRC_DIR.iterdir() if p.is_dir() and (p / "SKILL.md").is_file())
    if filter_name:
        sources = [p for p in sources if p.name == filter_name]
        if not sources:
            sys.exit(f"no skill named: {filter_name}")

    for skill_dir in sources:
        out = generate_one(skill_dir)
        print(f"  {skill_dir.name}/SKILL.md -> {out.relative_to(REPO_ROOT)}")
    print(f"\nGenerated {len(sources)} opencode skill file(s).")


if __name__ == "__main__":
    main()