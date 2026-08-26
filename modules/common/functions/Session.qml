pragma Singleton

import Quickshell
import qs.modules.raohane.services

Singleton {
    function closeAllWindows(): void { RaohaneSession.closeAllWindows() }
    function changePassword(): void { RaohaneSession.changePassword() }
    function lock(): void { RaohaneSession.lock() }
    function suspend(): void { RaohaneSession.suspend() }
    function logout(): void { RaohaneSession.logout() }
    function launchTaskManager(): void { RaohaneSession.launchTaskManager() }
    function hibernate(): void { RaohaneSession.hibernate() }
    function poweroff(): void { RaohaneSession.poweroff() }
    function reboot(): void { RaohaneSession.reboot() }
    function rebootToFirmware(): void { RaohaneSession.rebootToFirmware() }
}
