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

    opacity: shown ? RaohaneConfig.desktopWidgetsOpacity : 0
    scale: RaohaneConfig.desktopWidgetsScale
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

                width: Math.max(1, Math.min(root.width - 32, definition?.freeWidth ?? 280))
                height: widgetContent.implicitHeight
                scale: itemSize
                transformOrigin: Item.TopLeft
                x: Math.max(0, root.width - width * itemSize) * (placement?.x ?? 0)
                y: Math.max(0, root.height - height * itemSize) * (placement?.y ?? 0)

                RaohaneDesktopWidgetHost {
                    id: widgetContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    widgetId: placedWidget.widgetId
                    compact: root.compact
                    shown: root.shown && root.layoutPreset === "free"
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
            }
        }
    }
}
