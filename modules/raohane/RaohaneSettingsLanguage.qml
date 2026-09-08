pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Flickable {
        id: languageFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: languageColumn.implicitHeight + 40
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

        Column {
            id: languageColumn

            y: 16
            width: Math.min(parent.width - 44, 760)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 11

            RaohaneSurface {
                width: parent.width
                height: 86
                surfaceRadius: 13
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: 42
                    radius: 2
                    color: RaohaneTheme.accent
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 13

                    RaohaneSurface {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        surfaceRadius: 13
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
                        spacing: 3

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
                    surfaceRadius: 11
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

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: languageCard.selected ? 30 : languageCard.hovered ? 18 : 8
                        radius: 2
                        color: RaohaneTheme.accent
                        opacity: languageCard.selected ? 1 : languageCard.hovered ? 0.48 : 0
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 15
                        anchors.rightMargin: 13
                        spacing: 11

                        RaohaneSurface {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            surfaceRadius: 10
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
                            surfaceRadius: 8
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
