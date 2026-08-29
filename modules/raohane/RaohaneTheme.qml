pragma Singleton

import QtQuick

QtObject {
    // Ink-first palette: neutral surfaces with one restrained violet accent.
    // Existing token names are kept so older native surfaces inherit the new
    // visual system without compatibility shims.
    readonly property color background: "#0d0d12"
    readonly property color surface: "#e814141b"
    readonly property color surfaceRaised: "#f2191921"
    readonly property color surfaceHover: "#20ffffff"
    readonly property color surfacePressed: "#2bffffff"

    readonly property color glass: surface
    readonly property color glassStrong: surfaceRaised
    readonly property color border: "#20ffffff"
    readonly property color borderStrong: "#35ffffff"

    readonly property color text: "#f4f1f8"
    readonly property color textMuted: "#9893a2"
    readonly property color textFaint: "#6f6a76"

    readonly property color accent: "#b88cff"
    readonly property color accentSoft: "#22b88cff"
    readonly property color accentHover: "#35b88cff"
    readonly property color critical: "#ff6b82"

    readonly property int barHeight: 40
    readonly property int islandHeight: 42
    readonly property int radiusSmall: 9
    readonly property int radius: 14
    readonly property int radiusLarge: 20
    readonly property int animationDuration: 180
}
