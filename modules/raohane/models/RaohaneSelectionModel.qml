import QtQuick

QtObject {
    id: root

    property int count: 0
    property int currentIndex: 0
    readonly property bool hasItems: count > 0

    function normalize(index: int): int {
        if (root.count <= 0)
            return 0
        return Math.max(0, Math.min(root.count - 1, index))
    }

    function reset(): void {
        root.currentIndex = 0
    }

    function select(index: int): void {
        root.currentIndex = root.normalize(index)
    }

    function move(delta: int): void {
        root.select(root.currentIndex + delta)
    }

    onCountChanged: root.currentIndex = root.normalize(root.currentIndex)
}
