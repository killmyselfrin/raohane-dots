import QtQuick

Rectangle {
    id: root

    implicitWidth: {
        const titleWidth = titleMetrics.advanceWidth
        const detailWidth = detailMetrics.advanceWidth
        return Math.max(196, Math.min(440, Math.max(titleWidth, detailWidth) + 112))
    }
    implicitHeight: RaohaneTheme.islandHeight
    radius: height / 2
    color: RaohaneTheme.glassStrong
    border.width: 1
    border.color: RaohaneContext.mode === "recording"
        ? RaohaneTheme.critical
        : RaohaneTheme.borderStrong

    // The island remains the signature center pod, but minimal themes separate
    // it from the wallpaper with one quiet outer hairline rather than a glow.
    Rectangle {
        z: -2
        anchors.centerIn: parent
        width: parent.width + 8
        height: parent.height + 8
        radius: height / 2
        color: "transparent"
        border.width: 1
        border.color: RaohaneContext.mode === "recording"
            ? RaohaneTheme.critical
            : RaohaneTheme.borderFaint
        opacity: 0.8
    }

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
            ? RaohaneTheme.surfaceHover
            : RaohaneTheme.surfaceSubtle
        border.width: 1
        border.color: RaohaneContext.mode === "recording"
            ? RaohaneTheme.critical
            : RaohaneTheme.border

        Text {
            anchors.centerIn: parent
            text: RaohaneContext.icon
            color: RaohaneContext.mode === "recording"
                ? RaohaneTheme.critical
                : RaohaneTheme.accent
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
    }

    Column {
        anchors.left: iconPlate.right
        anchors.leftMargin: 10
        anchors.right: statusDots.left
        anchors.rightMargin: 10
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
            font.pixelSize: 9
            font.letterSpacing: 0.1
            elide: Text.ElideRight
        }
    }

    Row {
        id: statusDots
        anchors {
            right: parent.right
            rightMargin: 13
            verticalCenter: parent.verticalCenter
        }
        spacing: 4

        Repeater {
            model: 3
            delegate: Rectangle {
                required property int index
                width: index === 1 ? 5 : 3
                height: width
                radius: width / 2
                color: index === 1 ? RaohaneTheme.accent : RaohaneTheme.textFaint
                opacity: index === 1 ? 0.8 : 0.4
            }
        }
    }

    TextMetrics {
        id: titleMetrics
        font.pixelSize: 12
        text: RaohaneContext.title
    }
    TextMetrics {
        id: detailMetrics
        font.pixelSize: 9
        text: RaohaneContext.detail
    }
}
