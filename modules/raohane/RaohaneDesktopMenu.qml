pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.config
import qs.modules.raohane.services

Scope {
    id: root

    function openCentered(shouldOpen: bool): void {
        if (!shouldOpen) {
            RaohaneState.desktopMenuOpen = false
            return
        }

        const focusedName = Hyprland.focusedMonitor?.name
        const screen = Quickshell.screens.find(item => item.name === focusedName) ?? Quickshell.screens[0]
        if (!screen)
            return

        RaohaneState.desktopMenuScreen = screen
        RaohaneState.desktopMenuX = screen.width / 2
        RaohaneState.desktopMenuY = screen.height / 2
        RaohaneState.desktopMenuOpen = true
    }

    function close(): void {
        RaohaneState.desktopMenuOpen = false
    }

    Loader {
        active: RaohaneState.desktopMenuOpen

        sourceComponent: PanelWindow {
            id: menuWindow

            screen: RaohaneState.desktopMenuScreen ?? Quickshell.screens[0]
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
                x: Math.min(Math.max(RaohaneState.desktopMenuX - width / 2, 10), menuWindow.width - width - 10)
                y: Math.min(Math.max(RaohaneState.desktopMenuY - implicitHeight / 2, 10), menuWindow.height - implicitHeight - 10)
                radius: 24
                color: RaohaneTheme.glassStrong
                border.width: 1
                border.color: RaohaneTheme.border
                clip: true
                scale: RaohaneState.desktopMenuOpen ? 1 : 0.94
                opacity: RaohaneState.desktopMenuOpen ? 1 : 0

                Behavior on scale {
                    NumberAnimation { duration: 160; easing.type: Easing.OutBack }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 130 }
                }

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
                            source: RaohaneConfig.wallpaperPath.length > 0 ? "file://" + RaohaneConfig.wallpaperPath : ""
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
                                text: RaohaneConfig.wallpaperPath.split("/").pop() || qsTr("Wallpaper")
                                color: RaohaneTheme.text
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: qsTr("Workspace controls")
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
                            RaohaneState.wallpaperSelectorTarget = "wallpaper"
                            RaohaneState.wallpaperSelectorOpen = true
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
                                RaohaneWallpapers.randomFromCurrentFolder()
                                root.close()
                            }
                        }

                        CompactAction {
                            Layout.fillWidth: true
                            icon: "video_template"
                            title: qsTr("Choose")
                            onTriggered: {
                                RaohaneWallpapers.openFallbackPicker(true, RaohaneConfig.wallpaperDirectory)
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
                        detail: RaohaneDropShelf.items.length > 0
                            ? qsTr("%1 items ready").arg(RaohaneDropShelf.items.length)
                            : qsTr("Temporary files and drops")
                        onTriggered: {
                            const pointX = RaohaneState.desktopMenuX
                            const pointY = RaohaneState.desktopMenuY
                            root.close()
                            RaohaneDropShelf.show([], pointX, pointY)
                        }
                    }

                    MenuAction {
                        icon: "widgets"
                        title: qsTr("Desktop & widgets")
                        detail: qsTr("Open desktop configuration")
                        onTriggered: {
                            root.close()
                            RaohaneState.settingsPage = "Desktop"
                            RaohaneState.settingsOpen = true
                        }
                    }

                    MenuAction {
                        icon: "tune"
                        title: qsTr("Control Center")
                        detail: qsTr("Network, audio, privacy and notifications")
                        onTriggered: {
                            root.close()
                            RaohaneState.controlCenterOpen = true
                        }
                    }

                    MenuAction {
                        icon: "settings"
                        title: qsTr("Settings")
                        detail: qsTr("Configure Raohane")
                        onTriggered: {
                            root.close()
                            RaohaneState.settingsOpen = true
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
                                RaohaneState.sessionOpen = true
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
        function toggle(): void { root.openCentered(!RaohaneState.desktopMenuOpen) }
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

                RaohaneIcon {
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

            RaohaneIcon {
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

            RaohaneIcon {
                text: compact.icon
                iconSize: 15
                color: RaohaneTheme.textMuted
            }

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
