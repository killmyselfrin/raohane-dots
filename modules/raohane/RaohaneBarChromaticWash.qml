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

    // Move the precomputed linear gradient as a texture, rather than
    // animating GradientStop positions and rebuilding four gradient textures
    // each frame. Parent pod clips the oversize material to its round shape.
    width: parent ? parent.width * 1.40 : 0
    height: parent ? parent.height : 0
    x: parent ? -parent.width * 0.40 * phase : 0
    radius: parent ? parent.radius : 0
    color: "transparent"
    // The parent glass surface already owns opacity. Opaquely replace its
    // fill here, so turning up strength makes hues *clearer*, not muddier.
    opacity: 1

    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop {
            position: 0.0
            color: root.leftTone
        }
        GradientStop {
            position: 0.34
            color: root.leftTone
        }
        GradientStop {
            position: 0.64
            color: root.rightTone
        }
        GradientStop {
            position: 1.0
            color: root.rightTone
        }
    }
}
