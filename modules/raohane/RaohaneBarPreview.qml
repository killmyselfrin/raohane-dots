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

    implicitHeight: vertical ? 250 : 124
    surfaceRadius: RaohaneTheme.radiusLarge
    raised: false
    transparentIdle: true
    showSheen: false
    showInnerRim: false
    border.color: "transparent"
    clip: true

    Item {
        anchors.fill: parent
        anchors.margins: 14

        RaohaneSurface {
            id: horizontalBar
            visible: !root.vertical
            anchors {
                left: parent.left
                right: parent.right
                top: !RaohaneConfig.barBottom ? parent.top : undefined
                bottom: RaohaneConfig.barBottom ? parent.bottom : undefined
                topMargin: RaohaneConfig.barBottom ? 0 : 10
                bottomMargin: RaohaneConfig.barBottom ? 10 : 0
            }
            height: Math.max(42, Math.min(64, RaohaneConfig.barHeight + 10))
            surfaceRadius: Math.max(0, Math.min(RaohaneConfig.barRadius, height / 2))
            opacity: RaohaneConfig.barOpacity
            raised: RaohaneConfig.barShadow
            transparentIdle: !RaohaneConfig.barShowBackground
                || RaohaneConfig.barGroupStyle !== "pills"
            showSheen: false
            border.color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: Math.max(2, RaohaneConfig.barModuleSpacing + 4)

                PreviewZone {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    items: root.layout.left ?? []
                    alignment: Qt.AlignLeft
                }

                PreviewZone {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    items: root.layout.center ?? []
                    alignment: Qt.AlignHCenter
                }

                PreviewZone {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    items: root.layout.right ?? []
                    alignment: Qt.AlignRight
                }
            }
        }

        RaohaneSurface {
            id: verticalBar
            visible: root.vertical
            width: 68
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: !RaohaneConfig.barRight ? parent.left : undefined
                right: RaohaneConfig.barRight ? parent.right : undefined
                leftMargin: RaohaneConfig.barRight ? 0 : 12
                rightMargin: RaohaneConfig.barRight ? 12 : 0
            }
            surfaceRadius: Math.max(0, Math.min(RaohaneConfig.barRadius, width / 2))
            opacity: RaohaneConfig.barOpacity
            raised: RaohaneConfig.barShadow
            transparentIdle: !RaohaneConfig.barShowBackground
                || RaohaneConfig.barGroupStyle !== "pills"
            showSheen: false
            border.color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 10
                anchors.bottomMargin: 10
                spacing: Math.max(2, RaohaneConfig.barModuleSpacing + 2)

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

    component PreviewZone: Item {
        id: zone

        required property var items
        property int alignment: Qt.AlignLeft

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: zone.alignment === Qt.AlignLeft ? parent.left : undefined
            anchors.right: zone.alignment === Qt.AlignRight ? parent.right : undefined
            anchors.horizontalCenter: zone.alignment === Qt.AlignHCenter ? parent.horizontalCenter : undefined
            spacing: 5

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
            spacing: 4

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

        width: separator
            ? (verticalPreview ? 26 : (RaohaneConfig.barDividerStyle === "space" ? Math.max(9, RaohaneConfig.barDividerSpacing) : 9))
            : 30
        height: separator
            ? (verticalPreview ? (RaohaneConfig.barDividerStyle === "space" ? Math.max(7, RaohaneConfig.barDividerSpacing) : 7) : 26)
            : 30

        Rectangle {
            visible: glyph.separator && RaohaneConfig.barDividerStyle !== "space"
            anchors.centerIn: parent
            width: RaohaneConfig.barDividerStyle === "dot"
                ? 5
                : glyph.verticalPreview ? 22 : 1
            height: RaohaneConfig.barDividerStyle === "dot"
                ? 5
                : glyph.verticalPreview ? 1 : 22
            radius: Math.max(1, Math.min(width, height) / 2)
            color: RaohaneTheme.borderStrong
            opacity: 0.66
        }

        RaohaneSurface {
            visible: !glyph.separator
            anchors.fill: parent
            surfaceRadius: RaohaneConfig.barGroupStyle === "segmented" ? 6 : 10
            raised: RaohaneConfig.barGroupStyle === "separated" && RaohaneConfig.barShadow
            transparentIdle: RaohaneConfig.barGroupStyle === "transparent"
            showSheen: false
            border.color: "transparent"
            color: glyph.moduleId === "context"
                ? RaohaneTheme.accentSoft
                : RaohaneTheme.surfaceSubtle

            RaohaneIcon {
                anchors.centerIn: parent
                text: glyph.definition?.icon ?? "widgets"
                iconSize: 14
                fill: glyph.moduleId === "context" ? 1 : 0
                symbolWeight: glyph.moduleId === "context" ? 540 : 430
                color: glyph.moduleId === "context"
                    ? RaohaneTheme.accent
                    : RaohaneTheme.textMuted
            }
        }
    }
}
