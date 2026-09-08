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
            showSheen: true
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
                    leftMargin: 18
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
                anchors.leftMargin: 17
                anchors.rightMargin: 17
                anchors.topMargin: 14
                anchors.bottomMargin: 12
                spacing: 9

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    spacing: 11

                    RaohaneSurface {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        surfaceRadius: 14
                        active: true
                        showSheen: false

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

                RaohaneSurface {
                    visible: !quickControls.pickerOpen
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? 68 : 0
                    surfaceRadius: 15
                    raised: false
                    showSheen: false
                    border.color: RaohaneTheme.borderFaint
                    clip: true

                    GridLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        columns: 4
                        columnSpacing: 5
                        rowSpacing: 0

                        StatusCell {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            icon: RaohaneNetwork.materialSymbol
                            label: qsTr("Network")
                            value: RaohaneNetwork.networkName.length > 0
                                ? RaohaneNetwork.networkName
                                : (RaohaneNetwork.ethernet ? qsTr("Ethernet") : qsTr("Offline"))
                            active: RaohaneNetwork.wifiConnected || RaohaneNetwork.ethernet
                        }
                        StatusCell {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            icon: RaohaneBluetooth.connected ? "bluetooth_connected"
                                : RaohaneBluetooth.enabled ? "bluetooth" : "bluetooth_disabled"
                            label: qsTr("Bluetooth")
                            value: RaohaneBluetooth.firstConnectedName.length > 0
                                ? RaohaneBluetooth.firstConnectedName
                                : (RaohaneBluetooth.enabled ? qsTr("On") : qsTr("Off"))
                            active: RaohaneBluetooth.connected
                        }
                        StatusCell {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            icon: RaohaneAudio.muted ? "volume_off" : "speaker"
                            label: qsTr("Audio")
                            value: RaohaneAudio.sinkName.length > 0 ? RaohaneAudio.sinkName : qsTr("Default output")
                            active: RaohaneAudio.ready && !RaohaneAudio.muted
                        }
                        StatusCell {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            icon: root.privacyActive ? "shield_person" : "verified_user"
                            label: qsTr("Privacy")
                            value: root.privacyActive ? qsTr("Device in use") : qsTr("Quiet")
                            active: root.privacyActive
                            critical: root.privacyActive
                        }
                    }
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
                    spacing: 10

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

                RaohaneSurface {
                    visible: !quickControls.pickerOpen
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? 64 : 0
                    surfaceRadius: 14
                    raised: false
                    showSheen: false
                    border.color: RaohaneTheme.borderFaint

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 7
                        anchors.rightMargin: 7
                        spacing: 5

                        QuickAction {
                            Layout.fillWidth: true
                            icon: "screenshot_region"
                            label: qsTr("Screenshot")
                            onTriggered: panelWindow.openTransient("regionSelector")
                        }
                        QuickAction {
                            Layout.fillWidth: true
                            icon: "translate"
                            label: qsTr("Translator")
                            onTriggered: panelWindow.openSurface("screenTranslator")
                        }
                        QuickAction {
                            Layout.fillWidth: true
                            icon: "keyboard"
                            label: qsTr("OSK")
                            onTriggered: panelWindow.openTransient("osk")
                        }
                        QuickAction {
                            Layout.fillWidth: true
                            icon: "wallpaper"
                            label: qsTr("Wallpaper")
                            onTriggered: panelWindow.openSurface("wallpaper")
                        }
                        QuickAction {
                            Layout.fillWidth: true
                            icon: "power_settings_new"
                            label: qsTr("Power")
                            accent: true
                            onTriggered: panelWindow.openSurface("session")
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    spacing: 8

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
            spacing: 7

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

    component StatusCell: Item {
        id: status
        required property string icon
        required property string label
        required property string value
        property bool active: false
        property bool critical: false

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: status.active
                ? (status.critical ? Qt.rgba(RaohaneTheme.critical.r, RaohaneTheme.critical.g, RaohaneTheme.critical.b, 0.10) : RaohaneTheme.accentSoft)
                : "transparent"
            opacity: status.active ? 0.88 : 1

            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 9
            spacing: 8

            RaohaneIcon {
                text: status.icon
                iconSize: 16
                fill: status.active ? 1 : 0
                color: status.critical ? RaohaneTheme.critical
                    : status.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: status.label
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: status.value
                    color: status.critical ? RaohaneTheme.critical : RaohaneTheme.text
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }
        }
    }

    component QuickAction: RaohaneSurface {
        id: action
        required property string icon
        required property string label
        property bool accent: false
        signal triggered()

        Layout.preferredHeight: 52
        surfaceRadius: 11
        raised: false
        showSheen: false
        interactive: true
        hovered: actionMouse.containsMouse || activeFocus
        pressed: actionMouse.pressed
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: true
        transparentIdle: !action.accent && !action.hovered
        border.color: action.accent ? RaohaneTheme.accentBorder
            : action.hovered ? RaohaneTheme.borderStrong : "transparent"

        Column {
            anchors.centerIn: parent
            spacing: 3

            RaohaneIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: action.icon
                iconSize: 16
                fill: action.accent ? 1 : action.hovered ? 0.4 : 0
                symbolWeight: action.accent ? 560 : 450
                color: action.accent || action.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: action.label
                color: action.accent || action.hovered ? RaohaneTheme.text : RaohaneTheme.textFaint
                font.pixelSize: 7
                font.weight: Font.Medium
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

    component MediaCard: RaohaneSurface {
        id: mediaCard

        surfaceRadius: 13
        showSheen: false
        raised: false
        hovered: mediaSummaryMouse.containsMouse
        pressed: mediaSummaryMouse.pressed
        interactive: true
        hoverScale: 1
        pressedScale: 1
        border.color: hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 11
            spacing: 6

            RowLayout {
                id: mediaSummary
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 11

                Rectangle {
                    Layout.preferredWidth: 70
                    Layout.preferredHeight: 70
                    radius: 13
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
                    spacing: 2

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
