import QtQuick

import qs.modules.raohane.config
import qs.modules.raohane.services

RaohaneSurface {
    id: root

    property string densityMode: "full"  // full | compact | icon
    // Only the Bar passes this flag. Other Context Island instances keep
    // their original material and urgent state emphasis.
    property bool chromaticBackground: false
    readonly property bool condensed: densityMode !== "full"
    readonly property bool iconOnly: densityMode === "icon"
    readonly property var styleConfig: RaohaneConfig.style ?? ({})
    readonly property real islandScale: Number(styleConfig.contextIslandScale ?? 1.0)
    readonly property bool showDetail: !root.condensed
        && (styleConfig.contextIslandDetail === undefined ? true : Boolean(styleConfig.contextIslandDetail))
    readonly property bool showIndicators: !root.iconOnly
        && (styleConfig.contextIslandIndicators === undefined ? true : Boolean(styleConfig.contextIslandIndicators))
    readonly property bool priorityMode: RaohaneContext.mode === "recording" || RaohaneContext.mode === "privacy"
    readonly property bool progressMode: RaohaneContext.mode === "event" && RaohaneContext.eventProgress >= 0
    readonly property bool mediaMode: RaohaneContext.mode === "media"
    readonly property bool haloStyle: RaohaneConfig.barStylePreset === "halo"
    readonly property bool mediaProgressMode: root.mediaMode
        && RaohaneMedia.available
        && RaohaneMedia.length > 0
    readonly property bool showProgress: !root.iconOnly && (root.progressMode || root.mediaProgressMode)
    readonly property real progressValue: root.progressMode
        ? RaohaneContext.eventProgress
        : root.mediaProgressMode ? RaohaneMedia.progress : 0
    readonly property bool morphMotionAllowed: root.visible
        && RaohaneMotion.transformMotionEnabled
        && !RaohanePerformance.gameModeActive

    readonly property string sceneId: RaohaneScenes.activeSceneId
    readonly property bool sceneActive: root.sceneId !== "balanced"
    readonly property bool sceneAutomatic: RaohaneContext.sceneAutomatic
    readonly property bool sceneMarkerVisible: root.sceneActive
        && RaohaneContext.mode !== "scene"
        && !root.priorityMode
        && RaohaneContext.mode !== "event"
        && !root.showProgress
    readonly property bool gameplayRecording: RaohaneContext.gameplayRecording
    readonly property bool indicatorIsIcon: root.mediaMode
        || RaohaneContext.mode === "scene"
        || root.gameplayRecording
        || (root.sceneActive && !root.priorityMode && RaohaneContext.mode !== "event")

    readonly property color eventColor: RaohaneContext.eventTone === "success"
        ? RaohaneTheme.success
        : RaohaneContext.eventTone === "warning"
            ? RaohaneTheme.warning
            : RaohaneContext.eventTone === "critical"
                ? RaohaneTheme.critical
                : RaohaneContext.eventTone === "accent"
                    ? RaohaneTheme.accent
                    : RaohaneTheme.info
    readonly property color sceneColor: root.sceneId === "gaming"
        ? RaohaneTheme.accent
        : root.sceneId === "focus"
            ? RaohaneTheme.info
            : root.sceneId === "work"
                ? RaohaneTheme.success
                : RaohaneTheme.textFaint
    readonly property color modeColor: RaohaneContext.mode === "recording"
        ? RaohaneTheme.critical
        : RaohaneContext.mode === "privacy"
            ? RaohaneTheme.warning
            : RaohaneContext.mode === "event"
                ? root.eventColor
                : RaohaneContext.mode === "scene"
                    ? root.sceneColor
                    : RaohaneContext.mode === "window"
                        ? RaohaneTheme.accentSecondary
                        : RaohaneTheme.accent
    readonly property int modeMinimumWidth: root.mediaMode ? 220
        : RaohaneContext.mode === "privacy" ? 208
        : RaohaneContext.mode === "recording" ? 218
        : RaohaneContext.mode === "event" ? (root.progressMode ? 214 : 196)
        : RaohaneContext.mode === "scene" ? 224
        : RaohaneContext.mode === "window" ? 186
        : 168

    function sceneIcon(sceneId): string {
        switch (String(sceneId ?? "")) {
        case "gaming": return "sports_esports"
        case "focus": return "center_focus_strong"
        case "work": return "work"
        default: return "circle"
        }
    }

    readonly property string indicatorIcon: root.gameplayRecording ? "stop_circle"
        : root.mediaMode ? "open_in_new"
        : RaohaneContext.mode === "scene" ? (root.sceneAutomatic ? "auto_awesome" : "touch_app")
        : root.sceneActive ? root.sceneIcon(root.sceneId)
        : "circle"

    implicitWidth: {
        if (root.iconOnly)
            return 42
        if (root.condensed)
            return Math.max(130, Math.min(176, Math.round(160 * root.islandScale)))
        const titleWidth = titleMetrics.advanceWidth
        const detailWidth = root.showDetail ? detailMetrics.advanceWidth : 0
        const indicatorSpace = root.showIndicators ? (root.indicatorIsIcon ? 34 : 28) : 10
        const contentWidth = Math.max(titleWidth, detailWidth) + 58 + indicatorSpace
        return Math.max(root.modeMinimumWidth, Math.min(380, Math.round(contentWidth * root.islandScale)))
    }
    implicitHeight: Math.max(38, Math.min(50, Math.round((root.showProgress ? RaohaneTheme.islandHeight + 3 : RaohaneTheme.islandHeight) * root.islandScale)))
    surfaceRadius: Math.min(RaohaneTheme.radiusHero, height / 2)
    // Do not stack an opaque inner capsule on top of Halo's continuous
    // glass backing. Important media/privacy events keep their own emphasis.
    raised: root.priorityMode || (!root.haloStyle && !root.chromaticBackground)
    transparentIdle: (root.haloStyle || root.chromaticBackground) && !root.priorityMode
    showSheen: root.priorityMode || (!root.haloStyle && !root.chromaticBackground)
    showInnerRim: root.priorityMode || (!root.haloStyle && !root.chromaticBackground)
    clip: true
    border.width: (root.haloStyle || root.chromaticBackground) && !root.priorityMode ? 0 : 1
    border.color: root.priorityMode
        ? Qt.rgba(root.modeColor.r, root.modeColor.g, root.modeColor.b, 0.72)
        : RaohaneContext.mode === "event"
            ? Qt.rgba(root.modeColor.r, root.modeColor.g, root.modeColor.b, 0.42)
            : RaohaneContext.mode === "scene"
                ? Qt.rgba(root.sceneColor.r, root.sceneColor.g, root.sceneColor.b, 0.46)
                : root.sceneActive
                    ? Qt.rgba(root.sceneColor.r, root.sceneColor.g, root.sceneColor.b, 0.30)
                    : RaohaneTheme.borderStrong

    Behavior on implicitWidth {
        enabled: root.morphMotionAllowed
        NumberAnimation {
            duration: RaohaneMotion.standard
            easing.type: RaohaneMotion.easeEmphasized
        }
    }

    Behavior on implicitHeight {
        enabled: root.morphMotionAllowed
        NumberAnimation {
            duration: RaohaneMotion.shortDuration
            easing.type: RaohaneMotion.easeEmphasized
        }
    }

    Behavior on border.color {
        enabled: root.morphMotionAllowed
        ColorAnimation { duration: RaohaneMotion.micro }
    }

    Rectangle {
        id: activityWash
        anchors.fill: parent
        radius: parent.radius
        visible: RaohaneContext.mode === "event" || RaohaneContext.mode === "scene"
        color: root.modeColor
        opacity: RaohaneContext.mode === "scene" ? 0.035 : 0.045

        Behavior on color { enabled: root.morphMotionAllowed; ColorAnimation { duration: RaohaneMotion.micro } }
        Behavior on opacity { enabled: root.morphMotionAllowed; NumberAnimation { duration: RaohaneMotion.micro } }
    }

    Rectangle {
        id: sceneMarker
        visible: root.sceneMarkerVisible
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: 14
            bottomMargin: 4
        }
        width: Math.max(22, Math.min(42, Math.round(root.width * 0.12)))
        height: 2
        radius: 1
        color: root.sceneColor
        opacity: RaohaneScenes.autoSceneActive ? 0.94 : 0.62

        Behavior on width {
            enabled: root.morphMotionAllowed
            NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeEmphasized }
        }
        Behavior on color { enabled: root.morphMotionAllowed; ColorAnimation { duration: RaohaneMotion.micro } }
        Behavior on opacity { enabled: root.morphMotionAllowed; NumberAnimation { duration: RaohaneMotion.micro } }
    }

    Rectangle {
        id: iconPlate
        width: Math.max(29, Math.min(34, Math.round(root.height * 0.70)))
        height: width
        radius: Math.min(RaohaneTheme.radiusSmall, width / 2)
        anchors.left: parent.left
        anchors.leftMargin: root.iconOnly ? 5 : 7
        anchors.verticalCenter: parent.verticalCenter
        color: Qt.rgba(root.modeColor.r, root.modeColor.g, root.modeColor.b,
            root.priorityMode ? 0.16 : RaohaneContext.mode === "idle" ? 0.055 : RaohaneContext.mode === "scene" ? 0.13 : 0.10)
        border.width: 1
        border.color: Qt.rgba(root.modeColor.r, root.modeColor.g, root.modeColor.b,
            root.priorityMode ? 0.56 : RaohaneContext.mode === "event" ? 0.38 : RaohaneContext.mode === "scene" ? 0.40 : 0.24)

        Behavior on color { enabled: root.morphMotionAllowed; ColorAnimation { duration: RaohaneMotion.micro } }
        Behavior on border.color { enabled: root.morphMotionAllowed; ColorAnimation { duration: RaohaneMotion.micro } }

        RaohaneIcon {
            anchors.centerIn: parent
            text: RaohaneContext.icon
            iconSize: root.priorityMode ? 16 : 15
            fill: root.mediaMode
                || RaohaneContext.mode === "recording"
                || RaohaneContext.mode === "privacy"
                || RaohaneContext.mode === "event"
                || RaohaneContext.mode === "scene" ? 1 : 0
            symbolWeight: root.priorityMode || RaohaneContext.mode === "event" || RaohaneContext.mode === "scene" ? 560 : 470
            color: root.modeColor

            Behavior on color { enabled: root.morphMotionAllowed; ColorAnimation { duration: RaohaneMotion.micro } }
        }
    }

    Column {
        visible: !root.iconOnly
        anchors.left: iconPlate.right
        anchors.leftMargin: 9
        anchors.right: root.showIndicators ? statusIndicator.left : parent.right
        anchors.rightMargin: root.showIndicators ? 8 : 13
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.showProgress ? -2 : 0
        spacing: root.showDetail ? 1 : 0

        Text {
            width: parent.width
            text: RaohaneContext.title
            color: RaohaneTheme.text
            font.pixelSize: 11
            font.weight: root.priorityMode || RaohaneContext.mode === "event" || RaohaneContext.mode === "scene" ? Font.DemiBold : Font.Medium
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: root.showDetail && text.length > 0
            text: RaohaneContext.detail
            color: root.priorityMode || RaohaneContext.mode === "event" || RaohaneContext.mode === "scene"
                ? root.modeColor
                : RaohaneTheme.textMuted
            opacity: root.priorityMode ? 0.90 : RaohaneContext.mode === "event" || RaohaneContext.mode === "scene" ? 0.82 : 1
            font.pixelSize: 9
            elide: Text.ElideRight

            Behavior on color { enabled: root.morphMotionAllowed; ColorAnimation { duration: RaohaneMotion.micro } }
        }
    }

    Item {
        id: statusIndicator
        visible: root.showIndicators
        anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        width: root.indicatorIsIcon ? 18 : 12
        height: 20

        Rectangle {
            visible: !root.indicatorIsIcon
            anchors.centerIn: parent
            width: root.priorityMode ? 3 : 6
            height: root.priorityMode ? 15 : 6
            radius: width / 2
            color: root.modeColor
            opacity: RaohaneContext.mode === "idle" ? 0.38 : 0.88

            Behavior on width {
                enabled: root.morphMotionAllowed
                NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeEmphasized }
            }
            Behavior on height {
                enabled: root.morphMotionAllowed
                NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeEmphasized }
            }
            Behavior on color { enabled: root.morphMotionAllowed; ColorAnimation { duration: RaohaneMotion.micro } }
            Behavior on opacity { enabled: root.morphMotionAllowed; NumberAnimation { duration: RaohaneMotion.micro } }
        }

        RaohaneIcon {
            visible: root.indicatorIsIcon
            anchors.centerIn: parent
            text: root.indicatorIcon
            iconSize: root.gameplayRecording ? 14 : 12
            fill: 1
            symbolWeight: 600
            color: root.gameplayRecording ? RaohaneTheme.critical
                : root.mediaMode ? root.modeColor
                : root.sceneColor
            scale: root.morphMotionAllowed && recorderMouse.containsMouse && root.gameplayRecording ? 1.08 : 1

            Behavior on color { enabled: root.morphMotionAllowed; ColorAnimation { duration: RaohaneMotion.micro } }
            Behavior on scale { enabled: root.morphMotionAllowed; NumberAnimation { duration: RaohaneMotion.micro } }
        }

        MouseArea {
            id: recorderMouse
            anchors.fill: parent
            enabled: root.gameplayRecording
            hoverEnabled: enabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: RaohaneRecorder.stop()
        }
    }

    Rectangle {
        id: progressTrack
        visible: root.showProgress
        anchors {
            left: iconPlate.right
            right: statusIndicator.left
            bottom: parent.bottom
            leftMargin: 9
            rightMargin: 8
            bottomMargin: 5
        }
        height: 3
        radius: height / 2
        color: RaohaneTheme.surfaceSubtle

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.progressValue))
            height: parent.height
            radius: parent.radius
            color: root.modeColor

            Behavior on width {
                enabled: root.morphMotionAllowed
                NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
            }
            Behavior on color { enabled: root.morphMotionAllowed; ColorAnimation { duration: RaohaneMotion.micro } }
        }
    }

    MouseArea {
        id: mediaOpenArea
        anchors.fill: parent
        z: 40
        enabled: root.mediaMode
        hoverEnabled: enabled
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: RaohaneState.mediaOverlayOpen = true
    }

    TextMetrics {
        id: titleMetrics
        font.pixelSize: 11
        font.weight: root.priorityMode || RaohaneContext.mode === "event" || RaohaneContext.mode === "scene" ? Font.DemiBold : Font.Medium
        text: RaohaneContext.title
    }
    TextMetrics {
        id: detailMetrics
        font.pixelSize: 9
        text: RaohaneContext.detail
    }
}
