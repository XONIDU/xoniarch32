# XONIANT32 v4.2.0
### by Darian Alberto Camacho Salas

---

## 📋 Descripción

**XONIANT32** es una distribución Linux ligera basada en **antiX Linux (Debian Stable)**, diseñada específicamente para hardware de 32 bits con recursos limitados. El sistema incluye un instalador completo que automatiza todo el proceso desde el live USB hasta un sistema funcional con entorno gráfico y herramientas XONI.

---

## ✨ Características principales

- **Instalador todo-en-uno** – Un solo script que particiona, instala y configura todo.
- **Gráfico siempre activo** – Arranca directamente en entorno gráfico (sin startx manual).
- **Terminal fija** – La terminal principal no se puede cerrar.
- **Soporte completo de hardware** – Audio, video, red, WiFi, Bluetooth (controladores incluidos).
- **Herramientas XONI integradas** – Instalación modular mediante `xoni-install`.
- **Actualización desde GitHub** – Mantén tu sistema actualizado con `xoni-update`.

---

## ⚠️ Advertencia

Este sistema es para **fines educativos y personales**. El autor no se responsabiliza del uso que se le dé. Úsalo con responsabilidad.

---

## 📥 Instalación desde live USB

### 🔧 Requisitos previos
- Live USB de **antiX Linux 32 bits** (descargar desde [antixlinux.com](https://antixlinux.com))
- Conexión a internet (cable o WiFi)
- Al menos 8 GB libres en el disco de destino

### 🚀 Pasos de instalación

#### 1. Arranca desde el live USB de antiX Linux 32 bits

#### 2. Conéctate a internet

**Por WiFi (usando connman):**
```bash
sudo connmanctl
agent on
enable wifi
scan wifi
services
connect wifi_nombre_de_tu_red
# Ingresa la contraseña cuando se solicite
quit
```

**Por cable Ethernet:** conecta y listo.

#### 3. Descarga el instalador

```bash
wget -O xoniant32-install.sh https://raw.githubusercontent.com/XONIDU/xoniant32/main/install.sh
```

#### 4. Ejecuta el instalador

```bash
chmod +x xoniant32-install.sh
./xoniant32-install.sh
```

El script te guiará por:
- Configuración regional (zona horaria, idioma, teclado)
- Creación de usuario y contraseña
- Selección del disco de instalación
- Particionado (automático con o sin swap)
- Copia del sistema live al disco
- Instalación de gestores de display (lightdm, sddm, lxdm, slim)
- Personalización XONI (scripts, atajos, terminal fija)

#### 5. Al finalizar, reinicia

```bash
sudo reboot
```

---

## 🎯 Primer inicio

- **Usuario:** el que elegiste durante la instalación
- **Contraseña:** la que configuraste
- **Root:** `root` (misma contraseña)

El sistema arrancará **directamente en modo gráfico** con una **terminal fija** que no se puede cerrar. Usa el menú contextual (clic derecho) o las teclas rápidas para acceder a las funciones.

---

## 📦 Comandos principales

| Comando | Descripción |
|---------|-------------|
| `xoni-install <herramienta>` | Instalar herramienta XONI desde GitHub |
| `xoni-update` | Actualizar el sistema xoniant32 desde GitHub |
| `xoni-menu` | Abrir menú interactivo |
| `xoni-help` | Mostrar ayuda completa |
| `nmtui` | Configurar red WiFi/Ethernet |
| `htop` | Monitor del sistema |

---

## ⌨️ Atajos de teclado

| Tecla | Acción |
|-------|--------|
| `Win + x` | Abrir menú principal |
| `Win + t` | Abrir nueva terminal |
| `Win + h` | Mostrar ayuda |
| `Win + u` | Actualizar sistema |
| `Win + q` | Cerrar sesión |

---

## 🛠️ Herramientas XONI disponibles

```bash
xoni-install xonitube    # Reproductor de videos YouTube
xoni-install xonigraf    # Graficador matemático
xoni-install xonichat    # Chat con IA Gemini
xoni-install xonimail    # Cliente de correo
xoni-install xoniencript # Cifrado de archivos
xoni-install xoniweb     # Análisis de malware web
xoni-install xonidip     # Generador de diplomas
xoni-install xonidate    # Generador de citas aleatorias
xoni-install xoniconver  # Conversor de formatos
xoni-install xoniter     # Acceso rápido a comandos
xoni-install xonial      # Monitoreo de servicio social
xoni-install xonispam    # Pruebas éticas de spam
```

---

## 🔧 Solución de problemas comunes

### ❌ Error de partición "device is mounted"

```bash
sudo umount /dev/sd*
sudo partprobe /dev/sdX  # donde X es tu disco
```

### ❌ No aparece el disco en el instalador

```bash
lsblk  # Verifica que el disco sea visible
# Si usas máquina virtual, asegura que el controlador SATA esté activado
```

### ❌ WiFi no funciona

```bash
sudo rfkill unblock wifi
sudo connmanctl
enable wifi
scan wifi
services
connect wifi_nombre_de_tu_red
```

### ❌ La terminal fija se cerró accidentalmente

```bash
sudo systemctl restart lightdm   # o sddm, lxdm, slim según el que esté activo
```

### ❌ NetworkManager no inicia (antiX usa runit)

```bash
sudo ln -s /etc/sv/networkmanager /etc/service/networkmanager
sudo sv start networkmanager
```

---

## 📥 Descargar antiX Linux 32 bits

### 🌐 Mirrors oficiales

| Región | Mirror |
|--------|--------|
| EE.UU. | `https://mirrors.ocf.berkeley.edu/antix-iso/` |
| EE.UU. | `https://mirror.clarkson.edu/antix-iso/` |
| Alemania | `https://ftp.halifax.rwth-aachen.de/antix/` |
| Francia | `https://antix.jouvenot.net/` |
| Países Bajos | `https://mirror.cyberbits.eu/antix/` |

### 📦 ISO recomendada

- **Versión:** antiX-23.2 386 full edition
- **Descarga directa:** [antiX-23.2_386-full.iso](https://sourceforge.net/projects/antix-linux/files/Final/antiX-23.2/antiX-23.2_386-full.iso/download)
- **Tamaño:** ~1.2 GB

---

## 🔄 Actualización del sistema

```bash
# Actualizar herramientas XONI
xoni-update

# Actualizar paquetes del sistema
sudo apt update && sudo apt upgrade -y
```

---

## 💻 Hardware soportado

### Mínimo
- **Procesador**: Intel Pentium III / Celeron (32 bits)
- **RAM**: 512 MB (1 GB recomendado)
- **Almacenamiento**: 8 GB
- **Gráficos**: VESA compatible

### Probado en
- ASUS Eee PC 900 (Intel Celeron M 900MHz, 1GB RAM, GMA 900)
- ThinkPad X60 (Intel Core Duo, 32 bits)
- VirtualBox / QEMU

---

## 🧠 Estructura del repositorio

```
xoniant32/
├── install.sh          # Instalador principal (ejecutar desde live)
├── README.md           # Este archivo
└── .gitignore          # Archivos ignorados
```

---

## ✉️ Contacto y créditos

- **Autor**: Darian Alberto Camacho Salas
- **Email**: xonidu@gmail.com
- **Web**: [https://xonipage.xonidu.com/](https://xonipage.xonidu.com/)
- **GitHub**: [@XONIDU](https://github.com/XONIDU)
- **#Somos XONINDU**

---

## 🌐 Enlaces útiles

- [Repositorio XONIANT32](https://github.com/XONIDU/xoniant32)
- [antiX Linux Official](https://antixlinux.com/)
- [Foro de antiX](https://www.antixforum.com/)

---
 
