# XONIANT32 ULTIMATE
### by Darian Alberto Camacho Salas

---

## 📋 Descripción

**XONIANT32 ULTIMATE** es una transformación de **antiX Linux** (Debian Stable de 32 bits) que configura el sistema para que inicie directamente en una **terminal gráfica fija**, manteniendo **TODOS los controladores y paquetes originales** de antiX. Ideal para hardware antiguo (como ASUS Eee PC 900) con máxima compatibilidad para reproducción de video y herramientas XONI.

### Características principales

- **NO elimina ningún paquete** – Conserva TODOS los controladores de video, audio, WiFi, Bluetooth, impresión, etc.
- **Terminal principal FIJA** – Ocupa toda la pantalla, sin bordes, NO SE PUEDE CERRAR.
- **Ventanas emergentes SUPERPUESTAS** – Las nuevas terminales y reproductores (mpv) se ven **ENCIMA** de la principal.
- **Atajos de teclado COMPLETOS** – Alt+Tab, Ctrl+Alt+T, Alt+F4, Alt+F10, Win+x, Win+q.
- **Soporte de ratón** – Seleccionar texto copia automáticamente; click derecho pega.
- **Copiar/Pegar con teclado** – Ctrl+Shift+C/V, Ctrl+Insert/Shift+Insert.
- **Sin escritorio visible** – El sistema arranca directamente en la terminal, sin barras ni menús.
- **Compatible con XoniTube v5.5** – Reproducción de YouTube optimizada.
- **Scripts XONI** – Instalación automática de herramientas en `~/` (xonitube, xonigraf, xonichat, etc.).

---

## ⚠️ Advertencia

Este script **NO ELIMINA NINGÚN PAQUETE** del sistema antiX original. Solo **AÑADE y CONFIGURA** la terminal fija y los atajos. Es seguro para tu sistema y conserva todas las funcionalidades originales.

---

## 📥 Requisitos previos

- Tener **antiX Linux 32 bits ya instalado** en tu disco duro (o ejecutarse desde live USB con persistencia).
- Conexión a internet (cable o WiFi) – opcional, solo si quieres instalar herramientas XONI después.
- Ejecutar el script con permisos de superusuario (`sudo`).

---

## 🚀 Instalación (desde antiX ya instalado)

Puedes descargar el script de instalación usando cualquiera de estos métodos:

### Opción 1: con `wget`

```bash
wget -O install-xoniant32.sh https://raw.githubusercontent.com/XONIDU/xoniant32/main/install-xoniant32.sh
chmod +x install-xoniant32.sh
sudo ./install-xoniant32.sh
```

### Opción 2: con `curl`

```bash
curl -L -o install-xoniant32.sh https://raw.githubusercontent.com/XONIDU/xoniant32/main/install-xoniant32.sh
chmod +x install-xoniant32.sh
sudo ./install-xoniant32.sh
```

### Opción 3: con `git` (clonando el repositorio)

```bash
git clone https://github.com/XONIDU/xoniant32.git
cd xoniant32
chmod +x install-xoniant32.sh
sudo ./install-xoniant32.sh
```

El script te pedirá confirmación una vez y luego hará todo automáticamente.

---

## 🎯 Primer inicio después de la instalación

1. Reinicia el sistema: `sudo reboot`
2. Iniciará **directamente en la terminal gráfica fija** (pantalla negra con terminal).
3. La terminal principal **NO SE PUEDE CERRAR** (no tiene botón X ni responde a Alt+F4).
4. Usa los atajos de teclado para operar el sistema.

---

## ⌨️ Atajos de teclado

| Tecla | Acción |
|-------|--------|
| `Alt+Tab` | Cambiar entre ventanas emergentes |
| `Alt+F4` | Cerrar ventana actual (excepto la principal) |
| `Alt+F10` | Maximizar/restaurar ventana |
| `Win+↑` | Maximizar ventana |
| `Ctrl+Alt+T` | Abrir nueva terminal (emergente, encima de la principal) |
| `Win+x` | Abrir menú principal |
| `Win+q` | Cerrar sesión (única forma de salir) |
| `Ctrl+Alt+←/→` | Cambiar escritorio virtual |

---

## 🖱️ Ratón y portapapeles

| Acción | Resultado |
|--------|-----------|
| **Seleccionar texto** | Copia automáticamente al portapapeles |
| **Click derecho** | Pega el texto copiado |
| `Ctrl+Shift+C` | Copiar selección |
| `Ctrl+Shift+V` | Pegar |
| `Ctrl+Insert` | Copiar |
| `Shift+Insert` | Pegar |

---

