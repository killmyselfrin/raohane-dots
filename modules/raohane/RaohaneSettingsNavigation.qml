pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.modules.raohane.config
import qs.modules.raohane.services

Item {
    id: root

    property var pages: []
    property int currentPage: 0
    property bool compact: false

    signal pageRequested(int index)

    implicitWidth: compact ? 72 : 210

    Rectangle {
        anchors.fill: parent
        color: RaohaneTheme.surfaceSubtle
        opacity: RaohaneTheme.dark ? 0.50 : 0.36
    }

    Rectangle {
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }
        width: 1
        color: RaohaneTheme.highlight
        opacity: 0.035
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 11
        anchors.bottomMargin: 10
        spacing: 7

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 48

            RowLayout {
                anchors.fill: parent
                spacing: 9

                RaohaneSurface {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    surfaceRadius: 10
                    active: true
                    showSheen: false

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: "spa"
                        iconSize: 18
                        fill: 1
                        symbolWeight: 560
                        grade: 40
                        color: RaohaneTheme.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: !root.compact
                    spacing: 0

                    Text {
                        text: "RAOHANE"
                        color: RaohaneTheme.text
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.1
                    }

                    Text {
                        text: qsTr("System settings")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 7
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: RaohaneTheme.borderFaint
        }

        Flickable {
            id: navigation
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: navColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 2600

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                width: 3
                contentItem: Rectangle {
                    implicitWidth: 3
                    radius: 2
                    color: RaohaneTheme.accent
                    opacity: 0.42
                }
            }

            Column {
                id: navColumn
                width: navigation.width
                spacing: 1

                Repeater {
                    model: root.pages

                    delegate: Item {
                        id: navDelegate
                        required property var modelData
                        required property int index
                        readonly property bool firstInGroup: RaohaneSettingsPageRegistry.isFirstInGroup(index)

                        width: navColumn.width
                        height: root.compact ? 41 : (firstInGroup ? 54 : 37)

                        Text {
                            visible: !root.compact && navDelegate.firstInGroup
                            anchors {
                                left: parent.left
                                leftMargin: 9
                                top: parent.top
                                topMargin: 7
                            }
                            text: navDelegate.modelData.group
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 6
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.85
                        }

                        RaohaneSurface {
                            id: navItem
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }
                            height: 34
                            surfaceRadius: 9
                            active: root.currentPage === navDelegate.index
                            transparentIdle: !active
                            showSheen: false
                            interactive: true
                            hovered: navMouse.containsMouse || activeFocus
                            pressed: navMouse.pressed
                            hoverScale: 1
                            pressedScale: 1
                            activeFocusOnTab: true
                            border.color: navItem.active
                                ? RaohaneTheme.accentBorder
                                : navItem.hovered
                                    ? RaohaneTheme.borderStrong
                                    : RaohaneTheme.borderFaint

                            Rectangle {
                                visible: navItem.active
                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 2
                                }
                                width: 2
                                height: 16
                                radius: 1
                                color: RaohaneTheme.accent
                                opacity: 0.88
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: root.compact ? 0 : 10
                                anchors.rightMargin: root.compact ? 0 : 8
                                spacing: 8

                                RaohaneIcon {
                                    Layout.alignment: root.compact ? Qt.AlignCenter : Qt.AlignVCenter
                                    text: navDelegate.modelData.icon
                                    iconSize: 15
                                    fill: navItem.active ? 1 : navItem.hovered ? 0.30 : 0
                                    symbolWeight: navItem.active ? 550 : navItem.hovered ? 490 : 420
                                    color: navItem.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: !root.compact
                                    text: navDelegate.modelData.name
                                    color: navItem.active ? RaohaneTheme.text : RaohaneTheme.textMuted
                                    font.pixelSize: 8
                                    font.weight: navItem.active ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: navMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPressed: navItem.forceActiveFocus()
                                onClicked: root.pageRequested(navDelegate.index)
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.pageRequested(navDelegate.index)
                                    event.accepted = true
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: RaohaneTheme.borderFaint
        }

        RaohaneSurface {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            surfaceRadius: 11
            transparentIdle: true
            showSheen: false
            interactive: true
            hovered: profileMouse.containsMouse
            pressed: profileMouse.pressed
            hoverScale: 1
            pressedScale: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: root.compact ? 6 : 7
                anchors.rightMargin: 7
                spacing: 8

                RaohaneSurface {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    surfaceRadius: 10
                    showSheen: false
                    clip: true

                    Image {
                        id: avatar
                        anchors.fill: parent
                        source: RaohaneConfig.profileAvatarPath !== ""
                            ? "file://" + RaohaneConfig.profileAvatarPath
                            : RaohanePaths.defaultAvatarUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                        asynchronous: true
                    }

                    RaohaneIcon {
                        anchors.centerIn: parent
                        visible: !avatar.visible
                        text: "account_circle"
                        iconSize: 19
                        color: RaohaneTheme.textMuted
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: !root.compact
                    spacing: -1

                    Text {
                        Layout.fillWidth: true
                        text: RaohaneConfig.profileDisplayName === ""
                            ? RaohaneSystemInfo.username
                            : RaohaneConfig.profileDisplayName
                        color: RaohaneTheme.text
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: RaohaneSystemInfo.distroName || qsTr("Hyprland")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 6
                        elide: Text.ElideRight
                    }
                }

                RaohaneIcon {
                    visible: !root.compact
                    text: "chevron_right"
                    iconSize: 12
                    color: RaohaneTheme.textFaint
                }
            }

            MouseArea {
                id: profileMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const index = RaohaneSettingsPageRegistry.resolvePageIndex("profile")
                    if (index >= 0)
                        root.pageRequested(index)
                }
            }
        }
    }
}
