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

class Users(QAbstractListModel):
    rememberedChanged = Signal()
    def __init__(self):
        super().__init__()
        self.remembered = "raohane"
        self.names = ["other-user", "raohane"]
    def getRemembered(self):
        return self.remembered
    def setRemembered(self, value):
        self.remembered = value
        self.rememberedChanged.emit()
    lastUser = Property(str, getRemembered, setRemembered, notify=rememberedChanged)
    lastIndex = Property(int, lambda self: 1, constant=True)
    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self.names)
    def roleNames(self):
        return {Qt.UserRole + 1: b"name"}
    def data(self, index, role):
        if index.isValid() and role == Qt.UserRole + 1:
            return self.names[index.row()]
    def setNames(self, names):
        self.beginResetModel()
        self.names = names
        self.endResetModel()

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
config, user, keyboard = QQmlPropertyMap(), Users(), QQmlPropertyMap()
config.insert("ReduceMotion", "true")
config.insert("wallpaper", "")
config.insert("Background", "background.png")
config.insert("Avatar", "avatar.svg")
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
assert username is None, "username input must not exist"
assert root.property("loginAccount") == "raohane"
for width, height in [(1920, 1080), (1366, 768), (800, 600)]:
    view.resize(width, height)
    QTest.qWait(300)
    assert scene.width() * scene.scale() <= width - 40
    assert scene.height() * scene.scale() <= height - 80
    if os.environ.get("RAOHANE_TEST_RENDER"):
        # Let asynchronous image decoding finish before exporting a preview.
        QTest.qWait(600)
        view.grabWindow().save(f"/tmp/raohane-sddm-{width}.png")

# An empty remembered name still resolves the actual model's selected user.
user.setRemembered("")
QTest.qWait(20)
assert root.property("loginAccount") == "raohane"
user.setNames([])
QTest.qWait(20)
assert root.property("loginAccount") == ""
QMetaObject.invokeMethod(root, "authenticate")
assert not proxy.calls
assert "No user account" in root.property("message")
user.setNames(["other-user", "raohane"])
QTest.qWait(20)
assert root.property("loginAccount") == "raohane"
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
print("PASS: QML creation, three viewport sizes, hidden account resolution/session validation, keyboard/button submission, duplicate-submit guard, failure recovery and success cleanup")
