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
    readonly property bool desktopEditActive: root.shown && !RaohaneState.screenLocked
        && RaohaneState.desktopWidgetEditMode
        && RaohaneState.desktopWidgetEditScreenName === root.monitorName
    readonly property int editGridStep: 32

    Keys.onPressed: event => {
        if (root.desktopEditActive && event.key === Qt.Key_Escape) {
            RaohaneState.desktopWidgetEditMode = false
            event.accepted = true
        }
    }

    readonly property var composition: RaohaneConfig.sanitizeDesktopWidgetComposition(RaohaneConfig.desktopWidgetComposition)
    readonly property var primaryWidgetIds: root.composition.primary
    readonly property var secondaryWidgetIds: root.composition.secondary

    // Expose exact input geometry to the desktop PanelWindow mask. The mask
    // covers only widgets, so empty wallpaper remains right-clickable.
    readonly property real railScale: RaohaneConfig.desktopWidgetsScale
    readonly property real railOffsetX: (root.width - root.width * root.railScale) / 2
    readonly property real railOffsetY: (root.height - root.height * root.railScale) / 2
    readonly property rect primaryHitRect: Qt.rect(
        root.railOffsetX + primaryColumn.x * root.railScale,
        root.railOffsetY + primaryColumn.y * root.railScale,
        root.shown && root.layoutPreset !== "free" ? primaryColumn.width * root.railScale : 0,
        root.shown && root.layoutPreset !== "free" ? primaryColumn.height * root.railScale : 0)
    readonly property rect secondaryHitRect: Qt.rect(
        root.railOffsetX + secondaryColumn.x * root.railScale,
        root.railOffsetY + secondaryColumn.y * root.railScale,
        root.shown && root.layoutPreset !== "free" ? secondaryColumn.width * root.railScale : 0,
        root.shown && root.layoutPreset !== "free" ? secondaryColumn.height * root.railScale : 0)

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

    opacity: root.desktopEditActive ? 1 : (shown ? RaohaneConfig.desktopWidgetsOpacity : 0)
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
                property bool editingInteraction: false
                property real workingX: 0
                property real workingY: 0
                property real workingSize: 1
                property real pointerStartX: 0
                property real pointerStartY: 0
                property real originX: 0
                property real originY: 0
                property real originSize: 1
                property real resizeReferenceWidth: 1
                property real resizeReferenceHeight: 1

                readonly property bool editMode: root.desktopEditActive
                readonly property bool selected: RaohaneState.desktopWidgetEditWidgetId === widgetId
                readonly property real renderedScale: (editingInteraction ? workingSize : itemSize)
                    * RaohaneConfig.desktopWidgetsScale
                readonly property real travelX: Math.max(0, root.width - width * renderedScale)
                readonly property real travelY: Math.max(0, root.height - height * renderedScale)

                width: Math.max(1, Math.min(
                    (root.width - 32) / Math.max(0.01, renderedScale),
                    definition?.freeWidth ?? 280))
                height: widgetContent.implicitHeight
                scale: renderedScale
                transformOrigin: Item.TopLeft
                x: editingInteraction ? workingX : travelX * (placement?.x ?? 0)
                y: editingInteraction ? workingY : travelY * (placement?.y ?? 0)
                z: editMode && selected ? 5 : 1

                function beginInteraction(px: real, py: real): void {
                    RaohaneState.desktopWidgetEditWidgetId = widgetId
                    workingX = x
                    workingY = y
                    workingSize = itemSize
                    pointerStartX = px
                    pointerStartY = py
                    originX = x
                    originY = y
                    originSize = itemSize
                    resizeReferenceWidth = Math.max(1, width * renderedScale)
                    resizeReferenceHeight = Math.max(1, height * renderedScale)
                    editingInteraction = true
                    root.forceActiveFocus()
                }

                function moveTo(px: real, py: real): void {
                    if (!editingInteraction)
                        return
                    workingX = Math.max(0, Math.min(travelX, originX + px - pointerStartX))
                    workingY = Math.max(0, Math.min(travelY, originY + py - pointerStartY))
                }

                function resizeTo(px: real, py: real): void {
                    if (!editingInteraction)
                        return
                    const dx = (px - pointerStartX) / resizeReferenceWidth
                    const dy = (py - pointerStartY) / resizeReferenceHeight
                    const delta = Math.abs(dx) >= Math.abs(dy) ? dx : dy
                    workingSize = Math.max(0.65, Math.min(1.4, originSize * (1 + delta)))
                    workingX = Math.max(0, Math.min(travelX, originX))
                    workingY = Math.max(0, Math.min(travelY, originY))
                }

                function finishInteraction(): void {
                    if (!editingInteraction)
                        return
                    const snapX = Math.max(0, Math.min(travelX,
                        Math.round(workingX / root.editGridStep) * root.editGridStep))
                    const snapY = Math.max(0, Math.min(travelY,
                        Math.round(workingY / root.editGridStep) * root.editGridStep))
                    const xFraction = travelX > 0 ? snapX / travelX : 0
                    const yFraction = travelY > 0 ? snapY / travelY : 0
                    RaohaneConfig.setDesktopWidgetPlacement(root.monitorName, widgetId,
                        xFraction, yFraction, workingSize)
                    editingInteraction = false
                }

                RaohaneDesktopWidgetHost {
                    id: widgetContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    widgetId: placedWidget.widgetId
                    compact: root.compact
                    shown: root.shown && root.layoutPreset === "free"
                    onWidgetMenuRequested: (id, px, py) => root.openWidgetContext(id, px, py)
                }

                // The edit handles belong to the actual widget, never a proxy
                // in a settings or gallery window.
                Rectangle {
                    anchors.fill: parent
                    visible: placedWidget.editMode && widgetContent.visible
                    radius: 12
                    color: "transparent"
                    border.width: placedWidget.selected ? 2 : 1
                    border.color: placedWidget.selected ? RaohaneTheme.accent : RaohaneTheme.accentBorder
                    z: 7

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.SizeAllCursor
                        onPressed: mouse => {
                            const p = mapToItem(root, mouse.x, mouse.y)
                            placedWidget.beginInteraction(p.x, p.y)
                        }
                        onPositionChanged: mouse => {
                            if (!pressed)
                                return
                            const p = mapToItem(root, mouse.x, mouse.y)
                            placedWidget.moveTo(p.x, p.y)
                        }
                        onReleased: placedWidget.finishInteraction()
                        onCanceled: placedWidget.editingInteraction = false
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        width: 25
                        height: 25
                        radius: 8
                        color: RaohaneTheme.accent
                        border.color: RaohaneTheme.surfaceDeep

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "open_in_full"
                            iconSize: 14
                            color: RaohaneTheme.background
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            cursorShape: Qt.SizeFDiagCursor
                            onPressed: mouse => {
                                const p = mapToItem(root, mouse.x, mouse.y)
                                placedWidget.beginInteraction(p.x, p.y)
                            }
                            onPositionChanged: mouse => {
                                if (!pressed)
                                    return
                                const p = mapToItem(root, mouse.x, mouse.y)
                                placedWidget.resizeTo(p.x, p.y)
                            }
                            onReleased: placedWidget.finishInteraction()
                            onCanceled: placedWidget.editingInteraction = false
                        }
                    }
                }
            }
        }

        // The grid is completely unloaded outside editing sessions, so
        // normal desktop rendering does not keep a fullscreen QML grid alive.
        Loader {
            id: editGridLoader
            anchors.fill: parent
            z: 30
            active: root.desktopEditActive
            visible: active
            // Loading by URL avoids a hard QML type dependency during shell
            // startup. A missing/broken edit-only file must not crash Raohane.
            source: active ? Qt.resolvedUrl("RaohaneDesktopEditGrid.qml") : ""

            onStatusChanged: {
                if (status === Loader.Error && root.desktopEditActive) {
                    console.warn("[Raohane] Desktop grid failed to load; leaving edit mode")
                    RaohaneState.desktopWidgetEditMode = false
                }
            }
        }

        Binding {
            target: editGridLoader.item
            property: "editing"
            value: root.desktopEditActive
            when: editGridLoader.item !== null
        }

        Binding {
            target: editGridLoader.item
            property: "monitorName"
            value: root.monitorName
            when: editGridLoader.item !== null
        }

        Connections {
            target: editGridLoader.item
            ignoreUnknownSignals: true
            function onDoneRequested(): void {
                RaohaneState.desktopWidgetEditMode = false
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
