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
        : RaohaneTheme.accentBorder

    // Soft neon halo. It intentionally stays cheap: no per-frame shader or
    // blur effect, just layered translucent geometry around the signature pod.
    Rectangle {
        z: -2
        anchors.centerIn: parent
        width: parent.width + 10
        height: parent.height + 10
        radius: height / 2
        color: "transparent"
        border.width: 4
        border.color: RaohaneContext.mode === "recording"
            ? "#24ff6f91"
            : "#24c56cff"
        opacity: 0.75
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 22
            rightMargin: 22
        }
        height: 1
        color: RaohaneContext.mode === "recording"
            ? RaohaneTheme.critical
            : RaohaneTheme.accentSecondary
        opacity: 0.42
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: RaohaneTheme.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: iconPlate
        width: 36
        height: 36
        radius: 18
        anchors.left: parent.left
        anchors.leftMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        color: RaohaneContext.mode === "recording"
            ? "#38ff6f91"
            : RaohaneTheme.accentSoft
        border.width: 1
        border.color: RaohaneContext.mode === "recording"
            ? RaohaneTheme.critical
            : RaohaneTheme.accentGlow

        Rectangle {
            anchors.centerIn: parent
            width: 28
            height: 28
            radius: 14
            color: "#1fffffff"
        }

        Text {
            anchors.centerIn: parent
            text: RaohaneContext.icon
            color: RaohaneContext.mode === "recording"
                ? RaohaneTheme.critical
                : RaohaneTheme.text
            font.pixelSize: 15
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
            font.letterSpacing: 0.15
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
                opacity: index === 1 ? 0.9 : 0.48
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
