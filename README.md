# XONIARCH32 v5.1
### by Darian Alberto Camacho Salas

---

## 📋 Descripción

XONIARCH32 es una distribución Linux ligera basada en **Arch Linux 32 bits**, diseñada para hardware antiguo y de bajos recursos. El sistema incluye un instalador interactivo que configura todo automáticamente: detección de hardware, controladores, entorno gráfico con terminal fija y herramientas XONI.

---

## ✨ Características

- **Instalador interactivo** – Pregunta ubicación, teclado, idioma, usuario y contraseña
- **Detección automática de hardware** – CPU, GPU, audio, WiFi (instala controladores según el equipo)
- **GRÁFICO SIEMPRE ACTIVO** – Arranca directamente en entorno gráfico (sin `startx`)
- **Terminal fija** – La terminal principal no se puede cerrar
- **Múltiples gestores de display** – LightDM, SDDM, LXDM, SLiM (si uno falla, otro intenta)
- **Scripts XONI** – `installxoni`, `xoniarch-update`, `xoniarch-menu`, `xoniarch-help`
- **Actualización desde GitHub** – `xoniarch-update` mantiene las herramientas al día

---

## 📥 Instalación desde live USB

### Requisitos previos
- Live USB de **Arch Linux 32 bits** ([descargar](https://archlinux32.org))
- Conexión a internet (cable o WiFi)
- Al menos 8 GB libres en el disco de destino

### Pasos

1. **Arranca desde el live USB**

2. **Conéctate a internet** (por cable o WiFi con `iwctl`)

3. **Descarga el instalador**
   ```bash
   curl -O https://raw.githubusercontent.com/XONIDU/xoniarch32/main/install-xoniarch.sh
   ```

4. **Ejecuta el instalador**
   ```bash
   bash install-xoniarch.sh
   ```

5. **Sigue las instrucciones** (ubicación, idioma, teclado, usuario, disco, swap)

6. **Reinicia al finalizar**
   ```bash
   sudo reboot
   ```

---

## 🎯 Primer inicio

- **Usuario**: el que elegiste durante la instalación
- **Contraseña**: la que configuraste
- **Root**: `root` (misma contraseña)

El sistema arrancará **directamente en modo gráfico** con una **terminal fija** que no se puede cerrar. Usa el menú contextual (clic derecho) o las teclas rápidas.

---

## 📦 Comandos principales

| Comando | Descripción |
|---------|-------------|
| `installxoni <herramienta>` | Instalar herramienta XONI desde GitHub |
| `xoniarch-update` | Actualizar todas las herramientas |
| `xoniarch-menu` | Menú interactivo |
| `xoniarch-help` | Mostrar ayuda completa |
| `nmtui` | Configurar red WiFi/Ethernet |
| `htop` | Monitor del sistema |

---

## ⌨️ Atajos de teclado

| Tecla | Acción |
|-------|--------|
| `Win + x` | Abrir menú principal |
| `Win + t` | Abrir nueva terminal |
| `Win + h` | Mostrar ayuda |
| `Win + i` | Instalar herramienta XONI |
| `Win + q` | Cerrar sesión |

---

## 🛠️ Herramientas XONI disponibles

```bash
installxoni xonitube    # Reproductor de YouTube
installxoni xonigraf    # Graficador matemático
installxoni xonichat    # Chat con IA Gemini
installxoni xonimail    # Cliente de correo
installxoni xoniencript # Cifrado de archivos
installxoni xoniweb     # Análisis de malware web
installxoni xonidip     # Generador de diplomas
installxoni xonidate    # Generador de citas
installxoni xoniconver  # Conversor de formatos
installxoni xoniter     # Acceso rápido a comandos
installxoni xonial      # Monitoreo de servicio social
installxoni xonispam    # Pruebas éticas de spam
```

---

## 🔧 Solución de problemas comunes

### ❌ Error de firmas PGP
```bash
pacman-key --init
pacman-key --populate archlinux32
pacman-key --refresh-keys
```

### ❌ No aparece el disco
```bash
lsblk  # Verifica que el disco sea visible
```

### ❌ WiFi no funciona
```bash
rfkill unblock wifi
systemctl restart iwd
iwctl
device list
station wlan0 scan
station wlan0 connect "SSID"
```

### ❌ La terminal fija se cerró accidentalmente
```bash
sudo systemctl restart lightdm   # o sddm, lxdm, slim
```

---

## 💻 Hardware soportado

### Mínimo
- **Procesador**: Intel Pentium III / Celeron (32 bits)
- **RAM**: 512 MB
- **Almacenamiento**: 8 GB
- **Gráficos**: VESA compatible

### Probado en
- ASUS Eee PC 900 (Intel Celeron M 900MHz, 1GB RAM, GMA 900)
- ThinkPad X60 (Intel Core Duo, 32 bits)
- VirtualBox / QEMU

---

## 📥 Descargar Arch Linux 32 bits

| Región | Mirror |
|--------|--------|
| Alemania | `https://mirror.archlinux32.org` |
| Alemania | `https://ftp.halifax.rwth-aachen.de/archlinux32` |
| Estados Unidos | `https://mirror.clarkson.edu/archlinux32` |
| Francia | `https://archlinux32.agoctrl.org` |
| Rusia | `https://mirror.yandex.ru/archlinux32` |

**ISO recomendada**: [https://mirror.archlinux32.org/iso/latest/](https://mirror.archlinux32.org/iso/latest/) (~800 MB)

---

## 🔄 Actualización del sistema

```bash
# Actualizar herramientas XONI
xoniarch-update

# Actualizar paquetes del sistema
sudo pacman -Syu
```

---

## 📁 Estructura del repositorio

```
xoniarch32/
├── install-xoniarch.sh    # Instalador principal
├── README.md              # Este archivo
└── requisitos.txt         # Dependencias detalladas
```

---

## ✉️ Contacto y créditos

- **Autor**: Darian Alberto Camacho Salas
- **Email**: xonidu@gmail.com
- **Web**: [https://xonipage.xonidu.com/](https://xonipage.xonidu.com/)
- **GitHub**: [@XONIDU](https://github.com/XONIDU)

---

## 🌐 Enlaces útiles

- [Repositorio XONIARCH32](https://github.com/XONIDU/xoniarch32)
- [Arch Linux 32 Official](https://archlinux32.org/)
- [Guía de instalación de Arch](https://wiki.archlinux.org/title/Installation_guide)

---

⭐ **Si te gusta el proyecto, no olvides dejar una estrella en GitHub** ⭐

