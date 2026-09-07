#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request

REPOSITORY = "killmyselfrin/raohane-dots"
BRANCH = "main"
GIT_REMOTE_URL = f"https://github.com/{REPOSITORY}.git"
ARCHIVE_URL = f"https://codeload.github.com/{REPOSITORY}/tar.gz"
MAX_ARCHIVE_BYTES = 96 * 1024 * 1024
SHA_RE = re.compile(r"^[0-9a-f]{40}$")


def _home() -> pathlib.Path:
    return pathlib.Path.home()


def _config_home() -> pathlib.Path:
    return pathlib.Path(os.environ.get("XDG_CONFIG_HOME", _home() / ".config"))


def _state_home() -> pathlib.Path:
    return pathlib.Path(os.environ.get("XDG_STATE_HOME", _home() / ".local/state"))


def _runtime() -> pathlib.Path:
    return _config_home() / "quickshell/raohane"


def _state_file() -> pathlib.Path:
    return _state_home() / "raohane/updater.json"


def _read_state() -> dict:
    path = _state_file()
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
        return value if isinstance(value, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {}


def _write_state(state: dict) -> None:
    path = _state_file()
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(".tmp")
    temp.write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temp.replace(path)


def _request(url: str):
    return urllib.request.Request(
        url,
        headers={
            "User-Agent": "Raohane-Updater/1",
        },
    )


def _latest_revision() -> str:
    git = shutil.which("git")
    if not git:
        raise RuntimeError("git is required to check for Raohane updates")

    ref = f"refs/heads/{BRANCH}"
    try:
        result = subprocess.run(
            [git, "ls-remote", "--heads", GIT_REMOTE_URL, ref],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=15,
        )
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError("GitHub revision check timed out") from exc
    except subprocess.CalledProcessError as exc:
        detail = (exc.stderr or "").strip().splitlines()
        message = detail[-1] if detail else "git ls-remote failed"
        raise RuntimeError(message) from exc

    revision = ""
    for line in result.stdout.splitlines():
        fields = line.split()
        if len(fields) >= 2 and fields[1] == ref:
            revision = fields[0].lower()
            break

    if not SHA_RE.fullmatch(revision):
        raise RuntimeError("GitHub returned an invalid main revision")
    return revision


def _installed_revision() -> str:
    revision_path = _runtime() / "REVISION"
    try:
        value = revision_path.read_text(encoding="utf-8").strip().lower()
        if SHA_RE.fullmatch(value):
            return value
    except OSError:
        pass

    state_value = str(_read_state().get("current_revision", "")).lower()
    return state_value if SHA_RE.fullmatch(state_value) else ""


def _emit(payload: dict) -> None:
    print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), flush=True)


def check() -> int:
    try:
        latest = _latest_revision()
    except Exception as exc:
        _emit({"ok": False, "error": str(exc)})
        return 1

    current = _installed_revision()
    state = _read_state()

    # Fresh guided installations from main predate the revision marker. Establish
    # the first remote SHA as their baseline instead of immediately reinstalling
    # the same checkout. Every updater-driven installation writes REVISION.
    if not current:
        current = latest
        state["current_revision"] = current
        state["baseline_initialized"] = True
        _write_state(state)

    _emit(
        {
            "ok": True,
            "repository": REPOSITORY,
            "channel": BRANCH,
            "current": current,
            "latest": latest,
            "available": current != latest,
        }
    )
    return 0


def _download_archive(revision: str, destination: pathlib.Path) -> None:
    request = _request(f"{ARCHIVE_URL}/{revision}")
    total = 0
    with urllib.request.urlopen(request, timeout=20) as response, destination.open("wb") as output:
        while True:
            chunk = response.read(1024 * 1024)
            if not chunk:
                break
            total += len(chunk)
            if total > MAX_ARCHIVE_BYTES:
                raise RuntimeError("update archive exceeds the safety limit")
            output.write(chunk)


