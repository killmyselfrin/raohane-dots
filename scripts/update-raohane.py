#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import pathlib
import re
import shutil
import socket
import subprocess
import tarfile
import tempfile
import time
import urllib.error
import urllib.request

REPOSITORY = "killmyselfrin/raohane-dots"
BRANCH = "main"
GIT_REMOTE_URL = f"https://github.com/{REPOSITORY}.git"
ARCHIVE_URL = f"https://codeload.github.com/{REPOSITORY}/tar.gz"
MAX_ARCHIVE_BYTES = 96 * 1024 * 1024
DOWNLOAD_ATTEMPTS = 3
DOWNLOAD_TIMEOUT = 35
REVISION_ATTEMPTS = 2
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


def _log_file() -> pathlib.Path:
    return _state_home() / "raohane/update.log"


def _read_state() -> dict:
    try:
        value = json.loads(_state_file().read_text(encoding="utf-8"))
        return value if isinstance(value, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {}


def _write_state(state: dict) -> None:
    path = _state_file()
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(".tmp")
    temp.write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temp.replace(path)


def _reset_log(revision: str) -> None:
    path = _log_file()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(f"Raohane update transaction -> {revision}\n", encoding="utf-8")


def _log(message: str) -> None:
    path = _log_file()
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(message.rstrip() + "\n")


def _emit(payload: dict) -> None:
    print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), flush=True)


def _request(url: str):
    return urllib.request.Request(url, headers={"User-Agent": "Raohane-Updater/2"})


def _retryable_network_error(exc: BaseException) -> bool:
    if isinstance(exc, urllib.error.HTTPError):
        return exc.code in {408, 429, 500, 502, 503, 504}
    if isinstance(exc, urllib.error.URLError):
        return True
    if isinstance(exc, (TimeoutError, socket.timeout, ConnectionError)):
        return True
    message = str(exc).lower()
    return "timed out" in message or "temporary failure" in message or "connection reset" in message


def _latest_revision() -> str:
    git = shutil.which("git")
    if not git:
        raise RuntimeError("git is required to check for Raohane updates")

    ref = f"refs/heads/{BRANCH}"
    last_error = "GitHub revision check failed"
    for attempt in range(1, REVISION_ATTEMPTS + 1):
        try:
            result = subprocess.run(
                [git, "ls-remote", "--heads", GIT_REMOTE_URL, ref],
                check=True,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=15 if attempt == 1 else 25,
            )
        except subprocess.TimeoutExpired:
            last_error = "GitHub revision check timed out"
            if attempt < REVISION_ATTEMPTS:
                time.sleep(attempt)
                continue
            raise RuntimeError(last_error)
        except subprocess.CalledProcessError as exc:
            detail = (exc.stderr or "").strip().splitlines()
            last_error = detail[-1] if detail else "git ls-remote failed"
            if attempt < REVISION_ATTEMPTS:
                time.sleep(attempt)
                continue
            raise RuntimeError(last_error) from exc

        for line in result.stdout.splitlines():
            fields = line.split()
            if len(fields) >= 2 and fields[1] == ref:
                revision = fields[0].lower()
                if SHA_RE.fullmatch(revision):
                    return revision
        last_error = "GitHub returned an invalid main revision"
        if attempt < REVISION_ATTEMPTS:
            time.sleep(attempt)

    raise RuntimeError(last_error)


def _installed_revision() -> str:
    try:
        value = (_runtime() / "REVISION").read_text(encoding="utf-8").strip().lower()
        if SHA_RE.fullmatch(value):
            return value
    except OSError:
        pass

    value = str(_read_state().get("current_revision", "")).lower()
    return value if SHA_RE.fullmatch(value) else ""


def check() -> int:
    try:
        latest = _latest_revision()
    except Exception as exc:
        _emit({"ok": False, "error": str(exc)})
        return 1

    current = _installed_revision()
    state = _read_state()
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
            "last_error": str(state.get("last_error", "")),
        }
    )
    return 0


def _download_archive(revision: str, destination: pathlib.Path) -> None:
    url = f"{ARCHIVE_URL}/{revision}"
    last_error: BaseException | None = None

    for attempt in range(1, DOWNLOAD_ATTEMPTS + 1):
        destination.unlink(missing_ok=True)
        total = 0
        try:
            with urllib.request.urlopen(_request(url), timeout=DOWNLOAD_TIMEOUT) as response, destination.open("wb") as output:
                while True:
                    chunk = response.read(1024 * 1024)
                    if not chunk:
                        break
                    total += len(chunk)
                    if total > MAX_ARCHIVE_BYTES:
                        raise RuntimeError("update archive exceeds the safety limit")
                    output.write(chunk)
            if total <= 0:
                raise RuntimeError("update archive is empty")
            return
        except Exception as exc:
            destination.unlink(missing_ok=True)
            last_error = exc
            if not _retryable_network_error(exc) or attempt >= DOWNLOAD_ATTEMPTS:
                break
            _log(f"Archive download attempt {attempt}/{DOWNLOAD_ATTEMPTS} failed: {exc}; retrying.")
            time.sleep(attempt * 2)

    if last_error is not None and (isinstance(last_error, (TimeoutError, socket.timeout)) or "timed out" in str(last_error).lower()):
        raise RuntimeError(f"GitHub archive download timed out after {DOWNLOAD_ATTEMPTS} attempts") from last_error
    raise RuntimeError(f"GitHub archive download failed after {DOWNLOAD_ATTEMPTS} attempts: {last_error}") from last_error


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

    for candidate in destination.iterdir():
        if candidate.is_dir() and (candidate / "install-raohane.sh").is_file():
            return candidate
    raise RuntimeError("Raohane source root was not found in the archive")


