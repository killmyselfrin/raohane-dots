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

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    property int currentIndex: 0
    property string pendingAction: ""

    readonly property var actions: [
        { id: "lock", icon: "lock", title: qsTr("Lock"), detail: qsTr("Secure this session"), danger: false },
        { id: "sleep", icon: "dark_mode", title: qsTr("Sleep"), detail: qsTr("Suspend to memory"), danger: false },
        { id: "logout", icon: "logout", title: qsTr("Logout"), detail: qsTr("End the Hyprland session"), danger: true },
        { id: "tasks", icon: "browse_activity", title: qsTr("Task Manager"), detail: qsTr("Inspect running processes"), danger: false },
        { id: "hibernate", icon: "downloading", title: qsTr("Hibernate"), detail: qsTr("Suspend to disk"), danger: false },
        { id: "shutdown", icon: "power_settings_new", title: qsTr("Shutdown"), detail: qsTr("Power off the system"), danger: true },
        { id: "reboot", icon: "restart_alt", title: qsTr("Reboot"), detail: qsTr("Restart the system"), danger: true },
        { id: "firmware", icon: "settings_applications", title: qsTr("Firmware"), detail: qsTr("Restart into firmware settings"), danger: true }
    ]

    function close(): void {
        root.pendingAction = ""
        RaohaneState.setPrimaryOpen("session", false)
    }

    function requestAction(actionId: string, dangerous: bool): void {
        if (dangerous && root.pendingAction !== actionId) {
            root.pendingAction = actionId
            confirmTimer.restart()
            return
        }
        root.pendingAction = ""
        root.executeAction(actionId)
    }

    function executeAction(actionId: string): void {
        root.close()
        switch (actionId) {
        case "lock": RaohaneSession.lock(); break
        case "sleep": RaohaneSession.suspend(); break
        case "logout": RaohaneSession.logout(); break
        case "tasks": RaohaneSession.launchTaskManager(); break
        case "hibernate": RaohaneSession.hibernate(); break
        case "shutdown": RaohaneSession.poweroff(); break
        case "reboot": RaohaneSession.reboot(); break
        case "firmware": RaohaneSession.rebootToFirmware(); break
        }
    }

    Timer {
        id: confirmTimer
        interval: 4200
        repeat: false
        onTriggered: root.pendingAction = ""
    }

    Connections {
        target: RaohaneState

        function onSessionOpenChanged(): void {
            if (RaohaneState.sessionOpen) {
                root.currentIndex = 0
                root.pendingAction = ""
                RaohaneSessionWarnings.refresh()
            }
        }

        function onScreenLockedChanged(): void {
            if (RaohaneState.screenLocked)
                root.close()
        }
    }

    Loader {
        active: RaohaneState.sessionOpen

        sourceComponent: PanelWindow {
            id: panelWindow

            screen: root.focusedScreen
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:raohane-session"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Image {
                anchors.fill: parent
                source: RaohaneConfig.wallpaperPath
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                opacity: status === Image.Ready ? (RaohaneTheme.dark ? 0.24 : 0.18) : 0
            }

            Rectangle {
                anchors.fill: parent
                color: RaohaneTheme.dark ? "#8a000000" : "#465b5750"

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }

            RaohaneSurface {
                id: dialog
                width: Math.min(parent.width - 96, 850)
                height: Math.min(parent.height - 112, 540)
                anchors.centerIn: parent
                surfaceRadius: RaohaneTheme.radiusHero
                raised: true
                showSheen: false
                border.color: RaohaneTheme.borderStrong
                clip: true

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                }

                Keys.onPressed: event => {
                    const columns = 4
                    if (event.key === Qt.Key_Escape) {
                        root.close()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Left) {
                        root.currentIndex = Math.max(0, root.currentIndex - 1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Right) {
                        root.currentIndex = Math.min(root.actions.length - 1, root.currentIndex + 1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Up) {
                        root.currentIndex = Math.max(0, root.currentIndex - columns)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Down) {
                        root.currentIndex = Math.min(root.actions.length - 1, root.currentIndex + columns)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        const action = root.actions[root.currentIndex]
                        root.requestAction(action.id, action.danger)
                        event.accepted = true
                    }
                }

                Component.onCompleted: forceActiveFocus()

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 11

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        spacing: 10

                        Rectangle {
                            width: 36
                            height: 36
                            radius: 12
                            color: RaohaneTheme.surfaceSubtle
                            border.width: 1
                            border.color: RaohaneTheme.border

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: "power_settings_new"
                                iconSize: 18
                                color: RaohaneTheme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: qsTr("Session")
                                color: RaohaneTheme.text
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: qsTr("Choose what happens next")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                            }
                        }

                        Text {
                            text: RaohaneSystemInfo.username + " @ " + RaohaneSystemInfo.hostname
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                        }

                        RaohaneIconButton {
                            buttonSize: 30
                            iconSize: 15
                            icon: "close"
                            onClicked: root.close()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: RaohaneTheme.borderFaint
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 4
                        columnSpacing: 8
                        rowSpacing: 8

                        Repeater {
                            model: root.actions

                            delegate: RaohaneSurface {
                                id: actionCard
                                required property var modelData
                                required property int index

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumHeight: 118
                                readonly property bool selected: root.currentIndex === index
                                readonly property bool confirming: root.pendingAction === modelData.id
                                surfaceRadius: 16
                                raised: selected || confirming
                                hovered: actionMouse.containsMouse
                                showSheen: false
                                border.color: confirming ? RaohaneTheme.critical
                                    : selected ? RaohaneTheme.borderStrong : RaohaneTheme.border

                                Rectangle {
                                    visible: actionCard.selected && !actionCard.confirming
                                    anchors {
                                        left: parent.left
                                        top: parent.top
                                        bottom: parent.bottom
                                        leftMargin: 3
                                        topMargin: 11
                                        bottomMargin: 11
                                    }
                                    width: 2
                                    radius: 1
                                    color: RaohaneTheme.accent
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 5

                                    Rectangle {
                                        width: 38
                                        height: 38
                                        radius: 12
                                        color: RaohaneTheme.surfaceSubtle
                                        border.width: 1
                                        border.color: actionCard.confirming ? RaohaneTheme.critical : RaohaneTheme.border

                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: actionCard.confirming ? "priority_high" : actionCard.modelData.icon
                                            iconSize: 20
                                            color: actionCard.confirming ? RaohaneTheme.critical
                                                : actionCard.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                        }
                                    }

                                    Item { Layout.fillHeight: true }

                                    Text {
                                        Layout.fillWidth: true
                                        text: actionCard.confirming ? qsTr("Confirm %1").arg(actionCard.modelData.title) : actionCard.modelData.title
                                        color: actionCard.confirming ? RaohaneTheme.critical : RaohaneTheme.text
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: actionCard.confirming ? qsTr("Press again within 4 seconds") : actionCard.modelData.detail
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: 8
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: actionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.currentIndex = actionCard.index
                                    onClicked: root.requestAction(actionCard.modelData.id, actionCard.modelData.danger)
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        WarningBar {
                            visible: RaohaneSessionWarnings.packageManagerRunning
                            icon: "package_2"
                            text: qsTr("A package manager appears to be running. Avoid shutdown or reboot until it finishes.")
                        }
                        WarningBar {
                            visible: RaohaneSessionWarnings.downloadRunning
                            icon: "download"
                            text: qsTr("A download may still be in progress. Check Downloads before ending the session.")
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: root.pendingAction.length > 0
                                ? qsTr("Confirmation armed for a destructive action")
                                : qsTr("Destructive actions require a second press")
                            color: root.pendingAction.length > 0 ? RaohaneTheme.critical : RaohaneTheme.textFaint
                            font.pixelSize: 7
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: qsTr("Arrows navigate · Enter selects · Esc closes")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "session"
        function toggle(): void { RaohaneState.togglePrimary("session") }
        function open(): void { RaohaneState.setPrimaryOpen("session", true) }
        function close(): void { root.close() }
    }

    CompositorGlobalShortcut {
        name: "sessionToggle"
        description: "Toggle Raohane session screen"
        onPressed: RaohaneState.togglePrimary("session")
    }
    CompositorGlobalShortcut {
        name: "sessionOpen"
        description: "Open Raohane session screen"
        onPressed: RaohaneState.setPrimaryOpen("session", true)
    }
    CompositorGlobalShortcut {
        name: "sessionClose"
        description: "Close Raohane session screen"
        onPressed: root.close()
    }

    component WarningBar: Rectangle {
        id: warning
        required property string icon
        required property string text

        Layout.fillWidth: true
        Layout.preferredHeight: 32
        radius: 10
        color: RaohaneTheme.surfaceSubtle
        border.width: 1
        border.color: RaohaneTheme.warning

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 9
            spacing: 7

            RaohaneIcon {
                text: warning.icon
                iconSize: 14
                color: RaohaneTheme.warning
            }

            Text {
                Layout.fillWidth: true
                text: warning.text
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
                elide: Text.ElideRight
            }
        }
    }
}
