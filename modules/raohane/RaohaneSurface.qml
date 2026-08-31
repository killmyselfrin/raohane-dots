import QtQuick

Rectangle {
    id: root

    property bool raised: false
    property bool active: false
    property bool hovered: false
    property bool pressed: false
    property bool interactive: false
    property int surfaceRadius: RaohaneTheme.radius
    property bool showSheen: true
    property real hoverScale: RaohaneMotion.subtleHoverScale
    property real pressedScale: RaohaneMotion.softPressScale

    radius: surfaceRadius
    scale: interactive
        ? (pressed ? pressedScale : hovered ? hoverScale : 1)
        : 1
    color: pressed
        ? RaohaneTheme.surfacePressed
        : active
            ? RaohaneTheme.accentSoft
            : hovered
                ? RaohaneTheme.surfaceHover
                : raised
                    ? RaohaneTheme.surfaceRaised
                    : RaohaneTheme.surface
    border.width: 1
    border.color: active
        ? RaohaneTheme.accentBorder
        : hovered || pressed
            ? RaohaneTheme.borderStrong
            : RaohaneTheme.border

    Rectangle {
        visible: root.showSheen && RaohaneTheme.sheenEnabled
        z: 100
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: root.surfaceRadius
            rightMargin: root.surfaceRadius
        }
        height: 1
        color: root.active ? RaohaneTheme.accentGlow : RaohaneTheme.highlight
        opacity: root.pressed ? 0.05 : root.active ? 0.28 : root.hovered ? 0.18 : 0.10

        Behavior on opacity {
            NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
        }
    }

    Behavior on color {
        ColorAnimation { duration: RaohaneMotion.micro }
    }
    Behavior on border.color {
        ColorAnimation { duration: RaohaneMotion.micro }
    }
    Behavior on scale {
        NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeEmphasized }
    }
}
