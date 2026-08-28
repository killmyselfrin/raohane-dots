pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.modules.raohane.config

// Raohane-owned screen frame. Fake rounded screen corners are intentionally a
// separate surface; this component only owns the persistent edge frame and its
// workspace reservation semantics.
Scope {
    id: root

    readonly property string barPosition: {
        if (RaohaneConfig.barVertical)
            return RaohaneConfig.barBottom ? "right" : "left"
        return RaohaneConfig.barBottom ? "bottom" : "top"
    }

    function frameVisibleFor(side: string): bool {
        if (!RaohaneConfig.frameEnabled)
            return false
        if (side === root.barPosition && !RaohaneConfig.frameBarSideVisible)
            return false
        return true
    }

    component FrameEdge: PanelWindow {
        id: edge

        required property var targetScreen
        required property string side

        screen: targetScreen
        visible: root.frameVisibleFor(side)
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: visible ? RaohaneConfig.frameThickness : 0
        color: "transparent"
        mask: Region {}

        WlrLayershell.namespace: "quickshell:raohane-screen-frame"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: edge.side === "top" || edge.side === "left" || edge.side === "right"
            bottom: edge.side === "bottom" || edge.side === "left" || edge.side === "right"
            left: edge.side === "left" || edge.side === "top" || edge.side === "bottom"
            right: edge.side === "right" || edge.side === "top" || edge.side === "bottom"
        }

        implicitWidth: edge.side === "left" || edge.side === "right"
            ? RaohaneConfig.frameThickness
            : 1
        implicitHeight: edge.side === "top" || edge.side === "bottom"
            ? RaohaneConfig.frameThickness
            : 1

        Rectangle {
            anchors.fill: parent
            color: RaohaneConfig.frameColor
        }
    }

    Variants {
        model: Quickshell.screens

        Item {
            id: frameGroup
            required property var modelData

            FrameEdge {
                targetScreen: frameGroup.modelData
                side: "top"
            }
            FrameEdge {
                targetScreen: frameGroup.modelData
                side: "bottom"
            }
            FrameEdge {
                targetScreen: frameGroup.modelData
                side: "left"
            }
            FrameEdge {
                targetScreen: frameGroup.modelData
                side: "right"
            }
        }
    }
}
