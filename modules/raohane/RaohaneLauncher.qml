import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

import qs.modules.raohane.models
import qs.modules.raohane.services

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    readonly property var results: RaohaneSearch.results.slice(0, 9)

    RaohaneSelectionModel {
        id: selection
        count: root.results.length
    }

    function close(): void {
        RaohaneState.setPrimaryOpen("launcher", false)
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
        screen: root.focusedScreen
        exclusiveZone: 0
        implicitWidth: 720
        implicitHeight: Math.min(620, launcherSurface.implicitHeight + 18)
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
        margins.top: 86

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

        Rectangle {
            anchors.centerIn: launcherSurface
            width: launcherSurface.width + 14
            height: launcherSurface.height + 14
            radius: RaohaneTheme.radiusHero + 5
            color: "transparent"
            border.width: 4
            border.color: "#20c56cff"
        }

        RaohaneSurface {
            id: launcherSurface

            anchors.horizontalCenter: parent.horizontalCenter
            width: 672
            implicitHeight: content.implicitHeight + 30
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            border.color: RaohaneTheme.accentBorder
            clip: true

            ColumnLayout {
                id: content

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 15
                }
                spacing: 9

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    spacing: 8

                    Text {
                        text: "RAOHANE / SEARCH"
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.2
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: qsTr("apps · actions · commands · clipboard")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                    }
                }

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 58
                    surfaceRadius: 19
                    hovered: searchInput.activeFocus
                    active: searchInput.activeFocus

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 13
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 13
                            color: RaohaneTheme.accentSoft
                            border.width: 1
                            border.color: RaohaneTheme.accentGlow

                            Text {
                                anchors.centerIn: parent
                                text: "ラ"
                                color: RaohaneTheme.text
                                font.pixelSize: 14
                                font.weight: Font.Bold
                            }
                        }

                        TextInput {
                            id: searchInput

                            Layout.fillWidth: true
                            color: RaohaneTheme.text
                            selectionColor: RaohaneTheme.accentSoft
                            selectedTextColor: RaohaneTheme.text
                            font.pixelSize: 16
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

                        Rectangle {
                            implicitWidth: escText.implicitWidth + 14
                            implicitHeight: 24
                            radius: 9
                            color: "#18ffffff"
                            border.width: 1
                            border.color: RaohaneTheme.borderFaint

                            Text {
                                id: escText
                                anchors.centerIn: parent
                                text: "esc"
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 8
                                font.weight: Font.Medium
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: root.results.length > 0

                    Repeater {
                        model: root.results

                        delegate: RaohaneSurface {
                            id: resultRow
                            required property var modelData
                            required property int index

                            readonly property bool selected: index === selection.currentIndex

                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            surfaceRadius: 16
                            active: selected
                            hovered: resultMouse.containsMouse
                            showSheen: selected

                            Rectangle {
                                visible: resultRow.selected
                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 1
                                }
                                width: 3
                                height: 22
                                radius: 2
                                color: RaohaneTheme.accentSecondary
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 13
                                spacing: 11

                                Rectangle {
                                    Layout.preferredWidth: 34
                                    Layout.preferredHeight: 34
                                    radius: 12
                                    color: resultRow.selected
                                        ? "#24ffffff"
                                        : "#12ffffff"
                                    border.width: 1
                                    border.color: resultRow.selected
                                        ? RaohaneTheme.accentGlow
                                        : RaohaneTheme.borderFaint

                                    Loader {
                                        anchors.centerIn: parent
                                        width: 28
                                        height: 28
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
                                    spacing: 0

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

                                Rectangle {
                                    visible: verbText.text.length > 0
                                    implicitWidth: verbText.implicitWidth + 14
                                    implicitHeight: 24
                                    radius: 9
                                    color: resultRow.selected ? RaohaneTheme.accentSoft : "#10ffffff"

                                    Text {
                                        id: verbText
                                        anchors.centerIn: parent
                                        text: resultRow.modelData.verb
                                        color: resultRow.selected ? RaohaneTheme.accent : RaohaneTheme.textFaint
                                        font.pixelSize: 8
                                        font.weight: Font.Medium
                                    }
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
                    Layout.preferredHeight: 96
                    visible: root.results.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: RaohaneSearch.query.length === 0 ? qsTr("Search Raohane") : qsTr("No results")
                            color: RaohaneTheme.text
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("/ actions    > commands    = math    : clipboard")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.borderFaint
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4

                    Text {
                        text: "ラオハネ"
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        font.letterSpacing: 1.3
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
        function toggle(): void { RaohaneState.togglePrimary("launcher") }
        function open(): void { RaohaneState.setPrimaryOpen("launcher", true) }
        function close(): void { RaohaneState.setPrimaryOpen("launcher", false) }
    }

    CompositorGlobalShortcut {
        name: "raohaneLauncherToggle"
        description: "Toggles the Raohane launcher"
        onPressed: RaohaneState.togglePrimary("launcher")
    }
}
