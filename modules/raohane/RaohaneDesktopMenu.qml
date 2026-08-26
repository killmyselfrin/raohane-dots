pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: root

    function openCentered(shouldOpen: bool): void {
        if (!shouldOpen) {
            GlobalStates.desktopMenuOpen = false
            return
        }
        const focusedName = Hyprland.focusedMonitor?.name
        const screen = Quickshell.screens.find(item => item.name === focusedName) ?? Quickshell.screens[0]
        GlobalStates.desktopMenuScreen = screen
        GlobalStates.desktopMenuX = screen.width / 2
        GlobalStates.desktopMenuY = screen.height / 2
        GlobalStates.desktopMenuOpen = true
    }

    function close(): void {
        GlobalStates.desktopMenuOpen = false
    }

    Loader {
        active: GlobalStates.desktopMenuOpen

        sourceComponent: PanelWindow {
            id: menuWindow

            screen: GlobalStates.desktopMenuScreen ?? Quickshell.screens[0]
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:raohane-desktop-menu"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: root.close()
            }

            Rectangle {
                id: menuCard
                width: 356
                implicitHeight: menuContent.implicitHeight + 20
                x: Math.min(Math.max(GlobalStates.desktopMenuX - width / 2, 10), menuWindow.width - width - 10)
                y: Math.min(Math.max(GlobalStates.desktopMenuY - implicitHeight / 2, 10), menuWindow.height - implicitHeight - 10)
                radius: 24
                color: RaohaneTheme.glassStrong
                border.width: 1
                border.color: RaohaneTheme.border
                clip: true

                scale: GlobalStates.desktopMenuOpen ? 1 : 0.94
                opacity: GlobalStates.desktopMenuOpen ? 1 : 0
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                Behavior on opacity { NumberAnimation { duration: 130 } }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                }

                ColumnLayout {
                    id: menuContent
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 10
                    }
                    spacing: 7

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 142
                        radius: 18
                        color: "#201b2a"
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: Config.options.background.wallpaperPath
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            opacity: status === Image.Ready ? 0.85 : 0
                        }

                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                GradientStop { position: 0.28; color: "#10120f19" }
                                GradientStop { position: 1.0; color: "#db120f19" }
                            }
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                margins: 10
                            }
                            width: brand.implicitWidth + 18
                            height: 27
                            radius: 14
                            color: "#be17131f"
                            border.width: 1
                            border.color: RaohaneTheme.border

                            Text {
                                id: brand
                                anchors.centerIn: parent
                                text: "RAOHANE / DESKTOP"
                                color: RaohaneTheme.text
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.9
                            }
                        }

                        Column {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                margins: 12
                            }
                            spacing: 1

                            Text {
                                width: parent.width
                                text: Config.options.background.wallpaperPath.split("/").pop() || qsTr("Wallpaper")
                                color: RaohaneTheme.text
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: qsTr("Right-click workspace controls")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MenuAction {
                        icon: "wallpaper"
                        title: qsTr("Wallpaper")
                        detail: qsTr("Browse and preview backgrounds")
                        accent: true
                        onTriggered: {
                            root.close()
                            GlobalStates.wallpaperSelectorTarget = "wallpaper"
                            GlobalStates.wallpaperSelectorOpen = true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 7

                        CompactAction {
                            Layout.fillWidth: true
                            icon: "casino"
                            title: qsTr("Random")
                            onTriggered: {
                                Wallpapers.randomFromCurrentFolder()
                                root.close()
                            }
                        }
                        CompactAction {
                            Layout.fillWidth: true
                            icon: "video_template"
                            title: qsTr("Live")
                            onTriggered: {
                                Wallpapers.openFallbackPicker(
                                    Appearance.m3colors.darkmode,
                                    Config.options.wallpaperSelector.liveWallpapersPath ?? ""
                                )
                                root.close()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: RaohaneTheme.border
                    }

                    MenuAction {
                        icon: "stacks"
                        title: qsTr("DropShelf")
                        detail: DropShelf.items.length > 0
                            ? qsTr("%1 items ready").arg(DropShelf.items.length)
                            : qsTr("Temporary files and drops")
                        onTriggered: {
                            const pointX = GlobalStates.desktopMenuX
                            const pointY = GlobalStates.desktopMenuY
                            root.close()
                            GlobalStates.dropShelfX = pointX
                            GlobalStates.dropShelfY = pointY
                            GlobalStates.dropShelfOpen = true
                        }
                    }

                    MenuAction {
                        icon: "widgets"
                        title: qsTr("Desktop & widgets")
                        detail: qsTr("Open desktop configuration")
                        onTriggered: {
                            root.close()
                            GlobalStates.settingsPage = "Desktop"
                            GlobalStates.settingsOpen = true
                        }
                    }

                    MenuAction {
                        icon: "tune"
                        title: qsTr("Control Center")
                        detail: qsTr("Network, audio, privacy and notifications")
                        onTriggered: {
                            root.close()
                            GlobalStates.sidebarRightOpen = true
                        }
                    }

                    MenuAction {
                        icon: "settings"
                        title: qsTr("Settings")
                        detail: qsTr("Configure Raohane")
                        onTriggered: {
                            root.close()
                            GlobalStates.settingsOpen = true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        spacing: 7

                        CompactAction {
                            Layout.fillWidth: true
                            icon: "refresh"
                            title: qsTr("Reload")
                            onTriggered: {
                                root.close()
                                Quickshell.execDetached(["hyprctl", "reload"])
                                Quickshell.reload(true)
                            }
                        }
                        CompactAction {
                            Layout.fillWidth: true
                            icon: "power_settings_new"
                            title: qsTr("Session")
                            onTriggered: {
                                root.close()
                                GlobalStates.sessionOpen = true
                            }
                        }
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.close()
                        event.accepted = true
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "raohaneDesktop"
        function toggle(): void { root.openCentered(!GlobalStates.desktopMenuOpen) }
        function open(): void { root.openCentered(true) }
        function close(): void { root.close() }
    }

    component MenuAction: Rectangle {
        id: action
        required property string icon
        required property string title
        property string detail: ""
        property bool accent: false
        signal triggered()

        Layout.fillWidth: true
        Layout.preferredHeight: 54
        radius: 16
        color: action.accent || actionMouse.containsMouse ? RaohaneTheme.accentSoft : "#4217131f"
        border.width: 1
        border.color: action.accent || actionMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.border

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 11
            anchors.rightMargin: 10
            spacing: 9

            Rectangle {
                width: 32
                height: 32
                radius: 11
                color: "#20ffffff"

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: action.icon
                    iconSize: 18
                    color: action.accent ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: -1

                Text {
                    Layout.fillWidth: true
                    text: action.title
                    color: RaohaneTheme.text
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: action.detail
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                    elide: Text.ElideRight
                }
            }

            MaterialSymbol {
                text: "chevron_right"
                iconSize: 16
                color: actionMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.triggered()
        }
    }

    component CompactAction: Rectangle {
        id: compact
        required property string icon
        required property string title
        signal triggered()

        Layout.preferredHeight: 38
        radius: 13
        color: compactMouse.containsMouse ? RaohaneTheme.accentSoft : "#4217131f"
        border.width: 1
        border.color: compactMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.border

        Row {
            anchors.centerIn: parent
            spacing: 7
            MaterialSymbol { text: compact.icon; iconSize: 15; color: RaohaneTheme.textMuted }
            Text {
                text: compact.title
                color: RaohaneTheme.text
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: compactMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: compact.triggered()
        }
    }
}
