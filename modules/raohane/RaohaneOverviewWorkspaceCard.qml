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
    Layout.minimumHeight: 148
    surfaceRadius: RaohaneTheme.radiusHero
    raised: false
    active: root.activeWorkspace || root.selected || root.urgent
    hovered: workspaceMouse.containsMouse || activeFocus
    pressed: workspaceMouse.pressed
    interactive: true
    showSheen: false
    showInnerRim: root.activeWorkspace || root.urgent
    hoverScale: 1
    pressedScale: 1
    activeFocusOnTab: true
    idleColor: RaohaneTheme.surfaceDeep
    hoverColor: RaohaneTheme.surfaceRaised
    pressedColor: RaohaneTheme.surfacePressed
    activeColor: root.urgent
        ? Qt.rgba(RaohaneTheme.critical.r, RaohaneTheme.critical.g, RaohaneTheme.critical.b, 0.06)
        : root.activeWorkspace
            ? Qt.rgba(RaohaneTheme.accent.r, RaohaneTheme.accent.g, RaohaneTheme.accent.b, 0.08)
            : RaohaneTheme.surfaceRaised
    idleBorderColor: RaohaneTheme.borderFaint
    hoverBorderColor: RaohaneTheme.borderStrong
    pressedBorderColor: RaohaneTheme.borderStrong
    activeBorderColor: root.urgent
        ? RaohaneTheme.critical
        : root.activeWorkspace ? RaohaneTheme.accentBorder : RaohaneTheme.borderStrong
    showStateRail: root.activeWorkspace || root.urgent || root.selected
    stateRailColor: root.urgent ? RaohaneTheme.critical : RaohaneTheme.accent
    stateRailOpacity: root.urgent || root.activeWorkspace ? 1 : 0.46
    stateRailWidth: 3
    stateRailLength: Math.max(30, height - 2 * RaohaneTheme.panelPadding)

    ColumnLayout {
        z: 1
        anchors.fill: parent
        anchors.margins: RaohaneTheme.panelPadding + 1
        spacing: RaohaneTheme.spacingSmall + 2

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            spacing: RaohaneTheme.spacingSmall + 2

            Text {
                text: String(root.workspaceId).padStart(2, "0")
                color: root.urgent ? RaohaneTheme.critical
                    : root.activeWorkspace ? RaohaneTheme.accent : RaohaneTheme.text
                font.pixelSize: 25
                font.weight: Font.Medium
                font.letterSpacing: -0.7

                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
            }

            Rectangle {
                width: 1
                height: 28
                color: RaohaneTheme.borderFaint
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.max(1, RaohaneTheme.spacingTiny - 2)

                Text {
                    Layout.fillWidth: true
                    text: root.focusedTitle.length > 0
                        ? root.focusedTitle
                        : (root.activeWorkspace ? qsTr("Active") : qsTr("Empty workspace"))
                    color: root.focusedTitle.length > 0 ? RaohaneTheme.text : RaohaneTheme.textFaint
                    font.pixelSize: 9
                    font.weight: root.focusedTitle.length > 0 ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                }

                Text {
                    text: qsTr("%1 windows").arg(root.windows.length)
                    color: root.urgent ? RaohaneTheme.critical : RaohaneTheme.textFaint
                    font.pixelSize: 7
                    font.weight: Font.Medium
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
                implicitWidth: 24
                implicitHeight: 24
                surfaceRadius: RaohaneTheme.radiusTiny
                transparentIdle: !root.selected
                active: root.selected
                showSheen: false
                showInnerRim: false
                idleBorderColor: RaohaneTheme.borderFaint
                activeBorderColor: RaohaneTheme.accentBorder

                Text {
                    anchors.centerIn: parent
                    text: root.shortcutLabel
                    color: root.selected ? RaohaneTheme.accent : RaohaneTheme.textFaint
                    font.pixelSize: 8
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
                spacing: RaohaneTheme.spacingSmall - 1

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
                        spacing: RaohaneTheme.spacingSmall

                        RaohaneIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "crop_square"
                            iconSize: 21
                            symbolWeight: 320
                            color: RaohaneTheme.textFaint
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("Empty workspace")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                        }
                    }
                }

                Item { Layout.fillHeight: root.windows.length > 0 }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 18
            spacing: RaohaneTheme.spacingSmall

            Rectangle {
                width: root.activeWorkspace ? 16 : 6
                height: 4
                radius: 2
                color: root.urgent ? RaohaneTheme.critical
                    : root.activeWorkspace ? RaohaneTheme.accent : RaohaneTheme.textFaint
                opacity: root.activeWorkspace || root.urgent ? 1 : 0.42
            }

            Text {
                visible: root.activeWorkspace
                text: qsTr("Active")
                color: RaohaneTheme.accent
                font.pixelSize: 7
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            Text {
                visible: root.windows.length > 4
                text: "+" + (root.windows.length - 4)
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
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
