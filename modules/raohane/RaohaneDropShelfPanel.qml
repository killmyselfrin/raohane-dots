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
        implicitWidth: 450
        implicitHeight: 266

        anchors {
            top: true
            left: true
        }

        margins {
            left: Math.max(18, Math.min((shelfWindow.screen?.width ?? 1920) - implicitWidth - 18,
                RaohaneDropShelf.positionX - implicitWidth / 2))
            top: Math.max(18, Math.min((shelfWindow.screen?.height ?? 1080) - implicitHeight - 18,
                RaohaneDropShelf.positionY - implicitHeight - 32))
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
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            idleBorderColor: RaohaneTheme.borderStrong
            opacity: entered ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: RaohaneTheme.panelPadding + 1
                spacing: RaohaneTheme.spacingSmall + 2

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    spacing: RaohaneTheme.spacing

                    RaohaneSurface {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        surfaceRadius: RaohaneTheme.radius
                        active: true
                        raised: false
                        showSheen: false
                        showInnerRim: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "shelves"
                            iconSize: 17
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

                    RaohaneSurface {
                        implicitWidth: itemCount.implicitWidth + RaohaneTheme.spacingLarge
                        implicitHeight: 24
                        surfaceRadius: RaohaneTheme.radiusSmall
                        transparentIdle: true
                        showSheen: false
                        showInnerRim: false

                        Text {
                            id: itemCount
                            anchors.centerIn: parent
                            text: qsTr("%1 items").arg(RaohaneDropShelf.items.length)
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
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
                    Layout.preferredHeight: 148
                    orientation: ListView.Horizontal
                    spacing: RaohaneTheme.spacingSmall + 2
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
                        spacing: RaohaneTheme.spacingSmall

                        RaohaneSurface {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 40
                            height: 40
                            surfaceRadius: RaohaneTheme.radiusLarge
                            raised: false
                            showSheen: false
                            showInnerRim: false
                            idleColor: RaohaneTheme.surfaceSubtle
                            idleBorderColor: RaohaneTheme.borderFaint

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: "move_to_inbox"
                                iconSize: 23
                                color: RaohaneTheme.textFaint
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("Drop files here")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                            font.weight: Font.Medium
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: RaohaneTheme.spacingSmall

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
        Layout.preferredHeight: 36
        surfaceRadius: RaohaneTheme.radiusSmall
        active: primary
        transparentIdle: !primary && !hovered
        showSheen: false
        showInnerRim: primary
        interactive: true
        hovered: buttonMouse.containsMouse || activeFocus
        pressed: buttonMouse.pressed
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: enabled
        opacity: button.enabled ? 1 : RaohaneMotion.disabledOpacity
        idleBorderColor: RaohaneTheme.borderFaint
        hoverBorderColor: RaohaneTheme.borderStrong
        pressedBorderColor: RaohaneTheme.borderStrong
        activeBorderColor: RaohaneTheme.accentBorder

        Row {
            anchors.centerIn: parent
            spacing: RaohaneTheme.spacingSmall

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
            onPressed: button.forceActiveFocus()
            onClicked: button.triggered()
        }

        Keys.onPressed: event => {
            if (!button.enabled)
                return
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                button.triggered()
                event.accepted = true
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
        }
    }
}
