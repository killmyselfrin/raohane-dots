import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

import qs.services
import qs.modules.common.widgets
import qs.modules.raohane.services

Scope {
    id: root

    property int selectedIndex: 0
    readonly property var results: RaohaneSearch.results.slice(0, 9)

    function close(): void {
        RaohaneState.launcherOpen = false
    }

    function reset(): void {
        selectedIndex = 0
        RaohaneSearch.query = ""
    }

    function executeSelected(): void {
        if (root.results.length === 0)
            return
        const index = Math.max(0, Math.min(root.selectedIndex, root.results.length - 1))
        const result = root.results[index]
        if (!result || !result.execute)
            return
        root.close()
        result.execute()
    }

    PanelWindow {
        id: panelWindow
        visible: RaohaneState.launcherOpen
        exclusiveZone: 0
        implicitWidth: 620
        implicitHeight: Math.min(590, shell.implicitHeight)
        color: "transparent"

        WlrLayershell.namespace: "quickshell:raohane-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: RaohaneState.launcherOpen
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

        anchors {
            top: true
            left: true
            right: true
        }

        margins.top: 92

        onVisibleChanged: {
            if (visible) {
                root.reset()
                GlobalFocusGrab.addDismissable(panelWindow)
                searchInput.forceActiveFocus()
            } else {
                GlobalFocusGrab.removeDismissable(panelWindow)
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed(): void {
                root.close()
            }
        }

        Rectangle {
            id: shell
            anchors.horizontalCenter: parent.horizontalCenter
            width: 590
            implicitHeight: content.implicitHeight + 28
            radius: 28
            color: RaohaneTheme.glassStrong
            border.width: 1
            border.color: RaohaneTheme.border
            clip: true

            Rectangle {
                width: 4
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                color: RaohaneTheme.accent
                opacity: 0.9
            }

            ColumnLayout {
                id: content
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 14
                }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    spacing: 10

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 12
                        color: RaohaneTheme.accentSoft
                        border.width: 1
                        border.color: RaohaneTheme.border

                        Text {
                            anchors.centerIn: parent
                            text: "ラ"
                            color: RaohaneTheme.accent
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: RaohaneTheme.text
                        selectionColor: RaohaneTheme.accentSoft
                        selectedTextColor: RaohaneTheme.text
                        font.pixelSize: 17
                        clip: true
                        text: RaohaneSearch.query

                        onTextChanged: {
                            if (RaohaneSearch.query !== text)
                                RaohaneSearch.query = text
                            root.selectedIndex = 0
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                root.close()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Down) {
                                if (root.results.length > 0)
                                    root.selectedIndex = Math.min(root.selectedIndex + 1, root.results.length - 1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.executeSelected()
                                event.accepted = true
                            }
                        }
                    }

                    Rectangle {
                        width: 42
                        height: 28
                        radius: 14
                        color: "#2affffff"

                        Text {
                            anchors.centerIn: parent
                            text: "ESC"
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: RaohaneTheme.border
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    visible: root.results.length > 0

                    Repeater {
                        model: root.results

                        delegate: Rectangle {
                            id: resultRow
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            radius: 15
                            color: index === root.selectedIndex
                                ? RaohaneTheme.accentSoft
                                : resultMouse.containsMouse ? "#20ffffff" : "transparent"
                            border.width: index === root.selectedIndex ? 1 : 0
                            border.color: RaohaneTheme.border

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10

                                Item {
                                    width: 30
                                    height: 30

                                    Loader {
                                        anchors.fill: parent
                                        sourceComponent: {
                                            if (resultRow.modelData.iconType === "system")
                                                return systemIcon
                                            if (resultRow.modelData.iconType === "material")
                                                return materialIcon
                                            if (resultRow.modelData.iconType === "text")
                                                return textIcon
                                            return fallbackIcon
                                        }
                                    }

                                    Component {
                                        id: systemIcon
                                        IconImage {
                                            implicitSize: 28
                                            source: Quickshell.iconPath(resultRow.modelData.iconName, "image-missing")
                                        }
                                    }

                                    Component {
                                        id: materialIcon
                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: resultRow.modelData.iconName
                                            iconSize: 22
                                            color: RaohaneTheme.accent
                                        }
                                    }

                                    Component {
                                        id: textIcon
                                        Text {
                                            anchors.centerIn: parent
                                            text: resultRow.modelData.iconName
                                            color: RaohaneTheme.text
                                            font.pixelSize: 18
                                        }
                                    }

                                    Component {
                                        id: fallbackIcon
                                        Text {
                                            anchors.centerIn: parent
                                            text: "◇"
                                            color: RaohaneTheme.textMuted
                                            font.pixelSize: 17
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        text: resultRow.modelData.name
                                        color: RaohaneTheme.text
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: resultRow.modelData.comment || resultRow.modelData.type
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    text: resultRow.modelData.verb
                                    visible: text.length > 0
                                    color: index === root.selectedIndex
                                        ? RaohaneTheme.accent
                                        : RaohaneTheme.textMuted
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }
                            }

                            MouseArea {
                                id: resultMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.selectedIndex = resultRow.index
                                onClicked: {
                                    root.selectedIndex = resultRow.index
                                    root.executeSelected()
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 88
                    radius: 18
                    color: "#1810141d"
                    visible: root.results.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: RaohaneSearch.query.length === 0
                                ? qsTr("Start typing")
                                : qsTr("No results")
                            color: RaohaneTheme.text
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("Apps · / actions · > commands · = math · : clipboard")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24

                    Text {
                        text: "RAOHANE / LAUNCHER"
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 9
                        font.letterSpacing: 0.9
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "↑↓  NAVIGATE   ↵  OPEN"
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 9
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "raohaneLauncher"

        function toggle(): void {
            RaohaneState.launcherOpen = !RaohaneState.launcherOpen
        }

        function open(): void {
            RaohaneState.launcherOpen = true
        }

        function close(): void {
            RaohaneState.launcherOpen = false
        }
    }

    CompositorGlobalShortcut {
        name: "raohaneLauncherToggle"
        description: "Toggles the Raohane launcher"
        onPressed: RaohaneState.launcherOpen = !RaohaneState.launcherOpen
    }
}
