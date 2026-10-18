#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'desktop-widget-boundary-audit: %s\n' "$*" >&2
  exit 1
}

canvas='modules/raohane/RaohaneDesktopCanvas.qml'
widgets='modules/raohane/RaohaneDesktopWidgets.qml'
host='modules/raohane/RaohaneDesktopWidgetHost.qml'
clock='modules/raohane/RaohaneDesktopClockWidget.qml'
context='modules/raohane/RaohaneDesktopContextWidget.qml'
system='modules/raohane/RaohaneDesktopSystemWidget.qml'
motto='modules/raohane/RaohaneDesktopMottoWidget.qml'
studio='modules/raohane/RaohaneWidgetStudio.qml'
layout_studio='modules/raohane/RaohaneDesktopWidgetLayoutStudio.qml'
edit_grid='modules/raohane/RaohaneDesktopEditGrid.qml'
desktop_menu='modules/raohane/RaohaneDesktopMenu.qml'
background='modules/raohane/RaohaneBackground.qml'
state='modules/raohane/RaohaneState.qml'
free_studio='modules/raohane/RaohaneFreeWidgetStudio.qml'
widget_registry='modules/raohane/RaohaneDesktopWidgetRegistry.qml'
qmldir='modules/raohane/qmldir'
settings='modules/raohane/RaohaneSettingsContentV3.qml'
registry='modules/raohane/RaohaneSettingsPageRegistry.qml'
search='modules/raohane/RaohaneSettingsSearch.qml'
config='modules/raohane/config/RaohaneConfig.qml'
defaults='defaults/native.json'

for path in "$canvas" "$widgets" "$host" "$clock" "$context" "$system" "$motto" "$studio" "$layout_studio" "$edit_grid" "$desktop_menu" "$background" "$state" "$free_studio" "$widget_registry" "$qmldir" "$settings" "$registry" "$search" "$config" "$defaults"; do
  [[ -f "$path" ]] || fail "missing native widget path: $path"
done

rg -q '^singleton RaohaneDesktopWidgetRegistry 1\.0 RaohaneDesktopWidgetRegistry\.qml$' "$qmldir" \
  || fail 'Desktop Widget Registry is not registered in the Raohane QML module'
for registration in \
  '^RaohaneDesktopWidgetHost 1\.0 RaohaneDesktopWidgetHost\.qml$' \
  '^RaohaneDesktopClockWidget 1\.0 RaohaneDesktopClockWidget\.qml$' \
  '^RaohaneDesktopContextWidget 1\.0 RaohaneDesktopContextWidget\.qml$' \
  '^RaohaneDesktopSystemWidget 1\.0 RaohaneDesktopSystemWidget\.qml$' \
  '^RaohaneDesktopMottoWidget 1\.0 RaohaneDesktopMottoWidget\.qml$' \
  '^RaohaneDesktopWidgetLayoutStudio 1\.0 RaohaneDesktopWidgetLayoutStudio\.qml$' \
  '^RaohaneFreeWidgetStudio 1\.0 RaohaneFreeWidgetStudio\.qml$'; do
  rg -q "$registration" "$qmldir" || fail "desktop widget runtime lost registration: $registration"
done

# Widget context menus must reuse the existing desktop popup and Qt input
# masks: wallpaper remains clickable outside the four widget bounds.
rg -Fq 'RaohaneDesktopEditGrid 1.0 RaohaneDesktopEditGrid.qml' "$qmldir" \
  || fail 'desktop grid is not registered in native qmldir'
[[ -f "$edit_grid" ]] || fail 'desktop editing component is missing from the checkout'
rg -Fq 'source: active ? Qt.resolvedUrl("RaohaneDesktopEditGrid.qml") : ""' "$widgets" \
  || fail 'desktop editor is a hard dependency that can crash shell startup'
rg -Fq 'status === Loader.Error' "$widgets" \
  || fail 'desktop edit grid load failure does not leave edit mode safely'
rg -Fq 'mask: Region {' "$canvas" || fail 'widget canvas traps clicks across the wallpaper'
for widget in clock context system motto; do
  rg -Fq "desktopWidgets.freeHitRect(\"$widget\")" "$canvas" \
    || fail "free $widget widget is missing from input mask"
done
rg -Fq 'function freeHitRect(id: string): rect' "$widgets" \
  || fail 'desktop widgets lost bounded click geometry'
rg -Fq 'readonly property real railOffsetX:' "$widgets" \
  || fail 'rail click region no longer accounts for global scale'
rg -Fq 'readonly property real railOffsetY:' "$widgets" \
  || fail 'rail click region no longer accounts for vertical scaling'
