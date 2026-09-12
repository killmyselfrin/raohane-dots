pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.modules.raohane.services

Item {
    id: root

    property string rulePattern: ""
    property string ruleScene: "gaming"
    property string ruleMatch: "exact"
    property string behaviorScene: "gaming"

    readonly property bool compactLayout: width < 760
    readonly property var scenes: [
        { id: "balanced", label: qsTr("Balanced"), icon: "tune", detail: qsTr("Restore the normal desktop policy") },
        { id: "gaming", label: qsTr("Gaming"), icon: "sports_esports", detail: qsTr("DND, Keep Awake and Game Mode") },
        { id: "focus", label: qsTr("Focus"), icon: "center_focus_strong", detail: qsTr("Quiet notifications and reduce distractions") },
        { id: "work", label: qsTr("Work"), icon: "work", detail: qsTr("Keep the session awake for long work") }
    ]
    readonly property var behaviorScenes: root.scenes.filter(scene => scene.id !== "balanced")
    readonly property var matchChoices: [
        { id: "exact", label: qsTr("Exact appId"), icon: "target" },
        { id: "prefix", label: qsTr("Starts with"), icon: "first_page" },
        { id: "contains", label: qsTr("Contains text"), icon: "manage_search" }
    ]
    readonly property var motionChoices: [
        { id: "balanced", label: qsTr("Balanced motion"), icon: "motion_mode" },
        { id: "fast", label: qsTr("Fast motion"), icon: "speed" },
        { id: "quiet", label: qsTr("Quiet motion"), icon: "slow_motion_video" }
    ]
    readonly property var activeMatchRule: RaohaneScenes.matchingRuleFor(RaohaneScenes.activeAppId)

    function sceneLabel(sceneId): string {
        const scene = root.scenes.find(item => item.id === String(sceneId ?? ""))
        return scene ? scene.label : qsTr("Balanced")
    }

    function sceneIcon(sceneId): string {
        const scene = root.scenes.find(item => item.id === String(sceneId ?? ""))
        return scene ? scene.icon : "tune"
    }

    function matchLabel(matchId): string {
        const mode = root.matchChoices.find(item => item.id === String(matchId ?? ""))
        return mode ? mode.label : qsTr("Exact appId")
    }

    function useCurrentApp(): void {
        if (RaohaneScenes.activeAppId.length > 0) {
            root.rulePattern = RaohaneScenes.activeAppId
            root.ruleMatch = "exact"
        }
    }

    function saveRule(): void {
        const pattern = root.rulePattern.trim().toLowerCase()
        if (pattern.length === 0)
            return
        if (RaohaneScenes.setRule(pattern, root.ruleMatch, root.ruleScene))
            root.rulePattern = ""
    }

    function setBehaviorToggle(policyKey: string, checked: bool): void {
        if (policyKey === "notificationPolicy")
            RaohaneScenes.setPolicyValue(root.behaviorScene, policyKey, checked ? "dnd" : "inherit")
        else if (policyKey === "dockPolicy")
            RaohaneScenes.setPolicyValue(root.behaviorScene, policyKey, checked ? "hide" : "inherit")
        else
            RaohaneScenes.setPolicyValue(root.behaviorScene, policyKey, checked)
    }

    Flickable {
        id: sceneFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + RaohaneTheme.panelPadding * 3
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
            id: contentColumn

            width: Math.min(
                Math.max(0, parent.width - (root.compactLayout ? RaohaneTheme.panelPadding * 2 : 40)),
                880
            )
            anchors.top: parent.top
            anchors.topMargin: RaohaneTheme.spacingLarge
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: RaohaneTheme.spacingLarge

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 108
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                border.color: RaohaneScenes.autoSceneActive ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint
                showStateRail: true
                stateRailColor: RaohaneTheme.accent
                stateRailOpacity: RaohaneScenes.autoSceneActive ? 0.76 : 0.42
                stateRailWidth: 3
                stateRailLength: Math.max(38, height - RaohaneTheme.panelPadding * 3)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: RaohaneTheme.panelPadding + RaohaneTheme.spacingSmall
                    anchors.rightMargin: RaohaneTheme.panelPadding
                    spacing: RaohaneTheme.spacingLarge

                    RaohaneSurface {
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 46
                        surfaceRadius: RaohaneTheme.radiusSmall
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
                        spacing: RaohaneTheme.spacingTiny

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
                            maximumLineCount: 2
                            elide: Text.ElideRight
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
                        surfaceRadius: RaohaneTheme.radiusSmall
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
                Layout.leftMargin: RaohaneTheme.spacingTiny
                text: qsTr("SCENE")
                color: RaohaneTheme.textFaint
                font.pixelSize: 9
                font.weight: Font.DemiBold
                font.letterSpacing: 1.1
            }

            GridLayout {
                Layout.fillWidth: true
                columns: width >= 760 ? 4 : 2
                columnSpacing: RaohaneTheme.spacing
                rowSpacing: RaohaneTheme.spacing

                Repeater {
                    model: root.scenes

                    delegate: RaohaneSurface {
                        id: sceneCard
                        required property var modelData

                        readonly property bool activeScene: RaohaneScenes.activeSceneId === modelData.id
                        readonly property bool selectedScene: RaohaneScenes.selectedSceneId === modelData.id

                        Layout.fillWidth: true
                        Layout.preferredHeight: 88
                        surfaceRadius: RaohaneTheme.radiusSmall
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
                        showStateRail: activeScene || selectedScene
                        stateRailColor: RaohaneTheme.accent
                        stateRailOpacity: activeScene ? 0.78 : 0.38
                        stateRailWidth: 2
                        stateRailLength: Math.max(22, height - RaohaneTheme.panelPadding * 2)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: RaohaneTheme.spacing
                            spacing: RaohaneTheme.spacingTiny

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
                                maximumLineCount: 2
                                elide: Text.ElideRight
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

            Text {
                Layout.leftMargin: RaohaneTheme.spacingTiny
                Layout.topMargin: RaohaneTheme.spacingTiny
                text: qsTr("SCENE BEHAVIOR")
                color: RaohaneTheme.textFaint
                font.pixelSize: 9
                font.weight: Font.DemiBold
                font.letterSpacing: 1.1
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 292
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                border.color: RaohaneScenes.hasPolicyOverride(root.behaviorScene) ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint
                showStateRail: RaohaneScenes.hasPolicyOverride(root.behaviorScene)
                stateRailColor: RaohaneTheme.accent
                stateRailOpacity: 0.5
                stateRailWidth: 2
                stateRailLength: Math.max(30, height - RaohaneTheme.panelPadding * 3)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: RaohaneTheme.panelPadding
                    spacing: RaohaneTheme.spacing

                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: RaohaneTheme.spacingTiny

                            Text {
                                text: qsTr("Runtime policy")
                                color: RaohaneTheme.text
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: qsTr("Customize temporary behavior without changing your base Raohane settings.")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                            }
                        }

                        ActionButton {
                            icon: "restart_alt"
                            label: qsTr("Reset defaults")
                            enabled: RaohaneScenes.hasPolicyOverride(root.behaviorScene)
                            onClicked: RaohaneScenes.resetScenePolicy(root.behaviorScene)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: RaohaneTheme.spacingSmall

                        Repeater {
                            model: root.behaviorScenes

                            delegate: SceneChoice {
                                required property var modelData
                                Layout.fillWidth: true
                                sceneId: modelData.id
                                label: modelData.label
                                icon: modelData.icon
                                selected: root.behaviorScene === modelData.id
                                onChosen: root.behaviorScene = modelData.id
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: RaohaneTheme.spacingSmall
                        rowSpacing: RaohaneTheme.spacingSmall

                        BehaviorToggle {
                            Layout.fillWidth: true
                            policyKey: "notificationPolicy"
                            icon: "notifications_off"
                            label: qsTr("Do Not Disturb")
                            detail: qsTr("Pause notification popups while this Scene is active")
                            checked: RaohaneScenes.policyFor(root.behaviorScene).notificationPolicy === "dnd"
                            onChanged: checked => root.setBehaviorToggle(policyKey, checked)
                        }

                        BehaviorToggle {
                            Layout.fillWidth: true
                            policyKey: "keepAwake"
                            icon: "coffee"
                            label: qsTr("Keep Awake")
                            detail: qsTr("Temporarily inhibit idle and sleep")
                            checked: Boolean(RaohaneScenes.policyFor(root.behaviorScene).keepAwake)
                            onChanged: checked => root.setBehaviorToggle(policyKey, checked)
                        }

                        BehaviorToggle {
                            Layout.fillWidth: true
                            policyKey: "gameMode"
                            icon: "speed"
                            label: qsTr("Game Mode")
                            detail: qsTr("Use the low-latency Hyprland profile")
                            checked: Boolean(RaohaneScenes.policyFor(root.behaviorScene).gameMode)
                            onChanged: checked => root.setBehaviorToggle(policyKey, checked)
                        }

                        BehaviorToggle {
                            Layout.fillWidth: true
                            policyKey: "dockPolicy"
                            icon: "dock_to_bottom"
                            label: qsTr("Hide Dock")
                            detail: qsTr("Keep the Dock hidden unless you reveal it")
                            checked: RaohaneScenes.policyFor(root.behaviorScene).dockPolicy === "hide"
                            onChanged: checked => root.setBehaviorToggle(policyKey, checked)
                        }
                    }

                    Text {
                        text: qsTr("Motion cadence")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: RaohaneTheme.spacingSmall

                        Repeater {
                            model: root.motionChoices

                            delegate: MatchChoice {
                                required property var modelData
                                Layout.fillWidth: true
                                matchId: modelData.id
                                label: modelData.label
                                icon: modelData.icon
                                selected: RaohaneScenes.policyFor(root.behaviorScene).motionHint === modelData.id
                                onChosen: RaohaneScenes.setPolicyValue(root.behaviorScene, "motionHint", modelData.id)
                            }
                        }
                    }
                }
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 72
                surfaceRadius: RaohaneTheme.radiusSmall
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: RaohaneTheme.panelPadding
                    anchors.rightMargin: RaohaneTheme.panelPadding
                    spacing: RaohaneTheme.spacingLarge

                    RaohaneIcon {
                        text: "auto_awesome"
                        iconSize: 20
                        color: RaohaneScenes.autoSwitchEnabled ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: RaohaneTheme.spacingTiny

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
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }

                    RaohaneSwitch {
                        checked: RaohaneScenes.autoSwitchEnabled
                        onToggled: checked => RaohaneScenes.setAutoSwitch(checked)
                    }
                }
            }

            Text {
                Layout.leftMargin: RaohaneTheme.spacingTiny
                Layout.topMargin: RaohaneTheme.spacingTiny
                text: qsTr("ACTIVE APPLICATION")
                color: RaohaneTheme.textFaint
                font.pixelSize: 9
                font.weight: Font.DemiBold
                font.letterSpacing: 1.1
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 82
                surfaceRadius: RaohaneTheme.radiusSmall
                raised: false
                showSheen: false
                border.color: root.activeMatchRule ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint
                showStateRail: Boolean(root.activeMatchRule)
                stateRailColor: RaohaneTheme.accent
                stateRailOpacity: 0.56
                stateRailWidth: 2
                stateRailLength: Math.max(22, height - RaohaneTheme.panelPadding * 2)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: RaohaneTheme.panelPadding
                    anchors.rightMargin: RaohaneTheme.panelPadding
                    spacing: RaohaneTheme.spacingLarge

                    RaohaneSurface {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        surfaceRadius: RaohaneTheme.radiusSmall
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
                        spacing: RaohaneTheme.spacingTiny

                        Text {
                            text: RaohaneScenes.activeAppId.length > 0 ? RaohaneScenes.activeAppId : qsTr("No active appId")
                            color: RaohaneTheme.text
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            text: root.activeMatchRule
                                ? qsTr("%1 · %2 rule · %3")
                                    .arg(root.sceneLabel(root.activeMatchRule.scene))
                                    .arg(root.matchLabel(root.activeMatchRule.match))
                                    .arg(root.activeMatchRule.builtin ? qsTr("built-in") : qsTr("custom"))
                                : qsTr("No scene rule matches this application")
                            color: root.activeMatchRule ? RaohaneTheme.accent : RaohaneTheme.textMuted
                            font.pixelSize: 8
                            elide: Text.ElideRight
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
                Layout.leftMargin: RaohaneTheme.spacingTiny
                Layout.topMargin: RaohaneTheme.spacingTiny
                text: qsTr("APPLICATION RULES")
                color: RaohaneTheme.textFaint
                font.pixelSize: 9
                font.weight: Font.DemiBold
                font.letterSpacing: 1.1
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 205
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: RaohaneTheme.panelPadding
                    spacing: RaohaneTheme.spacingSmall

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: RaohaneTheme.spacing

                        RaohaneSurface {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            surfaceRadius: RaohaneTheme.radiusSmall
                            raised: false
                            showSheen: false
                            border.color: ruleField.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                            TextField {
                                id: ruleField
                                anchors.fill: parent
                                anchors.leftMargin: RaohaneTheme.spacing
                                anchors.rightMargin: RaohaneTheme.spacing
                                text: root.rulePattern
                                placeholderText: qsTr("appId or match pattern")
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
                        text: qsTr("Match mode")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: RaohaneTheme.spacingSmall

                        Repeater {
                            model: root.matchChoices

                            delegate: MatchChoice {
                                required property var modelData
                                Layout.fillWidth: true
                                matchId: modelData.id
                                label: modelData.label
                                icon: modelData.icon
                                selected: root.ruleMatch === modelData.id
                                onChosen: root.ruleMatch = modelData.id
                            }
                        }
                    }

                    Text {
                        text: qsTr("Switch matching applications to")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: RaohaneTheme.spacingSmall

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
                Layout.leftMargin: RaohaneTheme.spacingTiny
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
                    surfaceRadius: RaohaneTheme.radiusSmall
                    raised: false
                    showSheen: false
                    border.color: root.activeMatchRule
                            && root.activeMatchRule.pattern === ruleCard.modelData.pattern
                            && root.activeMatchRule.match === ruleCard.modelData.match
                        ? RaohaneTheme.accentBorder
                        : RaohaneTheme.borderFaint
                    showStateRail: Boolean(root.activeMatchRule
                        && root.activeMatchRule.pattern === ruleCard.modelData.pattern
                        && root.activeMatchRule.match === ruleCard.modelData.match)
                    stateRailColor: RaohaneTheme.accent
                    stateRailOpacity: 0.56
                    stateRailWidth: 2
                    stateRailLength: Math.max(18, height - RaohaneTheme.spacingLarge * 2)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: RaohaneTheme.panelPadding
                        anchors.rightMargin: RaohaneTheme.spacing
                        spacing: RaohaneTheme.spacing

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
                                text: qsTr("%1 · %2").arg(root.matchLabel(ruleCard.modelData.match)).arg(root.sceneLabel(ruleCard.modelData.scene))
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                            }
                        }

                        ActionButton {
                            icon: "delete"
                            label: qsTr("Remove")
                            onClicked: RaohaneScenes.removeRule(ruleCard.modelData.pattern, ruleCard.modelData.match)
                        }
                    }
                }
            }

            Text {
                Layout.leftMargin: RaohaneTheme.spacingTiny
                Layout.topMargin: RaohaneTheme.spacingTiny
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
                    surfaceRadius: RaohaneTheme.radiusSmall
                    raised: false
                    showSheen: false
                    border.color: root.activeMatchRule
                            && root.activeMatchRule.builtin
                            && root.activeMatchRule.pattern === builtinCard.modelData.pattern
                            && root.activeMatchRule.match === builtinCard.modelData.match
                        ? RaohaneTheme.accentBorder
                        : RaohaneTheme.borderFaint
                    showStateRail: Boolean(root.activeMatchRule
                        && root.activeMatchRule.builtin
                        && root.activeMatchRule.pattern === builtinCard.modelData.pattern
                        && root.activeMatchRule.match === builtinCard.modelData.match)
                    stateRailColor: RaohaneTheme.accent
                    stateRailOpacity: 0.44
                    stateRailWidth: 2
                    stateRailLength: Math.max(18, height - RaohaneTheme.spacingLarge * 2)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: RaohaneTheme.panelPadding
                        anchors.rightMargin: RaohaneTheme.panelPadding
                        spacing: RaohaneTheme.spacing

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
                                text: qsTr("%1 · %2 · protected default")
                                    .arg(root.matchLabel(builtinCard.modelData.match))
                                    .arg(root.sceneLabel(builtinCard.modelData.scene))
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
            surfaceRadius: RaohaneTheme.radiusSmall
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
                spacing: RaohaneTheme.spacingTiny

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

    component MatchChoice: FocusScope {
        id: choice

        required property string matchId
        required property string label
        required property string icon
        property bool selected: false
        signal chosen()

        implicitHeight: 34
        activeFocusOnTab: true

        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: RaohaneTheme.radiusSmall
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
                spacing: RaohaneTheme.spacingTiny

                RaohaneIcon {
                    text: choice.icon
                    iconSize: 12
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

    component BehaviorToggle: RaohaneSurface {
        id: behavior

        required property string policyKey
        required property string icon
        required property string label
        required property string detail
        property bool checked: false
        signal changed(bool checked)

        Layout.preferredHeight: 56
        surfaceRadius: RaohaneTheme.radiusSmall
        raised: false
        showSheen: false
        border.color: RaohaneTheme.borderFaint

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: RaohaneTheme.spacing
            anchors.rightMargin: RaohaneTheme.spacing
            spacing: RaohaneTheme.spacingSmall

            RaohaneIcon {
                text: behavior.icon
                iconSize: 16
                color: behavior.checked ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: behavior.label
                    color: RaohaneTheme.text
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: behavior.detail
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                    elide: Text.ElideRight
                }
            }

            RaohaneSwitch {
                checked: behavior.checked
                onToggled: checked => behavior.changed(checked)
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
            surfaceRadius: RaohaneTheme.radiusSmall
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
                spacing: RaohaneTheme.spacingSmall

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
