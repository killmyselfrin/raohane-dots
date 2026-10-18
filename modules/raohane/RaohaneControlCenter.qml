pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell
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
    // All dimensions are logical Wayland pixels. Never size a floating layer
    // beyond the currently focused output (including fractional scaling).
    readonly property int screenWidth: Math.max(1, Math.round(root.focusedScreen?.width ?? 1600))
    readonly property int screenHeight: Math.max(1, Math.round(root.focusedScreen?.height ?? 900))
    readonly property int panelWidth: Math.max(1, Math.min(root.screenWidth - 32,
        Math.min(1040, Math.max(820, Math.round(root.screenWidth * 0.74)))))
    readonly property int panelHeight: Math.max(1, Math.min(root.screenHeight - 32,
        Math.min(760, Math.max(650, root.screenHeight - 64))))
    readonly property bool compactPanel: root.panelWidth < 990
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
                const firstPresentation = !panelWindow.heldVisible
                panelWindow.heldVisible = true
                if (firstPresentation)
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

    Component.onDestruction: RaohaneFocusGrab.removeDismissable(panelWindow)

    PanelWindow {
        id: panelWindow

        property bool heldVisible: false

        visible: heldVisible
        screen: root.focusedScreen
        exclusiveZone: 0
        implicitWidth: root.panelWidth + 12
        implicitHeight: root.panelHeight + 12
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
            interval: RaohaneMotion.panelHoldDuration
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
            idleColor: RaohaneTheme.surfaceRaised
            border.color: RaohaneTheme.borderFaint
            clip: true
            opacity: entered ? 1 : 0
            focus: RaohaneState.controlCenterOpen

            transform: Translate {
                x: panelSurface.entered || !RaohaneMotion.panelTransformEnabled ? 0 : 8
                Behavior on x {
                    enabled: RaohaneMotion.panelTransformEnabled
                    NumberAnimation {
                        duration: panelSurface.entered
                            ? RaohaneMotion.panelEnterDuration : RaohaneMotion.panelExitDuration
                        easing.type: panelSurface.entered ? RaohaneMotion.easeEnter : RaohaneMotion.easeExit
                    }
                }
            }

            Behavior on opacity {
                enabled: RaohaneMotion.panelMotionEnabled
                NumberAnimation {
                    duration: panelSurface.entered
                        ? RaohaneMotion.panelEnterDuration : RaohaneMotion.panelExitDuration
                    easing.type: panelSurface.entered ? RaohaneMotion.easeEnter : RaohaneMotion.easeExit
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: panelSurface.surfaceRadius
                color: RaohaneTheme.surfaceDeep
                opacity: RaohaneTheme.dark ? 0.16 : 0.10
            }

            // A single content tree adapts to output changes without cloning
            // controls or leaving off-screen, unreachable actions.
            Flickable {
                id: panelScroll
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: contentLayout.y + contentLayout.height + RaohaneTheme.spacingLarge

                Controls.ScrollBar.vertical: Controls.ScrollBar {
                    policy: panelScroll.contentHeight > panelScroll.height
                        ? Controls.ScrollBar.AsNeeded : Controls.ScrollBar.AlwaysOff
                }

                ColumnLayout {
                    id: contentLayout
                    x: RaohaneTheme.spacingLarge
                    y: RaohaneTheme.spacingLarge
                    width: Math.max(1, panelScroll.width - 2 * RaohaneTheme.spacingLarge)
                    height: Math.max(implicitHeight, panelScroll.height - 2 * RaohaneTheme.spacingLarge)
                    spacing: RaohaneTheme.spacing

                    RaohaneControlCenterHeader {
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight

                        identityText: root.profileDisplayName.length > 0
                            ? root.profileDisplayName
                            : (root.systemIdentity.length > 0 ? root.systemIdentity : qsTr("Control Center"))
                        timeText: Qt.formatTime(root.now, "HH:mm")
                        dateText: Qt.formatDate(root.now, "ddd, d MMM")

                        onLauncherRequested: panelWindow.openSurface("launcher")
                        onSettingsRequested: panelWindow.openSurface("settings")
                        onPowerRequested: panelWindow.openSurface("session")
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: !root.compactPanel
                        // Two principal lanes give media the same visual
                        // importance as Quick Controls. Notifications have a
                        // full-width activity rail beneath them on desktop.
                        columns: root.compactPanel ? 1 : 2
                        rowSpacing: RaohaneTheme.spacing
                        columnSpacing: RaohaneTheme.spacing

                        RaohaneSurface {
                            Layout.preferredWidth: root.compactPanel ? -1 : 470
                            Layout.fillWidth: true
                            // A Bluetooth/Wi-Fi picker needs the whole row;
                            // there is still only one live Quick Controls tree.
                            Layout.columnSpan: quickControls.pickerOpen && !root.compactPanel ? 2 : 1
                            Layout.fillHeight: !root.compactPanel
                            Layout.preferredHeight: Math.max(360, quickControls.implicitHeight + 68)
                            surfaceRadius: RaohaneTheme.radiusHero
                            raised: true
                            showSheen: true
                            showInnerRim: true
                            idleColor: RaohaneTheme.surfaceRaised
                            idleBorderColor: RaohaneTheme.borderFaint

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: RaohaneTheme.spacing
                                spacing: RaohaneTheme.spacingSmall

                                RowLayout {
                                    visible: !quickControls.pickerOpen
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: visible ? 30 : 0

                                    Text {
                                        text: qsTr("Quick Controls")
                                        color: RaohaneTheme.text
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: RaohaneScenes.autoSceneActive ? qsTr("Automatic") : qsTr("Manual")
                                        color: RaohaneScenes.autoSceneActive ? RaohaneTheme.accent : RaohaneTheme.textFaint
                                        font.pixelSize: 8
                                        font.weight: Font.Medium
                                    }
                                }

                                RaohaneQuickControls {
                                    id: quickControls
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: implicitHeight
                                    screen: panelWindow.screen
                                    tileColumns: 2
                                }

                                Item { Layout.fillHeight: true }
                            }
                        }

                        ColumnLayout {
                            visible: !quickControls.pickerOpen
                            Layout.preferredWidth: root.compactPanel ? -1 : (visible ? 470 : 0)
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.fillHeight: !root.compactPanel
                            spacing: RaohaneTheme.spacing

                            RaohaneControlCenterMediaCard {
                                Layout.fillWidth: true
                                Layout.preferredHeight: implicitHeight

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

                            RaohaneControlCenterActionDock {
                                Layout.fillWidth: true
                                Layout.preferredHeight: implicitHeight

                                onScreenshotRequested: panelWindow.openTransient("regionSelector")
                                onTranslatorRequested: panelWindow.openSurface("screenTranslator")
                                onOskRequested: panelWindow.openTransient("osk")
                                onWallpaperRequested: panelWindow.openSurface("wallpaper")
                                onPowerRequested: panelWindow.openSurface("session")
                            }

                            Item { Layout.fillHeight: !root.compactPanel }
                        }

                        RaohaneNotificationCenter {
                            visible: !quickControls.pickerOpen
                            Layout.fillWidth: true
                            Layout.columnSpan: root.compactPanel ? 1 : 2
                            Layout.fillHeight: false
                            Layout.preferredHeight: root.compactPanel ? 320 : 264
                            Layout.minimumWidth: 0
                        }
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
    }

    component SectionLabel: Item {
        id: sectionLabel
        required property string label
        required property string icon

        Layout.fillWidth: true
        Layout.preferredHeight: 18

        RowLayout {
            anchors.fill: parent
            spacing: RaohaneTheme.spacingSmall

            RaohaneIcon { text: sectionLabel.icon; iconSize: 12; color: RaohaneTheme.textFaint }
            Text {
                text: sectionLabel.label.toUpperCase()
                color: RaohaneTheme.textFaint
                font.pixelSize: 8
                font.weight: Font.DemiBold
                font.letterSpacing: 0.7
            }
            Item { Layout.fillWidth: true }
            Rectangle { Layout.preferredWidth: 44; Layout.preferredHeight: 1; color: RaohaneTheme.borderFaint }
        }
    }
}
