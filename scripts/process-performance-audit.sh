#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'process-performance-audit: %s\n' "$*" >&2
  exit 1
}

service='modules/raohane/services/RaohaneProcesses.qml'
task_manager='modules/raohane/RaohaneTaskManager.qml'
helper='scripts/process-snapshot.py'

for path in "$service" "$task_manager" "$helper"; do
  [[ -f "$path" ]] || fail "missing process runtime path: $path"
done

python3 - "$helper" <<'PY'
import pathlib
import sys
path = pathlib.Path(sys.argv[1])
compile(path.read_text(encoding="utf-8"), str(path), "exec")
PY

rg -q 'Quickshell\.shellPath\("scripts/process-snapshot\.py"\)' "$service" \
  || fail 'process service no longer invokes the procfs snapshot helper'
rg -q 'minimumRefreshInterval:[[:space:]]*2800' "$service" \
  || fail 'process snapshot throttling was removed or changed unexpectedly'
rg -q 'lastRefreshMs' "$service" \
  || fail 'process service lost refresh coalescing state'
rg -q 'running:[[:space:]]*RaohaneState\.taskManagerOpen' "$task_manager" \
  || fail 'Task Manager refresh is no longer limited to the visible surface'

# A resident singleton must not retain the full process/command-line snapshot
# after the on-demand Task Manager has been dismissed.
for contract in \
  'property bool sessionActive: false' \
  'function beginSession\(\): void' \
  'function endSession\(\): void' \
  'if \(!root\.sessionActive \|\| snapshotProbe\.running\)' \
  'if \(!root\.sessionActive\)' \
  'root\.processes = \[\]' \
  'refreshDelay\.stop\(\)' \
  'root\.snapshotReceived = false' \
  'if \(exitCode !== 0 \|\| !root\.snapshotReceived\)'; do
  rg -q "$contract" "$service" || fail "process lifecycle lost contract: $contract"
done
rg -q 'RaohaneProcesses\.beginSession\(\)' "$task_manager" \
  || fail 'Task Manager no longer starts its procfs session on open'
rg -q 'RaohaneProcesses\.endSession\(\)' "$task_manager" \
  || fail 'Task Manager no longer releases its procfs snapshot on close'
rg -q 'interval:[[:space:]]*3000' "$task_manager" \
  || fail 'Task Manager started waking faster than its procfs throttle again'
rg -q 'Live · 3 s' "$task_manager" \
  || fail 'Task Manager refresh period label is out of sync'

# The old implementation spawned `ps --sort` on every refresh. Besides the
# repeated process-table scan, the short-lived ps process could report a very
# high lifetime CPU percentage and appear as the hottest process in its own
# snapshot. The native backend must remain procfs-only.
if rg -n 'LC_ALL=C[[:space:]]+ps|--sort=-%cpu|command:[[:space:]]*\[[^]]*"ps"' "$service"; then
  fail 'process service regressed to external ps polling'
fi

for contract in 'PROC = Path\("/proc"\)' 'SELF_PID = os\.getpid\(\)' 'os\.getloadavg\(\)' 'os\.cpu_count\(\)' '/ "stat"' '/ "status"'; do
  rg -q "$contract" "$helper" || fail "procfs helper lost contract: $contract"
done

snapshot="$(python3 "$helper")"
[[ "$snapshot" == @STAT$'\t'* ]] \
  || fail 'procfs helper did not emit a valid @STAT header'

printf 'process-performance-audit: Task Manager uses throttled procfs snapshots with no ps polling\n'
