#!/usr/bin/env python3
"""Offscreen QML contract tests; requires PySide6, never invokes real PAM/power."""
import os
os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "software")
import sys
from pathlib import Path
from PySide6.QtCore import (QObject, Signal, Slot, Property, QAbstractListModel,
                           QModelIndex, Qt, QUrl, QMetaObject, QPointF, qInstallMessageHandler)
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlPropertyMap
from PySide6.QtQuick import QQuickView
from PySide6.QtTest import QTest

class Sessions(QAbstractListModel):
    lastIndex = Property(int, lambda self: 1, constant=True)
    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else 2
    def roleNames(self):
        return {Qt.UserRole + 1: b"name"}
    def data(self, index, role):
        if index.isValid() and role == Qt.UserRole + 1:
            return ["Hyprland", "Hyprland (uwsm-managed)"][index.row()]

class Proxy(QObject):
    loginFailed = Signal()
    loginSucceeded = Signal()
    informationMessage = Signal(str)
    canPowerOff = Property(bool, lambda self: False, constant=True)
    canReboot = Property(bool, lambda self: False, constant=True)
    canSuspend = Property(bool, lambda self: False, constant=True)
    hostName = Property(str, lambda self: "raohane-desktop", constant=True)
    calls = []
    @Slot(str, str, int)
    def login(self, user, password, session):
        self.calls.append((user, password, session))
    @Slot()
    def powerOff(self): raise AssertionError("power off disabled")
    @Slot()
    def reboot(self): raise AssertionError("reboot disabled")
    @Slot()
    def suspend(self): raise AssertionError("suspend disabled")

app = QGuiApplication(sys.argv)
warnings = []
qInstallMessageHandler(lambda kind, context, text: warnings.append(text))
proxy, sessions = Proxy(), Sessions()
config, user, keyboard = QQmlPropertyMap(), QQmlPropertyMap(), QQmlPropertyMap()
config.insert("ReduceMotion", "true")
config.insert("wallpaper", "")
config.insert("Background", "background.png")
config.insert("Avatar", "avatar.svg")
user.insert("lastUser", "raohane")
keyboard.insert("capsLock", False)
view = QQuickView()
view.setResizeMode(QQuickView.SizeRootObjectToView)
for name, value in dict(config=config, userModel=user, sessionModel=sessions,
                        keyboard=keyboard, sddm=proxy).items():
    view.rootContext().setContextProperty(name, value)
theme = Path(__file__).resolve().parent.parent / "display-manager/sddm/raohane/Main.qml"
view.setSource(QUrl.fromLocalFile(str(theme)))
assert view.status() == QQuickView.Ready, view.errors()
view.show()
root = view.rootObject()
password = root.findChild(QObject, "password")
username = root.findChild(QObject, "userField")
session = root.findChild(QObject, "sessionBox")
scene = root.findChild(QObject, "scene")
assert session.property("currentIndex") == 1
assert not username.property("visible"), "remembered account name must stay hidden"
for width, height in [(1920, 1080), (1366, 768), (800, 600)]:
    view.resize(width, height)
    QTest.qWait(300)
    assert scene.width() * scene.scale() <= width - 40
    assert scene.height() * scene.scale() <= height - 80
    if os.environ.get("RAOHANE_TEST_RENDER"):
        view.grabWindow().save(f"/tmp/raohane-sddm-{width}.png")

username.setProperty("text", "")
QMetaObject.invokeMethod(root, "authenticate")
assert not proxy.calls
assert username.property("visible"), "missing account must remain recoverable"
username.setProperty("text", " raohane ")
password.setProperty("text", "test-only")
password.forceActiveFocus()
QTest.keyClick(view, Qt.Key_Return)
QMetaObject.invokeMethod(root, "authenticate")
assert proxy.calls == [("raohane", "test-only", 1)]
assert root.property("pending")
assert not password.property("enabled")
proxy.loginFailed.emit()
assert not root.property("pending")
assert password.property("text") == ""
assert root.property("failed")
session.setProperty("currentIndex", -1)
QMetaObject.invokeMethod(root, "authenticate")
assert len(proxy.calls) == 1
session.setProperty("currentIndex", 0)
password.setProperty("text", "second-test")
button = root.findChild(QObject, "signIn")
point = button.mapToScene(QPointF(button.width() / 2, button.height() / 2))
QTest.mouseClick(view, Qt.LeftButton, Qt.NoModifier, point.toPoint())
assert proxy.calls[-1] == ("raohane", "second-test", 0)
proxy.loginSucceeded.emit()
assert root.property("leaving")
assert password.property("text") == ""
QTest.qWait(30)
assert not warnings, "\n".join(warnings)
print("PASS: QML creation, three viewport sizes, account/session validation, keyboard/button submission, duplicate-submit guard, failure recovery and success cleanup")
