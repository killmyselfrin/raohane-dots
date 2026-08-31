import QtQuick

// Raohane-owned Material Symbols wrapper with a stable ligature API and the
// optical axes used by the polished interaction system.
Text {
    id: root

    property real iconSize: 16
    property real fill: 0
    property real symbolWeight: 420
    property real grade: 0
    property real opticalSize: iconSize
    readonly property real resolvedFill: Math.max(0, Math.min(1, fill))
    readonly property bool textualLyrics: root.text === "lyrics" && root.iconSize <= 20

    renderType: Text.NativeRendering
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    font {
        family: root.textualLyrics ? "sans-serif" : "Material Symbols Rounded"
        pixelSize: root.textualLyrics ? 8 : root.iconSize
        weight: root.textualLyrics ? Font.DemiBold : Font.Normal
        capitalization: root.textualLyrics ? Font.AllUppercase : Font.MixedCase
        letterSpacing: root.textualLyrics ? 0.35 : 0
        hintingPreference: Font.PreferNoHinting
        variableAxes: root.textualLyrics ? ({}) : {
            "FILL": root.resolvedFill,
            "wght": Math.max(100, Math.min(700, root.symbolWeight)),
            "GRAD": Math.max(-50, Math.min(200, root.grade)),
            "opsz": Math.max(20, Math.min(48, root.opticalSize)),
        }
    }
}
