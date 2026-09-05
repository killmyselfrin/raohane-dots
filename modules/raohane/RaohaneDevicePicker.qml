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

    implicitHeight: mode.length > 0 ? pickerContent.implicitHeight + 22 : 0
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
        surfaceRadius: 12
        raised: false
        showSheen: false
        color: RaohaneTheme.surfaceDeep
        border.color: RaohaneTheme.borderStrong
        clip: true

        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                leftMargin: 12
                rightMargin: 12
            }
            height: 1
            color: RaohaneTheme.accent
            opacity: 0.44
        }

        ColumnLayout {
            id: pickerContent
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 11
                rightMargin: 11
                topMargin: 10
            }
            spacing: 7

            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                Rectangle {
                    Layout.preferredWidth: 2
                    Layout.preferredHeight: 28
                    radius: 1
                    color: RaohaneTheme.accent
                }

                RaohaneIcon {
                    text: root.headerIcon
                    iconSize: 17
                    fill: 1
                    color: RaohaneTheme.accent
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: root.title
                        color: RaohaneTheme.text
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.subtitle
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 6
                        elide: Text.ElideRight
                    }
                }

                RaohaneSwitch {
                    visible: root.wifiMode
                    checked: RaohaneNetwork.wifiEnabled
                    onToggled: checked => RaohaneNetwork.setWifiEnabled(checked)
                }

                RaohaneIconButton {
                    buttonSize: 27
                    iconSize: 13
                    icon: "refresh"
                    transparentIdle: true
                    showSheen: false
                    hoverScale: 1
                    pressedScale: 1
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
                    buttonSize: 27
                    iconSize: 13
                    icon: "close"
                    transparentIdle: true
                    showSheen: false
                    hoverScale: 1
                    pressedScale: 1
                    onClicked: root.closeRequested()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: RaohaneTheme.borderFaint
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 43
                surfaceRadius: 9
                raised: false
                showSheen: false
                color: RaohaneTheme.surfaceSubtle
                active: root.wifiMode ? RaohaneNetwork.wifiConnected
                    : root.outputMode ? RaohaneAudio.ready
                    : RaohaneAudio.microphoneReady

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 9
                    anchors.rightMargin: 9
                    spacing: 7

                    Rectangle {
                        width: 5
                        height: 5
                        radius: 2.5
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
                            font.pixelSize: 8
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
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 6
                            elide: Text.ElideRight
                        }
                    }

                    RaohaneIcon {
                        text: "check_circle"
                        visible: parent.parent.active
                        iconSize: 14
                        fill: 1
                        color: RaohaneTheme.success
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
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
                    font.pixelSize: 7
                    horizontalAlignment: Text.AlignHCenter
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                }
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: root.selectedWifi.length > 0 ? 84 : 0
                visible: root.wifiMode && root.selectedWifi.length > 0
                surfaceRadius: 9
                raised: false
                showSheen: false
                active: true
                color: RaohaneTheme.surfaceSubtle
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        RaohaneIcon { text: "lock"; iconSize: 13; color: RaohaneTheme.accent }
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Password for %1").arg(root.selectedWifi)
                            color: RaohaneTheme.text
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        RaohaneIconButton {
                            buttonSize: 23
                            iconSize: 11
                            icon: "close"
                            transparentIdle: true
                            showSheen: false
                            hoverScale: 1
                            pressedScale: 1
                            onClicked: {
                                root.selectedWifi = ""
                                root.wifiPassword = ""
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        RaohaneSurface {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            surfaceRadius: 8
                            raised: false
                            showSheen: false
                            color: RaohaneTheme.surfaceDeep
                            border.color: passwordField.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                            TextInput {
                                id: passwordField
                                anchors.fill: parent
                                anchors.leftMargin: 9
                                anchors.rightMargin: 9
                                verticalAlignment: TextInput.AlignVCenter
                                text: root.wifiPassword
                                echoMode: TextInput.Password
                                color: RaohaneTheme.text
                                selectionColor: RaohaneTheme.accentSoft
                                selectedTextColor: RaohaneTheme.text
                                font.pixelSize: 8
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
                                    font.pixelSize: 7
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
                font.pixelSize: 6
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    component DeviceRow: RaohaneSurface {
        id: row
        required property var entry
        signal triggered()

        Layout.preferredHeight: 38
        surfaceRadius: 8
        raised: false
        showSheen: false
        transparentIdle: !rowActive && !hovered
        active: rowActive
        hovered: rowMouse.containsMouse || activeFocus
        pressed: rowMouse.pressed
        interactive: true
        feedback: rowActive ? "tap" : "navigate"
        hoverScale: 1
        pressedScale: 1
        border.color: rowActive ? RaohaneTheme.accentBorder
            : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

        readonly property bool rowActive: root.wifiMode
            ? Boolean(entry.active)
            : Boolean(entry.active)
        readonly property bool waiting: root.wifiMode
            && RaohaneNetwork.connectingSsid === String(entry.ssid ?? "")

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: 2
                topMargin: 7
                bottomMargin: 7
            }
            width: 2
            radius: 1
            color: RaohaneTheme.accent
            opacity: row.rowActive ? 1 : row.hovered ? 0.42 : 0
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 9
            spacing: 7

            RaohaneIcon {
                text: root.wifiMode
                    ? RaohaneNetwork.signalIcon(row.entry.strength)
                    : root.outputMode ? "speaker" : "mic"
                iconSize: 14
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
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.wifiMode
                        ? (row.entry.secure ? qsTr("Secured network") : qsTr("Open network"))
                        : (row.rowActive ? qsTr("Currently selected") : qsTr("Available device"))
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 6
                    elide: Text.ElideRight
                }
            }

            Text {
                visible: root.wifiMode
                text: String(Math.round(Number(row.entry.strength) || 0)) + "%"
                color: row.rowActive ? RaohaneTheme.accent : RaohaneTheme.textFaint
                font.pixelSize: 6
                font.weight: Font.DemiBold
            }

            RaohaneIcon {
                text: row.waiting ? "sync" : row.rowActive ? "check" : (root.wifiMode && row.entry.secure ? "lock" : "chevron_right")
                iconSize: 13
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

        Layout.preferredWidth: 88
        Layout.preferredHeight: 30
        surfaceRadius: 8
        active: true
        showSheen: false
        hovered: actionMouse.containsMouse
        pressed: actionMouse.pressed
        interactive: true
        feedback: "confirm"
        hoverScale: 1
        pressedScale: 1

        RowLayout {
            anchors.centerIn: parent
            spacing: 5
            RaohaneIcon { text: action.icon; iconSize: 12; color: RaohaneTheme.accent }
            Text { text: action.label; color: RaohaneTheme.text; font.pixelSize: 7; font.weight: Font.DemiBold }
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
