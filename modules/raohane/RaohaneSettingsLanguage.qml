pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: languageColumn.implicitHeight + 34
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 2600

        Column {
            id: languageColumn

            y: 14
            width: Math.min(parent.width - 36, 720)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 9

            RaohaneSurface {
                width: parent.width
                height: 72
                surfaceRadius: 10
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 2
                        Layout.preferredHeight: 28
                        radius: 1
                        color: RaohaneTheme.accent
                    }

                    RaohaneIcon {
                        text: "translate"
                        iconSize: 18
                        fill: 1
                        color: RaohaneTheme.accent
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: qsTr("Interface language")
                            color: RaohaneTheme.text
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Choose the language used by Raohane. The shell restarts automatically when a new runtime catalog needs to be applied.")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            lineHeight: 1.15
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
                    height: 52
                    surfaceRadius: 9
                    raised: false
                    active: selected
                    hovered: languageMouse.containsMouse
                    pressed: languageMouse.pressed
                    interactive: true
                    showSheen: false
                    hoverScale: 1
                    pressedScale: 1
                    border.color: selected
                        ? RaohaneTheme.accentBorder
                        : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: languageCard.selected ? 22 : languageCard.hovered ? 12 : 7
                        radius: 1
                        color: RaohaneTheme.accent
                        opacity: languageCard.selected ? 1 : languageCard.hovered ? 0.42 : 0
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 11
                        spacing: 9

                        RaohaneIcon {
                            text: languageCard.selected ? "check_circle" : "language"
                            iconSize: 17
                            fill: languageCard.selected ? 1 : 0
                            color: languageCard.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: languageCard.modelData.nativeName
                                color: RaohaneTheme.text
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: languageCard.modelData.name + " · " + languageCard.modelData.code
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 7
                            }
                        }

                        RaohaneSurface {
                            visible: languageCard.selected
                            implicitWidth: currentLabel.implicitWidth + 14
                            implicitHeight: 22
                            surfaceRadius: 7
                            raised: false
                            showSheen: false
                            border.color: RaohaneTheme.accentBorder

                            Text {
                                id: currentLabel
                                anchors.centerIn: parent
                                text: qsTr("Current")
                                color: RaohaneTheme.accent
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    MouseArea {
                        id: languageMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!languageCard.selected)
                                RaohaneI18n.setLanguage(languageCard.modelData.code)
                        }
                    }
                }
            }
        }
    }
}
