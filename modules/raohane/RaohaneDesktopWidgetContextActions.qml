pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

// Controls hosted inside the existing desktop context menu. One menu,
// one config owner and no new polling/overlay process.
ColumnLayout {
    id: root

    required property string widgetId
    required property string monitorName
    signal dismissRequested()

    readonly property var definition: RaohaneDesktopWidgetRegistry.definition(root.widgetId)
    readonly property var placement: RaohaneConfig.desktopWidgetPlacement(root.monitorName, root.widgetId)
    readonly property bool freeMode: RaohaneConfig.desktopWidgetsLayout === "free"

    spacing: 7

    function move(dx: real, dy: real): void {
        const p = root.placement
        if (!root.freeMode || !p)
            return
        RaohaneConfig.setDesktopWidgetPlacement(root.monitorName, root.widgetId,
            p.x + dx, p.y + dy, p.size)
    }

    function resize(delta: real): void {
        const p = root.placement
        if (!root.freeMode || !p)
            return
        RaohaneConfig.setDesktopWidgetPlacement(root.monitorName, root.widgetId,
            p.x, p.y, Math.round((p.size + delta) * 100) / 100)
    }

    function setPosition(x: real, y: real): void {
        const p = root.placement
        if (!root.freeMode || !p)
            return
        RaohaneConfig.setDesktopWidgetPlacement(root.monitorName, root.widgetId,
            x, y, p.size)
    }

    function reset(): void {
        const p = RaohaneConfig.defaultDesktopWidgetFreePlacements()[root.widgetId]
        if (!root.freeMode || !p)
            return
        RaohaneConfig.setDesktopWidgetPlacement(root.monitorName, root.widgetId,
            p.x, p.y, p.size)
    }

    RaohaneSurface {
        Layout.fillWidth: true
        Layout.preferredHeight: 70
        surfaceRadius: 10
        raised: false
        showSheen: false
        border.color: RaohaneTheme.accentBorder

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 11

            RaohaneIcon {
                text: root.definition?.icon ?? "widgets"
                iconSize: 22
                color: RaohaneTheme.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: root.definition?.title ?? qsTr("Desktop widget")
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: RaohaneTheme.text
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.monitorName + " · " + (root.freeMode
                        ? qsTr("Free layout") : qsTr("Preset layout"))
                    font.pixelSize: 9
                    color: RaohaneTheme.textMuted
                    elide: Text.ElideRight
                }
            }
        }
    }

    Action {
        Layout.fillWidth: true
        visible: !root.freeMode
        icon: "dashboard_customize"
        title: qsTr("Enable free positioning")
        detail: qsTr("Preserves your existing preset layout")
        onTriggered: RaohaneConfig.desktopWidgetsLayout = "free"
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 7
        visible: root.freeMode

        Text {
            text: qsTr("MOVE")
            color: RaohaneTheme.textFaint
            font.pixelSize: 9
            font.weight: Font.DemiBold
            font.letterSpacing: 1
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            Action { Layout.fillWidth: true; icon: "arrow_back"; title: qsTr("Left"); onTriggered: root.move(-0.05, 0) }
            Action { Layout.fillWidth: true; icon: "arrow_upward"; title: qsTr("Up"); onTriggered: root.move(0, -0.05) }
            Action { Layout.fillWidth: true; icon: "arrow_downward"; title: qsTr("Down"); onTriggered: root.move(0, 0.05) }
            Action { Layout.fillWidth: true; icon: "arrow_forward"; title: qsTr("Right"); onTriggered: root.move(0.05, 0) }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: qsTr("Size") + "  " + Math.round((root.placement?.size ?? 1) * 100) + "%"
                color: RaohaneTheme.text
                font.pixelSize: 11
                font.weight: Font.Medium
            }

            Action {
                Layout.preferredWidth: 70
                title: "−"
                icon: "remove"
                enabled: (root.placement?.size ?? 1) > 0.65
                onTriggered: root.resize(-0.05)
            }

            Action {
                Layout.preferredWidth: 70
                title: "+"
                icon: "add"
                enabled: (root.placement?.size ?? 1) < 1.4
                onTriggered: root.resize(0.05)
            }
        }

        Text {
            text: qsTr("QUICK POSITION")
            color: RaohaneTheme.textFaint
            font.pixelSize: 9
            font.weight: Font.DemiBold
            font.letterSpacing: 1
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            Action { Layout.fillWidth: true; icon: "north_west"; title: qsTr("Top left"); onTriggered: root.setPosition(0.03, 0.08) }
            Action { Layout.fillWidth: true; icon: "filter_center_focus"; title: qsTr("Center"); onTriggered: root.setPosition(0.5, 0.5) }
            Action { Layout.fillWidth: true; icon: "south_east"; title: qsTr("Bottom right"); onTriggered: root.setPosition(0.97, 0.87) }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            Action {
                Layout.fillWidth: true
                icon: "restart_alt"
                title: qsTr("Reset widget")
                onTriggered: root.reset()
            }

            Action {
                Layout.fillWidth: true
                icon: "visibility_off"
                title: qsTr("Hide widget")
                onTriggered: {
                    if (root.definition?.key) {
                        RaohaneConfig[root.definition.key] = false
                        root.dismissRequested()
                    }
                }
            }
        }
    }

    Action {
        Layout.fillWidth: true
        icon: "tune"
        title: qsTr("Open Widget Studio")
        detail: qsTr("Drag, resize, reorder and configure desktop widgets")
        onTriggered: RaohaneSettingsRouter.request("widgets", "")
    }

    component Action: RaohaneSurface {
        id: action

        required property string icon
        required property string title
        property string detail: ""
        signal triggered()

        Layout.preferredHeight: action.detail.length > 0 ? 44 : 34
        surfaceRadius: 9
        raised: false
        showSheen: false
        interactive: true
        hoverScale: 1
        pressedScale: 1
        hovered: actionMouse.containsMouse
        pressed: actionMouse.pressed
        border.color: hovered ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint
        color: hovered ? RaohaneTheme.surfaceSubtle : RaohaneTheme.surfaceDeep

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 9
            spacing: 6

            RaohaneIcon {
                text: action.icon
                iconSize: 14
                color: action.enabled ? RaohaneTheme.accent : RaohaneTheme.textFaint
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: action.title
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    color: action.enabled ? RaohaneTheme.text : RaohaneTheme.textFaint
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: action.detail.length > 0
                    text: action.detail
                    font.pixelSize: 8
                    color: RaohaneTheme.textMuted
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: action.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: action.triggered()
        }
    }
}
