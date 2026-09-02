#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'sddm-theme-audit: %s\n' "$*" >&2
  exit 1
}

theme='display-manager/sddm/raohane'
for path in \
  "$theme/Main.qml" \
  "$theme/metadata.desktop" \
  "$theme/theme.conf" \
  "$theme/background.png" \
  "$theme/avatar.svg" \
  scripts/install-sddm-theme.sh \
  scripts/play-ui-sound.sh; do
  [[ -e "$path" ]] || fail "missing greeter/audio path: $path"
done

rg -q '^MainScript=Main\.qml$' "$theme/metadata.desktop" \
  || fail 'theme metadata does not select Main.qml'
rg -q '^Theme-Id=raohane$' "$theme/metadata.desktop" \
  || fail 'theme metadata lost the raohane id'
rg -q '^QtVersion=6$' "$theme/metadata.desktop" \
  || fail 'theme metadata does not request the Qt 6 greeter'

for marker in \
  'userModel.lastUser' \
  'sessionModel' \
  'sessionModel.lastIndex' \
  'sddm.login' \
  'function onLoginFailed' \
  'sddm.canPowerOff' \
  'sddm.powerOff()' \
  'sddm.canReboot' \
  'sddm.reboot()' \
  'sddm.canSuspend' \
  'sddm.suspend()'; do
  rg -q -F "$marker" "$theme/Main.qml" \
    || fail "theme lost SDDM integration marker: $marker"
done

rg -q 'THEME_TARGET="/usr/share/sddm/themes/raohane"' scripts/install-sddm-theme.sh \
  || fail 'theme installer target changed unexpectedly'
rg -q 'CONFIG_TARGET="/etc/sddm\.conf\.d/raohane-theme\.conf"' scripts/install-sddm-theme.sh \
  || fail 'theme installer config target changed unexpectedly'
rg -q -- '--enable' scripts/install-sddm-theme.sh \
  || fail 'theme installer lost explicit display-manager enable boundary'
rg -q -- '--preview' scripts/install-sddm-theme.sh \
  || fail 'theme installer lost preview mode'
rg -q 'pw-play' scripts/play-ui-sound.sh \
  || fail 'UI feedback helper no longer prefers PipeWire playback'

bash -n scripts/install-sddm-theme.sh
bash -n scripts/play-ui-sound.sh

if command -v qmlformat >/dev/null 2>&1; then
  qmlformat "$theme/Main.qml" >/dev/null
elif [[ -x /usr/lib/qt6/bin/qmlformat ]]; then
  /usr/lib/qt6/bin/qmlformat "$theme/Main.qml" >/dev/null
fi

printf 'sddm-theme-audit: Qt6 metadata, login/session/power integration, installer safety boundary and PipeWire UI feedback path are valid\n'
