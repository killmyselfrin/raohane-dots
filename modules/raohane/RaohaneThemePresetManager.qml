pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts

import qs.modules.raohane.config
import qs.modules.raohane.services

RaohaneSurface {
    id: root

    property string presetName: RaohaneTheme.presetName + " Custom"
    property var pendingExportPreset: null

    readonly property var activePreset: RaohaneTheme.activePreset
    readonly property bool activeIsUser: String(activePreset?.source ?? "") === "user"
    readonly property int userPresetCount: RaohaneThemeLibrary.userPresets.length

    implicitHeight: managerColumn.implicitHeight + 28
    surfaceRadius: 13
    raised: false
    showSheen: false
    border.color: RaohaneTheme.borderFaint

    function slug(value: string): string {
        const clean = String(value ?? "")
            .toLowerCase()
            .replace(/[^a-z0-9]+/g, "-")
            .replace(/^-+|-+$/g, "")
        return clean.length > 0 ? clean : "custom-theme"
    }

    function colorString(value): string {
        return String(value)
    }

    function currentPreset(): var {
        const name = root.presetName.trim().length > 0 ? root.presetName.trim() : qsTr("Custom theme")
        return {
            id: "user-" + root.slug(name),
            name: name,
            description: qsTr("Saved from the current Raohane palette"),
            tone: RaohaneTheme.dark ? qsTr("Custom · Dark") : qsTr("Custom · Light"),
            dark: RaohaneTheme.dark,
            source: "user",
            background: root.colorString(RaohaneTheme.background),
            backgroundElevated: root.colorString(RaohaneTheme.backgroundElevated),
            surface: root.colorString(RaohaneTheme.surface),
            surfaceRaised: root.colorString(RaohaneTheme.surfaceRaised),
            surfaceDeep: root.colorString(RaohaneTheme.surfaceDeep),
            surfaceSubtle: root.colorString(RaohaneTheme.surfaceSubtle),
            surfaceHover: root.colorString(RaohaneTheme.surfaceHover),
            surfacePressed: root.colorString(RaohaneTheme.surfacePressed),
            border: root.colorString(RaohaneTheme.border),
            borderStrong: root.colorString(RaohaneTheme.borderStrong),
            borderFaint: root.colorString(RaohaneTheme.borderFaint),
            highlight: root.colorString(RaohaneTheme.highlight),
            text: root.colorString(RaohaneTheme.text),
            textMuted: root.colorString(RaohaneTheme.textMuted),
            textFaint: root.colorString(RaohaneTheme.textFaint),
            accent: root.colorString(RaohaneTheme.accent),
            accentSecondary: root.colorString(RaohaneTheme.accentSecondary),
            accentBlue: root.colorString(RaohaneTheme.accentBlue),
            success: root.colorString(RaohaneTheme.success),
            warning: root.colorString(RaohaneTheme.warning),
            critical: root.colorString(RaohaneTheme.critical),
            info: root.colorString(RaohaneTheme.info)
        }
    }

    function exportActive(): void {
        root.pendingExportPreset = root.activePreset
        exportDialog.open()
    }

    Connections {
        target: RaohaneThemePresets

        function onCompleted(operation: string, success: bool, themeId: string, path: string): void {
            if (!success)
                return
            RaohaneThemeLibrary.refresh()
            if (operation === "save" && themeId.length > 0)
                RaohaneConfig.themePreset = themeId
        }
    }

    FileDialog {
        id: importDialog
        title: qsTr("Import Raohane theme")
        fileMode: FileDialog.OpenFile
        currentFolder: Qt.resolvedUrl("file://" + (RaohanePaths.downloads || RaohanePaths.home))
        nameFilters: [qsTr("Raohane theme (*.json)"), qsTr("JSON files (*.json)"), qsTr("All files (*)")]
        onAccepted: RaohaneThemePresets.importTheme(selectedFile)
    }

    FileDialog {
        id: exportDialog
        title: qsTr("Export Raohane theme")
        fileMode: FileDialog.SaveFile
        currentFolder: Qt.resolvedUrl("file://" + (RaohanePaths.downloads || RaohanePaths.home))
        defaultSuffix: "json"
        nameFilters: [qsTr("Raohane theme (*.json)"), qsTr("JSON files (*.json)"), qsTr("All files (*)")]
        onAccepted: {
            if (root.pendingExportPreset)
                RaohaneThemePresets.exportPreset(root.pendingExportPreset, selectedFile)
            root.pendingExportPreset = null
        }
        onRejected: root.pendingExportPreset = null
    }

    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            topMargin: 12
            bottomMargin: 12
        }
        width: 3
        radius: 2
        color: RaohaneTheme.accent
        opacity: 0.68
    }

    ColumnLayout {
        id: managerColumn

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 14
            leftMargin: 17
        }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 11

            RaohaneSurface {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                surfaceRadius: 11
                active: true
                raised: false
                showSheen: false

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: "palette"
                    iconSize: 18
                    fill: 0.75
                    color: RaohaneTheme.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: qsTr("User presets")
                    color: RaohaneTheme.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Save, import and export portable Raohane color themes")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                    elide: Text.ElideRight
                }
            }

            RaohaneSurface {
                implicitWidth: presetCount.implicitWidth + 18
                implicitHeight: 26
                surfaceRadius: 9
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                Text {
                    id: presetCount
                    anchors.centerIn: parent
                    text: qsTr("%1 custom").arg(root.userPresetCount)
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.minimumWidth: 164
                Layout.preferredHeight: 36
                surfaceRadius: 10
                raised: false
                showSheen: false
                active: presetNameInput.activeFocus
                border.color: presetNameInput.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                TextInput {
                    id: presetNameInput
                    anchors.fill: parent
                    anchors.leftMargin: 11
                    anchors.rightMargin: 11
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.presetName
                    color: RaohaneTheme.text
                    selectionColor: RaohaneTheme.accentSoft
                    selectedTextColor: RaohaneTheme.text
                    font.pixelSize: 9
                    clip: true
                    onTextEdited: root.presetName = text

                    Text {
                        anchors.fill: parent
                        visible: presetNameInput.text.length === 0 && !presetNameInput.activeFocus
                        text: qsTr("Preset name")
                        color: RaohaneTheme.textFaint
                        font: presetNameInput.font
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            ManagerButton {
                icon: "bookmark_add"
                label: qsTr("Save current")
                emphasized: true
                enabled: !RaohaneThemePresets.busy && root.presetName.trim().length > 0
                onTriggered: RaohaneThemePresets.savePreset(root.currentPreset())
            }

            ManagerButton {
                icon: "file_open"
                label: qsTr("Import")
                enabled: !RaohaneThemePresets.busy
                onTriggered: importDialog.open()
            }

            ManagerButton {
                icon: "download"
                label: qsTr("Export selected")
                enabled: !RaohaneThemePresets.busy && !!root.activePreset
                onTriggered: root.exportActive()
            }

            ManagerButton {
                visible: root.activeIsUser
                icon: "delete"
                label: qsTr("Remove")
                enabled: !RaohaneThemePresets.busy
                destructive: true
                onTriggered: {
                    const removedId = String(root.activePreset?.id ?? "")
                    RaohaneConfig.themePreset = "zen-mist"
                    RaohaneThemePresets.removePreset(removedId)
                }
            }
        }

        RowLayout {
            visible: RaohaneThemePresets.statusMessage.length > 0
            Layout.fillWidth: true
            spacing: 8

            RaohaneIcon {
                text: RaohaneThemePresets.busy
                    ? "progress_activity"
                    : RaohaneThemePresets.lastSucceeded ? "check_circle" : "error"
                iconSize: 14
                fill: RaohaneThemePresets.lastSucceeded ? 1 : 0
                color: RaohaneThemePresets.lastSucceeded ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: RaohaneThemePresets.statusMessage
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: RaohaneThemePresets.detailMessage
                color: RaohaneTheme.textFaint
                font.pixelSize: 8
                elide: Text.ElideMiddle
            }
        }
    }

    component ManagerButton: RaohaneSurface {
        id: button

        required property string icon
        required property string label
        property bool emphasized: false
        property bool destructive: false
        signal triggered()

        implicitWidth: buttonRow.implicitWidth + 20
        implicitHeight: 36
        surfaceRadius: 10
        raised: false
        active: emphasized
        transparentIdle: !emphasized
        interactive: enabled
        hovered: buttonMouse.containsMouse
        pressed: buttonMouse.pressed
        hoverScale: 1
        pressedScale: 1
        showSheen: false
        border.color: destructive && hovered
            ? RaohaneTheme.critical
            : emphasized ? RaohaneTheme.accentBorder
            : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint
        opacity: enabled ? 1 : 0.42

        RowLayout {
            id: buttonRow
            anchors.centerIn: parent
            spacing: 6

            RaohaneIcon {
                text: button.icon
                iconSize: 14
                fill: button.emphasized ? 1 : 0
                color: button.destructive
                    ? RaohaneTheme.critical
                    : button.emphasized ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: button.label
                color: button.destructive ? RaohaneTheme.critical : RaohaneTheme.text
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            enabled: button.enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: button.triggered()
        }
    }
}
