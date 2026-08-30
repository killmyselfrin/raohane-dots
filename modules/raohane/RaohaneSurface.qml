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

    // Minimal glass highlight: enough to separate a floating surface from the
    // wallpaper without bringing back the previous neon/shader-heavy look.
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
        opacity: root.active ? 0.28 : root.hovered ? 0.18 : 0.10
    }

    Behavior on color {
        ColorAnimation { duration: RaohaneTheme.animationDuration }
    }
    Behavior on border.color {
        ColorAnimation { duration: RaohaneTheme.animationDuration }
    }
}
