pragma Singleton

import Quickshell
import qs.modules.raohane.config

Singleton {
    id: root

    function run(command): void {
        Quickshell.execDetached(command)
    }

    function runShell(command: string): void {
        if (command && command.trim().length > 0)
            root.run(["bash", "-lc", command])
    }

    function closeAllWindows(): void {
        // Session termination and systemd power actions already give clients a
        // chance to exit cleanly. Raohane deliberately avoids kill-by-PID here.
    }

    function changePassword(): void {
        root.runShell(RaohaneConfig.changePasswordCommand || "passwd")
    }

    function configName(): string {
        const configured = String(Quickshell.env("RAOHANE_QS_CONFIG") ?? "raohane")
        return configured.trim().length > 0 ? configured.trim() : "raohane"
    }

    function lock(): void {
        root.run(["qs", "-c", root.configName(), "ipc", "call", "lock", "activate"])
    }

    function suspend(): void {
        root.run(["systemctl", "suspend"])
    }

    function logout(): void {
        root.run(["hyprctl", "dispatch", "exit"])
    }

    function launchTaskManager(): void {
        const configured = String(RaohaneConfig.taskManagerCommand ?? "").trim()
        if (configured.length > 0) {
            root.runShell(configured)
            return
        }

        root.run(["qs", "-c", root.configName(), "ipc", "call", "taskManager", "open"])
    }

    function hibernate(): void {
        root.run(["systemctl", "hibernate"])
    }

    function poweroff(): void {
        root.run(["systemctl", "poweroff"])
    }

    function reboot(): void {
        root.run(["systemctl", "reboot"])
    }

    function rebootToFirmware(): void {
        root.run(["systemctl", "reboot", "--firmware-setup"])
    }
}
