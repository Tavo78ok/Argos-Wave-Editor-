# ArgOS Wave Editor

<p align="center">
  <img src="https://img.shields.io/badge/version-1.1.0-blue?style=flat-square"/>
  <img src="https://img.shields.io/badge/platform-Linux-orange?style=flat-square&logo=linux"/>
  <img src="https://img.shields.io/badge/GTK-4.0-green?style=flat-square"/>
  <img src="https://img.shields.io/badge/libadwaita-1.x-purple?style=flat-square"/>
  <img src="https://img.shields.io/badge/license-GPL--3.0-red?style=flat-square"/>
  <img src="https://img.shields.io/badge/numpy--free-✓-brightgreen?style=flat-square"/>
</p>

<p align="center">
  Editor de audio waveform para Linux, inspirado en Nero Wave Editor.<br>
  Parte del ecosistema <strong>ArgOS Platinum Edition</strong>.
</p>

---

## ✨ Características

### 🎵 Carga y visualización
- **Carga progresiva** tipo Audacity — la forma de onda aparece mientras decodifica
- Visualización estéreo con colores diferenciados (L azul / R verde)
- Grilla de tiempo adaptativa que se ajusta al nivel de zoom
- Zoom con rueda del ratón o botones, hasta nivel de muestra individual
- Compatible con archivos de **cualquier duración** sin colgar la interfaz

### ✂️ Edición
- Selección de región con clic y arrastrar
- Cortar · Copiar · Pegar · Eliminar
- **30 niveles de Deshacer/Rehacer**
- Procesado de efectos en hilo de fondo — la UI nunca se congela

### 🎛️ Efectos
| Efecto | Descripción |
|---|---|
| Fade In | Fundido de entrada suave |
| Fade Out | Fundido de salida suave |
| Normalizar | Pico al 99% sin clipping |
| Silenciar | Pone a cero la región |
| Invertir | Reversa del audio |
| Amplificar | Ganancia configurable en dB |
| **Ecualizador 10 bandas** | Biquad peaking IIR, acelerado con gcc |

### 🎚️ Ecualizador gráfico
- **10 bandas:** 32 · 64 · 125 · 250 · 500 · 1k · 2k · 4k · 8k · 16k Hz
- **12 presets:** Plano, Rock, Pop, Jazz, Clásica, Bass Boost, Vocal, Electrónica, Metal, Reggae, Acoustic, Lo-Fi
- Filtros biquad peaking IIR compilados con `gcc -O2` — **100× más rápido** que Python puro
- Procesado en hilo de fondo con progreso visible en barra de estado

### 💾 Formatos

| Formato | Lectura | Escritura | Bitrate |
|---|:---:|:---:|---|
| WAV | ✅ | ✅ | — (sin pérdida) |
| FLAC | ✅ | ✅ | — (sin pérdida) |
| Opus | ✅ | ✅ | 64–320 kbps |
| OGG Vorbis | ✅ | ✅ | 96–320 kbps |
| MP3 | ✅ | ✅ | 128–320 kbps |
| M4A / AAC | ✅ | ✅ | 96–256 kbps |

### 🖥️ Compatibilidad de hardware
- **Sin numpy, sin scipy** — no hay SIGILL por instrucciones AVX2/AVX512
- Funciona en **Pentium E5400**, Core2, Atom y CPUs sin extensiones modernas
- Probado en LMDE 6, Linux Mint 22, Ubuntu 24.04

---

## 📦 Instalación

### Opción 1 — Paquete .deb

```bash
wget https://github.com/Tavo78ok/argos-wave-editor/releases/latest/download/argos-wave-editor_1.1.0_all.deb
sudo dpkg -i argos-wave-editor_1.1.0_all.deb
sudo apt-get install -f
```

### Opción 2 — Desde el código fuente

