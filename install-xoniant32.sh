#!/bin/bash
# xoniant32 – Script de purga ULTRA minimalista
# Autor: Darian Alberto Camacho Salas
# Repositorio: https://github.com/XONIDU/xoniant32
#
# Este script elimina TODO lo innecesario de una instalación antiX existente
# y deja SOLO:
#   - Openbox (ventanas mínimas)
#   - Una terminal fija que ocupa toda la pantalla (rxvt-unicode)
#   - Audio (ALSA)
#   - Connman para WiFi (nativo de antiX)
#   - Scripts XONI (xoni-install, xoni-update, xoni-help, xoni-menu)
#   - NADA MÁS (ni tint2, ni feh, ni picom, ni escritorio, ni gestores de display)

set -euo pipefail
trap 'echo -e "\033[0;31m[ERROR] Falló en la línea $LINENO\033[0m" >&2' ERR

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

error_exit() { echo -e "${RED}[ERROR] $1${NC}" >&2; exit 1; }
info()  { echo -e "${GREEN}[INFO] $1${NC}"; }
warn()  { echo -e "${YELLOW}[AVISO] $1${NC}"; }

# Verificar root
if [ "$EUID" -ne 0 ]; then 
    error_exit "Este script debe ejecutarse como root (sudo)."
fi

# Verificar antiX
if [ ! -f /etc/antix-version ]; then
    error_exit "Este script debe ejecutarse en antiX Linux."
fi

clear
echo "========================================"
echo "   XONIANT32 - PURGA ULTRA MINIMALISTA "
echo "========================================"
echo "ADVERTENCIA: Este script ELIMINARÁ:"
echo "  - TODOS los escritorios completos"
echo "  - TODAS las aplicaciones gráficas"
echo "  - TODOS los gestores de display"
echo "  - Barras de tareas, fondos, compositores"
echo "  - NetworkManager (para usar connman)"
echo ""
echo "SOLO DEJARÁ:"
echo "  - Openbox (mínimo)"
echo "  - Terminal fija (rxvt-unicode)"
echo "  - ALSA para audio"
echo "  - Connman para WiFi"
echo "  - Scripts XONI"
echo ""
read -p "¿Estás seguro? (escribe YES): " CONFIRM
[ "$CONFIRM" != "YES" ] && error_exit "Operación cancelada."

# ============================================
# 1. PURGA MASIVA
# ============================================
info "Purgando escritorios completos..."
apt purge -y xfce4* lxde* lxqt* mate-* cinnamon* gnome-* kde-* || true

info "Purgando gestores de ventanas adicionales..."
apt purge -y fluxbox icewm jwm dwm awesome i3* || true

info "Purgando aplicaciones gráficas..."
apt purge -y firefox* chromium* seamonkey* libreoffice* abiword gnumeric || true
apt purge -y vlc smplayer audacious parole gimp inkscape blender shotwell || true
apt purge -y thunderbird* claws-mail* sylpheed* || true
apt purge -y gnome-games* aisleriot solitaire || true

info "Purgando gestores de display..."
apt purge -y lightdm sddm lxdm slim gdm3 xdm || true

info "Purgando NetworkManager y nmtui..."
apt purge -y network-manager* nmtui || true

info "Purgando herramientas de escritorio (tint2, feh, picom, nitrogen)..."
apt purge -y tint2 feh picom nitrogen || true

info "Purgando herramientas de desarrollo (opcional)..."
apt purge -y build-essential gcc g++ make cmake || true

info "Purgando documentación..."
apt purge -y man-db manpages info || true

# ============================================
# 2. AUTOLIMPIEZA
# ============================================
info "Eliminando dependencias no usadas..."
apt autoremove --purge -y

info "Limpiando caché..."
apt clean
apt autoclean

# ============================================
# 3. INSTALAR PAQUETES MÍNIMOS
# ============================================
info "Instalando paquetes mínimos..."

# Base
apt install -y git curl wget htop nano

# Audio (ALSA puro)
apt install -y alsa-utils

# Xorg mínimo
apt install -y xorg xserver-xorg-core xserver-xorg-input-all xserver-xorg-video-fbdev

# Openbox y terminal (solo lo necesario)
apt install -y openbox rxvt-unicode

# Connman (WiFi nativo)
apt install -y connman

# ============================================
# 4. CONFIGURAR OPENBOX (TERMINAL FIJA)
# ============================================
info "Configurando Openbox con terminal fija..."

# Determinar usuario objetivo (el que ejecuta el script con sudo)
TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME="/home/$TARGET_USER"

mkdir -p "$USER_HOME/.config/openbox"

