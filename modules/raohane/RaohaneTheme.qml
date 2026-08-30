pragma Singleton

import QtQuick

QtObject {
    // Raohane cyber-noir design system.
    // The old token names stay stable so every native surface inherits the
    // redesign without adding a compatibility layer.

    // Background / glass hierarchy.
    readonly property color background: "#080610"
    readonly property color backgroundElevated: "#0d0916"
    readonly property color surface: "#dc120e1c"
    readonly property color surfaceRaised: "#ee171224"
    readonly property color surfaceDeep: "#f20d0a15"
    readonly property color surfaceSubtle: "#8f1a1429"
    readonly property color surfaceHover: "#2fc777ff"
    readonly property color surfacePressed: "#42d06fff"

    readonly property color glass: surface
    readonly property color glassStrong: surfaceRaised
    readonly property color glassDeep: surfaceDeep

    // Hairlines deliberately carry a small amount of violet so glass panels
    // feel related even when the wallpaper is very dark.
    readonly property color border: "#2ebf92ee"
    readonly property color borderStrong: "#66d7a7ff"
    readonly property color borderFaint: "#19d9c5ff"
    readonly property color highlight: "#36ffffff"

    // Text.
    readonly property color text: "#f7f1ff"
    readonly property color textMuted: "#b6a9c9"
    readonly property color textFaint: "#786d8e"

    // Signature neon spectrum. Violet remains the primary interaction color;
    // magenta and cool blue are reserved for depth and contextual accents.
    readonly property color accent: "#c56cff"
    readonly property color accentSecondary: "#ee6dff"
    readonly property color accentBlue: "#6f9dff"
    readonly property color accentSoft: "#31c56cff"
    readonly property color accentHover: "#49c56cff"
    readonly property color accentPressed: "#60c56cff"
    readonly property color accentGlow: "#7fc56cff"
    readonly property color accentBorder: "#78d7a7ff"

    // Semantic states.
    readonly property color success: "#66e3b4"
    readonly property color warning: "#f4c76b"
    readonly property color critical: "#ff6f91"
    readonly property color info: "#78a8ff"

    // Geometry. These values intentionally bias toward floating, generous
    // surfaces rather than compact utility bars.
    readonly property int barHeight: 44
    readonly property int islandHeight: 46
    readonly property int radiusTiny: 8
    readonly property int radiusSmall: 11
    readonly property int radius: 16
    readonly property int radiusLarge: 24
    readonly property int radiusHero: 28

    // Shared rhythm.
    readonly property int spacingTiny: 4
    readonly property int spacingSmall: 8
    readonly property int spacing: 12
    readonly property int spacingLarge: 18
    readonly property int panelPadding: 16

    // Motion.
    readonly property int animationFast: 140
    readonly property int animationDuration: 220
    readonly property int animationSlow: 280
}
