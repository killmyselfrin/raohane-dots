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
                property bool entered: false

                width: 304
                implicitHeight: menuContent.implicitHeight + 18
                x: Math.min(Math.max(RaohaneState.desktopMenuX - width / 2, 10), menuWindow.width - width - 10)
                y: Math.min(Math.max(RaohaneState.desktopMenuY - implicitHeight / 2, 10), menuWindow.height - implicitHeight - 10)
                surfaceRadius: 14
                raised: true
                showSheen: false
                border.color: RaohaneTheme.borderStrong
                clip: true
                opacity: entered ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
                }

                Component.onCompleted: {
                    forceActiveFocus()
                    Qt.callLater(() => entered = true)
                }

                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        leftMargin: 13
                        rightMargin: 13
                    }
                    height: 1
                    color: RaohaneTheme.accent
                    opacity: 0.36
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
                        margins: 9
                    }
                    spacing: 4

                    RaohaneSurface {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 72
                        surfaceRadius: 10
                        raised: false
                        showSheen: false
                        clip: true
                        color: RaohaneTheme.surfaceDeep
                        border.color: RaohaneTheme.borderFaint

                        Image {
                            anchors.fill: parent
                            source: RaohaneConfig.wallpaperPath.length > 0 ? "file://" + RaohaneConfig.wallpaperPath : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            opacity: status === Image.Ready ? (RaohaneTheme.dark ? 0.46 : 0.34) : 0
                        }

                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                GradientStop { position: 0.16; color: "#22000000" }
                                GradientStop { position: 1.0; color: RaohaneTheme.dark ? "#dc0a0d14" : "#d8f5f2ec" }
                            }
                        }

                        RowLayout {
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                bottom: parent.bottom
                                margins: 9
                            }
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 2
                                Layout.preferredHeight: 30
                                radius: 1
                                color: RaohaneTheme.accent
                            }

                            RaohaneIcon {
                                text: "desktop_windows"
                                iconSize: 17
                                fill: 1
                                symbolWeight: 540
                                color: RaohaneTheme.accent
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("Desktop")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneConfig.wallpaperPath.split("/").pop() || qsTr("Wallpaper")
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 7
                                    elide: Text.ElideMiddle
                                }
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
                        spacing: 4

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
                        onTriggered: RaohaneSettingsRouter.request("Desktop & Spaces", "")
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
                        onTriggered: RaohaneSettingsRouter.request("home", "")
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        Layout.topMargin: 2
                        Layout.bottomMargin: 2
                        color: RaohaneTheme.borderFaint
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

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
                            accent: true
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

    component MenuAction: RaohaneSurface {
        id: action

        required property string icon
        required property string title
        property string detail: ""
        signal triggered()

        Layout.fillWidth: true
        Layout.preferredHeight: 43
        surfaceRadius: 8
        transparentIdle: !hovered
        showSheen: false
        raised: false
        interactive: true
        hovered: actionMouse.containsMouse || activeFocus
        pressed: actionMouse.pressed
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: true
        border.color: hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint
        color: hovered ? RaohaneTheme.surfaceSubtle : RaohaneTheme.surfaceDeep

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: 2
                topMargin: 8
                bottomMargin: 8
            }
            width: 2
            radius: 1
            color: RaohaneTheme.accent
            opacity: action.hovered || action.activeFocus ? 0.58 : 0

            Behavior on opacity { NumberAnimation { duration: RaohaneMotion.micro } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 8
            spacing: 7

            RaohaneIcon {
                text: action.icon
                iconSize: 14
                fill: action.hovered || action.activeFocus ? 0.45 : 0
                symbolWeight: action.hovered || action.activeFocus ? 510 : 420
                color: action.hovered || action.activeFocus ? RaohaneTheme.accent : RaohaneTheme.textMuted

                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: -1

                Text {
                    Layout.fillWidth: true
                    text: action.title
                    color: RaohaneTheme.text
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: action.detail
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 6
                    elide: Text.ElideRight
                }
            }

            RaohaneIcon {
                text: "chevron_right"
                iconSize: 11
                color: action.hovered || action.activeFocus ? RaohaneTheme.accent : RaohaneTheme.textFaint

                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: action.forceActiveFocus()
            onClicked: action.triggered()
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                action.triggered()
                event.accepted = true
            }
        }
    }

    component CompactAction: RaohaneSurface {
        id: compact

        required property string icon
        required property string title
        property bool accent: false
        signal triggered()

        Layout.preferredHeight: 32
        surfaceRadius: 8
        active: accent
        transparentIdle: !accent && !hovered
        showSheen: false
        raised: false
        interactive: true
        hovered: compactMouse.containsMouse || activeFocus
        pressed: compactMouse.pressed
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: true
        border.color: accent ? RaohaneTheme.accentBorder
            : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

        Row {
            anchors.centerIn: parent
            spacing: 5

            RaohaneIcon {
                text: compact.icon
                iconSize: 12
                fill: compact.accent ? 1 : compact.hovered || compact.activeFocus ? 0.4 : 0
                symbolWeight: compact.accent ? 550 : compact.hovered || compact.activeFocus ? 500 : 420
                color: compact.accent || compact.hovered || compact.activeFocus
                    ? RaohaneTheme.accent : RaohaneTheme.textMuted

                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
            }

            Text {
                text: compact.title
                color: compact.accent ? RaohaneTheme.accent : RaohaneTheme.text
                font.pixelSize: 7
                font.weight: Font.Medium
            }
        }

        MouseArea {
            id: compactMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: compact.forceActiveFocus()
            onClicked: compact.triggered()
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                compact.triggered()
                event.accepted = true
            }
        }
    }
}
