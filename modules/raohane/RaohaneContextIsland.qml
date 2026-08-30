import QtQuick

import qs.modules.raohane.config

Rectangle {
    id: root

    readonly property var styleConfig: RaohaneConfig.style ?? ({})
    readonly property real islandScale: Number(styleConfig.contextIslandScale ?? 1.0)
    readonly property bool showDetail: styleConfig.contextIslandDetail === undefined ? true : Boolean(styleConfig.contextIslandDetail)
    readonly property bool showIndicators: styleConfig.contextIslandIndicators === undefined ? true : Boolean(styleConfig.contextIslandIndicators)

    implicitWidth: {
        const titleWidth = titleMetrics.advanceWidth
        const detailWidth = root.showDetail ? detailMetrics.advanceWidth : 0
        const contentWidth = Math.max(titleWidth, detailWidth) + (root.showIndicators ? 112 : 88)
        return Math.max(176, Math.min(520, Math.round(contentWidth * root.islandScale)))
    }
    implicitHeight: Math.max(38, Math.min(50, Math.round(RaohaneTheme.islandHeight * root.islandScale)))
    radius: height / 2
    color: RaohaneTheme.glassStrong
    border.width: 1
    border.color: RaohaneContext.mode === "recording"
        ? RaohaneTheme.critical
        : RaohaneTheme.borderStrong

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

    Behavior on implicitHeight {
        NumberAnimation {
            duration: RaohaneTheme.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: iconPlate
        width: Math.max(30, Math.min(36, Math.round(root.height * 0.74)))
        height: width
        radius: width / 2
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
        anchors.right: root.showIndicators ? statusDots.left : parent.right
        anchors.rightMargin: root.showIndicators ? 10 : 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.showDetail ? 0 : -1

        Text {
            width: parent.width
            text: RaohaneContext.title
            color: RaohaneTheme.text
            font.pixelSize: root.showDetail ? 12 : 11
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: root.showDetail
            text: RaohaneContext.detail
            color: RaohaneTheme.textMuted
            font.pixelSize: 9
            font.letterSpacing: 0.1
            elide: Text.ElideRight
        }
    }

    Row {
        id: statusDots
        visible: root.showIndicators
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
