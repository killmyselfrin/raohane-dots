pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import qs.modules.raohane.config
import qs.modules.raohane.services

Item {
    id: root

    property string selectedRestorePath: ""

    function shortPath(path: string): string {
        const clean = RaohanePaths.cleanPath(path)
        if (clean.length <= 62)
            return clean
        return "…" + clean.substring(clean.length - 61)
    }

    FileDialog {
        id: exportDialog
        title: qsTr("Save Raohane backup")
        fileMode: FileDialog.SaveFile
        currentFolder: Qt.resolvedUrl("file://" + (RaohanePaths.downloads || RaohanePaths.home))
        defaultSuffix: "raohane-backup"
        nameFilters: [qsTr("Raohane backup (*.raohane-backup)"), qsTr("All files (*)")]
        onAccepted: RaohaneBackup.exportBackup(selectedFile)
    }

    FileDialog {
        id: restoreDialog
        title: qsTr("Choose Raohane backup")
        fileMode: FileDialog.OpenFile
        currentFolder: Qt.resolvedUrl("file://" + (RaohanePaths.downloads || RaohanePaths.home))
        nameFilters: [qsTr("Raohane backup (*.raohane-backup)"), qsTr("All files (*)")]
        onAccepted: root.selectedRestorePath = RaohanePaths.cleanPath(selectedFile)
    }

    Flickable {
        id: backupFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: pageColumn.implicitHeight + 42
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 2600

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 4
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: RaohaneTheme.accent
                opacity: 0.42
            }
        }

        ColumnLayout {
            id: pageColumn

            y: 16
            width: Math.min(parent.width - 40, 900)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: qsTr("Save the complete Raohane-owned setup as one portable file, then restore it after a reinstall or on another machine.")
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                lineHeight: 1.2
                wrapMode: Text.WordWrap
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 90
                surfaceRadius: 13
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: 46
                    radius: 2
                    color: RaohaneTheme.accent
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 13

                    RaohaneSurface {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        surfaceRadius: 13
                        raised: false
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "inventory_2"
                            iconSize: 21
                            fill: 0.8
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("What is included")
                            color: RaohaneTheme.text
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Wallpaper and lock wallpaper · theme and accent · keybinds · motion · bar and dock · monitor profiles · integrations · profile · notification/autostart/theme catalogs")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            lineHeight: 1.16
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 11

                ToolPanel {
                    id: exportPanel
                    Layout.fillWidth: true
                    icon: "archive"
                    title: qsTr("Create backup")
                    detail: qsTr("Current external wallpaper and avatar files are copied into the archive so the backup stays portable.")

                    ActionButton {
                        Layout.alignment: Qt.AlignLeft
                        icon: "save"
                        label: RaohaneBackup.busy && RaohaneBackup.operation === "export"
                            ? qsTr("Saving…")
                            : qsTr("Export backup")
                        emphasized: true
                        enabled: !RaohaneBackup.busy
                        onTriggered: exportDialog.open()
                    }
                }

                ToolPanel {
                    id: restorePanel
                    Layout.fillWidth: true
                    icon: "settings_backup_restore"
                    title: qsTr("Restore backup")
                    detail: qsTr("Choose a backup first. Nothing is replaced until you explicitly press Restore selected backup.")

                    RowLayout {
                        Layout.alignment: Qt.AlignLeft
                        spacing: 8

                        ActionButton {
                            icon: "folder_open"
                            label: qsTr("Choose backup")
                            emphasized: root.selectedRestorePath.length === 0
                            enabled: !RaohaneBackup.busy
                            onTriggered: restoreDialog.open()
                        }

                        ActionButton {
                            visible: root.selectedRestorePath.length > 0
                            icon: "restore"
                            label: RaohaneBackup.busy && RaohaneBackup.operation === "restore"
                                ? qsTr("Restoring…")
                                : qsTr("Restore selected")
                            emphasized: true
                            enabled: !RaohaneBackup.busy
                            onTriggered: RaohaneBackup.restoreBackup(root.selectedRestorePath)
                        }
                    }
                }
            }

            RaohaneSurface {
                visible: root.selectedRestorePath.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 62
                surfaceRadius: 11
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 10
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 3
                        Layout.preferredHeight: 28
                        radius: 2
                        color: RaohaneTheme.accent
                        opacity: 0.72
                    }

                    RaohaneIcon {
                        text: "description"
                        iconSize: 18
                        color: RaohaneTheme.textMuted
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: qsTr("Selected backup")
                            color: RaohaneTheme.text
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.shortPath(root.selectedRestorePath)
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                            elide: Text.ElideMiddle
                        }
                    }

                    RaohaneIconButton {
                        buttonSize: 32
                        iconSize: 14
                        icon: "close"
                        transparentIdle: true
                        showSheen: false
                        hoverScale: 1
                        pressedScale: 1
                        onClicked: root.selectedRestorePath = ""
                    }
                }
            }

            RaohaneSurface {
                visible: RaohaneBackup.statusMessage.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 78
                surfaceRadius: 12
                raised: false
                showSheen: false
                border.color: RaohaneBackup.lastSucceeded ? RaohaneTheme.accentBorder : RaohaneTheme.borderStrong

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    spacing: 11

                    Rectangle {
                        Layout.preferredWidth: 3
                        Layout.preferredHeight: 34
                        radius: 2
                        color: RaohaneBackup.lastSucceeded ? RaohaneTheme.accent : RaohaneTheme.textMuted
                        opacity: RaohaneBackup.busy || RaohaneBackup.lastSucceeded ? 1 : 0.5
                    }

                    RaohaneSurface {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        surfaceRadius: 11
                        raised: false
                        active: RaohaneBackup.busy || RaohaneBackup.lastSucceeded
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: RaohaneBackup.busy
                                ? "progress_activity"
                                : RaohaneBackup.lastSucceeded ? "check_circle" : "error"
                            iconSize: 19
                            fill: RaohaneBackup.lastSucceeded ? 1 : 0
                            color: RaohaneBackup.lastSucceeded ? RaohaneTheme.accent : RaohaneTheme.textMuted

                            RotationAnimation on rotation {
                                running: RaohaneBackup.busy
                                from: 0
                                to: 360
                                duration: 1000
                                loops: Animation.Infinite
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: RaohaneBackup.statusMessage
                            color: RaohaneTheme.text
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: RaohaneBackup.detailMessage
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            lineHeight: 1.15
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                        }
                    }

                    ActionButton {
                        visible: RaohaneBackup.lastSucceeded && RaohaneBackup.operation === "restore"
                        icon: "restart_alt"
                        label: qsTr("Restart Raohane")
                        emphasized: true
                        onTriggered: RaohaneBackup.restartShell()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: RaohaneTheme.borderFaint
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("Before every restore, Raohane automatically stores your current configuration in ~/.local/state/raohane/restore-points.")
                color: RaohaneTheme.textFaint
                font.pixelSize: 8
                lineHeight: 1.18
                wrapMode: Text.WordWrap
            }
        }
    }

    component ToolPanel: RaohaneSurface {
        id: toolPanel

        required property string icon
        required property string title
        required property string detail
        default property alias body: bodyColumn.data

        Layout.preferredHeight: 174
        surfaceRadius: 13
        raised: false
        showSheen: false
        border.color: RaohaneTheme.borderFaint

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 15
            anchors.bottomMargin: 15
            width: 3
            radius: 2
            color: RaohaneTheme.accent
            opacity: 0.76
        }

        ColumnLayout {
            id: bodyColumn
            anchors.fill: parent
            anchors.leftMargin: 17
            anchors.rightMargin: 15
            anchors.topMargin: 15
            anchors.bottomMargin: 14
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                RaohaneSurface {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    surfaceRadius: 11
                    raised: false
                    active: true
                    showSheen: false

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: toolPanel.icon
                        iconSize: 19
                        fill: 0.55
                        color: RaohaneTheme.accent
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: toolPanel.title
                    color: RaohaneTheme.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }

            Text {
                Layout.fillWidth: true
                text: toolPanel.detail
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                lineHeight: 1.16
                wrapMode: Text.WordWrap
            }

            Item { Layout.fillHeight: true }
        }
    }

    component ActionButton: FocusScope {
        id: actionButton

        required property string icon
        required property string label
        property bool emphasized: false
        signal triggered()

        implicitWidth: actionRow.implicitWidth + 24
        implicitHeight: 36
        activeFocusOnTab: true
        opacity: enabled ? 1 : 0.48

        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: 10
            active: actionButton.emphasized
            transparentIdle: !actionButton.emphasized && !hovered
            raised: false
            showSheen: false
            interactive: actionButton.enabled
            hovered: actionMouse.containsMouse || actionButton.activeFocus
            pressed: actionMouse.pressed
            hoverScale: 1
            pressedScale: 1
            border.color: actionButton.emphasized ? RaohaneTheme.accentBorder
                : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

            RowLayout {
                id: actionRow
                anchors.centerIn: parent
                spacing: 7

                RaohaneIcon {
                    text: actionButton.icon
                    iconSize: 14
                    fill: actionButton.emphasized || actionMouse.containsMouse || actionButton.activeFocus ? 1 : 0
                    color: actionButton.emphasized ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }

                Text {
                    text: actionButton.label
                    color: actionButton.emphasized ? RaohaneTheme.text : RaohaneTheme.textMuted
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            enabled: actionButton.enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: actionButton.forceActiveFocus()
            onClicked: actionButton.triggered()
        }

        Keys.onPressed: event => {
            if (!actionButton.enabled)
                return
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                actionButton.triggered()
                event.accepted = true
            }
        }
    }
}