rg -Fq 'onWidgetMenuRequested:' "$widgets" \
  || fail 'widget faces cannot open the desktop context menu'
rg -Fq 'acceptedButtons: Qt.RightButton' "$host" \
  || fail 'widget host lost right-click action'
rg -Fq 'acceptedButtons: Qt.RightButton' "$background" \
  || fail 'blank wallpaper lost right-click action'
rg -Fq 'desktopMenuWidgetId' "$state" \
  || fail 'desktop menu no longer remembers selected widget'
# Widgets now enter edit mode on the real desktop. The old gallery
# must not return and normal pointer input must be restored upon exit.
rg -Fq 'RaohaneDesktopEditGrid 1.0 RaohaneDesktopEditGrid.qml' "$qmldir" \
  || fail 'desktop edit grid is not registered'
rg -Fq 'Qt.resolvedUrl("RaohaneDesktopEditGrid.qml")' "$widgets" \
  || fail 'real desktop does not lazily load edit grid'
rg -Fq 'function startWidgetEditing(): void' "$desktop_menu" \
  || fail 'desktop Widgets menu no longer enters direct edit mode'
rg -Fq 'onTriggered: root.startWidgetEditing()' "$desktop_menu" \
  || fail 'Widgets command does not enter direct desktop edit mode'
rg -Fq 'desktopWidgetEditMode = true' "$desktop_menu" \
  || fail 'menu does not activate desktop editing'
if rg -Fq 'RaohaneDesktopWidgetPopover' "$desktop_menu"; then
  fail 'obsolete mock widget gallery returned'
fi
rg -Fq 'property bool desktopWidgetEditMode:' "$state" \
  || fail 'transient edit state is missing'
rg -Fq 'desktopWidgetEditScreenName:' "$state" \
  || fail 'desktop editor lost monitor selection'
rg -Fq 'width: desktopWindow.editInputEnabled ? desktopWindow.width : 0' "$canvas" \
  || fail 'desktop editing input region does not cover work area'
rg -Fq 'WlrLayershell.keyboardFocus: desktopWindow.editInputEnabled' "$canvas" \
  || fail 'desktop editor has no scoped keyboard focus'
rg -Fq 'onFullscreenActiveChanged:' "$canvas" \
  || fail 'desktop editor cannot dismiss on fullscreen'
rg -Fq 'Component.onDestruction:' "$canvas" \
  || fail 'desktop editor cannot dismiss on monitor disconnect'
if rg -Fq 'RaohaneState.desktopWidgetEditMode = false' "$edit_grid"; then
  fail 'edit grid must signal closure rather than mutate global state directly'
fi
rg -Fq 'function onDoneRequested(): void' "$widgets" \
  || fail 'editing has no Done action'
rg -Fq 'onReleased: placedWidget.finishInteraction()' "$widgets" \
  || fail 'desktop widgets cannot commit interactive drag/resize'
rg -Fq 'Math.round(workingX / root.editGridStep)' "$widgets" \
  || fail 'desktop widget movement lost grid snapping'
rg -Fq 'RaohaneConfig.setDesktopWidgetPlacement(' "$widgets" \
  || fail 'real widget drags do not persist positions'
rg -Fq 'acceptedButtons: Qt.LeftButton' "$widgets" \
  || fail 'editor blocks existing widget left-button controls outside edit mode'
rg -Fq 'model: RaohaneDesktopWidgetRegistry.definitions()' "$edit_grid" \
  || fail 'desktop editor cannot restore hidden widget types'
rg -Fq 'signal doneRequested()' "$edit_grid" \
  || fail 'desktop grid lost its completion action'
rg -Fq 'active: root.desktopEditActive' "$widgets" \
  || fail 'on-desktop edit grid is not unloaded when inactive'
rg -Fq 'desktopWidgetEditMode' "$host" \
  || fail 'widget host may open context menu during a drag'

rg -q 'readonly property var widgetIds:[[:space:]]*\["clock", "context", "system", "motto"\]' "$widget_registry" \
  || fail 'Desktop Widget Registry lost the native widget ids'
for widget_id in clock context system motto; do
  rg -q "${widget_id}:[[:space:]]*\{" "$widget_registry" \
    || fail "Desktop Widget Registry lost ${widget_id} metadata"
done
for source in RaohaneDesktopClockWidget.qml RaohaneDesktopContextWidget.qml RaohaneDesktopSystemWidget.qml RaohaneDesktopMottoWidget.qml; do
  rg -q "source:[[:space:]]*\"${source}\"" "$widget_registry" \
    || fail "Desktop Widget Registry lost runtime source ${source}"
