pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.raohane.config

Singleton {
    id: root

    property var monitors: []
    property var profiles: ({})
    property bool ready: false
    property bool profilesReady: false
    property bool bootProfilesApplied: false
    property bool refreshing: false
    property string errorMessage: ""

    property bool pending: false
    property string pendingMonitorName: ""
    property var pendingPrevious: null
    property var pendingConfig: null
    property int revertSeconds: 0

    signal configurationApplied(string monitorName)
    signal configurationConfirmed(string monitorName)
    signal configurationReverted(string monitorName)

    function monitorByName(name: string): var {
        return root.monitors.find(monitor => monitor.name === name) ?? null
    }

    function normalizeMode(value: string): string {
        return String(value ?? "").replace(/Hz$/i, "")
    }

    function currentMode(monitor): string {
        if (!monitor)
            return "preferred"
        const width = Number(monitor.width ?? 0)
        const height = Number(monitor.height ?? 0)
        const rate = Number(monitor.refreshRate ?? 0)
        if (width <= 0 || height <= 0 || rate <= 0)
            return "preferred"
        return `${width}x${height}@${rate.toFixed(2)}`
    }

    function sanitizeConfig(value): var {
        const input = value && typeof value === "object" ? value : {}
        const name = String(input.name ?? "")
        const mode = root.normalizeMode(String(input.mode ?? "preferred")) || "preferred"
        const position = String(input.position ?? "auto") || "auto"
        const scaleNumber = Number(input.scale ?? 1)
        const transform = Math.max(0, Math.min(7, Math.round(Number(input.transform ?? 0))))
        const vrr = Math.max(-1, Math.min(3, Math.round(Number(input.vrr ?? 0))))
        const bitdepth = Number(input.bitdepth) === 10 ? 10 : 8
        return {
            name: name,
            mode: mode,
            position: position,
            scale: isNaN(scaleNumber) || scaleNumber <= 0 ? 1 : Math.max(0.5, Math.min(4, scaleNumber)),
            transform: transform,
            vrr: vrr,
            bitdepth: bitdepth
        }
    }

    function currentConfiguration(name: string): var {
        const monitor = root.monitorByName(name)
        if (!monitor)
            return null

        const saved = root.profiles?.[name] ?? null
        const format = String(monitor.currentFormat ?? "")
        return root.sanitizeConfig({
            name: name,
            mode: root.currentMode(monitor),
            position: `${Math.round(Number(monitor.x ?? 0))}x${Math.round(Number(monitor.y ?? 0))}`,
            scale: Number(monitor.scale ?? 1),
            transform: Number(monitor.transform ?? 0),
            vrr: saved ? Number(saved.vrr ?? 0) : (monitor.vrr ? 1 : 0),
            bitdepth: saved ? Number(saved.bitdepth ?? 8) : (format.includes("2101010") || format.includes("101010") ? 10 : 8)
        })
    }

    function buildRule(value): string {
        const config = root.sanitizeConfig(value)
        if (config.name.length === 0)
            return ""
        return `${config.name},${config.mode},${config.position},${config.scale},transform,${config.transform},vrr,${config.vrr},bitdepth,${config.bitdepth}`
    }

    function luaString(value): string {
        return `"${String(value ?? "")
            .replace(/\\/g, "\\\\")
            .replace(/"/g, "\\\"")
            .replace(/\r/g, "\\r")
            .replace(/\n/g, "\\n")}"`
    }

    function buildLuaRule(value): string {
        const config = root.sanitizeConfig(value)
        if (config.name.length === 0)
            return ""
        return `hl.monitor({ output = ${root.luaString(config.name)}, mode = ${root.luaString(config.mode)}, position = ${root.luaString(config.position)}, scale = ${config.scale}, transform = ${config.transform}, vrr = ${config.vrr}, bitdepth = ${config.bitdepth} })`
    }

    function applyRule(value): void {
        const code = root.buildLuaRule(value)
        if (code.length === 0)
            return
        root.errorMessage = ""
        Quickshell.execDetached(["hyprctl", "eval", code])
        refreshDelay.restart()
    }

    function applyTemporary(value): void {
        const config = root.sanitizeConfig(value)
        if (config.name.length === 0)
            return

        if (root.pending)
            root.revertTemporary()

        root.pendingPrevious = root.currentConfiguration(config.name)
        if (!root.pendingPrevious) {
            root.errorMessage = qsTr("Could not capture the current monitor state.")
            return
        }

        root.pendingConfig = config
        root.pendingMonitorName = config.name
        root.pending = true
        root.revertSeconds = 15
        root.applyRule(config)
        revertTick.restart()
        root.configurationApplied(config.name)
    }

    function confirmTemporary(): void {
        if (!root.pending || !root.pendingConfig)
            return
        const name = root.pendingMonitorName
        revertTick.stop()
        root.saveProfile(root.pendingConfig)
        root.pending = false
        root.pendingMonitorName = ""
        root.pendingPrevious = null
        root.pendingConfig = null
        root.revertSeconds = 0
        root.configurationConfirmed(name)
    }

    function revertTemporary(): void {
        if (!root.pending)
            return
        const name = root.pendingMonitorName
        const previous = root.pendingPrevious
        revertTick.stop()
        root.pending = false
        root.pendingMonitorName = ""
        root.pendingPrevious = null
        root.pendingConfig = null
        root.revertSeconds = 0
        if (previous)
            root.applyRule(previous)
        root.configurationReverted(name)
    }

    function resetToPreferred(name: string): void {
        if (!root.monitorByName(name))
            return
        root.applyTemporary({
            name: name,
            mode: "preferred",
            position: "auto",
            scale: 1,
            transform: 0,
            vrr: 0,
            bitdepth: 8
        })
    }

    function saveProfile(value): void {
        const config = root.sanitizeConfig(value)
        if (config.name.length === 0)
            return
        const next = ({})
        for (const key of Object.keys(root.profiles ?? {}))
            next[key] = root.profiles[key]
        next[config.name] = config
        root.profiles = next
        if (root.profilesReady)
            profileFile.setText(JSON.stringify({ schemaVersion: 1, monitors: next }, null, 2) + "\n")
    }

    function removeProfile(name: string): void {
        const next = ({})
        for (const key of Object.keys(root.profiles ?? {})) {
            if (key !== name)
                next[key] = root.profiles[key]
        }
        root.profiles = next
        if (root.profilesReady)
            profileFile.setText(JSON.stringify({ schemaVersion: 1, monitors: next }, null, 2) + "\n")
    }

    function applySavedProfiles(): void {
        if (!root.profilesReady || root.bootProfilesApplied || root.monitors.length === 0)
            return
        root.bootProfilesApplied = true
        for (const name of Object.keys(root.profiles ?? {})) {
            const config = root.sanitizeConfig(root.profiles[name])
            const code = root.buildLuaRule(config)
            if (code.length > 0)
                Quickshell.execDetached(["hyprctl", "eval", code])
        }
        refreshDelay.restart()
    }

    function refresh(): void {
        if (root.refreshing)
            return
        root.refreshing = true
        monitorProbe.exec(["hyprctl", "-j", "monitors", "all"])
    }

    function dpms(name: string, enabled: bool): void {
        if (name.length === 0)
            return
        const action = enabled ? "enable" : "disable"
        const code = `hl.dispatch(hl.dsp.dpms({ action = ${root.luaString(action)}, monitor = ${root.luaString(name)} }))`
        Quickshell.execDetached(["hyprctl", "eval", code])
        refreshDelay.restart()
    }

    Process {
        id: ensureDirectory
        command: ["mkdir", "-p", RaohanePaths.configDirectory]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                profileFile.reload()
            else {
                root.profilesReady = true
                root.errorMessage = qsTr("Could not prepare the Raohane config directory.")
            }
        }
    }

    FileView {
        id: profileFile
        path: RaohanePaths.monitorConfigFile
        watchChanges: true

        onLoaded: {
            try {
                const parsed = JSON.parse(profileFile.text())
                root.profiles = parsed?.monitors && typeof parsed.monitors === "object" ? parsed.monitors : ({})
            } catch (error) {
                console.warn("[RaohaneMonitorManager] Invalid monitor profile file:", error)
                root.profiles = ({})
            }
            root.profilesReady = true
            root.applySavedProfiles()
        }

        onFileChanged: profileReload.restart()

        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                console.warn("[RaohaneMonitorManager] Could not load monitor profiles:", error)
            root.profiles = ({})
            root.profilesReady = true
            root.applySavedProfiles()
        }
    }

    Process {
        id: monitorProbe
        environment: ({ LANG: "C", LC_ALL: "C" })

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text)
                    const next = Array.isArray(parsed) ? parsed.map(item => ({
                        name: String(item?.name ?? ""),
                        description: String(item?.description ?? ""),
                        make: String(item?.make ?? ""),
                        model: String(item?.model ?? ""),
                        serial: String(item?.serial ?? ""),
                        width: Number(item?.width ?? 0),
                        height: Number(item?.height ?? 0),
                        refreshRate: Number(item?.refreshRate ?? 0),
                        x: Number(item?.x ?? 0),
                        y: Number(item?.y ?? 0),
                        scale: Number(item?.scale ?? 1),
                        transform: Number(item?.transform ?? 0),
                        focused: Boolean(item?.focused),
                        disabled: Boolean(item?.disabled),
                        dpmsStatus: item?.dpmsStatus === undefined ? true : Boolean(item.dpmsStatus),
                        vrr: Boolean(item?.vrr),
                        currentFormat: String(item?.currentFormat ?? ""),
                        mirrorOf: String(item?.mirrorOf ?? "none"),
                        availableModes: Array.isArray(item?.availableModes)
                            ? item.availableModes.map(mode => root.normalizeMode(mode))
                            : []
                    })).filter(item => item.name.length > 0) : []
                    root.monitors = next
                    root.errorMessage = ""
                    root.ready = true
                    root.applySavedProfiles()
                } catch (error) {
                    root.errorMessage = qsTr("Could not parse Hyprland monitor information.")
                    console.warn("[RaohaneMonitorManager] hyprctl monitor parse failed:", error)
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.refreshing = false
            if (exitCode !== 0) {
                root.ready = true
                root.errorMessage = qsTr("hyprctl could not read the monitor state.")
            }
        }
    }

    Timer {
        id: refreshDelay
        interval: 550
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: profileReload
        interval: 100
        repeat: false
        onTriggered: profileFile.reload()
    }

    Timer {
        id: revertTick
        interval: 1000
        repeat: true
        onTriggered: {
            root.revertSeconds -= 1
            if (root.revertSeconds <= 0)
                root.revertTemporary()
        }
    }

    Component.onCompleted: {
        ensureDirectory.running = true
        root.refresh()
    }
}
