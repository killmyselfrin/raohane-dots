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

    implicitWidth: compact ? 78 : 226

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
        anchors.margins: RaohaneTheme.panelPadding
        spacing: RaohaneTheme.spacingSmall

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 52

            RowLayout {
                anchors.fill: parent
                spacing: RaohaneTheme.spacing

                RaohaneSurface {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    surfaceRadius: RaohaneTheme.radiusLarge
                    active: true
                    showSheen: false

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: "spa"
                        iconSize: 19
                        fill: 1
                        symbolWeight: 560
                        grade: 40
                        color: RaohaneTheme.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: !root.compact
                    spacing: RaohaneTheme.spacingTiny / 3

                    Text {
                        text: "RAOHANE"
                        color: RaohaneTheme.text
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.1
                    }

                    Text {
                        text: qsTr("System settings")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
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
            contentHeight: navContent.height
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

            Item {
                id: navContent
                width: navigation.width
                height: navColumn.implicitHeight

                readonly property var selectedDelegate: navRepeater.itemAt(root.currentPage)
                readonly property real selectedY: selectedDelegate
                    ? selectedDelegate.y + selectedDelegate.height - 36
                    : 0

                RaohaneSurface {
                    id: selectionRail
                    z: 0
                    x: 0
                    y: navContent.selectedY
                    width: navContent.width
                    height: 36
                    visible: navContent.selectedDelegate !== null
                    opacity: visible ? 1 : 0
                    surfaceRadius: RaohaneTheme.radius
                    active: true
                    raised: false
                    showSheen: false
                    activeBorderColor: RaohaneTheme.accentBorder
                    showStateRail: true
                    stateRailWidth: 2
                    stateRailLength: 18
                    stateRailOpacity: 0.90

                    Behavior on y {
                        enabled: RaohaneMotion.transformMotionEnabled
                        NumberAnimation {
                            duration: RaohaneMotion.selectionTravel
                            easing.type: RaohaneMotion.easeEmphasized
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: RaohaneMotion.micro }
                    }
                }

                Column {
                    id: navColumn
                    z: 1
                    width: navContent.width
                    spacing: RaohaneTheme.spacingTiny - 1

                    Repeater {
                        id: navRepeater
                        model: root.pages

                        delegate: Item {
                            id: navDelegate
                            required property var modelData
                            required property int index
                            readonly property bool firstInGroup: RaohaneSettingsPageRegistry.isFirstInGroup(index)
                            readonly property bool selected: root.currentPage === navDelegate.index

                            width: navColumn.width
                            height: root.compact ? 43 : (firstInGroup ? 58 : 40)

                            Text {
                                visible: !root.compact && navDelegate.firstInGroup
                                anchors {
                                    left: parent.left
                                    leftMargin: RaohaneTheme.spacing
                                    top: parent.top
                                    topMargin: RaohaneTheme.spacingSmall
                                }
                                text: navDelegate.modelData.group
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.8
                            }

                            RaohaneSurface {
                                id: navItem
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                }
                                height: 36
                                surfaceRadius: RaohaneTheme.radius
                                active: false
                                transparentIdle: true
                                showSheen: false
                                showInnerRim: false
                                interactive: true
                                hovered: !navDelegate.selected && (navMouse.containsMouse || activeFocus)
                                pressed: !navDelegate.selected && navMouse.pressed
                                hoverScale: 1
                                pressedScale: 1
                                activeFocusOnTab: true
                                hoverColor: RaohaneTheme.surfaceSubtle
                                hoverBorderColor: RaohaneTheme.borderStrong

                                RowLayout {
                                    id: navRow
                                    anchors.fill: parent
                                    anchors.leftMargin: root.compact ? 0 : RaohaneTheme.spacing + 2
                                    anchors.rightMargin: root.compact ? 0 : RaohaneTheme.spacing
                                    spacing: RaohaneTheme.spacing

                                    transform: Translate {
                                        x: navItem.hovered && RaohaneMotion.transformMotionEnabled ? 2 : 0
                                        Behavior on x {
                                            NumberAnimation {
                                                duration: RaohaneMotion.micro
                                                easing.type: RaohaneMotion.easeStandard
                                            }
                                        }
                                    }

                                    RaohaneIcon {
                                        Layout.alignment: root.compact ? Qt.AlignCenter : Qt.AlignVCenter
                                        text: navDelegate.modelData.icon
                                        iconSize: 16
                                        fill: navDelegate.selected ? 1 : navItem.hovered ? 0.30 : 0
                                        symbolWeight: navDelegate.selected ? 550 : navItem.hovered ? 490 : 420
                                        color: navDelegate.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted

                                        Behavior on color {
                                            ColorAnimation { duration: RaohaneMotion.micro }
                                        }
                                        Behavior on fill {
                                            NumberAnimation { duration: RaohaneMotion.micro }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: !root.compact
                                        text: navDelegate.modelData.name
                                        color: navDelegate.selected ? RaohaneTheme.text : RaohaneTheme.textMuted
                                        font.pixelSize: 9
                                        font.weight: navDelegate.selected ? Font.DemiBold : Font.Normal
                                        elide: Text.ElideRight

                                        Behavior on color {
                                            ColorAnimation { duration: RaohaneMotion.micro }
                                        }
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
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: RaohaneTheme.borderFaint
        }

        RaohaneSurface {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            surfaceRadius: RaohaneTheme.radiusLarge
            transparentIdle: true
            showSheen: false
            interactive: true
            hovered: profileMouse.containsMouse
            pressed: profileMouse.pressed
            hoverScale: 1
            pressedScale: 1
            hoverColor: RaohaneTheme.surfaceSubtle
            hoverBorderColor: RaohaneTheme.borderStrong

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: root.compact ? RaohaneTheme.spacingSmall : RaohaneTheme.spacingSmall + 1
                anchors.rightMargin: RaohaneTheme.spacingSmall + 1
                spacing: RaohaneTheme.spacing

                transform: Translate {
                    x: profileMouse.containsMouse && RaohaneMotion.transformMotionEnabled ? 2 : 0
                    Behavior on x {
                        NumberAnimation {
                            duration: RaohaneMotion.micro
                            easing.type: RaohaneMotion.easeStandard
                        }
                    }
                }

                RaohaneSurface {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    surfaceRadius: RaohaneTheme.radiusLarge
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
                        iconSize: 20
                        color: RaohaneTheme.textMuted
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: !root.compact
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: RaohaneConfig.profileDisplayName === ""
                            ? RaohaneSystemInfo.username
                            : RaohaneConfig.profileDisplayName
                        color: RaohaneTheme.text
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: RaohaneSystemInfo.distroName || qsTr("Hyprland")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 7
                        elide: Text.ElideRight
                    }
                }

                RaohaneIcon {
                    visible: !root.compact
                    text: "chevron_right"
                    iconSize: 13
                    color: profileMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textFaint

                    Behavior on color {
                        ColorAnimation { duration: RaohaneMotion.micro }
                    }
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
