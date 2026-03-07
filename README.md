# 🏔️ XONIANT32 v4.2.0
### by Darian Alberto Camacho Salas

---

## 📋 Descripción

**XONIANT32** es una distribución Linux ultraligera basada en **antiX 32 bits**, diseñada específicamente para hardware antiguo y de bajos recursos (386, Pentium, Celeron). El sistema consiste en una base antiX completamente purgada de todo lo innecesario, dejando solo:

- **Openbox** como gestor de ventanas
- **Terminal fija** que no se puede cerrar
- **Soporte de audio** completo (ALSA + PulseAudio)
- **nmtui** para configuración de red
- **Scripts XONI** para instalar herramientas desde GitHub

El resultado es un sistema extremadamente liviano que arranca directamente en modo gráfico con una única terminal fija.

---

## ✨ Características principales

- **Ultraligero** – Consume menos de 150 MB de RAM en reposo
- **Sin escritorio** – Solo Openbox con terminal fija (no se puede cerrar)
- **Gráfico siempre activo** – Arranca directamente en X sin gestor de display
- **Soporte de audio** – ALSA + PulseAudio para todo tipo de hardware
- **Red por terminal** – `nmtui` para configurar WiFi/Ethernet fácilmente
- **Scripts XONI** – `installxoni`, `xoniarch-update`, `xoniarch-help`, `xoniarch-menu`
- **Actualización desde GitHub** – Mantén tus herramientas al día

---

## 📥 Requisitos previos

- **AntiX 32 bits** ya instalado en el disco duro (versión 21, 22 o 23)
- Conexión a internet (para descargar paquetes durante la conversión)
- Al menos **2 GB libres** en el disco (después de la purga quedará mucho más espacio)

---

## 🚀 Instalación / Conversión

### Paso 1: Arranca tu antiX ya instalado

Inicia sesión normalmente.

### Paso 2: Abre una terminal y descarga el script de conversión

```bash
wget -O purgar-xoniant32.sh https://raw.githubusercontent.com/XONIDU/xoniant32/main/purgar.sh
```

(Si no tienes `wget`, usa `curl -O` o crea el archivo manualmente con `nano`)

### Paso 3: Da permisos de ejecución

```bash
chmod +x purgar-xoniant32.sh
```

### Paso 4: Ejecuta el script como root

```bash
sudo ./purgar-xoniant32.sh
```

### Paso 5: Sigue las instrucciones

- El script te pedirá confirmación con **YES** (en mayúsculas)
- La purga puede tomar varios minutos dependiendo de tu hardware
- Al finalizar, te pedirá reiniciar

### Paso 6: Reinicia

```bash
sudo reboot
```

---

## 🎯 Primer inicio

Después del reinicio:

- El sistema arrancará directamente en **modo gráfico** con una **terminal fija** (no se puede cerrar)
- Usuario: el mismo que tenías en antiX
- Contraseña: la misma

---

## 📦 Comandos principales

| Comando | Descripción |
|---------|-------------|
| `xoniarch-help` | Mostrar ayuda completa |
| `xoniarch-menu` | Abrir menú interactivo |
| `installxoni <herramienta>` | Instalar herramienta XONI desde GitHub |
| `xoniarch-update` | Actualizar todas las herramientas |
| `nmtui` | Configurar red WiFi/Ethernet |
| `htop` | Monitor del sistema |
| `alsamixer` | Ajustar volumen |

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
installxoni xonitube    # Reproductor de YouTube en terminal
installxoni xonigraf    # Graficador matemático (requiere X)
installxoni xonichat    # Chat con IA Gemini
installxoni xonimail    # Cliente de correo desde terminal
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

## 🔧 Solución de problemas comunes

### ❌ WiFi no funciona

```bash
sudo nmtui
```
Dentro de `nmtui`, selecciona "Activar una conexión" y elige tu red WiFi.

### ❌ No hay sonido

```bash
alsamixer
```
Asegúrate de que no esté muteado (presiona `M` para activar). Luego prueba:
```bash
speaker-test -t sine -f 440
```

### ❌ La terminal fija se cerró accidentalmente

Reinicia la sesión gráfica:
```bash
sudo systemctl restart getty@tty1
```
O simplemente reinicia el sistema.

### ❌ Quiero instalar más paquetes

```bash
sudo apt update
sudo apt install <paquete>
```

---

## 📁 Estructura del repositorio

```
xoniant32/
├── purgar.sh            # Script de conversión (ejecutar desde antiX)
├── README.md            # Este archivo
└── scripts/             # Scripts individuales (opcional)
    ├── installxoni
    ├── xoniarch-update
    ├── xoniarch-help
    └── xoniarch-menu
```

---

## 💻 Hardware probado

| Equipo | Especificaciones | Estado |
|--------|------------------|--------|
| ASUS Eee PC 900 | Intel Celeron M 900MHz, 1GB RAM | ✅ Funciona perfecto |
| ThinkPad X60 | Intel Core Duo, 2GB RAM | ✅ Funciona |
| Pentium III | 800MHz, 512MB RAM | ✅ Funciona |
| VirtualBox | Cualquier VM 32 bits | ✅ Funciona |

---

## 🔄 Actualización del sistema

```bash
# Actualizar herramientas XONI
xoniarch-update

# Actualizar paquetes base (si es necesario)
sudo apt update
sudo apt upgrade
```

---

## 🧠 ¿Cómo funciona el script de purga?

El script `purgar.sh` realiza:

1. **Purga masiva** de:
   - Entornos de escritorio (XFCE, Fluxbox, IceWM, JWM)
   - Aplicaciones pesadas (LibreOffice, Firefox, Thunderbird)
   - Juegos, herramientas gráficas, clientes de correo
   - Paquetes de desarrollo y documentación

2. **Instalación** de paquetes esenciales:
   - Xorg mínimo
   - Openbox + tint2 + feh + picom + rxvt-unicode
   - ALSA + PulseAudio
   - NetworkManager + nmtui

3. **Configuración**:
   - Openbox con terminal fija (no se puede cerrar)
   - Scripts XONI en `/usr/local/bin`
   - Auto-login en tty1
   - NetworkManager para runit

4. **Resultado**: antiX transformado en xoniant32, ultra minimalista.

---

## ✉️ Contacto y créditos

- **Autor**: Darian Alberto Camacho Salas
- **Email**: xonidu@gmail.com
- **Web**: [https://xonipage.xonidu.com/](https://xonipage.xonidu.com/)
- **GitHub**: [@XONIDU](https://github.com/XONIDU)
- **#Somos XONINDU**

