pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    implicitHeight: shellColumn.implicitHeight

    ColumnLayout {
        id: shellColumn
        width: parent.width
        spacing: 12

        RaohaneSurface {
            Layout.fillWidth: true
            implicitHeight: previewColumn.implicitHeight + 24
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: false
            showSheen: false
            showInnerRim: false
            idleColor: RaohaneTheme.surfaceSubtle
            idleBorderColor: "transparent"

            ColumnLayout {
                id: previewColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 12
                }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9

                    RaohaneIcon {
                        text: "preview"
                        iconSize: 17
                        fill: 0.8
                        color: RaohaneTheme.accent
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: qsTr("Live preview")
                            color: RaohaneTheme.text
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Bar and dock changes appear here instantly.")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            elide: Text.ElideRight
                        }
                    }
                }

                RaohaneBarPreview {
                    Layout.fillWidth: true
                    orientation: editor.orientation
                }

                RaohaneDivider {
                    Layout.fillWidth: true
                    height: 1
                    color: RaohaneTheme.borderFaint
                    opacity: 0.55
                }

                RaohaneDockPreview {
                    Layout.fillWidth: true
                }
            }
        }

        RaohaneBarStudio {
            id: editor
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
        }
    }
}
