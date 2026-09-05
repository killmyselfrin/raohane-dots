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

    implicitHeight: vertical ? 236 : 94
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
        width: 170
        height: 170
        radius: 85
        color: RaohaneTheme.accentSoft
        opacity: 0.28
    }

    Item {
        anchors.fill: parent
        anchors.margins: 12

        RaohaneSurface {
            id: horizontalBar
            visible: !root.vertical
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            height: 50
            surfaceRadius: 16
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

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
            width: 62
            anchors {
                top: parent.top
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            surfaceRadius: 18
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                spacing: 6

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
            spacing: 4

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
            spacing: 3

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

        width: separator ? (verticalPreview ? 24 : 8) : 26
        height: separator ? (verticalPreview ? 6 : 24) : 26

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
            surfaceRadius: 9
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
