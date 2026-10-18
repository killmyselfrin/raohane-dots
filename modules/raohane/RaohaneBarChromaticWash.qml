import QtQuick

// The primary chromatic glass fill, not another low-alpha tint painted
// over an already colored surface. The base material becomes transparent
// while this fill is active, avoiding compounded grey/purple overlays.
// One smooth moving transition keeps both wallpaper hues distinguishable
// at *every* animation frame (they never blend into the same flat color).
Rectangle {
    id: root

    property color firstColor: "#9067b3"
    property color secondColor: "#ca7e67"
    property bool darkMode: true
    property real phase: 0
    property real strength: 0.20

    readonly property real colorStrength: Math.max(0.15,
        Math.min(0.90, 0.24 + strength * 1.47))
    readonly property color materialBase: darkMode ? "#151820" : "#e7e8ec"

    function tint(base, hue, factor) {
        const f = Math.max(0, Math.min(1, factor))
        // Use the actual wallpaper hue, but keep its luminance restrained.
        // Bright yellow/white text must retain contrast against the glass.
        const scale = Math.min(1, 0.50 / Math.max(hue.r, hue.g, hue.b, 0.001))
        return Qt.rgba(base.r * (1 - f) + hue.r * scale * f,
            base.g * (1 - f) + hue.g * scale * f,
            base.b * (1 - f) + hue.b * scale * f, 1)
    }

    readonly property color leftTone: root.tint(root.materialBase, root.firstColor, root.colorStrength)
    readonly property color rightTone: root.tint(root.materialBase, root.secondColor, root.colorStrength)

    // Two static gradients share the same endpoint hues but shift the
    // transition zone. Crossfade the *transition location*, never the end
    // colors, so both wallpaper hues remain visible even at phase=0.5.
    // Both fills match the actual capsule bounds and rounded corners.
    anchors.fill: parent
    radius: parent ? parent.radius : 0
    color: "transparent"
    opacity: 1

    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: root.leftTone }
        GradientStop { position: 0.26; color: root.leftTone }
        GradientStop { position: 0.54; color: root.rightTone }
        GradientStop { position: 1.0; color: root.rightTone }
    }

    Rectangle {
        id: shiftedTransition
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        opacity: Math.max(0, Math.min(1, root.phase))

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: root.leftTone }
            GradientStop { position: 0.46; color: root.leftTone }
            GradientStop { position: 0.74; color: root.rightTone }
            GradientStop { position: 1.0; color: root.rightTone }
        }
    }
}