done
rg -q 'function definitions\(\): var' "$widget_registry" \
  || fail 'Desktop Widget Registry lost ordered metadata access'

rg -q 'property var desktopWidgetComposition:[[:space:]]*root\.defaultDesktopWidgetComposition\(\)' "$config" \
  || fail 'native config lost persisted desktop widget composition'
rg -q 'function defaultDesktopWidgetComposition\(\): var' "$config" \
  || fail 'native config lost default desktop widget composition'
rg -q 'function sanitizeDesktopWidgetComposition\(value\): var' "$config" \
  || fail 'native config lost desktop widget composition sanitizer'
rg -q 'composition:[[:space:]]*root\.sanitizeDesktopWidgetComposition\(root\.desktopWidgetComposition\)' "$config" \
  || fail 'native snapshot no longer persists desktop widget composition'
rg -q 'assignIfPresent\(desktopWidgets, "composition"' "$config" \
  || fail 'native config no longer loads desktop widget composition'
rg -q 'onDesktopWidgetCompositionChanged:[[:space:]]*scheduleSave\(\)' "$config" \
  || fail 'desktop widget composition changes are not persisted'

jq -e '
  .schemaVersion == 15 and
  (.desktopWidgets | type == "object") and
  (.desktopWidgets.enabled | type == "boolean") and
  (.desktopWidgets.showClock | type == "boolean") and
  (.desktopWidgets.showContext | type == "boolean") and
  (.desktopWidgets.showSystem | type == "boolean") and
  (.desktopWidgets.showMotto | type == "boolean") and
  (.desktopWidgets.composition.primary == ["clock", "context"]) and
  (.desktopWidgets.composition.secondary == ["system", "motto"]) and
  (.desktopWidgets.compact | type == "boolean") and
  (.desktopWidgets.layout == "balanced") and
  (.desktopWidgets.freeLayouts == {}) and
  (.desktopWidgets.scale | type == "number") and
  (.desktopWidgets.opacity | type == "number")
' "$defaults" >/dev/null || fail 'native widget defaults are invalid'

# Free layout retains rail mode and uses native config persistence.
rg -Fq 'property var desktopWidgetFreeLayouts:' "$config" || fail 'missing free layout store'
rg -Fq 'function sanitizeDesktopWidgetFreeLayouts(value): var' "$config" || fail 'missing free layout sanitizer'
rg -Fq 'function setDesktopWidgetPlacement(' "$config" || fail 'missing placement API'
rg -Fq 'onDesktopWidgetFreeLayoutsChanged: scheduleSave()' "$config" || fail 'free layout changes do not save'
rg -Fq 'RaohaneConfig.desktopWidgetPlacement(' "$widgets" || fail 'free layout not rendered'
rg -Fq 'RaohaneFreeWidgetStudio {' "$studio" || fail 'free editor missing from Studio'
rg -Fq 'setDesktopWidgetPlacement(' "$free_studio" || fail 'free editor cannot persist drags'
rg -Fq 'resetDesktopWidgetFreeLayout(' "$free_studio" || fail 'free editor cannot reset monitor'

rg -Fq 'onMonitorScreenChanged:' "$free_studio" || fail 'free editor cannot recover after output removal'
rg -Fq 'Keys.onPressed:' "$free_studio" || fail 'free editor lost keyboard movement'
rg -Fq 'function resetSelected(): void' "$free_studio" || fail 'free editor lost per-widget reset'
rg -Fq 'root.forceActiveFocus()' "$free_studio" || fail 'free editor does not focus keyboard movement'
rg -Fq 'readonly property real totalScale:' "$free_studio" || fail 'free preview lost global scale'
rg -Fq 'readonly property real renderedScale:' "$widgets" || fail 'free canvas lost per-widget scale bounds'
rg -Fq 'root.layoutPreset === "free" ? 1 : RaohaneConfig.desktopWidgetsScale' "$widgets" \
  || fail 'free canvas is still globally scaled and can push widgets off-screen'
rg -Fq 'readonly property bool widgetEnabled:' "$host" || fail 'widget host lost own enable state'
if rg -q 'readonly property bool enabled:' "$host"; then
  fail 'widget host shadows QtQuick.Item.enabled'
fi

rg -q 'RaohaneConfig\.sanitizeDesktopWidgetComposition\(RaohaneConfig\.desktopWidgetComposition\)' "$widgets" \
  || fail 'desktop runtime does not consume the persisted sanitized composition'