## 📦 Comandos XONI disponibles

| Comando | Descripción |
|---------|-------------|
| `xoni-install <herramienta>` | Instala una herramienta XONI en `~/<herramienta>` y crea el comando global. |
| `xoni-update` | Actualiza los scripts del sistema y las herramientas en `~/`. |
| `xoni-help` | Muestra esta ayuda completa. |
| `xoni-menu` | Abre un menú interactivo con opciones rápidas. |

### Herramientas disponibles (desde XONIDU)

```bash
xoni-install xonitube    # Buscador y reproductor de YouTube
xoni-install xonigraf    # Graficador matemático
xoni-install xonichat    # Chat con IA (Gemini)
xoni-install xonimail    # Cliente de correo
# ... y más en https://github.com/XONIDU
```

---

## 🌐 Conectarse a WiFi (connman)

```bash
sudo connmanctl
```

Dentro de `connmanctl`:

```bash
agent on
enable wifi
scan wifi
services
connect wifi_nombre_de_tu_red   # Usa TAB para autocompletar
quit
```

También puedes usar la opción 3 del menú interactivo (`xoni-menu`).

---

## 🔊 Ajustar volumen (ALSA)

```bash
alsamixer
```

Usa las flechas para subir/bajar el volumen y `Esc` para salir.

---

## 🔄 Actualización del sistema

Para mantener tus scripts XONI actualizados, ejecuta:

```bash
xoni-update
```

Esto clonará/actualizará el repositorio principal y sincronizará los cambios.

---

## 💻 Hardware soportado

### Mínimo
- **Procesador**: 32 bits (i386)
- **RAM**: 512 MB (recomendado 1 GB)
- **Almacenamiento**: 8 GB
- **Gráficos**: Cualquier chip compatible con Xorg (todos los controladores originales se conservan)

### Probado en
- **ASUS Eee PC 900** (Intel Celeron M 900MHz, 1GB RAM, GMA 900)
- **ThinkPad X60** (Intel Core Duo, 32 bits)
- **VirtualBox / QEMU**

---

## 🛠️ Solución de problemas comunes

### ❌ Error de conexión WiFi
```bash
sudo sv restart connman   # antiX usa runit
sudo connmanctl
# Vuelve a conectar
```

### ❌ No se ven las ventanas emergentes
Verifica que la terminal principal tenga `layer>below` y las emergentes `layer>above` en `~/.config/openbox/rc.xml`. El script ya lo configura automáticamente.

### ❌ El video de XoniTube no se ve
Este script conserva TODOS los controladores originales, por lo que mpv debería funcionar sin problemas. Si hay problemas, prueba:

```bash
mpv --vo=x11 --ao=alsa https://youtu.be/...
```

### ❌ La terminal principal se cerró accidentalmente
Si lograste cerrarla (muy difícil), reinicia el gestor de display:

```bash
sudo systemctl restart lightdm   # o sddm/lxdm/slim
```

---

## 📋 Estructura del repositorio

```
xoniant32/
├── install-xoniant32.sh   # Script principal de instalación (versión Ultimate)
├── install-xoniant32.sh            # Script original (con purga de paquetes)
├── README.md                       # Este archivo
└── .gitignore                      # Archivos ignorados
```

---

## ✉️ Contacto y créditos

- **Autor**: Darian Alberto Camacho Salas
- **Email**: xonidu@gmail.com
- **Web**: [https://xonipage.xonidu.com/](https://xonipage.xonidu.com/)
- **GitHub**: [@XONIDU](https://github.com/XONIDU)

---

## 🌐 Enlaces útiles

- [Repositorio XONIANT32](https://github.com/XONIDU/xoniant32)
- [antiX Linux oficial](https://antixlinux.com/)
- [Foro de antiX](https://www.antixforum.com/)

---

⭐ **Si te gusta el proyecto, no olvides dejar una estrella en GitHub** ⭐
```

---

## 📝 **Resumen de cambios en el README**

| Sección | Cambio |
|---------|--------|
| **Título** | XONIANT32 ULTIMATE |
| **Descripción** | Aclarado que NO elimina paquetes, conserva TODOS los controladores |
| **Advertencia** | Cambiada para reflejar que es seguro y no elimina nada |
| **Instalación** | Añadida opción con `curl` y `git` |
| **Atajos** | Incluidos todos los nuevos (Alt+F10, Win+↑, etc.) |
| **Ratón** | Nueva sección con explicación de copiar/pegar |
| **Comandos XONI** | Misma estructura, actualizado el nombre del script |
| **Estructura** | Aclarado que hay dos versiones (original y Ultimate) |


