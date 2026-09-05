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

    ColumnLayout {
        id: primaryColumn

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
                shown: root.shown
            }
        }
    }

    ColumnLayout {
        id: secondaryColumn

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
                shown: root.shown
            }
        }
    }
}
