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

    function reloadDesktop(): void {
        root.run(["hyprctl", "reload"])
        Quickshell.reload(true)
    }

    function lock(): void {
        root.run(["qs", "-c", root.configName(), "ipc", "call", "lock", "activate"])
    }

    function suspend(): void {
        root.run(["systemctl", "suspend"])
    }

    function logout(): void {
        // UWSM owns the compositor and its graphical-session units, so it must
        // be allowed to tear them down in dependency order. Directly dispatching
        // Hyprland exit from an UWSM session can leave user units inconsistent.
        // Outside UWSM, prefer Hyprland's graceful client-closing helper and keep
        // compositor dispatch only as a compatibility fallback.
        root.runShell(
            "if command -v uwsm >/dev/null 2>&1 "
                + "&& systemctl --user is-active --quiet 'wayland-wm@*.service' 2>/dev/null; then "
                + "exec uwsm stop; "
                + "fi; "
                + "if command -v hyprshutdown >/dev/null 2>&1; then "
                + "exec hyprshutdown; "
                + "fi; "
                + "hyprctl dispatch 'hl.dsp.exit()' >/dev/null 2>&1 "
                + "|| hyprctl dispatch exit 1 >/dev/null 2>&1"
        )
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
