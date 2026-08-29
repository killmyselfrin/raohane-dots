import QtQuick

Rectangle {
    id: root

    property bool raised: false
    property bool active: false
    property bool hovered: false
    property int surfaceRadius: RaohaneTheme.radius

    radius: surfaceRadius
    color: active
        ? RaohaneTheme.accentSoft
        : hovered
            ? RaohaneTheme.surfaceHover
            : raised
                ? RaohaneTheme.surfaceRaised
                : RaohaneTheme.surface
    border.width: 1
    border.color: active ? RaohaneTheme.borderStrong : RaohaneTheme.border

    Behavior on color { ColorAnimation { duration: RaohaneTheme.animationDuration } }
    Behavior on border.color { ColorAnimation { duration: RaohaneTheme.animationDuration } }
}
