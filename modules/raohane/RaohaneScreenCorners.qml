pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.config
import qs.modules.raohane.services

// Native fake-screen rounding and hot-corner interaction surface.
Scope {
    id: root

    function actionForCorner(corner: int): string {
        if (corner === RaohaneRoundCorner.Corner.TopLeft)
            return "leftSidebar"
        if (corner === RaohaneRoundCorner.Corner.TopRight)
            return "controlCenter"
        if (corner === RaohaneRoundCorner.Corner.BottomLeft)
            return RaohaneConfig.hotCornerBottomLeftAction
        return RaohaneConfig.hotCornerBottomRightAction
    }

    function triggerCorner(corner: int, targetScreen): void {
        RaohaneActionRegistry.trigger(root.actionForCorner(corner), targetScreen)
    }

    component CornerWindow: PanelWindow {
        id: cornerWindow

        required property var targetScreen
        required property int corner

        readonly property bool isTopLeft: corner === RaohaneRoundCorner.Corner.TopLeft
        readonly property bool isTopRight: corner === RaohaneRoundCorner.Corner.TopRight
        readonly property bool isBottomLeft: corner === RaohaneRoundCorner.Corner.BottomLeft
        readonly property bool isBottomRight: corner === RaohaneRoundCorner.Corner.BottomRight
        readonly property bool isTop: isTopLeft || isTopRight
        readonly property bool isBottom: isBottomLeft || isBottomRight
        readonly property bool isLeft: isTopLeft || isBottomLeft
        readonly property bool isRight: isTopRight || isBottomRight

        readonly property var monitor: Hyprland.monitorFor(screen)
        readonly property bool fullscreen: monitor?.activeWorkspace?.hasFullscreen ?? false
        readonly property bool specialOpen: (monitor?.lastIpcObject?.specialWorkspace?.name ?? "") !== ""
        readonly property bool effectiveFullscreen: fullscreen && !specialOpen
        readonly property bool roundingVisible: RaohaneConfig.screenRoundingMode === 1
            || (RaohaneConfig.screenRoundingMode === 2 && !effectiveFullscreen)
        readonly property bool interactionActive: RaohaneConfig.hotCornersEnabled
            && !effectiveFullscreen
            && !RaohaneState.screenLocked

        screen: targetScreen
        visible: roundingVisible || interactionActive
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "quickshell:raohane-screen-corners"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: cornerWindow.isTop
            bottom: cornerWindow.isBottom
            left: cornerWindow.isLeft
            right: cornerWindow.isRight
        }

        margins {
            right: RaohaneConfig.deadPixelWorkaround && cornerWindow.isRight ? -1 : 0
            bottom: RaohaneConfig.deadPixelWorkaround && cornerWindow.isBottom ? -1 : 0
        }

        implicitWidth: Math.max(RaohaneConfig.screenCornerRadius, RaohaneConfig.hotCornerRegionWidth)
        implicitHeight: Math.max(RaohaneConfig.screenCornerRadius, RaohaneConfig.hotCornerRegionHeight)

        mask: Region {
            item: cornerWindow.interactionActive ? interactionArea : null
        }

        RaohaneRoundCorner {
            anchors {
                top: cornerWindow.isTop ? parent.top : undefined
                bottom: cornerWindow.isBottom ? parent.bottom : undefined
                left: cornerWindow.isLeft ? parent.left : undefined
                right: cornerWindow.isRight ? parent.right : undefined
            }
            visible: cornerWindow.roundingVisible
            corner: cornerWindow.corner
            implicitSize: RaohaneConfig.screenCornerRadius
            color: "#000000"
        }

        MouseArea {
            id: interactionArea

            width: RaohaneConfig.hotCornerRegionWidth
            height: RaohaneConfig.hotCornerRegionHeight
            visible: cornerWindow.interactionActive
            enabled: visible
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            anchors {
                top: cornerWindow.isTop ? parent.top : undefined
                bottom: cornerWindow.isBottom ? parent.bottom : undefined
                left: cornerWindow.isLeft ? parent.left : undefined
                right: cornerWindow.isRight ? parent.right : undefined
            }

            onEntered: {
                if (!cornerWindow.isTop || !RaohaneConfig.hotCornerClickless)
                    return
                root.triggerCorner(cornerWindow.corner, cornerWindow.targetScreen)
            }

            onPositionChanged: mouse => {
                if (!cornerWindow.isTop || !RaohaneConfig.hotCornerClicklessEnd)
                    return

                const correctX = cornerWindow.isRight
                    ? mouse.x >= interactionArea.width - 2
                    : mouse.x <= 2
                const correctY = mouse.y > RaohaneConfig.hotCornerVerticalOffset
                if (correctX && correctY)
                    root.triggerCorner(cornerWindow.corner, cornerWindow.targetScreen)
            }

            onPressed: root.triggerCorner(cornerWindow.corner, cornerWindow.targetScreen)

            onWheel: wheel => {
                if (!RaohaneConfig.hotCornerValueScroll)
                    return

                const direction = wheel.angleDelta.y >= 0 ? 1 : -1
                if (cornerWindow.isLeft) {
                    const current = RaohaneDisplay.compositeValue(cornerWindow.screen)
                    RaohaneDisplay.setComposite(cornerWindow.screen, current + direction * 0.03)
                } else {
                    const current = RaohaneAudio.volume
                    const step = current < 0.1 ? 0.01 : 0.02
                    RaohaneAudio.setVolume(current + direction * step)
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: RaohaneConfig.hotCornerVisualize
                color: RaohaneTheme.accentSoft
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Item {
            id: monitorCorners
            required property var modelData

            CornerWindow {
                targetScreen: monitorCorners.modelData
                corner: RaohaneRoundCorner.Corner.TopLeft
            }
            CornerWindow {
                targetScreen: monitorCorners.modelData
                corner: RaohaneRoundCorner.Corner.TopRight
            }
            CornerWindow {
                targetScreen: monitorCorners.modelData
                corner: RaohaneRoundCorner.Corner.BottomLeft
            }
            CornerWindow {
                targetScreen: monitorCorners.modelData
                corner: RaohaneRoundCorner.Corner.BottomRight
            }
        }
    }
}
