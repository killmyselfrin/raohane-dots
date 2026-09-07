#!/usr/bin/env python3
"""Low-overhead /proc process snapshot for the native Raohane Task Manager.

The helper intentionally avoids procps/ps so opening Task Manager does not create
short-lived `ps` processes that can report misleadingly high CPU usage. CPU is
sampled from /proc twice over a short interval so the UI reports current usage,
not a process's lifetime average.
"""

from __future__ import annotations

import os
import pwd
import time
from pathlib import Path

PROC = Path("/proc")
SELF_PID = os.getpid()
UID = os.getuid()
USERNAME = pwd.getpwuid(UID).pw_name
CLK_TCK = float(os.sysconf(os.sysconf_names["SC_CLK_TCK"]))
SAMPLE_INTERVAL = 0.22


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


def read_uid(pid_path: Path) -> int | None:
    try:
        with (pid_path / "status").open("r", encoding="utf-8") as handle:
            for line in handle:
                if line.startswith("Uid:"):
                    return int(line.split()[1])
    except (OSError, ValueError, IndexError):
        return None
    return None


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


def read_stat(pid_path: Path):
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

    try:
        ppid = int(fields[1])
        utime_ticks = float(fields[11])
        stime_ticks = float(fields[12])
        start_ticks = float(fields[19])
    except (ValueError, IndexError):
        return None

    return command, ppid, utime_ticks + stime_ticks, start_ticks


def read_cmdline(pid_path: Path, fallback: str) -> str:
    try:
        raw = (pid_path / "cmdline").read_bytes()
    except OSError:
        return fallback
    if not raw:
        return fallback
    parts = [
        part.decode("utf-8", errors="replace").strip()
        for part in raw.split(b"\0")
        if part
    ]
    value = " ".join(part for part in parts if part)
    return value.replace("\t", " ").replace("\n", " ").strip() or fallback


def read_cpu_baseline() -> dict[int, tuple[float, float, float]]:
    baseline: dict[int, tuple[float, float, float]] = {}
    try:
        entries = PROC.iterdir()
    except OSError:
        return baseline

    for pid_path in entries:
        if not pid_path.name.isdigit():
            continue
        try:
            pid = int(pid_path.name)
        except ValueError:
            continue
        if pid <= 1 or pid == SELF_PID:
            continue
        if read_uid(pid_path) != UID:
            continue

        stat = read_stat(pid_path)
        if stat is None:
            continue
        _command, _ppid, cpu_ticks, start_ticks = stat

        # Keep a per-process timestamp so scan time does not skew CPU values.
        baseline[pid] = (start_ticks, cpu_ticks, time.monotonic())

    return baseline


def read_process(
    pid_path: Path,
    uptime: float,
    total_mib: float,
    baseline: dict[int, tuple[float, float, float]],
):
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

    stat = read_stat(pid_path)
    if stat is None:
        return None
    command, ppid, cpu_ticks, start_ticks = stat

    sample_time = time.monotonic()
    previous = baseline.get(pid)
    cpu_percent = 0.0
    if previous is not None:
        previous_start, previous_ticks, previous_time = previous
        # starttime also protects against PID reuse between the two samples.
        if previous_start == start_ticks:
            wall_seconds = sample_time - previous_time
            delta_ticks = max(0.0, cpu_ticks - previous_ticks)
            if wall_seconds > 0.01:
                cpu_percent = (delta_ticks / CLK_TCK) / wall_seconds * 100.0

    elapsed = max(0.0, uptime - (start_ticks / CLK_TCK)) if uptime > 0 else 0.0
    rss_mib = max(0.0, rss_kib / 1024.0)
    memory_percent = (rss_mib / total_mib * 100.0) if total_mib > 0 else 0.0
    command_line = read_cmdline(pid_path, command or "process")

    return (
        pid,
        max(0, ppid),
        USERNAME,
        max(0.0, cpu_percent),
        max(0.0, memory_percent),
        max(0.0, rss_kib),
        max(0, int(elapsed)),
        command or "process",
        command_line,
    )


def main() -> int:
    baseline = read_cpu_baseline()
    time.sleep(SAMPLE_INTERVAL)

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
        row = read_process(pid_path, uptime, total_mib, baseline)
        if row is not None:
            rows.append(row)

    # Task Manager groups and re-sorts records in QML. This ordering only keeps
    # the most useful records near the top if a future safety cap is introduced.
    rows.sort(key=lambda row: (-row[3], -row[5], row[7].lower(), row[0]))

    for row in rows:
        pid, ppid, user, cpu, mem, rss_kib, elapsed, command, command_line = row
        print(
            f"{pid}\t{ppid}\t{user}\t{cpu:.1f}\t{mem:.2f}\t"
            f"{rss_kib:.0f}\t{elapsed}\t{command}\t{command_line}"
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
