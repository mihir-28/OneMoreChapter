#!/usr/bin/env python3
"""Build a reproducible One More Chapter install archive."""

from __future__ import annotations

import argparse
import re
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PLUGIN_DIR = "onemorechapter.koplugin"
FILES = ("README.md", "CHANGELOG.md", "LICENSE")


def read_version() -> str:
    metadata = (ROOT / PLUGIN_DIR / "_meta.lua").read_text(encoding="utf-8")
    match = re.search(r'^\s*version = "([0-9]+\.[0-9]+\.[0-9]+)"\s*,?\s*$', metadata, re.M)
    if not match:
        raise SystemExit("Could not read plugin version from _meta.lua")
    return match.group(1)


def build(output_dir: Path, tag: str | None = None) -> Path:
    version = read_version()
    if tag and tag != f"v{version}":
        raise SystemExit(f"Tag {tag} does not match plugin version v{version}")
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    if not re.search(rf"^## {re.escape(version)}(?:\s|—|-)", changelog, re.M):
        raise SystemExit(f"CHANGELOG.md missing entry for {version}")

    output_dir.mkdir(parents=True, exist_ok=True)
    archive = output_dir / f"onemorechapter-v{version}.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as bundle:
        plugin_root = ROOT / PLUGIN_DIR
        plugin_files = sorted(path for path in plugin_root.rglob("*") if path.is_file())
        if not plugin_files:
            raise SystemExit(f"Installable plugin folder is empty: {PLUGIN_DIR}")
        for path in plugin_files:
            bundle.write(path, path.relative_to(ROOT).as_posix())
        for name in FILES:
            path = ROOT / name
            if not path.is_file():
                raise SystemExit(f"Required release file missing: {name}")
            bundle.write(path, name)
    return archive


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=ROOT / "dist")
    parser.add_argument("--tag", help="Optional Git tag; must match the plugin version")
    args = parser.parse_args()
    print(build(args.output.resolve(), args.tag))


if __name__ == "__main__":
    main()