def _safe_extract(archive: pathlib.Path, destination: pathlib.Path) -> pathlib.Path:
    destination = destination.resolve()
    with tarfile.open(archive, "r:gz") as tar:
        members = tar.getmembers()
        if not members:
            raise RuntimeError("update archive is empty")

        for member in members:
            name = pathlib.PurePosixPath(member.name)
            if name.is_absolute() or ".." in name.parts:
                raise RuntimeError("unsafe path in update archive")
            if member.isdev() or member.isfifo():
                raise RuntimeError("unsupported special file in update archive")

        tar.extractall(destination, members=members, filter="data")

    candidates = [path for path in destination.iterdir() if path.is_dir()]
    for candidate in candidates:
        if (candidate / "install-raohane.sh").is_file():
            return candidate
    raise RuntimeError("Raohane source root was not found in the archive")


def _validate_source(root: pathlib.Path) -> None:
    required = [
        "install-raohane.sh",
        "shell.qml",
        "VERSION",
        "qmldir",
        "modules/raohane/qmldir",
        "modules/raohane/services/qmldir",
        "scripts/install-deps.sh",
        "scripts/validate-runtime-payload.sh",
    ]
    missing = [entry for entry in required if not (root / entry).exists()]
    if missing:
        raise RuntimeError("update payload is incomplete: " + ", ".join(missing))


def _missing_dependencies(root: pathlib.Path) -> list[str]:
    result = subprocess.run(
        ["bash", str(root / "scripts/install-deps.sh"), "--full", "--missing"],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def _install_dependencies(packages: list[str]) -> None:
    if not packages:
        return
    pkexec = shutil.which("pkexec")
    pacman = shutil.which("pacman")
    if not pkexec or not pacman:
        raise RuntimeError("new dependencies require pacman and pkexec/polkit authorization")
    subprocess.run(
        [pkexec, pacman, "-S", "--needed", "--noconfirm", "--", *packages],
        check=True,
    )


def apply(revision: str) -> int:
    revision = revision.strip().lower()
    if not SHA_RE.fullmatch(revision):
        _emit({"ok": False, "error": "invalid requested revision"})
        return 2

    try:
        # Refuse a stale UI request if main moved after the check. Updating to the
        # newest official revision is safer than installing an already-obsolete SHA.
        latest = _latest_revision()
        if revision != latest:
            revision = latest

        with tempfile.TemporaryDirectory(prefix="raohane-update-") as temp_raw:
            temp = pathlib.Path(temp_raw)
            archive = temp / "raohane.tar.gz"
            source_root_dir = temp / "source"
            source_root_dir.mkdir()

            _download_archive(revision, archive)
            source_root = _safe_extract(archive, source_root_dir)
            _validate_source(source_root)

            missing = _missing_dependencies(source_root)
            _install_dependencies(missing)

            subprocess.run(
                [
                    "bash",
                    str(source_root / "install-raohane.sh"),
                    "--no-deps",
                    "--no-login-theme",
                    "--no-start",
                ],
                check=True,
                cwd=source_root,
            )

            runtime = _runtime()
            runtime.mkdir(parents=True, exist_ok=True)
            (runtime / "REVISION").write_text(revision + "\n", encoding="utf-8")

        state = _read_state()
        state.update({"current_revision": revision, "last_error": ""})
        _write_state(state)
        _emit({"ok": True, "revision": revision, "restart": True})

        # update-raohane.py is launched in its own transient user unit, so it can
        # safely restart the shell service without killing the updater itself.
        subprocess.run(["systemctl", "--user", "restart", "raohane.service"], check=False)
        return 0
    except Exception as exc:
        state = _read_state()
        state["last_error"] = str(exc)
        _write_state(state)
        _emit({"ok": False, "error": str(exc)})
        return 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Raohane standalone updater")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("check")
    apply_parser = sub.add_parser("apply")
    apply_parser.add_argument("--revision", required=True)
    args = parser.parse_args()

    if args.command == "check":
        return check()
    return apply(args.revision)


if __name__ == "__main__":
    raise SystemExit(main())
