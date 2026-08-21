import sys
import dbus.mainloop.glib

from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QUrl

from player import Player


dbus.mainloop.glib.DBusGMainLoop(
    set_as_default=True
)

app = QApplication(sys.argv)

engine = QQmlApplicationEngine()

player = Player()

engine.rootContext().setContextProperty(
    "player",
    player
)

engine.load(
    QUrl.fromLocalFile(
        "main.qml"
    )
)

if not engine.rootObjects():
    sys.exit(1)

sys.exit(app.exec())
