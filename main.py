import sys
import dbus.mainloop.glib

from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QUrl, Slot

from player import Player

dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

class MusicApp(QApplication):
    def __init__(self, argv):
        super().__init__(argv)

        self.engine = QQmlApplicationEngine()
        self.player = Player()

        self.engine.rootContext().setContextProperty("player", self.player)
        self.engine.rootContext().setContextProperty("windowController", self)

        self.engine.load(QUrl.fromLocalFile("/home/arturofs/MusicApp/main.qml"))

        if not self.engine.rootObjects():
            sys.exit(1)

    @Slot()
    def startMove(self):
        windows = self.engine.rootObjects()
        if not windows:
            return

        window = windows[0]

        try:
            window.startSystemMove()
        except Exception as e:
            print("No se pudo iniciar el movimiento de ventana:", e)

app = MusicApp(sys.argv)
sys.exit(app.exec())
