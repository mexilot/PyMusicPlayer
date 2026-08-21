#!/bin/bash
set -e

APP="MusicApp"
ROOT="$(cd "$(dirname "$0")" && pwd)"
APPDIR="$ROOT/AppDir"

rm -rf "$APPDIR" "$ROOT/${APP}-x86_64.AppImage"

mkdir -p \
    "$APPDIR/usr/bin" \
    "$APPDIR/usr/share/applications" \
    "$APPDIR/usr/share/icons/hicolor/scalable/apps"

cp "$ROOT/main.py" "$APPDIR/usr/bin/"
cp "$ROOT/player.py" "$APPDIR/usr/bin/"
cp "$ROOT/main.qml" "$APPDIR/usr/bin/"
cp "$ROOT/requirements.txt" "$APPDIR/usr/bin/"
cp -r "$ROOT/MusicStyle" "$APPDIR/usr/bin/"
cp -r "$ROOT/assets" "$APPDIR/usr/bin/" 2>/dev/null || true

cat > "$APPDIR/usr/bin/$APP" <<'LAUNCHER'
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
cd "$HERE"
exec python main.py "$@"
LAUNCHER

chmod +x "$APPDIR/usr/bin/$APP"

cat > "$APPDIR/usr/share/applications/$APP.desktop" <<'DESKTOP'
[Desktop Entry]
Name=MusicApp
Comment=Reproductor multimedia con letras sincronizadas
Exec=MusicApp
Icon=musicapp
Terminal=false
Type=Application
Categories=AudioVideo;Audio;Player;
DESKTOP

cat > "$APPDIR/usr/share/icons/hicolor/scalable/apps/musicapp.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
<defs>
<linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="#ff3385"/>
<stop offset="1" stop-color="#ff0080"/>
</linearGradient>
</defs>
<rect x="32" y="32" width="448" height="448" rx="96" fill="url(#g)"/>
<path d="M300 112v238c0 42-35 76-78 76s-78-34-78-76 35-76 78-76c14 0 27 3 39 10V172l150-42v190c0 42-35 76-78 76s-78-34-78-76 35-76 78-76c14 0 27 3 39 10V112z" fill="white"/>
</svg>
SVG

if ! command -v linuxdeploy >/dev/null 2>&1; then
    if [ ! -f "$ROOT/linuxdeploy-x86_64.AppImage" ]; then
        curl -L \
            -o "$ROOT/linuxdeploy-x86_64.AppImage" \
            https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
        chmod +x "$ROOT/linuxdeploy-x86_64.AppImage"
    fi
    LINUXDEPLOY="$ROOT/linuxdeploy-x86_64.AppImage"
else
    LINUXDEPLOY="$(command -v linuxdeploy)"
fi

cd "$ROOT"

ARCH=x86_64 "$LINUXDEPLOY" \
    --appdir "$APPDIR" \
    --desktop-file "$APPDIR/usr/share/applications/$APP.desktop" \
    --output appimage

echo
echo "======================================"
echo " AppImage creado correctamente"
echo "======================================"
echo

ls -lh "$ROOT"/MusicApp*.AppImage
