#!/bin/bash
# install-xoniant32.sh – Instalador completo de xoniant32
# Autor: Darian Alberto Camacho Salas
# Repositorio: https://github.com/XONIDU/xoniant32
#
# Este script transforma una instalación existente de antiX
# en xoniant32, eliminando lo innecesario y dejando solo:
#   - Openbox con terminal fija
#   - ALSA para audio
#   - Connman para WiFi
#   - Scripts XONI (xoni-install, xoni-update, xoni-help, xoni-menu)
#   - Herramientas desde XONIDU: xonitube, xonigraf, xonichat, xonimail
#   - Sin rastros de xoniarch

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
echo "   XONIANT32 - INSTALADOR COMPLETO     "
echo "   by Darian Alberto Camacho Salas     "
echo "========================================"
echo "ADVERTENCIA: Este script ELIMINARÁ:"
echo "  - TODOS los escritorios completos"
echo "  - TODAS las aplicaciones gráficas pesadas"
echo "  - TODOS los gestores de display"
echo "  - Barras de tareas, fondos, compositores"
echo "  - NetworkManager (usaremos connman nativo)"
echo "  - Scripts antiguos (xoniarch-*)"
echo ""
echo "CONSERVARÁ:"
echo "  - Openbox con terminal fija"
echo "  - ALSA para audio"
echo "  - Connman para WiFi"
echo "  - Scripts XONI (xoni-install, xoni-update, xoni-help, xoni-menu)"
echo "  - Herramientas desde XONIDU: xonitube, xonigraf, xonichat, xonimail"
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

info "Instalando paquetes mínimos..."
apt install -y git curl wget htop nano alsa-utils xorg openbox rxvt-unicode connman

# Temas GTK (opcional para que las apps gráficas se vean bien)
apt install -y --fix-missing adwaita-icon-theme gnome-themes-extra || warn "Temas GTK no instalados, pero el sistema funcionará."

# ============================================
# 5. CONFIGURAR OPENBOX (TERMINAL FIJA)
# ============================================
info "Configurando Openbox con terminal fija..."

TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME="/home/$TARGET_USER"

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

# Auto-login en tty1
cat >> "$USER_HOME/.bashrc" << 'EOF'

# Iniciar X automáticamente en tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
fi
EOF

# Mensaje de bienvenida
cat >> "$USER_HOME/.bashrc" << 'EOF'

# Mensaje de bienvenida de Xoniant32
echo "========================================"
echo "   XONIANT32 by Darian Alberto Camacho Salas"
echo "========================================"
echo "Comandos útiles:"
echo "  xoni-help     : Muestra esta ayuda"
echo "  xoni-menu     : Menú interactivo"
echo "  xoni-update   : Actualiza xoniant32 desde GitHub"
echo "  xoni-install  : Instala herramientas XONI adicionales"
echo "  sudo connmanctl : Configura la red WiFi"
echo "  xonitube      : Buscador de YouTube (desde XONIDU)"
echo "  xonigraf      : Graficador matemático (desde XONIDU)"
echo "  xonichat      : Chat con IA (desde XONIDU)"
echo "  xonimail      : Cliente de correo (desde XONIDU)"
echo "========================================"
EOF

chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config" "$USER_HOME/.xinitrc" "$USER_HOME/.bashrc"

# ============================================
# 6. CREAR DIRECTORIO PARA HERRAMIENTAS XONI
# ============================================
mkdir -p /opt/xoni
chown -R "$TARGET_USER":"$TARGET_USER" /opt/xoni 2>/dev/null || true

# ============================================
# 7. INSTALAR XONITUBE DESDE XONIDU
# ============================================
info "Instalando xonitube desde XONIDU..."
cd /opt/xoni
if [ ! -d "xonitube" ]; then
    sudo -u "$TARGET_USER" git clone https://github.com/XONIDU/xonitube.git
else
    sudo -u "$TARGET_USER" git -C xonitube pull
fi

if [ -f "xonitube/xonitube.py" ]; then
    cp xonitube/xonitube.py /usr/local/bin/xonitube
    chmod +x /usr/local/bin/xonitube
    info "xonitube instalado correctamente."
else
    warn "No se encontró el archivo principal de xonitube."
fi

# ============================================
# 8. INSTALAR XONIGRAF DESDE XONIDU
# ============================================
info "Instalando xonigraf desde XONIDU..."
cd /opt/xoni
if [ ! -d "xonigraf" ]; then
    sudo -u "$TARGET_USER" git clone https://github.com/XONIDU/xonigraf.git
