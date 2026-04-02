# XONIARCH

by Darian Alberto Camacho Salas

## Descripcion

XONIARCH es una distribucion Linux especializada que transforma Arch Linux en un entorno de terminal grafica fija, disenada especificamente para hardware de 64 bits con recursos limitados.

Version actual: 1.0

## Caracteristicas

- Terminal principal fija que ocupa toda la pantalla, sin bordes, sin boton de cerrar
- Ventanas emergentes (mpv, nuevas terminales) se ven ENCIMA
- Soporte completo de raton: seleccionar texto copia, click derecho pega
- Atajos de teclado: Ctrl+Alt+T, Alt+Tab, Win+x, Win+q
- Actualizacion desde GitHub: xoniarch-update
- Instalacion modular: xoniarch-install
- Deteccion automatica de hardware

## Requisitos

- Procesador: 64 bits (x86_64)
- RAM: 1 GB (recomendado 2 GB)
- Espacio: 10 GB
- Conexion a internet

## Instalacion

### Opcion 1: Generar ISO propia

```bash
git clone https://github.com/XONIDU/xoniarch.git
cd xoniarch
sudo ./generate-xoniarch.sh
```

La ISO se generara como xoniarch.iso

### Opcion 2: Grabar ISO en USB

```bash
sudo dd if=xoniarch.iso of=/dev/sdX bs=4M status=progress
```

### Opcion 3: Instalar desde Arch existente

```bash
curl -sL https://raw.githubusercontent.com/XONIDU/xoniarch/main/install-xoniarch.sh | sudo bash
```

## Comandos

| Comando | Descripcion |
|---------|-------------|
| `xoniarch-menu` | Menu principal interactivo |
| `xoniarch-install` | Instalar herramientas XONI |
| `xoniarch-update` | Actualizar sistema desde GitHub |
| `xoniarch-help` | Mostrar ayuda |
| `xoniarch-detect-hardware` | Detectar e instalar controladores |

## Atajos de teclado

| Tecla | Accion |
|-------|--------|
| `Ctrl+Alt+T` | Nueva terminal emergente |
| `Alt+Tab` | Cambiar entre ventanas |
| `Alt+F4` | Cerrar ventana actual |
| `Win+↑` | Maximizar ventana |
| `Win+x` | Abrir menu principal |
| `Win+q` | Cerrar sesion |

## Raton

- Seleccionar texto → Copia automaticamente
- Click derecho → Pega el texto copiado

## Red

```bash
sudo nmtui
```

## Volumen

```bash
alsamixer
```

## Actualizacion del sistema

```bash
sudo xoniarch-update
```

## Herramientas disponibles

```bash
xoniarch-install xonitube    # Buscador y reproductor de YouTube
xoniarch-install xonigraf    # Graficador matematico
xoniarch-install xonichat    # Chat con IA (Gemini)
xoniarch-install xonimail    # Cliente de correo
xoniarch-install xonidip     # Generador de diplomas
xoniarch-install xoniconver  # Conversor de formatos
xoniarch-install xonidate    # Citas aleatorias
xoniarch-install xonimet     # Extractor de metadatos
xoniarch-install xoniweb     # Analisis de malware
```

## Estructura del repositorio

```
xoniarch/
├── archiso/                 # Configuracion de la ISO
├── config/                  # Archivos .txt de configuracion
│   ├── packages.txt         # Lista de paquetes
│   ├── openbox-rc.txt       # Atajos de teclado
│   ├── openbox-autostart.txt # Programas al inicio
│   ├── Xresources.txt       # Configuracion de terminal
│   ├── bashrc.txt           # Configuracion bash
│   ├── xinitrc.txt          # Inicio de X
│   ├── autologin.txt        # Auto-login
│   └── profile.txt          # Perfil de sistema
├── scripts/                 # Scripts ejecutables
├── generate-xoniarch.sh     # Generador de ISO
├── install-xoniarch.sh      # Instalador principal
└── README.md                # Este archivo
```

## Personalizacion

Edita los archivos `.txt` en `config/` para modificar:
- Paquetes a instalar
- Atajos de teclado
- Apariencia de la terminal
- Mensajes de bienvenida

## Solucion de problemas

### No se conecta WiFi

```bash
sudo systemctl restart NetworkManager
sudo nmtui
```

### No aparece el menu con Win+x

```bash
grep "W-x" ~/.config/openbox/rc.xml
```

### Error de espacio al generar ISO

```bash
sudo rm -rf ~/xoniarch-build
sudo ./generate-xoniarch.sh
```

## Hardware probado

- VirtualBox / QEMU
- PC con Intel Core i3/i5/i7
- PC con AMD Ryzen
- Hardware generico de 64 bits

## Creditos

- **Autor:** Darian Alberto Camacho Salas
- **Email:** xonidu@gmail.com
- **GitHub:** @XONIDU
- **Web:** https://xonipage.xonidu.com/

## Licencia

Codigo abierto. Libre de modificar y adaptar.

