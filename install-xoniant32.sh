#!/bin/bash
# install-xoniant32.sh – Terminal gráfica fija (herramientas en home)
# Autor: Darian Alberto Camacho Salas
# Repositorio: https://github.com/XONIDU/xoniant32
#
# Este script elimina escritorios y gestores de display,
# pero CONSERVA TODAS LAS DEPENDENCIAS GRÁFICAS.
# El sistema ARRANCA DIRECTAMENTE en una terminal maximizada
# que NO SE PUEDE CERRAR.
# Las herramientas XONI se instalan directamente en ~/ (ej: ~/xonitube)

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
echo "   XONIANT32 - TERMINAL GRÁFICA FIJA   "
echo "   by Darian Alberto Camacho Salas     "
echo "========================================"
echo "ADVERTENCIA: Este script ELIMINARÁ:"
echo "  - TODOS los escritorios completos"
echo "  - TODAS las aplicaciones gráficas pesadas"
echo "  - Gestores de display (lightdm, sddm, lxdm, slim, gdm3, xdm)"
echo "  - Barras de tareas, fondos, compositores"
echo "  - NetworkManager (usaremos connman nativo)"
echo "  - Scripts antiguos (xoniarch-*)"
echo ""
echo "CONSERVARÁ:"
echo "  - TODAS las dependencias gráficas (GTK, Qt, bibliotecas X, controladores)"
echo "  - Openbox (gestor de ventanas MÍNIMO)"
echo "  - Terminal fija (rxvt-unicode) - NO SE PUEDE CERRAR"
echo "  - ALSA para audio"
echo "  - Connman para WiFi (configurado)"
echo "  - mpv + yt-dlp (para xonitube)"
echo "  - Scripts XONI (xoni-install, xoni-update, xoni-help, xoni-menu)"
echo "  - Las herramientas XONI se instalarán DIRECTAMENTE en ~/ (ej: ~/xonitube)"
echo ""
read -p "¿Estás seguro? (escribe YES): " CONFIRM
[ "$CONFIRM" != "YES" ] && error_exit "Operación cancelada."

# ============================================
# 1. PURGA DE ESCRITORIOS
# ============================================
info "Purgando escritorios completos..."
apt purge -y xfce4* lxde* lxqt* mate-* cinnamon* gnome-* kde-* || true

info "Purgando gestores de ventanas adicionales..."
apt purge -y fluxbox icewm jwm dwm awesome i3* || true

info "Purgando aplicaciones gráficas pesadas..."
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
# 2. ELIMINAR RASTROS DE XONIARCH
# ============================================
info "Eliminando rastros de xoniarch..."
rm -f /usr/local/bin/xoniarch-* 2>/dev/null || true
rm -f /usr/local/bin/xoniarch 2>/dev/null || true
rm -f /usr/local/bin/xoniarch32 2>/dev/null || true
rm -rf /opt/xoniarch 2>/dev/null || true
rm -rf /opt/xoniarch32 2>/dev/null || true

# ============================================
# 3. AUTOLIMPIEZA
# ============================================
info "Eliminando dependencias no usadas..."
apt autoremove --purge -y

info "Limpiando caché..."
apt clean
apt autoclean

# ============================================
# 4. INSTALAR PAQUETES MÍNIMOS
# ============================================
info "Actualizando repositorios..."
apt update || warn "Error en apt update, continuando..."

info "Instalando paquetes base..."
apt install -y git curl wget htop nano alsa-utils connman

# Entorno gráfico mínimo (Openbox + terminal)
apt install -y xorg openbox rxvt-unicode

# Herramientas multimedia
apt install -y mpv yt-dlp ffmpeg

# Firmware WiFi
apt install -y firmware-atheros firmware-iwlwifi firmware-realtek || warn "Algún firmware WiFi no se pudo instalar."

# Temas GTK mínimos
apt install -y --fix-missing adwaita-icon-theme || warn "Temas GTK opcionales no instalados."

# ============================================
# 5. CONFIGURAR CONNMAN
# ============================================
info "Configurando connman para WiFi estable..."
mkdir -p /etc/connman
cat > /etc/connman/main.conf << 'EOF'
[General]
PreferredTechnologies = wifi,ethernet
AllowHostnames = true
SingleConnectedTechnology = false
AutoConnect = true
NetworkInterfaceBlacklist = vmnet,vboxnet,virbr,ifb
EOF

systemctl restart connman || sv restart connman || true

