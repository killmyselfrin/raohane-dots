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

    PanelWindow {
        id: shelfWindow

        visible: RaohaneDropShelf.open
        screen: root.focusedScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 372
        implicitHeight: 228

        anchors {
            top: true
            left: true
        }

        margins {
            left: Math.max(20, RaohaneDropShelf.positionX - implicitWidth / 2)
            top: Math.max(20, RaohaneDropShelf.positionY - implicitHeight - 30)
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
            surfaceRadius: 20
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            opacity: entered ? 1 : 0
            scale: entered ? 1 : 0.97

            transform: Translate {
                y: shelfPanel.entered ? 0 : 10
                Behavior on y {
                    NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
            }
            Behavior on scale {
                NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30

                    RaohaneSurface {
                        width: 28
                        height: 28
                        surfaceRadius: 9
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "shelves"
                            iconSize: 15
                            fill: 1
                            symbolWeight: 540
                            color: RaohaneTheme.accent
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Drop Shelf")
                        color: RaohaneTheme.text
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: qsTr("%1 items").arg(RaohaneDropShelf.items.length)
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
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
                    Layout.preferredHeight: 124
                    orientation: ListView.Horizontal
                    spacing: 7
                    clip: true
                    model: RaohaneDropShelf.items
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 2500

                    delegate: RaohaneSurface {
                        id: itemCard
                        required property string modelData

                        width: 104
                        height: 116
                        surfaceRadius: 14
                        raised: false
                        interactive: true
                        hovered: itemMouse.containsMouse
                        pressed: itemMouse.pressed
                        showSheen: false
                        hoverScale: 1.015
                        pressedScale: 0.975

                        readonly property string entryPath: modelData
                        readonly property bool imageLike: /\.(png|jpe?g|webp|bmp|gif)$/i.test(entryPath)

                        Drag.active: itemMouse.drag.active
                        Drag.dragType: Drag.Automatic
                        Drag.mimeData: ({ "text/uri-list": "file://" + entryPath })
                        Drag.supportedActions: Qt.CopyAction

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 7
                            spacing: 5

                            RaohaneSurface {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 76
                                surfaceRadius: 11
                                active: itemMouse.drag.active
                                showSheen: false
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: itemCard.imageLike ? "file://" + itemCard.entryPath : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    visible: itemCard.imageLike && status === Image.Ready
                                }

                                RaohaneIcon {
                                    anchors.centerIn: parent
                                    visible: !itemCard.imageLike
                                    text: itemCard.entryPath.endsWith("/") ? "folder" : "draft"
                                    iconSize: 24
                                    fill: itemMouse.containsMouse ? 1 : 0
                                    symbolWeight: itemMouse.containsMouse ? 520 : 430
                                    color: itemMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted

                                    Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: itemCard.entryPath.split("/").pop()
                                color: RaohaneTheme.text
                                font.pixelSize: 8
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideMiddle
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            drag.target: itemCard
                            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                            onReleased: {
                                if (itemCard.Drag.active)
                                    itemCard.Drag.drop()
                                itemCard.x = 0
                                itemCard.y = 0
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        visible: RaohaneDropShelf.items.length === 0
                        spacing: 4

                        RaohaneIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "move_to_inbox"
                            iconSize: 24
                            color: RaohaneTheme.textFaint
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("Drop files here")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

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
        Layout.preferredHeight: 34
        surfaceRadius: 10
        active: primary
        transparentIdle: !primary
        showSheen: false
        interactive: true
        hovered: buttonMouse.containsMouse
        pressed: buttonMouse.pressed
        hoverScale: 1.01
        pressedScale: RaohaneMotion.pressScale
        opacity: button.enabled ? 1 : RaohaneMotion.disabledOpacity

        Row {
            anchors.centerIn: parent
            spacing: 5

            RaohaneIcon {
                text: button.icon
                iconSize: 13
                fill: button.primary || button.hovered ? 1 : 0
                symbolWeight: button.pressed ? 560 : button.primary || button.hovered ? 520 : 430
                color: button.primary ? RaohaneTheme.accent
                    : button.hovered ? RaohaneTheme.text : RaohaneTheme.textMuted

                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
            }
            Text {
                text: button.title
                color: button.primary ? RaohaneTheme.accent : RaohaneTheme.text
                font.pixelSize: 8
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