# Configuración de Openbox - TERMINAL FIJA sin decoraciones
cat > "$USER_HOME/.config/openbox/rc.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config>
  <applications>
    <application class="URxvt" name="urxvt" title="principal">
      <decor>no</decor>
      <maximized>yes</maximized>
      <focus>yes</focus>
      <desktop>all</desktop>
      <layer>above</layer>
    </application>
  </applications>
  <menu><file>~/.config/openbox/menu.xml</file></menu>
  <keyboard>
    <keybind key="W-x"><action name="Execute"><command>xoni-menu</command></action></keybind>
    <keybind key="W-t"><action name="Execute"><command>urxvt</command></action></keybind>
    <keybind key="W-h"><action name="Execute"><command>xoni-help</command></action></keybind>
    <keybind key="W-u"><action name="Execute"><command>xoni-update</command></action></keybind>
    <keybind key="W-q"><action name="Exit"/></keybind>
  </keyboard>
</openbox_config>
EOF

# Menú minimalista
cat > "$USER_HOME/.config/openbox/menu.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<openbox_menu>
  <menu id="root-menu" label="Xoniant32">
    <item label="Nueva terminal"><action name="Execute"><command>urxvt</command></action></item>
    <item label="Instalar herramienta XONI"><action name="Execute"><command>urxvt -e xoni-install</command></action></item>
    <item label="Configurar red (connman)"><action name="Execute"><command>urxvt -e sudo connmanctl</command></action></item>
    <item label="Monitor sistema"><action name="Execute"><command>urxvt -e htop</command></action></item>
    <item label="Actualizar xoniant32"><action name="Execute"><command>urxvt -e xoni-update</command></action></item>
    <item label="Ayuda"><action name="Execute"><command>urxvt -e xoni-help</command></action></item>
    <item label="Cerrar sesión"><action name="Exit"/></item>
  </menu>
</openbox_menu>
EOF

# Autostart - SOLO la terminal principal (sin nada más)
cat > "$USER_HOME/.config/openbox/autostart" << 'EOF'
# TERMINAL PRINCIPAL (NO SE PUEDE CERRAR)
urxvt -title "principal" &
EOF

# .xinitrc
cat > "$USER_HOME/.xinitrc" << 'EOF'
#!/bin/sh
exec openbox-session
EOF
chmod +x "$USER_HOME/.xinitrc"

# Auto-login en tty1 (iniciar X automáticamente al hacer login)
cat >> "$USER_HOME/.bashrc" << 'EOF'

# Iniciar X automáticamente en tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
fi
EOF

chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config" "$USER_HOME/.xinitrc" "$USER_HOME/.bashrc"

# ============================================
# 5. CONFIGURAR CONNMAN (WiFi)
# ============================================
info "Configurando Connman..."

# Habilitar connman en runit (sistema de inicio de antiX)
if [ -d /etc/sv/connman ]; then
    ln -sf /etc/sv/connman /etc/service/connman
else
    # Crear servicio runit si no existe
    mkdir -p /etc/sv/connman
    cat > /etc/sv/connman/run << 'EOF'
#!/bin/bash
exec chpst -u root /usr/sbin/connmand -n
EOF
    chmod +x /etc/sv/connman/run
    ln -s /etc/sv/connman /etc/service/connman
fi

# Archivo de ayuda para WiFi en el home del usuario
cat > "$USER_HOME/.wifi-help" << 'EOF'
========================================
   CONECTARSE A WIFI CON CONNMAN
========================================
Comando: sudo connmanctl

Dentro de connmanctl:
  agent on                  # Activar agente
  enable wifi               # Habilitar WiFi
  scan wifi                 # Escanear redes
  services                  # Listar redes
  connect wifi_nombre       # Conectar (usa TAB para autocompletar)
  quit                      # Salir

Ejemplo:
  $ sudo connmanctl
  connmanctl> agent on
  connmanctl> enable wifi
  connmanctl> scan wifi
  connmanctl> services
  connmanctl> connect wifi_MiRed_managed_psk
  connmanctl> quit
EOF
chown "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.wifi-help"

# ============================================
# 6. CREAR SCRIPTS XONI
# ============================================
info "Creando scripts XONI..."

mkdir -p /usr/local/bin

cat > /usr/local/bin/xoni-install << 'EOF'
#!/bin/bash
REPO_BASE="https://github.com/XONIDU"
DIR="/opt/xoni"
[ ! -d "$DIR" ] && mkdir -p "$DIR"
cd "$DIR"
TOOL="${1:-}"
if [ -z "$TOOL" ]; then
    read -p "Herramienta a instalar (ej: xonitube): " TOOL
