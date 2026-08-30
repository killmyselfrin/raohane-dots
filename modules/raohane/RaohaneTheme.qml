pragma Singleton

import QtQuick
import qs.modules.raohane.config

QtObject {
    id: root

    // Raohane keeps one stable token API while allowing the visual mood to be
    // selected from Settings. Layout/behavior does not change with a preset;
    // only the shared surface, text and accent hierarchy changes.
    readonly property var presets: [
        {
            id: "zen-mist",
            name: qsTr("Zen Mist"),
            description: qsTr("Warm ivory glass and charcoal details"),
            tone: qsTr("Light"),
            dark: false,
            background: "#ece9e3",
            backgroundElevated: "#f5f2ed",
            surface: "#d9f6f2ec",
            surfaceRaised: "#eefaf7f2",
            surfaceDeep: "#f2e6e2dc",
            surfaceSubtle: "#8fffffff",
            surfaceHover: "#e6ece8e1",
            surfacePressed: "#eedfdad2",
            border: "#242c2a27",
            borderStrong: "#44302e2a",
            borderFaint: "#142c2a27",
            highlight: "#b8ffffff",
            text: "#272623",
            textMuted: "#706c65",
            textFaint: "#9a958d",
            accent: "#343331",
            accentSecondary: "#716b63",
            accentBlue: "#6c7b84",
            success: "#667869",
            warning: "#9a7b50",
            critical: "#a26161",
            info: "#697d89"
        },
        {
            id: "paper",
            name: qsTr("Paper"),
            description: qsTr("Neutral white with crisp ink contrast"),
            tone: qsTr("Light"),
            dark: false,
            background: "#f0f0ee",
            backgroundElevated: "#f8f8f6",
            surface: "#ddfbfbf8",
            surfaceRaised: "#f2ffffff",
            surfaceDeep: "#f3e8e8e4",
            surfaceSubtle: "#96ffffff",
            surfaceHover: "#e8eeeeeb",
            surfacePressed: "#efdcdcd8",
            border: "#211a1a19",
            borderStrong: "#421a1a19",
            borderFaint: "#121a1a19",
            highlight: "#c8ffffff",
            text: "#191918",
            textMuted: "#666663",
            textFaint: "#92928e",
            accent: "#1f1f1e",
            accentSecondary: "#62625f",
            accentBlue: "#66737c",
            success: "#5f7464",
            warning: "#96794d",
            critical: "#9b5e5e",
            info: "#647984"
        },
        {
            id: "sakura",
            name: qsTr("Sakura"),
            description: qsTr("Soft blush glass with muted rose accents"),
            tone: qsTr("Warm"),
            dark: false,
            background: "#eee7e6",
            backgroundElevated: "#f6f0ef",
            surface: "#dcf8f1f0",
            surfaceRaised: "#effcf7f5",
            surfaceDeep: "#f1e8dfdf",
            surfaceSubtle: "#91fffafa",
            surfaceHover: "#e9eee2e2",
            surfacePressed: "#efdccfd0",
            border: "#2a5c4b4d",
            borderStrong: "#496c5659",
            borderFaint: "#185c4b4d",
            highlight: "#c0ffffff",
            text: "#302829",
            textMuted: "#796d6e",
            textFaint: "#a09697",
            accent: "#8b666b",
            accentSecondary: "#a98585",
            accentBlue: "#79838b",
            success: "#6c7b6d",
            warning: "#9b7b58",
            critical: "#a55e68",
            info: "#74818b"
        },
        {
            id: "matcha",
            name: qsTr("Matcha"),
            description: qsTr("Quiet sage tones inspired by tea rooms"),
            tone: qsTr("Natural"),
            dark: false,
            background: "#e9ece6",
            backgroundElevated: "#f1f4ef",
            surface: "#dcf4f6f1",
            surfaceRaised: "#effafbf7",
            surfaceDeep: "#f1e1e6df",
            surfaceSubtle: "#90f8fff7",
            surfaceHover: "#e8e6ece4",
            surfacePressed: "#eed4ddd2",
            border: "#29475046",
            borderStrong: "#47525e51",
            borderFaint: "#17475046",
            highlight: "#bdffffff",
            text: "#293029",
            textMuted: "#687167",
            textFaint: "#929a91",
            accent: "#647263",
            accentSecondary: "#82907c",
            accentBlue: "#6e7c80",
            success: "#5d7663",
            warning: "#927a50",
            critical: "#9b6261",
            info: "#667b82"
        },
        {
            id: "slate",
            name: qsTr("Slate"),
            description: qsTr("Cool mist with restrained blue-gray accents"),
            tone: qsTr("Cool"),
            dark: false,
            background: "#e7eaec",
            backgroundElevated: "#f0f3f4",
            surface: "#dcf5f7f8",
            surfaceRaised: "#effcfdfe",
            surfaceDeep: "#f1dfe4e7",
            surfaceSubtle: "#90f8fbff",
            surfaceHover: "#e8e3e8eb",
            surfacePressed: "#eed0d8dd",
            border: "#29404a50",
            borderStrong: "#48515d64",
            borderFaint: "#17404a50",
            highlight: "#bdffffff",
            text: "#252b2f",
            textMuted: "#657078",
            textFaint: "#9099a0",
            accent: "#5d6d78",
            accentSecondary: "#7b8790",
            accentBlue: "#647f90",
            success: "#61786b",
            warning: "#957a51",
            critical: "#9d6266",
            info: "#5f7989"
        },
        {
            id: "sand",
            name: qsTr("Sand"),
            description: qsTr("Warm stone, linen and quiet earthy contrast"),
            tone: qsTr("Warm"),
            dark: false,
            background: "#eee9df",
            backgroundElevated: "#f6f1e8",
            surface: "#dcfaf6ee",
            surfaceRaised: "#effffbf3",
            surfaceDeep: "#f1e7dfd2",
            surfaceSubtle: "#90fffaf0",
            surfaceHover: "#e9eee8dd",
            surfacePressed: "#efded4c5",
            border: "#2956493b",
            borderStrong: "#48665748",
            borderFaint: "#1756493b",
            highlight: "#c0ffffff",
            text: "#312c25",
            textMuted: "#776e62",
            textFaint: "#9d9589",
            accent: "#776956",
            accentSecondary: "#93826c",
            accentBlue: "#748087",
            success: "#677765",
            warning: "#947546",
            critical: "#9e625e",
            info: "#697a82"
        },
        {
            id: "sumi",
            name: qsTr("Sumi"),
            description: qsTr("Ink-black glass with warm paper text"),
            tone: qsTr("Dark"),
            dark: true,
            background: "#101110",
            backgroundElevated: "#171817",
            surface: "#dc1b1c1a",
            surfaceRaised: "#ee222320",
            surfaceDeep: "#f20c0d0c",
            surfaceSubtle: "#8f292a27",
            surfaceHover: "#df2d2e2b",
            surfacePressed: "#e8383935",
            border: "#2efffff7",
            borderStrong: "#50fffdf5",
            borderFaint: "#18fffdf5",
            highlight: "#36ffffff",
            text: "#eeeae2",
            textMuted: "#aaa69e",
            textFaint: "#77746e",
            accent: "#d8d3ca",
            accentSecondary: "#aba59b",
            accentBlue: "#a5b1b6",
            success: "#86a08b",
            warning: "#b59a6d",
            critical: "#bd7777",
            info: "#8fa7b2"
        },
        {
            id: "midnight",
            name: qsTr("Midnight"),
            description: qsTr("Cool charcoal glass for low-light sessions"),
            tone: qsTr("Dark"),
            dark: true,
            background: "#0f1215",
            backgroundElevated: "#15191d",
            surface: "#dc191e23",
            surfaceRaised: "#ee20262c",
            surfaceDeep: "#f20b0e11",
            surfaceSubtle: "#8f273039",
            surfaceHover: "#df2a333c",
            surfacePressed: "#e836424d",
            border: "#2ed7e2e8",
            borderStrong: "#50dce7ed",
            borderFaint: "#18d7e2e8",
            highlight: "#34ffffff",
            text: "#edf1f3",
            textMuted: "#a8b0b5",
            textFaint: "#737d84",
            accent: "#bdc9cf",
            accentSecondary: "#9eabb2",
            accentBlue: "#91aab8",
            success: "#7d9986",
            warning: "#b3986b",
            critical: "#bb777c",
            info: "#87a3b2"
        }
    ]

    function presetFor(id): var {
        const match = root.presets.find(item => item.id === String(id ?? ""))
        return match ?? root.presets[0]
    }

    readonly property var activePreset: presetFor(RaohaneConfig.themePreset)
    readonly property bool dark: Boolean(activePreset.dark)
    readonly property string presetName: String(activePreset.name)

    // Background / glass hierarchy.
    readonly property color background: activePreset.background
    readonly property color backgroundElevated: activePreset.backgroundElevated
    readonly property color surface: activePreset.surface
    readonly property color surfaceRaised: activePreset.surfaceRaised
    readonly property color surfaceDeep: activePreset.surfaceDeep
    readonly property color surfaceSubtle: activePreset.surfaceSubtle
    readonly property color surfaceHover: activePreset.surfaceHover
    readonly property color surfacePressed: activePreset.surfacePressed

    readonly property color glass: surface
    readonly property color glassStrong: surfaceRaised
    readonly property color glassDeep: surfaceDeep

    readonly property color border: activePreset.border
    readonly property color borderStrong: activePreset.borderStrong
    readonly property color borderFaint: activePreset.borderFaint
    readonly property color highlight: activePreset.highlight

    // Text hierarchy.
    readonly property color text: activePreset.text
    readonly property color textMuted: activePreset.textMuted
    readonly property color textFaint: activePreset.textFaint

    // Accent hierarchy. The same names remain available to every existing
    // surface, but presets decide whether the accent is charcoal, rose, sage,
    // slate or a dark-mode neutral.
    readonly property color accent: activePreset.accent
    readonly property color accentSecondary: activePreset.accentSecondary
    readonly property color accentBlue: activePreset.accentBlue
    readonly property color accentSoft: Qt.rgba(accent.r, accent.g, accent.b, dark ? 0.18 : 0.11)
    readonly property color accentHover: Qt.rgba(accent.r, accent.g, accent.b, dark ? 0.25 : 0.16)
    readonly property color accentPressed: Qt.rgba(accent.r, accent.g, accent.b, dark ? 0.34 : 0.23)
    readonly property color accentGlow: Qt.rgba(accent.r, accent.g, accent.b, dark ? 0.40 : 0.24)
    readonly property color accentBorder: Qt.rgba(accent.r, accent.g, accent.b, dark ? 0.62 : 0.46)

    // Semantic states.
    readonly property color success: activePreset.success
    readonly property color warning: activePreset.warning
    readonly property color critical: activePreset.critical
    readonly property color info: activePreset.info

    // Geometry deliberately remains stable across presets: changing the theme
    // changes style, never the shell's information architecture.
    readonly property int barHeight: 44
    readonly property int islandHeight: 46
    readonly property int radiusTiny: 8
    readonly property int radiusSmall: 11
    readonly property int radius: 16
    readonly property int radiusLarge: 24
    readonly property int radiusHero: 28

    readonly property int spacingTiny: 4
    readonly property int spacingSmall: 8
    readonly property int spacing: 12
    readonly property int spacingLarge: 18
    readonly property int panelPadding: 16

    // Minimal motion: short, quiet and consistent.
    readonly property int animationFast: 110
    readonly property int animationDuration: 170
    readonly property int animationSlow: 220
}
