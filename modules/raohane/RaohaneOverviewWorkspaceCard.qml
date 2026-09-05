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
    Layout.minimumHeight: 132
    surfaceRadius: 12
    raised: false
    hovered: workspaceMouse.containsMouse || activeFocus
    pressed: workspaceMouse.pressed
    interactive: true
    showSheen: false
    hoverScale: 1
    pressedScale: 1
    activeFocusOnTab: true
    border.color: root.urgent ? RaohaneTheme.critical
        : root.activeWorkspace ? RaohaneTheme.accentBorder
        : root.selected ? RaohaneTheme.borderStrong
        : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint
    color: root.activeWorkspace
        ? Qt.rgba(RaohaneTheme.accent.r, RaohaneTheme.accent.g, RaohaneTheme.accent.b, 0.075)
        : root.selected
            ? RaohaneTheme.surfaceRaised
            : RaohaneTheme.surfaceDeep

    Rectangle {
        visible: root.activeWorkspace || root.urgent || root.selected
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            leftMargin: 2
            topMargin: 10
            bottomMargin: 10
        }
        width: 2
        radius: 1
        color: root.urgent ? RaohaneTheme.critical : RaohaneTheme.accent
        opacity: root.urgent || root.activeWorkspace ? 1 : 0.44

        Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
        Behavior on opacity { NumberAnimation { duration: RaohaneMotion.micro } }
    }

    ColumnLayout {
        z: 1
        anchors.fill: parent
        anchors.margins: 11
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            spacing: 7

            Text {
                text: String(root.workspaceId).padStart(2, "0")
                color: root.urgent ? RaohaneTheme.critical
                    : root.activeWorkspace ? RaohaneTheme.accent : RaohaneTheme.text
                font.pixelSize: 23
                font.weight: Font.Medium
                font.letterSpacing: -0.6

                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
            }

            Rectangle {
                width: 1
                height: 24
                color: RaohaneTheme.borderFaint
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: root.focusedTitle.length > 0
                        ? root.focusedTitle
                        : (root.activeWorkspace ? qsTr("Active") : qsTr("Empty workspace"))
                    color: root.focusedTitle.length > 0 ? RaohaneTheme.text : RaohaneTheme.textFaint
                    font.pixelSize: 8
                    font.weight: root.focusedTitle.length > 0 ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                }

                Text {
                    text: qsTr("%1 windows").arg(root.windows.length)
                    color: root.urgent ? RaohaneTheme.critical : RaohaneTheme.textFaint
                    font.pixelSize: 6
                    font.weight: Font.Medium
                }
            }

            RaohaneIcon {
                visible: root.urgent
                text: "priority_high"
                iconSize: 14
                fill: 1
                color: RaohaneTheme.critical
            }

            RaohaneSurface {
                visible: root.shortcutLabel.length > 0
                implicitWidth: 22
                implicitHeight: 22
                surfaceRadius: 6
                transparentIdle: !root.selected
                active: root.selected
                showSheen: false
                border.color: root.selected ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                Text {
                    anchors.centerIn: parent
                    text: root.shortcutLabel
                    color: root.selected ? RaohaneTheme.accent : RaohaneTheme.textFaint
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.urgent ? RaohaneTheme.critical : RaohaneTheme.borderFaint
            opacity: root.urgent ? 0.38 : 1

            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
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

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.windows.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 5

                        RaohaneIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "crop_square"
                            iconSize: 19
                            symbolWeight: 320
                            color: RaohaneTheme.textFaint
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("Empty workspace")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                        }
                    }
                }

                Item { Layout.fillHeight: root.windows.length > 0 }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 16
            spacing: 5

            Rectangle {
                width: root.activeWorkspace ? 14 : 5
                height: 3
                radius: 1.5
                color: root.urgent ? RaohaneTheme.critical
                    : root.activeWorkspace ? RaohaneTheme.accent : RaohaneTheme.textFaint
                opacity: root.activeWorkspace || root.urgent ? 1 : 0.42
            }

            Text {
                visible: root.activeWorkspace
                text: qsTr("Active")
                color: RaohaneTheme.accent
                font.pixelSize: 6
                font.weight: Font.DemiBold
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
