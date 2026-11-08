pragma ComponentBehavior: Bound

import QtQuick

// Two painted feather fans beside a word. Each wing is rendered once into a
// tiny Canvas texture; only the Items' opacity/rotation animate afterwards.
Item {
    id: root
    objectName: "raohaneLyricWings"

    required property real wordWidth
    property color tint: "#c9d0ef"
    property bool focusMode: false
    property bool expressive: false

    readonly property real wingWidth: root.focusMode ? 74 : 56
    readonly property real wingHeight: root.focusMode ? 54 : 40
    readonly property real gap: root.focusMode ? 7 : 5

    width: root.wordWidth + 2 * (root.wingWidth + root.gap)
    height: root.wingHeight

    function colorWithAlpha(alpha: real): string {
        return "rgba(" + Math.round(root.tint.r * 255) + ","
            + Math.round(root.tint.g * 255) + ","
            + Math.round(root.tint.b * 255) + "," + alpha + ")"
    }

    function paintWing(ctx, mirrored: bool, width: real, height: real): void {
        ctx.clearRect(0, 0, width, height)
        ctx.save()
        if (mirrored) {
            ctx.translate(width, 0)
            ctx.scale(-width / 100, height / 100)
        } else {
            ctx.scale(width / 100, height / 100)
        }

        // Broad upper coverts and a scalloped trailing edge make a recognizable
        // angel-wing silhouette even when rendered in the compact lyric row.
        const fill = ctx.createLinearGradient(3, 9, 96, 82)
        fill.addColorStop(0, root.colorWithAlpha(root.expressive ? 0.98 : 0.92))
        fill.addColorStop(0.58, root.colorWithAlpha(root.expressive ? 0.89 : 0.76))
        fill.addColorStop(1, root.colorWithAlpha(root.expressive ? 0.72 : 0.58))
        ctx.beginPath()
        ctx.moveTo(97, 73)
        ctx.bezierCurveTo(78, 33, 31, -2, 4, 5)
        ctx.bezierCurveTo(4, 23, 24, 34, 43, 40)
        ctx.bezierCurveTo(22, 34, 7, 29, 3, 34)
        ctx.bezierCurveTo(5, 51, 28, 57, 56, 62)
        ctx.bezierCurveTo(34, 57, 12, 56, 13, 66)
        ctx.bezierCurveTo(20, 80, 45, 82, 75, 79)
        ctx.bezierCurveTo(53, 83, 35, 84, 43, 91)
        ctx.bezierCurveTo(64, 101, 90, 91, 97, 73)
        ctx.closePath()
        ctx.fillStyle = fill
        ctx.fill()
        ctx.strokeStyle = root.colorWithAlpha(0.94)
        ctx.lineWidth = 1.75
        ctx.stroke()

        // Five long, overlapping flight feathers follow the outer fan.
        // Their shafts point back to the root beside the word.
        const tips = [
            [6, 7, 42, -4, 77, 26],
            [3, 35, 34, 22, 76, 40],
            [13, 65, 32, 54, 82, 61],
            [43, 90, 50, 73, 88, 72]
        ]
        for (let index = 0; index < tips.length; ++index) {
            const feather = tips[index]
            ctx.beginPath()
            ctx.moveTo(96, 73)
            ctx.quadraticCurveTo(feather[4], feather[5], feather[0], feather[1])
            ctx.quadraticCurveTo(feather[2], feather[3], 96, 73)
            ctx.fillStyle = root.colorWithAlpha(index % 2 ? 0.12 : 0.21)
            ctx.fill()
            ctx.strokeStyle = root.colorWithAlpha(root.expressive ? 0.55 : 0.43)
            ctx.lineWidth = 1.35
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(93, 72)
            ctx.quadraticCurveTo(feather[4] - 7, feather[5] + 3, feather[0] + 9, feather[1] + 5)
            ctx.strokeStyle = "rgba(255,255,255,0.56)"
            ctx.lineWidth = 1.05
            ctx.stroke()
        }

        // Short overlapping coverts convey layered plumage, not a single leaf.
        for (let row = 0; row < 3; ++row) {
            const x = 72 - row * 16
            const y = 51 - row * 12
            ctx.beginPath()
            ctx.moveTo(95, 73)
            ctx.quadraticCurveTo(x + 12, y - 20, x - 9, y - 13)
            ctx.quadraticCurveTo(x + 2, y + 7, 95, 73)
            ctx.fillStyle = "rgba(255,255,255,0.16)"
            ctx.fill()
            ctx.strokeStyle = root.colorWithAlpha(0.4)
            ctx.lineWidth = 1.15
            ctx.stroke()
        }

        ctx.beginPath()
        ctx.moveTo(97, 73)
        ctx.bezierCurveTo(76, 27, 31, -2, 5, 6)
        ctx.strokeStyle = "rgba(250,251,255,0.9)"
        ctx.lineWidth = 2.1
        ctx.stroke()
        ctx.restore()
    }

    Canvas {
        id: leftWing
        x: 0
        y: 0
        width: root.wingWidth
        height: root.wingHeight
        transformOrigin: Item.BottomRight
        onPaint: root.paintWing(getContext("2d"), false, width, height)

        SequentialAnimation on rotation {
            running: root.visible
            loops: Animation.Infinite
            NumberAnimation { to: -5; duration: 1800; easing.type: Easing.InOutSine }
            NumberAnimation { to: 2; duration: 1800; easing.type: Easing.InOutSine }
        }
    }

    Canvas {
        id: rightWing
        x: root.width - width
        y: 0
        width: root.wingWidth
        height: root.wingHeight
        transformOrigin: Item.BottomLeft
        onPaint: root.paintWing(getContext("2d"), true, width, height)

        SequentialAnimation on rotation {
            running: root.visible
            loops: Animation.Infinite
            NumberAnimation { to: 5; duration: 1800; easing.type: Easing.InOutSine }
            NumberAnimation { to: -2; duration: 1800; easing.type: Easing.InOutSine }
        }
    }

    onTintChanged: {
        leftWing.requestPaint()
        rightWing.requestPaint()
    }
    onExpressiveChanged: {
        leftWing.requestPaint()
        rightWing.requestPaint()
    }
}
