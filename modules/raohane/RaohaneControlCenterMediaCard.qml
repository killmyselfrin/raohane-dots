pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

RaohaneSurface {
    id: root

    property bool mediaAvailable: false
    property bool playing: false
    property bool canGoPrevious: false
    property bool canTogglePlaying: false
    property bool canGoNext: false
    property real progress: 0
    property url artUrl: ""
    property string playerName: ""
    property string title: qsTr("Nothing playing")
    property string subtitle: qsTr("Media controls")
    property string elapsedText: "--:--"
    property string totalText: "—"

    signal openRequested()
    signal previousRequested()
    signal togglePlayingRequested()
    signal nextRequested()

    readonly property real clampedProgress: Math.max(0, Math.min(1, Number(root.progress) || 0))

    implicitHeight: 142
    surfaceRadius: RaohaneTheme.radiusLarge
    raised: false
    showSheen: false
    showInnerRim: false
    interactive: true
    hovered: summaryMouse.containsMouse
    pressed: summaryMouse.pressed
    hoverScale: 1
    pressedScale: 1
    idleColor: RaohaneTheme.surfaceSubtle
    hoverColor: RaohaneTheme.surfaceHover
    idleBorderColor: RaohaneTheme.borderFaint
    hoverBorderColor: RaohaneTheme.borderStrong
    showStateRail: root.playing
    stateRailColor: RaohaneTheme.accent
    stateRailWidth: 2
    stateRailLength: 30
    stateRailOpacity: 0.72
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: RaohaneTheme.spacing
        spacing: RaohaneTheme.spacingSmall

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                spacing: RaohaneTheme.spacing

                RaohaneSurface {
                    Layout.preferredWidth: 68
                    Layout.preferredHeight: 68
                    Layout.alignment: Qt.AlignVCenter
                    surfaceRadius: RaohaneTheme.radiusLarge
                    raised: false
                    showSheen: false
                    showInnerRim: false
                    idleColor: RaohaneTheme.surfaceDeep
                    idleBorderColor: root.playing ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint
                    clip: true

                    Image {
                        id: mediaArt
                        anchors.fill: parent
                        source: root.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    RaohaneIcon {
                        anchors.centerIn: parent
                        visible: !mediaArt.visible
                        text: "music_note"
                        iconSize: 25
                        fill: root.playing ? 1 : 0
                        symbolWeight: root.playing ? 540 : 400
                        color: root.playing ? RaohaneTheme.accent : RaohaneTheme.textFaint
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Math.max(1, RaohaneTheme.spacingTiny - 1)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: RaohaneTheme.spacingSmall

                        Text {
                            Layout.fillWidth: true
                            text: root.mediaAvailable ? qsTr("Now playing") : qsTr("Media")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.7
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: root.playerName.length > 0
                            text: root.playerName
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.title
                        color: RaohaneTheme.text
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.subtitle
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        elide: Text.ElideRight
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        radius: 2
                        color: RaohaneTheme.surfaceDeep

                        Rectangle {
                            width: parent.width * root.clampedProgress
                            height: parent.height
                            radius: parent.radius
                            color: RaohaneTheme.accent
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: RaohaneTheme.spacingSmall

                        Text {
                            text: root.elapsedText
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: root.totalText
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                        }
                    }
                }
            }

            MouseArea {
                id: summaryMouse
                anchors.fill: parent
                z: 20
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openRequested()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: RaohaneTheme.divider
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            spacing: RaohaneTheme.spacingSmall

            Item { Layout.fillWidth: true }

            RaohaneIconButton {
                buttonSize: 28
                iconSize: 14
                icon: "skip_previous"
                transparentIdle: true
                showSheen: false
                hoverScale: 1
                pressedScale: 1
                enabled: root.canGoPrevious
                onClicked: root.previousRequested()
            }

            RaohaneIconButton {
                buttonSize: 30
                iconSize: 16
                icon: root.playing ? "pause" : "play_arrow"
                emphasized: root.playing
                transparentIdle: !root.playing
                showSheen: false
                hoverScale: 1
                pressedScale: 1
                enabled: root.canTogglePlaying
                onClicked: root.togglePlayingRequested()
            }

            RaohaneIconButton {
                buttonSize: 28
                iconSize: 14
                icon: "skip_next"
                transparentIdle: true
                showSheen: false
                hoverScale: 1
                pressedScale: 1
                enabled: root.canGoNext
                onClicked: root.nextRequested()
            }

            Item { Layout.fillWidth: true }
        }
    }
}