rg -q 'root\.composition\.primary' "$widgets" \
  || fail 'desktop runtime lost the primary persisted zone'
rg -q 'root\.composition\.secondary' "$widgets" \
  || fail 'desktop runtime lost the secondary persisted zone'
rg -q 'delegate:[[:space:]]*RaohaneDesktopWidgetHost[[:space:]]*\{' "$widgets" \
  || fail 'desktop runtime no longer renders composition IDs through the shared host'
if rg -q 'RaohaneDesktopWidgetRegistry\.idsForZone\(' "$widgets"; then
  fail 'desktop runtime regressed to hard-coded registry preferred zones instead of persisted composition'
fi

rg -q 'RaohaneDesktopWidgetRegistry\.definition\(root\.widgetId\)' "$host" \
  || fail 'desktop widget host lost registry metadata lookup'
rg -q 'RaohaneConfig\[root\.configKey\]' "$host" \
  || fail 'desktop widget host lost native enable-state binding'
rg -q 'source:[[:space:]]*root\.definition\?\.source' "$host" \
  || fail 'desktop widget host lost declarative source loading'

rg -q 'RaohaneMedia\.' "$context" || fail 'context widget lost native media service ownership'
rg -q 'RaohaneContext\.' "$context" || fail 'context widget lost live context ownership'
rg -q 'RaohaneNetwork\.' "$system" || fail 'system widget lost native network service ownership'
rg -q 'RaohaneAudio\.' "$system" || fail 'system widget lost native audio service ownership'
rg -q 'RaohaneSystemInfo\.' "$system" || fail 'system widget lost native host-status ownership'
rg -q 'Timer[[:space:]]*\{' "$clock" || fail 'clock widget lost its local idle-safe time source'
rg -q 'Move quietly\. Keep going\.' "$motto" || fail 'motto widget lost native ambient copy'

rg -q 'RaohaneDesktopWidgetRegistry\.definitions\(\)' "$studio" \
  || fail 'Widget Studio no longer consumes registry widget metadata'
rg -q 'RaohaneDesktopWidgetRegistry\.layouts' "$studio" \
  || fail 'Widget Studio no longer consumes registry composition presets'
rg -q 'desktopWidgetsLayout === modelData\.key' "$studio" \
  || fail 'Widget Studio presets are not connected to native config'
rg -q 'RaohaneDesktopWidgetLayoutStudio[[:space:]]*\{' "$studio" \
  || fail 'Widget Studio lost the persisted layout editor'
if rg -q 'readonly property var widgets:[[:space:]]*\[|readonly property var layouts:[[:space:]]*\[' "$studio"; then
  fail 'Widget Studio reintroduced duplicate widget or layout metadata'
fi

rg -q 'RaohaneConfig\.desktopWidgetComposition' "$layout_studio" \
  || fail 'Widget Layout Studio lost live native composition binding'
rg -q 'function moveWithin\(zone: string, index: int, delta: int\): void' "$layout_studio" \
  || fail 'Widget Layout Studio lost within-zone ordering'
rg -q 'function moveAcross\(zone: string, index: int\): void' "$layout_studio" \
  || fail 'Widget Layout Studio lost cross-zone movement'
rg -q 'defaultDesktopWidgetComposition\(\)' "$layout_studio" \
  || fail 'Widget Layout Studio lost reset-to-default behavior'

rg -q 'RaohaneSettingsPageRegistry\.searchEntries\(\)' "$search" \
  || fail 'Settings search is not driven by the native page registry'
rg -q 'key:[[:space:]]*"widgets".*source:[[:space:]]*"RaohaneWidgetStudio\.qml"' "$registry" \
  || fail 'Settings registry does not declaratively route the visual Widget Studio'
rg -q 'key:[[:space:]]*"desktopWidgetComposition".*label:[[:space:]]*qsTr\("Widget positions"\)' "$registry" \
  || fail 'Settings search no longer exposes Widget Layout Studio'

# Settings pages are still resolved exclusively from currentPageInfo.source, but
# the animated page transition owns Loader.source imperatively so the outgoing
# page can fade/slide before the incoming component is swapped in.
rg -q 'root\.currentPageInfo\?\.source' "$settings" \
  || fail 'Settings shell no longer resolves pages from the registry source field'
rg -q 'pageLoader\.source[[:space:]]*=[[:space:]]*nextSource' "$settings" \
  || fail 'Settings animated loader no longer applies registry-resolved page sources'
rg -q 'pageLoader\.source[[:space:]]*=[[:space:]]*root\.currentPageInfo\?\.source' "$settings" \
  || fail 'Settings initial page no longer loads from the registry source field'