else
    sudo -u "$TARGET_USER" git -C xonigraf pull
fi

if [ -f "xonigraf/xonigraf.py" ]; then
    cp xonigraf/xonigraf.py /usr/local/bin/xonigraf
    chmod +x /usr/local/bin/xonigraf
    info "xonigraf instalado correctamente."
else
    warn "No se encontró el archivo principal de xonigraf."
fi

# ============================================
# 9. INSTALAR XONICHAT DESDE XONIDU
# ============================================
info "Instalando xonichat desde XONIDU..."
cd /opt/xoni
if [ ! -d "xonichat" ]; then
    sudo -u "$TARGET_USER" git clone https://github.com/XONIDU/xonichat.git
else
    sudo -u "$TARGET_USER" git -C xonichat pull
fi

if [ -f "xonichat/xonichat.py" ]; then
    cp xonichat/xonichat.py /usr/local/bin/xonichat
    chmod +x /usr/local/bin/xonichat
    info "xonichat instalado correctamente."
else
    warn "No se encontró el archivo principal de xonichat."
fi

# ============================================
# 10. INSTALAR XONIMAIL DESDE XONIDU
# ============================================
info "Instalando xonimail desde XONIDU..."
cd /opt/xoni
if [ ! -d "xonimail" ]; then
    sudo -u "$TARGET_USER" git clone https://github.com/XONIDU/xonimail.git
else
    sudo -u "$TARGET_USER" git -C xonimail pull
fi

if [ -f "xonimail/xonimail.py" ]; then
    cp xonimail/xonimail.py /usr/local/bin/xonimail
    chmod +x /usr/local/bin/xonimail
    info "xonimail instalado correctamente."
else
    warn "No se encontró el archivo principal de xonimail."
fi

# ============================================
# 11. CREAR SCRIPTS XONI PRINCIPALES
# ============================================
info "Creando scripts XONI principales..."

cat > /usr/local/bin/xoni-install << 'EOF'
#!/bin/bash
# xoni-install – Instalador de herramientas XONI desde GitHub
# Autor: Darian Alberto Camacho Salas

REPO_BASE="https://github.com/XONIDU"
DIR="/opt/xoni"
[ ! -d "$DIR" ] && mkdir -p "$DIR"
cd "$DIR"
TOOL="${1:-}"
if [ -z "$TOOL" ]; then
    echo "Herramientas disponibles: xonitube, xonigraf, xonichat, xonimail, xonicar, xoniclus, xoniconver, xonidate, xonidal, xonidip, xoniencript, xonihelp, xonilab, xoniclient, xoniserver, xoniterm, xonifs, xonigrep, xonisearch, xonicrypt, xonidecode, xonicron, xonisync"
    read -p "Herramienta a instalar: " TOOL
fi
if [ -d "$TOOL" ]; then
    cd "$TOOL" && git pull && cd ..
else
    git clone "$REPO_BASE/$TOOL.git"
fi
if [ -f "$TOOL/$TOOL.py" ]; then
    cp "$TOOL/$TOOL.py" "/usr/local/bin/$TOOL"
    chmod +x "/usr/local/bin/$TOOL"
    echo "[OK] $TOOL instalado en /usr/local/bin/$TOOL"
elif [ -f "$TOOL/$TOOL.sh" ]; then
    cp "$TOOL/$TOOL.sh" "/usr/local/bin/$TOOL"
    chmod +x "/usr/local/bin/$TOOL"
    echo "[OK] $TOOL instalado en /usr/local/bin/$TOOL"
else
    echo "[AVISO] No se encontró un archivo principal, pero el repositorio se clonó en /opt/xoni/$TOOL"
fi
EOF

cat > /usr/local/bin/xoni-update << 'EOF'
#!/bin/bash
# xoni-update – Actualiza xoniant32 y las herramientas XONI desde GitHub
# Autor: Darian Alberto Camacho Salas

REPO="https://github.com/XONIDU/xoniant32.git"
DIR="/opt/xoniant32"

echo "Actualizando xoniant32 desde GitHub..."
if [ ! -d "$DIR" ]; then
    sudo git clone "$REPO" "$DIR"
else
    cd "$DIR" && sudo git pull
fi

# Actualizar scripts principales si existen
if [ -d "$DIR/scripts" ]; then
    sudo cp -v "$DIR/scripts"/xoni-* /usr/local/bin/ 2>/dev/null || true
