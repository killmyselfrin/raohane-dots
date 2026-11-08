pragma ComponentBehavior: Bound

import QtQuick
import "RaohaneLyricEffects.js" as LyricEffects

// A single, bounded decoration behind one semantic word of the active line.
// Nothing here animates the text glyphs, fetches media data, or polls a player.
Item {
    id: root

    required property string lineText
    required property font lyricFont
    property bool active: false
    property bool focusMode: false
    property string mode: "off"
    property color accent: RaohaneTheme.accent

    readonly property var match: root.active ? LyricEffects.detect(root.lineText) : null
    readonly property var wordBounds: root.measureWord()
    readonly property bool expressive: root.mode === "expressive"
    readonly property color tint: root.match?.motif === "flame" ? "#e7a07f"
        : root.match?.motif === "rain" || root.match?.motif === "wave" ? "#83b7d9"
        : root.match?.motif === "heart" || root.match?.motif === "petal" ? "#d9a0c5"
        : root.match?.motif === "leaf" ? "#98bca1"
        : root.match?.motif === "star" || root.match?.motif === "light" ? "#d8c3a0"
        : root.accent

    visible: root.active && root.mode !== "off" && root.wordBounds !== null
    clip: true

    function measureWord(): var {
        if (!root.match || root.width < 1 || layoutProbe.contentHeight < 1)
            return null
        const start = layoutProbe.positionToRectangle(root.match.start)
        const end = layoutProbe.positionToRectangle(root.match.end)
        if (![start.x, start.y, end.x, end.y].every(Number.isFinite))
            return null
        // A word split across two rendered rows cannot be decorated safely.
        if (Math.abs(start.y - end.y) > 1 || end.x <= start.x)
            return null
        const centerX = (start.x + end.x) / 2
        const centerY = start.y + start.height / 2
        return {
            x: Math.max(8, Math.min(root.width - 8, centerX)),
            y: Math.max(7, Math.min(root.height - 7, centerY)),
            width: Math.min(110, end.x - start.x)
        }
    }

    // TextEdit gives actual caret geometry after wrapping, unlike measuring
    // a flat prefix with FontMetrics. It is invisible and never takes input.
    TextEdit {
        id: layoutProbe
        anchors.fill: parent
        text: root.lineText
        font: root.lyricFont
        horizontalAlignment: TextEdit.AlignHCenter
        verticalAlignment: TextEdit.AlignVCenter
        wrapMode: TextEdit.WordWrap
        textMargin: 0
        readOnly: true
        selectByMouse: false
        activeFocusOnPress: false
        opacity: 0
    }

    Item {
        id: decoration
        visible: root.wordBounds !== null
        x: (root.wordBounds?.x ?? 0) - width / 2
        y: (root.wordBounds?.y ?? 0) - height / 2
        width: Math.min(root.width, (root.wordBounds?.width ?? 24) + (root.expressive ? 30 : 18))
        height: root.focusMode ? 25 : 18

        Rectangle {
            id: aura
            anchors.centerIn: parent
            width: parent.width
            height: parent.height * 0.78
            radius: height / 2
            color: root.tint
            opacity: root.expressive ? 0.14 : 0.075

            SequentialAnimation on opacity {
                running: root.visible
                loops: Animation.Infinite
                NumberAnimation { to: root.expressive ? 0.21 : 0.11; duration: 1450; easing.type: Easing.InOutSine }
                NumberAnimation { to: root.expressive ? 0.10 : 0.055; duration: 1450; easing.type: Easing.InOutSine }
            }
        }

        Repeater {
            model: root.expressive ? 3 : 2

            delegate: Text {
                id: ornament
                required property int index
                readonly property string motif: String(root.match?.motif ?? "star")
                text: motif === "rain" ? "·"
                    : motif === "snow" ? "✳"
                    : motif === "flame" ? "◦"
                    : motif === "heart" ? "♡"
                    : motif === "petal" || motif === "leaf" ? "❊"
                    : motif === "wing" || motif === "wind" ? "⌁"
                    : motif === "wave" ? "∿"
                    : motif === "shadow" ? "∙"
                    : motif === "ring" ? "◌" : "✧"
                x: index === 0 ? -2 : index === 1 ? decoration.width - width + 2 : decoration.width * 0.52
                y: index === 2 ? -8 : index === 0 ? -5 : decoration.height - height + 5
                color: root.tint
                font.pixelSize: root.focusMode ? 12 : 9
                opacity: root.expressive ? 0.75 : 0.42

                SequentialAnimation on opacity {
                    running: root.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.23; duration: 1250 + ornament.index * 230 }
                    NumberAnimation { to: root.expressive ? 0.78 : 0.49; duration: 1250 + ornament.index * 230 }
                }
            }
        }
    }
}
