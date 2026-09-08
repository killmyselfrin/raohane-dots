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
        surfaceRadius: 14
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
                leftMargin: 14
                rightMargin: 14
            }
            height: 2
            radius: 1
            color: RaohaneTheme.accent
            opacity: 0.48
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
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 9

                Rectangle {
                    Layout.preferredWidth: 3
                    Layout.preferredHeight: 32
                    radius: 2
                    color: RaohaneTheme.accent
                }

                RaohaneSurface {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    surfaceRadius: 11
                    raised: false
                    active: true
                    showSheen: false

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: root.headerIcon
                        iconSize: 19
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
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.subtitle
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                        elide: Text.ElideRight
                    }
                }

                RaohaneSwitch {
                    visible: root.wifiMode
                    checked: RaohaneNetwork.wifiEnabled
                    onToggled: checked => RaohaneNetwork.setWifiEnabled(checked)
                }

                RaohaneIconButton {
                    buttonSize: 30
                    iconSize: 14
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
                    buttonSize: 30
                    iconSize: 14
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
                Layout.preferredHeight: 52
                surfaceRadius: 11
                raised: false
                showSheen: false
                color: RaohaneTheme.surfaceSubtle
                active: root.wifiMode ? RaohaneNetwork.wifiConnected
                    : root.outputMode ? RaohaneAudio.ready
                    : RaohaneAudio.microphoneReady

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 11
                    anchors.rightMargin: 11
                    spacing: 9

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: parent.parent.active ? RaohaneTheme.success : RaohaneTheme.textFaint
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

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
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                            elide: Text.ElideRight
                        }
                    }

                    RaohaneIcon {
                        text: "check_circle"
                        visible: parent.parent.active
                        iconSize: 15
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
                Layout.preferredHeight: root.selectedWifi.length > 0 ? 96 : 0
                visible: root.wifiMode && root.selectedWifi.length > 0
                surfaceRadius: 11
                raised: false
                showSheen: false
                active: true
                color: RaohaneTheme.surfaceSubtle
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 8

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
                            buttonSize: 26
                            iconSize: 12
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
                        spacing: 8

                        RaohaneSurface {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            surfaceRadius: 9
                            raised: false
                            showSheen: false
                            color: RaohaneTheme.surfaceDeep
                            border.color: passwordField.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

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

        Layout.preferredHeight: 46
        surfaceRadius: 10
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
        activeFocusOnTab: !row.waiting
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
                topMargin: 8
                bottomMargin: 8
            }
            width: 3
            radius: 2
            color: RaohaneTheme.accent
            opacity: row.rowActive ? 1 : row.hovered ? 0.46 : 0
        }

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
                spacing: 1

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
                    color: RaohaneTheme.textFaint
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
            onPressed: row.forceActiveFocus()
            onClicked: row.triggered()
        }

        Keys.onPressed: event => {
            if (row.waiting)
                return
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                row.triggered()
                event.accepted = true
            }
        }
    }

    component ActionButton: FocusScope {
        id: action
        required property string icon
        required property string label
        signal triggered()

        Layout.preferredWidth: 96
        Layout.preferredHeight: 34
        activeFocusOnTab: true
        opacity: enabled ? 1 : 0.45

        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: 9
            active: true
            showSheen: false
            hovered: actionMouse.containsMouse || action.activeFocus
            pressed: actionMouse.pressed
            interactive: true
            feedback: "confirm"
            hoverScale: 1
            pressedScale: 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                RaohaneIcon { text: action.icon; iconSize: 13; color: RaohaneTheme.accent }
                Text { text: action.label; color: RaohaneTheme.text; font.pixelSize: 8; font.weight: Font.DemiBold }
            }
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
            onPressed: action.forceActiveFocus()
            onClicked: action.trigger()
        }

        Keys.onPressed: event => {
            if (!action.enabled)
                return
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                action.trigger()
                event.accepted = true
            }
        }
    }
}
