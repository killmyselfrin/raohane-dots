#!/usr/bin/env python3
"""Offscreen Qt Quick smoke test for the active lyric effect layout.

Run in an environment with PySide6. No Hyprland session or network required.
"""

from __future__ import annotations

import os
import shutil
import tempfile
from pathlib import Path
import shiboken6

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")

from PySide6.QtCore import QUrl  # noqa: E402
from PySide6.QtGui import QColor, QFont, QGuiApplication  # noqa: E402
from PySide6.QtQml import QJSEngine, QQmlComponent, QQmlEngine  # noqa: E402
from PySide6.QtQuick import QQuickItem, QQuickWindow  # noqa: E402


def main() -> int:
    app = QGuiApplication([])
    engine = QQmlEngine()
    source_dir = Path(__file__).resolve().parents[1] / "modules/raohane"
    js_engine = QJSEngine()
    script = (source_dir / "RaohaneLyricEffects.js").read_text(encoding="utf-8")
    script_result = js_engine.evaluate(script)
    if script_result.isError():
        raise AssertionError(script_result.toString())
    for lyric, expected in (
        ("Крыльями", "wings"),
        ("Розами", "rose"),
        ("Broken heart", "heart"),
    ):
        value = js_engine.evaluate(f"detect({lyric!r}).family")
        if value.toString() != expected:
            raise AssertionError(f"Qt JS detection of {lyric!r}: {value.toString()} != {expected}")

    temporary = tempfile.TemporaryDirectory(prefix="raohane-lyric-qt-")
    temporary_dir = Path(temporary.name)
    for name in ("RaohaneMediaLyricEffect.qml", "RaohaneLyricEffects.js"):
        shutil.copy2(source_dir / name, temporary_dir / name)
    component = QQmlComponent(engine, QUrl.fromLocalFile(str(temporary_dir / "RaohaneMediaLyricEffect.qml")))
    if component.isError():
        raise AssertionError("\n".join(str(error) for error in component.errors()))

    effect = component.createWithInitialProperties({
        "lineText": "Крыльями под дождём",
        "lyricFont": QFont("DejaVu Sans", 12),
        "accent": QColor("#9c94d7"),
    })
    if effect is None:
        raise AssertionError("\n".join(str(error) for error in component.errors()))
    item = shiboken6.wrapInstance(shiboken6.getCppPointer(effect)[0], QQuickItem)
    window = QQuickWindow()
    window.resize(480, 60)
    item.setParentItem(window.contentItem())
    item.setWidth(460)
    item.setHeight(34)
    effect.setProperty("active", True)
    effect.setProperty("mode", "expressive")
    window.show()
    for _ in range(5):
        app.processEvents()

    match = effect.property("match")
    bounds = effect.property("wordBounds")
    match = match.toVariant() if hasattr(match, "toVariant") else match
    bounds = bounds.toVariant() if hasattr(bounds, "toVariant") else bounds
    if not match or not bounds or not item.isVisible():
        raise AssertionError(f"active effect did not render: match={match}, bounds={bounds}, visible={item.isVisible()}")
    if not 0 <= bounds["x"] <= item.width():
        raise AssertionError(f"word anchor escaped the text: {bounds}")

    effect.setProperty("mode", "off")
    app.processEvents()
    if item.isVisible():
        raise AssertionError("disabled effect stayed visible")
    print("lyric-effects-qt-test: Qt JS words, active word geometry and disabled mode pass")
    window.close()
    effect.deleteLater()
    temporary.cleanup()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
