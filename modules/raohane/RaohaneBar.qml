pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.modules.raohane.config
import qs.modules.raohane.services

Scope {
    id: root

    readonly property var activeLayout: RaohaneBarModuleRegistry.sanitizeLayout(
        RaohaneConfig.barModuleLayout,
        "horizontal"
    )
    readonly property bool showDateConfigured: RaohaneConfig.barShowDate
    readonly property bool contextConfigured: root.activeLayout.left.includes("context")
        || root.activeLayout.center.includes("context")
        || root.activeLayout.right.includes("context")

    function styleValue(key: string, fallback): var {
        const style = RaohaneConfig.style
        if (!style || !Object.prototype.hasOwnProperty.call(style, key))
            return fallback
        return style[key]
    }

    function togglePrimarySurface(surfaceId: string): void {
        if (surfaceId === "controlCenter") {
            RaohaneState.togglePrimary("controlCenter")
            return
        }
        RaohaneState.togglePrimary(surfaceId)
    }

    function toggleTransientSurface(surfaceId: string): void {
        RaohaneState.toggleSurface(surfaceId)
    }

    Variants {
        model: RaohaneBarModuleRegistry.selectBarScreens(
            Quickshell.screens,
            RaohaneConfig.barScreenList,
            Hyprland.focusedMonitor?.name ?? ""
        )

        PanelWindow {
            id: barWindow
            required property ShellScreen modelData

            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            implicitHeight: Math.max(40, barWindow.podHeight + barWindow.outerGap * 2)

            property bool superShow: false
            readonly property bool autoHide: RaohaneConfig.barAutoHide
            readonly property bool contextAttention: root.contextConfigured
                && (RaohaneContext.mode === "event"
                    || RaohaneContext.mode === "recording"
                    || RaohaneContext.mode === "privacy")
            readonly property bool mustShow: !autoHide || hoverRegion.containsMouse || superShow || contextAttention
            readonly property var hyprMonitor: Hyprland.monitorFor(barWindow.screen)
            readonly property bool monitorHasFullscreen: hyprMonitor?.activeWorkspace?.hasFullscreen ?? false
            readonly property bool monitorHasSpecialOpen: (hyprMonitor?.lastIpcObject?.specialWorkspace?.name ?? "") !== ""
            readonly property bool effectiveFullscreen: monitorHasFullscreen && !monitorHasSpecialOpen
            readonly property bool fullscreenSuppressed: effectiveFullscreen && !superShow
            readonly property bool contentShown: !fullscreenSuppressed && mustShow
            readonly property real podScale: Number(root.styleValue("barScale", 1.0))
            readonly property int podHeight: Math.max(34, Math.min(64, Math.round(RaohaneConfig.barHeight * podScale)))
            readonly property string surfaceStyle: RaohaneConfig.barSurfaceStyle
            readonly property string groupStyle: RaohaneConfig.barGroupStyle
            readonly property bool cinematicPreset: RaohaneConfig.barStylePreset === "cinematic"
            readonly property bool haloPreset: RaohaneConfig.barStylePreset === "halo"
            readonly property bool compactPreset: RaohaneConfig.barStylePreset === "compact"
            readonly property bool islandsPreset: RaohaneConfig.barStylePreset === "islands"
            readonly property bool panelPreset: surfaceStyle === "panel"
            // Geometry is independent of the look: all presets use the same
            // collision-proof zones, while Halo/Cinematic/Float have their
            // own maximum content widths for an intentional silhouette.
            readonly property real contentWidthLimit: haloPreset ? 1240
                : cinematicPreset ? 1360
                : compactPreset ? 1200
                : islandsPreset ? 1320
                : panelPreset || surfaceStyle === "hug" ? barWindow.width
                : 1400
            readonly property bool compactWidth: barContent.width < 960
            readonly property bool narrowWidth: barContent.width < 770
            readonly property bool ultraNarrow: barContent.width < 590
            readonly property string moduleDensity: ultraNarrow ? "icon"
                : (haloPreset || compactPreset || compactWidth) ? "compact" : "full"
            readonly property bool clockCompact: compactPreset || narrowWidth
            readonly property real centerWidthLimit: Math.max(48,
                Math.min(barContent.width * (ultraNarrow ? 0.36 : narrowWidth ? 0.38 : 0.39),
                    haloPreset ? 405 : compactPreset ? 320 : 460))
            readonly property int edgeMargin: Math.max(0, Math.round(RaohaneConfig.barEdgeMargin * RaohaneTheme.densityScale))
            readonly property int effectiveEdgeMargin: surfaceStyle === "hug" || surfaceStyle === "panel" ? 0 : edgeMargin
            readonly property int outerGap: surfaceStyle === "hug" || surfaceStyle === "panel" ? 0 : 6
            readonly property int podRadius: Math.max(0, Math.min(Math.round(RaohaneConfig.barRadius), Math.floor(podHeight / 2)))
            readonly property int effectiveRadius: surfaceStyle === "hug" ? Math.min(10, podRadius) : podRadius
            readonly property int moduleSpacing: Math.max(0, Math.round(RaohaneConfig.barModuleSpacing))
            readonly property int effectiveModuleSpacing: narrowWidth ? Math.min(3, moduleSpacing)
                : groupStyle === "segmented" ? 1 : moduleSpacing
            readonly property int horizontalPadding: Math.max(2, Math.round(RaohaneConfig.barHorizontalPadding))
            readonly property int effectivePadding: ultraNarrow ? 3
                : narrowWidth ? Math.min(6, horizontalPadding) : horizontalPadding
            readonly property bool zoneBackgroundVisible: RaohaneConfig.barShowBackground
                && !haloPreset
                && surfaceStyle !== "panel"
                && groupStyle === "pills"
            readonly property bool surfaceMotionAllowed: RaohaneMotion.transformMotionEnabled
                && !RaohanePerformance.gameModeActive
            readonly property bool chromaticFlowEnabled: RaohaneConfig.barChromaticFlow
                && RaohaneConfig.barShowBackground
            readonly property bool chromaticFlowAnimating: chromaticFlowEnabled
                && contentShown && visible && RaohaneMotion.panelTransformEnabled
            property real chromaticPhase: 0

            // One slow oscillator per output, shared by all existing pod
            // surfaces. It stops entirely in fullscreen/Game Mode and for
            // reduced-motion preferences. Static gradient remains opt-in.
            SequentialAnimation on chromaticPhase {
                running: barWindow.chromaticFlowAnimating
                loops: Animation.Infinite
                NumberAnimation {
                    from: 0
                    to: 1
                    duration: RaohaneConfig.barChromaticSeconds * 500
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    from: 1
                    to: 0
                    duration: RaohaneConfig.barChromaticSeconds * 500
                    easing.type: Easing.InOutSine
                }
            }

            // Keep the layer-shell surface alive across fullscreen transitions.
            // Hiding/recreating the window itself could leave the bar missing
            // after games changed fullscreen state. A zero-sized input mask makes
            // the resident transparent surface fully click-through while hidden.
            visible: RaohaneState.barOpen && !RaohaneState.screenLocked
            mask: Region {
                width: barWindow.fullscreenSuppressed ? 0 : barWindow.width
                height: barWindow.fullscreenSuppressed ? 0 : barWindow.height
            }
            exclusiveZone: fullscreenSuppressed
                ? 0
                : (autoHide && (!mustShow || !RaohaneConfig.barAutoHidePushWindows))
                    ? 0
                    : implicitHeight

            WlrLayershell.namespace: "quickshell:raohane-bar"
            WlrLayershell.layer: (monitorHasFullscreen && (monitorHasSpecialOpen || superShow))
                ? WlrLayer.Overlay
                : WlrLayer.Top

            anchors {
                top: !RaohaneConfig.barBottom
                bottom: RaohaneConfig.barBottom
                left: true
                right: true
            }

            Timer {
                id: superRevealTimer
                interval: RaohaneConfig.barShowOnSuperDelay
                repeat: false
                onTriggered: barWindow.superShow = true
            }

            Connections {
                target: RaohaneState
                function onSuperDownChanged(): void {
                    if (!RaohaneConfig.barShowOnSuper)
                        return
                    if (RaohaneState.superDown) {
                        superRevealTimer.restart()
                    } else {
                        superRevealTimer.stop()
                        barWindow.superShow = false
                    }
                }
            }

            MouseArea {
                id: hoverRegion
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }

            Item {
                id: barContent
                width: Math.min(parent.width, barWindow.contentWidthLimit)
                anchors.horizontalCenter: parent.horizontalCenter
                height: barWindow.implicitHeight
                // Side zones reserve the complete center footprint plus a
                // real gap. The footprint does not depend on either side's
                // implicit width, so custom layouts cannot create loops.
                readonly property real zoneGap: barWindow.ultraNarrow ? 3
                    : barWindow.narrowWidth ? 5 : barWindow.haloPreset ? 12 : 10
                readonly property real sideInset: barWindow.effectiveEdgeMargin
                    + (barWindow.haloPreset ? 10 : 0)
                readonly property real sideIslandLimit: Math.max(0,
                    (width - centerIsland.width) / 2
                    - sideInset - zoneGap)
                y: {
                    if (barWindow.contentShown)
                        return RaohaneConfig.barBottom
                            ? barWindow.height - height - barWindow.outerGap
                            : barWindow.outerGap
                    return RaohaneConfig.barBottom ? barWindow.height + 2 : -height - 4
                }

                Behavior on y {
                    enabled: barWindow.surfaceMotionAllowed
                    NumberAnimation {
                        duration: RaohaneMotion.standard
                        easing.type: RaohaneMotion.easeEmphasized
                    }
                }

                RaohaneSurface {
                    id: panelSurface
                    // Halo is one continuous glass surface. Keep the same
                    // native modules and their click targets in three zones;
                    // the previous island/panel presets remain unchanged.
                    visible: RaohaneConfig.barShowBackground
                        && (barWindow.surfaceStyle === "panel" || barWindow.haloPreset)
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: barWindow.haloPreset ? barWindow.effectiveEdgeMargin : 0
                        rightMargin: barWindow.haloPreset ? barWindow.effectiveEdgeMargin : 0
                        verticalCenter: parent.verticalCenter
                    }
                    height: barWindow.podHeight
                    surfaceRadius: barWindow.effectiveRadius
                    opacity: RaohaneConfig.barOpacity
                    raised: RaohaneConfig.barShadow
                    showSheen: barWindow.haloPreset && !barWindow.chromaticFlowEnabled
                    showInnerRim: barWindow.haloPreset && !barWindow.chromaticFlowEnabled
                    clip: true
                    // A dark muted glass base prevents a red wallpaper from
                    // turning the entire bar into an opaque saturated strip.
                    idleColor: barWindow.chromaticFlowEnabled
                        ? "transparent"
                        : barWindow.haloPreset
                            ? RaohaneTheme.backgroundElevated
                            : (RaohaneConfig.barShadow ? RaohaneTheme.surfaceRaised : RaohaneTheme.surface)
                    border.color: barWindow.haloPreset
                        ? RaohaneTheme.borderStrong : RaohaneTheme.border

                    RaohaneBarChromaticWash {
                        // The material deliberately extends past its host
                        // and slides underneath the host's rounded clip.
                        visible: barWindow.chromaticFlowEnabled && parent.visible
                            && (!barWindow.panelPreset || parent === panelSurface)
                            && (!barWindow.haloPreset || parent === panelSurface)
                        phase: barWindow.chromaticPhase
                        darkMode: RaohaneTheme.dark
                        firstColor: RaohaneConfig.wallpaperFlowColorA
                        secondColor: RaohaneConfig.wallpaperFlowColorB
                        strength: RaohaneConfig.barChromaticIntensity
                    }

                    Rectangle {
                        // One restrained highlight, not an animated GPU glow.
                        visible: barWindow.haloPreset && !barWindow.chromaticFlowEnabled
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.topMargin: 1
                        width: parent.width * 0.32
                        height: 1
                        radius: 1
                        color: RaohaneTheme.accent
                        opacity: 0.28
                    }
                }

                // Fine separators are painted only when the three zones
                // have comfortable spacing. No artificial icons, polling or
                // hit-target overlays are added.
                Rectangle {
                    visible: barWindow.haloPreset && barContent.width >= 1100
                        && centerIsland.visible && leftIsland.visible
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: centerIsland.left
                    anchors.rightMargin: 9
                    width: 1
                    height: 15
                    radius: 1
                    color: RaohaneTheme.borderStrong
                    opacity: 0.52
                }

                Rectangle {
                    visible: barWindow.haloPreset && barContent.width >= 1100
                        && centerIsland.visible && rightIsland.visible
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: centerIsland.right
                    anchors.leftMargin: 9
                    width: 1
                    height: 15
                    radius: 1
                    color: RaohaneTheme.borderStrong
                    opacity: 0.52
                }

                RaohaneSurface {
                    id: leftIsland
                    visible: root.activeLayout.left.length > 0
                    anchors {
                        left: parent.left
                        leftMargin: barContent.sideInset
                        verticalCenter: parent.verticalCenter
                    }
                    width: visible
                        ? Math.min(barContent.sideIslandLimit, Math.max(0, leftRow.implicitWidth + barWindow.effectivePadding * 2))
                        : 0
                    height: visible ? barWindow.podHeight : 0
                    clip: true
                    surfaceRadius: barWindow.effectiveRadius
                    opacity: barWindow.haloPreset ? 1 : RaohaneConfig.barOpacity
                    raised: !barWindow.chromaticFlowEnabled
                        && !barWindow.haloPreset && RaohaneConfig.barShadow
                    transparentIdle: barWindow.chromaticFlowEnabled
                        || barWindow.haloPreset || !barWindow.zoneBackgroundVisible
                    showSheen: !barWindow.chromaticFlowEnabled
                        && barWindow.cinematicPreset && RaohaneConfig.barShowBackground
                    border.color: barWindow.zoneBackgroundVisible ? RaohaneTheme.border : "transparent"

                    RaohaneBarChromaticWash {
                        // The material deliberately extends past its host
                        // and slides underneath the host's rounded clip.
                        visible: barWindow.chromaticFlowEnabled && parent.visible
                            && (!barWindow.panelPreset || parent === panelSurface)
                            && (!barWindow.haloPreset || parent === panelSurface)
                        phase: barWindow.chromaticPhase
                        darkMode: RaohaneTheme.dark
                        firstColor: RaohaneConfig.wallpaperFlowColorA
                        secondColor: RaohaneConfig.wallpaperFlowColorB
                        strength: RaohaneConfig.barChromaticIntensity
                    }

                    // One quiet accent line per floating pod, never an extra
                    // bar/process or an independently positioned widget.
                    Rectangle {
                        visible: barWindow.cinematicPreset && RaohaneConfig.barShowBackground
                            && !barWindow.chromaticFlowEnabled
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width * 0.22
                        height: 2
                        radius: 1
                        color: RaohaneTheme.accent
                        opacity: 0.36
                    }

                    RowLayout {
                        id: leftRow
                        anchors {
                            fill: parent
                            leftMargin: barWindow.effectivePadding
                            rightMargin: barWindow.effectivePadding
                        }
                        spacing: barWindow.effectiveModuleSpacing

                        Repeater {
                            model: root.activeLayout.left

                            delegate: RaohaneBarModule {
                                required property var modelData

                                moduleId: String(modelData)
                                screen: barWindow.screen
                                parentWindow: barWindow
                                hostActive: barWindow.visible && !barWindow.fullscreenSuppressed
                                showDate: root.showDateConfigured
                                densityMode: barWindow.moduleDensity
                                compactClock: barWindow.clockCompact
                                compactWorkspaces: barWindow.compactWidth
                                minimalWorkspaces: barWindow.ultraNarrow
                                canShow: !(barWindow.narrowWidth && moduleId === "tray")
                                    && !(barWindow.ultraNarrow
                                        && (moduleId === "launcher" || moduleId === "system"))
                                groupStyle: barWindow.groupStyle
                                showBackground: RaohaneConfig.barShowBackground
                                primaryAction: root.togglePrimarySurface
                                transientAction: root.toggleTransientSurface
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }

                RaohaneSurface {
                    id: centerIsland
                    visible: root.activeLayout.center.length > 0
                    anchors.centerIn: parent
                    width: visible
                        ? Math.min(barWindow.centerWidthLimit, Math.max(0, centerRow.implicitWidth + barWindow.effectivePadding * 2))
                        : 0
                    height: visible ? barWindow.podHeight : 0
                    clip: true
                    surfaceRadius: barWindow.effectiveRadius
                    opacity: barWindow.haloPreset ? 1 : RaohaneConfig.barOpacity
                    raised: !barWindow.chromaticFlowEnabled
                        && !barWindow.haloPreset && RaohaneConfig.barShadow
                    transparentIdle: barWindow.chromaticFlowEnabled
                        || barWindow.haloPreset || !barWindow.zoneBackgroundVisible
                    showSheen: !barWindow.chromaticFlowEnabled
                        && barWindow.cinematicPreset && RaohaneConfig.barShowBackground
                    border.color: barWindow.zoneBackgroundVisible
                        ? (barWindow.cinematicPreset ? RaohaneTheme.accentBorder : RaohaneTheme.border)
                        : "transparent"

                    RaohaneBarChromaticWash {
                        // The material deliberately extends past its host
                        // and slides underneath the host's rounded clip.
                        visible: barWindow.chromaticFlowEnabled && parent.visible
                            && (!barWindow.panelPreset || parent === panelSurface)
                            && (!barWindow.haloPreset || parent === panelSurface)
                        phase: barWindow.chromaticPhase
                        darkMode: RaohaneTheme.dark
                        firstColor: RaohaneConfig.wallpaperFlowColorA
                        secondColor: RaohaneConfig.wallpaperFlowColorB
                        strength: RaohaneConfig.barChromaticIntensity
                    }

                    // One quiet accent line per floating pod, never an extra
                    // bar/process or an independently positioned widget.
                    Rectangle {
                        visible: barWindow.cinematicPreset && RaohaneConfig.barShowBackground
                            && !barWindow.chromaticFlowEnabled
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width * 0.38
                        height: 2
                        radius: 1
                        color: RaohaneTheme.accent
                        opacity: 0.85
                    }

                    RowLayout {
                        id: centerRow
                        anchors {
                            fill: parent
                            leftMargin: barWindow.effectivePadding
                            rightMargin: barWindow.effectivePadding
                        }
                        spacing: barWindow.effectiveModuleSpacing

                        Repeater {
                            model: root.activeLayout.center

                            delegate: RaohaneBarModule {
                                required property var modelData

                                moduleId: String(modelData)
                                screen: barWindow.screen
                                parentWindow: barWindow
                                hostActive: barWindow.visible && !barWindow.fullscreenSuppressed
                                showDate: root.showDateConfigured
                                densityMode: barWindow.moduleDensity
                                compactClock: barWindow.clockCompact
                                compactWorkspaces: barWindow.compactWidth
                                minimalWorkspaces: barWindow.ultraNarrow
                                canShow: !(barWindow.narrowWidth && moduleId === "tray")
                                    && !(barWindow.ultraNarrow
                                        && (moduleId === "launcher" || moduleId === "system"))
                                groupStyle: barWindow.groupStyle
                                showBackground: RaohaneConfig.barShowBackground
                                primaryAction: root.togglePrimarySurface
                                transientAction: root.toggleTransientSurface
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }

                RaohaneSurface {
                    id: rightIsland
                    visible: root.activeLayout.right.length > 0
                    anchors {
                        right: parent.right
                        rightMargin: barContent.sideInset
                        verticalCenter: parent.verticalCenter
                    }
                    width: visible
                        ? Math.min(barContent.sideIslandLimit, Math.max(0, rightRow.implicitWidth + barWindow.effectivePadding * 2))
                        : 0
                    height: visible ? barWindow.podHeight : 0
                    clip: true
                    surfaceRadius: barWindow.effectiveRadius
                    opacity: barWindow.haloPreset ? 1 : RaohaneConfig.barOpacity
                    raised: !barWindow.chromaticFlowEnabled
                        && !barWindow.haloPreset && RaohaneConfig.barShadow
                    transparentIdle: barWindow.chromaticFlowEnabled
                        || barWindow.haloPreset || !barWindow.zoneBackgroundVisible
                    showSheen: !barWindow.chromaticFlowEnabled
                        && barWindow.cinematicPreset && RaohaneConfig.barShowBackground
                    border.color: barWindow.zoneBackgroundVisible ? RaohaneTheme.border : "transparent"

                    RaohaneBarChromaticWash {
                        // The material deliberately extends past its host
                        // and slides underneath the host's rounded clip.
                        visible: barWindow.chromaticFlowEnabled && parent.visible
                            && (!barWindow.panelPreset || parent === panelSurface)
                            && (!barWindow.haloPreset || parent === panelSurface)
                        phase: barWindow.chromaticPhase
                        darkMode: RaohaneTheme.dark
                        firstColor: RaohaneConfig.wallpaperFlowColorA
                        secondColor: RaohaneConfig.wallpaperFlowColorB
                        strength: RaohaneConfig.barChromaticIntensity
                    }

                    // One quiet accent line per floating pod, never an extra
                    // bar/process or an independently positioned widget.
                    Rectangle {
                        visible: barWindow.cinematicPreset && RaohaneConfig.barShowBackground
                            && !barWindow.chromaticFlowEnabled
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width * 0.22
                        height: 2
                        radius: 1
                        color: RaohaneTheme.accent
                        opacity: 0.36
                    }

                    RowLayout {
                        id: rightRow
                        anchors {
                            fill: parent
                            leftMargin: barWindow.effectivePadding
                            rightMargin: barWindow.effectivePadding
                        }
                        spacing: barWindow.effectiveModuleSpacing

                        Repeater {
                            model: root.activeLayout.right

                            delegate: RaohaneBarModule {
                                required property var modelData

                                moduleId: String(modelData)
                                screen: barWindow.screen
                                parentWindow: barWindow
                                hostActive: barWindow.visible && !barWindow.fullscreenSuppressed
                                showDate: root.showDateConfigured
                                densityMode: barWindow.moduleDensity
                                compactClock: barWindow.clockCompact
                                compactWorkspaces: barWindow.compactWidth
                                minimalWorkspaces: barWindow.ultraNarrow
                                canShow: !(barWindow.narrowWidth && moduleId === "tray")
                                    && !(barWindow.ultraNarrow
                                        && (moduleId === "launcher" || moduleId === "system"))
                                groupStyle: barWindow.groupStyle
                                showBackground: RaohaneConfig.barShowBackground
                                primaryAction: root.togglePrimarySurface
                                transientAction: root.toggleTransientSurface
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "bar"
        function toggle(): void { RaohaneState.barOpen = !RaohaneState.barOpen }
        function open(): void { RaohaneState.barOpen = true }
        function close(): void { RaohaneState.barOpen = false }
        function mode(): string { return "horizontal" }
    }

    CompositorGlobalShortcut {
        name: "barToggle"
        description: "Toggles the Raohane bar"
        onPressed: RaohaneState.barOpen = !RaohaneState.barOpen
    }
}
