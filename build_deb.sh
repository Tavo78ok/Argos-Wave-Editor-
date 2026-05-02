#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
# build_deb.sh — ArgOS Wave Editor v1.1.0
# Script autónomo: no requiere carpeta DEBIAN/ separada.
# Solo necesita argos_wave_editor.py en el mismo directorio.
#
# Uso:  bash build_deb.sh
# Req:  sudo apt install dpkg-dev
# ──────────────────────────────────────────────────────────────────────────────
set -e

PKG="argos-wave-editor"
VER="1.1.0"
ARCH="all"
BUILD_DIR="build/${PKG}_${VER}_${ARCH}"
DEB_OUT="${PKG}_${VER}_${ARCH}.deb"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║      ArgOS Wave Editor v${VER} — build .deb       ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── Verificar herramientas ────────────────────────────────────────────────────
if ! command -v dpkg-deb &>/dev/null; then
    echo "❌  dpkg-deb no encontrado. Instalar con:"
    echo "    sudo apt install dpkg-dev"
    exit 1
fi
if [[ ! -f "argos_wave_editor.py" ]]; then
    echo "❌  argos_wave_editor.py no encontrado en $SCRIPT_DIR"
    exit 1
fi

# ── Estructura de directorios ─────────────────────────────────────────────────
echo "▶  Preparando estructura..."
rm -rf build/
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/lib/argos-wave-editor"
mkdir -p "$BUILD_DIR/usr/share/applications"
mkdir -p "$BUILD_DIR/usr/share/doc/$PKG"

# ── Archivo principal ─────────────────────────────────────────────────────────
echo "▶  Copiando archivos..."
cp argos_wave_editor.py "$BUILD_DIR/usr/lib/argos-wave-editor/"

# ── DEBIAN/control ────────────────────────────────────────────────────────────
cat > "$BUILD_DIR/DEBIAN/control" << 'CONTROL'
Package: argos-wave-editor
Version: 1.1.0
Section: sound
Priority: optional
Architecture: all
Maintainer: Tavo78ok <github.com/Tavo78ok>
Homepage: https://github.com/Tavo78ok/argos-wave-editor
Depends: python3 (>= 3.11), python3-gi, python3-gi-cairo, gir1.2-gtk-4.0, gir1.2-adw-1, gir1.2-gstreamer-1.0, gstreamer1.0-plugins-good, gstreamer1.0-plugins-base, gstreamer1.0-alsa, ffmpeg, gcc
Recommends: python3-pydub
Description: Editor de audio waveform para Linux — ArgOS Platinum Edition
 ArgOS Wave Editor es un editor de audio con interfaz GTK4/libadwaita,
 inspirado en Nero Wave Editor. Compatible con cualquier CPU x86 incluyendo
 Pentium, Core2 y Atom anteriores a 2012. Sin numpy ni scipy.
 .
 Carga progresiva, visualizacion de forma de onda estereo, reproduccion
 GStreamer, edicion (cortar/copiar/pegar), efectos (fade, normalize, reversa,
 amplificar), ecualizador 10 bandas con 12 presets, exportacion a
 WAV/FLAC/Opus/OGG/MP3/M4A con control de bitrate.
 .
 Parte del ecosistema ArgOS Platinum Edition.
CONTROL

# ── DEBIAN/postinst ───────────────────────────────────────────────────────────
cat > "$BUILD_DIR/DEBIAN/postinst" << 'POSTINST'
#!/bin/bash
set -e
echo "ArgOS Wave Editor — configurando dependencias opcionales..."
if ! python3 -c "import pydub" 2>/dev/null; then
    pip3 install --break-system-packages --quiet pydub 2>/dev/null || true
fi
update-desktop-database -q /usr/share/applications 2>/dev/null || true
update-mime-database /usr/share/mime 2>/dev/null || true
echo "ArgOS Wave Editor v1.1.0 instalado. Ejecutar: argos-wave-editor"
exit 0
POSTINST
chmod 755 "$BUILD_DIR/DEBIAN/postinst"

# ── Launcher ─────────────────────────────────────────────────────────────────
cat > "$BUILD_DIR/usr/bin/argos-wave-editor" << 'LAUNCHER'
#!/bin/bash
export OPENBLAS_CORETYPE=PRESCOTT
export OMP_NUM_THREADS=1
export VECLIB_MAXIMUM_THREADS=1
export NPY_DISABLE_CPU_FEATURES="AVX2 AVX512F AVX512CD AVX512_KNL \
AVX512_KNM AVX512_SKX AVX512_CLX AVX512_CNL AVX512_ICL AVX512_ICX \
AVX512_SPR AVX512_SNC4 AVX512_VL AVX512_BW AVX512_DQ AVX512_4FMAPS \
AVX512_4VNNIW AVX512_VNNI AVX512_VBMI2 AVX512_BF16 AVX512_VBMI"
export GST_GL_DISABLE_EXTENSIONS=1
export AV_LOG_LEVEL=quiet
unset FFREPORT
exec python3 /usr/lib/argos-wave-editor/argos_wave_editor.py "$@"
LAUNCHER
chmod 755 "$BUILD_DIR/usr/bin/argos-wave-editor"

# ── .desktop ─────────────────────────────────────────────────────────────────
cat > "$BUILD_DIR/usr/share/applications/io.github.Tavo78ok.ArgOSWaveEditor.desktop" << 'DESKTOP'
[Desktop Entry]
Name=ArgOS Wave Editor
GenericName=Editor de Audio
Comment=Editor de audio waveform para Linux — ArgOS Platinum Edition
Exec=argos-wave-editor %F
Icon=multimedia-audio-player
Terminal=false
Type=Application
Categories=AudioVideo;Audio;GTK;
MimeType=audio/wav;audio/x-wav;audio/mpeg;audio/flac;audio/ogg;audio/opus;audio/mp4;
Keywords=audio;editor;wav;mp3;flac;opus;waveform;argos;
StartupNotify=true
StartupWMClass=argos-wave-editor
DESKTOP

# ── Copyright ─────────────────────────────────────────────────────────────────
cat > "$BUILD_DIR/usr/share/doc/$PKG/copyright" << 'COPYRIGHT'
ArgOS Wave Editor — Copyright 2026 Tavo78ok
License: GNU GPL v3 — https://www.gnu.org/licenses/gpl-3.0.html
Source:  https://github.com/Tavo78ok/argos-wave-editor
COPYRIGHT

gzip -9 -c /dev/null > "$BUILD_DIR/usr/share/doc/$PKG/changelog.Debian.gz"

# ── Permisos finales ──────────────────────────────────────────────────────────
find "$BUILD_DIR" -type d -exec chmod 755 {} \;
find "$BUILD_DIR" -type f -exec chmod 644 {} \;
chmod 755 "$BUILD_DIR/DEBIAN/postinst"
chmod 755 "$BUILD_DIR/usr/bin/argos-wave-editor"

# ── Construir .deb ────────────────────────────────────────────────────────────
echo "▶  Construyendo $DEB_OUT..."
dpkg-deb --build --root-owner-group "$BUILD_DIR" "$DEB_OUT"

echo ""
echo "✅  Paquete listo: $SCRIPT_DIR/$DEB_OUT"
echo ""
echo "    Instalar:    sudo dpkg -i $DEB_OUT"
echo "    Deps falt:   sudo apt-get install -f"
echo "    Verificar:   dpkg-deb --info $DEB_OUT"
echo ""
