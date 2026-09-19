pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

RaohaneSurface {
    id: root

    property string orientation: RaohaneConfig.barVertical ? "vertical" : "horizontal"

    readonly property bool vertical: orientation === "vertical"
    readonly property var sourceLayout: vertical
        ? RaohaneConfig.barVerticalModuleLayout
        : RaohaneConfig.barModuleLayout
    readonly property var layout: RaohaneBarModuleRegistry.sanitizeLayout(sourceLayout, orientation)
    readonly property string barStyle: RaohaneConfig.sanitizeBarStyle(RaohaneConfig.barStyle)
    readonly property bool floatingStyle: barStyle === "floating"
    readonly property bool unifiedStyle: barStyle === "unified"
    readonly property bool minimalStyle: barStyle === "minimal"
    readonly property int previewThickness: Math.max(root.vertical ? 38 : 34, Math.min(58, RaohaneConfig.barThickness))
    readonly property int previewRadius: Math.max(0, Math.min(RaohaneConfig.barRadius, previewThickness / 2))
    readonly property int previewSpacing: Math.max(0, Math.min(14, RaohaneConfig.barModuleSpacing))
    readonly property int previewEdgeMargin: Math.max(0, Math.min(32, RaohaneConfig.barEdgeMargin))
    readonly property int previewOuterMargin: Math.max(0, Math.min(18, RaohaneConfig.barOuterMargin))
    readonly property color previewSurface: root.withOpacity(RaohaneTheme.surfaceRaised, RaohaneConfig.barBackgroundOpacity)
    readonly property color previewBorder: root.withOpacity(RaohaneTheme.borderStrong, RaohaneConfig.barBorderOpacity)

    function withOpacity(base, opacity): color {
        const factor = Math.max(0, Math.min(1, Number(opacity)))
        return Qt.rgba(base.r, base.g, base.b, base.a * factor)
    }

    implicitHeight: vertical ? 268 : 122
    surfaceRadius: RaohaneTheme.radiusLarge
    raised: false
    showSheen: false
    border.color: RaohaneTheme.borderStrong
    clip: true

    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: -72
            rightMargin: -44
        }
        width: 176
        height: 176
        radius: 88
        color: RaohaneTheme.accentSoft
        opacity: 0.28
    }

    Item {
        id: previewArea
        anchors.fill: parent
        anchors.margins: 14

        Item {
            id: horizontalHost
            visible: !root.vertical
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: root.previewEdgeMargin
                rightMargin: root.previewEdgeMargin
            }
            height: root.previewThickness

            RaohaneSurface {
                visible: root.unifiedStyle
                anchors.fill: parent
                surfaceRadius: root.previewRadius
                raised: true
                showSheen: false
                idleColor: root.previewSurface
                idleBorderColor: root.previewBorder
            }

            RowLayout {
                anchors.fill: parent
                spacing: root.floatingStyle ? 8 : 2

                PreviewZone {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: items.length > 0
                    items: root.layout.left ?? []
                    alignment: Qt.AlignLeft
                    framed: root.floatingStyle
                }

                PreviewZone {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: items.length > 0
                    items: root.layout.center ?? []
                    alignment: Qt.AlignHCenter
                    framed: root.floatingStyle
                }

                PreviewZone {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: items.length > 0
                    items: root.layout.right ?? []
                    alignment: Qt.AlignRight
                    framed: root.floatingStyle
                }
            }
        }

        Item {
            id: verticalHost
            visible: root.vertical
            width: root.previewThickness
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: RaohaneConfig.barVerticalRight ? undefined : parent.left
                right: RaohaneConfig.barVerticalRight ? parent.right : undefined
                leftMargin: root.previewOuterMargin
                rightMargin: root.previewOuterMargin
                topMargin: root.previewOuterMargin
                bottomMargin: root.previewOuterMargin
            }

            RaohaneSurface {
                visible: !root.minimalStyle
                anchors.fill: parent
                surfaceRadius: root.previewRadius
                raised: true
                showSheen: false
                idleColor: root.previewSurface
                idleBorderColor: root.previewBorder
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 5
                }
                spacing: root.previewSpacing

                VerticalPreviewZone {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    items: root.layout.left ?? []
                    alignment: Qt.AlignTop
                }

                VerticalPreviewZone {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    items: root.layout.center ?? []
                    alignment: Qt.AlignVCenter
                }

                VerticalPreviewZone {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    items: root.layout.right ?? []
                    alignment: Qt.AlignBottom
                }
            }
        }
    }

    component PreviewZone: RaohaneSurface {
        id: zone

        required property var items
        property int alignment: Qt.AlignLeft
        property bool framed: false

        surfaceRadius: root.previewRadius
        raised: framed
        transparentIdle: !framed
        showInnerRim: framed
        showSheen: false
        idleColor: root.previewSurface
        idleBorderColor: root.previewBorder

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: zone.alignment === Qt.AlignLeft ? parent.left : undefined
            anchors.right: zone.alignment === Qt.AlignRight ? parent.right : undefined
            anchors.horizontalCenter: zone.alignment === Qt.AlignHCenter ? parent.horizontalCenter : undefined
            anchors.leftMargin: zone.framed ? 6 : 2
            anchors.rightMargin: zone.framed ? 6 : 2
            spacing: root.previewSpacing

            Repeater {
                model: zone.items

                delegate: ModuleGlyph {
                    required property var modelData
                    moduleId: String(modelData)
                    verticalPreview: false
                }
            }
        }
    }

    component VerticalPreviewZone: Item {
        id: zone

        required property var items
        property int alignment: Qt.AlignTop

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: zone.alignment === Qt.AlignTop ? parent.top : undefined
            anchors.bottom: zone.alignment === Qt.AlignBottom ? parent.bottom : undefined
            anchors.verticalCenter: zone.alignment === Qt.AlignVCenter ? parent.verticalCenter : undefined
            spacing: root.previewSpacing

            Repeater {
                model: zone.items

                delegate: ModuleGlyph {
                    required property var modelData
                    moduleId: String(modelData)
                    verticalPreview: true
                }
            }
        }
    }

    component ModuleGlyph: Item {
        id: glyph

        required property string moduleId
        property bool verticalPreview: false
        readonly property bool separator: moduleId === "separator"
        readonly property var definition: RaohaneBarModuleRegistry.definition(moduleId)

        width: separator ? (verticalPreview ? 24 : 8) : 28
        height: separator ? (verticalPreview ? 7 : 24) : 28

        Rectangle {
            visible: glyph.separator
            anchors.centerIn: parent
            width: glyph.verticalPreview ? 20 : 1
            height: glyph.verticalPreview ? 1 : 20
            radius: 1
            color: RaohaneTheme.borderStrong
            opacity: 0.66
        }

        RaohaneSurface {
            visible: !glyph.separator
            anchors.fill: parent
            surfaceRadius: Math.min(9, root.previewRadius)
            raised: false
            showSheen: false
            border.color: glyph.moduleId === "context"
                ? RaohaneTheme.accentBorder
                : RaohaneTheme.borderFaint
            color: glyph.moduleId === "context"
                ? RaohaneTheme.accentSoft
                : RaohaneTheme.surfaceSubtle

            RaohaneIcon {
                anchors.centerIn: parent
                text: glyph.definition?.icon ?? "widgets"
                iconSize: 13
                fill: glyph.moduleId === "context" ? 1 : 0
                symbolWeight: glyph.moduleId === "context" ? 540 : 430
                color: glyph.moduleId === "context"
                    ? RaohaneTheme.accent
                    : RaohaneTheme.textMuted
            }
        }
    }
}
