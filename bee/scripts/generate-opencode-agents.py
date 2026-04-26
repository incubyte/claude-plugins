#!/usr/bin/env python3
"""Generate .opencode/agents/*.md from bee/agents/*.md.

Single source of truth = Claude agent files in bee/agents/. This script keeps
the opencode twins in sync by transforming frontmatter to opencode's schema
and prepending an explicit skill-load instruction to the body (opencode does
not auto-load skills from frontmatter the way Claude Code does).

Run after editing any Claude agent file. Both files should be committed.

Usage:
    python3 bee/scripts/generate-opencode-agents.py              # regenerate all
    python3 bee/scripts/generate-opencode-agents.py <name>       # regenerate one
"""
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))
from opencode_subs import BODY_SUBS

REPO_ROOT = SCRIPT_DIR.parent.parent
SRC_DIR = REPO_ROOT / "bee" / "agents"
OUT_DIR = REPO_ROOT / "bee" / ".opencode" / "agents"

CATEGORY_BY_PREFIX = [
    ("review-", "reviewing"),
    ("tdd-planner-", "planning"),
    ("tdd-test-writer", "deep-work"),
    ("tdd-coder", "deep-work"),
    ("tdd-ping-pong", "deep-work"),
    ("slice-", "deep-work"),
    ("spec-builder", "planning"),
    ("discovery", "planning"),
    ("architecture-", "planning"),
    ("context-gatherer", "planning"),
    ("domain-language-", "planning"),
    ("quick-fix", "quick-work"),
    ("tidy", "quick-work"),
    ("design-agent", "visual"),
    ("browser-verifier", "visual"),
    ("onboard", "teaching"),
    ("recap", "teaching"),
    ("qc-planner", "planning"),
    ("sdd-verifier", "reviewing"),
    ("reviewer", "reviewing"),
    ("verifier", "reviewing"),
    ("programmer", "deep-work"),
]


def infer_category(name: str) -> str:
    for prefix, cat in CATEGORY_BY_PREFIX:
        if name == prefix or name.startswith(prefix):
            return cat
    return "deep-work"


def parse_frontmatter(text: str) -> tuple[dict, str]:
    """Parse minimal frontmatter, tolerating non-YAML blocks like <example>.

    Returns (frontmatter_dict, body). Frontmatter is a best-effort extraction
    of top-level key/value and key/list pairs. Unrecognised lines are ignored
    (including <example>...</example> blocks that Claude agents embed inside
    frontmatter).
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
        # Unrecognised line (e.g., <example>, prose inside frontmatter).
        # Silently drop — these are Claude-specific embellishments that
        # opencode does not need.
        current_list_key = None
    return fm, body


def transform(fm: dict, body: str, name: str) -> tuple[dict, str]:
    skills = fm.get("skills") if isinstance(fm.get("skills"), list) else []
    category = infer_category(name)

    description = fm.get("description", "")
    # Description from Claude often has trailing prose (examples, etc.) that
    # got dropped during parsing. Keep the first clean sentence.
    description = description.strip()

    new_fm: dict = {
        "description": description,
        "mode": "subagent",
        "category": category,
    }

    # Intentionally do NOT write a `name:` field. Opencode's ConfigAgent reads
    # frontmatter via `{ name, ...md.data, prompt }`, so a frontmatter `name`
    # would clobber the filename-derived name — and the install symlinks are
    # the only thing that prefixes agents with `bee-`. Letting filename win
    # keeps cross-references (e.g. Task subagent_type: "bee-slice-coder")
    # consistent with what opencode actually registers.
    #
    # Intentionally do NOT write a `model:` field. The user picks the model at
    # the opencode TUI / session level; agent-level pinning would override
    # their choice. `category` stays as metadata for opt-in future routing.

    # Opencode does not auto-load skills. Prepend an explicit instruction.
    new_body = body.lstrip("\n")
    if skills:
        preamble = (
            "Before starting, load these skills using the skill tool: "
            + ", ".join(f"`{s}`" for s in skills)
            + ".\n\n"
        )
        new_body = preamble + new_body

    for pattern, replacement in BODY_SUBS:
        new_body = pattern.sub(replacement, new_body)

    return new_fm, new_body


def render_frontmatter(fm: dict) -> str:
    lines = ["---"]
    for k, v in fm.items():
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
    name = src.stem
    new_fm, new_body = transform(fm, body, name)

    out = OUT_DIR / src.name
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(render_frontmatter(new_fm) + "\n\n" + new_body)
    return out


def main() -> None:
    if not SRC_DIR.is_dir():
        sys.exit(f"source not found: {SRC_DIR}")

    filter_name = sys.argv[1] if len(sys.argv) > 1 else None
    sources = sorted(p for p in SRC_DIR.glob("*.md") if p.is_file())
    if filter_name:
        sources = [p for p in sources if p.stem == filter_name]
        if not sources:
            sys.exit(f"no agent named: {filter_name}")

    for src in sources:
        out = generate_one(src)
        print(f"  {src.name} -> {out.relative_to(REPO_ROOT)}")
    print(f"\nGenerated {len(sources)} opencode agent file(s).")


if __name__ == "__main__":
    main()
