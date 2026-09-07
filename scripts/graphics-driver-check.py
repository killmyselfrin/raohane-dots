#!/usr/bin/env python3
"""Inspect the active Linux graphics stack without changing it.

Raohane deliberately detects the driver family already in use instead of
choosing one for the user. On Arch-family systems this probe checks only
already-installed graphics packages and recommends a normal full system
upgrade when repository updates exist.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
from pathlib import Path
from typing import Any

FULL_UPGRADE_COMMAND = "sudo pacman -Syu"

AMD_PACKAGES = {
    "mesa", "lib32-mesa", "vulkan-radeon", "lib32-vulkan-radeon",
    "amdvlk", "lib32-amdvlk", "libva-mesa-driver",
    "lib32-libva-mesa-driver", "mesa-vdpau", "lib32-mesa-vdpau",
    "xf86-video-amdgpu",
}
INTEL_PACKAGES = {
    "mesa", "lib32-mesa", "vulkan-intel", "lib32-vulkan-intel",
    "intel-media-driver", "libva-intel-driver", "vpl-gpu-rt",
    "xf86-video-intel",
}
NOUVEAU_PACKAGES = {
    "mesa", "lib32-mesa", "vulkan-nouveau", "lib32-vulkan-nouveau",
    "libva-mesa-driver", "lib32-libva-mesa-driver", "mesa-vdpau",
    "lib32-mesa-vdpau",
}
ARCH_IDS = {"arch", "cachyos", "endeavouros", "manjaro", "garuda"}
UPDATE_RE = re.compile(r"^(\S+)\s+(\S+)\s+->\s+(\S+)(?:\s+.*)?$")


def run(command: list[str], timeout: int = 25) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(
            command,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
            env={**os.environ, "LC_ALL": "C", "LANG": "C"},
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        return subprocess.CompletedProcess(command, 127, "", str(error))


def read_os_release() -> dict[str, str]:
    values: dict[str, str] = {}
    try:
        for raw in Path("/etc/os-release").read_text(
            encoding="utf-8", errors="replace"
        ).splitlines():
            if "=" not in raw:
                continue
            key, value = raw.split("=", 1)
            values[key] = value.strip().strip('"')
    except OSError:
        pass
    return {
        "id": values.get("ID", "unknown").lower(),
        "name": values.get("PRETTY_NAME", values.get("NAME", "Unknown Linux")),
        "id_like": values.get("ID_LIKE", "").lower(),
    }


def vendor_for(description: str) -> str:
    lowered = description.lower()
    if "nvidia" in lowered:
        return "nvidia"
    if "advanced micro devices" in lowered or "amd/ati" in lowered:
        return "amd"
    if "intel" in lowered:
        return "intel"
    return "other"


def clean_model(description: str) -> str:
    value = re.sub(r"\s+\[[0-9a-fA-F]{4}:[0-9a-fA-F]{4}\]\s*$", "", description)
    value = re.sub(r"\s+\(rev [^)]+\)\s*$", "", value)
    value = re.sub(r"^NVIDIA Corporation\s+", "", value, flags=re.I)
    value = re.sub(
        r"^Advanced Micro Devices, Inc\.\s+\[AMD/ATI\]\s+", "", value, flags=re.I
    )
    value = re.sub(r"^Intel Corporation\s+", "", value, flags=re.I)
    return value.strip()


def detect_gpus() -> list[dict[str, Any]]:
    if not shutil.which("lspci"):
        return []
    result = run(["lspci", "-nnk"], timeout=10)
    if result.returncode != 0:
        return []

    gpus: list[dict[str, Any]] = []
    current: dict[str, Any] | None = None
    for line in result.stdout.splitlines():
        if line and not line[0].isspace():
            current = None
            if not re.search(
                r"\b(VGA compatible controller|3D controller|Display controller)\b",
                line,
                re.I,
            ):
                continue
            match = re.match(r"^(\S+)\s+.+?:\s+(.+)$", line)
            if not match:
                continue
            address, description = match.groups()
            current = {
                "pci_address": address,
                "vendor": vendor_for(description),
                "model": clean_model(description),
                "kernel_driver": "",
                "kernel_modules": [],
            }
            gpus.append(current)
            continue

        if current is None:
            continue
        stripped = line.strip()
        if stripped.startswith("Kernel driver in use:"):
            current["kernel_driver"] = stripped.split(":", 1)[1].strip()
        elif stripped.startswith("Kernel modules:"):
            current["kernel_modules"] = [
                item.strip()
                for item in stripped.split(":", 1)[1].split(",")
                if item.strip()
            ]
    return gpus


def pacman_packages() -> dict[str, str]:
    if not shutil.which("pacman"):
        return {}
    result = run(["pacman", "-Q"], timeout=20)
    if result.returncode != 0:
        return {}
    packages: dict[str, str] = {}
    for line in result.stdout.splitlines():
        parts = line.split(maxsplit=1)
        if len(parts) == 2:
            packages[parts[0]] = parts[1]
    return packages


def foreign_packages() -> set[str]:
    if not shutil.which("pacman"):
        return set()
    result = run(["pacman", "-Qmq"], timeout=15)
    if result.returncode not in (0, 1):
        return set()
    return {line.strip() for line in result.stdout.splitlines() if line.strip()}


def nvidia_package(name: str) -> bool:
    lowered = name.lower()
    return "nvidia" in lowered or lowered.startswith("cuda")


def relevant_packages(
    gpus: list[dict[str, Any]], installed: dict[str, str]
) -> set[str]:
    selected: set[str] = set()
    installed_names = installed.keys()

    for gpu in gpus:
        vendor = str(gpu.get("vendor", ""))
        driver = str(gpu.get("kernel_driver", "")).lower()
        if vendor == "nvidia" and (driver == "nvidia" or driver.startswith("nvidia_")):
            selected.update(name for name in installed_names if nvidia_package(name))
        elif vendor == "nvidia" and driver == "nouveau":
            selected.update(NOUVEAU_PACKAGES & installed_names)
        elif vendor == "amd" or driver == "amdgpu":
            selected.update(AMD_PACKAGES & installed_names)
        elif vendor == "intel" or driver in {"i915", "xe"}:
            selected.update(INTEL_PACKAGES & installed_names)

    # Hardware may be visible before a kernel driver is bound. In that case we
    # may inspect already-installed matching packages, but never install or
    # switch to a different driver family.
    if not selected:
        vendors = {str(gpu.get("vendor", "")) for gpu in gpus}
        if "nvidia" in vendors:
            selected.update(name for name in installed_names if nvidia_package(name))
        if "amd" in vendors:
            selected.update(AMD_PACKAGES & installed_names)
        if "intel" in vendors:
            selected.update(INTEL_PACKAGES & installed_names)
    return selected


def parse_updates(text: str) -> dict[str, dict[str, str]]:
    updates: dict[str, dict[str, str]] = {}
    for raw in text.splitlines():
        match = UPDATE_RE.match(raw.strip())
        if not match:
            continue
        name, installed, candidate = match.groups()
        updates[name] = {
            "name": name,
            "installed": installed,
            "candidate": candidate,
        }
    return updates


def final_error(result: subprocess.CompletedProcess[str], fallback: str) -> str:
    stderr = result.stderr.strip()
    return stderr.splitlines()[-1] if stderr else fallback


def check_arch_updates() -> tuple[dict[str, dict[str, str]], str, bool, str]:
    """Return updates, source label, freshness and a non-fatal diagnostic."""
    check_error = ""
    if shutil.which("checkupdates"):
        result = run(["checkupdates", "--nocolor"], timeout=90)
        if result.returncode == 0:
            return parse_updates(result.stdout), "checkupdates", True, ""
        if (
            result.returncode in (1, 2)
            and not result.stdout.strip()
            and not result.stderr.strip()
        ):
            return {}, "checkupdates", True, ""
        check_error = final_error(result, "checkupdates failed")
    else:
        check_error = "checkupdates is not installed"

    # pacman -Qu does not refresh repository metadata. Positive matches are
    # useful, but an empty result is not proof that the graphics stack is fresh.
    fallback = run(["pacman", "-Qu"], timeout=25)
    if fallback.returncode in (0, 1):
        return parse_updates(fallback.stdout), "pacman-local-db", False, check_error
    fallback_error = final_error(fallback, "pacman -Qu failed")
    if check_error:
        fallback_error = f"{check_error}; {fallback_error}"
    return {}, "unavailable", False, fallback_error


def nvidia_driver_version(gpus: list[dict[str, Any]]) -> str:
    if not any(
        str(gpu.get("kernel_driver", "")).lower().startswith("nvidia")
        for gpu in gpus
    ):
        return ""
    if not shutil.which("nvidia-smi"):
        return ""
    result = run(
        ["nvidia-smi", "--query-gpu=driver_version", "--format=csv,noheader"],
        timeout=10,
    )
    if result.returncode != 0:
        return ""
    return ", ".join(
        sorted({line.strip() for line in result.stdout.splitlines() if line.strip()})
    )


def is_arch_family(os_info: dict[str, str]) -> bool:
    return bool(shutil.which("pacman")) and (
        os_info["id"] in ARCH_IDS or "arch" in os_info["id_like"].split()
    )


def build_report() -> dict[str, Any]:
    os_info = read_os_release()
    gpus = detect_gpus()
    installed = pacman_packages()
    foreign = foreign_packages()
    selected = relevant_packages(gpus, installed)
    arch_family = is_arch_family(os_info)
    notes: list[str] = []

    update_map: dict[str, dict[str, str]] = {}
    source = "unsupported"
    fresh = False
    check_error = ""
    if arch_family:
        update_map, source, fresh, check_error = check_arch_updates()
        if source == "pacman-local-db":
            notes.append(
                "Fresh repository metadata was unavailable; results use the current local pacman sync database."
            )
            notes.append(
                "Install pacman-contrib to enable the safe fresh checkupdates path."
            )
        elif source == "unavailable":
            notes.append("Package update metadata could not be checked.")
    elif os_info["id"] == "nixos" or "nixos" in os_info["id_like"].split():
        notes.append(
            "NixOS graphics updates follow the configured nixpkgs/system generation; Raohane will not mutate it."
        )
    else:
        notes.append(
            "Automatic graphics package freshness checks are currently available only on Arch-family systems."
        )

    packages: list[dict[str, Any]] = []
    updates: list[dict[str, str]] = []
    foreign_selected: list[str] = []
    for name in sorted(selected):
        update = update_map.get(name)
        is_foreign = name in foreign
        packages.append(
            {
                "name": name,
                "installed": installed.get(name, ""),
                "candidate": update["candidate"] if update else installed.get(name, ""),
                "update": bool(update),
                "source": "foreign" if is_foreign else "repo",
            }
        )
        if update:
            updates.append(update)
        if is_foreign:
            foreign_selected.append(name)

    if foreign_selected:
        notes.append(
            "Foreign/AUR graphics packages cannot be verified against official pacman repositories: "
            + ", ".join(foreign_selected)
        )

    if not gpus:
        status = "unknown"
        notes.append("No VGA/3D/Display PCI device could be identified with lspci.")
    elif updates:
        status = "updates_available"
    elif foreign_selected and fresh:
        status = "unverified"
    elif arch_family and fresh:
        status = "current"
    elif arch_family:
        status = "unknown"
    else:
        status = "unsupported"

    return {
        "ok": True,
        "status": status,
        "supported": arch_family,
        "os": os_info,
        "gpus": gpus,
        "gpu_summary": "; ".join(
            f"{gpu.get('model', 'Unknown GPU')} ({gpu.get('kernel_driver') or 'driver unbound'})"
            for gpu in gpus
        ),
        "active_drivers": sorted(
            {
                str(gpu.get("kernel_driver", ""))
                for gpu in gpus
                if str(gpu.get("kernel_driver", ""))
            }
        ),
        "driver_version": nvidia_driver_version(gpus),
        "packages": packages,
        "updates": updates,
        "update_available": bool(updates),
        "check_source": source,
        "check_fresh": fresh,
        "check_error": check_error,
        "update_command": FULL_UPGRADE_COMMAND if arch_family else "",
        "notes": notes,
    }


def print_human(report: dict[str, Any]) -> None:
    print("Graphics hardware")
    if report["gpus"]:
        for gpu in report["gpus"]:
            print(f"  GPU: {gpu.get('model', 'Unknown')}")
            print(f"    vendor: {gpu.get('vendor', 'unknown')}")
            print(f"    kernel driver: {gpu.get('kernel_driver') or 'unbound/unknown'}")
            modules = gpu.get("kernel_modules") or []
            if modules:
                print(f"    available modules: {', '.join(modules)}")
    else:
        print("  [--] no GPU detected through lspci")

    if report.get("driver_version"):
        print(f"  NVIDIA userspace driver: {report['driver_version']}")

    print("\nInstalled graphics stack")
    if not report["packages"]:
        print("  [--] no matching installed graphics packages were identified")
    for package in report["packages"]:
        marker = "!!" if package["update"] else "ok"
        suffix = f" -> {package['candidate']}" if package["update"] else ""
        foreign = " [foreign/AUR]" if package["source"] == "foreign" else ""
        print(f"  [{marker}] {package['name']} {package['installed']}{suffix}{foreign}")

    print("\nUpdate check")
    print(f"  status: {report['status']}")
    print(f"  source: {report['check_source']}")
    if report.get("check_error"):
        print(f"  note: {report['check_error']}")
    if report["updates"]:
        print("  graphics updates:")
        for update in report["updates"]:
            print(
                f"    - {update['name']}: {update['installed']} -> {update['candidate']}"
            )
        print("\nArch supports full system upgrades, not partial driver upgrades.")
        print(f"  suggested command: {report['update_command']}")
    elif report["status"] == "current":
        print("  [ok] installed repository graphics packages are current")
    for note in report["notes"]:
        print(f"  [--] {note}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Inspect the active Raohane graphics driver stack"
    )
    parser.add_argument("--json", action="store_true", help="emit one JSON object")
    args = parser.parse_args()
    try:
        report = build_report()
    except Exception as error:  # Diagnostics should fail readable, not crash QML.
        report = {
            "ok": False,
            "status": "error",
            "error": str(error),
            "gpus": [],
            "packages": [],
            "updates": [],
            "update_available": False,
            "check_source": "error",
            "check_fresh": False,
            "update_command": "",
            "notes": [],
        }

    if args.json:
        print(json.dumps(report, ensure_ascii=False, separators=(",", ":")))
    elif report.get("ok"):
        print_human(report)
    else:
        print(f"Graphics check failed: {report.get('error', 'unknown error')}")
    return 0 if report.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main())
