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
    property bool showInnerRim: true
    property bool transformMotion: true
    property real hoverScale: 1
    property real pressedScale: 1
    property string feedback: "tap"

    // Shared material-state contract. Consumers can tune a surface without
    // replacing its state machine with one-off Rectangle bindings.
    property color idleColor: root.raised
        ? RaohaneTheme.surfaceRaised
        : root.transparentIdle
            ? "transparent"
            : RaohaneTheme.surface
    property color hoverColor: RaohaneTheme.surfaceHover
    property color pressedColor: RaohaneTheme.surfacePressed
    property color activeColor: RaohaneTheme.accentSoft
    property color idleBorderColor: root.raised ? RaohaneTheme.borderStrong : RaohaneTheme.border
    property color hoverBorderColor: RaohaneTheme.borderStrong
    property color pressedBorderColor: RaohaneTheme.borderStrong
    property color activeBorderColor: RaohaneTheme.accentBorder

    // A restrained state rail is the canonical compact emphasis marker used
    // by Settings rows, command tiles and other dense Raohane surfaces.
    property bool showStateRail: false
    property color stateRailColor: RaohaneTheme.accent
    property real stateRailOpacity: 0.76
    property int stateRailWidth: 3
    property int stateRailLength: Math.min(26, Math.max(0, Math.round(root.height - 16)))
    property int stateRailInset: 2
    property int stateRailRadius: 2

    readonly property bool transformMotionAllowed: root.transformMotion
        && RaohaneMotion.transformMotionEnabled
        && !RaohanePerformance.gameModeActive

    radius: surfaceRadius
    scale: interactive && transformMotionAllowed
        ? (pressed ? pressedScale : hovered ? hoverScale : 1)
        : 1
    color: pressed
        ? root.pressedColor
        : active
            ? root.activeColor
            : hovered
                ? root.hoverColor
                : root.idleColor
    border.width: transparentIdle && !active && !hovered && !pressed ? 0 : 1
    border.color: active
        ? root.activeBorderColor
        : pressed
            ? root.pressedBorderColor
            : hovered
                ? root.hoverBorderColor
                : root.idleBorderColor

    onPressedChanged: {
        if (root.interactive && root.pressed && root.feedback.length > 0)
            RaohaneUiFeedback.play(root.feedback)
    }

    // Soft glass rim: one inexpensive 1px layer shared by all cards. Raised
    // surfaces reflect more light without animated blurs or frame shaders.
    Rectangle {
        visible: root.showInnerRim && (!root.transparentIdle || root.active || root.hovered || root.pressed)
        z: 98
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.surfaceRadius - 1)
        color: "transparent"
        border.width: 1
        border.color: root.active
            ? Qt.rgba(root.activeBorderColor.r, root.activeBorderColor.g, root.activeBorderColor.b, 0.16)
            : Qt.rgba(RaohaneTheme.highlight.r, RaohaneTheme.highlight.g, RaohaneTheme.highlight.b,
                root.hovered ? 0.14 : root.raised ? 0.095 : 0.055)
        opacity: root.pressed ? 0.55 : 1

        Behavior on border.color {
            enabled: root.transformMotionAllowed
            ColorAnimation { duration: RaohaneMotion.micro }
        }
        Behavior on opacity {
            enabled: root.transformMotionAllowed
            NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
        }
    }

    Rectangle {
        visible: root.showStateRail && root.stateRailLength > 0
        z: 99
        anchors {
            left: parent.left
            leftMargin: root.stateRailInset
            verticalCenter: parent.verticalCenter
        }
        width: root.stateRailWidth
        height: root.stateRailLength
        radius: Math.min(root.stateRailRadius, width / 2)
        color: root.stateRailColor
        opacity: root.stateRailOpacity

        Behavior on color {
            enabled: root.transformMotionAllowed
            ColorAnimation { duration: RaohaneMotion.micro }
        }
        Behavior on opacity {
            enabled: root.transformMotionAllowed
            NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
        }
    }

    // A one-pixel top catch-light gives the smoky panels the same polished rim
    // as the reference without a compositor-expensive shadow/glow layer.
    Rectangle {
        visible: root.showSheen && RaohaneTheme.sheenEnabled && !root.transparentIdle
        z: 100
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: Math.max(8, root.surfaceRadius - 2)
            rightMargin: Math.max(8, root.surfaceRadius - 2)
        }
        height: 1
        color: root.active ? root.activeBorderColor : RaohaneTheme.highlight
        opacity: root.pressed ? 0.03 : root.active ? 0.24 : root.hovered ? 0.18 : root.raised ? 0.12 : 0.07

        Behavior on opacity {
            enabled: root.transformMotionAllowed
            NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
        }
    }

    Behavior on color {
        enabled: root.transformMotionAllowed
        ColorAnimation { duration: RaohaneMotion.micro }
    }
    Behavior on border.color {
        enabled: root.transformMotionAllowed
        ColorAnimation { duration: RaohaneMotion.micro }
    }
    Behavior on border.width {
        enabled: root.transformMotionAllowed
        NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
    }
    Behavior on scale {
        enabled: root.transformMotionAllowed && (root.hoverScale !== 1 || root.pressedScale !== 1)
        NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeEmphasized }
    }
}
