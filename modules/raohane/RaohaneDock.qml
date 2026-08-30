pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

import qs.modules.raohane.config
import qs.modules.raohane.services

Scope {
    id: root

    property bool forcedOpen: false

    function appEntry(appId: string): var {
        if (!appId || appId.length === 0)
            return null
        return DesktopEntries.byId(appId) ?? DesktopEntries.heuristicLookup(appId) ?? null
    }

    function iconName(appId: string, entry): string {
        if (entry?.icon && entry.icon.length > 0)
            return entry.icon
        return appId && appId.length > 0 ? appId : "application-x-executable"
    }

    function isPinned(appId: string): bool {
        const needle = (appId ?? "").toLowerCase()
        return Array.from(RaohaneConfig.dockPinnedApps ?? []).some(id => String(id).toLowerCase() === needle)
    }

    function togglePin(appId: string): void {
        if (!appId || appId.length === 0)
            return

        const current = Array.from(RaohaneConfig.dockPinnedApps ?? [])
        const index = current.findIndex(id => String(id).toLowerCase() === appId.toLowerCase())
        if (index >= 0)
            current.splice(index, 1)
        else
            current.push(appId)
        RaohaneConfig.dockPinnedApps = current
    }

    function activateApp(app): void {
        const windows = Array.from(app?.windows ?? [])
        if (windows.length > 0) {
            const activeIndex = windows.findIndex(window => window.activated)
            const nextIndex = activeIndex >= 0 && windows.length > 1
                ? (activeIndex + 1) % windows.length
                : 0
            windows[nextIndex].activate()
            return
        }

        if (app?.desktopEntry) {
            app.desktopEntry.execute()
            return
        }

        if (app?.id)
            Quickshell.execDetached([app.id])
    }

    function launchNew(app): void {
        if (app?.desktopEntry) {
            app.desktopEntry.execute()
            return
        }
        if (app?.id)
            Quickshell.execDetached([app.id])
    }

    function closeApp(app): void {
        for (const window of Array.from(app?.windows ?? []))
            window.close()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dockWindow

            required property var modelData

            property bool hoverLatched: false
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
            readonly property list<HyprlandWorkspace> monitorWorkspaces: Hyprland.workspaces.values.filter(workspace =>
                workspace.monitor && dockWindow.monitor
                && workspace.monitor.name === dockWindow.monitor.name
            )
            readonly property bool fullscreenActive: monitorWorkspaces.some(workspace =>
                workspace.active
                && workspace.toplevels.values.some(window => window.wayland?.fullscreen)
            )
            readonly property var liveToplevels: ToplevelManager.toplevels.values.filter(toplevel => {
                const title = String(toplevel.title ?? "")
                return !title.toLowerCase().startsWith("quickshell")
                    && String(toplevel.appId ?? "").length > 0
            })
            readonly property var runningApps: {
                const apps = new Map()
                for (const toplevel of dockWindow.liveToplevels) {
                    const appId = String(toplevel.appId ?? "")
                    if (!appId.length)
                        continue

                    if (!apps.has(appId)) {
                        const entry = root.appEntry(appId)
                        apps.set(appId, {
                            id: appId,
                            name: entry?.name ?? toplevel.title ?? appId,
                            icon: root.iconName(appId, entry),
                            desktopEntry: entry,
                            windows: [toplevel],
                            running: true,
                            pinned: root.isPinned(appId)
                        })
                    } else {
                        apps.get(appId).windows.push(toplevel)
                    }
                }
                return Array.from(apps.values())
            }
            readonly property var appModel: {
                const result = []
                const pinnedIds = Array.from(RaohaneConfig.dockPinnedApps ?? [])

                for (const pinnedValue of pinnedIds) {
                    const pinnedId = String(pinnedValue)
                    const running = dockWindow.runningApps.find(app => app.id.toLowerCase() === pinnedId.toLowerCase())
                    if (running) {
                        result.push({
                            id: running.id,
                            name: running.name,
                            icon: running.icon,
                            desktopEntry: running.desktopEntry,
                            windows: running.windows,
                            running: true,
                            pinned: true
                        })
                        continue
                    }

                    const entry = root.appEntry(pinnedId)
                    result.push({
                        id: pinnedId,
                        name: entry?.name ?? pinnedId,
                        icon: root.iconName(pinnedId, entry),
                        desktopEntry: entry,
                        windows: [],
                        running: false,
                        pinned: true
                    })
                }

                for (const running of dockWindow.runningApps) {
                    if (pinnedIds.some(id => String(id).toLowerCase() === running.id.toLowerCase()))
                        continue
                    result.push({
                        id: running.id,
                        name: running.name,
                        icon: running.icon,
                        desktopEntry: running.desktopEntry,
                        windows: running.windows,
                        running: true,
                        pinned: false
                    })
                }

                return result
            }
            readonly property bool revealed: {
                if (dockWindow.fullscreenActive)
                    return dockWindow.hoverLatched || root.forcedOpen
                return !RaohaneConfig.dockAutoHide
                    || RaohaneConfig.dockPinned
                    || dockWindow.hoverLatched
                    || root.forcedOpen
            }
            readonly property int hiddenHoverHeight: 5

            screen: modelData
            visible: RaohaneConfig.dockEnabled
            color: "transparent"
            exclusionMode: ExclusionMode.Auto
            exclusiveZone: RaohaneConfig.dockExclusiveZone
                && RaohaneConfig.dockPinned
                && !dockWindow.fullscreenActive
                ? RaohaneConfig.dockHeight + RaohaneConfig.dockBottomMargin
                : 0
            implicitHeight: dockWindow.revealed
                ? RaohaneConfig.dockHeight + RaohaneConfig.dockBottomMargin + 20
                : dockWindow.hiddenHoverHeight
            WlrLayershell.namespace: "quickshell:raohane-dock"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                bottom: true
                left: true
                right: true
            }

            mask: Region {
                item: hoverArea
            }

            Timer {
                id: hideTimer
                interval: 460
                repeat: false
                onTriggered: dockWindow.hoverLatched = false
            }

            MouseArea {
                id: hoverArea

                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
                width: Math.max(280, dockSurface.implicitWidth + 44)
                height: parent.height
                hoverEnabled: true
                acceptedButtons: Qt.NoButton

                onEntered: {
                    hideTimer.stop()
                    dockWindow.hoverLatched = true
                }
                onExited: hideTimer.restart()

                Rectangle {
                    id: dockHalo
                    anchors.centerIn: dockSurface
                    width: dockSurface.width + 10
                    height: dockSurface.height + 10
                    radius: height / 2
                    color: "transparent"
                    border.width: 1
                    border.color: dockWindow.fullscreenActive ? RaohaneTheme.critical : RaohaneTheme.borderFaint
                    opacity: dockWindow.revealed ? 0.75 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: RaohaneTheme.animationDuration }
                    }
                }

                RaohaneSurface {
                    id: dockSurface

                    anchors {
                        bottom: parent.bottom
                        bottomMargin: RaohaneConfig.dockBottomMargin
                        horizontalCenter: parent.horizontalCenter
                    }
                    implicitWidth: dockRow.implicitWidth + 26
                    width: implicitWidth
                    height: RaohaneConfig.dockHeight
                    surfaceRadius: Math.min(RaohaneTheme.radiusHero, height / 2)
                    raised: true
                    border.color: dockWindow.fullscreenActive
                        ? RaohaneTheme.critical
                        : RaohaneTheme.borderStrong
                    opacity: dockWindow.revealed ? 1 : 0
                    scale: dockWindow.revealed ? 1 : 0.96

                    Behavior on opacity {
                        NumberAnimation { duration: RaohaneTheme.animationFast; easing.type: Easing.OutCubic }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: RaohaneTheme.animationDuration; easing.type: Easing.OutCubic }
                    }

                    RowLayout {
                        id: dockRow

                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                            margins: 7
                        }
                        spacing: 5

                        DockControlButton {
                            glyph: "間"
                            active: RaohaneState.overviewOpen
                            tooltip: qsTr("Spaces")
                            onTriggered: RaohaneState.togglePrimary("overview")
                        }

                        DockControlButton {
                            glyph: "⌖"
                            active: RaohaneConfig.dockPinned
                            tooltip: qsTr("Pin dock")
                            onTriggered: RaohaneConfig.dockPinned = !RaohaneConfig.dockPinned
                        }

                        Rectangle {
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: Math.max(24, RaohaneConfig.dockIconSize - 5)
                            color: RaohaneTheme.borderFaint
                            visible: dockWindow.appModel.length > 0
                        }

                        Repeater {
                            model: dockWindow.appModel

                            delegate: Rectangle {
                                id: appButton

                                required property var modelData
                                required property int index

                                readonly property bool anyActivated: Array.from(modelData.windows ?? []).some(window => window.activated)

                                Layout.preferredWidth: RaohaneConfig.dockIconSize + 16
                                Layout.preferredHeight: RaohaneConfig.dockIconSize + 16
                                radius: 16
                                color: anyActivated
                                    ? RaohaneTheme.accentSoft
                                    : appMouse.containsMouse ? RaohaneTheme.surfaceHover : "transparent"
                                border.width: anyActivated || appMouse.containsMouse ? 1 : 0
                                border.color: anyActivated
                                    ? RaohaneTheme.accentBorder
                                    : RaohaneTheme.borderStrong
                                scale: appMouse.containsMouse ? 1.04 : 1

                                Behavior on scale {
                                    NumberAnimation { duration: RaohaneTheme.animationFast; easing.type: Easing.OutCubic }
                                }

                                IconImage {
                                    anchors.centerIn: parent
                                    implicitSize: RaohaneConfig.dockIconSize
                                    source: Quickshell.iconPath(appButton.modelData.icon, "application-x-executable")
                                }

                                Rectangle {
                                    width: appButton.modelData.windows?.length > 1 ? 18 : 8
                                    height: 3
                                    radius: 2
                                    anchors {
                                        horizontalCenter: parent.horizontalCenter
                                        bottom: parent.bottom
                                        bottomMargin: 2
                                    }
                                    color: appButton.modelData.running ? RaohaneTheme.accent : "transparent"
                                    opacity: appButton.modelData.running ? 0.9 : 0
                                }

                                Rectangle {
                                    visible: appButton.modelData.pinned
                                    width: 5
                                    height: 5
                                    radius: 3
                                    anchors {
                                        right: parent.right
                                        top: parent.top
                                        rightMargin: 4
                                        topMargin: 4
                                    }
                                    color: RaohaneTheme.textMuted
                                    opacity: 0.45
                                }

                                MouseArea {
                                    id: appMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: mouse => {
                                        if (mouse.button === Qt.LeftButton)
                                            root.activateApp(appButton.modelData)
                                        else if (mouse.button === Qt.MiddleButton)
                                            root.launchNew(appButton.modelData)
                                        else if (mouse.button === Qt.RightButton)
                                            root.togglePin(appButton.modelData.id)
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: Math.max(24, RaohaneConfig.dockIconSize - 5)
                            color: RaohaneTheme.borderFaint
                            visible: RaohaneMedia.available && dockWindow.appModel.length > 0
                        }

                        DockControlButton {
                            visible: RaohaneMedia.available
                            glyph: RaohaneMedia.isPlaying ? "♪" : "♫"
                            active: RaohaneMedia.isPlaying
                            tooltip: RaohaneMedia.title.length > 0 ? RaohaneMedia.title : qsTr("Media")
                            onTriggered: RaohaneState.mediaOverlayOpen = !RaohaneState.mediaOverlayOpen
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "raohaneDock"

        function togglePin(): void {
            RaohaneConfig.dockPinned = !RaohaneConfig.dockPinned
        }
        function toggleAutoHide(): void {
            RaohaneConfig.dockAutoHide = !RaohaneConfig.dockAutoHide
        }
        function toggle(): void {
            root.forcedOpen = !root.forcedOpen
        }
    }

    component DockControlButton: Rectangle {
        id: control

        required property string glyph
        property bool active: false
        property string tooltip: ""
        signal triggered()

        Layout.preferredWidth: RaohaneConfig.dockIconSize + 12
        Layout.preferredHeight: RaohaneConfig.dockIconSize + 12
        radius: 16
        color: active
            ? RaohaneTheme.accentSoft
            : controlMouse.containsMouse ? RaohaneTheme.surfaceHover : "transparent"
        border.width: active || controlMouse.containsMouse ? 1 : 0
        border.color: active ? RaohaneTheme.accentBorder : RaohaneTheme.borderStrong
        scale: controlMouse.containsMouse ? 1.04 : 1

        Behavior on scale {
            NumberAnimation { duration: RaohaneTheme.animationFast; easing.type: Easing.OutCubic }
        }

        Text {
            anchors.centerIn: parent
            text: control.glyph
            color: control.active ? RaohaneTheme.accent : RaohaneTheme.text
            font.pixelSize: Math.max(16, RaohaneConfig.dockIconSize * 0.46)
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: controlMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: control.triggered()
        }
    }
}
