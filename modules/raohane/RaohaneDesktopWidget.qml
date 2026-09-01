pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config
import qs.modules.raohane.services

Item {
    id: root

    required property var widgetData
    required property date now
    required property string screenName

    readonly property string widgetType: String(widgetData.type ?? "clock")
    readonly property bool editing: RaohaneState.desktopWidgetEditMode

    width: widgetType === "clock" ? 360 : widgetType === "media" ? 390 : widgetType === "system" ? 320 : 360
    height: widgetType === "clock" ? 222 : widgetType === "media" ? 142 : widgetType === "system" ? 126 : 96
    x: Number(widgetData.x ?? 0.05) * Math.max(1, parent.width - width)
    y: Number(widgetData.y ?? 0.12) * Math.max(1, parent.height - height)
    z: editing ? 20 : 1

    function persistPosition(): void {
        const xRatio = root.x / Math.max(1, root.parent.width - root.width)
        const yRatio = root.y / Math.max(1, root.parent.height - root.height)
        RaohaneConfig.moveDesktopWidget(String(root.widgetData.id), xRatio, yRatio, root.screenName)
    }

    Component.onCompleted: {
        if (root.widgetType === "system" && RaohaneSystemInfo.memory === "")
            RaohaneSystemInfo.refresh()
    }

    RaohaneSurface {
        anchors.fill: parent
        surfaceRadius: root.widgetType === "clock" ? 22 : 18
        raised: root.widgetType !== "clock"
        transparentIdle: root.widgetType === "clock" && !root.editing
        active: root.editing
        showSheen: root.widgetType !== "clock"
        border.color: root.editing ? RaohaneTheme.accentBorder : RaohaneTheme.border
    }

    ColumnLayout {
        visible: root.widgetType === "clock"
        anchors.fill: parent
        anchors.margins: 18
        spacing: 1

        RowLayout {
            spacing: 9

            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: RaohaneTheme.accent
                opacity: 0.9
            }

            Text {
                text: "ラオハネ  ·  RAOHANE"
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                font.weight: Font.DemiBold
                font.letterSpacing: 1.4
            }
        }

        Text {
            Layout.topMargin: 5
            text: Qt.formatTime(root.now, "HH:mm")
            color: RaohaneTheme.text
            font.pixelSize: 68
            font.weight: Font.Light
            font.letterSpacing: -2.8
        }

        Text {
            text: Qt.formatDate(root.now, "dddd, d MMMM")
            color: RaohaneTheme.textMuted
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        Rectangle {
            Layout.topMargin: 12
            Layout.preferredWidth: 118
            Layout.preferredHeight: 1
            color: RaohaneTheme.accent
            opacity: 0.58
        }

        Text {
            Layout.topMargin: 7
            text: qsTr("静けさの中で動く")
            color: RaohaneTheme.textMuted
            opacity: 0.72
            font.pixelSize: 8
            font.letterSpacing: 0.7
        }
    }

    RowLayout {
        visible: root.widgetType === "context"
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        RaohaneSurface {
            Layout.preferredWidth: 46
            Layout.preferredHeight: 46
            surfaceRadius: 15
            active: RaohaneContext.mode === "privacy" || RaohaneContext.mode === "recording"
            showSheen: false

            RaohaneIcon {
                anchors.centerIn: parent
                text: RaohaneContext.icon
                iconSize: 20
                fill: RaohaneContext.mode === "idle" ? 0 : 1
                color: RaohaneTheme.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: RaohaneContext.title
                color: RaohaneTheme.text
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: RaohaneContext.detail
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: RaohaneContext.mode === "media" ? qsTr("music is part of the room") : qsTr("live desktop context")
                color: RaohaneTheme.textFaint
                font.pixelSize: 7
                elide: Text.ElideRight
            }
        }
    }

    RowLayout {
        visible: root.widgetType === "media"
        anchors.fill: parent
        anchors.margins: 14
        spacing: 13

        RaohaneSurface {
            Layout.preferredWidth: 108
            Layout.fillHeight: true
            surfaceRadius: 14
            showSheen: false
            clip: true

            Image {
                id: mediaArt
                anchors.fill: parent
                source: RaohaneMedia.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }

            RaohaneIcon {
                anchors.centerIn: parent
                visible: !mediaArt.visible
                text: "music_note"
                iconSize: 30
                color: RaohaneTheme.textFaint
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 3

            Text {
                Layout.fillWidth: true
                text: RaohaneMedia.available ? RaohaneMedia.title : qsTr("Nothing playing")
                color: RaohaneTheme.text
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: RaohaneMedia.available ? (RaohaneMedia.artist || RaohaneMedia.playerName) : qsTr("Start a player to fill this space")
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                elide: Text.ElideRight
            }

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 3
                radius: 2
                color: RaohaneTheme.borderFaint

                Rectangle {
                    width: parent.width * RaohaneMedia.progress
                    height: parent.height
                    radius: parent.radius
                    color: RaohaneTheme.accent
                }
            }

            Text {
                text: RaohaneMedia.available
                    ? RaohaneMedia.formatTime(RaohaneMedia.position) + "  /  " + RaohaneMedia.formatTime(RaohaneMedia.length)
                    : qsTr("MPRIS ready")
                color: RaohaneTheme.textFaint
                font.pixelSize: 7
            }
        }
    }

    ColumnLayout {
        visible: root.widgetType === "system"
        anchors.fill: parent
        anchors.margins: 15
        spacing: 7

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: RaohaneSystemInfo.hostname || qsTr("This system")
                color: RaohaneTheme.text
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            RaohaneIcon {
                text: "memory"
                iconSize: 16
                color: RaohaneTheme.accent
            }
        }

        MetricRow { label: qsTr("Memory"); value: RaohaneSystemInfo.memory || qsTr("Loading…") }
        MetricRow { label: qsTr("Disk"); value: RaohaneSystemInfo.disk || qsTr("Loading…") }
        MetricRow { label: qsTr("Kernel"); value: RaohaneSystemInfo.kernelVersion || qsTr("Loading…") }
    }

    Rectangle {
        visible: root.editing
        anchors.fill: parent
        radius: 19
        color: "transparent"
        border.width: 1
        border.color: RaohaneTheme.accentBorder
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: root.editing
        acceptedButtons: Qt.LeftButton
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.target: root
        drag.minimumX: 0
        drag.maximumX: Math.max(0, root.parent.width - root.width)
        drag.minimumY: 0
        drag.maximumY: Math.max(0, root.parent.height - root.height)
        onReleased: root.persistPosition()
    }

    RaohaneIconButton {
        visible: root.editing
        z: 40
        anchors {
            top: parent.top
            right: parent.right
            topMargin: -10
            rightMargin: -10
        }
        buttonSize: 28
        iconSize: 14
        icon: "close"
        emphasized: true
        onClicked: RaohaneConfig.removeDesktopWidget(String(root.widgetData.id))
    }

    component MetricRow: RowLayout {
        required property string label
        required property string value

        Layout.fillWidth: true
        spacing: 10

        Text {
            Layout.preferredWidth: 54
            text: parent.label
            color: RaohaneTheme.textFaint
            font.pixelSize: 8
        }

        Text {
            Layout.fillWidth: true
            text: parent.value
            color: RaohaneTheme.textMuted
            font.pixelSize: 8
            elide: Text.ElideRight
        }
    }
}
