pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

RaohaneSurface {
    id: root

    required property int workspaceId
    property var workspaceObject: null
    property int cardIndex: -1
    property bool activeWorkspace: false
    property bool selected: false
    property string shortcutLabel: ""
    readonly property var windows: root.workspaceObject?.toplevels?.values ?? []
    readonly property bool urgent: root.windows.some(toplevel => Boolean(toplevel?.urgent))
    readonly property var focusedWindow: root.windows.find(toplevel => Boolean(toplevel?.activated)) ?? null
    readonly property string focusedTitle: String(root.focusedWindow?.title ?? "")

    signal hoveredIndex(int index)
    signal workspaceActivated(int workspaceId)
    signal windowActivated(var toplevel)

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: 128
    surfaceRadius: 17
    raised: root.activeWorkspace || root.selected
    hovered: workspaceMouse.containsMouse || activeFocus
    pressed: workspaceMouse.pressed
    interactive: true
    showSheen: false
    hoverScale: 1.008
    pressedScale: 0.994
    activeFocusOnTab: true
    border.color: root.urgent ? RaohaneTheme.critical
        : root.activeWorkspace ? RaohaneTheme.accentBorder
        : root.selected ? RaohaneTheme.borderStrong
        : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.border

    Rectangle {
        visible: root.activeWorkspace || root.urgent
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            leftMargin: 3
            topMargin: 12
            bottomMargin: 12
        }
        width: 2
        radius: 1
        color: root.urgent ? RaohaneTheme.critical : RaohaneTheme.accent

        Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
    }

    ColumnLayout {
        z: 1
        anchors.fill: parent
        anchors.margins: 12
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: -2

                Text {
                    text: String(root.workspaceId).padStart(2, "0")
                    color: root.urgent ? RaohaneTheme.critical
                        : root.activeWorkspace ? RaohaneTheme.accent : RaohaneTheme.text
                    font.pixelSize: 18
                    font.weight: Font.Medium

                    Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                }

                Text {
                    visible: root.focusedTitle.length > 0
                    Layout.fillWidth: true
                    text: root.focusedTitle
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                    elide: Text.ElideRight
                }
            }

            RaohaneIcon {
                visible: root.urgent
                text: "priority_high"
                iconSize: 15
                fill: 1
                color: RaohaneTheme.critical
            }

            RaohaneSurface {
                visible: root.shortcutLabel.length > 0
                implicitWidth: 21
                implicitHeight: 21
                surfaceRadius: 7
                transparentIdle: !root.selected
                active: root.selected
                showSheen: false

                Text {
                    anchors.centerIn: parent
                    text: root.shortcutLabel
                    color: root.selected ? RaohaneTheme.accent : RaohaneTheme.textFaint
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                }
            }

            RaohaneSurface {
                visible: root.activeWorkspace
                implicitWidth: activeText.implicitWidth + 12
                implicitHeight: 21
                surfaceRadius: 7
                active: true
                showSheen: false

                Text {
                    id: activeText
                    anchors.centerIn: parent
                    text: qsTr("Active")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: root.urgent ? RaohaneTheme.critical : RaohaneTheme.borderFaint
            opacity: root.urgent ? 0.42 : 1

            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            Repeater {
                model: root.windows.slice(0, 4)

                delegate: RaohaneOverviewWindowRow {
                    required property var modelData
                    toplevel: modelData
                    onHoveredChanged: {
                        if (hovered)
                            root.hoveredIndex(root.cardIndex)
                    }
                    onActivated: toplevel => root.windowActivated(toplevel)
                }
            }

            Text {
                visible: root.windows.length === 0
                text: qsTr("Empty workspace")
                color: RaohaneTheme.textFaint
                font.pixelSize: 8
            }

            Item { Layout.fillHeight: true }
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: qsTr("%1 windows").arg(root.windows.length)
                color: root.urgent ? RaohaneTheme.critical : RaohaneTheme.textFaint
                font.pixelSize: 7
            }
            Item { Layout.fillWidth: true }
            Text {
                visible: root.windows.length > 4
                text: "+" + (root.windows.length - 4)
                color: RaohaneTheme.textMuted
                font.pixelSize: 7
                font.weight: Font.DemiBold
            }
        }
    }

    MouseArea {
        id: workspaceMouse
        anchors.fill: parent
        z: 0
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onPressed: root.forceActiveFocus()
        onEntered: root.hoveredIndex(root.cardIndex)
        onClicked: root.workspaceActivated(root.workspaceId)
    }
}
