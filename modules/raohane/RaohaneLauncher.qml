import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.config
import qs.modules.raohane.models
import qs.modules.raohane.services

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    readonly property var results: RaohaneSearch.results.slice(0, 8)
    readonly property var idleActions: RaohaneSearch.actionResults("").slice(0, 6)
    readonly property var pinnedApps: {
        const pinnedIds = Array.from(RaohaneConfig.dockPinnedApps ?? []).slice(0, 6)
        const entries = pinnedIds
            .map(id => DesktopEntries.byId(String(id)) ?? DesktopEntries.heuristicLookup(String(id)))
            .filter(entry => !!entry)
        return entries.length > 0 ? entries : RaohaneSearch.applications.slice(0, 6)
    }
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

    function executePinned(entry): void {
        if (!entry)
            return
        root.close()
        RaohaneSearch.executeApplication(entry)
    }

    PanelWindow {
        id: panelWindow

        visible: RaohaneState.launcherOpen
        screen: root.focusedScreen
        exclusiveZone: 0
        implicitWidth: 716
        implicitHeight: Math.min(690, launcherSurface.implicitHeight + 22)
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
        margins.top: 84

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
            width: 680
            implicitHeight: content.implicitHeight + 30
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: true
            showSheen: true
            border.color: RaohaneTheme.borderStrong
            clip: true
            opacity: entered ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
            }

            ColumnLayout {
                id: content

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 15
                }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    spacing: 9

                    RaohaneSurface {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        surfaceRadius: 14
                        raised: false
                        hovered: searchInput.activeFocus
                        showSheen: false
                        border.color: searchInput.activeFocus
                            ? RaohaneTheme.accentBorder
                            : RaohaneTheme.borderStrong

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 13
                            anchors.rightMargin: 10
                            spacing: 9

                            RaohaneIcon {
                                text: "search"
                                iconSize: 19
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
                                font.pixelSize: 12
                                clip: true
                                text: RaohaneSearch.query

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: searchInput.text.length === 0
                                    text: qsTr("Search Raohane")
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 10
                                }

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

                            RaohaneIconButton {
                                visible: searchInput.text.length > 0
                                buttonSize: 30
                                iconSize: 14
                                icon: "backspace"
                                transparentIdle: true
                                showSheen: false
                                hoverScale: 1
                                pressedScale: 1
                                onClicked: root.reset()
                            }
                        }
                    }

                    RaohaneIconButton {
                        buttonSize: 48
                        iconSize: 19
                        icon: "settings"
                        transparentIdle: false
                        showSheen: false
                        hoverScale: 1
                        pressedScale: 1
                        onClicked: {
                            root.close()
                            RaohaneState.setPrimaryOpen("settings", true)
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    ModeChip {
                        Layout.fillWidth: true
                        label: qsTr("Apps")
                        icon: "apps"
                        prefix: ""
                        selected: root.currentMode === "app"
                    }
                    ModeChip {
                        Layout.fillWidth: true
                        label: qsTr("Actions")
                        icon: "bolt"
                        prefix: "/"
                        selected: root.currentMode === "action"
                    }
                    ModeChip {
                        Layout.fillWidth: true
                        label: qsTr("Commands")
                        icon: "terminal"
                        prefix: ">"
                        selected: root.currentMode === "command"
                    }
                    ModeChip {
                        Layout.fillWidth: true
                        label: qsTr("Math")
                        icon: "calculate"
                        prefix: "="
                        selected: root.currentMode === "calculator"
                    }
                    ModeChip {
                        Layout.fillWidth: true
                        label: qsTr("Clipboard")
                        icon: "content_paste"
                        prefix: ":"
                        selected: root.currentMode === "clipboard"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: RaohaneSearch.query.trim().length === 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 3
                        Layout.rightMargin: 3

                        Text {
                            text: qsTr("Pinned")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.6
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: qsTr("Dock apps")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: root.pinnedApps

                            delegate: PinnedApp {
                                required property var modelData
                                Layout.fillWidth: true
                                entry: modelData
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        Layout.topMargin: 3
                        color: RaohaneTheme.borderFaint
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 3
                        Layout.rightMargin: 3

                        Text {
                            text: qsTr("Quick access")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.6
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
                        columnSpacing: 8
                        rowSpacing: 8

                        Repeater {
                            model: root.idleActions

                            delegate: RaohaneSurface {
                                id: idleAction
                                required property var modelData

                                Layout.fillWidth: true
                                Layout.preferredHeight: 58
                                surfaceRadius: 13
                                showSheen: false
                                raised: false
                                hovered: idleActionMouse.containsMouse || activeFocus
                                pressed: idleActionMouse.pressed
                                interactive: true
                                hoverScale: 1
                                pressedScale: 1
                                activeFocusOnTab: true
                                border.color: hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

                                Rectangle {
                                    visible: idleAction.hovered
                                    anchors {
                                        left: parent.left
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 2
                                    }
                                    width: 3
                                    height: 24
                                    radius: 2
                                    color: RaohaneTheme.accent
                                    opacity: 0.72
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 11
                                    anchors.rightMargin: 11
                                    spacing: 10

                                    RaohaneSurface {
                                        Layout.preferredWidth: 34
                                        Layout.preferredHeight: 34
                                        surfaceRadius: 10
                                        active: idleAction.hovered
                                        showSheen: false

                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: idleAction.modelData.iconName
                                            iconSize: 17
                                            fill: idleAction.hovered ? 1 : 0
                                            symbolWeight: idleAction.hovered ? 540 : 430
                                            color: idleAction.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

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
                                    onPressed: idleAction.forceActiveFocus()
                                    onClicked: {
                                        root.close()
                                        idleAction.modelData.execute()
                                    }
                                }

                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                        root.close()
                                        idleAction.modelData.execute()
                                        event.accepted = true
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    visible: RaohaneSearch.query.trim().length > 0 && root.results.length > 0

                    Repeater {
                        model: root.results

                        delegate: RaohaneSurface {
                            id: resultRow
                            required property var modelData
                            required property int index

                            readonly property bool selected: index === selection.currentIndex

                            Layout.fillWidth: true
                            Layout.preferredHeight: 55
                            surfaceRadius: 12
                            active: selected
                            hovered: resultMouse.containsMouse || activeFocus
                            pressed: resultMouse.pressed
                            interactive: true
                            transparentIdle: !selected && !hovered
                            showSheen: false
                            hoverScale: 1
                            pressedScale: 1
                            activeFocusOnTab: true

                            Rectangle {
                                visible: resultRow.selected
                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 2
                                }
                                width: 3
                                height: 24
                                radius: 2
                                color: RaohaneTheme.accent
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 11
                                anchors.rightMargin: 12
                                spacing: 10

                                RaohaneSurface {
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 36
                                    surfaceRadius: 10
                                    active: resultRow.selected
                                    showSheen: false

                                    Loader {
                                        anchors.centerIn: parent
                                        width: 28
                                        height: 28
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
                                            iconSize: 25
                                            fallbackColor: resultRow.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                        }
                                    }

                                    Component {
                                        id: materialIcon
                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: resultRow.modelData.iconName
                                            iconSize: 18
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
                                            iconSize: 17
                                            color: RaohaneTheme.textMuted
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

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
                    Layout.preferredHeight: 100
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
                    Layout.preferredHeight: 22
                    Layout.leftMargin: 3
                    Layout.rightMargin: 3

                    Text {
                        text: "RAOHANE"
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 7
                        font.letterSpacing: 1.2
                        font.weight: Font.DemiBold
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "↑↓ navigate   ↵ open   esc close"
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

        Layout.preferredHeight: 34
        surfaceRadius: 10
        active: selected
        hovered: chipMouse.containsMouse || activeFocus
        pressed: chipMouse.pressed
        interactive: true
        transparentIdle: !selected && !hovered
        showSheen: false
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: true

        Row {
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
            onPressed: chip.forceActiveFocus()
            onClicked: root.setMode(chip.prefix)
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.setMode(chip.prefix)
                event.accepted = true
            }
        }
    }

    component PinnedApp: RaohaneSurface {
        id: app

        required property var entry

        Layout.preferredHeight: 76
        surfaceRadius: 13
        transparentIdle: !app.hovered
        showSheen: false
        interactive: true
        hovered: appMouse.containsMouse || activeFocus
        pressed: appMouse.pressed
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: true

        Column {
            anchors.centerIn: parent
            width: Math.max(50, app.width - 12)
            spacing: 5

            RaohaneSurface {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 40
                height: 40
                surfaceRadius: 12
                active: app.hovered
                showSheen: false

                RaohaneAdaptiveIcon {
                    anchors.centerIn: parent
                    iconSource: String(app.entry?.icon ?? "")
                    iconSize: 29
                    fallbackColor: app.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }
            }

            Text {
                width: parent.width
                text: String(app.entry?.name ?? "App")
                color: app.hovered ? RaohaneTheme.text : RaohaneTheme.textMuted
                font.pixelSize: 7
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: appMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: app.forceActiveFocus()
            onClicked: root.executePinned(app.entry)
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.executePinned(app.entry)
                event.accepted = true
            }
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
