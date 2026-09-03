pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    property var screen
    property bool shown: true

    readonly property bool compact: RaohaneConfig.desktopWidgetsCompact || width < 1280
    readonly property int edge: compact ? 34 : 54
    readonly property int cardWidth: compact ? 238 : 294
    readonly property string layoutPreset: RaohaneConfig.desktopWidgetsLayout
    readonly property var primaryWidgetIds: RaohaneDesktopWidgetRegistry.idsForZone("primary")
    readonly property var secondaryWidgetIds: RaohaneDesktopWidgetRegistry.idsForZone("secondary")

    opacity: shown ? RaohaneConfig.desktopWidgetsOpacity : 0
    scale: RaohaneConfig.desktopWidgetsScale
    transformOrigin: Item.Center
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: RaohaneMotion.relaxed
            easing.type: RaohaneMotion.easeStandard
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: RaohaneMotion.relaxed
            easing.type: RaohaneMotion.easeEmphasized
        }
    }

    ColumnLayout {
        id: primaryColumn

        x: root.layoutPreset === "right" ? parent.width - width - root.edge : root.edge
        y: root.compact ? 72 : 92
        width: Math.min(root.compact ? 370 : 510, parent.width * 0.44)
        spacing: 12

        Behavior on x {
            NumberAnimation {
                duration: RaohaneMotion.relaxed
                easing.type: RaohaneMotion.easeEmphasized
            }
        }

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
            ? parent.height - height - (RaohaneConfig.dockEnabled ? (root.compact ? 104 : 122) : root.edge)
            : Math.min(parent.height - height - root.edge, primaryColumn.y + primaryColumn.height + 16)
        width: root.cardWidth
        spacing: 10

        Behavior on x {
            NumberAnimation {
                duration: RaohaneMotion.relaxed
                easing.type: RaohaneMotion.easeEmphasized
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: RaohaneMotion.relaxed
                easing.type: RaohaneMotion.easeEmphasized
            }
        }

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