for property_name in desktopWidgetsLayout desktopWidgetsScale desktopWidgetsOpacity; do
  rg -q "property (string|real) ${property_name}:" "$config" \
    || fail "native config is missing $property_name"
  rg -q "on${property_name^}Changed:[[:space:]]*scheduleSave\(\)" "$config" \
    || fail "$property_name is not persisted"
  rg -q "key:[[:space:]]*\"${property_name}\"" "$registry" \
    || fail "Settings registry/search schema does not expose $property_name"
done

properties=(
  desktopWidgetsEnabled desktopWidgetClock desktopWidgetContext
  desktopWidgetSystem desktopWidgetMotto desktopWidgetsCompact
)
for property_name in "${properties[@]}"; do
  rg -q "property bool ${property_name}:" "$config" \
    || fail "native config is missing $property_name"
  rg -q "on${property_name^}Changed:[[:space:]]*scheduleSave\(\)" "$config" \
    || fail "$property_name is not persisted"
  rg -q "key:[[:space:]]*\"${property_name}\"" "$registry" \
    || fail "Settings registry does not expose $property_name"
done

for symbol in \
  'RaohaneConfig\.desktopWidgetsCompact' \
  'RaohaneConfig\.desktopWidgetsLayout' \
  'RaohaneConfig\.desktopWidgetsScale' \
  'RaohaneConfig\.desktopWidgetsOpacity'; do
  rg -q "$symbol" "$widgets" || fail "desktop host lost native composition contract: $symbol"
done

rg -q 'RaohaneConfig\.desktopWidgetsEnabled' "$canvas" \
  || fail 'desktop canvas does not honor the widget master switch'
rg -q 'RaohaneDesktopWidgets[[:space:]]*\{' "$canvas" \
  || fail 'desktop canvas does not load the native widget composition'

if rg -n 'RaohaneMedia\.|RaohaneNetwork\.|RaohaneAudio\.|RaohaneSystemInfo\.' "$widgets"; then
  fail 'desktop host reabsorbed concrete widget service ownership'
fi
if [[ -e defaults/widgets ]]; then
  find defaults/widgets -type f -print -quit | grep -q . \
    && fail 'retired inherited widget SDK returned'
fi
if rg -n '^import qs\.services$|^import qs\.modules\.common|AbstractBackgroundWidget' "$canvas" "$widgets" "$host" "$clock" "$context" "$system" "$motto" "$studio" "$layout_studio" "$widget_registry" "$settings" "$registry" "$search"; then
  fail 'desktop widgets depend on retired inherited APIs'
fi

# The desktop widget deck must change composition, not just theme colors,
# without introducing new polling or crossing native service ownership.
for contract in \
  'implicitHeight: root.compact ? 154 : 190' \
  'text: "RAOHANE"' \
  'font.pixelSize: root.compact ? 52 : 70' \
  'showSheen: true' \
  'showInnerRim: true' \
  'interval: 60000' \
  'running: root.visible'; do
  rg -Fq "$contract" "$clock" \
    || fail "Desktop hero clock lost its layout/idle policy: $contract"
done
for contract in \
  'implicitHeight: root.compact ? 146 : 164' \
  'Layout.preferredWidth: root.compact ? 62 : 80' \
  'source: root.visible && root.hasMedia ? root.coverUrl : ""' \
  'sourceSize.width: 160' \
  'asynchronous: true' \
  'font.pixelSize: root.compact ? 12 : 15' \
  'RaohaneMedia.progress' \
  'RaohaneContext.title'; do
  rg -Fq "$contract" "$context" \
    || fail "Desktop media/context feature card lost its layout: $contract"
done
for contract in \
  'implicitHeight: root.compact ? 122 : 142' \
  'component StatusTile: RaohaneSurface' \
  'required property bool statusActive' \
  'RaohaneNetwork.materialSymbol' \
  'RaohaneAudio.muted' \
  'RaohaneSystemInfo.hostname'; do
  rg -Fq "$contract" "$system" \
    || fail "Desktop system deck lost its status tile contract: $contract"
done
[[ "$(rg -Fc 'StatusTile {' "$system")" == 2 ]] \
  || fail 'Desktop system deck must contain exactly two status tiles'
if rg -Fq 'required property bool active' "$system"; then
  fail 'Desktop status tiles redeclare the inherited surface active property'
fi


printf 'desktop-widget-boundary-audit: persisted registry-driven widget composition, Widget Studio, animated Settings routing, native config and service ownership are valid\n'