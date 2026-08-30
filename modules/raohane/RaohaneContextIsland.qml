import QtQuick

import qs.modules.raohane.config

RaohaneSurface {
    id: root

    readonly property var styleConfig: RaohaneConfig.style ?? ({})
    readonly property real islandScale: Number(styleConfig.contextIslandScale ?? 1.0)
    readonly property bool showDetail: styleConfig.contextIslandDetail === undefined ? true : Boolean(styleConfig.contextIslandDetail)
    readonly property bool showIndicators: styleConfig.contextIslandIndicators === undefined ? true : Boolean(styleConfig.contextIslandIndicators)

    implicitWidth: {
        const titleWidth = titleMetrics.advanceWidth
        const detailWidth = root.showDetail ? detailMetrics.advanceWidth : 0
        const contentWidth = Math.max(titleWidth, detailWidth) + (root.showIndicators ? 96 : 82)
        return Math.max(170, Math.min(500, Math.round(contentWidth * root.islandScale)))
    }
    implicitHeight: Math.max(38, Math.min(50, Math.round(RaohaneTheme.islandHeight * root.islandScale)))
    surfaceRadius: height / 2
    raised: true
    showSheen: false
    border.color: RaohaneContext.mode === "recording"
        ? RaohaneTheme.critical
        : RaohaneTheme.borderStrong

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
        width: Math.max(29, Math.min(34, Math.round(root.height * 0.72)))
        height: width
        radius: width / 2
        anchors.left: parent.left
        anchors.leftMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        color: RaohaneTheme.surfaceSubtle
        border.width: 1
        border.color: RaohaneContext.mode === "recording"
            ? RaohaneTheme.critical
            : RaohaneTheme.border

        RaohaneIcon {
            anchors.centerIn: parent
            text: RaohaneContext.icon
            iconSize: 15
            fill: RaohaneContext.mode === "media" || RaohaneContext.mode === "recording" ? 1 : 0
            color: RaohaneContext.mode === "recording"
                ? RaohaneTheme.critical
                : RaohaneTheme.accent
        }
    }

    Column {
        anchors.left: iconPlate.right
        anchors.leftMargin: 10
        anchors.right: root.showIndicators ? statusIndicator.left : parent.right
        anchors.rightMargin: root.showIndicators ? 11 : 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.showDetail ? 0 : -1

        Text {
            width: parent.width
            text: RaohaneContext.title
            color: RaohaneTheme.text
            font.pixelSize: root.showDetail ? 11 : 10
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: root.showDetail
            text: RaohaneContext.detail
            color: RaohaneTheme.textMuted
            font.pixelSize: 8
            elide: Text.ElideRight
        }
    }

    Rectangle {
        id: statusIndicator
        visible: root.showIndicators
        anchors {
            right: parent.right
            rightMargin: 13
            verticalCenter: parent.verticalCenter
        }
        width: 6
        height: 6
        radius: 3
        color: RaohaneContext.mode === "recording"
            ? RaohaneTheme.critical
            : RaohaneContext.mode === "privacy"
                ? RaohaneTheme.warning
                : RaohaneTheme.accent
        opacity: RaohaneContext.mode === "idle" ? 0.45 : 0.9
    }

    TextMetrics {
        id: titleMetrics
        font.pixelSize: 11
        text: RaohaneContext.title
    }
    TextMetrics {
        id: detailMetrics
        font.pixelSize: 8
        text: RaohaneContext.detail
    }
}
