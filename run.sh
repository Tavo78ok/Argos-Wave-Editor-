#!/bin/bash
# run.sh — Launcher de ArgOS Wave Editor
# Setea variables de compatibilidad CPU *antes* de iniciar Python,
# para que las librerías C (GStreamer/libav/OpenBLAS) también las vean.

# ── Compatibilidad con CPUs sin AVX2/AVX512 (Pentium E5400, Atom, etc.) ──────
export OPENBLAS_CORETYPE=PRESCOTT
export OMP_NUM_THREADS=1
export VECLIB_MAXIMUM_THREADS=1
export NPY_DISABLE_CPU_FEATURES="AVX2 AVX512F AVX512CD AVX512_KNL \
AVX512_KNM AVX512_SKX AVX512_CLX AVX512_CNL AVX512_ICL AVX512_ICX \
AVX512_SPR AVX512_SNC4 AVX512_VL AVX512_BW AVX512_DQ AVX512_4FMAPS \
AVX512_4VNNIW AVX512_VNNI AVX512_VBMI2 AVX512_BF16 AVX512_VBMI"

# ── GStreamer ─────────────────────────────────────────────────────────────────
export GST_GL_DISABLE_EXTENSIONS=1

# ── ffmpeg: silenciar logs y DESHABILITAR reportes en disco ──────────────────
export AV_LOG_LEVEL=quiet
unset FFREPORT          # si FFREPORT está definida ffmpeg crea archivos .log

# ── Wayland (descomentar si hay problemas gráficos) ───────────────────────────
# export GDK_BACKEND=x11

# ── Modo diagnóstico ──────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$1" == "--diagnostico" || "$1" == "--diag" ]]; then
    echo "Ejecutando diagnóstico de compatibilidad..."
    exec python3 "$SCRIPT_DIR/diagnostico.py"
fi

# ── Lanzar ────────────────────────────────────────────────────────────────────
exec python3 "$SCRIPT_DIR/argos_wave_editor.py" "$@"
