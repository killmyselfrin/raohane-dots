#!/usr/bin/env python3
"""Generate a deterministic dependency inventory from vendored Arch PKGBUILDs.

This parser deliberately does *not* execute PKGBUILD shell code. It extracts the
static dependency arrays we need for coverage auditing and keeps the raw token
alongside a normalized Arch package key.
"""

from __future__ import annotations

import argparse
import csv
import re
import shlex
from dataclasses import dataclass
from pathlib import Path

ARRAY_NAMES = ("depends", "makedepends", "checkdepends", "optdepends")
DEFAULT_SELECTED_META = {
    "illogical-impulse-audio",
    "illogical-impulse-backlight",
    "illogical-impulse-basic",
    "illogical-impulse-fonts-themes",
    "illogical-impulse-kde",
    "illogical-impulse-portal",
    "illogical-impulse-python",
    "illogical-impulse-screencapture",
    "illogical-impulse-toolkit",
    "illogical-impulse-widgets",
    "illogical-impulse-hyprland",
    "illogical-impulse-microtex-git",
    "illogical-impulse-quickshell-git",
    "illogical-impulse-bibata-modern-classic-bin",
}

VERSION_OP_RE = re.compile(r"\s*(>=|<=|=|>|<).*$")


@dataclass(frozen=True)
class Row:
    source_meta_package: str
    dependency_type: str
    package: str
    raw_dependency: str
    selected_by_upstream_installer: str
    source_file: str


def strip_shell_comment(line: str) -> str:
    """Remove an unquoted Bash # comment from a single line."""
    out: list[str] = []
    quote: str | None = None
    escaped = False
    for char in line:
        if escaped:
            out.append(char)
            escaped = False
            continue
        if char == "\\" and quote != "'":
            out.append(char)
            escaped = True
            continue
        if quote:
            out.append(char)
            if char == quote:
                quote = None
            continue
        if char in ("'", '"'):
            quote = char
            out.append(char)
            continue
        if char == "#":
            break
        out.append(char)
    return "".join(out)


def find_array_body(text: str, name: str) -> str | None:
    match = re.search(rf"(?m)^\s*{re.escape(name)}\s*=\s*\(", text)
    if not match:
        return None

    start = match.end()
    depth = 1
    quote: str | None = None
    escaped = False
    i = start
    while i < len(text):
        char = text[i]
        if escaped:
            escaped = False
            i += 1
            continue
        if char == "\\" and quote != "'":
            escaped = True
            i += 1
            continue
        if quote:
            if char == quote:
                quote = None
            i += 1
            continue
        if char in ("'", '"'):
            quote = char
            i += 1
            continue
        if char == "#":
            newline = text.find("\n", i)
            if newline == -1:
                return None
            i = newline + 1
            continue
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return text[start:i]
        i += 1
    raise ValueError(f"unterminated {name}=() array")


def tokenize_array(body: str) -> list[str]:
    cleaned = "\n".join(strip_shell_comment(line) for line in body.splitlines())
    lexer = shlex.shlex(cleaned, posix=True)
    lexer.whitespace_split = True
    lexer.commenters = ""
    return [token.strip() for token in lexer if token.strip()]


def normalize_package(raw: str, dep_type: str) -> str:
    token = raw.strip()
    if dep_type == "optdepends":
        # Arch optdepends entries are conventionally "package: description".
        token = token.split(":", 1)[0].strip()
    token = VERSION_OP_RE.sub("", token).strip()
    return token


def parse_pkgbuild(path: Path, root: Path) -> list[Row]:
    text = path.read_text(encoding="utf-8")
    meta = path.parent.name
    selected = "yes" if meta in DEFAULT_SELECTED_META else "no"
    rows: list[Row] = []

    for dep_type in ARRAY_NAMES:
        body = find_array_body(text, dep_type)
        if body is None:
            continue
        for raw in tokenize_array(body):
            package = normalize_package(raw, dep_type)
            if not package:
                continue
            rows.append(
                Row(
                    source_meta_package=meta,
                    dependency_type=dep_type,
                    package=package,
                    raw_dependency=raw,
                    selected_by_upstream_installer=selected,
                    source_file=str(path.relative_to(root)),
                )
            )
    return rows


def write_tsv(rows: list[Row], output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = [field.name for field in Row.__dataclass_fields__.values()]
    with output.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        for row in sorted(
            rows,
            key=lambda r: (
                r.source_meta_package,
                r.dependency_type,
                r.package,
                r.raw_dependency,
            ),
        ):
            writer.writerow(row.__dict__)


def write_summary(rows: list[Row], output: Path, pkgbuild_count: int) -> None:
    selected_rows = [r for r in rows if r.selected_by_upstream_installer == "yes"]
    unique_runtime = sorted({r.package for r in selected_rows if r.dependency_type == "depends"})
    unique_build = sorted(
        {r.package for r in selected_rows if r.dependency_type in {"makedepends", "checkdepends"}}
    )
    unique_optional = sorted({r.package for r in selected_rows if r.dependency_type == "optdepends"})
    meta = sorted({r.source_meta_package for r in selected_rows})

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        "\n".join(
            [
                "# Generated upstream dependency baseline",
                "",
                "This file is generated from the pinned vendored `end-4/dots-hyprland` PKGBUILDs.",
                "Do not edit it manually; use Raohane overlay metadata for project-specific policy.",
                "",
                f"- PKGBUILDs scanned: **{pkgbuild_count}**",
                f"- Upstream installer meta-packages represented: **{len(meta)}**",
                f"- Unique selected runtime dependencies: **{len(unique_runtime)}**",
                f"- Unique selected build/check dependencies: **{len(unique_build)}**",
                f"- Unique selected optional dependencies: **{len(unique_optional)}**",
                "",
                "## Selected upstream meta-packages",
                "",
                *[f"- `{name}`" for name in meta],
                "",
                "## Policy",
                "",
                "Raohane may add packages, metadata, diagnostics, service rules and hardware profiles,",
                "but must not silently reduce this baseline while the corresponding upstream feature remains active.",
                "",
            ]
        ),
        encoding="utf-8",
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source",
        default="upstream/illogical-impulse-system/sdata/dist-arch",
        help="vendored dist-arch directory",
    )
    parser.add_argument(
        "--output",
        default="manifests/upstream-package-baseline.tsv",
        help="generated TSV path",
    )
    parser.add_argument(
        "--summary",
        default="manifests/upstream-package-baseline.md",
        help="generated human-readable summary",
    )
    args = parser.parse_args()

    root = Path.cwd().resolve()
    source = (root / args.source).resolve()
    if not source.is_dir():
        raise SystemExit(f"source directory not found: {source}")

    pkgbuilds = sorted(source.glob("*/PKGBUILD"))
    if not pkgbuilds:
        raise SystemExit(f"no PKGBUILDs found under {source}")

    rows: list[Row] = []
    for path in pkgbuilds:
        rows.extend(parse_pkgbuild(path, root))

    if not rows:
        raise SystemExit("no dependency rows parsed")

    write_tsv(rows, root / args.output)
    write_summary(rows, root / args.summary, len(pkgbuilds))
    print(f"scanned {len(pkgbuilds)} PKGBUILDs; generated {len(rows)} dependency rows")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
