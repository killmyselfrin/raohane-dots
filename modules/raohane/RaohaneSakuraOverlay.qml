pragma ComponentBehavior: Bound

import QtQuick

import qs.modules.raohane.config

// Lightweight ambient sakura layer shared by Raohane surfaces. Petals are kept
// deliberately simple: no shaders, blur or per-frame JavaScript. Delegates stay
// resident with their parent surface and animations stop completely while the
// surface is hidden, preserving Raohane's responsiveness budget.
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
    readonly property int petalCount: root.intensity === "cinematic" ? 24
        : root.intensity === "standard" ? 16 : 9
    readonly property real speedFactor: root.speed === "brisk" ? 0.76
        : root.speed === "slow" ? 1.28 : 1.0

    visible: RaohaneConfig.sakuraEnabled
    clip: true
    opacity: 0.82

    function noise(index: int, salt: real): real {
        const value = Math.sin((index + 1) * 12.9898 + salt * 78.233) * 43758.5453
        return value - Math.floor(value)
    }

    function fallDuration(index: int): int {
        return Math.round((7600 + root.noise(index, 2.7) * 6200) * root.speedFactor)
    }

    function driftDuration(index: int): int {
        return Math.round((3300 + root.noise(index, 4.1) * 3600) * root.speedFactor)
    }

    Repeater {
        model: root.petalCount

        delegate: Item {
            id: petal
            required property int index

            readonly property real seedX: root.noise(index, 1.2)
            readonly property real seedY: root.noise(index, 3.4)
            readonly property real seedShape: root.noise(index, 5.6)
            readonly property real baseX: Math.max(0, seedX * Math.max(0, root.width - width))
            readonly property real drift: 18 + root.noise(index, 7.8) * 44
            readonly property int delayMs: Math.round(seedY * 5200 * root.speedFactor)

            width: 8 + seedShape * 7
            height: width * (1.28 + root.noise(index, 9.1) * 0.34)
            opacity: 0.34 + root.noise(index, 10.7) * 0.34
            transformOrigin: Item.Center

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.72
                height: parent.height
                radius: width * 0.52
                rotation: -10 + root.noise(petal.index, 12.4) * 20
                color: RaohaneTheme.dark ? "#ffd4e5" : "#df789d"
                opacity: 0.94

                Rectangle {
                    width: parent.width * 0.48
                    height: parent.height * 0.36
                    radius: width * 0.5
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: parent.height * 0.08
                    }
                    color: RaohaneTheme.dark ? "#f3a9c6" : "#c85882"
                    opacity: 0.38
                }
            }

            SequentialAnimation on y {
                running: root.running
                loops: Animation.Infinite

                PauseAnimation { duration: petal.delayMs }
                NumberAnimation {
                    from: -petal.height - 18 - petal.seedY * root.height * 0.22
                    to: root.height + petal.height + 22
                    duration: root.fallDuration(petal.index)
                    easing.type: Easing.Linear
                }
                PauseAnimation {
                    duration: Math.round((450 + root.noise(petal.index, 14.2) * 1300) * root.speedFactor)
                }
            }

            SequentialAnimation on x {
                running: root.running
                loops: Animation.Infinite

                NumberAnimation {
                    from: Math.max(-petal.width, petal.baseX - petal.drift * 0.35)
                    to: Math.min(root.width, petal.baseX + petal.drift)
                    duration: root.driftDuration(petal.index)
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    from: Math.min(root.width, petal.baseX + petal.drift)
                    to: Math.max(-petal.width, petal.baseX - petal.drift * 0.55)
                    duration: Math.round(root.driftDuration(petal.index) * 1.14)
                    easing.type: Easing.InOutSine
                }
            }

            RotationAnimation on rotation {
                running: root.running
                loops: Animation.Infinite
                from: -35 + petal.seedShape * 110
                to: 325 + petal.seedShape * 110
                duration: Math.round((4800 + root.noise(petal.index, 16.6) * 5200) * root.speedFactor)
                direction: RotationAnimation.Clockwise
            }
        }
    }
}
