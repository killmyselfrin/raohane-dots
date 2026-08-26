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
        pendingAction = ""
        GlobalStates.sessionOpen = false
    }

    function requestAction(actionId: string, dangerous: bool): void {
        if (dangerous && pendingAction !== actionId) {
            pendingAction = actionId
            confirmTimer.restart()
            return
        }
        pendingAction = ""
        executeAction(actionId)
    }

    function executeAction(actionId: string): void {
        root.close()
        switch (actionId) {
        case "lock": Session.lock(); break
        case "sleep": Session.suspend(); break
        case "logout": Session.logout(); break
        case "tasks": Session.launchTaskManager(); break
        case "hibernate": Session.hibernate(); break
        case "shutdown": Session.poweroff(); break
        case "reboot": Session.reboot(); break
        case "firmware": Session.rebootToFirmware(); break
        }
    }

    Timer {
        id: confirmTimer
        interval: 4200
        repeat: false
        onTriggered: root.pendingAction = ""
    }

    Connections {
        target: GlobalStates
        function onSessionOpenChanged(): void {
            if (GlobalStates.sessionOpen) {
                root.currentIndex = 0
                root.pendingAction = ""
                SessionWarnings.refresh()
            }
        }
        function onScreenLockedChanged(): void {
            if (GlobalStates.screenLocked)
                root.close()
        }
    }

    Loader {
        active: GlobalStates.sessionOpen

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
                source: Config.options.background.wallpaperPath
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                opacity: status === Image.Ready ? 0.33 : 0
            }

            Rectangle {
                anchors.fill: parent
                color: "#d2080710"

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }

            Rectangle {
                id: dialog
                width: Math.min(parent.width - 80, 880)
                height: Math.min(parent.height - 100, 570)
                anchors.centerIn: parent
                radius: 30
                color: RaohaneTheme.glassStrong
                border.width: 1
                border.color: RaohaneTheme.border
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
                    anchors.margins: 22
                    spacing: 15

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            width: 44
                            height: 44
                            radius: 15
                            color: RaohaneTheme.accentSoft
                            border.width: 1
                            border.color: RaohaneTheme.border

                            Text {
                                anchors.centerIn: parent
                                text: "ラ"
                                color: RaohaneTheme.accent
                                font.pixelSize: 19
                                font.weight: Font.Bold
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: -1

                            Text {
                                text: qsTr("Session")
                                color: RaohaneTheme.text
                                font.pixelSize: 20
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: qsTr("Choose what Raohane should do next · arrows / Enter / Esc")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                            }
                        }

                        Rectangle {
                            width: userText.implicitWidth + 18
                            height: 29
                            radius: 15
                            color: "#1cffffff"
                            border.width: 1
                            border.color: RaohaneTheme.border

                            Text {
                                id: userText
                                anchors.centerIn: parent
                                text: SystemInfo.username + " @ " + SystemInfo.hostname
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 4
                        columnSpacing: 10
                        rowSpacing: 10

                        Repeater {
                            model: root.actions

                            delegate: Rectangle {
                                id: actionCard
                                required property var modelData
                                required property int index

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumHeight: 126
                                readonly property bool selected: root.currentIndex === index
                                readonly property bool confirming: root.pendingAction === modelData.id
                                radius: 20
                                color: confirming ? "#32ff668c"
                                    : selected || actionMouse.containsMouse ? RaohaneTheme.accentSoft : "#63171320"
                                border.width: 1
                                border.color: confirming ? RaohaneTheme.critical
                                    : selected || actionMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.border

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 5

                                    Rectangle {
                                        width: 42
                                        height: 42
                                        radius: 14
                                        color: actionCard.confirming ? "#35ff668c" : "#20ffffff"

                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: actionCard.confirming ? "priority_high" : actionCard.modelData.icon
                                            iconSize: 22
                                            color: actionCard.confirming ? RaohaneTheme.critical
                                                : actionCard.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                        }
                                    }

                                    Item { Layout.fillHeight: true }

                                    Text {
                                        Layout.fillWidth: true
                                        text: actionCard.confirming ? qsTr("Confirm %1").arg(actionCard.modelData.title) : actionCard.modelData.title
                                        color: actionCard.confirming ? RaohaneTheme.critical : RaohaneTheme.text
                                        font.pixelSize: 11
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
                        spacing: 6

                        WarningBar {
                            visible: SessionWarnings.packageManagerRunning
                            icon: "package_2"
                            text: qsTr("A package manager appears to be running. Avoid shutdown/reboot until it finishes.")
                        }
                        WarningBar {
                            visible: SessionWarnings.downloadRunning
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
                            color: root.pendingAction.length > 0 ? RaohaneTheme.critical : RaohaneTheme.textMuted
                            font.pixelSize: 8
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "RAOHANE / SESSION"
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            font.letterSpacing: 0.9
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "session"
        function toggle(): void { GlobalStates.sessionOpen = !GlobalStates.sessionOpen }
        function open(): void { GlobalStates.sessionOpen = true }
        function close(): void { root.close() }
    }

    CompositorGlobalShortcut {
        name: "sessionToggle"
        description: "Toggle Raohane session screen"
        onPressed: GlobalStates.sessionOpen = !GlobalStates.sessionOpen
    }
    CompositorGlobalShortcut {
        name: "sessionOpen"
        description: "Open Raohane session screen"
        onPressed: GlobalStates.sessionOpen = true
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
        Layout.preferredHeight: 34
        radius: 12
        color: "#2cff668c"
        border.width: 1
        border.color: "#66ff668c"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 7
            MaterialSymbol { text: warning.icon; iconSize: 15; color: RaohaneTheme.critical }
            Text {
                Layout.fillWidth: true
                text: warning.text
                color: RaohaneTheme.text
                font.pixelSize: 8
                elide: Text.ElideRight
            }
        }
    }
}