def _validate_source(root: pathlib.Path) -> None:
    required = [
        "shell.qml",
        "qmldir",
        "VERSION",
        "assets",
        "translations",
        "modules/raohane",
        "modules/raohane/qmldir",
        "modules/raohane/services/qmldir",
        "panelFamilies/RaohaneFamily.qml",
        "defaults/native.json",
        "defaults/themes",
        "install/arch",
        "scripts/install-deps.sh",
        "scripts/prune-runtime.sh",
        "scripts/validate-runtime-payload.sh",
        "scripts/raohane",
    ]
    missing = [entry for entry in required if not (root / entry).exists()]
    if missing:
        raise RuntimeError("update payload is incomplete: " + ", ".join(missing))


def _run(command: list[str], *, cwd: pathlib.Path | None = None) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        command,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    if result.stdout:
        _log(result.stdout)
    if result.returncode != 0:
        tail = [line for line in (result.stdout or "").splitlines() if line.strip()]
        detail = tail[-1] if tail else f"exit status {result.returncode}"
        raise RuntimeError(detail)
    return result


def _missing_dependencies(root: pathlib.Path) -> list[str]:
    result = _run(["bash", str(root / "scripts/install-deps.sh"), "--minimal", "--missing"])
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def _install_dependencies(packages: list[str]) -> None:
    if not packages:
        return
    pkexec = shutil.which("pkexec")
    pacman = shutil.which("pacman")
    if not pkexec or not pacman:
        raise RuntimeError("new core dependencies require pacman and Polkit authorization")
    _log("Installing missing core dependencies: " + ", ".join(packages))
    _run([pkexec, pacman, "-S", "--needed", "--noconfirm", "--", *packages])


def _copy_entry(source: pathlib.Path, destination: pathlib.Path) -> None:
    if source.is_dir():
        shutil.copytree(source, destination, symlinks=True)
    else:
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)


def _build_runtime(source_root: pathlib.Path, revision: str) -> pathlib.Path:
    runtime = _runtime()
    runtime_parent = runtime.parent
    runtime_parent.mkdir(parents=True, exist_ok=True)
    stage = runtime_parent / f".raohane-update-{revision[:12]}-{os.getpid()}"
    shutil.rmtree(stage, ignore_errors=True)
    stage.mkdir(parents=True)

    entries = [
        "shell.qml",
        "qmldir",
        "VERSION",
        "assets",
        "translations",
        "modules/raohane",
        "panelFamilies",
        "defaults/native.json",
        "defaults/themes",
        "install/arch",
        "scripts",
    ]
    for entry in entries:
        source = source_root / entry
        destination = stage / entry
        destination.parent.mkdir(parents=True, exist_ok=True)
        _copy_entry(source, destination)

    _run(["bash", str(source_root / "scripts/prune-runtime.sh"), str(stage)])
    (stage / "REVISION").write_text(revision + "\n", encoding="utf-8")
    _run(["bash", str(source_root / "scripts/validate-runtime-payload.sh"), str(stage)])
    return stage


def _install_cli(source_root: pathlib.Path) -> None:
    target = _home() / ".local/bin/raohane"
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_suffix(".new")
    shutil.copy2(source_root / "scripts/raohane", temporary)
    temporary.chmod(0o755)
    temporary.replace(target)


def _activate_runtime(stage: pathlib.Path, revision: str) -> None:
    runtime = _runtime()
    backup = runtime.parent / f".raohane-backup-{revision[:12]}"
    shutil.rmtree(backup, ignore_errors=True)

    had_runtime = runtime.exists()
    if had_runtime:
        runtime.rename(backup)

    try:
        stage.rename(runtime)
    except Exception:
        if had_runtime and backup.exists() and not runtime.exists():
            backup.rename(runtime)
        raise
    else:
        shutil.rmtree(backup, ignore_errors=True)


def apply(revision: str) -> int:
    revision = revision.strip().lower()
    if not SHA_RE.fullmatch(revision):
        _emit({"ok": False, "error": "invalid requested revision"})
        return 2

    stage: pathlib.Path | None = None
    try:
        latest = _latest_revision()
        if revision != latest:
            revision = latest
        _reset_log(revision)
        _log("Resolving official Raohane archive.")

        with tempfile.TemporaryDirectory(prefix="raohane-update-source-") as temp_raw:
            temp = pathlib.Path(temp_raw)
            archive = temp / "raohane.tar.gz"
            extracted = temp / "source"
            extracted.mkdir()

            _download_archive(revision, archive)
            source_root = _safe_extract(archive, extracted)
            _validate_source(source_root)

            missing = _missing_dependencies(source_root)
            _install_dependencies(missing)

            _log("Building validated runtime staging tree.")
            stage = _build_runtime(source_root, revision)
            _install_cli(source_root)
            _log("Activating validated runtime.")
            _activate_runtime(stage, revision)
            stage = None

        state = _read_state()
        state.update({"current_revision": revision, "last_error": ""})
        _write_state(state)
        _log("Update installed successfully.")
        _emit({"ok": True, "revision": revision, "restart": True})

        subprocess.run(["systemctl", "--user", "restart", "raohane.service"], check=False)
        return 0
    except Exception as exc:
        if stage is not None:
            shutil.rmtree(stage, ignore_errors=True)
        message = str(exc)
        _log("ERROR: " + message)
        state = _read_state()
        state["last_error"] = message
        _write_state(state)
        _emit({"ok": False, "error": message, "log": str(_log_file())})
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
