## 🏔️ **XONIARCH32** v4.2.0
### by Darian Alberto Camacho Salas

---

## 📋 **Descripción**

**XONIARCH32** es una distribución Linux ligera basada en **Arch Linux 32 bits**, diseñada específicamente para hardware antiguo y de bajos recursos. El sistema incluye un instalador completo que automatiza todo el proceso desde el live USB hasta un sistema funcional con entorno gráfico y herramientas XONI.

---

## ✨ **Características principales**

- **Instalador todo-en-uno** – Un solo script que particiona, instala y configura todo.
- **Gráfico siempre activo** – Inicia directamente en entorno gráfico (sin `startx` manual).
- **Terminal fija** – La terminal principal no se puede cerrar.
- **Soporte completo de hardware** – Audio, video, red, WiFi, Bluetooth (controladores incluidos).
- **Herramientas XONI integradas** – Instalación modular mediante `installxoni`.
- **Actualización desde GitHub** – Mantén tu sistema actualizado con `xoniarch-update`.

---

## ⚠️ **Advertencia**

Este sistema es para **fines educativos y personales**. El autor no se responsabiliza del uso que se le dé. Úsalo con responsabilidad.

---

## 📥 **Instalación desde live USB**

### 🔧 **Requisitos previos**
- Live USB de **Arch Linux 32 bits** (descargar desde [archlinux32.org](https://archlinux32.org))
- Conexión a internet (cable o WiFi)
- Al menos 8 GB libres en el disco de destino

### 🚀 **Pasos de instalación**

#### **1. Arranca desde el live USB de Arch Linux 32 bits**

#### **2. Conéctate a internet**

**Por WiFi (usando `iwctl`):**
```bash
iwctl
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect "NombreDeTuRed"
exit
```

**Por cable Ethernet:** conecta y listo.

#### **3. Descarga el instalador**

```bash
curl -O https://raw.githubusercontent.com/XONIDU/xoniarch32/main/install-xoniarch.sh
```

#### **4. Ejecuta el instalador**

```bash
bash install-xoniarch.sh
```

El script te guiará por:
- Selección del disco de instalación
- Particionado (automático con o sin swap, o manual)
- Instalación del sistema base
- Configuración del sistema (locale, hostname, usuario, GRUB)
- Personalización Xoniarch32 (entorno gráfico, scripts, herramientas)

#### **5. Al finalizar, reinicia**

```bash
sudo reboot
```

---

## 🎯 **Primer inicio**

- **Usuario:** `xoniarch`
- **Contraseña:** `xoniarch`
- **Root:** `root` / `root`

El sistema arrancará directamente en modo gráfico con una **terminal fija** que no se puede cerrar. Usa el menú contextual (clic derecho) o las teclas rápidas para acceder a las funciones.

---

## 📦 **Comandos principales**

| Comando | Descripción |
|---------|-------------|
| `installxoni <herramienta>` | Instalar herramienta XONI desde GitHub |
| `xoniarch-update` | Actualizar sistema y herramientas |
| `xoniarch-help` | Mostrar ayuda completa |
| `xoniarch-menu` | Abrir menú interactivo |
| `nmtui` | Configurar red WiFi/Ethernet |
| `htop` | Monitor del sistema |
| `pcmanfm` | Gestor de archivos |
| `alsamixer` | Ajustar volumen |

---

## ⌨️ **Atajos de teclado**

| Tecla | Acción |
|-------|--------|
| `Windows + x` | Abrir menú principal |
| `Windows + t` | Abrir nueva terminal |
| `Windows + h` | Mostrar ayuda |
| `Windows + i` | Instalar herramienta |
| `Windows + q` | Cerrar sesión |

---

## 🛠️ **Herramientas XONI disponibles**

```bash
installxoni xonitube    # Reproductor de videos YouTube
installxoni xonigraf    # Graficador matemático
installxoni xonichat    # Chat con IA Gemini
installxoni xonimail    # Cliente de correo
installxoni xoniencript # Cifrado de archivos
installxoni xoniweb     # Análisis de malware web
installxoni xonidip     # Generador de diplomas
installxoni xonidate    # Generador de citas aleatorias
installxoni xoniconver  # Conversor de formatos
installxoni xoniter     # Acceso rápido a comandos
installxoni xonial      # Monitoreo de servicio social
installxoni xonispam    # Pruebas éticas de spam
```

---

## 🔧 **Solución de problemas comunes**

### ❌ **Error de firmas PGP al instalar**
```bash
pacman-key --init
pacman-key --populate archlinux32
pacman-key --refresh-keys
pacman -Sy
```

### ❌ **No aparece el disco en el instalador**
```bash
lsblk  # Verifica que el disco sea visible
# Si usas máquina virtual, asegura que el controlador SATA esté activado
```

### ❌ **WiFi no funciona**
```bash
rfkill unblock wifi
systemctl restart iwd
iwctl
device list
station wlan0 scan
station wlan0 connect "SSID"
```

### ❌ **La terminal fija se cerró accidentalmente**
Reinicia el servidor gráfico:
```bash
sudo systemctl restart sddm
```

---

## 📥 **Descargar Arch Linux 32 bits**

### 🌐 **Mirrors oficiales**

| Región | Mirror |
|--------|--------|
| Alemania | [de.mirror.archlinux32.org](http://de.mirror.archlinux32.org) |
| Alemania | [mirror.archlinux32.org](http://mirror.archlinux32.org) |
| Estados Unidos | [mirror.clarkson.edu](http://mirror.clarkson.edu) |
| Estados Unidos | [mirror.math.princeton.edu](http://mirror.math.princeton.edu) |
| Francia | [archlinux32.agoctrl.org](http://archlinux32.agoctrl.org) |
| Rusia | [mirror.yandex.ru](http://mirror.yandex.ru) |

### 📦 **ISO recomendada**
- **Última versión estable:** [https://mirror.archlinux32.org/iso/latest/](https://mirror.archlinux32.org/iso/latest/)
- **Tamaño:** ~800 MB

---

## 🔄 **Actualización del sistema**

```bash
# Actualizar herramientas XONI
xoniarch-update

# Actualizar paquetes del sistema
sudo pacman -Syu
```

---

## 💻 **Hardware soportado**

### **Mínimo**
- Procesador: Intel Pentium III / Celeron (32 bits)
- RAM: 512 MB
- Almacenamiento: 8 GB
- Gráficos: VESA compatible

### **Probado en**
- ASUS Eee PC 900 (Intel Celeron M 900MHz, 1GB RAM, GMA 900)
- ThinkPad X60 (Intel Core Duo, 32 bits)
- VirtualBox / QEMU

---

## 🧠 **Estructura del repositorio**

```
xoniarch32/
├── install-xoniarch.sh    # Instalador principal (ejecutar desde live)
├── xoniarch-install.sh    # Script de personalización (ejecutado internamente)
├── README.md              # Este archivo
├── requisitos.txt         # Dependencias detalladas
└── .gitignore             # Archivos ignorados
```

---

## ✉️ **Contacto y créditos**

- **Autor:** Darian Alberto Camacho Salas
- **Email:** xonidu@gmail.com
- **Web:** [https://xonipage.xonidu.com/](https://xonipage.xonidu.com/)
- **GitHub:** [@XONIDU](https://github.com/XONIDU)
- **#Somos XONINDU**

---

## 🌐 **Enlaces útiles**

- [Repositorio XONIARCH32](https://github.com/XONIDU/xoniarch32)
- [Arch Linux 32 Official](https://archlinux32.org/)
- [Guía de instalación de Arch](https://wiki.archlinux.org/title/Installation_guide)
- [XONIPAGE](https://xonipage.xonidu.com/)
- [XONIENCRIPT](https://xoniencript.xonidu.com/)
- [XONITRES](https://xonitres.xonidu.com/)

