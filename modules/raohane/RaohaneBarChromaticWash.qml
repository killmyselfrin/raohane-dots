import QtQuick

// A transparent two-tone wash painted *inside* existing Bar materials.
// No extra window, shader, network request or frame sampler. Animation of
// phase belongs to the Bar's single per-output animation controller.
Rectangle {
    id: root

    property color firstColor: "#9067b3"
    property color secondColor: "#ca7e67"
    property real phase: 0
    property real strength: 0.20

    function blend(first, second, amount) {
        const t = Math.max(0, Math.min(1, amount))
        return Qt.rgba(first.r * (1 - t) + second.r * t,
            first.g * (1 - t) + second.g * t,
            first.b * (1 - t) + second.b * t, 1)
    }

    color: "transparent"
    radius: parent ? parent.radius : 0
    opacity: Math.max(0, Math.min(0.45, strength))

    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop {
            position: 0.0
            color: root.blend(root.firstColor, root.secondColor, root.phase)
        }
        GradientStop {
            position: 0.5
            color: root.blend(root.firstColor, root.secondColor, 0.5)
        }
        GradientStop {
            position: 1.0
            color: root.blend(root.secondColor, root.firstColor, root.phase)
        }
    }
}
