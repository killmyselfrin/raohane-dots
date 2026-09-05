import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.models
import qs.modules.raohane.services

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    readonly property var results: RaohaneSearch.results.slice(0, 9)
    readonly property var idleActions: RaohaneSearch.actionResults("").slice(0, 6)
    readonly property string currentMode: {
        const value = String(RaohaneSearch.query ?? "").replace(/^\s+/, "")
        if (value.startsWith("/"))
            return "action"
        if (value.startsWith(">"))
            return "command"
        if (value.startsWith(":"))
            return "clipboard"
        if (value.startsWith("="))
            return "calculator"
        return "app"
    }

    RaohaneSelectionModel {
        id: selection
        count: root.results.length
    }

    function close(): void {
        RaohaneState.setPrimaryOpen("launcher", false)
    }

    function reset(): void {
        selection.reset()
        RaohaneSearch.query = ""
    }

    function stripMode(value): string {
        const current = String(value ?? "").replace(/^\s+/, "")
        if (current.startsWith("/") || current.startsWith(">") || current.startsWith(":") || current.startsWith("="))
            return current.slice(1).replace(/^\s+/, "")
        return current
    }

    function setMode(prefix: string): void {
        const body = root.stripMode(RaohaneSearch.query)
        RaohaneSearch.query = prefix + body
        selection.reset()
        searchInput.forceActiveFocus()
    }

    function executeSelected(): void {
        if (!selection.hasItems)
            return
        const result = root.results[selection.currentIndex]
        if (!result || !result.execute)
            return
        root.close()
        result.execute()
    }

    PanelWindow {
        id: panelWindow

        visible: RaohaneState.launcherOpen
        screen: root.focusedScreen
        exclusiveZone: 0
        implicitWidth: 612
        implicitHeight: Math.min(620, launcherSurface.implicitHeight + 18)
        color: "transparent"

        WlrLayershell.namespace: "quickshell:raohane-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: RaohaneState.launcherOpen
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

        anchors {
            top: true
            left: true
            right: true
        }
        margins.top: 82

        onVisibleChanged: {
            if (visible) {
                root.reset()
                launcherSurface.entered = false
                Qt.callLater(() => launcherSurface.entered = true)
                RaohaneFocusGrab.addDismissable(panelWindow)
                searchInput.forceActiveFocus()
            } else {
                launcherSurface.entered = false
                RaohaneFocusGrab.removeDismissable(panelWindow)
            }
        }

        Connections {
            target: RaohaneFocusGrab
            function onDismissed(): void { root.close() }
        }

        RaohaneSurface {
            id: launcherSurface
            property bool entered: false

            anchors.horizontalCenter: parent.horizontalCenter
            width: 572
            implicitHeight: content.implicitHeight + 28
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            clip: true
            opacity: entered ? 1 : 0
            scale: entered ? 1 : 0.985
            y: entered ? 0 : -10

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
            }
            Behavior on scale {
                NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
            }
            Behavior on y {
                NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
            }

            ColumnLayout {
                id: content

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 14
                }
                spacing: 9

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    spacing: 9

                    RaohaneSurface {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        surfaceRadius: 11
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "spa"
                            iconSize: 17
                            fill: 1
                            symbolWeight: 560
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: -1

                        Text {
                            text: "Raohane"
                            color: RaohaneTheme.text
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.4
                        }

                        Text {
                            text: qsTr("apps · actions · commands · clipboard")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                        }
                    }

                    RaohaneSurface {
                        implicitWidth: escText.implicitWidth + 16
                        implicitHeight: 24
                        surfaceRadius: 8
                        transparentIdle: false
                        showSheen: false

                        Text {
                            id: escText
                            anchors.centerIn: parent
                            text: "ESC"
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.5
                        }
                    }
                }

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 54
                    surfaceRadius: 16
                    raised: true
                    hovered: searchInput.activeFocus
                    showSheen: false
                    border.color: searchInput.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.borderStrong

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        RaohaneIcon {
                            text: "search"
                            iconSize: 18
                            fill: searchInput.activeFocus ? 1 : 0
                            symbolWeight: searchInput.activeFocus ? 540 : 430
                            color: searchInput.activeFocus ? RaohaneTheme.accent : RaohaneTheme.textMuted
                        }

                        TextInput {
                            id: searchInput

                            Layout.fillWidth: true
                            color: RaohaneTheme.text
                            selectionColor: RaohaneTheme.accentSoft
                            selectedTextColor: RaohaneTheme.text
                            font.pixelSize: 14
                            clip: true
                            text: RaohaneSearch.query

                            onTextChanged: {
                                if (RaohaneSearch.query !== text)
                                    RaohaneSearch.query = text
                                selection.reset()
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    root.close()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Down) {
                                    selection.move(1)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Up) {
                                    selection.move(-1)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.executeSelected()
                                    event.accepted = true
                                }
                            }
                        }

                        RaohaneIcon {
                            visible: searchInput.text.length > 0
                            text: "backspace"
                            iconSize: 15
                            color: clearMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textFaint

                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                anchors.margins: -8
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.reset()
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    ModeChip {
                        label: qsTr("App")
                        icon: "apps"
                        prefix: ""
                        selected: root.currentMode === "app"
                    }
                    ModeChip {
                        label: qsTr("Raohane action")
                        icon: "bolt"
                        prefix: "/"
                        selected: root.currentMode === "action"
                    }
                    ModeChip {
                        label: qsTr("Shell command")
                        icon: "terminal"
                        prefix: ">"
                        selected: root.currentMode === "command"
                    }
                    ModeChip {
                        label: qsTr("Clipboard")
                        icon: "content_paste"
                        prefix: ":"
                        selected: root.currentMode === "clipboard"
                    }

                    Item { Layout.fillWidth: true }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 7
                    visible: RaohaneSearch.query.trim().length === 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 2
                        Layout.rightMargin: 2

                        Text {
                            text: qsTr("Search Raohane")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "/  >  =  :"
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 7
                        rowSpacing: 7

                        Repeater {
                            model: root.idleActions

                            delegate: RaohaneSurface {
                                id: idleAction
                                required property var modelData

                                Layout.fillWidth: true
                                Layout.preferredHeight: 54
                                surfaceRadius: 14
                                showSheen: false
                                raised: false
                                hovered: idleActionMouse.containsMouse
                                pressed: idleActionMouse.pressed
                                interactive: true
                                hoverScale: 1.004
                                pressedScale: 0.992
                                border.color: hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 9

                                    RaohaneSurface {
                                        Layout.preferredWidth: 32
                                        Layout.preferredHeight: 32
                                        surfaceRadius: 10
                                        active: idleAction.hovered
                                        showSheen: false

                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: idleAction.modelData.iconName
                                            iconSize: 16
                                            fill: idleAction.hovered ? 1 : 0
                                            symbolWeight: idleAction.hovered ? 540 : 430
                                            color: idleAction.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        Text {
                                            Layout.fillWidth: true
                                            text: idleAction.modelData.name
                                            color: RaohaneTheme.text
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: idleAction.modelData.type
                                            color: RaohaneTheme.textFaint
                                            font.pixelSize: 7
                                            elide: Text.ElideRight
                                        }
                                    }

                                    RaohaneIcon {
                                        text: "arrow_outward"
                                        iconSize: 12
                                        color: idleAction.hovered ? RaohaneTheme.accent : RaohaneTheme.textFaint
                                    }
                                }

                                MouseArea {
                                    id: idleActionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.close()
                                        idleAction.modelData.execute()
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: root.results.length > 0

                    Repeater {
                        model: root.results

                        delegate: RaohaneSurface {
                            id: resultRow
                            required property var modelData
                            required property int index

                            readonly property bool selected: index === selection.currentIndex

                            Layout.fillWidth: true
                            Layout.preferredHeight: 49
                            surfaceRadius: 13
                            active: selected
                            hovered: resultMouse.containsMouse || activeFocus
                            pressed: resultMouse.pressed
                            interactive: true
                            transparentIdle: !selected && !hovered
                            showSheen: false
                            hoverScale: 1.003
                            pressedScale: 0.992
                            activeFocusOnTab: true

                            Rectangle {
                                visible: resultRow.selected
                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 3
                                }
                                width: 2
                                height: 20
                                radius: 1
                                color: RaohaneTheme.accent
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 11
                                spacing: 9

                                RaohaneSurface {
                                    Layout.preferredWidth: 31
                                    Layout.preferredHeight: 31
                                    surfaceRadius: 10
                                    active: resultRow.selected
                                    showSheen: false

                                    Loader {
                                        anchors.centerIn: parent
                                        width: 25
                                        height: 25
                                        sourceComponent: {
                                            if (resultRow.modelData.iconType === "system")
                                                return systemIcon
                                            if (resultRow.modelData.iconType === "material")
                                                return materialIcon
                                            if (resultRow.modelData.iconType === "text")
                                                return textIcon
                                            return fallbackIcon
                                        }
                                    }

                                    Component {
                                        id: systemIcon
                                        RaohaneAdaptiveIcon {
                                            anchors.centerIn: parent
                                            iconSource: String(resultRow.modelData.iconName ?? "")
                                            iconSize: 23
                                            fallbackColor: resultRow.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                        }
                                    }

                                    Component {
                                        id: materialIcon
                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: resultRow.modelData.iconName
                                            iconSize: 17
                                            fill: resultRow.selected ? 1 : 0
                                            symbolWeight: resultRow.selected ? 540 : 430
                                            color: resultRow.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                        }
                                    }

                                    Component {
                                        id: textIcon
                                        Text {
                                            anchors.centerIn: parent
                                            text: resultRow.modelData.iconName
                                            color: resultRow.selected ? RaohaneTheme.accent : RaohaneTheme.text
                                            font.pixelSize: 15
                                        }
                                    }

                                    Component {
                                        id: fallbackIcon
                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: "apps"
                                            iconSize: 16
                                            color: RaohaneTheme.textMuted
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        text: resultRow.modelData.name
                                        color: RaohaneTheme.text
                                        font.pixelSize: 9
                                        font.weight: resultRow.selected ? Font.DemiBold : Font.Medium
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: resultRow.modelData.comment || resultRow.modelData.type
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: 7
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    text: resultRow.modelData.verb
                                    color: resultRow.selected ? RaohaneTheme.accent : RaohaneTheme.textFaint
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.4
                                }
                            }

                            MouseArea {
                                id: resultMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPressed: resultRow.forceActiveFocus()
                                onEntered: selection.select(resultRow.index)
                                onClicked: {
                                    selection.select(resultRow.index)
                                    root.executeSelected()
                                }
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                    selection.select(resultRow.index)
                                    root.executeSelected()
                                    event.accepted = true
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 92
                    visible: RaohaneSearch.query.trim().length > 0 && root.results.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("No results")
                            color: RaohaneTheme.text
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("/ actions    > commands    = math    : clipboard")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.borderFaint
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    Layout.leftMargin: 2
                    Layout.rightMargin: 2

                    Text {
                        text: "RAOHANE"
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 7
                        font.letterSpacing: 1.1
                        font.weight: Font.DemiBold
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "↑↓ navigate   ↵ open"
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 7
                    }
                }
            }
        }
    }

    component ModeChip: RaohaneSurface {
        id: chip

        required property string label
        required property string icon
        required property string prefix
        property bool selected: false

        Layout.preferredWidth: chipRow.implicitWidth + 18
        Layout.preferredHeight: 30
        surfaceRadius: 10
        active: selected
        hovered: chipMouse.containsMouse
        pressed: chipMouse.pressed
        interactive: true
        transparentIdle: !selected && !hovered
        showSheen: false
        hoverScale: 1.003
        pressedScale: 0.992

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 5

            RaohaneIcon {
                text: chip.icon
                iconSize: 12
                fill: chip.selected ? 1 : 0
                symbolWeight: chip.selected ? 540 : 430
                color: chip.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: chip.label
                color: chip.selected ? RaohaneTheme.text : RaohaneTheme.textMuted
                font.pixelSize: 7
                font.weight: chip.selected ? Font.DemiBold : Font.Medium
            }
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.setMode(chip.prefix)
        }
    }

    IpcHandler {
        target: "raohaneLauncher"
        function toggle(): void { RaohaneState.togglePrimary("launcher") }
        function open(): void { RaohaneState.setPrimaryOpen("launcher", true) }
        function close(): void { RaohaneState.setPrimaryOpen("launcher", false) }
    }

    CompositorGlobalShortcut {
        name: "raohaneLauncherToggle"
        description: "Toggles the Raohane launcher"
        onPressed: RaohaneState.togglePrimary("launcher")
    }
}
