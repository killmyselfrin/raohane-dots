pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs

Singleton {
    id: root

    signal brightnessChanged()
    signal gammaChanged()

    readonly property int gammaLowerLimit: 25
    property int gamma: 100
    property bool temperatureActive: false
    property var ddcMonitors: []

    readonly property int colorTemperature: Config.options?.light?.night?.colorTemperature ?? 5000
    readonly property list<BrightnessMonitor> monitors: Quickshell.screens.map(screen => monitorComponent.createObject(root, { screen }))

    function getMonitorForScreen(screen: ShellScreen): var {
        return root.monitors.find(monitor => monitor.screen === screen) ?? null
    }

    function load(): void {
        root.detectDisplays()
        root.fetchTemperatureState()
    }

    function detectDisplays(): void {
        root.ddcMonitors = []
        ddcDetect.exec(["ddcutil", "detect", "--brief"])
    }

    function initializeMonitor(index: int): void {
        if (index >= root.monitors.length)
            return
        root.monitors[index].initialize()
    }

    function setGamma(value: real): void {
        root.gamma = Math.round(Math.max(root.gammaLowerLimit, Math.min(100, value)))
        root.ensureHyprsunset()
        Quickshell.execDetached(["hyprctl", "hyprsunset", "gamma", String(root.gamma)])
        root.gammaChanged()
    }

    function ensureHyprsunset(): void {
        Quickshell.execDetached([
            "bash", "-c",
            "pidof hyprsunset >/dev/null 2>&1 || (hyprsunset >/dev/null 2>&1 & disown)"
        ])
    }

    function enableTemperature(): void {
        root.ensureHyprsunset()
        Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(root.colorTemperature)])
        root.temperatureActive = true
    }

    function disableTemperature(): void {
        Quickshell.execDetached(["hyprctl", "hyprsunset", "identity"])
        root.temperatureActive = false
    }

    function toggleTemperature(): void {
        if (root.temperatureActive)
            root.disableTemperature()
        else
            root.enableTemperature()
    }

    function fetchTemperatureState(): void {
        temperatureProbe.exec(["hyprctl", "hyprsunset", "temperature"])
    }

    function setComposite(screen: ShellScreen, value: real): void {
        const monitor = root.getMonitorForScreen(screen)
        if (!monitor)
            return

        const clamped = Math.max(0, Math.min(1, value))
        if (clamped >= 0.3) {
            monitor.setBrightness((clamped - 0.3) / 0.7)
            if (root.gamma !== 100)
                root.setGamma(100)
        } else {
            if (monitor.brightness !== 0)
                monitor.setBrightness(0)
            root.setGamma(clamped / 0.3 * (100 - root.gammaLowerLimit) + root.gammaLowerLimit)
        }
    }

    function compositeValue(screen: ShellScreen): real {
        const monitor = root.getMonitorForScreen(screen)
        if (root.gamma === 100)
            return 0.3 + (monitor?.brightness ?? 0.5) * 0.7
        return (root.gamma - root.gammaLowerLimit) / (100 - root.gammaLowerLimit) * 0.3
    }

    Component.onCompleted: root.load()

    onMonitorsChanged: root.detectDisplays()

    Connections {
        target: Config.options?.light?.night ?? null

        function onColorTemperatureChanged(): void {
            if (root.temperatureActive)
                root.enableTemperature()
        }
    }

    Process {
        id: ddcDetect

        stdout: StdioCollector {
            onStreamFinished: {
                const detected = []
                const blocks = text.split(/\n\s*\n/)

                for (const block of blocks) {
                    if (!block.trim().startsWith("Display "))
                        continue

                    const lines = block.split("\n").map(line => line.trim())
                    const connectorLine = lines.find(line => line.startsWith("DRM connector:")) ?? ""
                    const busLine = lines.find(line => line.startsWith("I2C bus:")) ?? ""
                    const connector = connectorLine.split(":").slice(1).join(":").trim()
                    const busMatch = busLine.match(/\/dev\/i2c-(\d+)/)

                    if (connector.length && busMatch)
                        detected.push({ name: connector, busNum: busMatch[1] })
                }

                root.ddcMonitors = detected
            }
        }

        onExited: root.initializeMonitor(0)
    }

    Process {
        id: setProcess
    }

    Process {
        id: temperatureProbe

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim()
                root.temperatureActive = output.length > 0
                    && !output.startsWith("Couldn't")
                    && output !== "6500"
            }
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        onTriggered: root.fetchTemperatureState()
    }

    component BrightnessMonitor: QtObject {
        id: monitor

        required property ShellScreen screen
        property bool isDdc: false
        property string busNum: ""
        property int rawMaxBrightness: 100
        property real brightness: 0.5
        property bool ready: false

        onBrightnessChanged: {
            if (ready)
                root.brightnessChanged()
        }

        function initialize(): void {
            ready = false
            const earlier = root.monitors.slice(0, root.monitors.indexOf(monitor))
            const match = root.ddcMonitors.find(candidate =>
                candidate.name === screen.name
                && !earlier.some(previous => previous.busNum === candidate.busNum)
            )

            isDdc = !!match
            busNum = match?.busNum ?? ""

            if (isDdc)
                initProcess.exec(["ddcutil", "-b", busNum, "getvcp", "10", "--brief"])
            else
                initProcess.exec(["brightnessctl", "-m", "--class", "backlight"])
        }

        function setBrightness(value: real): void {
            brightness = Math.max(0, Math.min(1, value))
            syncBrightness()
        }

        function syncBrightness(): void {
            if (!ready)
                return

            if (isDdc) {
                const rawValue = Math.max(1, Math.round(brightness * rawMaxBrightness))
                setProcess.exec(["ddcutil", "-b", busNum, "setvcp", "10", String(rawValue)])
            } else {
                const percent = Math.max(1, Math.round(brightness * 100))
                setProcess.exec(["brightnessctl", "--class", "backlight", "set", `${percent}%`, "--quiet"])
            }
        }

        readonly property Process initProcess: Process {
            environment: ({ LANG: "C", LC_ALL: "C" })

            stdout: StdioCollector {
                onStreamFinished: {
                    if (monitor.isDdc) {
                        const numbers = text.match(/\d+/g) ?? []
                        if (numbers.length >= 2) {
                            const current = Number(numbers[numbers.length - 2])
                            const maximum = Number(numbers[numbers.length - 1])
                            if (maximum > 0) {
                                monitor.rawMaxBrightness = maximum
                                monitor.brightness = current / maximum
                                monitor.ready = true
                            }
                        }
                    } else {
                        const line = text.trim().split("\n")[0] ?? ""
                        const fields = line.split(",")
                        const current = Number(fields[2] ?? 0)
                        const maximum = Number(fields[3] ?? 0)
                        if (maximum > 0) {
                            monitor.rawMaxBrightness = maximum
                            monitor.brightness = current / maximum
                            monitor.ready = true
                        }
                    }
                }
            }

            onExited: root.initializeMonitor(root.monitors.indexOf(monitor) + 1)
        }
    }

    Component {
        id: monitorComponent
        BrightnessMonitor {}
    }
}
