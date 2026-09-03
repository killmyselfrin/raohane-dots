pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: languageColumn.implicitHeight + 42
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 2600

        Column {
            id: languageColumn
            y: 18
            width: Math.min(parent.width - 48, 720)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14

            RaohaneSurface {
                width: parent.width
                height: 96
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    RaohaneSurface {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        surfaceRadius: 15
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "translate"
                            iconSize: 23
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
                            font.pixelSize: 8
                            lineHeight: 1.2
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
                    height: 72
                    surfaceRadius: 18
                    raised: false
                    active: selected
                    hovered: languageMouse.containsMouse
                    pressed: languageMouse.pressed
                    interactive: true
                    showSheen: false

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 14
                        spacing: 12

                        RaohaneIcon {
                            text: languageCard.selected ? "check_circle" : "language"
                            iconSize: 20
                            fill: languageCard.selected ? 1 : 0
                            color: languageCard.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
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

                        Text {
                            visible: languageCard.selected
                            text: qsTr("Current")
                            color: RaohaneTheme.accent
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
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
