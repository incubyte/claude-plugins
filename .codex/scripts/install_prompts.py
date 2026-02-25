#!/usr/bin/env python3
"""Install Bee/Learn Codex prompt files into the user's Codex prompts directory.

Default target directory:
- $CODEX_HOME/prompts if CODEX_HOME is set
- ~/.codex/prompts otherwise
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import sys


def default_target() -> Path:
    codex_home = os.environ.get("CODEX_HOME")
    if codex_home:
        return Path(codex_home).expanduser() / "prompts"
    return Path.home() / ".codex" / "prompts"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Install Bee/Learn Codex commands into a Codex prompts directory."
    )
    parser.add_argument(
        "--target",
        type=Path,
        default=default_target(),
        help="Destination prompts directory (default: $CODEX_HOME/prompts or ~/.codex/prompts)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing files in the target directory.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be copied without writing files.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    repo_root = Path(__file__).resolve().parents[2]
    source_dir = repo_root / ".codex" / "commands"

    if not source_dir.exists():
        print(f"error: source directory not found: {source_dir}", file=sys.stderr)
        return 1

    # Install executable command prompts plus compatibility guidance
    # referenced by those prompts.
    sources = sorted(
        [
            path
            for path in source_dir.glob("*.md")
            if (
                path.name.startswith(("bee", "learn"))
                or path.name == "CODEX_COMPATIBILITY.md"
            )
            and path.name != "README.md"
        ]
    )
    if not sources:
        print(f"error: no Bee/Learn prompt files found in {source_dir}", file=sys.stderr)
        return 1

    target = args.target.expanduser().resolve()

    print(f"source: {source_dir}")
    print(f"target: {target}")
    print(f"mode: {'dry-run' if args.dry_run else 'install'}")

    if not args.dry_run:
        target.mkdir(parents=True, exist_ok=True)

    copied = 0
    skipped = 0

    for src in sources:
        dst = target / src.name
        if dst.exists() and not args.force:
            skipped += 1
            print(f"skip   {src.name} (exists; use --force to overwrite)")
            continue

        action = "copy" if not dst.exists() else "update"
        print(f"{action:6} {src.name}")

        if not args.dry_run:
            shutil.copy2(src, dst)
        copied += 1

    print(f"\nsummary: copied={copied}, skipped={skipped}, total={len(sources)}")

    if skipped > 0 and not args.force:
        print("note: rerun with --force to overwrite existing prompts")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
