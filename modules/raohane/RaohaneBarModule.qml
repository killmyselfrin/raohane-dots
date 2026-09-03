pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config
import qs.modules.raohane.services

// Shared renderer for horizontal and vertical registered bar modules. Geometry
// stays in the host bars; this component owns orientation-specific presentation
// and native service interaction for each stable module id.
Item {
    id: root

    required property string moduleId
    property string orientation: "horizontal"
    property var screen: null
    property var parentWindow: null
    property bool hostActive: true
    property bool showDate: RaohaneConfig.barShowDate
    property var primaryAction: null
    property var transientAction: null

    readonly property bool vertical: orientation === "vertical"
    readonly property bool known: RaohaneBarModuleRegistry.supports(moduleId, orientation)
    readonly property real loadedWidth: Number(contentLoader.item?.implicitWidth ?? contentLoader.item?.width ?? 0)
    readonly property real loadedHeight: Number(contentLoader.item?.implicitHeight ?? contentLoader.item?.height ?? 0)

    function fallbackWidth(id: string): real {
        if (root.vertical)
            return id === "separator" ? 36 : 36
        switch (id) {
        case "launcher": return 30
        case "workspaces": return Math.max(31, Math.min(300, RaohaneConfig.overviewWorkspaceCount * 28 + 3))
        case "context": return 170
        case "tray": return 0
        case "system": return 54
        case "clock": return root.showDate ? 70 : 42
        case "control": return 30
        case "separator": return 1
        default: return 0
        }
    }

    function fallbackHeight(id: string): real {
        if (root.vertical)
            return id === "separator" ? 1 : 36
        switch (id) {
        case "context": return 38
        case "separator": return 17
        case "workspaces": return 28
        default: return 30
        }
    }

    implicitWidth: Math.max(root.loadedWidth, root.fallbackWidth(root.moduleId))
    implicitHeight: Math.max(root.loadedHeight, root.fallbackHeight(root.moduleId))
    width: implicitWidth
    height: implicitHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    visible: known && contentLoader.status === Loader.Ready && (contentLoader.item?.visible ?? true)

    function requestPrimary(surfaceId: string): void {
        if (typeof root.primaryAction === "function") {
            root.primaryAction(surfaceId)
            return
        }
        RaohaneState.togglePrimary(surfaceId)
    }

    function requestControlCenter(): void {
        root.requestPrimary("controlCenter")
    }

    function requestTransient(surfaceId: string): void {
        if (typeof root.transientAction === "function") {
            root.transientAction(surfaceId)
            return
        }
        RaohaneState.toggleSurface(surfaceId)
    }

    function componentFor(id: string): Component {
        if (root.vertical) {
            switch (id) {
            case "launcher": return verticalLauncherComponent
            case "workspaces": return verticalWorkspacesComponent
            case "context": return verticalContextComponent
            case "network": return verticalNetworkComponent
            case "bluetooth": return verticalBluetoothComponent
            case "notifications": return verticalNotificationsComponent
            case "clock": return verticalClockComponent
            case "audio": return verticalAudioComponent
            case "control": return verticalControlComponent
            case "session": return verticalSessionComponent
            case "separator": return verticalSeparatorComponent
            default: return null
            }
        }

        switch (id) {
        case "launcher": return launcherComponent
        case "workspaces": return workspacesComponent
        case "context": return contextComponent
        case "tray": return trayComponent
        case "system": return systemComponent
        case "clock": return clockComponent
        case "control": return controlComponent
        case "separator": return separatorComponent
        default: return null
        }
    }

    Loader {
        id: contentLoader
        anchors.centerIn: parent
        active: root.known
        sourceComponent: root.componentFor(root.moduleId)
    }

    Component {
        id: launcherComponent

        RaohaneIconButton {
            implicitWidth: 30
            implicitHeight: 30
            buttonSize: 30
            iconSize: 17
            icon: "apps"
            onClicked: root.requestPrimary("launcher")
        }
    }

    Component {
        id: workspacesComponent

        RaohaneWorkspaces {
            screen: root.screen
            orientation: "horizontal"
        }
    }

    Component {
        id: contextComponent

        RaohaneContextIsland {
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor

                onClicked: mouse => {
                    if (RaohaneContext.mode !== "media") {
                        if (mouse.button === Qt.LeftButton)
                            root.requestControlCenter()
                        return
                    }

                    if (mouse.button === Qt.MiddleButton) {
                        RaohaneMedia.togglePlaying()
                    } else if (mouse.button === Qt.RightButton) {
                        RaohaneMedia.cyclePlayer(1)
                    } else {
                        root.requestTransient("mediaOverlay")
                    }
                }

                onWheel: wheel => {
                    if (RaohaneContext.mode !== "media" || !RaohaneMedia.volumeSupported)
                        return
                    const step = wheel.angleDelta.y >= 0 ? 0.04 : -0.04
                    RaohaneMedia.setVolume(RaohaneMedia.volume + step)
                    wheel.accepted = true
                }
            }
        }
    }

    Component {
        id: trayComponent

        RaohaneSysTray {
            parentWindow: root.parentWindow
        }
    }

    Component {
        id: systemComponent

        RaohaneSystemIcons {
            onActivated: root.requestControlCenter()
        }
    }

    Component {
        id: clockComponent

        RaohaneClock {
            showDate: root.showDate
            active: root.hostActive
        }
    }

    Component {
        id: controlComponent

        RaohaneIconButton {
            implicitWidth: 30
            implicitHeight: 30
            buttonSize: 30
            iconSize: 16
            icon: "tune"
            onClicked: root.requestControlCenter()
        }
    }

    Component {
        id: separatorComponent

        Item {
            implicitWidth: 1
            implicitHeight: 17

            Rectangle {
                anchors.fill: parent
                color: RaohaneTheme.borderFaint
            }
        }
    }

    Component {
        id: verticalLauncherComponent

        VerticalButton {
            icon: "apps"
            emphasized: RaohaneState.launcherOpen
            onTriggered: root.requestPrimary("launcher")
        }
    }

    Component {
        id: verticalWorkspacesComponent

        RaohaneWorkspaces {
            screen: root.screen
            orientation: "vertical"
        }
    }

    Component {
        id: verticalContextComponent

        VerticalButton {
            icon: RaohanePrivacy.recordingActive ? "screen_record"
                : RaohanePrivacy.cameraActive ? "videocam"
                : RaohanePrivacy.microphoneActive ? "mic"
                : (RaohaneContext.mode === "media" ? "music_note" : "circle")
            emphasized: RaohanePrivacy.recordingActive
                || RaohanePrivacy.cameraActive
                || RaohanePrivacy.microphoneActive
                || RaohaneContext.mode === "media"
            onTriggered: {
                if (RaohaneContext.mode === "media")
                    root.requestTransient("mediaOverlay")
                else
                    root.requestControlCenter()
            }
        }
    }

    Component {
        id: verticalNetworkComponent

        VerticalButton {
            icon: RaohaneNetwork.materialSymbol
            emphasized: RaohaneNetwork.wifiConnected || RaohaneNetwork.ethernet
            onTriggered: root.requestControlCenter()
        }
    }

    Component {
        id: verticalBluetoothComponent

        Item {
            visible: RaohaneBluetooth.available
            implicitWidth: visible ? 36 : 0
            implicitHeight: visible ? 36 : 0

            VerticalButton {
                anchors.centerIn: parent
                icon: RaohaneBluetooth.connected
                    ? "bluetooth_connected"
                    : (RaohaneBluetooth.enabled ? "bluetooth" : "bluetooth_disabled")
                emphasized: RaohaneBluetooth.connected
                onTriggered: RaohaneBluetooth.toggle()
            }
        }
    }

    Component {
        id: verticalNotificationsComponent

        VerticalButton {
            icon: RaohaneNotifications.silent ? "notifications_off" : "notifications"
            emphasized: RaohaneNotifications.unread > 0
            badgeCount: RaohaneNotifications.unread
            onTriggered: root.requestControlCenter()
        }
    }

    Component {
        id: verticalClockComponent

        Item {
            id: verticalClock
            property date now: new Date()

            implicitWidth: 38
            implicitHeight: root.showDate ? 48 : 36

            Timer {
                interval: 1000
                repeat: true
                running: root.hostActive
                triggeredOnStart: true
                onTriggered: verticalClock.now = new Date()
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: -2

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatTime(verticalClock.now, "HH")
                    color: RaohaneTheme.text
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatTime(verticalClock.now, "mm")
                    color: RaohaneTheme.text
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                Text {
                    visible: root.showDate
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDate(verticalClock.now, "dd")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 7
                }
            }
        }
    }

    Component {
        id: verticalAudioComponent

        VerticalButton {
            icon: RaohaneAudio.muted ? "volume_off"
                : (RaohaneAudio.volume > 0.66 ? "volume_up"
                    : RaohaneAudio.volume > 0.05 ? "volume_down" : "volume_mute")
            emphasized: !RaohaneAudio.muted && RaohaneAudio.volume > 0
            onTriggered: RaohaneAudio.toggleMute()
        }
    }

    Component {
        id: verticalControlComponent

        VerticalButton {
            icon: "tune"
            emphasized: RaohaneState.controlCenterOpen
            onTriggered: root.requestControlCenter()
        }
    }

    Component {
        id: verticalSessionComponent

        VerticalButton {
            icon: "power_settings_new"
            onTriggered: RaohaneState.setPrimaryOpen("session", true)
        }
    }

    Component {
        id: verticalSeparatorComponent

        Item {
            implicitWidth: 36
            implicitHeight: 1

            Rectangle {
                anchors.fill: parent
                color: RaohaneTheme.borderFaint
            }
        }
    }

    component VerticalButton: RaohaneIconButton {
        id: button

        property int badgeCount: 0
        signal triggered()

        implicitWidth: 36
        implicitHeight: 36
        buttonSize: 36
        iconSize: 16
        transparentIdle: true
        onClicked: button.triggered()

        Rectangle {
            anchors {
                right: parent.right
                top: parent.top
                rightMargin: 1
                topMargin: 1
            }
            width: 14
            height: 14
            radius: 7
            color: RaohaneTheme.accent
            opacity: button.badgeCount > 0 ? 1 : 0
            scale: button.badgeCount > 0 ? 1 : 0.45

            Text {
                anchors.centerIn: parent
                text: Math.min(9, button.badgeCount) + (button.badgeCount > 9 ? "+" : "")
                color: RaohaneTheme.background
                font.pixelSize: 6
                font.weight: Font.Bold
            }

            Behavior on opacity { NumberAnimation { duration: RaohaneMotion.micro } }
            Behavior on scale {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeEmphasized }
            }
        }
    }
}
