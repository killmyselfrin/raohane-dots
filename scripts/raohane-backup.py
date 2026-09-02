#!/usr/bin/env python3
"""Portable backup/restore for Raohane-owned settings.

The archive intentionally contains Raohane configuration/state only. Generated
Hyprland files and caches are excluded because they can be recreated from the
native configuration after restore.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import pathlib
import shutil
import socket
import tempfile
import urllib.parse
import uuid
import zipfile

FORMAT_NAME = "raohane-backup"
FORMAT_VERSION = 1


def home_dir() -> pathlib.Path:
    return pathlib.Path.home()


def xdg_path(variable: str, fallback: pathlib.Path) -> pathlib.Path:
    value = os.environ.get(variable, "").strip()
    return pathlib.Path(value).expanduser() if value else fallback


def config_dir() -> pathlib.Path:
    return xdg_path("XDG_CONFIG_HOME", home_dir() / ".config") / "raohane"


def state_dir() -> pathlib.Path:
    return xdg_path("XDG_STATE_HOME", home_dir() / ".local" / "state") / "raohane"


def data_dir() -> pathlib.Path:
    return xdg_path("XDG_DATA_HOME", home_dir() / ".local" / "share") / "raohane"


def normalize_local_path(value: object) -> pathlib.Path | None:
    if value is None:
        return None
    raw = str(value).strip()
    if not raw:
        return None
    if raw.startswith("file://"):
        parsed = urllib.parse.urlparse(raw)
        raw = urllib.parse.unquote(parsed.path)
    path = pathlib.Path(raw).expanduser()
    try:
        return path.resolve(strict=False)
    except OSError:
        return path


def read_json(path: pathlib.Path) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
        return value if isinstance(value, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {}


def write_json(path: pathlib.Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def nested_get(document: dict, keys: tuple[str, ...]) -> object:
    current: object = document
    for key in keys:
        if not isinstance(current, dict):
            return None
        current = current.get(key)
    return current


def nested_set(document: dict, keys: tuple[str, ...], value: object) -> None:
    current = document
    for key in keys[:-1]:
        child = current.get(key)
        if not isinstance(child, dict):
            child = {}
            current[key] = child
        current = child
    current[keys[-1]] = value


def safe_archive_name(path: pathlib.Path) -> str:
    suffix = path.suffix.lower()
    if len(suffix) > 12 or not suffix.replace(".", "").isalnum():
        suffix = ""
    return suffix


def iter_owned_files(root: pathlib.Path):
    if not root.is_dir():
        return
    for path in sorted(root.rglob("*")):
        if path.is_file() and not path.is_symlink():
            yield path


def same_path(left: pathlib.Path, right: pathlib.Path) -> bool:
    try:
        return left.resolve(strict=False) == right.resolve(strict=False)
    except OSError:
        return left.absolute() == right.absolute()


def ensure_output_suffix(path: pathlib.Path) -> pathlib.Path:
    if path.name.endswith(".raohane-backup"):
        return path
    return path.with_name(path.name + ".raohane-backup")


def validate_native_document(document: dict, *, context: str) -> None:
    if not isinstance(document, dict) or not document:
        raise ValueError(f"{context} does not contain a valid native.json")
    schema = document.get("schemaVersion")
    if not isinstance(schema, int) or schema <= 0:
        raise ValueError(f"{context} native.json does not contain a valid schemaVersion")


def create_archive(output: pathlib.Path, *, include_state: bool = True) -> pathlib.Path:
    output = ensure_output_suffix(output.expanduser())
    output.parent.mkdir(parents=True, exist_ok=True)

    cfg = config_dir()
    state = state_dir()
    native_path = cfg / "native.json"
    native = read_json(native_path)
    validate_native_document(native, context="Current Raohane configuration")

    timestamp = dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()
    backup_id = dt.datetime.now().strftime("%Y%m%d-%H%M%S") + "-" + uuid.uuid4().hex[:8]
    manifest: dict = {
        "format": FORMAT_NAME,
        "version": FORMAT_VERSION,
        "backupId": backup_id,
        "createdAt": timestamp,
        "host": socket.gethostname(),
        "schemaVersion": native.get("schemaVersion"),
        "assets": [],
    }

    asset_specs = [
        ("wallpaper", ("wallpaper", "path")),
        ("lock-wallpaper", ("wallpaper", "lockPath")),
        ("profile-avatar", ("profile", "avatarPath")),
    ]

    seen_assets: dict[pathlib.Path, str] = {}

    temporary = output.with_name(output.name + ".tmp")
    try:
        temporary.unlink(missing_ok=True)
        with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
            for path in iter_owned_files(cfg) or []:
                # A user may deliberately save an archive inside ~/.config/raohane.
                # Never recursively archive the output or its in-progress temp file.
                if same_path(path, output) or same_path(path, temporary):
                    continue
                archive.write(path, "config/" + path.relative_to(cfg).as_posix())

            if include_state:
                for path in iter_owned_files(state) or []:
                    # Do not recursively embed old restore-point archives.
                    try:
                        relative = path.relative_to(state)
                    except ValueError:
                        continue
                    if relative.parts and relative.parts[0] == "restore-points":
                        continue
                    archive.write(path, "state/" + relative.as_posix())

            for kind, keys in asset_specs:
                original = normalize_local_path(nested_get(native, keys))
                if original is None or not original.is_file() or original.is_symlink():
                    continue
                try:
                    resolved = original.resolve()
                except OSError:
                    resolved = original

                archive_path = seen_assets.get(resolved)
                if archive_path is None:
                    archive_path = f"assets/{len(seen_assets) + 1:02d}-{kind}{safe_archive_name(original)}"
                    archive.write(original, archive_path)
                    seen_assets[resolved] = archive_path

                manifest["assets"].append({
                    "kind": kind,
                    "configPath": list(keys),
                    "originalPath": str(original),
                    "archivePath": archive_path,
                })

            archive.writestr(
                "manifest.json",
                json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
            )

        os.replace(temporary, output)
    finally:
        temporary.unlink(missing_ok=True)

    return output


def validate_member_name(name: str) -> None:
    path = pathlib.PurePosixPath(name)
    if path.is_absolute() or ".." in path.parts:
        raise ValueError(f"Unsafe archive entry: {name}")


def validate_archive(archive: zipfile.ZipFile) -> tuple[dict, dict]:
    names = set(archive.namelist())
    for member in archive.infolist():
        validate_member_name(member.filename)

    try:
        manifest = json.loads(archive.read("manifest.json").decode("utf-8"))
    except (KeyError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError("Backup does not contain a valid manifest.json") from error

    if not isinstance(manifest, dict) or manifest.get("format") != FORMAT_NAME:
        raise ValueError("This file is not a Raohane backup")

    version = int(manifest.get("version", 0))
    if version <= 0:
        raise ValueError("Backup format version is invalid")
    if version > FORMAT_VERSION:
        raise ValueError("Backup was created by a newer Raohane backup format")

    if "config/native.json" not in names:
        raise ValueError("Backup is incomplete: config/native.json is missing")
    try:
        native = json.loads(archive.read("config/native.json").decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError("Backup contains an invalid config/native.json") from error
    validate_native_document(native, context="Backup")

    assets = manifest.get("assets", [])
    if not isinstance(assets, list):
        raise ValueError("Backup manifest assets field is invalid")
    for asset in assets:
        if not isinstance(asset, dict):
            raise ValueError("Backup manifest contains an invalid asset entry")
        archive_path = str(asset.get("archivePath") or "")
        if not archive_path:
            raise ValueError("Backup manifest contains an asset without archivePath")
        validate_member_name(archive_path)
        if archive_path not in names:
            raise ValueError(f"Backup asset is missing: {archive_path}")

    return manifest, native


def restore_archive(source: pathlib.Path) -> tuple[pathlib.Path, pathlib.Path | None]:
    source = source.expanduser()
    if not source.is_file():
        raise FileNotFoundError(source)

    cfg = config_dir()
    cfg_parent = cfg.parent
    state = state_dir()
    data = data_dir()
    cfg_parent.mkdir(parents=True, exist_ok=True)
    state.mkdir(parents=True, exist_ok=True)
    data.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(source, "r") as archive:
        # Validate the incoming archive completely before touching current state.
        manifest, _ = validate_archive(archive)

        restore_point: pathlib.Path | None = None
        if cfg.exists() and (cfg / "native.json").is_file():
            restore_points = state / "restore-points"
            restore_points.mkdir(parents=True, exist_ok=True)
            name = "before-restore-" + dt.datetime.now().strftime("%Y%m%d-%H%M%S") + ".raohane-backup"
            restore_point = create_archive(restore_points / name, include_state=False)

        backup_id = str(manifest.get("backupId") or uuid.uuid4().hex[:12])
        asset_target = data / "restored-assets" / backup_id

        with tempfile.TemporaryDirectory(prefix=".raohane-restore-", dir=cfg_parent) as temp_root_raw:
            temp_root = pathlib.Path(temp_root_raw)
            restored_cfg = temp_root / "config"
            restored_state = temp_root / "state"
            restored_cfg.mkdir(parents=True, exist_ok=True)

            for member in archive.infolist():
                name = pathlib.PurePosixPath(member.filename)
                if member.is_dir():
                    continue
                if name.parts and name.parts[0] == "config":
                    relative = pathlib.Path(*name.parts[1:])
                    destination = restored_cfg / relative
                elif name.parts and name.parts[0] == "state":
                    relative = pathlib.Path(*name.parts[1:])
                    destination = restored_state / relative
                else:
                    continue
                destination.parent.mkdir(parents=True, exist_ok=True)
                with archive.open(member, "r") as src, destination.open("wb") as dst:
                    shutil.copyfileobj(src, dst)

            restored_native_path = restored_cfg / "native.json"
            restored_native = read_json(restored_native_path)
            validate_native_document(restored_native, context="Extracted backup")
            restored_assets: dict[str, pathlib.Path] = {}

            for asset in manifest.get("assets", []):
                archive_path = str(asset.get("archivePath") or "")
                keys = asset.get("configPath")
                kind = str(asset.get("kind") or "asset")
                if not isinstance(keys, list) or not keys:
                    continue

                target_name = pathlib.Path(archive_path).name
                destination = asset_target / target_name
                destination.parent.mkdir(parents=True, exist_ok=True)
                with archive.open(archive_path, "r") as src, destination.open("wb") as dst:
                    shutil.copyfileobj(src, dst)
                restored_assets[kind] = destination
                nested_set(restored_native, tuple(str(key) for key in keys), str(destination))

            if "wallpaper" in restored_assets:
                nested_set(restored_native, ("wallpaper", "directory"), str(asset_target))
            write_json(restored_native_path, restored_native)

            old_cfg = cfg_parent / (".raohane-old-" + uuid.uuid4().hex[:8])
            if cfg.exists():
                os.replace(cfg, old_cfg)
            try:
                os.replace(restored_cfg, cfg)
            except Exception:
                if old_cfg.exists() and not cfg.exists():
                    os.replace(old_cfg, cfg)
                raise
            else:
                if old_cfg.exists():
                    shutil.rmtree(old_cfg, ignore_errors=True)

            if restored_state.exists():
                for path in iter_owned_files(restored_state) or []:
                    relative = path.relative_to(restored_state)
                    destination = state / relative
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(path, destination)

    native = cfg / "native.json"
    if native.exists():
        os.utime(native, None)
    monitors = cfg / "monitors.json"
    if monitors.exists():
        os.utime(monitors, None)

    return cfg, restore_point


def inspect_archive(source: pathlib.Path) -> dict:
    with zipfile.ZipFile(source.expanduser(), "r") as archive:
        manifest, _ = validate_archive(archive)
        return manifest


def main() -> int:
    parser = argparse.ArgumentParser(description="Export and restore Raohane settings")
    subparsers = parser.add_subparsers(dest="command", required=True)

    export_parser = subparsers.add_parser("export", help="Create a portable backup")
    export_parser.add_argument("--output", required=True, type=pathlib.Path)

    restore_parser = subparsers.add_parser("restore", help="Restore a portable backup")
    restore_parser.add_argument("--input", required=True, type=pathlib.Path)

    inspect_parser = subparsers.add_parser("inspect", help="Print backup metadata")
    inspect_parser.add_argument("--input", required=True, type=pathlib.Path)

    args = parser.parse_args()

    if args.command == "export":
        output = create_archive(args.output)
        print(json.dumps({"ok": True, "operation": "export", "path": str(output)}, ensure_ascii=False))
        return 0

    if args.command == "restore":
        cfg, restore_point = restore_archive(args.input)
        print(json.dumps({
            "ok": True,
            "operation": "restore",
            "config": str(cfg),
            "restorePoint": str(restore_point) if restore_point else "",
        }, ensure_ascii=False))
        return 0

    manifest = inspect_archive(args.input)
    print(json.dumps(manifest, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:  # Keep CLI/QML integration predictable.
        print(json.dumps({"ok": False, "error": str(error)}, ensure_ascii=False))
        raise SystemExit(1)
