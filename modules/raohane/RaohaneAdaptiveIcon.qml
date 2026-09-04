pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    property string iconSource: ""
    property int iconSize: 20
    property color fallbackColor: RaohaneTheme.textMuted
    property real imageScale: 1

    readonly property string fallbackSymbol: RaohaneIconResolver.materialSymbol(iconSource)
    readonly property bool useMaterialFallback: fallbackSymbol.length > 0 || iconSource.length === 0
    readonly property string systemSource: {
        let source = String(root.iconSource ?? "").trim()
        if (!source.length)
            return ""
        if (source.startsWith("image://")
                || source.startsWith("file:")
                || source.startsWith("qrc:")
                || source.startsWith("/") )
            return source

        // Some icon-provider values can come back as `name?fallback=...`.
        // Feeding that query back into iconPath nests provider fallbacks and
        // produces misleading missing-icon warnings. Resolve only the actual
        // freedesktop icon name here; generic names are handled by the
        // Material fallback above.
        const queryIndex = source.indexOf("?")
        if (queryIndex >= 0)
            source = source.slice(0, queryIndex)
        if (!source.length)
            return ""
        return Quickshell.iconPath(source, "application-x-executable")
    }

    implicitWidth: iconSize
    implicitHeight: iconSize

    Loader {
        anchors.fill: parent
        sourceComponent: root.useMaterialFallback ? materialIcon : systemIcon
    }

    Component {
        id: systemIcon

        IconImage {
            anchors.centerIn: parent
            implicitSize: root.iconSize
            source: root.systemSource
            scale: root.imageScale
        }
    }

    Component {
        id: materialIcon

        RaohaneIcon {
            anchors.centerIn: parent
            text: root.fallbackSymbol.length > 0 ? root.fallbackSymbol : "apps"
            iconSize: Math.max(14, Math.round(root.iconSize * 0.72))
            color: root.fallbackColor
            scale: root.imageScale
        }
    }
}
