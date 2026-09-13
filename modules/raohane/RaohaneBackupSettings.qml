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

    readonly property bool compactLayout: width < 760
    readonly property color statusColor: RaohaneBackup.busy
        ? RaohaneTheme.info
        : RaohaneBackup.lastSucceeded ? RaohaneTheme.success : RaohaneTheme.critical

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
        contentHeight: pageColumn.implicitHeight + RaohaneTheme.panelPadding * 3
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 2600

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 4
            anchors.right: parent.right
            anchors.rightMargin: RaohaneTheme.spacingTiny
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: RaohaneTheme.accent
                opacity: 0.42
            }
        }

        ColumnLayout {
            id: pageColumn

            y: RaohaneTheme.spacingLarge
            width: Math.min(
                Math.max(0, parent.width - (root.compactLayout ? RaohaneTheme.panelPadding * 2 : 40)),
                900
            )
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: RaohaneTheme.spacingLarge

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
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint
                showStateRail: true
                stateRailColor: RaohaneTheme.accent
                stateRailOpacity: 0.62
                stateRailWidth: 3
                stateRailLength: 46

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: RaohaneTheme.panelPadding + RaohaneTheme.spacingSmall
                    anchors.rightMargin: RaohaneTheme.panelPadding
                    spacing: RaohaneTheme.spacingLarge

                    RaohaneSurface {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        surfaceRadius: RaohaneTheme.radiusSmall
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
                        spacing: RaohaneTheme.spacingTiny

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
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: root.compactLayout ? 1 : 2
                columnSpacing: RaohaneTheme.spacing
                rowSpacing: RaohaneTheme.spacing

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
                        spacing: RaohaneTheme.spacingSmall

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
                surfaceRadius: RaohaneTheme.radiusSmall
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint
                showStateRail: true
                stateRailColor: RaohaneTheme.accent
                stateRailOpacity: 0.54
                stateRailWidth: 2
                stateRailLength: 28

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: RaohaneTheme.panelPadding
                    anchors.rightMargin: RaohaneTheme.spacing
                    spacing: RaohaneTheme.spacing

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
                surfaceRadius: RaohaneTheme.radiusSmall
                raised: false
                showSheen: false
                border.color: Qt.rgba(root.statusColor.r, root.statusColor.g, root.statusColor.b, 0.48)
                showStateRail: true
                stateRailColor: root.statusColor
                stateRailOpacity: 0.72
                stateRailWidth: 3
                stateRailLength: 34

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: RaohaneTheme.panelPadding
                    anchors.rightMargin: RaohaneTheme.panelPadding
                    spacing: RaohaneTheme.spacing

                    RaohaneSurface {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        surfaceRadius: RaohaneTheme.radiusSmall
                        raised: false
                        active: RaohaneBackup.busy || RaohaneBackup.lastSucceeded
                        showSheen: false
                        border.color: Qt.rgba(root.statusColor.r, root.statusColor.g, root.statusColor.b, 0.38)

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: RaohaneBackup.busy
                                ? "progress_activity"
                                : RaohaneBackup.lastSucceeded ? "check_circle" : "error"
                            iconSize: 19
                            fill: RaohaneBackup.lastSucceeded ? 1 : 0
                            color: root.statusColor

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
                        spacing: RaohaneTheme.spacingTiny

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
                            maximumLineCount: 2
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

            RaohaneDivider {
                Layout.fillWidth: true
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
        surfaceRadius: RaohaneTheme.radiusLarge
        raised: false
        showSheen: false
        border.color: RaohaneTheme.borderFaint
        showStateRail: true
        stateRailColor: RaohaneTheme.accent
        stateRailOpacity: 0.56
        stateRailWidth: 3
        stateRailLength: Math.max(34, height - RaohaneTheme.panelPadding * 3)

        ColumnLayout {
            id: bodyColumn
            anchors.fill: parent
            anchors.leftMargin: RaohaneTheme.panelPadding + RaohaneTheme.spacingSmall
            anchors.rightMargin: RaohaneTheme.panelPadding
            anchors.topMargin: RaohaneTheme.panelPadding
            anchors.bottomMargin: RaohaneTheme.panelPadding
            spacing: RaohaneTheme.spacingSmall

            RowLayout {
                Layout.fillWidth: true
                spacing: RaohaneTheme.spacing

                RaohaneSurface {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    surfaceRadius: RaohaneTheme.radiusSmall
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
        activeFocusOnTab: enabled
        opacity: enabled ? 1 : RaohaneMotion.disabledOpacity

        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: RaohaneTheme.radiusSmall
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
                spacing: RaohaneTheme.spacingSmall

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
