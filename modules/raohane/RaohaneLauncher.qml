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
        margins.top: RaohaneTheme.barHeight + 3 * RaohaneTheme.panelPadding + RaohaneTheme.spacingSmall

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
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: true
            idleBorderColor: RaohaneTheme.borderStrong
            clip: true
            opacity: entered ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }

            ColumnLayout {
                id: content

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: RaohaneTheme.panelPadding + RaohaneTheme.spacingTiny
                }
                spacing: RaohaneTheme.spacing + 1

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    spacing: RaohaneTheme.spacing

                    RaohaneSurface {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        surfaceRadius: RaohaneTheme.radiusHero
                        raised: false
                        active: searchInput.activeFocus
                        showSheen: false
                        showInnerRim: false
                        idleColor: RaohaneTheme.surface
                        activeColor: RaohaneTheme.surface
                        idleBorderColor: RaohaneTheme.borderStrong
                        activeBorderColor: RaohaneTheme.accentBorder

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: RaohaneTheme.panelPadding + 1
                            anchors.rightMargin: RaohaneTheme.spacing + 1
                            spacing: RaohaneTheme.spacing

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
                    spacing: RaohaneTheme.spacingSmall

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
                    spacing: RaohaneTheme.spacing + 1
                    visible: RaohaneSearch.query.trim().length === 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: RaohaneTheme.spacingTiny
                        Layout.rightMargin: RaohaneTheme.spacingTiny

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
                        spacing: RaohaneTheme.spacingSmall + 2

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
                        Layout.topMargin: RaohaneTheme.spacingTiny
                        color: RaohaneTheme.borderFaint
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: RaohaneTheme.spacingTiny
                        Layout.rightMargin: RaohaneTheme.spacingTiny

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
                        columnSpacing: RaohaneTheme.spacingSmall + 2
                        rowSpacing: RaohaneTheme.spacingSmall + 2

                        Repeater {
                            model: root.idleActions

                            delegate: RaohaneSurface {
                                id: idleAction
                                required property var modelData

                                Layout.fillWidth: true
                                Layout.preferredHeight: 58
                                surfaceRadius: RaohaneTheme.radiusLarge
                                showSheen: false
                                showInnerRim: false
                                raised: false
                                hovered: idleActionMouse.containsMouse || activeFocus
                                pressed: idleActionMouse.pressed
                                interactive: true
                                hoverScale: 1
                                pressedScale: 1
                                activeFocusOnTab: true
                                idleBorderColor: RaohaneTheme.borderFaint
                                hoverBorderColor: RaohaneTheme.borderStrong
                                pressedBorderColor: RaohaneTheme.borderStrong
                                showStateRail: idleAction.hovered
                                stateRailWidth: 3
                                stateRailLength: 24
                                stateRailOpacity: 0.72

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: RaohaneTheme.spacing + 2
                                    anchors.rightMargin: RaohaneTheme.spacing + 2
                                    spacing: RaohaneTheme.spacing + 1

                                    RaohaneSurface {
                                        Layout.preferredWidth: 34
                                        Layout.preferredHeight: 34
                                        surfaceRadius: RaohaneTheme.radius
                                        active: idleAction.hovered
                                        showSheen: false
                                        showInnerRim: false

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
                                        spacing: Math.max(1, RaohaneTheme.spacingTiny - 2)

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
                    spacing: RaohaneTheme.spacingSmall - 1
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
                            surfaceRadius: RaohaneTheme.radiusLarge
                            active: selected
                            hovered: resultMouse.containsMouse || activeFocus
                            pressed: resultMouse.pressed
                            interactive: true
                            transparentIdle: !selected && !hovered
                            showSheen: false
                            showInnerRim: selected
                            hoverScale: 1
                            pressedScale: 1
                            activeFocusOnTab: true
                            showStateRail: selected
                            stateRailWidth: 3
                            stateRailLength: 24
                            stateRailOpacity: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: RaohaneTheme.spacing + 2
                                anchors.rightMargin: RaohaneTheme.panelPadding
                                spacing: RaohaneTheme.spacing + 1

                                RaohaneSurface {
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 36
                                    surfaceRadius: RaohaneTheme.radius
                                    active: resultRow.selected
                                    showSheen: false
                                    showInnerRim: false

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
                                    spacing: Math.max(1, RaohaneTheme.spacingTiny - 2)

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
                                text: "search_off"
                                iconSize: 20
                                color: RaohaneTheme.textFaint
                            }
                        }

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
                    Layout.leftMargin: RaohaneTheme.spacingTiny
                    Layout.rightMargin: RaohaneTheme.spacingTiny

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
        surfaceRadius: RaohaneTheme.radius
        active: selected
        hovered: chipMouse.containsMouse || activeFocus
        pressed: chipMouse.pressed
        interactive: true
        transparentIdle: !selected && !hovered
        showSheen: false
        showInnerRim: selected
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: true
        idleBorderColor: "transparent"
        hoverBorderColor: RaohaneTheme.borderStrong
        pressedBorderColor: RaohaneTheme.borderStrong
        activeBorderColor: RaohaneTheme.accentBorder

        Row {
            anchors.centerIn: parent
            spacing: RaohaneTheme.spacingSmall - 1

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
        surfaceRadius: RaohaneTheme.radiusLarge
        transparentIdle: !app.hovered
        showSheen: false
        showInnerRim: false
        interactive: true
        hovered: appMouse.containsMouse || activeFocus
        pressed: appMouse.pressed
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: true
        idleBorderColor: "transparent"
        hoverBorderColor: RaohaneTheme.borderStrong
        pressedBorderColor: RaohaneTheme.borderStrong

        Column {
            anchors.centerIn: parent
            width: Math.max(50, app.width - 2 * RaohaneTheme.spacingSmall)
            spacing: RaohaneTheme.spacingSmall - 1

            RaohaneSurface {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 40
                height: 40
                surfaceRadius: RaohaneTheme.radiusLarge
                active: app.hovered
                showSheen: false
                showInnerRim: false

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
