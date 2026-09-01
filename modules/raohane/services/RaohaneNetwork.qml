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

    property var availableNetworks: []
    property var savedNetworkNames: []
    property bool scanning: false
    property string connectingSsid: ""
    property string lastActionError: ""
    property bool scanWhenEnabled: false

    readonly property int minimumRefreshInterval: 1400
    readonly property string wifiStatus: !wifiEnabled
        ? "disabled"
        : connecting || connectingSsid.length > 0
            ? "connecting"
            : wifiConnected
                ? "connected"
                : "disconnected"

    readonly property string materialSymbol: ethernet
        ? "lan"
        : wifiStatus === "connected"
            ? root.signalIcon(networkStrength)
            : wifiStatus === "connecting"
                ? "signal_wifi_statusbar_not_connected"
                : wifiStatus === "disabled"
                    ? "signal_wifi_off"
                    : "wifi_find"

    function signalIcon(strength): string {
        const value = Number(strength) || 0
        return value > 83 ? "signal_wifi_4_bar"
            : value > 67 ? "network_wifi"
            : value > 50 ? "network_wifi_3_bar"
            : value > 33 ? "network_wifi_2_bar"
            : value > 17 ? "network_wifi_1_bar"
            : "signal_wifi_0_bar"
    }

    function unescapeNmcli(value): string {
        return String(value ?? "")
            .replace(/\\:/g, ":")
            .replace(/\\\\/g, "\\")
    }

    function isSaved(ssid: string): bool {
        return root.savedNetworkNames.indexOf(String(ssid ?? "")) >= 0
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

    function scanNetworks(): void {
        if (!root.wifiEnabled || networkScan.running)
            return
        root.lastActionError = ""
        root.scanning = true
        savedProbe.exec(["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"])
        networkScan.exec(["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list", "--rescan", "yes"])
    }

    function connectNetwork(ssid: string, password: string): void {
        const cleanSsid = String(ssid ?? "").trim()
        if (!cleanSsid.length || networkConnect.running)
            return

        root.lastActionError = ""
        root.connectingSsid = cleanSsid
        const command = ["nmcli", "--wait", "15", "device", "wifi", "connect", cleanSsid]
        const secret = String(password ?? "")
        if (secret.length > 0)
            command.push("password", secret)
        networkConnect.exec(command)
    }

    function finishProbeCycle(): void {
        if (root.probesRunning() || !root.refreshQueued)
            return
        refreshCooldown.interval = root.minimumRefreshInterval
        refreshCooldown.restart()
    }

    function setWifiEnabled(enabled: bool): void {
        root.scanWhenEnabled = enabled
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
            onStreamFinished: {
                const enabled = text.trim() === "enabled"
                const becameEnabled = enabled && !root.wifiEnabled
                root.wifiEnabled = enabled

                if (!enabled) {
                    root.scanWhenEnabled = false
                    root.availableNetworks = []
                } else if (becameEnabled || root.scanWhenEnabled) {
                    root.scanWhenEnabled = false
                    scanDelay.restart()
                }
            }
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
        id: savedProbe
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const names = []
                for (const line of text.trim().split("\n")) {
                    if (!line.length)
                        continue
                    const parts = line.split(":")
                    const type = parts[parts.length - 1] ?? ""
                    if (type !== "802-11-wireless" && type !== "wifi")
                        continue
                    const name = root.unescapeNmcli(parts.slice(0, -1).join(":"))
                    if (name.length && names.indexOf(name) < 0)
                        names.push(name)
                }
                root.savedNetworkNames = names
            }
        }
    }

    Process {
        id: networkScan
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const bySsid = ({})
                for (const line of text.trim().split("\n")) {
                    if (!line.length)
                        continue
                    const parts = line.split(":")
                    if (parts.length < 4)
                        continue
                    const active = (parts[0] ?? "") === "*"
                    const strength = Math.max(0, Math.min(100, Number(parts[1] ?? 0) || 0))
                    const security = String(parts[2] ?? "").trim()
                    const ssid = root.unescapeNmcli(parts.slice(3).join(":"))
                    if (!ssid.length)
                        continue
                    const open = security.length === 0 || security === "--"
                    const candidate = {
                        ssid: ssid,
                        strength: strength,
                        security: security,
                        secure: !open,
                        active: active,
                        saved: root.isSaved(ssid)
                    }
                    if (!bySsid[ssid] || active || strength > Number(bySsid[ssid].strength ?? 0))
                        bySsid[ssid] = candidate
                }

                const networks = Object.keys(bySsid).map(key => bySsid[key])
                networks.sort((left, right) => {
                    if (left.active !== right.active)
                        return left.active ? -1 : 1
                    return Number(right.strength) - Number(left.strength)
                })
                root.availableNetworks = networks
            }
        }
        onExited: {
            root.scanning = false
            root.refresh(true)
        }
    }

    Process {
        id: networkConnect
        environment: ({ LANG: "C", LC_ALL: "C" })
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.lastActionError = "Connection failed"
            root.connectingSsid = ""
            root.refresh(true)
            scanDelay.restart()
        }
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
        id: scanDelay
        interval: 700
        repeat: false
        onTriggered: root.scanNetworks()
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
