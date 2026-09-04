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
        const source = String(root.iconSource ?? "").trim()
        if (!source.length)
            return ""
        if (source.startsWith("image://")
                || source.startsWith("file:")
                || source.startsWith("qrc:")
                || source.startsWith("/") )
            return source
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
