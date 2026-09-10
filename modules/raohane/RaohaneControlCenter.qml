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
    readonly property string profileDisplayName: String(RaohaneConfig.profileDisplayName ?? "").trim()
    readonly property string systemIdentity: {
        const user = String(RaohaneSystemInfo.username ?? "").trim()
        const host = String(RaohaneSystemInfo.hostname ?? "").trim()
        if (user.length > 0 && host.length > 0)
            return user + " @ " + host
        return host.length > 0 ? host : user
    }
    readonly property bool privacyActive: RaohanePrivacy.recordingActive
        || RaohanePrivacy.cameraActive
        || RaohanePrivacy.microphoneActive
    readonly property int panelWidth: Math.min(740, Math.max(600, Math.round((root.focusedScreen?.width ?? 1280) * 0.49)))
    readonly property int panelHeight: Math.min(760, Math.max(620, Math.round((root.focusedScreen?.height ?? 800) - 48)))
    property date now: new Date()

    Timer {
        interval: 1000
        repeat: true
        running: RaohaneState.controlCenterOpen
        onTriggered: root.now = new Date()
    }

    Connections {
        target: RaohaneState

        function onControlCenterOpenChanged(): void {
            if (RaohaneState.controlCenterOpen) {
                closeHold.stop()
                openRefresh.stop()
                panelWindow.heldVisible = true
                panelSurface.entered = false
                root.now = new Date()
                RaohaneNotifications.markAllRead()
                RaohaneFocusGrab.addDismissable(panelWindow)
                Qt.callLater(() => {
                    if (!RaohaneState.controlCenterOpen)
                        return
                    panelSurface.entered = true
                    panelSurface.forceActiveFocus()
                    openRefresh.restart()
                })
            } else if (panelWindow.heldVisible) {
                openRefresh.stop()
                quickControls.pickerMode = ""
                panelSurface.entered = false
                RaohaneFocusGrab.removeDismissable(panelWindow)
                closeHold.restart()
            }
        }
    }

    PanelWindow {
        id: panelWindow

        property bool heldVisible: false

        visible: heldVisible
        screen: root.focusedScreen
        exclusiveZone: 0
        implicitWidth: root.panelWidth + 30
        implicitHeight: root.panelHeight + 30
        color: "transparent"

        WlrLayershell.namespace: "quickshell:raohane-control-center"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: RaohaneState.controlCenterOpen
            ? WlrKeyboardFocus.OnDemand
            : WlrKeyboardFocus.None

        anchors {
            top: true
            right: true
        }
        margins {
            top: 14
            right: 14
        }

        function hide(): void {
            if (RaohaneState.controlCenterOpen)
                RaohaneState.setPrimaryOpen("controlCenter", false)
        }

        function openSurface(surfaceId: string): void {
            RaohaneState.setPrimaryOpen(surfaceId, true)
        }

        function openTransient(surfaceId: string): void {
            panelWindow.hide()
            Qt.callLater(() => RaohaneState.setSurfaceOpen(surfaceId, true))
        }

        Component.onCompleted: {
            if (RaohaneState.controlCenterOpen) {
                heldVisible = true
                panelSurface.entered = true
                RaohaneFocusGrab.addDismissable(panelWindow)
                openRefresh.restart()
            }
        }

        Connections {
            target: RaohaneFocusGrab
            function onDismissed(): void { panelWindow.hide() }
        }

        // Keep command/process work off the interaction-to-first-frame path.
        // Services already maintain cached state through their native monitors;
        // this delayed pass only repairs anything that changed while hidden.
        Timer {
            id: openRefresh
            interval: 90
            repeat: false
            onTriggered: {
                if (!RaohaneState.controlCenterOpen)
                    return
                RaohaneAudio.refresh()
                RaohaneNetwork.refresh()
                RaohaneBluetooth.refresh()
                RaohaneEasyEffects.refresh()
                RaohanePerformance.refreshGameMode()
            }
        }

        Timer {
            id: closeHold
            interval: Math.max(80, RaohaneMotion.standard)
            repeat: false
            onTriggered: panelWindow.heldVisible = false
        }

        RaohaneSurface {
            id: panelSurface
            property bool entered: false

            width: root.panelWidth
            height: root.panelHeight
            anchors {
                top: parent.top
                right: parent.right
            }
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            showInnerRim: false
            border.color: RaohaneTheme.borderStrong
            clip: true
            opacity: entered ? 1 : 0
            focus: RaohaneState.controlCenterOpen

            transform: Translate {
                x: panelSurface.entered || !RaohaneMotion.transformMotionEnabled ? 0 : 8
                Behavior on x {
                    NumberAnimation {
                        duration: RaohaneMotion.standard
                        easing.type: panelSurface.entered ? RaohaneMotion.easeEmphasized : RaohaneMotion.easeExit
                    }
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: 92
                color: RaohaneTheme.surfaceDeep
                opacity: 0.30
            }

            RaohaneSakuraOverlay {
                anchors.fill: parent
                active: RaohaneState.controlCenterOpen && RaohaneConfig.sakuraInControlCenter
            }

            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: RaohaneTheme.panelPadding
                }
                width: panelSurface.entered ? 52 : 14
                height: 3
                radius: 2
                color: RaohaneTheme.accent
                opacity: panelSurface.entered ? 0.78 : 0

                Behavior on width {
                    NumberAnimation { duration: RaohaneMotion.relaxed; easing.type: RaohaneMotion.easeEmphasized }
                }
                Behavior on opacity { NumberAnimation { duration: RaohaneMotion.standard } }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: RaohaneTheme.panelPadding
                anchors.rightMargin: RaohaneTheme.panelPadding
                anchors.topMargin: RaohaneTheme.spacingLarge
                anchors.bottomMargin: RaohaneTheme.spacing
                spacing: RaohaneTheme.spacingSmall + 1

                RaohaneControlCenterHeader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight

                    identityText: root.profileDisplayName.length > 0
                        ? root.profileDisplayName
                        : (root.systemIdentity.length > 0 ? root.systemIdentity : qsTr("Control Center"))
                    timeText: Qt.formatTime(root.now, "HH:mm")
                    dateText: Qt.formatDate(root.now, "ddd, d MMM")

                    onSettingsRequested: panelWindow.openSurface("settings")
                    onPowerRequested: panelWindow.openSurface("session")
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.divider
                }

                RaohaneControlCenterStatusStrip {
                    visible: !quickControls.pickerOpen
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? implicitHeight : 0

                    networkIcon: RaohaneNetwork.materialSymbol
                    networkValue: RaohaneNetwork.networkName.length > 0
                        ? RaohaneNetwork.networkName
                        : (RaohaneNetwork.ethernet ? qsTr("Ethernet") : qsTr("Offline"))
                    networkActive: RaohaneNetwork.wifiConnected || RaohaneNetwork.ethernet

                    bluetoothIcon: RaohaneBluetooth.connected ? "bluetooth_connected"
                        : RaohaneBluetooth.enabled ? "bluetooth" : "bluetooth_disabled"
                    bluetoothValue: RaohaneBluetooth.firstConnectedName.length > 0
                        ? RaohaneBluetooth.firstConnectedName
                        : (RaohaneBluetooth.enabled ? qsTr("On") : qsTr("Off"))
                    bluetoothActive: RaohaneBluetooth.connected

                    audioIcon: RaohaneAudio.muted ? "volume_off" : "speaker"
                    audioValue: RaohaneAudio.sinkName.length > 0
                        ? RaohaneAudio.sinkName : qsTr("Default output")
                    audioActive: RaohaneAudio.ready && !RaohaneAudio.muted

                    privacyValue: root.privacyActive ? qsTr("Device in use") : qsTr("Quiet")
                    privacyActive: root.privacyActive
                }

                SectionLabel {
                    visible: !quickControls.pickerOpen
                    label: qsTr("QUICK CONTROLS")
                    icon: "instant_mix"
                }

                RaohaneQuickControls {
                    id: quickControls
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    screen: panelWindow.screen
                    tileColumns: 3
                }

                RowLayout {
                    visible: !quickControls.pickerOpen
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 142
                    spacing: RaohaneTheme.spacing

                    RaohaneControlCenterMediaCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1

                        mediaAvailable: RaohaneMedia.available
                        playing: RaohaneMedia.isPlaying
                        canGoPrevious: RaohaneMedia.canGoPrevious
                        canTogglePlaying: RaohaneMedia.canTogglePlaying
                        canGoNext: RaohaneMedia.canGoNext
                        progress: RaohaneMedia.progress
                        artUrl: RaohaneMedia.artUrl
                        playerName: RaohaneMedia.available ? RaohaneMedia.playerName : ""
                        title: RaohaneMedia.available && RaohaneMedia.title.length > 0
                            ? RaohaneMedia.title : qsTr("Nothing playing")
                        subtitle: RaohaneMedia.available
                            ? (RaohaneMedia.artist.length > 0 ? RaohaneMedia.artist : RaohaneMedia.playerName)
                            : qsTr("Media controls")
                        elapsedText: RaohaneMedia.length > 0
                            ? RaohaneMedia.formatTime(RaohaneMedia.position)
                            : "--:--"
                        totalText: RaohaneMedia.length > 0
                            ? RaohaneMedia.formatTime(RaohaneMedia.length)
                            : "—"

                        onOpenRequested: RaohaneState.toggleSurface("mediaOverlay")
                        onPreviousRequested: RaohaneMedia.previous()
                        onTogglePlayingRequested: RaohaneMedia.togglePlaying()
                        onNextRequested: RaohaneMedia.next()
                    }

                    RaohaneNotificationCenter {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                    }
                }

                RaohaneControlCenterActionDock {
                    visible: !quickControls.pickerOpen
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? implicitHeight : 0

                    onScreenshotRequested: panelWindow.openTransient("regionSelector")
                    onTranslatorRequested: panelWindow.openSurface("screenTranslator")
                    onOskRequested: panelWindow.openTransient("osk")
                    onWallpaperRequested: panelWindow.openSurface("wallpaper")
                    onPowerRequested: panelWindow.openSurface("session")
                }

                RaohaneControlCenterFooter {
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    privacyActive: root.privacyActive
                    systemIdentity: root.systemIdentity

                    onReloadRequested: RaohaneSession.reloadDesktop()
                    onCloseRequested: panelWindow.hide()
                }
            }

            Keys.onPressed: event => {
                if (event.key !== Qt.Key_Escape)
                    return
                if (quickControls.pickerOpen) {
                    quickControls.pickerMode = ""
                    event.accepted = true
                    return
                }
                panelWindow.hide()
                event.accepted = true
            }
        }

        IpcHandler {
            target: "sidebarRight"
            function toggle(): void { RaohaneState.togglePrimary("controlCenter") }
            function open(): void { RaohaneState.setPrimaryOpen("controlCenter", true) }
            function close(): void { RaohaneState.setPrimaryOpen("controlCenter", false) }
        }

        CompositorGlobalShortcut {
            name: "sidebarRightToggle"
            description: "Toggles Raohane control center"
            onPressed: RaohaneState.togglePrimary("controlCenter")
        }
    }

    component SectionLabel: Item {
        id: sectionLabel
        required property string label
        required property string icon

        Layout.fillWidth: true
        Layout.preferredHeight: 21

        RowLayout {
            anchors.fill: parent
            spacing: RaohaneTheme.spacingSmall

            RaohaneIcon { text: sectionLabel.icon; iconSize: 12; color: RaohaneTheme.textFaint }
            Text {
                text: sectionLabel.label.toUpperCase()
                color: RaohaneTheme.textFaint
                font.pixelSize: 8
                font.weight: Font.DemiBold
                font.letterSpacing: 0.9
            }
            Item { Layout.fillWidth: true }
            Rectangle { Layout.preferredWidth: 44; Layout.preferredHeight: 1; color: RaohaneTheme.borderFaint }
        }
    }
}