```bash
git clone https://github.com/Tavo78ok/argos-wave-editor.git
cd argos-wave-editor

sudo apt install \
  python3-gi python3-gi-cairo \
  gir1.2-gtk-4.0 gir1.2-adw-1 \
  gir1.2-gstreamer-1.0 \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-base \
  gstreamer1.0-alsa \
  ffmpeg gcc

bash run.sh
```

### Construir el .deb

```bash
sudo apt install dpkg-dev
bash build_deb.sh
sudo dpkg -i argos-wave-editor_1.1.0_all.deb
```

---

## ⌨️ Atajos de teclado

| Tecla | Acción |
|---|---|
| `Espacio` | Reproducir / Pausar |
| `Ctrl+O` | Abrir archivo |
| `Ctrl+S` | Guardar |
| `Ctrl+Z / Y` | Deshacer / Rehacer |
| `Ctrl+X / C / V` | Cortar / Copiar / Pegar |
| `Ctrl+A` | Seleccionar todo |
| `Ctrl+E` | Ecualizador |
| `Supr` | Eliminar selección |
| `Inicio / Fin` | Ir al inicio / final |
| `Ctrl++ / -` | Zoom in / out |
| Rueda ratón | Zoom en la forma de onda |

---

## 🏗️ Arquitectura

```
argos_wave_editor.py  (~1500 líneas, un solo archivo)
│
├── AudioData              Modelo — list[array.array('f')] por canal
├── load_audio_streaming   Carga progresiva via ffmpeg pipe
├── save_wav_file          WAV via ffmpeg pipe + fallback wave stdlib
├── export_audio_file      Exportación via ffmpeg con codec/bitrate
│
├── EQ DSP
│   ├── _try_compile_c     Compila helper C con gcc al arrancar
│   ├── _biquad_filter_c   Filtro via ctypes (100× Python)
│   └── _biquad_filter_py  Fallback Python puro
│
├── WaveformWidget         Gtk.DrawingArea + Cairo
│   ├── Caché de picos por bloque
│   ├── Grilla de tiempo adaptativa
│   └── Selección drag & drop
│
├── ExportDialog           Formato + bitrate + carpeta + nombre
├── EqualizerDialog        10 sliders + 12 presets
└── AmplifyDialog          Ganancia en dB
```

### ¿Por qué sin numpy?

El numpy del repositorio de Debian/Ubuntu viene compilado con AVX2/AVX512. En CPUs anteriores a 2013 esto provoca `SIGILL` (Instrucción Ilegal) al hacer `import numpy`. La solución es `array.array` de la stdlib (4 bytes/muestra, sin overhead) y `ffmpeg` para toda la decodificación. Para el EQ, un helper C compilado on-the-fly con `gcc -O2 -shared` y cargado via `ctypes` da el mismo rendimiento que scipy sin ninguna dependencia binaria.

---

## 📋 Dependencias

| Paquete | Rol |
|---|---|
| `python3-gi` | Bindings GTK/GLib |
| `gir1.2-gtk-4.0` | GTK 4 |
| `gir1.2-adw-1` | libadwaita |
| `gir1.2-gstreamer-1.0` | GStreamer |
| `gstreamer1.0-plugins-good` | Codecs de audio |
| `gstreamer1.0-alsa` | Salida de audio |
| `ffmpeg` | Decodificación y exportación |
| `gcc` | Aceleración C del ecualizador |

---

## 🗺️ Roadmap

- [ ] Marcadores con etiquetas
- [ ] Vista de espectrograma
- [ ] Grabación desde micrófono
- [ ] Trim automático de silencio
- [ ] Archivos recientes
- [ ] Integración de metadatos con ArgOS Tag Studio

---

## 👨‍💻 Autor

**Tavo78ok** — ArgOS Platinum Edition · [github.com/Tavo78ok](https://github.com/Tavo78ok)

## 📄 Licencia

GNU General Public License v3.0

---

*ArgOS Wave Editor es parte de un ecosistema GTK4/libadwaita para Linux:*
*Melodia Player · ArgOS Tag Studio · ArgOS Opus Forge · FFmpeg Studio · ArgOS Security Auditor*
