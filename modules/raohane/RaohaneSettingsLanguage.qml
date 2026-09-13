pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    readonly property bool compactLayout: width < 700

    Flickable {
        id: languageFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: languageColumn.implicitHeight + RaohaneTheme.panelPadding * 3
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

        Column {
            id: languageColumn

            y: RaohaneTheme.spacingLarge
            width: Math.min(
                Math.max(0, parent.width - (root.compactLayout ? RaohaneTheme.panelPadding * 2 : 44)),
                760
            )
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: RaohaneTheme.spacing

            RaohaneSurface {
                width: parent.width
                height: 86
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint
                showStateRail: true
                stateRailColor: RaohaneTheme.accent
                stateRailOpacity: 0.62
                stateRailWidth: 3
                stateRailLength: 42

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: RaohaneTheme.panelPadding + RaohaneTheme.spacingSmall
                    anchors.rightMargin: RaohaneTheme.panelPadding
                    spacing: RaohaneTheme.spacingLarge

                    RaohaneSurface {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        surfaceRadius: RaohaneTheme.radiusSmall
                        raised: false
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "translate"
                            iconSize: 22
                            fill: 1
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: RaohaneTheme.spacingTiny

                        Text {
                            text: qsTr("Interface language")
                            color: RaohaneTheme.text
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Choose the language used by Raohane. The shell restarts automatically when a new runtime catalog needs to be applied.")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                            lineHeight: 1.16
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            Repeater {
                model: RaohaneI18n.supportedLanguages

                delegate: RaohaneSurface {
                    id: languageCard

                    required property var modelData
                    readonly property bool selected: RaohaneI18n.language === modelData.code

                    width: languageColumn.width
                    height: 62
                    surfaceRadius: RaohaneTheme.radiusSmall
                    raised: false
                    active: selected
                    hovered: languageMouse.containsMouse || activeFocus
                    pressed: languageMouse.pressed
                    interactive: true
                    showSheen: false
                    hoverScale: 1
                    pressedScale: 1
                    activeFocusOnTab: true
                    color: selected ? RaohaneTheme.surfaceRaised
                        : hovered ? RaohaneTheme.surfaceSubtle : RaohaneTheme.surfaceDeep
                    border.color: selected
                        ? RaohaneTheme.accentBorder
                        : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint
                    showStateRail: selected || hovered
                    stateRailColor: RaohaneTheme.accent
                    stateRailOpacity: selected ? 0.84 : 0.38
                    stateRailWidth: 3
                    stateRailLength: selected ? 30 : 18

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: RaohaneTheme.panelPadding
                        anchors.rightMargin: RaohaneTheme.panelPadding
                        spacing: RaohaneTheme.spacing

                        RaohaneSurface {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            surfaceRadius: RaohaneTheme.radiusSmall
                            raised: false
                            active: languageCard.selected
                            showSheen: false

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: languageCard.selected ? "check_circle" : "language"
                                iconSize: 18
                                fill: languageCard.selected ? 1 : 0
                                color: languageCard.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: languageCard.modelData.nativeName
                                color: RaohaneTheme.text
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: languageCard.modelData.name + " · " + languageCard.modelData.code
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                            }
                        }

                        RaohaneSurface {
                            visible: languageCard.selected
                            implicitWidth: currentLabel.implicitWidth + 18
                            implicitHeight: 26
                            surfaceRadius: RaohaneTheme.radiusSmall
                            raised: false
                            active: true
                            showSheen: false
                            border.color: RaohaneTheme.accentBorder

                            Text {
                                id: currentLabel
                                anchors.centerIn: parent
                                text: qsTr("Current")
                                color: RaohaneTheme.accent
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    MouseArea {
                        id: languageMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: languageCard.forceActiveFocus()
                        onClicked: {
                            if (!languageCard.selected)
                                RaohaneI18n.setLanguage(languageCard.modelData.code)
                        }
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (!languageCard.selected)
                                RaohaneI18n.setLanguage(languageCard.modelData.code)
                            event.accepted = true
                        }
                    }
                }
            }
        }
    }
}
