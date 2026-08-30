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
            RaohaneState.setPrimaryOpen("desktopMenu", false)
            return
        }

        const focusedName = Hyprland.focusedMonitor?.name
        const screen = Quickshell.screens.find(item => item.name === focusedName) ?? Quickshell.screens[0]
        if (!screen)
            return

        RaohaneState.desktopMenuScreen = screen
        RaohaneState.desktopMenuX = screen.width / 2
        RaohaneState.desktopMenuY = screen.height / 2
        RaohaneState.setPrimaryOpen("desktopMenu", true)
    }

    function close(): void {
        RaohaneState.setPrimaryOpen("desktopMenu", false)
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

            RaohaneSurface {
                id: menuCard

                width: 336
                implicitHeight: menuContent.implicitHeight + 20
                x: Math.min(Math.max(RaohaneState.desktopMenuX - width / 2, 10), menuWindow.width - width - 10)
                y: Math.min(Math.max(RaohaneState.desktopMenuY - implicitHeight / 2, 10), menuWindow.height - implicitHeight - 10)
                surfaceRadius: 20
                raised: true
                showSheen: false
                border.color: RaohaneTheme.borderStrong
                clip: true
                scale: RaohaneState.desktopMenuOpen ? 1 : 0.97
                opacity: RaohaneState.desktopMenuOpen ? 1 : 0

                Behavior on scale {
                    NumberAnimation { duration: RaohaneTheme.animationDuration; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: RaohaneTheme.animationFast }
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
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 118
                        radius: 15
                        color: RaohaneTheme.surfaceDeep
                        border.width: 1
                        border.color: RaohaneTheme.border
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: RaohaneConfig.wallpaperPath.length > 0 ? "file://" + RaohaneConfig.wallpaperPath : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            opacity: status === Image.Ready ? (RaohaneTheme.dark ? 0.58 : 0.46) : 0
                        }

                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                GradientStop { position: 0.25; color: RaohaneTheme.dark ? "#24101010" : "#20f5f2ec" }
                                GradientStop { position: 1.0; color: RaohaneTheme.dark ? "#d4101010" : "#d8f5f2ec" }
                            }
                        }

                        RowLayout {
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 11
                            }
                            spacing: 8

                            Rectangle {
                                width: 29
                                height: 29
                                radius: 9
                                color: RaohaneTheme.surfaceSubtle
                                border.width: 1
                                border.color: RaohaneTheme.border

                                Text {
                                    anchors.centerIn: parent
                                    text: "ラ"
                                    color: RaohaneTheme.accent
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Desktop")
                                color: RaohaneTheme.text
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }
                        }

                        Column {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                margins: 11
                            }
                            spacing: 1

                            Text {
                                width: parent.width
                                text: RaohaneConfig.wallpaperPath.split("/").pop() || qsTr("Wallpaper")
                                color: RaohaneTheme.text
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: qsTr("Wallpaper and workspace actions")
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
                        onTriggered: {
                            RaohaneState.wallpaperSelectorTarget = "wallpaper"
                            RaohaneState.setPrimaryOpen("wallpaper", true)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

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
                            icon: "folder_open"
                            title: qsTr("Choose file")
                            onTriggered: {
                                RaohaneWallpapers.openFallbackPicker(true, RaohaneConfig.wallpaperDirectory)
                                root.close()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        Layout.topMargin: 2
                        Layout.bottomMargin: 2
                        color: RaohaneTheme.borderFaint
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
                        icon: "space_dashboard"
                        title: qsTr("Desktop & Spaces")
                        detail: qsTr("Wallpaper and workspace configuration")
                        onTriggered: {
                            RaohaneState.settingsPage = "Desktop & Spaces"
                            RaohaneState.setPrimaryOpen("settings", true)
                        }
                    }

                    MenuAction {
                        icon: "tune"
                        title: qsTr("Control Center")
                        detail: qsTr("Network, audio, privacy and notifications")
                        onTriggered: RaohaneState.setPrimaryOpen("controlCenter", true)
                    }

                    MenuAction {
                        icon: "settings"
                        title: qsTr("Settings")
                        detail: qsTr("Configure Raohane")
                        onTriggered: RaohaneState.setPrimaryOpen("settings", true)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        spacing: 6

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
                            onTriggered: RaohaneState.setPrimaryOpen("session", true)
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
        signal triggered()

        Layout.fillWidth: true
        Layout.preferredHeight: 50
        radius: 13
        color: actionMouse.containsMouse ? RaohaneTheme.surfaceHover : "transparent"
        border.width: actionMouse.containsMouse ? 1 : 0
        border.color: RaohaneTheme.border

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 9
            spacing: 9

            Rectangle {
                width: 30
                height: 30
                radius: 9
                color: RaohaneTheme.surfaceSubtle
                border.width: 1
                border.color: RaohaneTheme.border

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: action.icon
                    iconSize: 16
                    color: actionMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: -1

                Text {
                    Layout.fillWidth: true
                    text: action.title
                    color: RaohaneTheme.text
                    font.pixelSize: 9
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
                iconSize: 14
                color: actionMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textFaint
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

        Layout.preferredHeight: 36
        radius: 11
        color: compactMouse.containsMouse ? RaohaneTheme.surfaceHover : "transparent"
        border.width: 1
        border.color: compactMouse.containsMouse ? RaohaneTheme.borderStrong : RaohaneTheme.border

        Row {
            anchors.centerIn: parent
            spacing: 6

            RaohaneIcon {
                text: compact.icon
                iconSize: 14
                color: compactMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: compact.title
                color: RaohaneTheme.text
                font.pixelSize: 8
                font.weight: Font.Medium
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
