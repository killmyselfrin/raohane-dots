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
        implicitWidth: 626
        implicitHeight: Math.min(610, launcherSurface.implicitHeight + 18)
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
        margins.top: 88

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
            width: 592
            implicitHeight: content.implicitHeight + 24
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
                    margins: 12
                }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    spacing: 7

                    RaohaneSurface {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        surfaceRadius: 12
                        raised: false
                        hovered: searchInput.activeFocus
                        showSheen: false
                        border.color: searchInput.activeFocus
                            ? RaohaneTheme.accentBorder
                            : RaohaneTheme.borderStrong

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 11
                            anchors.rightMargin: 8
                            spacing: 8

                            RaohaneIcon {
                                text: "search"
                                iconSize: 17
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
                                font.pixelSize: 11
                                clip: true
                                text: RaohaneSearch.query

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: searchInput.text.length === 0
                                    text: qsTr("Search Raohane")
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 9
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
                                buttonSize: 26
                                iconSize: 13
                                icon: "backspace"
                                transparentIdle: true
                                showSheen: false
                                onClicked: root.reset()
                            }
                        }
                    }

                    RaohaneIconButton {
                        buttonSize: 42
                        iconSize: 17
                        icon: "settings"
                        transparentIdle: false
                        showSheen: false
                        onClicked: {
                            root.close()
                            RaohaneState.setPrimaryOpen("settings", true)
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5

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
                    spacing: 8
                    visible: RaohaneSearch.query.trim().length === 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 2
                        Layout.rightMargin: 2

                        Text {
                            text: qsTr("Pinned")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.5
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: qsTr("Dock apps")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 6
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 7

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
                        Layout.topMargin: 2
                        color: RaohaneTheme.borderFaint
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 2
                        Layout.rightMargin: 2

                        Text {
                            text: qsTr("Quick access")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.5
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "/  >  =  :"
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
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
                                Layout.preferredHeight: 49
                                surfaceRadius: 12
                                showSheen: false
                                raised: false
                                hovered: idleActionMouse.containsMouse
                                pressed: idleActionMouse.pressed
                                interactive: true
                                hoverScale: 1
                                pressedScale: 1
                                border.color: hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

                                Rectangle {
                                    visible: idleAction.hovered
                                    anchors {
                                        left: parent.left
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 2
                                    }
                                    width: 2
                                    height: 18
                                    radius: 1
                                    color: RaohaneTheme.accent
                                    opacity: 0.70
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 9
                                    anchors.rightMargin: 9
                                    spacing: 8

                                    RaohaneSurface {
                                        Layout.preferredWidth: 30
                                        Layout.preferredHeight: 30
                                        surfaceRadius: 9
                                        active: idleAction.hovered
                                        showSheen: false

                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: idleAction.modelData.iconName
                                            iconSize: 15
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
                                            font.pixelSize: 8
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: idleAction.modelData.type
                                            color: RaohaneTheme.textFaint
                                            font.pixelSize: 6
                                            elide: Text.ElideRight
                                        }
                                    }

                                    RaohaneIcon {
                                        text: "arrow_outward"
                                        iconSize: 11
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
                    visible: RaohaneSearch.query.trim().length > 0 && root.results.length > 0

                    Repeater {
                        model: root.results

                        delegate: RaohaneSurface {
                            id: resultRow
                            required property var modelData
                            required property int index

                            readonly property bool selected: index === selection.currentIndex

                            Layout.fillWidth: true
                            Layout.preferredHeight: 47
                            surfaceRadius: 11
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
                                width: 2
                                height: 18
                                radius: 1
                                color: RaohaneTheme.accent
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 9
                                anchors.rightMargin: 10
                                spacing: 8

                                RaohaneSurface {
                                    Layout.preferredWidth: 30
                                    Layout.preferredHeight: 30
                                    surfaceRadius: 9
                                    active: resultRow.selected
                                    showSheen: false

                                    Loader {
                                        anchors.centerIn: parent
                                        width: 24
                                        height: 24
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
                                            iconSize: 22
                                            fallbackColor: resultRow.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                        }
                                    }

                                    Component {
                                        id: materialIcon
                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: resultRow.modelData.iconName
                                            iconSize: 16
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
                                            font.pixelSize: 14
                                        }
                                    }

                                    Component {
                                        id: fallbackIcon
                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: "apps"
                                            iconSize: 15
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
                                        font.pixelSize: 8
                                        font.weight: resultRow.selected ? Font.DemiBold : Font.Medium
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: resultRow.modelData.comment || resultRow.modelData.type
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: 6
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    text: resultRow.modelData.verb
                                    color: resultRow.selected ? RaohaneTheme.accent : RaohaneTheme.textFaint
                                    font.pixelSize: 6
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
                    Layout.preferredHeight: 88
                    visible: RaohaneSearch.query.trim().length > 0 && root.results.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("No results")
                            color: RaohaneTheme.text
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("/ actions    > commands    = math    : clipboard")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
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
                    Layout.preferredHeight: 18
                    Layout.leftMargin: 2
                    Layout.rightMargin: 2

                    Text {
                        text: "RAOHANE"
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 6
                        font.letterSpacing: 1.1
                        font.weight: Font.DemiBold
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "↑↓ navigate   ↵ open   esc close"
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 6
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

        Layout.preferredHeight: 29
        surfaceRadius: 9
        active: selected
        hovered: chipMouse.containsMouse
        pressed: chipMouse.pressed
        interactive: true
        transparentIdle: !selected && !hovered
        showSheen: false
        hoverScale: 1
        pressedScale: 1

        Row {
            anchors.centerIn: parent
            spacing: 4

            RaohaneIcon {
                text: chip.icon
                iconSize: 11
                fill: chip.selected ? 1 : 0
                symbolWeight: chip.selected ? 540 : 430
                color: chip.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: chip.label
                color: chip.selected ? RaohaneTheme.text : RaohaneTheme.textMuted
                font.pixelSize: 6
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

    component PinnedApp: RaohaneSurface {
        id: app

        required property var entry

        Layout.preferredHeight: 66
        surfaceRadius: 12
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
            width: Math.max(46, app.width - 10)
            spacing: 4

            RaohaneSurface {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 34
                height: 34
                surfaceRadius: 10
                active: app.hovered
                showSheen: false

                RaohaneAdaptiveIcon {
                    anchors.centerIn: parent
                    iconSource: String(app.entry?.icon ?? "")
                    iconSize: 25
                    fallbackColor: app.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }
            }

            Text {
                width: parent.width
                text: String(app.entry?.name ?? "App")
                color: app.hovered ? RaohaneTheme.text : RaohaneTheme.textMuted
                font.pixelSize: 6
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
