import QtQuick

Rectangle {
    id: root

    implicitWidth: {
        const titleWidth = titleMetrics.advanceWidth
        const detailWidth = detailMetrics.advanceWidth
        return Math.max(164, Math.min(420, Math.max(titleWidth, detailWidth) + 76))
    }
    implicitHeight: RaohaneTheme.islandHeight
    radius: height / 2
    color: RaohaneTheme.glassStrong
    border.width: 1
    border.color: RaohaneContext.mode === "recording"
        ? RaohaneTheme.critical : RaohaneTheme.border

    Behavior on implicitWidth {
        NumberAnimation {
            duration: RaohaneTheme.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: iconPlate
        width: 34
        height: 34
        radius: 17
        anchors.left: parent.left
        anchors.leftMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        color: RaohaneContext.mode === "recording"
            ? "#38ff668c" : RaohaneTheme.accentSoft

        Text {
            anchors.centerIn: parent
            text: RaohaneContext.icon
            color: RaohaneContext.mode === "recording"
                ? RaohaneTheme.critical : RaohaneTheme.accent
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }
    }

    Column {
        anchors.left: iconPlate.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Text {
            width: parent.width
            text: RaohaneContext.title
            color: RaohaneTheme.text
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: RaohaneContext.detail
            color: RaohaneTheme.textMuted
            font.pixelSize: 10
            elide: Text.ElideRight
        }
    }

    TextMetrics { id: titleMetrics; font.pixelSize: 12; text: RaohaneContext.title }
    TextMetrics { id: detailMetrics; font.pixelSize: 10; text: RaohaneContext.detail }
}
