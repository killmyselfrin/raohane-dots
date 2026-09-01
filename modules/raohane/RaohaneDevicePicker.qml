pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.services

Item {
    id: root

    property string mode: ""
    property string selectedWifi: ""
    property string wifiPassword: ""
    signal closeRequested()

    readonly property bool wifiMode: mode === "wifi"
    readonly property bool outputMode: mode === "output"
    readonly property bool inputMode: mode === "input"
    readonly property var visibleEntries: wifiMode
        ? RaohaneNetwork.availableNetworks.slice(0, 6)
        : outputMode
            ? RaohaneAudio.outputDevices.slice(0, 6)
            : RaohaneAudio.inputDevices.slice(0, 6)
    readonly property string title: wifiMode ? qsTr("Wi-Fi networks")
        : outputMode ? qsTr("Sound output")
        : qsTr("Microphone input")
    readonly property string subtitle: wifiMode
        ? (RaohaneNetwork.wifiEnabled ? qsTr("Choose a network") : qsTr("Wi-Fi is turned off"))
        : outputMode
            ? (RaohaneAudio.sinkName || qsTr("Choose an output device"))
            : (RaohaneAudio.sourceName || qsTr("Choose an input device"))
    readonly property string headerIcon: wifiMode ? RaohaneNetwork.materialSymbol
        : outputMode ? (RaohaneAudio.muted ? "volume_off" : "speaker")
        : (RaohaneAudio.microphoneMuted ? "mic_off" : "mic")
    readonly property bool busy: wifiMode ? (RaohaneNetwork.scanning || RaohaneNetwork.connectingSsid.length > 0)
        : RaohaneAudio.devicesRefreshing

    implicitHeight: mode.length > 0 ? pickerContent.implicitHeight + 26 : 0
    visible: mode.length > 0

    onModeChanged: {
        root.selectedWifi = ""
        root.wifiPassword = ""
        if (root.wifiMode)
            RaohaneNetwork.scanNetworks()
        else if (root.outputMode || root.inputMode)
            RaohaneAudio.refreshDevices(true)
    }

    function selectEntry(entry): void {
        if (root.wifiMode) {
            if (entry.active)
                return
            if (entry.secure && !entry.saved) {
                root.selectedWifi = String(entry.ssid ?? "")
                root.wifiPassword = ""
                passwordField.forceActiveFocus()
                return
            }
            RaohaneNetwork.connectNetwork(String(entry.ssid ?? ""), "")
            return
        }

        if (root.outputMode)
            RaohaneAudio.setDefaultSink(entry)
        else
            RaohaneAudio.setDefaultSource(entry)
    }

    RaohaneSurface {
        anchors.fill: parent
        surfaceRadius: 19
        raised: false
        showSheen: false
        border.color: RaohaneTheme.borderStrong
        clip: true

        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: 2
            color: RaohaneTheme.accent
            opacity: 0.72
        }

        ColumnLayout {
            id: pickerContent
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 13
                rightMargin: 13
                topMargin: 12
            }
            spacing: 9

            RowLayout {
                Layout.fillWidth: true
                spacing: 9

                RaohaneSurface {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    surfaceRadius: 12
                    active: true
                    showSheen: false

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: root.headerIcon
                        iconSize: 18
                        fill: 1
                        color: RaohaneTheme.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: root.title
                        color: RaohaneTheme.text
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.subtitle
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 7
                        elide: Text.ElideRight
                    }
                }

                RaohaneSwitch {
                    visible: root.wifiMode
                    checked: RaohaneNetwork.wifiEnabled
                    onToggled: checked => RaohaneNetwork.setWifiEnabled(checked)
                }

                RaohaneIconButton {
                    buttonSize: 29
                    iconSize: 14
                    icon: "refresh"
                    transparentIdle: true
                    showSheen: false
                    enabled: root.wifiMode ? RaohaneNetwork.wifiEnabled && !root.busy : !root.busy
                    onClicked: {
                        if (root.wifiMode)
                            RaohaneNetwork.scanNetworks()
                        else
                            RaohaneAudio.refreshDevices(true)
                    }

                    RotationAnimation on rotation {
                        running: root.busy
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 900
                    }
                }

                RaohaneIconButton {
                    buttonSize: 29
                    iconSize: 14
                    icon: "close"
                    transparentIdle: true
                    showSheen: false
                    onClicked: root.closeRequested()
                }
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                surfaceRadius: 14
                raised: false
                showSheen: false
                active: root.wifiMode ? RaohaneNetwork.wifiConnected
                    : root.outputMode ? RaohaneAudio.ready
                    : RaohaneAudio.microphoneReady

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 11
                    anchors.rightMargin: 11
                    spacing: 9

                    Rectangle {
                        width: 7
                        height: 7
                        radius: 4
                        color: parent.parent.active ? RaohaneTheme.success : RaohaneTheme.textFaint
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: root.wifiMode
                                ? (RaohaneNetwork.networkName || qsTr("Not connected"))
                                : root.outputMode
                                    ? (RaohaneAudio.sinkName || qsTr("No output device"))
                                    : (RaohaneAudio.sourceName || qsTr("No input device"))
                            color: RaohaneTheme.text
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.wifiMode
                                ? (RaohaneNetwork.wifiConnected
                                    ? qsTr("Connected · %1% signal").arg(RaohaneNetwork.networkStrength)
                                    : qsTr("Available networks nearby"))
                                : root.outputMode
                                    ? qsTr("Default playback device")
                                    : qsTr("Default recording device")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 7
                            elide: Text.ElideRight
                        }
                    }

                    RaohaneIcon {
                        text: "check_circle"
                        visible: parent.parent.active
                        iconSize: 16
                        fill: 1
                        color: RaohaneTheme.success
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                visible: root.wifiMode ? RaohaneNetwork.wifiEnabled : true

                Repeater {
                    model: root.visibleEntries

                    DeviceRow {
                        required property var modelData
                        Layout.fillWidth: true
                        entry: modelData
                        onTriggered: root.selectEntry(entry)
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.visibleEntries.length === 0 && !root.busy
                    text: root.wifiMode ? qsTr("No Wi-Fi networks found") : qsTr("No devices found")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 8
                    horizontalAlignment: Text.AlignHCenter
                    Layout.topMargin: 9
                    Layout.bottomMargin: 9
                }
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: root.selectedWifi.length > 0 ? 92 : 0
                visible: root.wifiMode && root.selectedWifi.length > 0
                surfaceRadius: 14
                raised: false
                showSheen: false
                active: true
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 7

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 7
                        RaohaneIcon { text: "lock"; iconSize: 14; color: RaohaneTheme.accent }
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Password for %1").arg(root.selectedWifi)
                            color: RaohaneTheme.text
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        RaohaneIconButton {
                            buttonSize: 24
                            iconSize: 12
                            icon: "close"
                            transparentIdle: true
                            showSheen: false
                            onClicked: {
                                root.selectedWifi = ""
                                root.wifiPassword = ""
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 7

                        RaohaneSurface {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            surfaceRadius: 10
                            raised: false
                            showSheen: false
                            border.color: passwordField.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.border

                            TextInput {
                                id: passwordField
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                text: root.wifiPassword
                                echoMode: TextInput.Password
                                color: RaohaneTheme.text
                                selectionColor: RaohaneTheme.accentSoft
                                selectedTextColor: RaohaneTheme.text
                                font.pixelSize: 9
                                clip: true
                                onTextChanged: root.wifiPassword = text
                                Keys.onReturnPressed: connectButton.trigger()
                                Keys.onEnterPressed: connectButton.trigger()

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    visible: passwordField.text.length === 0 && !passwordField.activeFocus
                                    text: qsTr("Enter Wi-Fi password")
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 8
                                }
                            }
                        }

                        ActionButton {
                            id: connectButton
                            icon: "arrow_forward"
                            label: qsTr("Connect")
                            enabled: root.wifiPassword.length > 0 && RaohaneNetwork.connectingSsid.length === 0
                            onTriggered: {
                                RaohaneNetwork.connectNetwork(root.selectedWifi, root.wifiPassword)
                                root.selectedWifi = ""
                                root.wifiPassword = ""
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.wifiMode && RaohaneNetwork.lastActionError.length > 0
                text: qsTr("Could not connect to this network")
                color: RaohaneTheme.critical
                font.pixelSize: 7
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    component DeviceRow: RaohaneSurface {
        id: row
        required property var entry
        signal triggered()

        Layout.preferredHeight: 43
        surfaceRadius: 12
        raised: false
        showSheen: false
        transparentIdle: !rowActive
        active: rowActive
        hovered: rowMouse.containsMouse || activeFocus
        pressed: rowMouse.pressed
        interactive: true
        feedback: rowActive ? "tap" : "navigate"

        readonly property bool rowActive: root.wifiMode
            ? Boolean(entry.active)
            : Boolean(entry.active)
        readonly property bool waiting: root.wifiMode
            && RaohaneNetwork.connectingSsid === String(entry.ssid ?? "")

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            RaohaneIcon {
                text: root.wifiMode
                    ? RaohaneNetwork.signalIcon(row.entry.strength)
                    : root.outputMode ? "speaker" : "mic"
                iconSize: 16
                fill: row.rowActive ? 1 : 0
                color: row.rowActive || row.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: root.wifiMode ? String(row.entry.ssid ?? "") : String(row.entry.name ?? "")
                    color: RaohaneTheme.text
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.wifiMode
                        ? (row.entry.secure ? qsTr("Secured network") : qsTr("Open network"))
                        : (row.rowActive ? qsTr("Currently selected") : qsTr("Available device"))
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 7
                    elide: Text.ElideRight
                }
            }

            Text {
                visible: root.wifiMode
                text: String(Math.round(Number(row.entry.strength) || 0)) + "%"
                color: row.rowActive ? RaohaneTheme.accent : RaohaneTheme.textFaint
                font.pixelSize: 7
                font.weight: Font.DemiBold
            }

            RaohaneIcon {
                text: row.waiting ? "sync" : row.rowActive ? "check" : (root.wifiMode && row.entry.secure ? "lock" : "chevron_right")
                iconSize: 14
                fill: row.rowActive ? 1 : 0
                color: row.rowActive ? RaohaneTheme.accent : RaohaneTheme.textFaint

                RotationAnimation on rotation {
                    running: row.waiting
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 850
                }
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: !row.waiting
            onClicked: row.triggered()
        }
    }

    component ActionButton: RaohaneSurface {
        id: action
        required property string icon
        required property string label
        signal triggered()

        Layout.preferredWidth: 94
        Layout.preferredHeight: 32
        surfaceRadius: 10
        active: true
        showSheen: false
        hovered: actionMouse.containsMouse
        pressed: actionMouse.pressed
        interactive: true
        feedback: "confirm"

        RowLayout {
            anchors.centerIn: parent
            spacing: 5
            RaohaneIcon { text: action.icon; iconSize: 13; color: RaohaneTheme.accent }
            Text { text: action.label; color: RaohaneTheme.text; font.pixelSize: 8; font.weight: Font.DemiBold }
        }

        function trigger(): void {
            if (action.enabled)
                action.triggered()
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: action.enabled
            cursorShape: action.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: action.trigger()
        }
    }
}
