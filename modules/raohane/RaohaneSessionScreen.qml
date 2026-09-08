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

    readonly property var pendingActionModel: root.actions.find(action => action.id === root.pendingAction) ?? null

    function close(): void {
        confirmTimer.stop()
        root.pendingAction = ""
        RaohaneState.setPrimaryOpen("session", false)
    }

    function cancelPendingAction(): void {
        confirmTimer.stop()
        root.pendingAction = ""
    }

    function requestAction(actionId: string, dangerous: bool): void {
        if (dangerous) {
            root.pendingAction = actionId
            confirmTimer.restart()
            return
        }

        root.cancelPendingAction()
        root.executeAction(actionId)
    }

    function confirmPendingAction(): void {
        if (root.pendingAction.length === 0)
            return

        const actionId = root.pendingAction
        root.pendingAction = ""
        confirmTimer.stop()
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
        interval: 10000
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
                opacity: status === Image.Ready ? (RaohaneTheme.dark ? 0.18 : 0.14) : 0
            }

            Rectangle {
                anchors.fill: parent
                color: RaohaneTheme.dark
                    ? Qt.rgba(0.01, 0.015, 0.035, 0.62)
                    : Qt.rgba(0.18, 0.17, 0.15, 0.24)
                opacity: dialog.entered ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }

            RaohaneSurface {
                id: dialog
                property bool entered: false

                width: Math.min(parent.width - 96, 900)
                height: Math.min(parent.height - 104, root.pendingActionModel ? 630 : 570)
                anchors.centerIn: parent
                surfaceRadius: RaohaneTheme.radiusHero
                raised: true
                showSheen: true
                border.color: RaohaneTheme.borderStrong
                clip: true
                opacity: entered ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
                }
                Behavior on height {
                    NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeEmphasized }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                }

                Keys.onPressed: event => {
                    const columns = 4

                    if (event.key === Qt.Key_Escape) {
                        if (root.pendingAction.length > 0)
                            root.cancelPendingAction()
                        else
                            root.close()
                        event.accepted = true
                        return
                    }

                    if (root.pendingAction.length > 0) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.confirmPendingAction()
                            event.accepted = true
                        }
                        return
                    }

                    if (event.key === Qt.Key_Left) {
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

                Component.onCompleted: {
                    forceActiveFocus()
                    Qt.callLater(() => entered = true)
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        spacing: 10

                        RaohaneSurface {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 38
                            surfaceRadius: 11
                            active: true
                            showSheen: false

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: "power_settings_new"
                                iconSize: 19
                                fill: 1
                                symbolWeight: 550
                                grade: 30
                                color: RaohaneTheme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

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
                            transparentIdle: true
                            showSheen: false
                            hoverScale: 1
                            pressedScale: 1
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
                        columnSpacing: 9
                        rowSpacing: 9

                        Repeater {
                            model: root.actions

                            delegate: RaohaneSurface {
                                id: actionCard
                                required property var modelData
                                required property int index

                                readonly property bool selected: root.currentIndex === index
                                readonly property bool pending: root.pendingAction === modelData.id

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumHeight: 124
                                surfaceRadius: 14
                                active: selected && !pending
                                hovered: actionMouse.containsMouse || activeFocus
                                pressed: actionMouse.pressed
                                interactive: true
                                showSheen: false
                                hoverScale: 1
                                pressedScale: 1
                                activeFocusOnTab: true
                                border.color: pending
                                    ? RaohaneTheme.critical
                                    : selected
                                        ? RaohaneTheme.accentBorder
                                        : hovered
                                            ? RaohaneTheme.borderStrong
                                            : RaohaneTheme.borderFaint

                                Rectangle {
                                    visible: actionCard.selected || actionCard.pending
                                    anchors {
                                        left: parent.left
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 2
                                    }
                                    width: 3
                                    height: 34
                                    radius: 2
                                    color: actionCard.pending ? RaohaneTheme.critical : RaohaneTheme.accent
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 13
                                    spacing: 5

                                    RaohaneSurface {
                                        Layout.preferredWidth: 38
                                        Layout.preferredHeight: 38
                                        surfaceRadius: 11
                                        active: actionCard.selected && !actionCard.pending
                                        showSheen: false
                                        border.color: actionCard.pending ? RaohaneTheme.critical : RaohaneTheme.borderFaint

                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: actionCard.modelData.icon
                                            iconSize: 20
                                            fill: actionCard.pending || actionCard.selected ? 1 : 0
                                            symbolWeight: actionCard.pending ? 600 : actionCard.selected ? 550 : 430
                                            color: actionCard.pending
                                                ? RaohaneTheme.critical
                                                : actionCard.selected
                                                    ? RaohaneTheme.accent
                                                    : RaohaneTheme.textMuted
                                        }
                                    }

                                    Item { Layout.fillHeight: true }

                                    Text {
                                        Layout.fillWidth: true
                                        text: actionCard.modelData.title
                                        color: actionCard.pending ? RaohaneTheme.critical : RaohaneTheme.text
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: actionCard.modelData.detail
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
                                    onPressed: actionCard.forceActiveFocus()
                                    onEntered: root.currentIndex = actionCard.index
                                    onClicked: root.requestAction(actionCard.modelData.id, actionCard.modelData.danger)
                                }
                            }
                        }
                    }

                    RaohaneSurface {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 78
                        visible: root.pendingActionModel !== null
                        surfaceRadius: 13
                        showSheen: false
                        raised: false
                        border.color: RaohaneTheme.critical

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 11

                            RaohaneSurface {
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 38
                                surfaceRadius: 11
                                showSheen: false
                                raised: false
                                border.color: RaohaneTheme.critical

                                RaohaneIcon {
                                    anchors.centerIn: parent
                                    text: root.pendingActionModel?.icon ?? "warning"
                                    iconSize: 19
                                    fill: 1
                                    color: RaohaneTheme.critical
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: root.pendingActionModel
                                        ? qsTr("Confirm %1").arg(root.pendingActionModel.title)
                                        : ""
                                    color: RaohaneTheme.text
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: root.pendingAction === "logout"
                                        ? qsTr("Applications will be asked to close before the Hyprland session ends.")
                                        : qsTr("This system action will be executed immediately after confirmation.")
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 8
                                    elide: Text.ElideRight
                                }
                            }

                            ConfirmButton {
                                label: qsTr("Cancel")
                                icon: "close"
                                danger: false
                                onClicked: root.cancelPendingAction()
                            }

                            ConfirmButton {
                                label: root.pendingActionModel?.title ?? qsTr("Confirm")
                                icon: root.pendingAction === "logout" ? "logout" : "check"
                                danger: true
                                onClicked: root.confirmPendingAction()
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
                                ? qsTr("Enter confirms · Esc cancels")
                                : qsTr("Destructive actions open a confirmation panel")
                            color: root.pendingAction.length > 0 ? RaohaneTheme.critical : RaohaneTheme.textFaint
                            font.pixelSize: 7
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: root.pendingAction.length > 0
                                ? qsTr("Choose Cancel or confirm the action")
                                : qsTr("Arrows navigate · Enter selects · Esc closes")
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

    component ConfirmButton: RaohaneSurface {
        id: button

        property string label: ""
        property string icon: "check"
        property bool danger: false
        signal clicked()

        Layout.preferredWidth: 112
        Layout.preferredHeight: 36
        surfaceRadius: 10
        showSheen: false
        raised: false
        interactive: true
        hovered: buttonMouse.containsMouse || activeFocus
        pressed: buttonMouse.pressed
        border.color: danger ? RaohaneTheme.critical : RaohaneTheme.borderStrong
        hoverScale: 1
        pressedScale: 0.98
        activeFocusOnTab: true

        RowLayout {
            anchors.centerIn: parent
            spacing: 6

            RaohaneIcon {
                text: button.icon
                iconSize: 14
                fill: 1
                color: button.danger ? RaohaneTheme.critical : RaohaneTheme.textMuted
            }

            Text {
                text: button.label
                color: button.danger ? RaohaneTheme.critical : RaohaneTheme.text
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: button.forceActiveFocus()
            onClicked: button.clicked()
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                button.clicked()
                event.accepted = true
            }
        }
    }

    component WarningBar: RaohaneSurface {
        id: warning
        required property string icon
        required property string text

        Layout.fillWidth: true
        Layout.preferredHeight: 34
        surfaceRadius: 10
        showSheen: false
        border.color: RaohaneTheme.warning

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            RaohaneIcon {
                text: warning.icon
                iconSize: 14
                fill: 1
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