fi
if [ -d "$TOOL" ]; then
    cd "$TOOL" && git pull
else
    git clone "$REPO_BASE/$TOOL.git"
fi
find "$TOOL" -name "*.py" -o -name "*.sh" -exec chmod +x {} \;
echo "[OK] $TOOL instalado"
EOF

cat > /usr/local/bin/xoni-update << 'EOF'
#!/bin/bash
REPO="https://github.com/XONIDU/xoniant32.git"
DIR="/opt/xoniant32"
if [ ! -d "$DIR" ]; then
    git clone "$REPO" "$DIR"
else
    cd "$DIR" && git pull
fi
# Sincronizar scripts y configuraciones
rsync -av --chown=root:root "$DIR/rootfs/" / 2>/dev/null || true
echo "[OK] xoniant32 actualizado desde GitHub"
EOF

cat > /usr/local/bin/xoni-help << 'EOF'
#!/bin/bash
cat << 'HELP'
========================================
   XONIANT32 - AYUDA
========================================
COMANDOS:
  xoni-install <herramienta>  : Instalar desde GitHub
  xoni-update                 : Actualizar xoniant32
  xoni-menu                   : Menú interactivo
  sudo connmanctl             : Configurar WiFi
  alsamixer                   : Ajustar volumen
  speaker-test                : Probar audio
  htop                        : Monitor del sistema

ATAJOS:
  Win + x   : Menú principal
  Win + t   : Nueva terminal
  Win + h   : Ayuda
  Win + u   : Actualizar sistema
  Win + q   : Cerrar sesión

El sistema ARRANCA DIRECTAMENTE EN MODO GRÁFICO
La terminal principal es FIJA (no se puede cerrar)

REPOSITORIO: https://github.com/XONIDU/xoniant32
HELP
EOF

cat > /usr/local/bin/xoni-menu << 'EOF'
#!/bin/bash
while true; do
    clear
    echo "========================================"
    echo "      XONIANT32 - MENÚ PRINCIPAL"
    echo "========================================"
    echo "1) Nueva terminal"
    echo "2) Instalar herramienta XONI"
    echo "3) Configurar red (connman)"
    echo "4) Monitor del sistema (htop)"
    echo "5) Actualizar xoniant32"
    echo "6) Ayuda"
    echo "7) Cerrar sesión"
    echo ""
    read -p "Opción [1-7]: " opt
    case $opt in
        1) urxvt ;;
        2) urxvt -e xoni-install ; read -p "Presiona Enter..." ;;
        3) urxvt -e sudo connmanctl ;;
        4) urxvt -e htop ;;
        5) urxvt -e xoni-update ; read -p "Presiona Enter..." ;;
        6) xoni-help ; read -p "Presiona Enter..." ;;
        7) openbox --exit ;;
        *) echo "Opción inválida"; sleep 2 ;;
    esac
done
EOF

chmod +x /usr/local/bin/xoni-*

# ============================================
# 7. ACTUALIZAR MENSAJE DE BIENVENIDA (MOTD)
# ============================================
cat > /etc/motd << 'EOF'
========================================
   XONIANT32 - by Darian Alberto Camacho Salas
========================================
Comandos útiles:
  xoni-help     : Muestra esta ayuda
  xoni-menu     : Menú interactivo
  xoni-update   : Actualiza xoniant32 desde GitHub
  xoni-install  : Instala herramientas XONI
  sudo connmanctl : Configura la red WiFi

El sistema arranca directamente en modo gráfico.
La terminal principal es fija (no se puede cerrar).

Repositorio: https://github.com/XONIDU/xoniant32
========================================
EOF

# ============================================
# 8. FINALIZACIÓN
# ============================================
echo "========================================"
echo "   PURGA COMPLETADA                     "
echo "========================================"
echo ""
echo "antiX ha sido transformado en xoniant32"
echo ""
echo "SOLO QUEDA:"
echo "  - Openbox (mínimo)"
echo "  - Terminal fija (rxvt-unicode)"
echo "  - ALSA para audio"
echo "  - Connman para WiFi"
echo "  - Scripts XONI"
echo ""
echo "NO HAY:"
echo "  - Escritorios"
echo "  - Barras de tareas"
echo "  - Fondos de pantalla"
echo "  - Gestores de display"
echo ""
echo "WiFi: cat ~/.wifi-help"
echo ""
echo "Reinicia el sistema para aplicar los cambios."
echo ""
echo "Usuario: $TARGET_USER (contraseña sin cambios)"
echo ""
echo "¡Disfruta xoniant32!"
