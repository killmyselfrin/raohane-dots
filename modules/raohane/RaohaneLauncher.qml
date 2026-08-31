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
        implicitWidth: 684
        implicitHeight: Math.min(600, launcherSurface.implicitHeight + 18)
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
                launcherSurface.entered = false
                Qt.callLater(() => launcherSurface.entered = true)
                RaohaneFocusGrab.addDismissable(panelWindow)
                searchInput.forceActiveFocus()
            } else {
                launcherSurface.entered = false
                RaohaneFocusGrab.removeDismissable(panelWindow)
            }
        }

        Connections {
            target: RaohaneFocusGrab
            function onDismissed(): void { root.close() }
        }

        RaohaneSurface {
            id: launcherSurface
            property bool entered: false

            anchors.horizontalCenter: parent.horizontalCenter
            width: 640
            implicitHeight: content.implicitHeight + 28
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            clip: true
            opacity: entered ? 1 : 0
            scale: entered ? 1 : 0.985
            y: entered ? 0 : -10

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
            }
            Behavior on scale {
                NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
            }
            Behavior on y {
                NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
            }

            ColumnLayout {
                id: content

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 14
                }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    Layout.leftMargin: 3
                    Layout.rightMargin: 3
                    spacing: 8

                    Text {
                        text: qsTr("Raohane Search")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
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
                    Layout.preferredHeight: 56
                    surfaceRadius: 17
                    raised: true
                    hovered: searchInput.activeFocus
                    showSheen: false
                    border.color: searchInput.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 13
                        anchors.rightMargin: 12
                        spacing: 11

                        RaohaneSurface {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            surfaceRadius: 11
                            showSheen: false
                            active: searchInput.activeFocus

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: "search"
                                iconSize: 18
                                fill: searchInput.activeFocus ? 1 : 0
                                symbolWeight: searchInput.activeFocus ? 540 : 440
                                color: searchInput.activeFocus ? RaohaneTheme.accent : RaohaneTheme.textMuted

                                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                            }
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

                        RaohaneSurface {
                            implicitWidth: escText.implicitWidth + 14
                            implicitHeight: 23
                            surfaceRadius: 8
                            transparentIdle: true
                            showSheen: false

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
                    spacing: 3
                    visible: root.results.length > 0

                    Repeater {
                        model: root.results

                        delegate: RaohaneSurface {
                            id: resultRow
                            required property var modelData
                            required property int index

                            readonly property bool selected: index === selection.currentIndex

                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            surfaceRadius: 14
                            active: selected
                            hovered: resultMouse.containsMouse || activeFocus
                            pressed: resultMouse.pressed
                            interactive: true
                            transparentIdle: !selected
                            showSheen: false
                            hoverScale: 1.006
                            pressedScale: 0.992
                            activeFocusOnTab: true

                            Rectangle {
                                visible: resultRow.selected
                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 3
                                }
                                width: 2
                                height: 20
                                radius: 1
                                color: RaohaneTheme.accent

                                Behavior on height {
                                    NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeEmphasized }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 11
                                anchors.rightMargin: 12
                                spacing: 10

                                RaohaneSurface {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    surfaceRadius: 10
                                    active: resultRow.selected
                                    showSheen: false

                                    Loader {
                                        anchors.centerIn: parent
                                        width: 26
                                        height: 26
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
                                            implicitSize: 24
                                            source: Quickshell.iconPath(resultRow.modelData.iconName, "image-missing")
                                        }
                                    }

                                    Component {
                                        id: materialIcon
                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: resultRow.modelData.iconName
                                            iconSize: 18
                                            fill: resultRow.selected ? 1 : 0
                                            symbolWeight: resultRow.selected ? 540 : 430
                                            color: resultRow.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                        }
                                    }

                                    Component {
                                        id: textIcon
                                        Text {
                                            anchors.centerIn: parent
                                            text: resultRow.modelData.iconName
                                            color: resultRow.selected ? RaohaneTheme.accent : RaohaneTheme.text
                                            font.pixelSize: 16
                                        }
                                    }

                                    Component {
                                        id: fallbackIcon
                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: "apps"
                                            iconSize: 17
                                            color: RaohaneTheme.textMuted
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
                                        font.pixelSize: 10
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

                                RaohaneSurface {
                                    visible: verbText.text.length > 0
                                    implicitWidth: verbText.implicitWidth + 13
                                    implicitHeight: 22
                                    surfaceRadius: 8
                                    transparentIdle: true
                                    showSheen: false
                                    active: resultRow.selected

                                    Text {
                                        id: verbText
                                        anchors.centerIn: parent
                                        text: resultRow.modelData.verb
                                        color: resultRow.selected ? RaohaneTheme.textMuted : RaohaneTheme.textFaint
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
                                onPressed: resultRow.forceActiveFocus()
                                onEntered: selection.select(resultRow.index)
                                onClicked: {
                                    selection.select(resultRow.index)
                                    root.executeSelected()
                                }
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                    selection.select(resultRow.index)
                                    root.executeSelected()
                                    event.accepted = true
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 92
                    visible: root.results.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: RaohaneSearch.query.length === 0 ? qsTr("Search Raohane") : qsTr("No results")
                            color: RaohaneTheme.text
                            font.pixelSize: 12
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
                    Layout.preferredHeight: 22
                    Layout.leftMargin: 3
                    Layout.rightMargin: 3

                    Text {
                        text: "RAOHANE"
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 7
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
