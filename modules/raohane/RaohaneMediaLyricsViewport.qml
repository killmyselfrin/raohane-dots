pragma ComponentBehavior: Bound

import QtQuick

ListView {
    id: root

    property var lines: []
    property bool focusMode: false
    property bool syncedAvailable: false
    property int syncedIndex: -1
    property bool canSeek: false
    property color accent: RaohaneTheme.accent
    property color focusActive: RaohaneTheme.text
    property color focusSecondary: RaohaneTheme.textMuted
    property color focusHalo: "transparent"

    signal seekRequested(real time)

    model: root.lines
    currentIndex: root.syncedAvailable ? root.syncedIndex : -1
    clip: true
    spacing: root.focusMode ? 9 : 4
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 2200
    cacheBuffer: root.focusMode ? height * 1.5 : 0

    function centerCurrentLine(animated: bool): void {
        if (!root.syncedAvailable || root.syncedIndex < 0 || root.count <= 0)
            return

        const item = root.itemAtIndex(root.syncedIndex)
        if (!item) {
            root.positionViewAtIndex(root.syncedIndex, ListView.Center)
            return
        }

        const maxContentY = Math.max(0, root.contentHeight - root.height)
        const targetContentY = Math.max(0, Math.min(maxContentY,
            item.y + item.height / 2 - root.height / 2))

        if (animated && RaohaneMotion.enabled) {
            scrollAnimation.stop()
            scrollAnimation.from = root.contentY
            scrollAnimation.to = targetContentY
            scrollAnimation.start()
        } else {
            root.contentY = targetContentY
        }
    }

    NumberAnimation {
        id: scrollAnimation
        target: root
        property: "contentY"
        duration: RaohaneMotion.standard
        easing.type: RaohaneMotion.easeStandard
    }

    delegate: RaohaneMediaLyricLine {
        required property var modelData
        required property int index

        width: ListView.view.width
        lineData: modelData
        current: root.syncedAvailable && index === root.syncedIndex
        focusMode: root.focusMode
        seekEnabled: root.syncedAvailable
            && Number(modelData.time) >= 0
            && root.canSeek
        accent: root.accent
        focusActive: root.focusActive
        focusSecondary: root.focusSecondary
        focusHalo: root.focusHalo
        onSeekRequested: time => root.seekRequested(time)
    }
}
