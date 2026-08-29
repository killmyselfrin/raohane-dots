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
        const configured = String(Quickshell.env("RAOHANE_QS_CONFIG") ?? "raohane")
        const configName = configured.trim().length > 0 ? configured.trim() : "raohane"
        root.run(["qs", "-c", configName, "ipc", "call", "lock", "activate"])
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

        root.runShell(
            "monitor='if command -v btop >/dev/null 2>&1; then exec btop; "
                + "elif command -v htop >/dev/null 2>&1; then exec htop; else exec top; fi'; "
                + "if command -v xdg-terminal-exec >/dev/null 2>&1; then exec xdg-terminal-exec bash -lc \"$monitor\"; "
                + "elif command -v foot >/dev/null 2>&1; then exec foot -e bash -lc \"$monitor\"; "
                + "elif command -v kitty >/dev/null 2>&1; then exec kitty bash -lc \"$monitor\"; "
                + "elif command -v alacritty >/dev/null 2>&1; then exec alacritty -e bash -lc \"$monitor\"; "
                + "elif command -v wezterm >/dev/null 2>&1; then exec wezterm start --always-new-process -- bash -lc \"$monitor\"; "
                + "elif command -v ghostty >/dev/null 2>&1; then exec ghostty -e bash -lc \"$monitor\"; "
                + "elif command -v konsole >/dev/null 2>&1; then exec konsole -e bash -lc \"$monitor\"; "
                + "elif command -v gnome-terminal >/dev/null 2>&1; then exec gnome-terminal -- bash -lc \"$monitor\"; "
                + "elif command -v xterm >/dev/null 2>&1; then exec xterm -e bash -lc \"$monitor\"; "
                + "elif command -v notify-send >/dev/null 2>&1; then notify-send 'Raohane Task Manager' 'No supported terminal emulator was found.'; fi"
        )
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
