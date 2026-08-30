import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.services

Item {
    id: root

    required property var keyData

    property string keyLabel: String(keyData?.label ?? "")
    property string keyType: String(keyData?.keytype ?? "normal")
    property int keycode: Number(keyData?.keycode ?? -1)
    property string shape: String(keyData?.shape ?? "normal")
    property bool held: false

    readonly property bool isShift: RaohaneYdotool.shiftKeys.includes(keycode)
    readonly property bool isBackspace: keyLabel.toLowerCase() === "backspace"
    readonly property bool isEnter: keyLabel.toLowerCase() === "enter" || keyLabel.toLowerCase() === "return"
    readonly property bool isEmpty: shape === "empty"
    readonly property bool toggled: isShift ? RaohaneYdotool.shiftMode > 0 : held

    readonly property var widthMultiplier: ({
        normal: 1,
        fn: 1,
        tab: 1.6,
        caps: 1.9,
        shift: 2.5,
        control: 1.3
    })
    readonly property var heightMultiplier: ({
        normal: 1,
        fn: 0.7,
        tab: 1,
        caps: 1,
        shift: 1,
        control: 1
    })

    implicitWidth: 45 * (widthMultiplier[shape] ?? 1)
    implicitHeight: 45 * (heightMultiplier[shape] ?? 1)
    Layout.fillWidth: shape === "space" || shape === "expand"

    function pressKey(): void {
        if (isEmpty || keycode < 0)
            return
        RaohaneYdotool.press(keycode)
        if (isShift && RaohaneYdotool.shiftMode === 0)
            RaohaneYdotool.shiftMode = 1
    }

    function releaseKey(): void {
        if (isEmpty || keycode < 0)
            return

        if (keyType === "normal") {
            RaohaneYdotool.release(keycode)
            if (RaohaneYdotool.shiftMode === 1)
                RaohaneYdotool.releaseShiftKeys()
            return
        }

        if (isShift) {
            if (RaohaneYdotool.shiftMode === 1) {
                if (!capsTimer.armed) {
                    capsTimer.armed = true
                    capsTimer.restart()
                } else if (capsTimer.acceptSecondTap) {
                    capsTimer.stop()
                    capsTimer.armed = false
                    capsTimer.acceptSecondTap = false
                    RaohaneYdotool.shiftMode = 2
                } else {
                    capsTimer.armed = false
                    RaohaneYdotool.releaseShiftKeys()
                }
            } else if (RaohaneYdotool.shiftMode === 2) {
                capsTimer.armed = false
                RaohaneYdotool.releaseShiftKeys()
            }
            return
        }

        if (keyType === "modkey") {
            root.held = !root.held
            if (!root.held)
                RaohaneYdotool.release(keycode)
        }
    }

    Timer {
        id: capsTimer
        property bool armed: false
        property bool acceptSecondTap: false
        interval: 300
        onRunningChanged: {
            if (running)
                acceptSecondTap = true
        }
        onTriggered: acceptSecondTap = false
    }

    Rectangle {
        anchors.fill: parent
        radius: 11
        color: {
            if (root.isEmpty)
                return "transparent"
            if (root.toggled)
                return RaohaneTheme.surfaceRaised
            if (keyMouse.pressed)
                return RaohaneTheme.surfacePressed
            if (keyMouse.containsMouse)
                return RaohaneTheme.surfaceHover
            return RaohaneTheme.surfaceSubtle
        }
        border.width: root.isEmpty ? 0 : 1
        border.color: root.toggled ? RaohaneTheme.accentBorder
            : keyMouse.containsMouse ? RaohaneTheme.borderStrong : RaohaneTheme.border

        Text {
            anchors.centerIn: parent
            width: parent.width - 8
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: {
                if (root.isBackspace)
                    return "⌫"
                if (root.isEnter)
                    return "↵"
                if (RaohaneYdotool.shiftMode === 2)
                    return root.keyData.labelCaps ?? root.keyData.labelShift ?? root.keyLabel
                if (RaohaneYdotool.shiftMode === 1)
                    return root.keyData.labelShift ?? root.keyLabel
                return root.keyLabel
            }
            color: root.isEmpty ? "transparent" : root.toggled ? RaohaneTheme.accent : RaohaneTheme.text
            font.pixelSize: root.shape === "fn" ? 10 : 12
            font.weight: root.toggled ? Font.DemiBold : Font.Normal
        }

        MouseArea {
            id: keyMouse
            anchors.fill: parent
            enabled: !root.isEmpty
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: root.pressKey()
            onReleased: root.releaseKey()
            onCanceled: {
                if (root.keyType === "normal" && root.keycode >= 0)
                    RaohaneYdotool.release(root.keycode)
            }
        }
    }
}
