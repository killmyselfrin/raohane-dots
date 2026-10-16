import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.config
import qs.modules.raohane.models
import qs.modules.raohane.services

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    readonly property var results: RaohaneSearch.results.slice(0, 8)
    readonly property var idleActions: RaohaneSearch.actionResults("").slice(0, 6)
    readonly property var pinnedApps: {
        const pinnedIds = Array.from(RaohaneConfig.dockPinnedApps ?? []).slice(0, 6)
        const entries = pinnedIds
            .map(id => DesktopEntries.byId(String(id)) ?? DesktopEntries.heuristicLookup(String(id)))
            .filter(entry => !!entry)
        return entries.length > 0 ? entries : RaohaneSearch.applications.slice(0, 6)
    }
    readonly property string currentMode: {
        const value = String(RaohaneSearch.query ?? "").replace(/^\s+/, "")
        if (value.startsWith("/"))
            return "action"
        if (value.startsWith(">"))
            return "command"
        if (value.startsWith(":"))
            return "clipboard"
        if (value.startsWith("="))
            return "calculator"
        return "app"
    }

    RaohaneSelectionModel {
        id: selection
        count: root.results.length
    }

    function close(): void {
        RaohaneState.setPrimaryOpen("launcher", false)
    }

    function reset(): void {
        selection.reset()
        RaohaneSearch.query = ""
    }

    function stripMode(value): string {
        const current = String(value ?? "").replace(/^\s+/, "")
        if (current.startsWith("/") || current.startsWith(">") || current.startsWith(":") || current.startsWith("="))
            return current.slice(1).replace(/^\s+/, "")
        return current
    }

    function setMode(prefix: string): void {
        const body = root.stripMode(RaohaneSearch.query)
        RaohaneSearch.query = prefix + body
        selection.reset()
        searchBar.focusSearch()
    }

    function executeSelected(): void {
        if (!selection.hasItems)
            return
        const result = root.results[selection.currentIndex]
        if (!result || !result.execute)
            return
        root.close()
        result.execute()
    }

    function executePinned(entry): void {
        if (!entry)
            return
        root.close()
        RaohaneSearch.executeApplication(entry)
    }

    function executeAction(action): void {
        if (!action || !action.execute)
            return
        root.close()
        action.execute()
    }

    PanelWindow {
        id: panelWindow

        // Remain mapped while the visual exit plays; the registry defers
        // destroying this on-demand Scope until after the hold has elapsed.
        property bool heldVisible: false

        visible: heldVisible
        screen: root.focusedScreen
        exclusiveZone: 0
        implicitWidth: 716
        implicitHeight: Math.min(690, launcherSurface.implicitHeight + 22)
        color: "transparent"

        WlrLayershell.namespace: "quickshell:raohane-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: RaohaneState.launcherOpen
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

        anchors {
            top: true
            left: true
            right: true
        }
        margins.top: RaohaneTheme.barHeight + 3 * RaohaneTheme.panelPadding + RaohaneTheme.spacingSmall

        function present(): void {
            closeHold.stop()
            const firstPresentation = !heldVisible
            heldVisible = true
            if (firstPresentation) {
                root.reset()
                launcherSurface.entered = false
            }
            RaohaneFocusGrab.addDismissable(panelWindow)
            Qt.callLater(() => {
                if (!RaohaneState.launcherOpen)
                    return
                launcherSurface.entered = true
                searchBar.focusSearch()
            })
        }

        function dismissVisual(): void {
            launcherSurface.entered = false
            RaohaneFocusGrab.removeDismissable(panelWindow)
            closeHold.restart()
        }

        Component.onCompleted: {
            if (RaohaneState.launcherOpen)
                present()
        }

        Connections {
            target: RaohaneState
            function onLauncherOpenChanged(): void {
                if (RaohaneState.launcherOpen)
                    panelWindow.present()
                else if (panelWindow.heldVisible)
                    panelWindow.dismissVisual()
            }
        }

        Timer {
            id: closeHold
            interval: RaohaneMotion.panelHoldDuration
            repeat: false
            onTriggered: panelWindow.heldVisible = false
        }

        Component.onDestruction: RaohaneFocusGrab.removeDismissable(panelWindow)

        Connections {
            target: RaohaneFocusGrab
            function onDismissed(): void { root.close() }
        }

        RaohaneSurface {
            id: launcherSurface
            property bool entered: false

            anchors.horizontalCenter: parent.horizontalCenter
            width: 680
            implicitHeight: content.implicitHeight + 30
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            idleBorderColor: RaohaneTheme.borderStrong
            clip: true
            opacity: entered ? 1 : 0

            transform: Translate {
                y: launcherSurface.entered || !RaohaneMotion.panelTransformEnabled ? 0 : -8
                Behavior on y {
                    enabled: RaohaneMotion.panelTransformEnabled
                    NumberAnimation {
                        duration: launcherSurface.entered
                            ? RaohaneMotion.panelEnterDuration : RaohaneMotion.panelExitDuration
                        easing.type: launcherSurface.entered ? RaohaneMotion.easeEnter : RaohaneMotion.easeExit
                    }
                }
            }

            Behavior on opacity {
                enabled: RaohaneMotion.panelMotionEnabled
                NumberAnimation {
                    duration: launcherSurface.entered
                        ? RaohaneMotion.panelEnterDuration : RaohaneMotion.panelExitDuration
                    easing.type: launcherSurface.entered ? RaohaneMotion.easeEnter : RaohaneMotion.easeExit
                }
            }

            ColumnLayout {
                id: content

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: RaohaneTheme.panelPadding + RaohaneTheme.spacingTiny
                }
                spacing: RaohaneTheme.spacing + 1

                RaohaneLauncherSearchBar {
                    id: searchBar

                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    queryText: RaohaneSearch.query

                    onQueryEdited: text => {
                        if (RaohaneSearch.query !== text)
                            RaohaneSearch.query = text
                        selection.reset()
                    }
                    onClearRequested: root.reset()
                    onSettingsRequested: {
                        root.close()
                        RaohaneState.setPrimaryOpen("settings", true)
                    }
                    onEscapeRequested: root.close()
                    onSelectionMoveRequested: delta => selection.move(delta)
                    onSubmitRequested: root.executeSelected()
                }

                RaohaneLauncherModeBar {
                    Layout.fillWidth: true
                    currentMode: root.currentMode
                    onModeRequested: prefix => root.setMode(prefix)
                }

                RaohaneLauncherIdleContent {
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? implicitHeight : 0
                    visible: RaohaneSearch.query.trim().length === 0
                    pinnedApps: root.pinnedApps
                    idleActions: root.idleActions
                    onPinnedRequested: entry => root.executePinned(entry)
                    onActionRequested: action => root.executeAction(action)
                }

                RaohaneLauncherResultsView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? implicitHeight : 0
                    visible: RaohaneSearch.query.trim().length > 0
                    results: root.results
                    selectedIndex: selection.currentIndex
                    onSelectionHovered: index => selection.select(index)
                    onActivateRequested: index => {
                        selection.select(index)
                        root.executeSelected()
                    }
                }

                RaohaneLauncherFooter {
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                }
            }
        }
    }
}
