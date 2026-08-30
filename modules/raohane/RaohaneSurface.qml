import QtQuick

Rectangle {
    id: root

    property bool raised: false
    property bool active: false
    property bool hovered: false
    property int surfaceRadius: RaohaneTheme.radius
    property bool showSheen: true

    radius: surfaceRadius
    color: active
        ? RaohaneTheme.accentSoft
        : hovered
            ? RaohaneTheme.surfaceHover
            : raised
                ? RaohaneTheme.surfaceRaised
                : RaohaneTheme.surface
    border.width: 1
    border.color: active
        ? RaohaneTheme.accentBorder
        : hovered
            ? RaohaneTheme.borderStrong
            : RaohaneTheme.border

    // A restrained top highlight makes every panel read as the same piece of
    // glass without requiring expensive blur/shadow effects per component.
    Rectangle {
        visible: root.showSheen
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
        opacity: root.active ? 0.52 : root.hovered ? 0.34 : 0.18
    }

    Behavior on color {
        ColorAnimation { duration: RaohaneTheme.animationDuration }
    }
    Behavior on border.color {
        ColorAnimation { duration: RaohaneTheme.animationDuration }
    }
}
