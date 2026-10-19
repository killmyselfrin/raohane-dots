import QtQuick

// A real moving two-color wave on the bar's primary glass material.
// Colors come from the applied wallpaper; no additional translucent filter,
// video decoder, ShaderEffect or continuously running external process.
Rectangle {
    id: root

    property color firstColor: "#9067b3"
    property color secondColor: "#ca7e67"
    property bool darkMode: true
    // Animate phase from 0 through 1 and repeat. At half a cycle, the two
    // color regions trade places; at 1, we return smoothly to the first frame.
    property real phase: 0
    property real strength: 0.20

    readonly property real colorStrength: Math.max(0.15,
        Math.min(0.90, 0.24 + strength * 1.47))
    readonly property color materialBase: darkMode ? "#151820" : "#e7e8ec"

    function tint(base, hue, factor) {
        const f = Math.max(0, Math.min(1, factor))
        // Cap luminance so white time/status labels remain legible.
        const scale = Math.min(1, 0.50 / Math.max(hue.r, hue.g, hue.b, 0.001))
        return Qt.rgba(base.r * (1 - f) + hue.r * scale * f,
            base.g * (1 - f) + hue.g * scale * f,
            base.b * (1 - f) + hue.b * scale * f, 1)
    }

    readonly property color firstTone: root.tint(root.materialBase, root.firstColor, root.colorStrength)
    readonly property color secondTone: root.tint(root.materialBase, root.secondColor, root.colorStrength)

    function flowingColor(position) {
        // Moving one spatial sine wave, rather than fading A->B uniformly.
        // Nine stops approximate the wave: at *every* phase the bar contains
        // clear regions of both colors and the wave travels horizontally.
        const radians = 2 * Math.PI * (position - root.phase)
        const wave = 0.5 + 0.5 * Math.sin(radians)
        const blend = wave * wave * (3 - 2 * wave)
        return Qt.rgba(
            root.firstTone.r * (1 - blend) + root.secondTone.r * blend,
            root.firstTone.g * (1 - blend) + root.secondTone.g * blend,
            root.firstTone.b * (1 - blend) + root.secondTone.b * blend, 1)
    }

    anchors.fill: parent
    radius: parent ? parent.radius : 0
    color: "transparent"
    opacity: 1

    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.000; color: root.flowingColor(0.000) }
        GradientStop { position: 0.125; color: root.flowingColor(0.125) }
        GradientStop { position: 0.250; color: root.flowingColor(0.250) }
        GradientStop { position: 0.375; color: root.flowingColor(0.375) }
        GradientStop { position: 0.500; color: root.flowingColor(0.500) }
        GradientStop { position: 0.625; color: root.flowingColor(0.625) }
        GradientStop { position: 0.750; color: root.flowingColor(0.750) }
        GradientStop { position: 0.875; color: root.flowingColor(0.875) }
        GradientStop { position: 1.000; color: root.flowingColor(1.000) }
    }
}
