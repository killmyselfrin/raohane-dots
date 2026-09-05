import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.services

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    readonly property var targetScreen: Quickshell.screens.find(screen => screen.name === RaohaneDropShelf.targetScreenName)
        ?? root.focusedScreen

    PanelWindow {
        id: shelfWindow

        visible: RaohaneDropShelf.open
        screen: root.targetScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 410
        implicitHeight: 238

        anchors {
            top: true
            left: true
        }

        margins {
            left: Math.max(16, Math.min((shelfWindow.screen?.width ?? 1920) - implicitWidth - 16,
                RaohaneDropShelf.positionX - implicitWidth / 2))
            top: Math.max(16, Math.min((shelfWindow.screen?.height ?? 1080) - implicitHeight - 16,
                RaohaneDropShelf.positionY - implicitHeight - 30))
        }

        WlrLayershell.namespace: "quickshell:raohane-dropshelf"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        onVisibleChanged: {
            if (visible) {
                shelfPanel.entered = false
                Qt.callLater(() => shelfPanel.entered = true)
            } else {
                shelfPanel.entered = false
            }
        }

        DropArea {
            anchors.fill: parent
            keys: ["text/uri-list"]
            onEntered: drag => drag.accepted = drag.hasUrls
            onDropped: drop => {
                if (!drop.hasUrls) {
                    drop.accepted = false
                    return
                }
                RaohaneDropShelf.addItems(drop.urls)
                drop.accept()
            }
        }

        RaohaneSurface {
            id: shelfPanel
            property bool entered: false

            anchors.fill: parent
            surfaceRadius: 14
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            opacity: entered ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 14
                    rightMargin: 14
                }
                height: 1
                color: RaohaneTheme.accent
                opacity: 0.34
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 11
                spacing: 7

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 29
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 2
                        Layout.preferredHeight: 22
                        radius: 1
                        color: RaohaneTheme.accent
                    }

                    RaohaneIcon {
                        text: "shelves"
                        iconSize: 15
                        fill: 1
                        symbolWeight: 540
                        color: RaohaneTheme.accent
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Drop Shelf")
                        color: RaohaneTheme.text
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    RaohaneSurface {
                        implicitWidth: itemCount.implicitWidth + 14
                        implicitHeight: 22
                        surfaceRadius: 7
                        transparentIdle: true
                        showSheen: false

                        Text {
                            id: itemCount
                            anchors.centerIn: parent
                            text: qsTr("%1 items").arg(RaohaneDropShelf.items.length)
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 6
                            font.weight: Font.Medium
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.borderFaint
                }

                ListView {
                    id: shelfList

                    Layout.fillWidth: true
                    Layout.preferredHeight: 126
                    orientation: ListView.Horizontal
                    spacing: 6
                    clip: true
                    model: RaohaneDropShelf.items
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 2500

                    delegate: RaohaneDropShelfItem {
                        required property string modelData
                        required property int index

                        entryPath: modelData
                        itemIndex: index
                        onOpenRequested: path => RaohaneDropShelf.openPath(path)
                        onRevealRequested: path => RaohaneDropShelf.revealPath(path)
                        onCopyRequested: path => RaohaneDropShelf.copyPath(path)
                        onRemoveRequested: index => RaohaneDropShelf.removeAt(index)
                    }

                    Column {
                        anchors.centerIn: parent
                        visible: RaohaneDropShelf.items.length === 0
                        spacing: 4

                        RaohaneIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "move_to_inbox"
                            iconSize: 22
                            color: RaohaneTheme.textFaint
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("Drop files here")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    ShelfButton {
                        title: qsTr("Copy")
                        icon: "content_copy"
                        primary: true
                        enabled: RaohaneDropShelf.items.length > 0
                        onTriggered: RaohaneDropShelf.copyAll()
                    }
                    ShelfButton {
                        title: qsTr("Clear")
                        icon: "delete_sweep"
                        enabled: RaohaneDropShelf.items.length > 0
                        onTriggered: RaohaneDropShelf.clear()
                    }
                    ShelfButton {
                        title: qsTr("Close")
                        icon: "close"
                        onTriggered: RaohaneDropShelf.hide()
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "dropShelf"
        function open(): void { RaohaneDropShelf.open = true }
        function close(): void { RaohaneDropShelf.hide() }
        function clear(): void { RaohaneDropShelf.clear() }
        function copyAll(): void { RaohaneDropShelf.copyAll() }
    }

    component ShelfButton: RaohaneSurface {
        id: button
        required property string title
        required property string icon
        property bool primary: false
        signal triggered()

        Layout.fillWidth: true
        Layout.preferredHeight: 32
        surfaceRadius: 8
        active: primary
        transparentIdle: !primary && !hovered
        showSheen: false
        interactive: true
        hovered: buttonMouse.containsMouse
        pressed: buttonMouse.pressed
        hoverScale: 1
        pressedScale: 1
        opacity: button.enabled ? 1 : RaohaneMotion.disabledOpacity
        border.color: primary ? RaohaneTheme.accentBorder
            : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

        Row {
            anchors.centerIn: parent
            spacing: 5

            RaohaneIcon {
                text: button.icon
                iconSize: 12
                fill: button.primary || button.hovered ? 1 : 0
                symbolWeight: button.pressed ? 560 : button.primary || button.hovered ? 520 : 430
                color: button.primary ? RaohaneTheme.accent
                    : button.hovered ? RaohaneTheme.text : RaohaneTheme.textMuted

                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
            }
            Text {
                text: button.title
                color: button.primary ? RaohaneTheme.accent : RaohaneTheme.text
                font.pixelSize: 7
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: button.enabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: button.triggered()
        }

        Behavior on opacity {
            NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
        }
    }
}
