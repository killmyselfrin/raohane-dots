pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: false
    property bool wifiConnected: false
    property bool ethernet: false
    property bool connecting: false
    property string networkName: ""
    property int networkStrength: 0
    property bool refreshQueued: false
    property double lastRefreshMs: 0

    readonly property int minimumRefreshInterval: 1400
    readonly property string wifiStatus: !wifiEnabled
        ? "disabled"
        : connecting
            ? "connecting"
            : wifiConnected
                ? "connected"
                : "disconnected"

    readonly property string materialSymbol: ethernet
        ? "lan"
        : wifiStatus === "connected"
            ? (networkStrength > 83 ? "signal_wifi_4_bar"
                : networkStrength > 67 ? "network_wifi"
                : networkStrength > 50 ? "network_wifi_3_bar"
                : networkStrength > 33 ? "network_wifi_2_bar"
                : networkStrength > 17 ? "network_wifi_1_bar"
                : "signal_wifi_0_bar")
            : wifiStatus === "connecting"
                ? "signal_wifi_statusbar_not_connected"
                : wifiStatus === "disabled"
                    ? "signal_wifi_off"
                    : "wifi_find"

    function unescapeNmcli(value): string {
        return String(value ?? "").replace(/\\:/g, ":")
    }

    function probesRunning(): bool {
        return radioProbe.running || deviceProbe.running || wifiProbe.running
    }

    // Keep the optional force flag untyped for deployed Quickshell compatibility.
    function refresh(force) {
        const forced = force === true
        if (root.probesRunning()) {
            root.refreshQueued = true
            return
        }

        const now = Date.now()
        const elapsed = now - root.lastRefreshMs
        if (!forced && root.lastRefreshMs > 0 && elapsed < root.minimumRefreshInterval) {
            root.refreshQueued = true
            refreshCooldown.interval = Math.max(120, root.minimumRefreshInterval - elapsed)
            refreshCooldown.restart()
            return
        }

        root.refreshQueued = false
        root.lastRefreshMs = now
        radioProbe.exec(["nmcli", "radio", "wifi"])
        deviceProbe.exec(["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device", "status"])
        wifiProbe.exec(["nmcli", "-t", "-f", "ACTIVE,SIGNAL,SSID", "device", "wifi"])
    }

    function finishProbeCycle(): void {
        if (root.probesRunning() || !root.refreshQueued)
            return
        refreshCooldown.interval = root.minimumRefreshInterval
        refreshCooldown.restart()
    }

    function setWifiEnabled(enabled: bool): void {
        wifiToggle.exec(["nmcli", "radio", "wifi", enabled ? "on" : "off"])
    }

    function toggleWifi(): void {
        root.setWifiEnabled(!root.wifiEnabled)
    }

    Component.onCompleted: root.refresh(true)

    Process {
        id: radioProbe
        environment: ({ LANG: "C", LC_ALL: "C" })

        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
        onExited: root.finishProbeCycle()
    }

    Process {
        id: deviceProbe
        environment: ({ LANG: "C", LC_ALL: "C" })

        stdout: StdioCollector {
            onStreamFinished: {
                let wifiConnected = false
                let ethernet = false
                let connecting = false
                let name = ""

                for (const line of text.trim().split("\n")) {
                    if (!line.length)
                        continue

                    const parts = line.split(":")
                    const type = parts[0] ?? ""
                    const state = parts[1] ?? ""
                    const connection = root.unescapeNmcli(parts.slice(2).join(":"))

                    if (type === "ethernet" && state.startsWith("connected")) {
                        ethernet = true
                        if (!name.length)
                            name = connection
                    }

                    if (type === "wifi") {
                        if (state.startsWith("connected")) {
                            wifiConnected = true
                            name = connection
                        } else if (state.includes("connecting")) {
                            connecting = true
                        }
                    }
                }

                root.wifiConnected = wifiConnected
                root.ethernet = ethernet
                root.connecting = connecting
                root.networkName = name
            }
        }
        onExited: root.finishProbeCycle()
    }

    Process {
        id: wifiProbe
        environment: ({ LANG: "C", LC_ALL: "C" })

        stdout: StdioCollector {
            onStreamFinished: {
                let strength = 0
                let ssid = ""

                for (const line of text.trim().split("\n")) {
                    if (!line.startsWith("yes:"))
                        continue

                    const parts = line.split(":")
                    strength = Number(parts[1] ?? 0)
                    ssid = root.unescapeNmcli(parts.slice(2).join(":"))
                    break
                }

                root.networkStrength = Number.isFinite(strength) ? strength : 0
                if (ssid.length)
                    root.networkName = ssid
            }
        }
        onExited: root.finishProbeCycle()
    }

    Process {
        id: wifiToggle
        environment: ({ LANG: "C", LC_ALL: "C" })
        onExited: root.refresh(true)
    }

    // NetworkManager can emit several monitor lines for one state transition.
    // Collapse the whole burst before launching any nmcli snapshots.
    Process {
        id: monitor
        running: true
        command: ["nmcli", "monitor"]
        environment: ({ LANG: "C", LC_ALL: "C" })

        stdout: SplitParser {
            onRead: data => {
                if (data.length > 0)
                    networkDebounce.restart()
            }
        }

        onExited: monitorRestart.restart()
    }

    Timer {
        id: networkDebounce
        interval: 450
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: refreshCooldown
        interval: root.minimumRefreshInterval
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: monitorRestart
        interval: 3500
        repeat: false
        onTriggered: monitor.running = true
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }
}
