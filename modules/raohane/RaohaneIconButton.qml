import QtQuick

RaohaneSurface {
    id: root

    required property string icon
    property int buttonSize: 30
    property int iconSize: 17
    property bool emphasized: false
    property bool filledWhenActive: true
    signal clicked()

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    surfaceRadius: Math.round(buttonSize / 3)
    active: emphasized
    hovered: pointer.containsMouse || activeFocus
    pressed: pointer.pressed
    interactive: true
    hoverScale: RaohaneMotion.hoverScale
    pressedScale: RaohaneMotion.pressScale
    activeFocusOnTab: enabled
    opacity: enabled ? 1 : RaohaneMotion.disabledOpacity

    RaohaneIcon {
        anchors.centerIn: parent
        text: root.icon
        iconSize: root.iconSize
        fill: root.filledWhenActive
            ? (root.emphasized ? 1 : pointer.pressed ? 0.70 : pointer.containsMouse || root.activeFocus ? 0.32 : 0)
            : 0
        symbolWeight: root.emphasized ? 560 : pointer.pressed ? 540 : pointer.containsMouse || root.activeFocus ? 500 : 430
        grade: root.emphasized ? 40 : pointer.containsMouse || root.activeFocus ? 20 : 0
        color: root.emphasized || pointer.containsMouse || root.activeFocus
            ? RaohaneTheme.accent
            : RaohaneTheme.textMuted
        scale: root.transformMotionAllowed && pointer.pressed ? 0.92 : 1

        Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
        Behavior on scale {
            enabled: root.transformMotionAllowed
            NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: root.forceActiveFocus()
        onClicked: root.clicked()
    }

    Keys.onPressed: event => {
        if (!root.enabled)
            return
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.clicked()
            event.accepted = true
        }
    }

    Behavior on opacity {
        NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
    }
}