# ============================================
# 6. CONFIGURAR MPV
# ============================================
info "Configurando mpv..."
mkdir -p /etc/mpv
cat > /etc/mpv/mpv.conf << 'EOF'
vo=x11
ao=alsa
cache=yes
cache-secs=30
profile=fast
msg-level=all=error
x11-bypass-compositor=yes
EOF

TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME="/home/$TARGET_USER"

mkdir -p "$USER_HOME/.config/mpv"
cp /etc/mpv/mpv.conf "$USER_HOME/.config/mpv/"
chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config/mpv"

# ============================================
# 7. CONFIGURAR OPENBOX (TERMINAL FIJA)
# ============================================
info "Configurando Openbox con terminal fija..."

mkdir -p "$USER_HOME/.config/openbox"

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

cat > "$USER_HOME/.config/openbox/autostart" << 'EOF'
# TERMINAL PRINCIPAL (NO SE PUEDE CERRAR)
urxvt -title "principal" &
EOF

cat > "$USER_HOME/.xinitrc" << 'EOF'
#!/bin/sh
exec openbox-session
EOF
chmod +x "$USER_HOME/.xinitrc"

# ============================================
# 8. AUTO-LOGIN EN TTY1 + INICIO DE X
# ============================================
info "Configurando auto-login e inicio automático de X..."

# Auto-login en tty1
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $TARGET_USER --noclear %I 38400 linux
EOF

# Iniciar X automáticamente en .bashrc
cat >> "$USER_HOME/.bashrc" << 'EOF'

# Iniciar X automáticamente en tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
    exit 0
fi
EOF

# Mensaje de bienvenida
cat >> "$USER_HOME/.bashrc" << 'EOF'

# Mensaje de bienvenida
echo "========================================"
echo "   XONIANT32 - by Darian Alberto Camacho Salas"
echo "========================================"
echo "Comandos útiles:"
echo "  xoni-help     : Muestra esta ayuda"
echo "  xoni-menu     : Menú interactivo"
echo "  xoni-update   : Actualiza xoniant32"
echo "  xoni-install  : Instala herramientas XONI directamente en ~/"
echo "  sudo connmanctl : Configura la red WiFi"
echo "========================================"
EOF

chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config" "$USER_HOME/.xinitrc" "$USER_HOME/.bashrc"

# ============================================
# 9. CREAR SCRIPTS XONI (herramientas en home)
# ============================================
info "Creando scripts XONI (herramientas directamente en ~/)..."

cat > /usr/local/bin/xoni-install << 'EOF'
#!/bin/bash
# xoni-install – Instalador de herramientas XONI directamente en ~/
# Autor: Darian Alberto Camacho Salas

REPO_BASE="https://github.com/XONIDU"
cd "$HOME"

if [ -n "$1" ]; then
    TOOL="$1"
    echo "Instalando $TOOL desde $REPO_BASE/$TOOL.git en ~/$TOOL ..."
    
    if [ -d "$TOOL" ]; then
        echo "Actualizando $TOOL existente..."
        cd "$TOOL" && git pull && cd ..
    else
        git clone "$REPO_BASE/$TOOL.git"
    fi
    
    # Buscar el archivo principal y crear enlace simbólico en /usr/local/bin
    if [ -f "$TOOL/start.py" ]; then
        echo "Creando enlace simbólico en /usr/local/bin/$TOOL (necesita sudo)"
        sudo ln -sf "$HOME/$TOOL/start.py" "/usr/local/bin/$TOOL"
        sudo chmod +x "/usr/local/bin/$TOOL"
        echo "[OK] $TOOL disponible como comando global (enlace a ~/$TOOL/start.py)"
    elif [ -f "$TOOL/$TOOL.py" ]; then
        sudo ln -sf "$HOME/$TOOL/$TOOL.py" "/usr/local/bin/$TOOL"
        sudo chmod +x "/usr/local/bin/$TOOL"
        echo "[OK] $TOOL disponible como comando global (enlace a ~/$TOOL/$TOOL.py)"
    elif [ -f "$TOOL/$TOOL.sh" ]; then
        sudo ln -sf "$HOME/$TOOL/$TOOL.sh" "/usr/local/bin/$TOOL"
        sudo chmod +x "/usr/local/bin/$TOOL"
        echo "[OK] $TOOL disponible como comando global (enlace a ~/$TOOL/$TOOL.sh)"
    else
        echo "[AVISO] No se encontró archivo principal, pero el repositorio está en ~/$TOOL"
    fi

