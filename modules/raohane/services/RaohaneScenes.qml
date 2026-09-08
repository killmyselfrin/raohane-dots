pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.modules.raohane.config

Singleton {
    id: root

    property bool ready: false
    property string selectedSceneId: "balanced"
    property string activeSceneId: "balanced"
    property string activationSource: "startup"

    property bool autoSwitchEnabled: true
    property var appRules: []
    property bool autoSceneActive: false
    property string autoSourceAppId: ""
    property bool manualOverride: false
    property string manualOverrideAppId: ""

    property bool baselineCaptured: false
    property bool baselineDnd: false
    property bool baselineKeepAwake: false
    property bool baselineGameMode: false
    property bool restoringBaseline: false
    property bool desiredGameMode: false

    readonly property var sceneIds: ["balanced", "gaming", "focus", "work"]
    readonly property var matchModes: ["exact", "prefix", "contains"]
    readonly property string activeAppId: String(ToplevelManager.activeToplevel?.appId ?? "").trim().toLowerCase()
    readonly property var activePolicy: root.policyFor(root.activeSceneId)
    readonly property bool gaming: root.activeSceneId === "gaming"
    readonly property var activeRule: root.autoSceneActive && root.autoSourceAppId.length > 0
        ? root.matchingRuleFor(root.autoSourceAppId)
        : null
    readonly property string activeRulePattern: String(root.activeRule?.pattern ?? "")
    readonly property string activeRuleMatch: String(root.activeRule?.match ?? "")
    readonly property bool activeRuleBuiltin: Boolean(root.activeRule?.builtin ?? false)

    signal sceneActivated(string sceneId, string source)
    signal policyApplied(string sceneId)
    signal autoRuleMatched(string appId, string sceneId)

    function sanitizeSceneId(value): string {
        const requested = String(value ?? "").trim().toLowerCase()
        return root.sceneIds.includes(requested) ? requested : "balanced"
    }

    function policyFor(sceneId): var {
        switch (root.sanitizeSceneId(sceneId)) {
        case "gaming":
            return {
                notificationPolicy: "dnd",
                keepAwake: true,
                dockPolicy: "hide",
                contextMode: "gaming",
                gameMode: true,
                motionHint: "fast"
            }
        case "focus":
            return {
                notificationPolicy: "dnd",
                keepAwake: false,
                dockPolicy: "hide",
                contextMode: "focus",
                gameMode: false,
                motionHint: "quiet"
            }
        case "work":
            return {
                notificationPolicy: "inherit",
                keepAwake: true,
                dockPolicy: "inherit",
                contextMode: "work",
                gameMode: false,
                motionHint: "balanced"
            }
        default:
            return {
                notificationPolicy: "inherit",
                keepAwake: false,
                dockPolicy: "inherit",
                contextMode: "default",
                gameMode: false,
                motionHint: "balanced"
            }
        }
    }

    function defaultRules(): var {
        return [
            { pattern: "steam_app_", match: "prefix", scene: "gaming", builtin: true },
            { pattern: "gamescope", match: "contains", scene: "gaming", builtin: true }
        ]
    }

    function sanitizeRule(rule): var {
        if (!rule || typeof rule !== "object")
            return null
        const pattern = String(rule.pattern ?? rule.appId ?? "").trim().toLowerCase()
        if (pattern.length === 0 || pattern.length > 180)
            return null
        const requestedMatch = String(rule.match ?? "exact").trim().toLowerCase()
        const match = root.matchModes.includes(requestedMatch) ? requestedMatch : "exact"
        const scene = root.sanitizeSceneId(rule.scene)
        if (!root.sceneIds.includes(String(rule.scene ?? "").trim().toLowerCase()))
            return null
        return { pattern: pattern, match: match, scene: scene }
    }

    function sanitizeRules(value): var {
        if (!Array.isArray(value))
            return []
        const result = []
        const seen = new Set()
        for (const rawRule of value) {
            const rule = root.sanitizeRule(rawRule)
            if (!rule)
                continue
            const key = `${rule.match}:${rule.pattern}`
            if (seen.has(key))
                continue
            seen.add(key)
            result.push(rule)
            if (result.length >= 64)
                break
        }
        return result
    }

    function ruleMatches(rule, appId: string): bool {
        if (!rule || appId.length === 0)
            return false
        if (rule.match === "prefix")
            return appId.startsWith(rule.pattern)
        if (rule.match === "contains")
            return appId.includes(rule.pattern)
        return appId === rule.pattern
    }

    function matchingRuleFor(appId): var {
        const normalizedAppId = String(appId ?? "").trim().toLowerCase()
        if (normalizedAppId.length === 0)
            return null

        // User rules take precedence over conservative built-in gaming rules.
        const userRules = root.sanitizeRules(root.appRules).map(rule => ({
            pattern: rule.pattern,
            match: rule.match,
            scene: rule.scene,
            builtin: false
        }))
        const rules = userRules.concat(root.defaultRules())
        for (const rule of rules) {
            if (root.ruleMatches(rule, normalizedAppId))
                return rule
        }
        return null
    }

    function matchingSceneFor(appId): string {
        const rule = root.matchingRuleFor(appId)
        return rule ? root.sanitizeSceneId(rule.scene) : ""
    }

    function captureBaseline(): void {
        if (root.baselineCaptured)
            return
        root.baselineDnd = RaohaneNotifications.silent
        root.baselineKeepAwake = RaohaneIdle.inhibit
        root.baselineGameMode = RaohanePerformance.gameModeActive
        root.baselineCaptured = true
    }

    function requestGameMode(enabled: bool): void {
        root.desiredGameMode = Boolean(enabled)
        if (RaohanePerformance.busy) {
            gameModeRetry.restart()
            return
        }
        if (RaohanePerformance.gameModeActive !== root.desiredGameMode)
            RaohanePerformance.setGameMode(root.desiredGameMode)
        else
            root.finishBaselineRestoreIfReady()
    }

    function finishBaselineRestoreIfReady(): void {
        if (!root.restoringBaseline)
            return
        if (RaohanePerformance.busy || RaohanePerformance.gameModeActive !== root.desiredGameMode)
            return
        root.restoringBaseline = false
        root.baselineCaptured = false
    }

    function applyActivePolicy(): void {
        if (!root.ready)
            return

        if (root.activeSceneId === "balanced") {
            if (!root.baselineCaptured)
                return
            root.restoringBaseline = true
            RaohaneNotifications.silent = root.baselineDnd
            RaohaneIdle.setInhibit(root.baselineKeepAwake)
            root.requestGameMode(root.baselineGameMode)
            root.policyApplied(root.activeSceneId)
            return
        }

        root.restoringBaseline = false
        root.captureBaseline()
        const policy = root.activePolicy
        RaohaneNotifications.silent = policy.notificationPolicy === "dnd"
            ? true
            : root.baselineDnd
        RaohaneIdle.setInhibit(policy.keepAwake ? true : root.baselineKeepAwake)
        root.requestGameMode(Boolean(policy.gameMode))
        root.policyApplied(root.activeSceneId)
    }

    function applyScene(sceneId, source): bool {
        const requested = String(sceneId ?? "").trim().toLowerCase()
        if (!root.sceneIds.includes(requested))
            return false

        root.activationSource = String(source ?? "manual") || "manual"
        if (root.activeSceneId !== requested)
            root.activeSceneId = requested
        root.sceneActivated(requested, root.activationSource)
        sceneApplyTimer.restart()
        return true
    }

    function activate(sceneId, source): bool {
        const requested = String(sceneId ?? "").trim().toLowerCase()
        if (!root.sceneIds.includes(requested))
            return false

        const normalizedSource = String(source ?? "manual") || "manual"
        const automatic = normalizedSource.startsWith("auto")
        if (!automatic && normalizedSource !== "startup") {
            root.selectedSceneId = requested
            root.manualOverride = true
            root.manualOverrideAppId = root.activeAppId
            root.autoSceneActive = false
            root.autoSourceAppId = ""
        }

        return root.applyScene(requested, normalizedSource)
    }

    function reset(source): void {
        root.activate("balanced", source ?? "manual")
    }

    function evaluateAutoScene(): void {
        if (!root.ready)
            return

        if (!root.autoSwitchEnabled) {
            if (root.autoSceneActive) {
                root.autoSceneActive = false
                root.autoSourceAppId = ""
                root.applyScene(root.selectedSceneId, "auto-disabled")
            }
            return
        }

        if (root.manualOverride)
            return

        const appId = root.activeAppId
        const matchedRule = root.matchingRuleFor(appId)
        const matchedScene = matchedRule ? root.sanitizeSceneId(matchedRule.scene) : ""
        if (matchedScene.length > 0) {
            if (root.autoSceneActive && root.autoSourceAppId === appId && root.activeSceneId === matchedScene)
                return
            root.autoSceneActive = true
            root.autoSourceAppId = appId
            root.autoRuleMatched(appId, matchedScene)
            root.applyScene(matchedScene, "auto:" + appId)
            return
        }

        if (root.autoSceneActive) {
            root.autoSceneActive = false
            root.autoSourceAppId = ""
            root.applyScene(root.selectedSceneId, "auto-return")
        }
    }

    function setAutoSwitch(enabled: bool): void {
        const next = Boolean(enabled)
        if (root.autoSwitchEnabled === next)
            return
        root.autoSwitchEnabled = next
        saveTimer.restart()
        autoEvaluate.restart()
    }

    function setRule(patternValue, matchType, sceneId): bool {
        const pattern = String(patternValue ?? "").trim().toLowerCase()
        const match = String(matchType ?? "exact").trim().toLowerCase()
        const scene = String(sceneId ?? "").trim().toLowerCase()
        if (pattern.length === 0 || pattern.length > 180 || !root.matchModes.includes(match) || !root.sceneIds.includes(scene))
            return false

        const rules = root.sanitizeRules(root.appRules).filter(rule => !(rule.match === match && rule.pattern === pattern))
        rules.unshift({ pattern: pattern, match: match, scene: scene })
        root.appRules = root.sanitizeRules(rules)
        saveTimer.restart()
        autoEvaluate.restart()
        return true
    }

    function removeRule(patternValue, matchType): bool {
        const pattern = String(patternValue ?? "").trim().toLowerCase()
        const match = String(matchType ?? "exact").trim().toLowerCase()
        if (pattern.length === 0 || !root.matchModes.includes(match))
            return false
        const before = root.sanitizeRules(root.appRules)
        const after = before.filter(rule => !(rule.match === match && rule.pattern === pattern))
        if (after.length === before.length)
            return false
        root.appRules = after
        saveTimer.restart()
        autoEvaluate.restart()
        return true
    }

    function setAppRule(appId, sceneId): bool {
        return root.setRule(appId, "exact", sceneId)
    }

    function removeAppRule(appId): bool {
        return root.removeRule(appId, "exact")
    }

    function clearManualOverride(): void {
        root.manualOverride = false
        root.manualOverrideAppId = ""
        autoEvaluate.restart()
    }

    function snapshot(): var {
        return {
            version: 2,
            selectedScene: root.selectedSceneId,
            autoSwitch: root.autoSwitchEnabled,
            rules: root.sanitizeRules(root.appRules)
        }
    }

    function loadState(text: string): void {
        try {
            const parsed = JSON.parse(text)
            const selected = parsed?.selectedScene ?? parsed?.activeScene ?? "balanced"
            root.selectedSceneId = root.sanitizeSceneId(selected)
            root.activeSceneId = root.selectedSceneId
            root.autoSwitchEnabled = parsed?.autoSwitch === undefined ? true : Boolean(parsed.autoSwitch)
            root.appRules = root.sanitizeRules(parsed?.rules)
        } catch (error) {
            console.warn("[RaohaneScenes] Invalid scene state, using defaults:", error)
            root.selectedSceneId = "balanced"
            root.activeSceneId = "balanced"
            root.autoSwitchEnabled = true
            root.appRules = []
        }
        root.activationSource = "startup"
        root.ready = true
        startupApply.restart()
    }

    function saveNow(): void {
        if (!root.ready)
            return
        stateFile.setText(JSON.stringify(root.snapshot(), null, 2) + "\n")
    }

    onSelectedSceneIdChanged: {
        if (root.ready)
            saveTimer.restart()
    }
    onAppRulesChanged: {
        if (root.ready)
            saveTimer.restart()
    }
    onActiveAppIdChanged: {
        if (!root.ready)
            return
        if (root.manualOverride && root.activeAppId !== root.manualOverrideAppId) {
            root.manualOverride = false
            root.manualOverrideAppId = ""
        }
        autoEvaluate.restart()
    }

    Connections {
        target: RaohanePerformance

        function onGameModeApplied(enabled: bool): void {
            if (enabled !== root.desiredGameMode)
                gameModeRetry.restart()
            else
                root.finishBaselineRestoreIfReady()
        }
    }

    Timer {
        id: saveTimer
        interval: 120
        repeat: false
        onTriggered: root.saveNow()
    }

    Timer {
        id: sceneApplyTimer
        interval: 20
        repeat: false
        onTriggered: root.applyActivePolicy()
    }

    Timer {
        id: startupApply
        interval: 900
        repeat: false
        onTriggered: {
            root.applyActivePolicy()
            autoEvaluate.restart()
        }
    }

    Timer {
        id: autoEvaluate
        interval: 90
        repeat: false
        onTriggered: root.evaluateAutoScene()
    }

    Timer {
        id: gameModeRetry
        interval: 220
        repeat: false
        onTriggered: root.requestGameMode(root.desiredGameMode)
    }

    Process {
        id: ensureStateDirectory
        command: ["mkdir", "-p", RaohanePaths.stateDirectory]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("[RaohaneScenes] Could not create state directory")
                root.ready = true
                return
            }
            stateFile.reload()
        }
    }

    FileView {
        id: stateFile
        path: RaohanePaths.sceneStateFile
        onLoaded: root.loadState(stateFile.text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.ready = true
                saveTimer.restart()
                startupApply.restart()
            } else {
                console.warn("[RaohaneScenes] Could not load scene state:", error)
                root.ready = true
            }
        }
    }

    IpcHandler {
        target: "scenes"

        function current(): string {
            return root.activeSceneId
        }

        function selected(): string {
            return root.selectedSceneId
        }

        function list(): string {
            return JSON.stringify(root.sceneIds)
        }

        function status(): string {
            return JSON.stringify({
                selected: root.selectedSceneId,
                active: root.activeSceneId,
                source: root.activationSource,
                activeAppId: root.activeAppId,
                autoSwitch: root.autoSwitchEnabled,
                autoScene: root.autoSceneActive,
                autoSourceAppId: root.autoSourceAppId,
                activeRule: root.activeRule,
                manualOverride: root.manualOverride,
                rules: root.sanitizeRules(root.appRules)
            })
        }

        function activate(sceneId: string): string {
            return root.activate(sceneId, "ipc") ? root.activeSceneId : "invalid-scene"
        }

        function reset(): string {
            root.reset("ipc")
            return root.activeSceneId
        }

        function setAuto(enabled: string): string {
            const value = String(enabled ?? "").trim().toLowerCase()
            if (!["1", "0", "true", "false", "on", "off"].includes(value))
                return "invalid-value"
            root.setAutoSwitch(["1", "true", "on"].includes(value))
            return root.autoSwitchEnabled ? "on" : "off"
        }

        function setRule(appId: string, sceneId: string): string {
            return root.setAppRule(appId, sceneId) ? "ok" : "invalid-rule"
        }

        function setPatternRule(pattern: string, matchType: string, sceneId: string): string {
            return root.setRule(pattern, matchType, sceneId) ? "ok" : "invalid-rule"
        }

        function removeRule(appId: string): string {
            return root.removeAppRule(appId) ? "ok" : "not-found"
        }

        function removePatternRule(pattern: string, matchType: string): string {
            return root.removeRule(pattern, matchType) ? "ok" : "not-found"
        }

        function clearOverride(): string {
            root.clearManualOverride()
            return "ok"
        }
    }

    Component.onCompleted: ensureStateDirectory.running = true
}
