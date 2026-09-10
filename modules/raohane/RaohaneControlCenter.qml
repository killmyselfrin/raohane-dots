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

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    spacing: RaohaneTheme.spacing

                    RaohaneSurface {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        surfaceRadius: RaohaneTheme.radiusLarge
                        active: true
                        showSheen: false
                        showInnerRim: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "spa"
                            iconSize: 23
                            fill: 1
                            symbolWeight: 560
                            grade: 40
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: "Raohane"
                            color: RaohaneTheme.text
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.2
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.profileDisplayName.length > 0
                                ? root.profileDisplayName
                                : (root.systemIdentity.length > 0 ? root.systemIdentity : qsTr("Control Center"))
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                            elide: Text.ElideRight
                        }
                    }

                    ColumnLayout {
                        spacing: 0

                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: Qt.formatTime(root.now, "HH:mm")
                            color: RaohaneTheme.text
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: Qt.formatDate(root.now, "ddd, d MMM")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                        }
                    }

                    HeaderButton {
                        icon: RaohaneNotifications.silent ? "notifications_off" : "notifications"
                        emphasized: RaohaneNotifications.silent || RaohaneNotifications.unread > 0
                        onClicked: RaohaneNotifications.silent = !RaohaneNotifications.silent
                    }
                    HeaderButton {
                        icon: "settings"
                        onClicked: panelWindow.openSurface("settings")
                    }
                    HeaderButton {
                        icon: "power_settings_new"
                        emphasized: true
                        onClicked: panelWindow.openSurface("session")
                    }
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
                    Layout.minimumHeight: 138
                    spacing: RaohaneTheme.spacing

                    MediaCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 0.96
                    }

                    RaohaneNotificationCenter {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1.04
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

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    spacing: RaohaneTheme.spacingSmall

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: root.privacyActive ? RaohaneTheme.critical : RaohaneTheme.success
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.privacyActive ? qsTr("Privacy activity") : qsTr("System ready")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: root.systemIdentity.length > 0
                        text: root.systemIdentity
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 7
                        elide: Text.ElideRight
                    }

                    HeaderButton { icon: "restart_alt"; onClicked: RaohaneSession.reloadDesktop() }
                    HeaderButton { icon: "close"; onClicked: panelWindow.hide() }
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

    component HeaderButton: RaohaneIconButton {
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        buttonSize: 32
        iconSize: 15
        transparentIdle: !emphasized
        showSheen: false
        hoverScale: 1
        pressedScale: 1
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

    component MediaCard: RaohaneSurface {
        id: mediaCard

        surfaceRadius: RaohaneTheme.radiusLarge
        showSheen: false
        raised: false
        hovered: mediaSummaryMouse.containsMouse
        pressed: mediaSummaryMouse.pressed
        interactive: true
        hoverScale: 1
        pressedScale: 1
        idleBorderColor: RaohaneTheme.borderFaint
        hoverBorderColor: RaohaneTheme.borderStrong

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: RaohaneTheme.spacing
            spacing: RaohaneTheme.spacingSmall

            RowLayout {
                id: mediaSummary
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: RaohaneTheme.spacing

                Rectangle {
                    Layout.preferredWidth: 70
                    Layout.preferredHeight: 70
                    radius: RaohaneTheme.radiusLarge
                    color: RaohaneTheme.accentSoft
                    clip: true

                    Image {
                        id: mediaArt
                        anchors.fill: parent
                        source: RaohaneMedia.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }
                    RaohaneIcon {
                        anchors.centerIn: parent
                        visible: !mediaArt.visible
                        text: "music_note"
                        iconSize: 26
                        fill: RaohaneMedia.isPlaying ? 1 : 0
                        color: RaohaneTheme.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: RaohaneTheme.spacingTiny

                    Text {
                        Layout.fillWidth: true
                        text: RaohaneMedia.available && RaohaneMedia.title.length > 0
                            ? RaohaneMedia.title : qsTr("Nothing playing")
                        color: RaohaneTheme.text
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: RaohaneMedia.available
                            ? (RaohaneMedia.artist.length > 0 ? RaohaneMedia.artist : RaohaneMedia.playerName)
                            : qsTr("Media controls")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        elide: Text.ElideRight
                    }
                    Item { Layout.fillHeight: true }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        radius: 2
                        color: RaohaneTheme.surfaceSubtle
                        Rectangle {
                            width: parent.width * RaohaneMedia.progress
                            height: parent.height
                            radius: parent.radius
                            color: RaohaneTheme.accent
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: RaohaneMedia.formatTime(RaohaneMedia.position); color: RaohaneTheme.textFaint; font.pixelSize: 7 }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: RaohaneMedia.length > 0 ? RaohaneMedia.formatTime(RaohaneMedia.length) : "—"
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                        }
                    }
                }

                MouseArea {
                    id: mediaSummaryMouse
                    anchors.fill: parent
                    z: 20
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: RaohaneState.toggleSurface("mediaOverlay")
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 31
                Item { Layout.fillWidth: true }
                RaohaneIconButton {
                    buttonSize: 29; iconSize: 14; icon: "skip_previous"; transparentIdle: true; showSheen: false
                    enabled: RaohaneMedia.canGoPrevious
                    hoverScale: 1
                    pressedScale: 1
                    onClicked: RaohaneMedia.previous()
                }
                RaohaneIconButton {
                    buttonSize: 32; iconSize: 16
                    icon: RaohaneMedia.isPlaying ? "pause" : "play_arrow"
                    emphasized: RaohaneMedia.isPlaying
                    transparentIdle: !RaohaneMedia.isPlaying
                    showSheen: false
                    hoverScale: 1
                    pressedScale: 1
                    enabled: RaohaneMedia.canTogglePlaying
                    onClicked: RaohaneMedia.togglePlaying()
                }
                RaohaneIconButton {
                    buttonSize: 29; iconSize: 14; icon: "skip_next"; transparentIdle: true; showSheen: false
                    enabled: RaohaneMedia.canGoNext
                    hoverScale: 1
                    pressedScale: 1
                    onClicked: RaohaneMedia.next()
                }
                Item { Layout.fillWidth: true }
            }
        }
    }
}
