pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

RaohaneSurface {
    id: root

    readonly property var pinnedApps: Array.from(RaohaneConfig.dockPinnedApps ?? []).slice(0, 6)
    readonly property int previewIconSize: Math.max(22, Math.min(32, Math.round(RaohaneConfig.dockIconSize * 0.66)))

    implicitHeight: 104
    surfaceRadius: RaohaneTheme.radiusLarge
    raised: false
    showSheen: false
    border.color: RaohaneTheme.borderStrong
    clip: true

    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: -48
            topMargin: -58
        }
        width: 150
        height: 150
        radius: 75
        color: RaohaneTheme.accentSoft
        opacity: 0.24
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 14

        ColumnLayout {
            Layout.preferredWidth: 154
            spacing: 3

            RowLayout {
                spacing: 8

                RaohaneIcon {
                    text: "dock_to_bottom"
                    iconSize: 17
                    fill: RaohaneConfig.dockEnabled ? 1 : 0
                    color: RaohaneConfig.dockEnabled ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }

                Text {
                    text: qsTr("Dock")
                    color: RaohaneTheme.text
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }

            Text {
                Layout.fillWidth: true
                text: RaohaneConfig.dockAutoHide
                    ? qsTr("Auto-hide dock")
                    : qsTr("Pin dock")
                color: RaohaneTheme.textFaint
                font.pixelSize: 8
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: RaohaneConfig.dockIconSize + " px"
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 54
            color: RaohaneTheme.borderFaint
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RaohaneSurface {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }
                implicitWidth: previewRow.implicitWidth + 20
                width: implicitWidth
                height: Math.max(46, root.previewIconSize + 18)
                surfaceRadius: height / 2
                raised: true
                showSheen: false
                border.color: RaohaneTheme.borderStrong
                opacity: RaohaneConfig.dockEnabled ? 1 : 0.38

                RowLayout {
                    id: previewRow
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                        margins: 7
                    }
                    spacing: 5

                    PreviewControl {
                        icon: "space_dashboard"
                        active: false
                    }

                    PreviewControl {
                        icon: RaohaneConfig.dockPinned ? "keep" : "keep_off"
                        active: RaohaneConfig.dockPinned
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: Math.max(22, root.previewIconSize - 3)
                        color: RaohaneTheme.borderFaint
                        visible: root.pinnedApps.length > 0
                    }

                    Repeater {
                        model: root.pinnedApps

                        delegate: RaohaneSurface {
                            required property var modelData

                            Layout.preferredWidth: root.previewIconSize + 8
                            Layout.preferredHeight: root.previewIconSize + 8
                            surfaceRadius: 10
                            transparentIdle: true
                            showSheen: false

                            RaohaneAdaptiveIcon {
                                anchors.centerIn: parent
                                iconSource: String(modelData)
                                iconSize: root.previewIconSize
                                fallbackColor: RaohaneTheme.textMuted
                            }

                            Rectangle {
                                anchors {
                                    horizontalCenter: parent.horizontalCenter
                                    bottom: parent.bottom
                                    bottomMargin: 1
                                }
                                width: 7
                                height: 2
                                radius: 1
                                color: RaohaneTheme.accent
                                opacity: 0.42
                            }
                        }
                    }

                    PreviewControl {
                        visible: root.pinnedApps.length === 0
                        icon: "terminal"
                        active: true
                    }

                    PreviewControl {
                        visible: root.pinnedApps.length === 0
                        icon: "folder"
                        active: false
                    }

                    PreviewControl {
                        visible: root.pinnedApps.length === 0
                        icon: "language"
                        active: false
                    }
                }
            }
        }
    }

    component PreviewControl: RaohaneSurface {
        required property string icon

        Layout.preferredWidth: root.previewIconSize + 8
        Layout.preferredHeight: root.previewIconSize + 8
        surfaceRadius: 10
        transparentIdle: !active
        showSheen: false

        RaohaneIcon {
            anchors.centerIn: parent
            text: icon
            iconSize: Math.max(14, root.previewIconSize * 0.58)
            fill: parent.active ? 1 : 0
            symbolWeight: parent.active ? 540 : 430
            color: parent.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
        }
    }
}
