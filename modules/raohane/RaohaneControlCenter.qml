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
    readonly property int panelWidth: Math.min(680, Math.max(520, Math.round((root.focusedScreen?.width ?? 1280) * 0.46)))
    readonly property int panelHeight: Math.min(620, Math.max(560, Math.round((root.focusedScreen?.height ?? 800) - 72)))
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
            if (!RaohaneState.controlCenterOpen)
                return
            root.now = new Date()
            RaohaneAudio.refresh(true)
            RaohaneNetwork.refresh(true)
            RaohaneEasyEffects.refresh()
            RaohanePerformance.refreshGameMode()
        }
    }

    PanelWindow {
        id: panelWindow

        visible: RaohaneState.controlCenterOpen
        screen: root.focusedScreen
        exclusiveZone: 0
        implicitWidth: root.panelWidth + 28
        implicitHeight: root.panelHeight + 28
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
            top: 12
            right: 12
        }

        function hide(): void {
            RaohaneState.setPrimaryOpen("controlCenter", false)
        }

        function openSurface(surfaceId: string): void {
            RaohaneState.setPrimaryOpen(surfaceId, true)
        }

        function openTransient(surfaceId: string): void {
            panelWindow.hide()
            Qt.callLater(() => RaohaneState.setSurfaceOpen(surfaceId, true))
        }

        onVisibleChanged: {
            if (visible) {
                panelSurface.entered = false
                Qt.callLater(() => panelSurface.entered = true)
                RaohaneNotifications.markAllRead()
                RaohaneFocusGrab.addDismissable(panelWindow)
            } else {
                panelSurface.entered = false
                RaohaneFocusGrab.removeDismissable(panelWindow)
            }
        }

        Connections {
            target: RaohaneFocusGrab
            function onDismissed(): void { panelWindow.hide() }
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

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: 76
                color: RaohaneTheme.surfaceDeep
                opacity: 0.26
            }

            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: 16
                }
                width: 42
                height: 2
                radius: 1
                color: RaohaneTheme.accent
                opacity: 0.72
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 15
                anchors.rightMargin: 15
                anchors.topMargin: 12
                anchors.bottomMargin: 10
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 54
                    spacing: 9

                    RaohaneSurface {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        surfaceRadius: 12
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "spa"
                            iconSize: 20
                            fill: 1
                            symbolWeight: 560
                            grade: 40
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: -1

                        Text {
                            text: "Raohane"
                            color: RaohaneTheme.text
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.2
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.profileDisplayName.length > 0
                                ? root.profileDisplayName
                                : (root.systemIdentity.length > 0 ? root.systemIdentity : qsTr("Control Center"))
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                            elide: Text.ElideRight
                        }
                    }

                    StatusPill {
                        icon: RaohaneNetwork.materialSymbol
                        text: RaohaneNetwork.networkName.length > 0
                            ? RaohaneNetwork.networkName
                            : (RaohaneNetwork.ethernet ? qsTr("Ethernet") : qsTr("Offline"))
                        active: RaohaneNetwork.wifiConnected || RaohaneNetwork.ethernet
                    }

                    Text {
                        text: Qt.formatTime(root.now, "HH:mm")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 9
                        font.weight: Font.Medium
                    }

                    HeaderButton {
                        icon: "notifications"
                        emphasized: RaohaneNotifications.unread > 0
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

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: 11
                    Layout.bottomMargin: 10
                    spacing: 10

                    ColumnLayout {
                        Layout.fillHeight: true
                        Layout.fillWidth: quickControls.pickerOpen
                        Layout.preferredWidth: quickControls.pickerOpen ? -1 : Math.max(292, panelSurface.width * 0.53)
                        spacing: 6

                        SectionLabel {
                            visible: !quickControls.pickerOpen
                            label: qsTr("CONTROLS")
                            icon: "tune"
                        }

                        RaohaneQuickControls {
                            id: quickControls
                            Layout.fillWidth: true
                            Layout.preferredHeight: implicitHeight
                            screen: panelWindow.screen
                        }

                        Item { Layout.fillHeight: true }
                    }

                    ColumnLayout {
                        visible: !quickControls.pickerOpen
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 7

                        MediaCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 126
                        }

                        InfoCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            icon: "headphones"
                            title: qsTr("Devices")
                            firstLabel: qsTr("Output")
                            firstValue: RaohaneAudio.sinkName.length > 0 ? RaohaneAudio.sinkName : qsTr("Default output")
                            secondLabel: qsTr("Input")
                            secondValue: RaohaneAudio.sourceName.length > 0 ? RaohaneAudio.sourceName : qsTr("Default input")
                            onTriggered: quickControls.togglePicker("output")
                        }

                        InfoCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            icon: RaohaneNetwork.materialSymbol
                            title: qsTr("Network")
                            firstLabel: qsTr("Wi-Fi")
                            firstValue: RaohaneNetwork.networkName.length > 0
                                ? RaohaneNetwork.networkName
                                : (RaohaneNetwork.wifiEnabled ? qsTr("Not connected") : qsTr("Off"))
                            secondLabel: qsTr("Signal")
                            secondValue: RaohaneNetwork.wifiConnected ? Math.max(0, RaohaneNetwork.networkStrength) + "%" : "—"
                            accent: RaohaneNetwork.wifiConnected || RaohaneNetwork.ethernet
                            onTriggered: quickControls.togglePicker("wifi")
                        }

                        RaohaneNotificationCenter {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: 104
                        }
                    }
                }

                RaohaneSurface {
                    visible: !quickControls.pickerOpen
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? 64 : 0
                    surfaceRadius: RaohaneTheme.radius
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
                    Layout.preferredHeight: 30
                    Layout.topMargin: 5
                    spacing: 7

                    Rectangle {
                        width: 5
                        height: 5
                        radius: 3
                        color: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                            ? RaohaneTheme.critical
                            : RaohaneTheme.success
                    }

                    Text {
                        Layout.fillWidth: true
                        text: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                            ? qsTr("Privacy activity")
                            : qsTr("System ready")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 7
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: root.systemIdentity.length > 0
                        text: root.systemIdentity
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 6
                        elide: Text.ElideRight
                    }

                    Text {
                        text: Qt.formatDate(root.now, "ddd, d MMM")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 7
                    }

                    HeaderButton { icon: "restart_alt"; onClicked: RaohaneSession.reloadDesktop() }
                    HeaderButton { icon: "close"; onClicked: panelWindow.hide() }
                }
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
        Layout.preferredWidth: 29
        Layout.preferredHeight: 29
        buttonSize: 29
        iconSize: 14
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
        Layout.preferredHeight: 20

        RowLayout {
            anchors.fill: parent
            spacing: 6

            RaohaneIcon { text: sectionLabel.icon; iconSize: 11; color: RaohaneTheme.textFaint }
            Text {
                text: sectionLabel.label.toUpperCase()
                color: RaohaneTheme.textFaint
                font.pixelSize: 7
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
            }
            Item { Layout.fillWidth: true }
            Rectangle { Layout.preferredWidth: 28; Layout.preferredHeight: 1; color: RaohaneTheme.borderFaint }
        }
    }

    component StatusPill: RaohaneSurface {
        id: pill
        required property string icon
        required property string text

        implicitWidth: Math.min(142, pillRow.implicitWidth + 14)
        implicitHeight: 24
        surfaceRadius: 9
        transparentIdle: !pill.active
        showSheen: false
        border.color: pill.active ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 5

            RaohaneIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: pill.icon
                iconSize: 11
                fill: pill.active ? 1 : 0
                color: pill.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(105, implicitWidth)
                text: pill.text
                color: pill.active ? RaohaneTheme.text : RaohaneTheme.textMuted
                font.pixelSize: 7
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }
    }

    component QuickAction: RaohaneSurface {
        id: action
        required property string icon
        required property string label
        property bool accent: false
        signal triggered()

        Layout.preferredHeight: 50
        surfaceRadius: 11
        active: action.accent
        raised: false
        showSheen: false
        interactive: true
        hovered: actionMouse.containsMouse || activeFocus
        pressed: actionMouse.pressed
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: true
        transparentIdle: !action.accent && !action.hovered

        Column {
            anchors.centerIn: parent
            spacing: 3

            RaohaneIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: action.icon
                iconSize: 15
                fill: action.accent ? 1 : action.hovered ? 0.35 : 0
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
    }

    component InfoCard: RaohaneSurface {
        id: infoCard
        required property string icon
        required property string title
        required property string firstLabel
        required property string firstValue
        required property string secondLabel
        required property string secondValue
        property bool accent: false
        signal triggered()

        surfaceRadius: 11
        raised: false
        showSheen: false
        interactive: true
        hovered: infoMouse.containsMouse || activeFocus
        pressed: infoMouse.pressed
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: true
        border.color: infoCard.accent ? RaohaneTheme.accentBorder
            : infoCard.hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

        RowLayout {
            anchors.fill: parent
            anchors.margins: 7
            spacing: 7

            RaohaneIcon {
                Layout.preferredWidth: 20
                text: infoCard.icon
                iconSize: 15
                fill: infoCard.accent ? 1 : 0
                color: infoCard.accent ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: infoCard.title
                        color: RaohaneTheme.text
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    RaohaneIcon {
                        text: "arrow_forward"
                        iconSize: 10
                        color: infoCard.hovered ? RaohaneTheme.accent : RaohaneTheme.textFaint
                    }
                }
                DetailRow { Layout.fillWidth: true; label: infoCard.firstLabel; value: infoCard.firstValue }
                DetailRow { Layout.fillWidth: true; label: infoCard.secondLabel; value: infoCard.secondValue }
            }
        }

        MouseArea {
            id: infoMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: infoCard.forceActiveFocus()
            onClicked: infoCard.triggered()
        }
    }

    component DetailRow: RowLayout {
        id: detail
        required property string label
        required property string value
        spacing: 6

        Text {
            Layout.preferredWidth: 38
            text: detail.label
            color: RaohaneTheme.textFaint
            font.pixelSize: 6
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            text: detail.value
            color: RaohaneTheme.textMuted
            font.pixelSize: 6
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
    }

    component MediaCard: RaohaneSurface {
        id: mediaCard

        surfaceRadius: 12
        showSheen: false
        raised: false
        hovered: mediaMouse.containsMouse
        interactive: true
        hoverScale: 1
        pressedScale: 1
        border.color: hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 9
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 9

                Rectangle {
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 60
                    radius: 11
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
                        iconSize: 23
                        fill: RaohaneMedia.isPlaying ? 1 : 0
                        color: RaohaneTheme.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: RaohaneMedia.available && RaohaneMedia.title.length > 0
                            ? RaohaneMedia.title : qsTr("Nothing playing")
                        color: RaohaneTheme.text
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: RaohaneMedia.available
                            ? (RaohaneMedia.artist.length > 0 ? RaohaneMedia.artist : RaohaneMedia.playerName)
                            : qsTr("Media controls")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 7
                        elide: Text.ElideRight
                    }
                    Item { Layout.fillHeight: true }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 3
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
                        Text { text: RaohaneMedia.formatTime(RaohaneMedia.position); color: RaohaneTheme.textFaint; font.pixelSize: 6 }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: RaohaneMedia.length > 0 ? RaohaneMedia.formatTime(RaohaneMedia.length) : "—"
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 6
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 27
                Item { Layout.fillWidth: true }
                RaohaneIconButton {
                    buttonSize: 26; iconSize: 13; icon: "skip_previous"; transparentIdle: true; showSheen: false
                    enabled: RaohaneMedia.canGoPrevious
                    hoverScale: 1
                    pressedScale: 1
                    onClicked: RaohaneMedia.previous()
                }
                RaohaneIconButton {
                    buttonSize: 28; iconSize: 15
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
                    buttonSize: 26; iconSize: 13; icon: "skip_next"; transparentIdle: true; showSheen: false
                    enabled: RaohaneMedia.canGoNext
                    hoverScale: 1
                    pressedScale: 1
                    onClicked: RaohaneMedia.next()
                }
                Item { Layout.fillWidth: true }
            }
        }

        MouseArea {
            id: mediaMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            z: -1
            onClicked: RaohaneState.toggleSurface("mediaOverlay")
        }
    }
}
