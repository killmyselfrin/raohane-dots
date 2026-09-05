import QtQuick

import qs.modules.raohane.services

Rectangle {
    id: root

    property bool raised: false
    property bool active: false
    property bool hovered: false
    property bool pressed: false
    property bool interactive: false
    property bool transparentIdle: false
    property int surfaceRadius: RaohaneTheme.radius
    property bool showSheen: true
    property bool transformMotion: true
    property real hoverScale: RaohaneMotion.subtleHoverScale
    property real pressedScale: RaohaneMotion.softPressScale
    property string feedback: "tap"

    // Game Mode already removes compositor blur/rounding/animations. Keep the
    // QML interaction layer on the same low-cost path as well: large shared
    // surfaces retain color/focus feedback, but stop scale transforms. The same
    // policy also respects the Style Studio reduced-motion preset.
    readonly property bool transformMotionAllowed: root.transformMotion
        && RaohaneMotion.transformMotionEnabled
        && !RaohanePerformance.gameModeActive

    radius: surfaceRadius
    scale: interactive && transformMotionAllowed
        ? (pressed ? pressedScale : hovered ? hoverScale : 1)
        : 1
    color: pressed
        ? RaohaneTheme.surfacePressed
        : active
            ? RaohaneTheme.accentSoft
            : hovered
                ? RaohaneTheme.surfaceHover
                : raised
                    ? RaohaneTheme.surfaceRaised
                    : transparentIdle
                        ? "transparent"
                        : RaohaneTheme.surface
    border.width: transparentIdle && !active && !hovered && !pressed ? 0 : 1
    border.color: active
        ? RaohaneTheme.accentBorder
        : hovered || pressed
            ? RaohaneTheme.borderStrong
            : RaohaneTheme.border

    onPressedChanged: {
        if (root.interactive && root.pressed && root.feedback.length > 0)
            RaohaneUiFeedback.play(root.feedback)
    }

    // The final Nocturne material uses a very restrained inner rim instead of
    // a heavy drop shadow. Because it lives in the shared primitive, panels,
    // cards and command tiles keep identical depth and do not grow one-off
    // glow implementations.
    Rectangle {
        visible: !root.transparentIdle && (root.raised || root.active || root.hovered)
        z: 98
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.surfaceRadius - 1)
        color: "transparent"
        border.width: 1
        border.color: root.active
            ? Qt.rgba(RaohaneTheme.accent.r, RaohaneTheme.accent.g, RaohaneTheme.accent.b, 0.10)
            : Qt.rgba(RaohaneTheme.highlight.r, RaohaneTheme.highlight.g, RaohaneTheme.highlight.b,
                root.hovered ? 0.085 : root.raised ? 0.050 : 0.030)
        opacity: root.pressed ? 0.45 : 1

        Behavior on border.color {
            ColorAnimation { duration: RaohaneMotion.micro }
        }
        Behavior on opacity {
            NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
        }
    }

    Rectangle {
        visible: root.showSheen && RaohaneTheme.sheenEnabled && !root.transparentIdle
        z: 100
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: root.surfaceRadius
            rightMargin: root.surfaceRadius
        }
        height: 1
        color: root.active ? RaohaneTheme.accentGlow : RaohaneTheme.highlight
        opacity: root.pressed ? 0.04 : root.active ? 0.24 : root.hovered ? 0.15 : root.raised ? 0.09 : 0.06

        Behavior on opacity {
            NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
        }
    }

    Behavior on color {
        ColorAnimation { duration: RaohaneMotion.micro }
    }
    Behavior on border.color {
        ColorAnimation { duration: RaohaneMotion.micro }
    }
    Behavior on border.width {
        NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
    }
    Behavior on scale {
        enabled: root.transformMotionAllowed
        NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeEmphasized }
    }
}
