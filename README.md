## XONIARCH - Documentación Legal y Funcionamiento

### Autor
**Darian Alberto Camacho Salas**
- Email: xonidu@gmail.com
- GitHub: @XONIDU
- Web: https://xonipage.xonidu.com/

### Licencia
**Código abierto (Open Source)**
- Libre de modificar, adaptar y distribuir
- No incluye garantía
- El autor no se hace responsable del mal uso

---

## ¿Qué es XONIARCH?

XONIARCH es una distribución Linux basada en Arch Linux que transforma el sistema en un entorno de terminal gráfica fija, diseñada para hardware de 64 bits con recursos limitados.

---

## Estructura del Proyecto

```
xoniarch/
├── archiso/                 # Configuración para generar la ISO
│   ├── airootfs/           # Sistema base personalizado
│   ├── packages.x86_64     # Paquetes que se instalan en la ISO
│   ├── pacman.conf         # Repositorios de paquetes
│   └── profiledef.sh       # Configuración del perfil de la ISO
│
├── config/                  # Archivos .txt de configuración
│   ├── packages.txt        # Paquetes a instalar por xoniarch-install
│   ├── openbox-rc.txt      # Atajos de teclado y comportamiento
│   ├── openbox-autostart.txt # Programas que inician con Openbox
│   ├── Xresources.txt      # Configuración de la terminal (colores, fuente)
│   ├── bashrc.txt          # Configuración de bash (alias, prompt)
│   ├── xinitrc.txt         # Inicio de X (Openbox)
│   ├── autologin.txt       # Auto-login en consola
│   └── profile.txt         # Perfil de sistema (inicia X en tty1)
│
├── scripts/                 # Scripts ejecutables
│   ├── xoniarch-menu       # Menú principal interactivo
│   ├── xoniarch-install    # Instalador de herramientas XONI
│   ├── xoniarch-update     # Actualizador del sistema
│   ├── xoniarch-help       # Ayuda rápida
│   └── xoniarch-detect-hardware # Detección de controladores
│
├── generate-xoniarch.sh    # Generador de la ISO
├── install-xoniarch.sh     # Instalador principal (lee config/)
└── README.md               # Documentación
```

---

## Funcionamiento por Partes

### 1. `archiso/` - Generación de la ISO
- **`packages.x86_64`**: Paquetes que se incluyen en la ISO (git, networkmanager, etc.)
- **`pacman.conf`**: Repositorios de donde descargar paquetes
- **`profiledef.sh`**: Configuración del nombre y tipo de boot de la ISO
- **`airootfs/`**: Sistema base que se copia a la ISO (scripts, configuraciones)

### 2. `config/` - Configuración del Instalador
- **`packages.txt`**: Lista de paquetes que instalará `xoniarch-install` (openbox, rxvt-unicode, mpv, etc.)
- **`openbox-rc.txt`**: Define atajos de teclado (Win+x, Ctrl+Alt+T, Alt+Tab)
- **`openbox-autostart.txt`**: Inicia la terminal fija, nm-applet, picom
- **`Xresources.txt`**: Configura colores y copiar/pegar con ratón
- **`bashrc.txt`**: Aliases y prompt personalizado
- **`xinitrc.txt`**: Ejecuta `openbox-session` al iniciar X
- **`autologin.txt`**: Configura login automático en tty1
- **`profile.txt`**: Inicia `startx` automáticamente en tty1

### 3. `scripts/` - Comandos del Sistema
- **`xoniarch-menu`**: Menú interactivo con opciones (red, instalar, actualizar)
- **`xoniarch-install`**: Clona repositorio y ejecuta `install-xoniarch.sh`
- **`xoniarch-update`**: Actualiza el sistema desde GitHub
- **`xoniarch-help`**: Muestra ayuda rápida
- **`xoniarch-detect-hardware`**: Detecta GPU e instala controladores

### 4. `install-xoniarch.sh` - Instalador Principal
- Lee los archivos `.txt` de `config/`
- Instala paquetes con `pacman`
- Copia configuraciones a `~/.config/openbox/`
- Configura autologin y profile
- Instala scripts en `/usr/local/bin/`

### 5. `generate-xoniarch.sh` - Generador de ISO
- Copia `archiso/` a `~/xoniarch-build/`
- Ejecuta `mkarchiso` para crear la ISO
- Renombra la ISO a `xoniarch.iso`

---

## Flujo de Uso

### Para el Usuario Final:

1. **Generar ISO**:
   ```bash
   git clone https://github.com/XONIDU/xoniarch.git
   cd xoniarch
   sudo ./generate-xoniarch.sh
   ```

2. **Grabar ISO en USB**:
   ```bash
   sudo dd if=xoniarch.iso of=/dev/sdX bs=4M status=progress
   ```

3. **Bootear desde USB**:
   - Inicia sesión automáticamente (root)
   - Aparece el menú `xoniarch-menu`

4. **Conectar WiFi** (opción 1):
   ```bash
   sudo nmtui
   ```

5. **Instalar XONIARCH** (opción 2):
   - Clona repositorio `https://github.com/XONIDU/xoniarch`
   - Ejecuta `install-xoniarch.sh`
   - Instala todos los paquetes y configuraciones
   - Reinicia al finalizar

6. **Usar el sistema instalado**:
   - Terminal fija con Openbox
   - Atajos: `Win+x` (menú), `Ctrl+Alt+T` (nueva terminal)
   - Ratón: seleccionar copia, click derecho pega

---

## Para el Desarrollador

### Actualizar configuraciones:
1. Editar archivos `.txt` en `config/`
2. Subir cambios a GitHub
3. Los usuarios obtienen actualizaciones con `sudo xoniarch-update`

### Agregar herramientas XONI:
```bash
xoniarch-install xonitube
xoniarch-install xonigraf
xoniarch-install xonichat
xoniarch-install xonimail
```

### Reconstruir ISO después de cambios:
```bash
sudo rm -rf ~/xoniarch-build
sudo ./generate-xoniarch.sh
```

---

## Comandos Rápidos

| Comando | Función |
|---------|---------|
| `xoniarch-menu` | Menú principal |
| `xoniarch-install` | Instalar herramientas XONI |
| `xoniarch-update` | Actualizar sistema desde GitHub |
| `xoniarch-help` | Mostrar ayuda |
| `xoniarch-detect-hardware` | Detectar e instalar controladores |

---

## Atajos de Teclado (una vez instalado)

| Tecla | Acción |
|-------|--------|
| `Ctrl+Alt+T` | Nueva terminal emergente |
| `Alt+Tab` | Cambiar entre ventanas |
| `Alt+F4` | Cerrar ventana actual |
| `Win+↑` | Maximizar ventana |
| `Win+x` | Abrir menú principal |
| `Win+q` | Cerrar sesión |

---

## Licencia

Este proyecto es de código abierto. Siéntete libre de modificarlo y adaptarlo a tus necesidades.

**Autor:** Darian Alberto Camacho Salas  
**Email:** xonidu@gmail.com  
**GitHub:** @XONIDU
