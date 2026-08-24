#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0
pass() { printf 'PASS  %s\n' "$1"; }
bad() { printf 'FAIL  %s\n' "$1" >&2; fail=1; }

while IFS= read -r file; do bash -n "$file" || bad "shell syntax: ${file#$ROOT/}"; done < <(find "$ROOT" -type f -name '*.sh' -not -path '*/.git/*' -print)
((fail)) || pass 'shell syntax'

manifest="$ROOT/manifests/raohane-dependencies.tsv"
expected=$'id\tgroup\tarch_package\trequirement\tprofiles\tfeature\tcapability\tdiagnostic\tservice\tsource\tinstall_notes\tsession_requirement\thardware_condition'
[[ -r "$manifest" && "$(head -n1 "$manifest")" == "$expected" ]] && pass 'dependency manifest schema' || bad 'dependency manifest schema'
groups=(core quickshell-qt hyprland-wayland portals polkit-keyring audio-media network bluetooth backlight-power capture input-clipboard widgets-tools theming graphics-common graphics-nvidia-legacy graphics-nvidia-modern graphics-amd graphics-intel)
for group in "${groups[@]}"; do awk -F '\t' -v g="raohane-$group" 'NR>1 && $2==g{found=1} END{exit !found}' "$manifest" || bad "missing package group: raohane-$group"; done
((fail)) || pass 'required package groups'

grep -Fq 'qs -c raohane' "$ROOT/scripts/raohane" && pass 'named Quickshell configuration' || bad 'launcher must use qs -c raohane'
grep -Fq 'GPU groups: excluded from automatic installation' "$ROOT/install-raohane.sh" && pass 'GPU installation safety gate' || bad 'GPU driver safety gate missing'

if [[ -d "$ROOT/modules/raohane" ]]; then
  if rg -n -i 'iNiR|Niri|Waffle|Ricelin|sidebarRight' "$ROOT/modules/raohane" --glob '*.qml'; then bad 'legacy identity in primary UI'; else pass 'primary UI identity boundary'; fi
else
  printf 'WARN  modules/raohane is absent from this source snapshot; primary-QML import validation skipped\n'
fi

if [[ -f "$ROOT/qmldir" ]] && grep -Fqx 'module qs' "$ROOT/qmldir"; then pass 'root qmldir'; else bad 'root qmldir'; fi
exit "$fail"
