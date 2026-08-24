#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_NAME="raohane"
RUNTIME="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/$CONFIG_NAME"
BIN_DIR="$HOME/.local/bin"
SYSTEMD_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
INSTALL_DEPS=no
START_AFTER=no
CHECK_ONLY=no

usage() {
  cat <<'EOF'
Usage: ./install-raohane-foundation.sh [options]

Options:
  --check        inspect prerequisites; do not change the system
  --shell-only   install only the imported Quickshell foundation (default)
  --with-deps    install full pinned upstream dependency baseline first
  --start        start/restart raohane.service after installation
  -h, --help

This is a migration-baseline installer. It deliberately does not overwrite the
user's Hyprland configuration and does not install or replace GPU drivers.
EOF
}

while (($#)); do
  case "$1" in
    --check) CHECK_ONLY=yes ;;
    --shell-only) INSTALL_DEPS=no ;;
    --with-deps) INSTALL_DEPS=yes ;;
    --start) START_AFTER=yes ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done

printf 'Raohane foundation installer\n'
printf '  source: %s\n' "$ROOT"
printf '  runtime: %s\n' "$RUNTIME"
printf '  Quickshell config: %s\n' "$CONFIG_NAME"
printf '  dependency mode: %s\n\n' "$([[ "$INSTALL_DEPS" == yes ]] && echo full-upstream || echo shell-only)"

[[ -f "$ROOT/shell.qml" ]] || { echo 'FAIL  shell.qml missing from source tree.' >&2; exit 1; }
[[ -d "$ROOT/modules/ii" ]] || { echo 'FAIL  imported end4-pC foundation is incomplete.' >&2; exit 1; }
[[ -f "$ROOT/scripts/raohane-deps" ]] || { echo 'FAIL  scripts/raohane-deps missing.' >&2; exit 1; }
[[ -f "$ROOT/manifests/upstream-package-baseline.tsv" ]] || { echo 'FAIL  generated dependency baseline missing.' >&2; exit 1; }

font_count="$(find "$ROOT" -type f \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.eot' \) -not -path '*/.git/*' | wc -l)"
[[ "$font_count" -eq 0 ]] || { printf 'FAIL  source contains %s bundled font binaries.\n' "$font_count" >&2; exit 1; }

for cmd in rsync systemctl; do
  command -v "$cmd" >/dev/null 2>&1 || printf 'WARN  command unavailable: %s\n' "$cmd"
done
command -v qs >/dev/null 2>&1 && echo 'PASS  Quickshell found' || echo 'WARN  Quickshell missing (use --with-deps on supported Arch systems)'
command -v hyprctl >/dev/null 2>&1 && echo 'PASS  Hyprland CLI found' || echo 'WARN  hyprctl missing/not in PATH'

if [[ "$CHECK_ONLY" == yes ]]; then
  "$ROOT/scripts/raohane-deps" summary
  exit 0
fi

command -v rsync >/dev/null 2>&1 || { echo 'FAIL  rsync is required for installation.' >&2; exit 1; }
command -v systemctl >/dev/null 2>&1 || { echo 'FAIL  systemd user service support is required by this baseline installer.' >&2; exit 1; }

if [[ "$INSTALL_DEPS" == yes ]]; then
  chmod +x "$ROOT/scripts/raohane-deps"
  "$ROOT/scripts/raohane-deps" install
fi

command -v qs >/dev/null 2>&1 || {
  echo 'FAIL  Quickshell is still unavailable. Dependency installation must be completed first.' >&2
  exit 1
}

if systemctl --user is-active --quiet raohane.service 2>/dev/null; then
  systemctl --user stop raohane.service
fi

mkdir -p "$RUNTIME" "$BIN_DIR" "$SYSTEMD_DIR"

# Copy runtime-relevant foundation content. Vendored system sources, migration
# snapshots, CI files and repository metadata stay in the development checkout.
# Licensing/attribution/pinned-source metadata remain in the installed runtime.
rsync -a --delete \
  --exclude='.git/' \
  --exclude='.github/' \
  --exclude='upstream/' \
  --exclude='migration/' \
  --exclude='docs/' \
  --exclude='manifests/' \
  --exclude='FOUNDATION-STATUS.md' \
  --exclude='AGENTS.md' \
  --exclude='install-raohane-foundation.sh' \
  "$ROOT/" "$RUNTIME/"

# The runtime needs the generated baseline for raohane-deps diagnostics.
mkdir -p "$RUNTIME/manifests"
install -m 0644 "$ROOT/manifests/upstream-package-baseline.tsv" "$RUNTIME/manifests/upstream-package-baseline.tsv"
install -m 0644 "$ROOT/manifests/upstream-package-baseline.md" "$RUNTIME/manifests/upstream-package-baseline.md"

# Runtime dependency builds need the pinned local PKGBUILDs. Keep only dist-arch,
# not the entire vendored system tree.
mkdir -p "$RUNTIME/upstream/illogical-impulse-system/sdata"
rsync -a --delete "$ROOT/upstream/illogical-impulse-system/sdata/dist-arch/" \
  "$RUNTIME/upstream/illogical-impulse-system/sdata/dist-arch/"

install -m 0755 "$ROOT/scripts/raohane" "$BIN_DIR/raohane"
chmod +x "$RUNTIME/scripts/raohane" "$RUNTIME/scripts/raohane-deps" "$RUNTIME/scripts/audit-foundation.sh" 2>/dev/null || true

cat > "$SYSTEMD_DIR/raohane.service" <<SERVICE
[Unit]
Description=Raohane Quickshell foundation
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=simple
ExecStart=${BIN_DIR}/raohane run
Restart=on-failure
RestartSec=2
Environment=QT_QPA_PLATFORM=wayland

[Install]
WantedBy=default.target
SERVICE

systemctl --user daemon-reload
systemctl --user enable raohane.service >/dev/null

printf '\nPASS  Raohane foundation installed.\n'
printf 'Runtime: %s\n' "$RUNTIME"
printf 'CLI: %s/raohane\n' "$BIN_DIR"
printf '\nNo Hyprland config was overwritten.\n'
printf 'Settings can be opened after startup with: raohane settings\n'
printf 'Foreground debug: raohane run\n'
printf 'Logs: raohane logs\n'
printf 'Runtime audit: raohane foundation-audit\n'

if [[ "$START_AFTER" == yes ]]; then
  systemctl --user restart raohane.service
  sleep 1
  systemctl --user --no-pager --full status raohane.service || true
else
  printf 'Start when ready: raohane start\n'
fi
