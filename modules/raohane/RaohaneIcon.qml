import QtQuick

// Raohane-owned Material Symbols wrapper. Keep native surfaces independent
// from modules/common/widgets while retaining the standard ligature API.
Text {
    id: root

    property real iconSize: 16
    property real fill: 0
    readonly property real resolvedFill: fill >= 0.5 ? 1.0 : 0.0

    implicitWidth: Math.max(iconSize, contentWidth)
    implicitHeight: Math.max(iconSize, contentHeight)

    renderType: Text.NativeRendering
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    font {
        family: "Material Symbols Rounded"
        pixelSize: root.iconSize
        weight: root.resolvedFill > 0.5 ? Font.DemiBold : Font.Normal
        hintingPreference: Font.PreferNoHinting
        variableAxes: {
            "FILL": root.resolvedFill,
            "opsz": root.iconSize,
        }
    }
}
