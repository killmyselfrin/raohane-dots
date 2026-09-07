#!/usr/bin/env python3
"""Inspect the active Linux graphics stack without changing it.

The probe is intentionally conservative:
- it detects the GPU(s) and kernel driver(s) actually in use;
- on Arch-family systems it checks updates only for graphics packages that are
  already installed;
- it never recommends switching driver families;
- it never performs a partial package upgrade.

JSON output is consumed by Raohane QML. Human output powers `raohane doctor graphics`.
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
    "mesa",
    "lib32-mesa",
    "vulkan-radeon",
    "lib32-vulkan-radeon",
    "amdvlk",
    "lib32-amdvlk",
    "libva-mesa-driver",
    "lib32-libva-mesa-driver",
    "mesa-vdpau",
    "lib32-mesa-vdpau",
    "xf86-video-amdgpu",
}

INTEL_PACKAGES = {
    "mesa",
    "lib32-mesa",
    "vulkan-intel",
    "lib32-vulkan-intel",
    "intel-media-driver",
    "libva-intel-driver",
    "vpl-gpu-rt",
    "xf86-video-intel",
}

NOUVEAU_PACKAGES = {
    "mesa",
    "lib32-mesa",
    "vulkan-nouveau",
    "lib32-vulkan-nouveau",
    "libva-mesa-driver",
    "lib32-libva-mesa-driver",
    "mesa-vdpau",
    "lib32-mesa-vdpau",
}


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


def os_release() -> dict[str, str]:
    values: dict[str, str] = {}
    try:
        for raw in Path("/etc/os-release").read_text(encoding="utf-8", errors="replace").splitlines():
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


def clean_gpu_model(description: str) -> str:
    value = re.sub(r"\s+\[[0-9a-fA-F]{4}:[0-9a-fA-F]{4}\]\s*$", "", description)
    value = re.sub(r"\s+\(rev [^)]+\)\s*$", "", value)
    value = re.sub(r"^NVIDIA Corporation\s+", "", value, flags=re.I)
    value = re.sub(r"^Advanced Micro Devices, Inc\.\s+\[AMD/ATI\]\s+", "", value, flags=re.I)
    value = re.sub(r"^Intel Corporation\s+", "", value, flags=re.I)
    return value.strip()


def gpu_vendor(description: str) -> str:
    lowered = description.lower()
    if "nvidia" in lowered:
        return "nvidia"
    if "advanced micro devices" in lowered or "amd/ati" in lowered or "amd " in lowered:
        return "amd"
    if "intel" in lowered:
        return "intel"
    return "other"


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
            if not re.search(r"\b(VGA compatible controller|3D controller|Display controller)\b", line, re.I):
                continue
            match = re.match(r"^(\S+)\s+.+?:\s+(.+)$", line)
            if not match:
                continue
            address, description = match.groups()
            current = {
                "pci_address": address,
                "vendor": gpu_vendor(description),
                "model": clean_gpu_model(description),
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
                item.strip() for item in stripped.split(":", 1)[1].split(",") if item.strip()
            ]

    return gpus


def installed_packages() -> dict[str, str]:
    if not shutil.which("pacman"):
        return {}
    result = run(["pacman", "-Q"], timeout=20)
    packages: dict[str, str] = {}
    if result.returncode != 0:
        return packages
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


def is_nvidia_package(name: str) -> bool:
    lowered = name.lower()
    return "nvidia" in lowered or lowered.startswith("cuda")


def package_candidates(gpus: list[dict[str, Any]], installed: dict[str, str]) -> set[str]:
    candidates: set[str] = set()

    for gpu in gpus:
        vendor = str(gpu.get("vendor", ""))
        driver = str(gpu.get("kernel_driver", "")).lower()

        if vendor == "nvidia" and (driver == "nvidia" or driver.startswith("nvidia_")):
            candidates.update(name for name in installed if is_nvidia_package(name))
        elif vendor == "nvidia" and driver == "nouveau":
            candidates.update(NOUVEAU_PACKAGES & installed.keys())
        elif vendor == "amd" or driver == "amdgpu":
            candidates.update(AMD_PACKAGES & installed.keys())
        elif vendor == "intel" or driver in {"i915", "xe"}:
            candidates.update(INTEL_PACKAGES & installed.keys())

    # If the hardware is visible but no driver is bound yet, report matching
    # already-installed packages without using that as permission to switch the
    # system to another driver family.
    if not candidates:
        vendors = {str(gpu.get("vendor", "")) for gpu in gpus}
        if "nvidia" in vendors:
            candidates.update(name for name in installed if is_nvidia_package(name))
        if "amd" in vendors:
            candidates.update(AMD_PACKAGES & installed.keys())
        if "intel" in vendors:
            candidates.update(INTEL_PACKAGES & installed.keys())

    return candidates


UPDATE_RE = re.compile(r"^(\S+)\s+(\S+)\s+->\s+(\S+)(?:\s+.*)?$")


def parse_updates(text: str) -> dict[str, dict[str, str]]:
    updates: dict[str, dict[str, str]] = {}
    for raw in text.splitlines():
        line = raw.strip()
        match = UPDATE_RE.match(line)
        if not match:
            continue
        name, old, new = match.groups()
        updates[name] = {"name": name, "installed": old, "candidate": new}
    return updates


def check_arch_updates() -> tuple[dict[str, dict[str, str]], str, bool, str]:
    """Return (updates, source, fresh, error)."""
    if shutil.which("checkupdates"):
        result = run(["checkupdates", "--nocolor"], timeout=90)
        if result.returncode in (0, 2):
            return parse_updates(result.stdout), "checkupdates", True, ""
        error = result.stderr.strip().splitlines()[-1] if result.stderr.strip() else "checkupdates failed"
    else:
        error = "checkupdates is not installed"

    # pacman -Qu never refreshes the sync databases. Positive matches are still
    # useful, but an empty result is not proof that the graphics stack is current.
    fallback = run(["pacman", "-Qu"], timeout=25)
    if fallback.returncode in (0, 1):
        return parse_updates(fallback.stdout), "pacman-local-db", False, error
    fallback_error = fallback.stderr.strip().splitlines()[-1] if fallback.stderr.strip() else "pacman -Qu failed"
    return {}, "unavailable", False, f"{error}; {fallback_error}" if error else fallback_error


def nvidia_driver_version(gpus: list[dict[str, Any]]) -> str:
    if not any(str(gpu.get("kernel_driver", "")).lower().startswith("nvidia") for gpu in gpus):
        return ""
    if not shutil.which("nvidia-smi"):
        return ""
    result = run(
        ["nvidia-smi", "--query-gpu=driver_version", "--format=csv,noheader"],
        timeout=10,
    )
    if result.returncode != 0:
        return ""
    versions = sorted({line.strip() for line in result.stdout.splitlines() if line.strip()})
    return ", ".join(versions)


def build_report() -> dict[str, Any]:
    os_info = os_release()
    gpus = detect_gpus()
    installed = installed_packages()
    foreign = foreign_packages()
    relevant_names = package_candidates(gpus, installed)
    driver_version = nvidia_driver_version(gpus)
    notes: list[str] = []

    arch_family = bool(shutil.which("pacman")) and (
        os_info["id"] in {"arch", "cachyos", "endeavouros", "manjaro", "garuda"}
        or "arch" in os_info["id_like"].split()
    )

    update_map: dict[str, dict[str, str]] = {}
    check_source = "unsupported"
    check_fresh = False
    check_error = ""

    if arch_family:
        update_map, check_source, check_fresh, check_error = check_arch_updates()
        if check_source == "pacman-local-db":
            notes.append(
                "Fresh repository metadata was unavailable; results use the current local pacman sync database."
            )
            notes.append("Install pacman-contrib to enable the safe fresh checkupdates path.")
        elif check_source == "unavailable":
            notes.append("Package update metadata could not be checked.")
    elif os_info["id"] == "nixos" or "nixos" in os_info["id_like"].split():
        notes.append("NixOS graphics updates follow the configured nixpkgs/system generation; Raohane will not mutate it.")
    else:
        notes.append("Automatic graphics package freshness checks are currently available only on Arch-family systems.")

    packages: list[dict[str, Any]] = []
    graphics_updates: list[dict[str, str]] = []
    foreign_relevant: list[str] = []

    for name in sorted(relevant_names):
        update = update_map.get(name)
        is_foreign = name in foreign
        record: dict[str, Any] = {
            "name": name,
            "installed": installed.get(name, ""),
            "candidate": update["candidate"] if update else installed.get(name, ""),
            "update": bool(update),
            "source": "foreign" if is_foreign else "repo",
        }
        packages.append(record)
        if update:
            graphics_updates.append(
                {
                    "name": name,
                    "installed": update["installed"],
                    "candidate": update["candidate"],
                }
            )
        if is_foreign:
            foreign_relevant.append(name)

    if foreign_relevant:
        notes.append(
            "Foreign/AUR graphics packages cannot be verified against official pacman repositories: "
            + ", ".join(foreign_relevant)
        )

    if not gpus:
        status = "unknown"
        notes.append("No VGA/3D/Display PCI device could be identified with lspci.")
    elif graphics_updates:
        status = "updates_available"
    elif foreign_relevant and check_fresh:
        status = "unverified"
    elif arch_family and check_fresh:
        status = "current"
    elif arch_family:
        status = "unknown"
    else:
        status = "unsupported"

    gpu_summary = "; ".join(
        f"{gpu.get('model', 'Unknown GPU')} ({gpu.get('kernel_driver') or 'driver unbound'})" for gpu in gpus
    )

    return {
        "ok": True,
        "status": status,
        "supported": arch_family,
        "os": os_info,
        "gpus": gpus,
        "gpu_summary": gpu_summary,
        "active_drivers": sorted(
            {str(gpu.get("kernel_driver", "")) for gpu in gpus if str(gpu.get("kernel_driver", ""))}
        ),
        "driver_version": driver_version,
        "packages": packages,
        "updates": graphics_updates,
        "update_available": bool(graphics_updates),
        "check_source": check_source,
        "check_fresh": check_fresh,
        "check_error": check_error,
        "update_command": FULL_UPGRADE_COMMAND if arch_family else "",
        "notes": notes,
    }


def print_human(report: dict[str, Any]) -> None:
    print("Graphics hardware")
    gpus = report.get("gpus", [])
    if gpus:
        for gpu in gpus:
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
    packages = report.get("packages", [])
    if not packages:
        print("  [--] no matching installed graphics packages were identified")
    for package in packages:
        source = " [foreign/AUR]" if package.get("source") == "foreign" else ""
        suffix = f" -> {package['candidate']}" if package.get("update") else ""
        marker = "!!" if package.get("update") else "ok"
        print(f"  [{marker}] {package['name']} {package['installed']}{suffix}{source}")

    print("\nUpdate check")
    print(f"  status: {report.get('status', 'unknown')}")
    print(f"  source: {report.get('check_source', 'unknown')}")
    if report.get("check_error"):
        print(f"  note: {report['check_error']}")

    updates = report.get("updates", [])
    if updates:
        print("  graphics updates:")
        for update in updates:
            print(f"    - {update['name']}: {update['installed']} -> {update['candidate']}")
        print("\nArch supports full system upgrades, not partial driver upgrades.")
        print(f"  suggested command: {report.get('update_command', FULL_UPGRADE_COMMAND)}")
    elif report.get("status") == "current":
        print("  [ok] installed repository graphics packages are current")

    for note in report.get("notes", []):
        print(f"  [--] {note}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Inspect the active Raohane graphics driver stack")
    parser.add_argument("--json", action="store_true", help="emit one JSON object")
    args = parser.parse_args()

    try:
        report = build_report()
    except Exception as error:  # Defensive boundary: diagnostics must stay readable.
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
    else:
        if not report.get("ok"):
            print(f"Graphics check failed: {report.get('error', 'unknown error')}")
            return 1
        print_human(report)
    return 0 if report.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main())