fi

# Eliminar cualquier rastro de xoniarch
sudo rm -f /usr/local/bin/xoniarch-* 2>/dev/null || true
sudo rm -f /usr/local/bin/xoniarch 2>/dev/null || true

# Asegurar permisos
sudo chmod +x /usr/local/bin/xoni-* 2>/dev/null || true

# Actualizar herramientas instaladas en /opt/xoni
if [ -d /opt/xoni ]; then
    cd /opt/xoni
    for tool in */; do
        if [ -d "$tool" ]; then
            echo "Actualizando ${tool%/}..."
            cd "$tool" && git pull && cd ..
        fi
    done
fi

echo "[OK] xoniant32 actualizado correctamente"
EOF

cat > /usr/local/bin/xoni-help << 'EOF'
#!/bin/bash
# xoni-help – Muestra ayuda de xoniant32
# Autor: Darian Alberto Camacho Salas

cat << 'HELP'
========================================
   XONIANT32 - AYUDA
========================================
COMANDOS PRINCIPALES:
  xoni-help                    : Muestra esta ayuda
  xoni-menu                    : Menú interactivo
  xoni-update                   : Actualiza xoniant32 y herramientas
  xoni-install <herramienta>   : Instala herramientas XONI adicionales

HERRAMIENTAS XONI INSTALADAS (desde XONIDU):
  xonitube    : Buscador y reproductor de YouTube
  xonigraf    : Graficador matemático
  xonichat    : Chat con IA (Gemini)
  xonimail    : Cliente de correo desde terminal

OTRAS HERRAMIENTAS DISPONIBLES:
  xonicar, xoniclus, xoniconver, xonidate, xonidal, xonidip, xoniencript
  xonihelp, xonilab, xoniclient, xoniserver, xoniterm, xonifs, xonigrep
  xonisearch, xonicrypt, xonidecode, xonicron, xonisync

ATAJOS DE TECLADO (en Openbox):
  Win + x   : Menú principal
  Win + t   : Nueva terminal
  Win + h   : Ayuda
  Win + u   : Actualizar sistema
  Win + q   : Cerrar sesión

El sistema arranca directamente en modo gráfico.
La terminal principal es fija (no se puede cerrar).

REPOSITORIO: https://github.com/XONIDU/xoniant32
========================================
HELP
EOF

cat > /usr/local/bin/xoni-menu << 'EOF'
#!/bin/bash
# xoni-menu – Menú interactivo de xoniant32
# Autor: Darian Alberto Camacho Salas

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
# 12. ACTUALIZAR MOTD
# ============================================
cat > /etc/motd << 'EOF'
========================================
   XONIANT32 - by Darian Alberto Camacho Salas
========================================
Comandos útiles:
  xoni-help     : Muestra esta ayuda
  xoni-menu     : Menú interactivo
  xoni-update   : Actualiza xoniant32 desde GitHub
  xoni-install  : Instala herramientas XONI adicionales
  sudo connmanctl : Configura la red WiFi
  xonitube      : Buscador de YouTube (XONIDU)
  xonigraf      : Graficador matemático (XONIDU)
  xonichat      : Chat con IA (XONIDU)
  xonimail      : Cliente de correo (XONIDU)

El sistema arranca directamente en modo gráfico.
La terminal principal es fija (no se puede cerrar).

Repositorio: https://github.com/XONIDU/xoniant32
========================================
EOF

# ============================================
# 13. FINALIZACIÓN
# ============================================
echo "========================================"
echo "   INSTALACIÓN COMPLETADA               "
echo "========================================"
echo ""
echo "antiX ha sido transformado en xoniant32"
echo ""
echo "Componentes instalados:"
echo "  - Openbox con terminal fija"
echo "  - ALSA (audio)"
echo "  - Connman (WiFi)"
echo "  - Scripts XONI: xoni-install, xoni-update, xoni-help, xoni-menu"
echo "  - Herramientas desde XONIDU:"
echo "    * xonitube (YouTube)"
echo "    * xonigraf (graficador)"
echo "    * xonichat (IA)"
echo "    * xonimail (correo)"
echo ""
echo "No hay escritorio, barras, fondos ni gestores de display."
echo "WiFi: sudo connmanctl (opción 3 del menú)"
echo ""
echo "Reinicia el sistema para aplicar los cambios: sudo reboot"
echo ""
echo "Usuario: $TARGET_USER (contraseña sin cambios)"
echo ""
echo "¡Disfruta xoniant32!"
