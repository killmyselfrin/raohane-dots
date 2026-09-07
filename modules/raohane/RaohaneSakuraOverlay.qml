pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes

import qs.modules.raohane.config

// Lightweight ambient sakura layer shared by Raohane surfaces. Each delegate
// uses one scene-graph Shape instead of blur/shader effects, and all animation
// stops while the owning surface is hidden. The petal silhouette deliberately
// includes the shallow cleft associated with cherry blossom petals so the
// ambience reads as sakura rather than generic falling particles.
Item {
    id: root

    property bool active: true
    property string intensity: RaohaneConfig.sakuraIntensity
    property string speed: RaohaneConfig.sakuraSpeed

    readonly property bool running: root.active
        && RaohaneConfig.sakuraEnabled
        && RaohaneMotion.enabled
        && root.width > 1
        && root.height > 1
    readonly property int petalCount: root.intensity === "cinematic" ? 26
        : root.intensity === "standard" ? 18 : 10
    readonly property real speedFactor: root.speed === "brisk" ? 0.76
        : root.speed === "slow" ? 1.28 : 1.0

    visible: RaohaneConfig.sakuraEnabled
    clip: true
    opacity: 0.88

    function noise(index: int, salt: real): real {
        const value = Math.sin((index + 1) * 12.9898 + salt * 78.233) * 43758.5453
        return value - Math.floor(value)
    }

    function fallDuration(index: int): int {
        return Math.round((8200 + root.noise(index, 2.7) * 6200) * root.speedFactor)
    }

    function driftDuration(index: int): int {
        return Math.round((3800 + root.noise(index, 4.1) * 3600) * root.speedFactor)
    }

    Repeater {
        model: root.petalCount

        delegate: Item {
            id: petal
            required property int index

            readonly property real seedX: root.noise(index, 1.2)
            readonly property real seedY: root.noise(index, 3.4)
            readonly property real seedShape: root.noise(index, 5.6)
            readonly property real seedDepth: root.noise(index, 6.9)
            readonly property real seedFace: root.noise(index, 8.3)
            readonly property real baseX: Math.max(0, seedX * Math.max(0, root.width - width))
            readonly property real drift: 28 + root.noise(index, 7.8) * 58
            readonly property int delayMs: Math.round(seedY * 4800 * root.speedFactor)
            readonly property real restingAngle: -34 + root.noise(index, 12.4) * 68
            readonly property real swayAngle: 48 + root.noise(index, 15.8) * 64

            // A few larger, softer petals create depth without requiring blur.
            width: 11 + seedShape * 7 + seedDepth * 5
            height: width * (0.96 + root.noise(index, 9.1) * 0.22)
            opacity: 0.38 + seedDepth * 0.34
            transformOrigin: Item.Center

            Shape {
                id: petalShape
                anchors.fill: parent
                antialiasing: true

                ShapePath {
                    strokeWidth: 0.45
                    strokeColor: RaohaneTheme.dark ? "#78d786a8" : "#70ad456f"
                    fillColor: petal.seedFace > 0.52
                        ? (RaohaneTheme.dark ? "#ffe4ee" : "#f29ab9")
                        : (RaohaneTheme.dark ? "#f7b8cf" : "#df789d")

                    startX: petalShape.width * 0.50
                    startY: petalShape.height * 0.98

                    // Left side rises into the first rounded lobe.
                    PathCubic {
                        control1X: petalShape.width * 0.21
                        control1Y: petalShape.height * 0.82
                        control2X: petalShape.width * 0.03
                        control2Y: petalShape.height * 0.47
                        x: petalShape.width * 0.26
                        y: petalShape.height * 0.16
                    }

                    // The two top lobes meet in a shallow central cleft, the
                    // detail that makes a detached petal read immediately as sakura.
                    PathCubic {
                        control1X: petalShape.width * 0.34
                        control1Y: petalShape.height * 0.05
                        control2X: petalShape.width * 0.43
                        control2Y: petalShape.height * 0.08
                        x: petalShape.width * 0.50
                        y: petalShape.height * 0.23
                    }
                    PathCubic {
                        control1X: petalShape.width * 0.57
                        control1Y: petalShape.height * 0.08
                        control2X: petalShape.width * 0.66
                        control2Y: petalShape.height * 0.05
                        x: petalShape.width * 0.74
                        y: petalShape.height * 0.16
                    }

                    // Right side tapers back into the narrow petal base.
                    PathCubic {
                        control1X: petalShape.width * 0.97
                        control1Y: petalShape.height * 0.47
                        control2X: petalShape.width * 0.79
                        control2Y: petalShape.height * 0.82
                        x: petalShape.width * 0.50
                        y: petalShape.height * 0.98
                    }
                }

                // Subtle central blush/vein. It adds the pale-to-pink depth from
                // the visual reference without a per-petal shader or blur pass.
                ShapePath {
                    fillColor: "transparent"
                    strokeColor: RaohaneTheme.dark ? "#6bd67f9d" : "#66b54d78"
                    strokeWidth: Math.max(0.45, petal.width * 0.035)

                    startX: petalShape.width * 0.50
                    startY: petalShape.height * 0.90
                    PathCubic {
                        control1X: petalShape.width * 0.48
                        control1Y: petalShape.height * 0.72
                        control2X: petalShape.width * 0.50
                        control2Y: petalShape.height * 0.50
                        x: petalShape.width * 0.50
                        y: petalShape.height * 0.31
                    }
                }
            }

            SequentialAnimation on y {
                running: root.running
                loops: Animation.Infinite

                PauseAnimation { duration: petal.delayMs }
                NumberAnimation {
                    from: -petal.height - 18 - petal.seedY * root.height * 0.20
                    to: root.height + petal.height + 24
                    duration: root.fallDuration(petal.index)
                    easing.type: Easing.Linear
                }
                PauseAnimation {
                    duration: Math.round((420 + root.noise(petal.index, 14.2) * 1200) * root.speedFactor)
                }
            }

            SequentialAnimation on x {
                running: root.running
                loops: Animation.Infinite

                NumberAnimation {
                    from: Math.max(-petal.width, petal.baseX - petal.drift * 0.34)
                    to: Math.min(root.width, petal.baseX + petal.drift)
                    duration: root.driftDuration(petal.index)
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    from: Math.min(root.width, petal.baseX + petal.drift)
                    to: Math.max(-petal.width, petal.baseX - petal.drift * 0.58)
                    duration: Math.round(root.driftDuration(petal.index) * 1.16)
                    easing.type: Easing.InOutSine
                }
            }

            // Do not spin like a particle icon. Sakura petals rock and tumble as
            // the wind catches them, so alternating arcs look considerably more
            // organic while retaining the same inexpensive property animation.
            SequentialAnimation on rotation {
                running: root.running
                loops: Animation.Infinite

                NumberAnimation {
                    from: petal.restingAngle - petal.swayAngle * 0.42
                    to: petal.restingAngle + petal.swayAngle
                    duration: Math.round((3100 + root.noise(petal.index, 16.6) * 2600) * root.speedFactor)
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    from: petal.restingAngle + petal.swayAngle
                    to: petal.restingAngle - petal.swayAngle * 0.68
                    duration: Math.round((3600 + root.noise(petal.index, 17.9) * 3000) * root.speedFactor)
                    easing.type: Easing.InOutSine
                }
            }
        }
    }
}
