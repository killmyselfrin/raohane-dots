pragma Singleton

import QtQuick

QtObject {
    function normalizedName(value): string {
        let name = String(value ?? "").trim()
        if (!name.length)
            return ""

        const queryIndex = name.indexOf("?")
        if (queryIndex >= 0)
            name = name.slice(0, queryIndex)

        const slashIndex = name.lastIndexOf("/")
        if (slashIndex >= 0)
            name = name.slice(slashIndex + 1)

        if (name.endsWith("-symbolic"))
            name = name.slice(0, -9)

        return name.toLowerCase()
    }

    function materialSymbol(value): string {
        const name = normalizedName(value)

        if (name === "image-x-generic")
            return "image"
        if (name === "image-missing")
            return "broken_image"
        if (name === "application-x-executable")
            return "apps"
        if (name === "hyprland-dialog")
            return "select_window_2"

        if (name.startsWith("network-wireless")) {
            if (name.includes("disconnected") || name.includes("offline") || name.includes("off"))
                return "signal_wifi_off"
            return "wifi"
        }

        if (name.startsWith("network-wired"))
            return "lan"
        if (name.startsWith("network-vpn"))
            return "vpn_lock"

        return ""
    }
}
