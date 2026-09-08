pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.modules.raohane.services

Item {
    id: root

    property string rulePattern: ""
    property string ruleScene: "gaming"

    readonly property var scenes: [
        { id: "balanced", label: qsTr("Balanced"), icon: "tune", detail: qsTr("Restore the normal desktop policy") },
        { id: "gaming", label: qsTr("Gaming"), icon: "sports_esports", detail: qsTr("DND, Keep Awake and Game Mode") },
        { id: "focus", label: qsTr("Focus"), icon: "center_focus_strong", detail: qsTr("Quiet notifications and reduce distractions") },
        { id: "work", label: qsTr("Work"), icon: "work", detail: qsTr("Keep the session awake for long work") }
    ]

    function sceneLabel(sceneId): string {
        const scene = root.scenes.find(item => item.id === String(sceneId ?? ""))
        return scene ? scene.label : qsTr("Balanced")
    }

    function sceneIcon(sceneId): string {
        const scene = root.scenes.find(item => item.id === String(sceneId ?? ""))
        return scene ? scene.icon : "tune"
    }

    function useCurrentApp(): void {
        if (RaohaneScenes.activeAppId.length > 0)
            root.rulePattern = RaohaneScenes.activeAppId
    }

    function saveRule(): void {
        const pattern = root.rulePattern.trim().toLowerCase()
        if (pattern.length === 0)
            return
        if (RaohaneScenes.setAppRule(pattern, root.ruleScene))
            root.rulePattern = ""
    }

    Flickable {
        id: sceneFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + 40
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
            id: contentColumn

            width: Math.min(parent.width - 40, 880)
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 108
                surfaceRadius: 14
                raised: false
                showSheen: false
                border.color: RaohaneScenes.autoSceneActive ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 16
                    anchors.bottomMargin: 16
                    width: 3
                    radius: 2
                    color: RaohaneTheme.accent
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 16
                    spacing: 14

                    RaohaneSurface {
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 46
                        surfaceRadius: 14
                        raised: false
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: root.sceneIcon(RaohaneScenes.activeSceneId)
                            iconSize: 24
                            fill: 1
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            text: qsTr("Contextual Scenes")
                            color: RaohaneTheme.text
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Scenes apply temporary runtime policies without overwriting your base Raohane settings.")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            text: qsTr("Selected %1 · active %2 · %3")
                                .arg(root.sceneLabel(RaohaneScenes.selectedSceneId))
                                .arg(root.sceneLabel(RaohaneScenes.activeSceneId))
                                .arg(RaohaneScenes.autoSceneActive ? qsTr("AUTO") : qsTr("MANUAL"))
                            color: RaohaneTheme.accent
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                        }
                    }

                    RaohaneSurface {
                        implicitWidth: statusLabel.implicitWidth + 20
                        implicitHeight: 28
                        surfaceRadius: 9
                        raised: false
                        active: RaohaneScenes.autoSceneActive
                        showSheen: false
                        border.color: RaohaneScenes.autoSceneActive ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                        Text {
                            id: statusLabel
                            anchors.centerIn: parent
                            text: RaohaneScenes.autoSceneActive ? qsTr("AUTO ACTIVE") : qsTr("MANUAL")
                            color: RaohaneScenes.autoSceneActive ? RaohaneTheme.accent : RaohaneTheme.textMuted
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }

            Text {
                Layout.leftMargin: 3
                text: qsTr("SCENE")
                color: RaohaneTheme.textFaint
                font.pixelSize: 9
                font.weight: Font.DemiBold
                font.letterSpacing: 1.1
            }

            GridLayout {
                Layout.fillWidth: true
                columns: width >= 760 ? 4 : 2
                columnSpacing: 9
                rowSpacing: 9

                Repeater {
                    model: root.scenes

                    delegate: RaohaneSurface {
                        id: sceneCard
                        required property var modelData

                        readonly property bool activeScene: RaohaneScenes.activeSceneId === modelData.id
                        readonly property bool selectedScene: RaohaneScenes.selectedSceneId === modelData.id

                        Layout.fillWidth: true
                        Layout.preferredHeight: 88
                        surfaceRadius: 12
                        raised: false
                        active: activeScene
                        hovered: sceneMouse.containsMouse || activeFocus
                        pressed: sceneMouse.pressed
                        interactive: true
                        showSheen: false
                        hoverScale: 1
                        pressedScale: 1
                        activeFocusOnTab: true
                        border.color: activeScene ? RaohaneTheme.accentBorder
                            : selectedScene ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 11
                            spacing: 3

                            RowLayout {
                                Layout.fillWidth: true

                                RaohaneIcon {
                                    text: sceneCard.modelData.icon
                                    iconSize: 19
                                    fill: sceneCard.activeScene ? 1 : 0
                                    color: sceneCard.activeScene ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    visible: sceneCard.selectedScene
                                    text: sceneCard.activeScene ? qsTr("ACTIVE") : qsTr("SELECTED")
                                    color: sceneCard.activeScene ? RaohaneTheme.accent : RaohaneTheme.textFaint
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.6
                                }
                            }

                            Text {
                                text: sceneCard.modelData.label
                                color: RaohaneTheme.text
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            Text {
                                Layout.fillWidth: true
                                text: sceneCard.modelData.detail
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                                wrapMode: Text.WordWrap
                            }
                        }

                        MouseArea {
                            id: sceneMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: sceneCard.forceActiveFocus()
                            onClicked: RaohaneScenes.activate(sceneCard.modelData.id, "settings")
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                RaohaneScenes.activate(sceneCard.modelData.id, "settings")
                                event.accepted = true
                            }
                        }
                    }
                }
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 72
                surfaceRadius: 12
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    RaohaneIcon {
                        text: "auto_awesome"
                        iconSize: 20
                        color: RaohaneScenes.autoSwitchEnabled ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: qsTr("Automatic scene switching")
                            color: RaohaneTheme.text
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Match the active Wayland appId against your rules. Manual choices win until the active application changes.")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            wrapMode: Text.WordWrap
                        }
                    }

                    RaohaneSwitch {
                        checked: RaohaneScenes.autoSwitchEnabled
                        onToggled: checked => RaohaneScenes.setAutoSwitch(checked)
                    }
                }
            }

            Text {
                Layout.leftMargin: 3
                Layout.topMargin: 3
                text: qsTr("ACTIVE APPLICATION")
                color: RaohaneTheme.textFaint
                font.pixelSize: 9
                font.weight: Font.DemiBold
                font.letterSpacing: 1.1
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 78
                surfaceRadius: 12
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    spacing: 12

                    RaohaneSurface {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        surfaceRadius: 11
                        raised: false
                        active: RaohaneScenes.activeAppId.length > 0
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "web_asset"
                            iconSize: 19
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: RaohaneScenes.activeAppId.length > 0 ? RaohaneScenes.activeAppId : qsTr("No active appId")
                            color: RaohaneTheme.text
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            text: RaohaneScenes.matchingSceneFor(RaohaneScenes.activeAppId).length > 0
                                ? qsTr("Matches %1").arg(root.sceneLabel(RaohaneScenes.matchingSceneFor(RaohaneScenes.activeAppId)))
                                : qsTr("No scene rule matches this application")
                            color: RaohaneScenes.matchingSceneFor(RaohaneScenes.activeAppId).length > 0 ? RaohaneTheme.accent : RaohaneTheme.textMuted
                            font.pixelSize: 8
                        }
                    }

                    ActionButton {
                        icon: "add_link"
                        label: qsTr("Use current app")
                        enabled: RaohaneScenes.activeAppId.length > 0
                        onClicked: root.useCurrentApp()
                    }
                }
            }

            Text {
                Layout.leftMargin: 3
                Layout.topMargin: 3
                text: qsTr("APPLICATION RULES")
                color: RaohaneTheme.textFaint
                font.pixelSize: 9
                font.weight: Font.DemiBold
                font.letterSpacing: 1.1
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 150
                surfaceRadius: 12
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 13
                    spacing: 9

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 9

                        RaohaneSurface {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            surfaceRadius: 9
                            raised: false
                            showSheen: false
                            border.color: ruleField.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                            TextField {
                                id: ruleField
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                text: root.rulePattern
                                placeholderText: qsTr("appId, for example code or steam_app_123456")
                                color: RaohaneTheme.text
                                placeholderTextColor: RaohaneTheme.textFaint
                                font.pixelSize: 9
                                selectByMouse: true
                                background: null
                                onTextEdited: root.rulePattern = text
                                Keys.onReturnPressed: root.saveRule()
                                Keys.onEnterPressed: root.saveRule()
                            }
                        }

                        ActionButton {
                            icon: "add"
                            label: qsTr("Add rule")
                            emphasized: true
                            enabled: root.rulePattern.trim().length > 0
                            onClicked: root.saveRule()
                        }
                    }

                    Text {
                        text: qsTr("When this exact appId becomes active, switch to:")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 7

                        Repeater {
                            model: root.scenes

                            delegate: SceneChoice {
                                required property var modelData
                                Layout.fillWidth: true
                                sceneId: modelData.id
                                label: modelData.label
                                icon: modelData.icon
                                selected: root.ruleScene === modelData.id
                                onChosen: root.ruleScene = modelData.id
                            }
                        }
                    }
                }
            }

            Text {
                visible: RaohaneScenes.appRules.length > 0
                Layout.leftMargin: 3
                text: qsTr("CUSTOM RULES")
                color: RaohaneTheme.textFaint
                font.pixelSize: 9
                font.weight: Font.DemiBold
                font.letterSpacing: 1.1
            }

            Repeater {
                model: RaohaneScenes.appRules

                delegate: RaohaneSurface {
                    id: ruleCard
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    surfaceRadius: 11
                    raised: false
                    showSheen: false
                    border.color: RaohaneTheme.borderFaint

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 13
                        anchors.rightMargin: 10
                        spacing: 11

                        RaohaneIcon {
                            text: root.sceneIcon(ruleCard.modelData.scene)
                            iconSize: 18
                            color: RaohaneTheme.accent
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: ruleCard.modelData.pattern
                                color: RaohaneTheme.text
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                text: qsTr("%1 match · %2").arg(ruleCard.modelData.match).arg(root.sceneLabel(ruleCard.modelData.scene))
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                            }
                        }

                        ActionButton {
                            visible: ruleCard.modelData.match === "exact"
                            icon: "delete"
                            label: qsTr("Remove")
                            onClicked: RaohaneScenes.removeAppRule(ruleCard.modelData.pattern)
                        }
                    }
                }
            }

            Text {
                Layout.leftMargin: 3
                Layout.topMargin: 3
                text: qsTr("BUILT-IN RULES")
                color: RaohaneTheme.textFaint
                font.pixelSize: 9
                font.weight: Font.DemiBold
                font.letterSpacing: 1.1
            }

            Repeater {
                model: RaohaneScenes.defaultRules()

                delegate: RaohaneSurface {
                    id: builtinCard
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    surfaceRadius: 11
                    raised: false
                    showSheen: false
                    border.color: RaohaneTheme.borderFaint

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 13
                        anchors.rightMargin: 13
                        spacing: 11

                        RaohaneIcon {
                            text: "verified"
                            iconSize: 17
                            color: RaohaneTheme.textMuted
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: builtinCard.modelData.pattern
                                color: RaohaneTheme.text
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: qsTr("%1 match · %2 · protected default").arg(builtinCard.modelData.match).arg(root.sceneLabel(builtinCard.modelData.scene))
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                            }
                        }
                    }
                }
            }
        }
    }

    component SceneChoice: FocusScope {
        id: choice

        required property string sceneId
        required property string label
        required property string icon
        property bool selected: false
        signal chosen()

        implicitHeight: 38
        activeFocusOnTab: true

        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: 9
            raised: false
            active: choice.selected
            hovered: choiceMouse.containsMouse || choice.activeFocus
            pressed: choiceMouse.pressed
            interactive: true
            transparentIdle: !choice.selected && !hovered
            hoverScale: 1
            pressedScale: 1
            showSheen: false
            border.color: choice.selected ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

            RowLayout {
                anchors.centerIn: parent
                spacing: 5

                RaohaneIcon {
                    text: choice.icon
                    iconSize: 13
                    color: choice.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }

                Text {
                    text: choice.label
                    color: choice.selected ? RaohaneTheme.text : RaohaneTheme.textMuted
                    font.pixelSize: 8
                    font.weight: choice.selected ? Font.DemiBold : Font.Medium
                }
            }
        }

        MouseArea {
            id: choiceMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: choice.forceActiveFocus()
            onClicked: choice.chosen()
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                choice.chosen()
                event.accepted = true
            }
        }
    }

    component ActionButton: FocusScope {
        id: action

        required property string icon
        required property string label
        property bool emphasized: false
        signal clicked()

        implicitWidth: actionRow.implicitWidth + 22
        implicitHeight: 34
        activeFocusOnTab: enabled
        opacity: enabled ? 1 : RaohaneMotion.disabledOpacity

        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: 9
            raised: false
            active: action.emphasized
            hovered: actionMouse.containsMouse || action.activeFocus
            pressed: actionMouse.pressed
            interactive: true
            transparentIdle: !action.emphasized && !hovered
            hoverScale: 1
            pressedScale: 1
            showSheen: false
            border.color: action.emphasized ? RaohaneTheme.accentBorder : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

            RowLayout {
                id: actionRow
                anchors.centerIn: parent
                spacing: 6

                RaohaneIcon {
                    text: action.icon
                    iconSize: 13
                    color: action.emphasized ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }

                Text {
                    text: action.label
                    color: action.emphasized ? RaohaneTheme.text : RaohaneTheme.textMuted
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                }
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            enabled: action.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: action.forceActiveFocus()
            onClicked: action.clicked()
        }

        Keys.onPressed: event => {
            if (action.enabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                action.clicked()
                event.accepted = true
            }
        }
    }
}
