pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    function goTo(control: string): void {
        const requested = String(control ?? "").trim().toLowerCase()
        if (requested === "motion" || requested === "keybinds")
            preferences.section = requested
    }

    RaohanePreferencesHub {
        id: preferences
        anchors.fill: parent
        section: "keybinds"
        onCloseRequested: RaohaneSettingsRouter.request("home", "")
    }
}
