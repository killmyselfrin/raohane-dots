pragma Singleton

import QtQuick

QtObject {
    function clamp(value: real, minimum: real, maximum: real): real {
        const number = Number(value)
        if (!Number.isFinite(number))
            return minimum
        return Math.max(minimum, Math.min(maximum, number))
    }

    function clampInt(value: var, minimum: int, maximum: int, fallback: int): int {
        const number = Number(value)
        if (!Number.isFinite(number))
            return Math.max(minimum, Math.min(maximum, fallback))
        return Math.round(Math.max(minimum, Math.min(maximum, number)))
    }

    function stringValue(value: var, fallback: string): string {
        if (value === null || value === undefined)
            return fallback
        return String(value)
    }

    function stringList(value: var): var {
        return Array.isArray(value) ? value.map(item => String(item)) : []
    }

    function normalizeLanguage(value: var, fallback: string): string {
        const language = String(value ?? fallback).trim().toLowerCase()
        return language === "en" || language === "ru" ? language : fallback
    }

    function percent(value: real): string {
        return Math.round(clamp(value, 0, 1) * 100) + "%"
    }
}
