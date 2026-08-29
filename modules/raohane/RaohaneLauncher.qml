import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

import qs.modules.raohane.models
import qs.modules.raohane.services

Scope {
    id: root

    readonly property var results: RaohaneSearch.results.slice(0, 9)

    RaohaneSelectionModel {
        id: selection
        count: root.results.length
    }

    function close(): void {
        RaohaneState.launcherOpen = false
    }

    function reset(): void {
        selection.reset()
        RaohaneSearch.query = ""
    }

    function executeSelected(): void {
        if (!selection.hasItems)
            return
        const result = root.results[selection.currentIndex]
        if (!result || !result.execute)
            return
        root.close()
        result.execute()
    }

    PanelWindow {
        id: panelWindow

        visible: RaohaneState.launcherOpen
        exclusiveZone: 0
        implicitWidth: 586
        implicitHeight: Math.min(560, launcherSurface.implicitHeight)
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
        margins.top: 78

        onVisibleChanged: {
            if (visible) {
                root.reset()
                RaohaneFocusGrab.addDismissable(panelWindow)
                searchInput.forceActiveFocus()
            } else {
                RaohaneFocusGrab.removeDismissable(panelWindow)
            }
        }

        Connections {
            target: RaohaneFocusGrab
            function onDismissed(): void { root.close() }
        }

        RaohaneSurface {
            id: launcherSurface

            anchors.horizontalCenter: parent.horizontalCenter
            width: 552
            implicitHeight: content.implicitHeight + 24
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: true
            clip: true

            ColumnLayout {
                id: content

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 12
                }
                spacing: 7

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    surfaceRadius: RaohaneTheme.radius
                    hovered: searchInput.activeFocus

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 13
                        anchors.rightMargin: 11
                        spacing: 10

                        Text {
                            text: "ラ"
                            color: RaohaneTheme.accent
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }

                        TextInput {
                            id: searchInput

                            Layout.fillWidth: true
                            color: RaohaneTheme.text
                            selectionColor: RaohaneTheme.accentSoft
                            selectedTextColor: RaohaneTheme.text
                            font.pixelSize: 15
                            clip: true
                            text: RaohaneSearch.query

                            onTextChanged: {
                                if (RaohaneSearch.query !== text)
                                    RaohaneSearch.query = text
                                selection.reset()
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    root.close()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Down) {
                                    selection.move(1)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Up) {
                                    selection.move(-1)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.executeSelected()
                                    event.accepted = true
                                }
                            }
                        }

                        Text {
                            text: "esc"
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 9
                            font.weight: Font.Medium
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: root.results.length > 0

                    Repeater {
                        model: root.results

                        delegate: RaohaneSurface {
                            id: resultRow
                            required property var modelData
                            required property int index

                            readonly property bool selected: index === selection.currentIndex

                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            surfaceRadius: RaohaneTheme.radiusSmall + 3
                            color: selected
                                ? RaohaneTheme.accentSoft
                                : resultMouse.containsMouse ? RaohaneTheme.surfaceHover : "transparent"
                            border.width: selected ? 1 : 0
                            border.color: selected ? RaohaneTheme.borderStrong : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 11
                                spacing: 10

                                Item {
                                    width: 28
                                    height: 28

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
                                            implicitSize: 26
                                            source: Quickshell.iconPath(resultRow.modelData.iconName, "image-missing")
                                        }
                                    }

                                    Component {
                                        id: materialIcon
                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: resultRow.modelData.iconName
                                            iconSize: 19
                                            color: resultRow.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                        }
                                    }

                                    Component {
                                        id: textIcon
                                        Text {
                                            anchors.centerIn: parent
                                            text: resultRow.modelData.iconName
                                            color: resultRow.selected ? RaohaneTheme.accent : RaohaneTheme.text
                                            font.pixelSize: 17
                                        }
                                    }

                                    Component {
                                        id: fallbackIcon
                                        Text {
                                            anchors.centerIn: parent
                                            text: "·"
                                            color: RaohaneTheme.textMuted
                                            font.pixelSize: 18
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: -1

                                    Text {
                                        Layout.fillWidth: true
                                        text: resultRow.modelData.name
                                        color: RaohaneTheme.text
                                        font.pixelSize: 11
                                        font.weight: resultRow.selected ? Font.DemiBold : Font.Medium
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: resultRow.modelData.comment || resultRow.modelData.type
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: 8
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    visible: text.length > 0
                                    text: resultRow.modelData.verb
                                    color: resultRow.selected ? RaohaneTheme.accent : RaohaneTheme.textFaint
                                    font.pixelSize: 8
                                    font.weight: Font.Medium
                                }
                            }

                            MouseArea {
                                id: resultMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: selection.select(resultRow.index)
                                onClicked: {
                                    selection.select(resultRow.index)
                                    root.executeSelected()
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 78
                    visible: root.results.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: RaohaneSearch.query.length === 0 ? qsTr("Search Raohane") : qsTr("No results")
                            color: RaohaneTheme.text
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("/ actions   > commands   = math   : clipboard")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    Layout.leftMargin: 3
                    Layout.rightMargin: 3

                    Text {
                        text: "RAOHANE"
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                        font.letterSpacing: 1.1
                        font.weight: Font.DemiBold
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "↑↓ navigate   ↵ open"
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "raohaneLauncher"
        function toggle(): void { RaohaneState.launcherOpen = !RaohaneState.launcherOpen }
        function open(): void { RaohaneState.launcherOpen = true }
        function close(): void { RaohaneState.launcherOpen = false }
    }

    CompositorGlobalShortcut {
        name: "raohaneLauncherToggle"
        description: "Toggles the Raohane launcher"
        onPressed: RaohaneState.launcherOpen = !RaohaneState.launcherOpen
    }
}
