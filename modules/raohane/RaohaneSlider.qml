import QtQuick

FocusScope {
    id: root

    property real from: 0
    property real to: 1
    property real value: 0
    property real stepSize: 0.01
    property bool wheelEnabled: true
    property bool showHandle: true
    property int trackHeight: 5
    property int handleSize: 15
    signal moved(real value)

    readonly property real span: Math.max(0.000001, to - from)
    readonly property real normalizedValue: Math.max(0, Math.min(1, (value - from) / span))
    readonly property real shownRatio: pointer.pressed ? dragRatio : normalizedValue
    readonly property bool hovered: pointer.containsMouse
    property real dragRatio: normalizedValue

    implicitHeight: 26
    activeFocusOnTab: enabled
    opacity: enabled ? 1 : RaohaneMotion.disabledOpacity

    function clamp(valueToClamp: real): real {
        return Math.max(from, Math.min(to, valueToClamp))
    }

    function snapped(valueToSnap: real): real {
        const safe = clamp(valueToSnap)
        if (stepSize <= 0)
            return safe
        const steps = Math.round((safe - from) / stepSize)
        return clamp(from + steps * stepSize)
    }

    function valueForX(mouseX: real): real {
        if (width <= 0)
            return root.value
        return root.snapped(root.from + Math.max(0, Math.min(1, mouseX / width)) * root.span)
    }

    function applyX(mouseX: real): void {
        const next = root.valueForX(mouseX)
        root.dragRatio = Math.max(0, Math.min(1, (next - root.from) / root.span))
        root.moved(next)
    }

    function nudge(direction: int): void {
        const increment = stepSize > 0 ? stepSize : span / 100
        root.moved(root.snapped(root.value + increment * direction))
    }

    Behavior on opacity {
        NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
    }

    Rectangle {
        id: track
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        height: pointer.pressed ? root.trackHeight + 2 : root.hovered ? root.trackHeight + 1 : root.trackHeight
        radius: height / 2
        color: RaohaneTheme.surfaceDeep
        border.width: 1
        border.color: root.activeFocus || root.hovered ? RaohaneTheme.borderStrong : RaohaneTheme.border

        Behavior on height {
            NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
        }
        Behavior on border.color {
            ColorAnimation { duration: RaohaneMotion.micro }
        }

        Rectangle {
            width: Math.max(parent.height, Math.min(parent.width, root.shownRatio * parent.width))
            height: parent.height
            radius: parent.radius
            color: RaohaneTheme.accent

            Behavior on width {
                NumberAnimation {
                    duration: pointer.pressed ? 0 : RaohaneMotion.micro
                    easing.type: RaohaneMotion.easeStandard
                }
            }
        }
    }

    Rectangle {
        id: handle
        visible: root.showHandle
        width: root.handleSize
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(root.width - width, root.shownRatio * root.width - width / 2))
        scale: pointer.pressed ? 1.20 : root.hovered || root.activeFocus ? 1.10 : 1
        color: RaohaneTheme.surfaceRaised
        border.width: 2
        border.color: RaohaneTheme.accent

        Rectangle {
            anchors.centerIn: parent
            width: Math.max(3, parent.width * 0.28)
            height: width
            radius: width / 2
            color: RaohaneTheme.accent
            opacity: pointer.pressed ? 0.92 : root.hovered ? 0.62 : 0.36

            Behavior on opacity { NumberAnimation { duration: RaohaneMotion.micro } }
        }

        Behavior on x {
            NumberAnimation {
                duration: pointer.pressed ? 0 : RaohaneMotion.micro
                easing.type: RaohaneMotion.easeStandard
            }
        }
        Behavior on scale {
            NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeEmphasized }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        preventStealing: true
        acceptedButtons: Qt.LeftButton
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        onPressed: mouse => {
            root.forceActiveFocus()
            root.dragRatio = root.normalizedValue
            root.applyX(mouse.x)
        }
        onPositionChanged: mouse => {
            if (pressed)
                root.applyX(mouse.x)
        }
        onReleased: mouse => root.applyX(mouse.x)
        onWheel: wheel => {
            if (!root.wheelEnabled)
                return
            const direction = wheel.angleDelta.y >= 0 ? 1 : -1
            root.nudge(direction)
            wheel.accepted = true
        }
    }

    Keys.onPressed: event => {
        if (!root.enabled)
            return
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) {
            root.nudge(-1)
            event.accepted = true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Up) {
            root.nudge(1)
            event.accepted = true
        } else if (event.key === Qt.Key_Home) {
            root.moved(root.from)
            event.accepted = true
        } else if (event.key === Qt.Key_End) {
            root.moved(root.to)
            event.accepted = true
        }
    }
}