else
    echo "Herramientas disponibles en XONIDU:"
    echo "  xonitube, xonigraf, xonichat, xonimail, xonicar, xoniclus, xoniconver, xonidate, xonidal, xonidip, xoniencript, xonihelp, xonilab, xoniclient, xoniserver, xoniterm, xonifs, xonigrep, xonisearch, xonicrypt, xonidecode, xonicron, xonisync"
    echo ""
    read -p "Herramienta a instalar: " TOOL
    if [ -n "$TOOL" ]; then
        exec "$0" "$TOOL"
    else
        echo "No se especificó ninguna herramienta."
    fi
fi
EOF

cat > /usr/local/bin/xoni-update << 'EOF'
#!/bin/bash
# xoni-update – Actualiza xoniant32 y las herramientas XONI

# Actualizar scripts del sistema
REPO="https://github.com/XONIDU/xoniant32.git"
DIR="/opt/xoniant32"
echo "Actualizando scripts de xoniant32..."
if [ ! -d "$DIR" ]; then
    sudo git clone "$REPO" "$DIR"
else
    cd "$DIR" && sudo git pull
fi

if [ -d "$DIR/scripts" ]; then
    sudo cp -v "$DIR/scripts"/xoni-* /usr/local/bin/ 2>/dev/null || true
fi

sudo rm -f /usr/local/bin/xoniarch-* 2>/dev/null || true
sudo chmod +x /usr/local/bin/xoni-* 2>/dev/null || true

# Actualizar herramientas en ~/
echo ""
echo "Actualizando herramientas en ~/ ..."
cd "$HOME"
for tool in */; do
    toolname="${tool%/}"
    if [ -d "$toolname" ] && [ -d "$toolname/.git" ]; then
        echo "Actualizando $toolname..."
        cd "$toolname" && git pull && cd "$HOME"
    fi
done

echo "[OK] xoniant32 actualizado"
EOF

cat > /usr/local/bin/xoni-help << 'EOF'
#!/bin/bash
cat << 'HELP'
========================================
   XONIANT32 - AYUDA
========================================
COMANDOS:
  xoni-help                    : Muestra esta ayuda
  xoni-menu                    : Menú interactivo
  xoni-update                  : Actualiza scripts y herramientas
  xoni-install <herramienta>   : Instala herramientas XONI en ~/

HERRAMIENTAS DISPONIBLES:
  xonitube, xonigraf, xonichat, xonimail, xonicar, xoniclus, xoniconver,
  xonidate, xonidal, xonidip, xoniencript, xonihelp, xonilab, xoniclient,
  xoniserver, xoniterm, xonifs, xonigrep, xonisearch, xonicrypt,
  xonidecode, xonicron, xonisync

ATAJOS:
  Win + x   : Menú principal
  Win + t   : Nueva terminal
  Win + h   : Ayuda
  Win + u   : Actualizar
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
# 10. ACTUALIZAR MOTD
# ============================================
cat > /etc/motd << 'EOF'
========================================
   XONIANT32 - by Darian Alberto Camacho Salas
========================================
Comandos útiles:
  xoni-help     : Muestra esta ayuda
  xoni-menu     : Menú interactivo
  xoni-update   : Actualiza scripts y herramientas
  xoni-install  : Instala herramientas XONI directamente en ~/
  sudo connmanctl : Configura la red WiFi

El sistema ARRANCA DIRECTAMENTE EN MODO GRÁFICO
La terminal principal es FIJA (no se puede cerrar)

Repositorio: https://github.com/XONIDU/xoniant32
========================================
EOF

# ============================================
# 11. FINALIZACIÓN
# ============================================
echo "========================================"
echo "   INSTALACIÓN COMPLETADA               "
echo "========================================"
echo ""
echo "antiX ha sido transformado en xoniant32"
echo ""
echo "Características:"
echo "  - Terminal gráfica fija (NO se puede cerrar)"
echo "  - TODAS las dependencias gráficas conservadas"
echo "  - Openbox como gestor de ventanas mínimo"
echo "  - ALSA + Connman + mpv listos"
echo "  - Scripts XONI instalados"
echo "  - HERRAMIENTAS XONI SE INSTALAN DIRECTAMENTE EN ~/"
echo ""
echo "Para instalar xonitube: xoni-install xonitube"
echo ""
echo "Reinicia: sudo reboot"
echo ""
echo "Usuario: $TARGET_USER"
echo ""
echo "¡Disfruta xoniant32!"