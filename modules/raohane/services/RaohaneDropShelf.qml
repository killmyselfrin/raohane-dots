pragma Singleton

import QtQuick
import Quickshell

// Native transient drag/drop shelf backend. It intentionally owns only
// session state; persistence is not required for a transfer shelf.
Singleton {
    id: root

    property var items: []
    property int maxItems: 30
    property bool open: false
    property real positionX: 20
    property real positionY: 220

    function cleanPath(value): string {
        let path = String(value ?? "")
        if (path.startsWith("file://"))
            path = path.substring(7)
        try {
            path = decodeURIComponent(path)
        } catch (error) {
        }
        return path
    }

    function shellQuote(value): string {
        return "'" + String(value ?? "").replace(/'/g, "'\"'\"'") + "'"
    }

    function addItems(urls): void {
        const next = Array.from(root.items)
        for (const url of Array.from(urls ?? [])) {
            const path = root.cleanPath(url)
            if (path.length > 0 && !next.includes(path) && next.length < root.maxItems)
                next.push(path)
        }
        root.items = next
    }

    function show(urls, x: real, y: real): void {
        root.addItems(urls)
        if (Number.isFinite(Number(x)))
            root.positionX = Number(x)
        if (Number.isFinite(Number(y)))
            root.positionY = Number(y)
        root.open = true
    }

    function copyAll(): void {
        if (root.items.length === 0)
            return
        const uriList = root.items.map(path => "file://" + path).join("\n")
        Quickshell.execDetached([
            "bash", "-lc",
            "printf '%s' " + root.shellQuote(uriList) + " | wl-copy --type text/uri-list"
        ])
    }

    function clear(): void {
        root.items = []
        root.open = false
    }

    function hide(): void {
        root.open = false
    }
}
