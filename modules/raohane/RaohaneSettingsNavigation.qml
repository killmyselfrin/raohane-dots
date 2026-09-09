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

    function revealPage(index: int): void {
        const item = navRepeater.itemAt(index)
        if (!item)
            return
        const top = item.y + item.height - 36
        const bottom = item.y + item.height
        const nextY = top < navigation.contentY ? top
            : bottom > navigation.contentY + navigation.height ? bottom - navigation.height
            : navigation.contentY
        navigation.contentY = Math.max(0, Math.min(Math.max(0, navigation.contentHeight - navigation.height), nextY))
    }

    function focusPage(index: int): void {
        const item = navRepeater.itemAt(Math.max(0, Math.min(root.pages.length - 1, index)))
        if (item)
            item.focusControl()
    }

    onCurrentPageChanged: Qt.callLater(() => root.revealPage(root.currentPage))
    onCompactChanged: Qt.callLater(() => root.revealPage(root.currentPage))

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
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 13
        anchors.bottomMargin: 12
        spacing: 8

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 52

            RowLayout {
                anchors.fill: parent
                spacing: 10

                RaohaneSurface {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    surfaceRadius: 11
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
                    spacing: 1

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
            onHeightChanged: Qt.callLater(() => root.revealPage(root.currentPage))

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
                    surfaceRadius: 10
                    active: true
                    raised: false
                    showSheen: false
                    border.color: RaohaneTheme.accentBorder

                    Rectangle {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: 2
                        }
                        width: 2
                        height: 18
                        radius: 1
                        color: RaohaneTheme.accent
                        opacity: 0.90
                    }

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
                    spacing: 2

                    Repeater {
                        id: navRepeater
                        model: root.pages

                        delegate: Item {
                            id: navDelegate
                            required property var modelData
                            required property int index
                            readonly property bool firstInGroup: RaohaneSettingsPageRegistry.isFirstInGroup(index)
                            readonly property bool selected: root.currentPage === navDelegate.index

                            function focusControl(): void {
                                navItem.forceActiveFocus(Qt.TabFocusReason)
                            }

                            width: navColumn.width
                            height: root.compact ? 43 : (firstInGroup ? 58 : 40)

                            Text {
                                visible: !root.compact && navDelegate.firstInGroup
                                anchors {
                                    left: parent.left
                                    leftMargin: 10
                                    top: parent.top
                                    topMargin: 8
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
                                surfaceRadius: 10
                                active: false
                                transparentIdle: true
                                showSheen: false
                                interactive: true
                                hovered: navMouse.containsMouse || activeFocus
                                pressed: navMouse.pressed
                                hoverScale: 1
                                pressedScale: 1
                                activeFocusOnTab: true
                                Accessible.role: Accessible.Button
                                Accessible.name: navDelegate.modelData.name
                                Accessible.onPressAction: root.pageRequested(navDelegate.index)
                                onActiveFocusChanged: {
                                    if (activeFocus)
                                        root.revealPage(navDelegate.index)
                                }
                                ToolTip.visible: root.compact && navMouse.containsMouse
                                ToolTip.text: navDelegate.modelData.name
                                ToolTip.delay: 500
                                border.color: navDelegate.selected
                                    ? "transparent"
                                    : navItem.hovered
                                        ? RaohaneTheme.borderStrong
                                        : "transparent"

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 10
                                    color: RaohaneTheme.surfaceSubtle
                                    opacity: !navDelegate.selected && navItem.hovered ? 0.36 : 0

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: RaohaneMotion.micro
                                            easing.type: RaohaneMotion.easeStandard
                                        }
                                    }
                                }

                                RowLayout {
                                    id: navRow
                                    anchors.fill: parent
                                    anchors.leftMargin: root.compact ? 0 : 11
                                    anchors.rightMargin: root.compact ? 0 : 9
                                    spacing: 9

                                    transform: Translate {
                                        x: navItem.hovered && !navDelegate.selected && RaohaneMotion.transformMotionEnabled ? 2 : 0
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
                                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                                        root.focusPage(navDelegate.index + (event.key === Qt.Key_Down ? 1 : -1))
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Home || event.key === Qt.Key_End) {
                                        root.focusPage(event.key === Qt.Key_Home ? 0 : root.pages.length - 1)
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
            surfaceRadius: 12
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
                spacing: 9

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
                    surfaceRadius: 11
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
