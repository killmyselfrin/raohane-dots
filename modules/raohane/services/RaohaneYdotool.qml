pragma Singleton

import Quickshell

Singleton {
    id: root

    property int shiftMode: 0 // 0 off, 1 one-shot, 2 locked
    readonly property var shiftKeys: [42, 54]

    function press(keycode: int): void {
        if (keycode === undefined || keycode === null)
            return
        Quickshell.execDetached(["ydotool", "key", "--key-delay", "0", `${keycode}:1`])
    }

    function release(keycode: int): void {
        if (keycode === undefined || keycode === null)
            return
        Quickshell.execDetached(["ydotool", "key", "--key-delay", "0", `${keycode}:0`])
    }

    function releaseShiftKeys(): void {
        Quickshell.execDetached([
            "ydotool", "key", "--key-delay", "0",
            ...root.shiftKeys.map(keycode => `${keycode}:0`)
        ])
        root.shiftMode = 0
    }

    function releaseAllKeys(): void {
        const keycodes = Array.from(Array(249).keys())
        Quickshell.execDetached([
            "ydotool", "key", "--key-delay", "0",
            ...keycodes.map(keycode => `${keycode}:0`)
        ])
        root.shiftMode = 0
    }
}
