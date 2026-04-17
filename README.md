# XONIARCH v.16.4.26

**by Darian Alberto Camacho Salas**

## Descripción

XONIARCH es una distribución Linux especializada que transforma Arch Linux en un entorno de **terminal gráfica fija**, diseñada específicamente para hardware de **64 bits con recursos limitados**.

Este proyecto forma parte del ecosistema **XONIDU**, una organización dedicada al desarrollo de código abierto con énfasis en automatización, optimización de recursos y democratización del acceso a herramientas tecnológicas eficientes.

**Versión actual:** 16.4.26

- 🌐 **Sitio web oficial:** [https://xoniarch.xonidu.com](https://xoniarch.xonidu.com) – Descarga la última ISO, consulta el historial de versiones y accede a la documentación.
- 📚 **Documentación técnica completa:** [Xoniarch 3.4.26 en Calaméo](https://www.calameo.com/read/00817762450b43c8e8769)

## Características

- Terminal principal fija que ocupa toda la pantalla, sin bordes, sin botón de cerrar.
- Ventanas emergentes (mpv, nuevas terminales) se ven **ENCIMA**.
- Soporte completo de ratón: seleccionar texto copia, click derecho pega.
- Atajos de teclado: `Ctrl+Alt+T`, `Alt+Tab`, `Win+x`, `Win+q`.
- Actualización desde GitHub: `xoniarch-update`.
- Instalación modular: `xoniarch-install`.
- Detección automática de hardware.

## Requisitos

| Requisito       | Mínimo             | Recomendado          |
|----------------|--------------------|----------------------|
| Procesador     | 64 bits (x86_64)   | Intel Core i3 o superior |
| RAM            | 1 GB               | 2 GB                 |
| Espacio en disco | 8 GB              | 10 GB                |
| Conexión a internet | Sí (para instalar) | Sí                   |

## 📥 Instalación

### Opción 1: Descargar ISO desde la web oficial (recomendado)

Visita [https://xoniarch.xonidu.com](https://xoniarch.xonidu.com) y descarga la última versión de la ISO. Allí encontrarás:
- La última ISO disponible para descargar.
- Historial de versiones anteriores con notas de lanzamiento.
- Enlaces a la documentación y al repositorio.

### Opción 2: Generar ISO propia (para desarrolladores)

```bash
git clone https://github.com/XONIDU/xoniarch.git
cd xoniarch
sudo ./generate-xoniarch.sh
```

### Opción 3: Grabar ISO en USB

```bash
# Identificar tu USB
lsblk

# Grabar la ISO (reemplazar sdX por tu dispositivo)
sudo dd if=xoniarch.iso of=/dev/sdX bs=4M status=progress
sync
```

### Opción 4: Instalar desde Arch existente

```bash
curl -sL https://raw.githubusercontent.com/XONIDU/xoniarch/main/install-xoniarch.sh | sudo bash
```

## Comandos del Sistema

| Comando | Descripción |
|---------|-------------|
| `xoniarch-menu` | Menú principal interactivo |
| `xoniarch-install` | Instalar herramientas XONI desde GitHub |
| `xoniarch-update` | Actualizar el sistema desde GitHub |
| `xoniarch-help` | Mostrar ayuda rápida |
| `xoniarch-detect-hardware` | Detectar e instalar controladores |

## Atajos de Teclado

| Tecla | Acción |
|-------|--------|
| `Ctrl+Alt+T` | Nueva terminal emergente |
| `Alt+Tab` | Cambiar entre ventanas |
| `Alt+F4` | Cerrar ventana actual |
| `Win+↑` | Maximizar ventana |
| `Win+x` | Abrir menú principal |
| `Win+q` | Cerrar sesión |

## Ratón

- Seleccionar texto → Copia automáticamente al portapapeles.
- Click derecho → Pega el texto copiado.

## Red

```bash
sudo nmtui
```

## Volumen

```bash
alsamixer
```

## Actualización del Sistema

```bash
sudo xoniarch-update
```

## Herramientas Disponibles

```bash
xoniarch-install xonitube    # Buscador y reproductor de YouTube
xoniarch-install xonigraf    # Graficador matemático
xoniarch-install xonichat    # Chat con IA (Gemini)
xoniarch-install xonimail    # Cliente de correo
xoniarch-install xonidip     # Generador de diplomas
xoniarch-install xoniconver  # Conversor de formatos
xoniarch-install xonidate    # Citas aleatorias
xoniarch-install xonimet     # Extractor de metadatos
xoniarch-install xoniweb     # Análisis de malware
```

## Estructura del Repositorio

```
xoniarch/
├── archiso/                 # Configuración para generar la ISO
├── config/                  # Archivos .txt de configuración
│   ├── packages.txt         # Lista de paquetes a instalar
│   ├── openbox-rc.txt       # Atajos de teclado
│   ├── openbox-autostart.txt # Programas al inicio
│   ├── Xresources.txt       # Configuración de terminal
│   ├── bashrc.txt           # Configuración de bash
│   ├── xinitrc.txt          # Inicio de X
│   ├── autologin.txt        # Auto-login
│   └── profile.txt          # Perfil de sistema
├── scripts/                 # Scripts ejecutables
├── generate-xoniarch.sh     # Generador de ISO
├── install-xoniarch.sh      # Instalador principal
└── README.md                # Este archivo
```

## Personalización

Edita los archivos `.txt` en `config/` para modificar:
- Paquetes a instalar.
- Atajos de teclado.
- Apariencia de la terminal.
- Mensajes de bienvenida.

## Solución de Problemas

### No se conecta WiFi

```bash
sudo systemctl restart NetworkManager
sudo nmtui
```

### No aparece el menú con Win+x

```bash
grep "W-x" ~/.config/openbox/rc.xml
```

### Error de espacio al generar ISO

```bash
sudo rm -rf ~/xoniarch-build
sudo ./generate-xoniarch.sh
```

## Hardware Probado

- VirtualBox / QEMU.
- PC con Intel Core i3/i5/i7.
- PC con AMD Ryzen.
- Hardware genérico de 64 bits.

## Créditos

- **Autor:** Darian Alberto Camacho Salas
- **Email:** xonidu@gmail.com
- **GitHub:** [@XONIDU](https://github.com/XONIDU)
- **Web:** [https://xonipage.xonidu.com/](https://xonipage.xonidu.com/)
- **Sitio de descargas:** [https://xoniarch.xonidu.com](https://xoniarch.xonidu.com)

