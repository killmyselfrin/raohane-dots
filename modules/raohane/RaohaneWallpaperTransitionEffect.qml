pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects

// Shared wallpaper reveal primitive. The Settings previews and the desktop
// renderer both use this component, so the selected transition is not merely
// a decorative mock-up.
Item {
    id: root

    property url source: ""
    property string effectType: "fade"
    property real progress: 1
    property int dissolveColumns: 8
    property int dissolveRows: 5

    readonly property int tileCount: Math.max(1, dissolveColumns * dissolveRows)

    clip: true

    Image {
        id: fadeImage
        anchors.fill: parent
        source: root.effectType === "fade" ? root.source : ""
        sourceSize: Qt.size(Math.max(1, root.width), Math.max(1, root.height))
        asynchronous: true
        cache: true
        smooth: true
        fillMode: Image.PreserveAspectCrop
        visible: root.effectType === "fade"
        opacity: root.progress
    }

    Item {
        id: wipeViewport
        anchors.fill: parent
        clip: true
        visible: root.effectType === "wipe"
        Item {
            width: root.width * Math.max(0, Math.min(1, root.progress))
            height: root.height
            clip: true
            Image {
                width: root.width
                height: root.height
                source: root.effectType === "wipe" ? root.source : ""
                sourceSize: Qt.size(Math.max(1, root.width), Math.max(1, root.height))
                asynchronous: true
                cache: true
                smooth: true
                fillMode: Image.PreserveAspectCrop
            }
        }
    }

    Image {
        id: circleSource
        anchors.fill: parent
        source: root.effectType === "circle" ? root.source : ""
        sourceSize: Qt.size(Math.max(1, root.width), Math.max(1, root.height))
        asynchronous: true
        cache: true
        smooth: true
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    Item {
        id: circleMask
        anchors.fill: parent
        visible: false
        Rectangle {
            readonly property real diameter: Math.max(root.width, root.height) * 1.55
                * Math.max(0, Math.min(1, root.progress))
            width: diameter
            height: diameter
            radius: diameter / 2
            anchors.centerIn: parent
            color: "white"
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: circleSource
        maskEnabled: root.effectType === "circle"
        maskSource: circleMask
        visible: root.effectType === "circle"
    }

    Grid {
        anchors.fill: parent
        columns: Math.max(1, root.dissolveColumns)
        rows: Math.max(1, root.dissolveRows)
        visible: root.effectType === "dissolve"
        Repeater {
            model: root.tileCount
            delegate: Image {
                required property int index
                readonly property int columnIndex: index % Math.max(1, root.dissolveColumns)
                readonly property int rowIndex: Math.floor(index / Math.max(1, root.dissolveColumns))
                readonly property real threshold: {
                    const seed = (index * 37 + rowIndex * 17 + columnIndex * 13) % 101
                    return seed / 101
                }
                width: root.width / Math.max(1, root.dissolveColumns)
                height: root.height / Math.max(1, root.dissolveRows)
                source: root.effectType === "dissolve" ? root.source : ""
                sourceSize: Qt.size(Math.max(1, root.width), Math.max(1, root.height))
                sourceClipRect: Qt.rect(
                    columnIndex / Math.max(1, root.dissolveColumns),
                    rowIndex / Math.max(1, root.dissolveRows),
                    1 / Math.max(1, root.dissolveColumns),
                    1 / Math.max(1, root.dissolveRows)
                )
                asynchronous: true
                cache: true
                smooth: true
                fillMode: Image.Stretch
                visible: threshold <= root.progress
            }
        }
    }
}
