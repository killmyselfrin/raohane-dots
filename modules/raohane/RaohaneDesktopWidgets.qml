pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    property var screen
    property bool shown: true

    readonly property bool compact: RaohaneConfig.desktopWidgetsCompact || width < 1280
    readonly property int edge: compact ? 28 : 44
    readonly property int cardWidth: compact ? 226 : 278
    readonly property string layoutPreset: RaohaneConfig.desktopWidgetsLayout
    readonly property string monitorName: String(root.screen?.name ?? "default")
    readonly property var composition: RaohaneConfig.sanitizeDesktopWidgetComposition(RaohaneConfig.desktopWidgetComposition)
    readonly property var primaryWidgetIds: root.composition.primary
    readonly property var secondaryWidgetIds: root.composition.secondary

    // Expose exact input geometry to the desktop PanelWindow mask. The mask
    // covers only widgets, so empty wallpaper remains right-clickable.
    readonly property rect primaryHitRect: Qt.rect(primaryColumn.x, primaryColumn.y,
        root.shown && root.layoutPreset !== "free" ? primaryColumn.width : 0,
        root.shown && root.layoutPreset !== "free" ? primaryColumn.height : 0)
    readonly property rect secondaryHitRect: Qt.rect(secondaryColumn.x, secondaryColumn.y,
        root.shown && root.layoutPreset !== "free" ? secondaryColumn.width : 0,
        root.shown && root.layoutPreset !== "free" ? secondaryColumn.height : 0)

    function freeHitRect(id: string): rect {
        if (!root.shown || root.layoutPreset !== "free")
            return Qt.rect(0, 0, 0, 0)
        const def = RaohaneDesktopWidgetRegistry.definition(id)
        if (!def || !RaohaneConfig[def.key])
            return Qt.rect(0, 0, 0, 0)
        const place = RaohaneConfig.desktopWidgetPlacement(root.monitorName, id)
        const s = (place?.size ?? 1) * RaohaneConfig.desktopWidgetsScale
        const faceWidth = Math.max(1, Math.min((root.width - 32) / Math.max(0.01, s),
            def.freeWidth ?? 280))
        const compactHeights = { clock: 154, context: 146, system: 122, motto: 40 }
        const faceHeight = root.compact ? compactHeights[id] : def.freeHeight
        const w = faceWidth * s
        const h = faceHeight * s
        return Qt.rect(
            Math.max(0, root.width - w) * (place?.x ?? 0),
            Math.max(0, root.height - h) * (place?.y ?? 0),
            w, h)
    }

    function openWidgetContext(widgetId: string, x: real, y: real): void {
        if (!root.shown || !root.screen || RaohaneState.screenLocked)
            return
        RaohaneState.desktopMenuScreen = root.screen
        RaohaneState.desktopMenuX = x
        RaohaneState.desktopMenuY = y
        RaohaneState.desktopMenuWidgetId = widgetId
        RaohaneState.desktopMenuWidgetMonitor = root.monitorName
        RaohaneState.setPrimaryOpen("desktopMenu", true)
    }

    opacity: shown ? RaohaneConfig.desktopWidgetsOpacity : 0
    // In free mode the global scale is applied per widget, so coordinate
    // clamping still uses the physical monitor bounds, not a scaled canvas.
    scale: root.layoutPreset === "free" ? 1 : RaohaneConfig.desktopWidgetsScale
    transformOrigin: Item.Center
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: RaohaneMotion.standard
            easing.type: RaohaneMotion.easeStandard
        }
    }

    // Free mode is additive. Keep the rail layout and its saved order intact
    // so returning to Balanced/Left/Right never changes previous preferences.
    Item {
        id: freeLayer
        anchors.fill: parent
        visible: root.layoutPreset === "free"

        Repeater {
            model: RaohaneDesktopWidgetRegistry.widgetIds

            delegate: Item {
                id: placedWidget
                required property var modelData
                readonly property string widgetId: String(modelData)
                readonly property var definition: RaohaneDesktopWidgetRegistry.definition(widgetId)
                readonly property var placement: RaohaneConfig.desktopWidgetPlacement(root.monitorName, widgetId)
                readonly property real itemSize: placement?.size ?? 1
                readonly property real renderedScale: itemSize * RaohaneConfig.desktopWidgetsScale

                // Scale the face, not the whole desktop canvas. A narrow
                // monitor still keeps an enlarged face within its right edge.
                width: Math.max(1, Math.min(
                    (root.width - 32) / Math.max(0.01, renderedScale),
                    definition?.freeWidth ?? 280))
                height: widgetContent.implicitHeight
                scale: renderedScale
                transformOrigin: Item.TopLeft
                x: Math.max(0, root.width - width * renderedScale) * (placement?.x ?? 0)
                y: Math.max(0, root.height - height * renderedScale) * (placement?.y ?? 0)

                RaohaneDesktopWidgetHost {
                    id: widgetContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    widgetId: placedWidget.widgetId
                    compact: root.compact
                    shown: root.shown && root.layoutPreset === "free"
                    onWidgetMenuRequested: (id, x, y) => root.openWidgetContext(id, x, y)
                }
            }
        }
    }

    ColumnLayout {
        id: primaryColumn
        visible: root.layoutPreset !== "free"

        x: root.layoutPreset === "right" ? parent.width - width - root.edge : root.edge
        y: root.compact ? 68 : 82
        width: Math.min(root.compact ? 350 : 480, parent.width * 0.42)
        spacing: root.compact ? 8 : 9

        Repeater {
            model: root.primaryWidgetIds

            delegate: RaohaneDesktopWidgetHost {
                required property var modelData

                widgetId: String(modelData)
                compact: root.compact
                shown: root.shown && root.layoutPreset !== "free"
                onWidgetMenuRequested: (id, x, y) => root.openWidgetContext(id, x, y)
            }
        }
    }

    ColumnLayout {
        id: secondaryColumn
        visible: root.layoutPreset !== "free"

        x: root.layoutPreset === "left" ? root.edge : parent.width - width - root.edge
        y: root.layoutPreset === "balanced"
            ? parent.height - height - (RaohaneConfig.dockEnabled ? (root.compact ? 96 : 112) : root.edge)
            : Math.min(parent.height - height - root.edge, primaryColumn.y + primaryColumn.height + 12)
        width: root.cardWidth
        spacing: 8

        Repeater {
            model: root.secondaryWidgetIds

            delegate: RaohaneDesktopWidgetHost {
                required property var modelData

                widgetId: String(modelData)
                compact: root.compact
                shown: root.shown && root.layoutPreset !== "free"
                onWidgetMenuRequested: (id, x, y) => root.openWidgetContext(id, x, y)
            }
        }
    }
}
