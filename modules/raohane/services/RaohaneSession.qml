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

    function lock(): void {
        root.run(["loginctl", "lock-session"])
    }

    function suspend(): void {
        root.run(["systemctl", "suspend"])
    }

    function logout(): void {
        root.run(["hyprctl", "dispatch", "exit"])
    }

    function launchTaskManager(): void {
        const configured = RaohaneConfig.taskManagerCommand
        if (configured.trim().length > 0) {
            root.runShell(configured)
            return
        }
        root.runShell("command -v btop >/dev/null && btop || command -v htop >/dev/null && htop || top")
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
