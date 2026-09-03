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
    readonly property var windows: root.workspaceObject?.toplevels?.values ?? []

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
    border.color: root.activeWorkspace ? RaohaneTheme.accentBorder
        : root.selected ? RaohaneTheme.borderStrong
        : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.border

    Rectangle {
        visible: root.activeWorkspace
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
        color: RaohaneTheme.accent
    }

    ColumnLayout {
        z: 1
        anchors.fill: parent
        anchors.margins: 12
        spacing: 7

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: String(root.workspaceId).padStart(2, "0")
                color: root.activeWorkspace ? RaohaneTheme.accent : RaohaneTheme.text
                font.pixelSize: 18
                font.weight: Font.Medium

                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
            }

            Item { Layout.fillWidth: true }

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
            color: RaohaneTheme.borderFaint
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
                color: RaohaneTheme.textFaint
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
