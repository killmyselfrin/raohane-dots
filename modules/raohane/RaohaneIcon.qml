import QtQuick

// Raohane-owned Material Symbols wrapper with a stable ligature API for
// native shell surfaces.
Text {
    id: root

    property real iconSize: 16
    property real fill: 0
    readonly property real resolvedFill: fill >= 0.5 ? 1.0 : 0.0
    // The Material Symbols "lyrics" ligature can read like an ordinary music
    // note at small sizes. In compact controls render it as an explicit LYRICS
    // label so the player action is discoverable without hover/tooltips.
    readonly property bool textualLyrics: root.text === "lyrics" && root.iconSize <= 20

    renderType: Text.NativeRendering
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    font {
        family: root.textualLyrics ? "sans-serif" : "Material Symbols Rounded"
        pixelSize: root.textualLyrics ? 8 : root.iconSize
        weight: root.textualLyrics || root.resolvedFill > 0.5 ? Font.DemiBold : Font.Normal
        capitalization: root.textualLyrics ? Font.AllUppercase : Font.MixedCase
        letterSpacing: root.textualLyrics ? 0.35 : 0
        hintingPreference: Font.PreferNoHinting
        variableAxes: root.textualLyrics ? ({}) : {
            "FILL": root.resolvedFill,
            "opsz": root.iconSize,
        }
    }
}
