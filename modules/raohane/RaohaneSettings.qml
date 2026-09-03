import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]

    PanelWindow {
        id: panelWindow

        visible: RaohaneState.settingsOpen
        screen: root.focusedScreen
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "quickshell:raohane-settings"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: RaohaneState.settingsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        function hide(): void {
            settingsSearch.clear()
            workspace.preferencesOpen = false
            workspace.backupOpen = false
            RaohaneState.setPrimaryOpen("settings", false)
        }

        function openPreferences(section: string): void {
            settingsSearch.clear()
            workspace.backupOpen = false
            preferences.section = section
            workspace.preferencesOpen = true
            preferences.forceActiveFocus()
        }

        function openBackup(): void {
            settingsSearch.clear()
            workspace.preferencesOpen = false
            workspace.backupOpen = true
            backupPage.forceActiveFocus()
        }

        function showMainSettings(): void {
            workspace.preferencesOpen = false
            workspace.backupOpen = false
            workspace.forceActiveFocus()
        }

        onVisibleChanged: {
            if (visible) {
                workspace.entered = false
                Qt.callLater(() => workspace.entered = true)
                RaohaneFocusGrab.addDismissable(panelWindow)
            } else {
                workspace.entered = false
                workspace.preferencesOpen = false
                workspace.backupOpen = false
                RaohaneFocusGrab.removeDismissable(panelWindow)
            }
        }

        Connections {
            target: RaohaneFocusGrab
            function onDismissed() { panelWindow.hide() }
        }

        Connections {
            target: RaohaneSettingsRouter

            function onPageRequested(pageKey: string, controlKey: string): void {
                panelWindow.showMainSettings()
            }

            function onPreferencesRequested(section: string): void {
                panelWindow.openPreferences(section)
            }

            function onBackupRequested(): void {
                panelWindow.openBackup()
            }

            function onLanguageRequested(): void {
                panelWindow.showMainSettings()
                RaohaneI18n.openPicker()
            }
        }

        Rectangle {
            anchors.fill: parent
            color: RaohaneTheme.dark
                ? Qt.rgba(0, 0, 0, 0.46)
                : Qt.rgba(0.18, 0.17, 0.15, 0.18)
            opacity: RaohaneState.settingsOpen ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: panelWindow.hide()
            }
        }

        RaohaneSurface {
            id: workspace
            property bool entered: false
            property bool preferencesOpen: false
            property bool backupOpen: false

            width: Math.min(parent.width - 96, 1040)
            height: Math.min(parent.height - 96, 700)
            anchors.centerIn: parent
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            clip: true
            opacity: entered ? 1 : 0
            scale: entered ? 1 : 0.994
            focus: RaohaneState.settingsOpen

            transform: Translate {
                y: workspace.entered ? 0 : 10
                Behavior on y {
                    NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeEmphasized }
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }

            Behavior on scale {
                NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeEmphasized }
            }

            Rectangle {
                z: 40
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: 18
                }
                width: 54
                height: 2
                radius: 1
                color: RaohaneTheme.accent
                opacity: 0.72
            }

            RaohaneSettingsContentV3 {
                anchors.fill: parent
                visible: !workspace.preferencesOpen && !workspace.backupOpen
            }

            RaohanePreferencesHub {
                id: preferences
                anchors.fill: parent
                visible: workspace.preferencesOpen
                z: 45
                onCloseRequested: {
                    workspace.preferencesOpen = false
                    workspace.forceActiveFocus()
                }
            }

            Item {
                id: backupPage
                anchors.fill: parent
                visible: workspace.backupOpen
                z: 45
                focus: visible

                Item {
                    id: backupHeader
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                    height: 66

                    RaohaneIconButton {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: 16
                        }
                        buttonSize: 32
                        iconSize: 16
                        icon: "arrow_back"
                        transparentIdle: true
                        showSheen: false
                        onClicked: {
                            workspace.backupOpen = false
                            workspace.forceActiveFocus()
                        }
                    }

                    Column {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: 60
                        }
                        spacing: 1

                        Text {
                            text: qsTr("Backup & Restore")
                            color: RaohaneTheme.text
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: qsTr("Portable Raohane settings, wallpapers and monitor profiles")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                        }
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            leftMargin: 18
                            rightMargin: 18
                        }
                        height: 1
                        color: RaohaneTheme.borderFaint
                    }
                }

                RaohaneBackupSettings {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: backupHeader.bottom
                        bottom: parent.bottom
                        leftMargin: 16
                        rightMargin: 16
                        bottomMargin: 8
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        workspace.backupOpen = false
                        workspace.forceActiveFocus()
                        event.accepted = true
                    }
                }
            }

            RaohaneSettingsSearch {
                id: settingsSearch
                visible: !workspace.preferencesOpen && !workspace.backupOpen
                z: 50
                width: Math.min(300, Math.max(220, workspace.width * 0.27))
                height: 34
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 19
                    rightMargin: 204
                }
            }

            RaohaneIconButton {
                visible: !workspace.preferencesOpen && !workspace.backupOpen
                z: 50
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 20
                    rightMargin: 164
                }
                buttonSize: 30
                iconSize: 15
                icon: "inventory_2"
                transparentIdle: true
                showSheen: false
                onClicked: RaohaneSettingsRouter.request("backup", "")
            }

            RaohaneIconButton {
                visible: !workspace.preferencesOpen && !workspace.backupOpen
                z: 50
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 20
                    rightMargin: 127
                }
                buttonSize: 30
                iconSize: 15
                icon: "keyboard"
                transparentIdle: true
                showSheen: false
                onClicked: RaohaneSettingsRouter.request("keybinds", "")
            }

            RaohaneIconButton {
                visible: !workspace.preferencesOpen && !workspace.backupOpen
                z: 50
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 20
                    rightMargin: 90
                }
                buttonSize: 30
                iconSize: 15
                icon: "animation"
                transparentIdle: true
                showSheen: false
                onClicked: RaohaneSettingsRouter.request("motion", "")
            }

            RaohaneIconButton {
                visible: !workspace.preferencesOpen && !workspace.backupOpen
                z: 50
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 20
                    rightMargin: 53
                }
                buttonSize: 30
                iconSize: 15
                icon: "language"
                transparentIdle: true
                showSheen: false
                onClicked: RaohaneSettingsRouter.request("language", "")
            }

            RaohaneIconButton {
                z: 50
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 20
                    rightMargin: 16
                }
                buttonSize: 30
                iconSize: 15
                icon: "close"
                transparentIdle: true
                showSheen: false
                onClicked: panelWindow.hide()
            }

            Keys.onPressed: event => {
                if (workspace.backupOpen && event.key === Qt.Key_Escape) {
                    workspace.backupOpen = false
                    workspace.forceActiveFocus()
                    event.accepted = true
                } else if (workspace.preferencesOpen && event.key === Qt.Key_Escape) {
                    workspace.preferencesOpen = false
                    workspace.forceActiveFocus()
                    event.accepted = true
                } else if (!workspace.preferencesOpen && !workspace.backupOpen && (event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
                    settingsSearch.focusSearch()
                    event.accepted = true
                } else if (!workspace.preferencesOpen && !workspace.backupOpen && event.key === Qt.Key_Escape) {
                    if (settingsSearch.query.length > 0) {
                        settingsSearch.clear()
                        workspace.forceActiveFocus()
                    } else {
                        panelWindow.hide()
                    }
                    event.accepted = true
                }
            }
        }

        IpcHandler {
            target: "settings"
            function toggle(): void { RaohaneState.togglePrimary("settings") }
            function open(): void { RaohaneState.setPrimaryOpen("settings", true) }
            function close(): void { panelWindow.hide() }
            function status(): string { return RaohaneState.settingsOpen ? "open" : "closed" }
            function page(page: string): void { RaohaneSettingsRouter.request(page, "") }
        }

        CompositorGlobalShortcut {
            name: "settingsToggle"
            description: "Toggles Raohane settings"
            onPressed: RaohaneState.togglePrimary("settings")
        }
    }
}
