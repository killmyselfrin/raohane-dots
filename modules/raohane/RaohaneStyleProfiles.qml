pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

RowLayout {
    id: root

    property bool compact: false
    property bool showDescription: !compact

    readonly property bool constrained: compact || width < 660
    readonly property bool descriptionsVisible: showDescription && width >= 760 && !constrained
    readonly property var profiles: [
        {
            id: "quiet",
            name: qsTr("Quiet"),
            icon: "spa",
            detail: qsTr("Tighter, calmer and almost static"),
            glassOpacity: 0.94,
            borderStrength: 0.78,
            radiusScale: 0.92,
            densityScale: 0.90,
            motionScale: 0.35,
            accentStrength: 0.82,
            sheenEnabled: false
        },
        {
            id: "balanced",
            name: qsTr("Balanced"),
            icon: "tune",
            detail: qsTr("The default Nocturne rhythm"),
            glassOpacity: 1.0,
            borderStrength: 1.0,
            radiusScale: 1.0,
            densityScale: 1.0,
            motionScale: 0.92,
            accentStrength: 1.0,
            sheenEnabled: true
        },
        {
            id: "expressive",
            name: qsTr("Expressive"),
            icon: "auto_awesome",
            detail: qsTr("Airier geometry and stronger feedback"),
            glassOpacity: 0.88,
            borderStrength: 1.16,
            radiusScale: 1.12,
            densityScale: 1.06,
            motionScale: 1.14,
            accentStrength: 1.18,
            sheenEnabled: true
        }
    ]

    spacing: constrained ? 5 : 8

    function almostEqual(left, right): bool {
        return Math.abs(Number(left) - Number(right)) < 0.015
    }

    function matches(profile): bool {
        const style = RaohaneConfig.style ?? {}
        return root.almostEqual(style.glassOpacity, profile.glassOpacity)
            && root.almostEqual(style.borderStrength, profile.borderStrength)
            && root.almostEqual(style.radiusScale, profile.radiusScale)
            && root.almostEqual(style.densityScale, profile.densityScale)
            && root.almostEqual(style.motionScale, profile.motionScale)
            && root.almostEqual(style.accentStrength, profile.accentStrength)
            && Boolean(style.sheenEnabled) === Boolean(profile.sheenEnabled)
    }

    function apply(profile): void {
        const current = RaohaneConfig.style ?? {}
        const next = {}
        for (const key in current)
            next[key] = current[key]

        next.glassOpacity = profile.glassOpacity
        next.borderStrength = profile.borderStrength
        next.radiusScale = profile.radiusScale
        next.densityScale = profile.densityScale
        next.motionScale = profile.motionScale
        next.accentStrength = profile.accentStrength
        next.sheenEnabled = profile.sheenEnabled

        RaohaneConfig.style = RaohaneConfig.sanitizeStyle(next)
    }

    Repeater {
        model: root.profiles

        delegate: RaohaneSurface {
            id: profileButton

            required property var modelData
            readonly property bool selected: root.matches(modelData)

            Layout.fillWidth: true
            Layout.minimumWidth: root.constrained ? 94 : 118
            Layout.preferredHeight: root.descriptionsVisible ? 54 : 38
            surfaceRadius: root.constrained ? 11 : 13
            active: selected
            raised: false
            showSheen: false
            interactive: true
            hovered: profileMouse.containsMouse || activeFocus
            pressed: profileMouse.pressed
            hoverScale: 1
            pressedScale: 1
            activeFocusOnTab: true
            border.color: selected ? RaohaneTheme.accentBorder
                : hovered ? RaohaneTheme.borderStrong
                : RaohaneTheme.borderFaint

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: root.constrained ? 8 : 10
                anchors.rightMargin: root.constrained ? 8 : 10
                spacing: root.constrained ? 6 : 8

                Rectangle {
                    Layout.preferredWidth: root.constrained ? 24 : 28
                    Layout.preferredHeight: width
                    radius: root.constrained ? 8 : 9
                    color: profileButton.selected ? RaohaneTheme.accentSoft : RaohaneTheme.surfaceSubtle
                    border.width: 1
                    border.color: profileButton.selected ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: profileButton.modelData.icon
                        iconSize: root.constrained ? 12 : 14
                        fill: profileButton.selected ? 1 : profileButton.hovered ? 0.35 : 0
                        symbolWeight: profileButton.selected ? 540 : 440
                        color: profileButton.selected || profileButton.hovered
                            ? RaohaneTheme.accent
                            : RaohaneTheme.textMuted
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: profileButton.modelData.name
                        color: profileButton.selected ? RaohaneTheme.text : RaohaneTheme.textMuted
                        font.pixelSize: root.constrained ? 8 : 9
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: root.descriptionsVisible
                        text: profileButton.modelData.detail
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 7
                        elide: Text.ElideRight
                    }
                }

                RaohaneIcon {
                    visible: profileButton.selected && !root.constrained
                    text: "check"
                    iconSize: 12
                    fill: 1
                    symbolWeight: 560
                    color: RaohaneTheme.accent
                }
            }

            MouseArea {
                id: profileMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: profileButton.forceActiveFocus()
                onClicked: root.apply(profileButton.modelData)
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.apply(profileButton.modelData)
                    event.accepted = true
                }
            }
        }
    }
}
