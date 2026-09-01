#!/usr/bin/env python3
"""Low-overhead /proc process snapshot for the native Raohane Task Manager.

The helper intentionally avoids procps/ps so opening Task Manager does not create
short-lived `ps` processes that can report misleadingly high lifetime CPU usage.
It emits the tab-separated format consumed by RaohaneProcesses.qml.
"""

from __future__ import annotations

import os
import pwd
from pathlib import Path

PROC = Path("/proc")
SELF_PID = os.getpid()
UID = os.getuid()
USERNAME = pwd.getpwuid(UID).pw_name
CLK_TCK = float(os.sysconf(os.sysconf_names["SC_CLK_TCK"]))


def read_memory() -> tuple[float, float]:
    total_kib = 0.0
    available_kib = 0.0
    try:
        with (PROC / "meminfo").open("r", encoding="utf-8") as handle:
            for line in handle:
                if line.startswith("MemTotal:"):
                    total_kib = float(line.split()[1])
                elif line.startswith("MemAvailable:"):
                    available_kib = float(line.split()[1])
                if total_kib and available_kib:
                    break
    except (OSError, ValueError, IndexError):
        pass

    total_mib = total_kib / 1024.0
    used_mib = max(0.0, (total_kib - available_kib) / 1024.0)
    return used_mib, total_mib


def read_uptime() -> float:
    try:
        return float((PROC / "uptime").read_text(encoding="utf-8").split()[0])
    except (OSError, ValueError, IndexError):
        return 0.0


def read_status(pid_path: Path) -> tuple[int, float] | None:
    uid = -1
    rss_kib = 0.0
    try:
        with (pid_path / "status").open("r", encoding="utf-8") as handle:
            for line in handle:
                if line.startswith("Uid:"):
                    uid = int(line.split()[1])
                    if uid != UID:
                        return None
                elif line.startswith("VmRSS:"):
                    rss_kib = float(line.split()[1])
    except (OSError, ValueError, IndexError):
        return None

    if uid != UID:
        return None
    return uid, rss_kib


def read_process(pid_path: Path, uptime: float, total_mib: float):
    try:
        pid = int(pid_path.name)
    except ValueError:
        return None
    if pid <= 1 or pid == SELF_PID:
        return None

    status = read_status(pid_path)
    if status is None:
        return None
    _, rss_kib = status

    try:
        stat_line = (pid_path / "stat").read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None

    # /proc/<pid>/stat keeps comm in parentheses and comm may contain spaces.
    left = stat_line.find("(")
    right = stat_line.rfind(")")
    if left < 0 or right <= left:
        return None

    command = stat_line[left + 1 : right].replace("\t", " ").replace("\n", " ").strip()
    fields = stat_line[right + 2 :].split()
    if len(fields) < 20:
        return None

    if command in {"quickshell", "qs"}:
        return None

    try:
        ppid = int(fields[1])
        utime_ticks = float(fields[11])
        stime_ticks = float(fields[12])
        start_ticks = float(fields[19])
    except (ValueError, IndexError):
        return None

    elapsed = max(0.0, uptime - (start_ticks / CLK_TCK)) if uptime > 0 else 0.0
    cpu_seconds = (utime_ticks + stime_ticks) / CLK_TCK
    cpu_percent = (cpu_seconds / elapsed * 100.0) if elapsed > 0.05 else 0.0
    rss_mib = max(0.0, rss_kib / 1024.0)
    memory_percent = (rss_mib / total_mib * 100.0) if total_mib > 0 else 0.0

    return (
        pid,
        max(0, ppid),
        USERNAME,
        max(0.0, cpu_percent),
        max(0.0, memory_percent),
        max(0.0, rss_kib),
        max(0, int(elapsed)),
        command or "process",
    )


def main() -> int:
    used_mib, total_mib = read_memory()
    try:
        load_one = float(os.getloadavg()[0])
    except (OSError, ValueError):
        load_one = 0.0
    cpu_count = max(1, int(os.cpu_count() or 1))
    uptime = read_uptime()

    print(f"@STAT\t{used_mib:.1f}\t{total_mib:.1f}\t{load_one:.2f}\t{cpu_count}")

    rows = []
    try:
        entries = PROC.iterdir()
    except OSError:
        return 1

    for pid_path in entries:
        if not pid_path.name.isdigit():
            continue
        row = read_process(pid_path, uptime, total_mib)
        if row is not None:
            rows.append(row)

    # Task Manager groups and re-sorts records in QML. This ordering only keeps
    # the most useful records near the top if a future safety cap is introduced.
    rows.sort(key=lambda row: (-row[3], -row[5], row[7].lower(), row[0]))

    for row in rows:
        pid, ppid, user, cpu, mem, rss_kib, elapsed, command = row
        print(
            f"{pid}\t{ppid}\t{user}\t{cpu:.1f}\t{mem:.2f}\t"
            f"{rss_kib:.0f}\t{elapsed}\t{command}"
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
