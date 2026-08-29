#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'lock-boundary-audit: %s\n' "$*" >&2
  exit 1
}

family='panelFamilies/RaohaneFamily.qml'
qmldir='modules/raohane/qmldir'
lock='modules/raohane/RaohaneLock.qml'
context='modules/raohane/RaohaneLockContext.qml'
surface='modules/raohane/RaohaneLockSurface.qml'
fingerprint_pam='modules/raohane/pam/fprintd.conf'
session='modules/raohane/services/RaohaneSession.qml'
features='install/arch/features.txt'

for path in "$family" "$qmldir" "$lock" "$context" "$surface" "$fingerprint_pam" "$session" "$features"; do
  [[ -f "$path" ]] || fail "missing native lock path: $path"
done

for registration in \
  'RaohaneLockContext 1.0 RaohaneLockContext.qml' \
  'RaohaneLockSurface 1.0 RaohaneLockSurface.qml' \
  'RaohaneLock 1.0 RaohaneLock.qml'; do
  rg -q "^${registration}$" "$qmldir" || fail "missing qmldir registration: $registration"
done

rg -q 'component: RaohaneLock \{\}' "$family" \
  || fail 'RaohaneFamily does not load the native lock'
if rg -n '^import qs\.modules\.ii\.lock$|component: Lock \{\}' "$family"; then
  fail 'RaohaneFamily still loads the inherited lock runtime'
fi

for symbol in \
  'WlSessionLock[[:space:]]*\{' \
  'WlSessionLockSurface[[:space:]]*\{' \
  'RaohaneState\.screenLocked' \
  'lockContext\.refreshFingerprints\(\)' \
  'target: "lock"'; do
  rg -q "$symbol" "$lock" || fail "RaohaneLock lost secure/native contract: $symbol"
done
if rg -n '^import qs$|^import qs\.services$|^import qs\.modules\.common|^import qs\.modules\.ii|\bGlobalStates\.|\bConfig\.|\bAppearance\.' "$lock" "$context" "$surface"; then
  fail 'native lock regressed to inherited root/common/config/UI dependencies'
fi

rg -q 'Quickshell\.Services\.Pam' "$context" \
  || fail 'RaohaneLockContext is not using Quickshell PAM'
rg -q '\bPamContext[[:space:]]*\{' "$context" \
  || fail 'RaohaneLockContext does not own a PAM transaction'
rg -q 'configDirectory:[[:space:]]*"pam"' "$context" \
  || fail 'fingerprint PamContext lost its Raohane-owned PAM directory'
rg -q 'config:[[:space:]]*"fprintd\.conf"' "$context" \
  || fail 'fingerprint PamContext lost its native PAM profile'
rg -q 'fprintd-list' "$context" \
  || fail 'RaohaneLockContext lost optional fingerprint discovery'
for finger in left-thumb left-index-finger right-thumb right-index-finger; do
  rg -q "\"${finger}\"" "$context" \
    || fail "fingerprint discovery lost stable fprintd finger identifier: $finger"
done
rg -q 'fingerprintNames\.some\(name => output\.includes\(name\)\)' "$context" \
  || fail 'fingerprint discovery regressed to locale-dependent output parsing'
rg -q 'readonly property int fingerprintRetryLimit:[[:space:]]*[1-9]' "$context" \
  || fail 'fingerprint transient retries are no longer bounded'
rg -q 'fingerprintRetryCount \+ 1 < root\.fingerprintRetryLimit' "$context" \
  || fail 'fingerprint PAM errors can retry without the native retry bound'
rg -q '^[[:space:]]*auth[[:space:]]+required[[:space:]]+pam_fprintd\.so([[:space:]]|$)' "$fingerprint_pam" \
  || fail 'native fingerprint PAM profile does not require pam_fprintd.so'
rg -q '^fprintd$' "$features" \
  || fail 'fingerprint-capable native lock is missing fprintd from the feature manifest'

for symbol in 'RaohaneConfig\.lockWallpaperPath' 'RaohanePaths\.defaultWallpaperUrl' 'RaohaneSession\.suspend' 'RaohaneSession\.poweroff'; do
  rg -q "$symbol" "$surface" || fail "RaohaneLockSurface lost native dependency: $symbol"
done

rg -q 'ipc", "call", "lock", "activate"' "$session" \
  || fail 'RaohaneSession.lock does not route to the native lock IPC'
if rg -n 'loginctl.*lock-session' "$session"; then
  fail 'RaohaneSession.lock still uses the old logind-only lock path'
fi

printf 'lock-boundary-audit: native WlSessionLock/PAM/fprintd runtime, refresh, bounded retries and owned fingerprint profile are valid\n'
