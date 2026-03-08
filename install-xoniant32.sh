#!/bin/bash
# install-xoniant32-ultimate.sh – Terminal fija ULTIMATE (con atajos completos)
# Autor: Darian Alberto Camacho Salas
#
# Este script:
# 1. ELIMINA AUTOMÁTICAMENTE paquetes innecesarios (sin preguntar)
# 2. CONSERVA gráficos, audio, video, WiFi y Bluetooth (controladores)
# 3. CONFIGURA Openbox con terminal fija que OCULTA EL ESCRITORIO
# 4. AÑADE ATAJOS DE TECLADO COMPLETOS (Alt+Tab, Ctrl+Alt+T, etc.)
# 5. Optimizado para XoniTube v5.5 (tamaño de ventana 640x360)
# 6. Máxima compatibilidad con hardware de 32 bits (ASUS Eee PC 900)

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
echo "   XONIANT32 ULTIMATE - TERMINAL FIJA  "
echo "   by Darian Alberto Camacho Salas     "
echo "========================================"
echo "Este script ELIMINA AUTOMÁTICAMENTE:"
echo "  - Impresión (CUPS)"
echo "  - Bluetooth (solo servicios)"
echo "  - Wicd (gestor alternativo)"
echo "  - Scanner (saned)"
echo "  - Juegos preinstalados"
echo "  - Otros gestores (icewm, fluxbox, jwm)"
echo ""
echo "CONSERVA:"
echo "  - Controladores de video, audio, red"
echo "  - WiFi y Bluetooth (drivers)"
echo "  - Xorg completo"
echo "  - ALSA + PulseAudio"
echo ""
echo "AÑADE ATAJOS DE TECLADO:"
echo "  - Alt+Tab : Cambiar entre ventanas"
echo "  - Alt+F4  : Cerrar ventana"
echo "  - Ctrl+Alt+T : Nueva terminal"
echo "  - Win+x   : Menú principal"
echo "  - Win+q   : Cerrar sesión"
echo ""
echo "INICIARÁ DIRECTAMENTE EN TERMINAL (sin escritorio)"
echo "========================================"
echo ""
read -p "¿Continuar? (s/n): " CONFIRM
[[ "$CONFIRM" =~ ^[Ss]$ ]] || error_exit "Operación cancelada."

# ============================================
# 1. ELIMINAR PAQUETES INNECESARIOS (AUTOMÁTICO)
# ============================================
info "Eliminando paquetes innecesarios (para liberar RAM y disco)..."

# Impresión
apt purge -y cups cups-client cups-common cups-filters cups-ppdc || true

# Bluetooth (servicios, no drivers)
apt purge -y bluez bluetooth bluez-utils || true

# Gestores de red alternativos
apt purge -y wicd wicd-gtk wicd-daemon || true

# Scanner
apt purge -y sane saned sane-utils || true

# Juegos y aplicaciones innecesarias
apt purge -y gnome-games* aisleriot solitaire || true

# Gestores de ventanas adicionales
apt purge -y icewm* fluxbox* jwm* || true

# ============================================
# 2. INSTALAR PAQUETES NECESARIOS
# ============================================
info "Actualizando repositorios..."
apt update

info "Instalando paquetes esenciales..."
apt install -y git curl wget htop nano alsa-utils pulseaudio pavucontrol
apt install -y xorg xserver-xorg-core xserver-xorg-video-fbdev xserver-xorg-video-vesa
apt install -y openbox obconf rxvt-unicode
apt install -y mpv yt-dlp ffmpeg
apt install -y firmware-atheros firmware-iwlwifi firmware-realtek || true

# Controladores Intel (opcional, pero recomendado para Eee PC)
apt install -y xserver-xorg-video-intel || true

# ============================================
# 3. CONFIGURAR MPV (optimizado para 1GB RAM)
# ============================================
info "Configurando mpv para bajo consumo de recursos..."
mkdir -p /etc/mpv
cat > /etc/mpv/mpv.conf << 'EOF'
# Configuración ULTIMATE para mpv (bajo consumo)
vo=x11
ao=alsa
cache=yes
cache-secs=15           # Reduce uso de RAM
profile=fast
vd-lavc-fast
vd-lavc-skip-loop-filter=all
no-sub
no-osc
no-osd-bar
no-window-dragging      # Ahorra CPU
keepaspect-window
geometry=640x360        # Tamaño fijo (recomendado para XoniTube v5.5)
x11-bypass-compositor=yes
msg-level=all=error
EOF

# Configuración para el usuario
TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME="/home/$TARGET_USER"
mkdir -p "$USER_HOME/.config/mpv"
cp /etc/mpv/mpv.conf "$USER_HOME/.config/mpv/"
chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config/mpv"

# ============================================
# 4. CONFIGURAR OPENBOX (TERMINAL FIJA + ATAJOS)
# ============================================
info "Configurando Openbox con terminal fija y atajos completos..."

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
      <position force="yes">
        <x>0</x>
        <y>0</y>
      </position>
    </application>
  </applications>
  
  <menu><file>~/.config/openbox/menu.xml</file></menu>
  
  <keyboard>
    <!-- Atajos básicos de escritorio -->
    <keybind key="A-Tab">
      <action name="NextWindow"/>
    </keybind>
    <keybind key="A-S-Tab">
      <action name="PreviousWindow"/>
    </keybind>
    <keybind key="A-F4">
      <action name="Close"/>
    </keybind>
    
    <!-- Atajos personalizados Xoniant32 -->
    <keybind key="W-x">
      <action name="Execute"><command>xoni-menu</command></action>
    </keybind>
    <keybind key="W-t">
      <action name="Execute"><command>urxvt</command></action>
    </keybind>
    <keybind key="C-A-t">
      <action name="Execute"><command>urxvt</command></action>
    </keybind>
    <keybind key="W-h">
      <action name="Execute"><command>xoni-help</command></action>
    </keybind>
    <keybind key="W-q">
      <action name="Exit"/>
    </keybind>
    
    <!-- Cambiar entre escritorios virtuales -->
    <keybind key="C-A-Left">
      <action name="GoToDesktop"><to>left</to></action>
    </keybind>
    <keybind key="C-A-Right">
      <action name="GoToDesktop"><to>right</to></action>
    </keybind>
  </keyboard>
  
  <mouse>
    <context name="Root">
      <mousebind button="Right" action="Press">
        <action name="ShowMenu"><menu>root-menu</menu></action>
      </mousebind>
    </context>
  </mouse>
</openbox_config>
EOF

# Menú completo
cat > "$USER_HOME/.config/openbox/menu.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<openbox_menu>
  <menu id="root-menu" label="Xoniant32 Ultimate">
    <item label="Nueva terminal (Ctrl+Alt+T)">
      <action name="Execute"><command>urxvt</command></action>
    </item>
    <separator/>
    <item label="Instalar herramienta XONI">
      <action name="Execute"><command>urxvt -e xoni-install</command></action>
    </item>
    <item label="Configurar red (connman)">
      <action name="Execute"><command>urxvt -e sudo connmanctl</command></action>
    </item>
    <separator/>
    <item label="Ayuda">
      <action name="Execute"><command>xoni-help</command></action>
    </item>
    <item label="Cerrar sesión (Win+q)">
      <action name="Exit"/>
    </item>
  </menu>
</openbox_menu>
EOF

# Autostart - SOLO LA TERMINAL (NADA MÁS)
cat > "$USER_HOME/.config/openbox/autostart" << 'EOF'
# TERMINAL PRINCIPAL - OCUPA TODA LA PANTALLA
urxvt -title "principal" -fg white -bg black &
EOF

cat > "$USER_HOME/.xinitrc" << 'EOF'
#!/bin/sh
exec openbox-session
EOF
chmod +x "$USER_HOME/.xinitrc"

# ============================================
# 5. CONFIGURAR CONNMAN (WiFi)
# ============================================
info "Configurando connman (gestor de red liviano)..."
apt install -y connman
mkdir -p /etc/connman
cat > /etc/connman/main.conf << 'EOF'
[General]
PreferredTechnologies = wifi,ethernet
AllowHostnames = true
AutoConnect = true
SingleConnectedTechnology = false
NetworkInterfaceBlacklist = vmnet,vboxnet,virbr,ifb
EOF

systemctl restart connman || sv restart connman || true

# ============================================
# 6. DESACTIVAR OTROS GESTORES DE VENTANAS
# ============================================
info "Desactivando otros gestores de ventanas..."
for wm in icewm fluxbox jwm; do
    if [ -f "/usr/share/xsessions/$wm.desktop" ]; then
        mv "/usr/share/xsessions/$wm.desktop" "/usr/share/xsessions/$wm.desktop.disabled" 2>/dev/null || true
    fi
done

# ============================================
# 7. CONFIGURAR AUTO-LOGIN (GRÁFICO DIRECTO)
# ============================================
info "Configurando auto-login para iniciar directamente en la terminal..."

# Crear archivo de sesión Openbox
mkdir -p /usr/share/xsessions
cat > /usr/share/xsessions/openbox.desktop << 'EOF'
[Desktop Entry]
Name=Openbox
Comment=Openbox Window Manager
Exec=openbox-session
Type=Application
EOF

# LightDM
if [ -f /etc/lightdm/lightdm.conf ]; then
    mkdir -p /etc/lightdm/lightdm.conf.d
    cat > /etc/lightdm/lightdm.conf.d/50-xoniant32.conf << EOF
[Seat:*]
autologin-user=$TARGET_USER
autologin-session=openbox
user-session=openbox
EOF
    info "LightDM configurado con auto-login."
fi

# SDDM
if [ -f /etc/sddm.conf ]; then
    mkdir -p /etc/sddm.conf.d
    cat > /etc/sddm.conf.d/50-xoniant32.conf << EOF
[Autologin]
User=$TARGET_USER
Session=openbox.desktop
EOF
    info "SDDM configurado con auto-login."
fi

# LXDM
if [ -f /etc/lxdm/lxdm.conf ]; then
    sed -i "s/^# autologin=.*/autologin=$TARGET_USER/" /etc/lxdm/lxdm.conf
    sed -i "s/^# session=.*/session=\/usr\/share\/xsessions\/openbox.desktop/" /etc/lxdm/lxdm.conf
    info "LXDM configurado con auto-login."
fi

# SLiM
if [ -f /etc/slim.conf ]; then
    echo "default_user $TARGET_USER" >> /etc/slim.conf
    echo "auto_login yes" >> /etc/slim.conf
    echo "session openbox" >> /etc/slim.conf
    info "SLiM configurado con auto-login."
fi

# Fallback: auto-login en consola (si no hay gestor de display)
if ! pgrep -x "lightdm|sddm|lxdm|slim" >/dev/null 2>&1; then
    warn "No se detectó gestor de display. Configurando auto-login en consola..."
    mkdir -p /etc/systemd/system/getty@tty1.service.d
    cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $TARGET_USER --noclear %I 38400 linux
EOF
    cat >> "$USER_HOME/.bashrc" << 'EOF'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
    exit 0
fi
EOF
fi

# ============================================
# 8. CREAR SCRIPTS XONI (OPTIMIZADOS)
# ============================================
info "Creando scripts XONI..."

cat > /usr/local/bin/xoni-install << 'EOF'
#!/bin/bash
# Instalador automático de herramientas XONI
REPO_BASE="https://github.com/XONIDU"
cd "$HOME"
TOOL="${1:-}"
if [ -z "$TOOL" ]; then
    echo "Herramientas: xonitube, xonigraf, xonichat, xonimail"
    read -p "Instalar: " TOOL
fi
if [ -n "$TOOL" ]; then
    [ -d "$TOOL" ] || git clone "$REPO_BASE/$TOOL.git"
    if [ -f "$TOOL/start.py" ]; then
        sudo ln -sf "$HOME/$TOOL/start.py" "/usr/local/bin/$TOOL"
        sudo chmod +x "/usr/local/bin/$TOOL"
        echo "[OK] $TOOL instalado (comando: $TOOL)"
    else
        echo "[AVISO] Repositorio descargado en ~/$TOOL"
    fi
fi
EOF

cat > /usr/local/bin/xoni-menu << 'EOF'
#!/bin/bash
while true; do
    clear
    echo "============================="
    echo "  XONIANT32 ULTIMATE - MENÚ"
    echo "============================="
    echo "1) Nueva terminal (Ctrl+Alt+T)"
    echo "2) Instalar herramienta XONI"
    echo "3) Configurar red (connman)"
    echo "4) Ayuda"
    echo "5) Cerrar sesión (Win+q)"
    echo ""
    read -p "Opción: " opt
    case $opt in
        1) urxvt ;;
        2) urxvt -e xoni-install ; read -p "Enter..." ;;
        3) urxvt -e sudo connmanctl ;;
        4) xoni-help ; read -p "Enter..." ;;
        5) openbox --exit ;;
    esac
done
EOF

cat > /usr/local/bin/xoni-help << 'EOF'
#!/bin/bash
cat << 'HELP'
========================================
   XONIANT32 ULTIMATE - AYUDA
========================================
COMANDOS:
  xoni-menu     : Menú interactivo
  xoni-install  : Instalar herramientas (ej: xoni-install xonitube)
  sudo connmanctl : Configurar WiFi

ATAJOS DE TECLADO (en Openbox):
  Alt+Tab       : Cambiar entre ventanas
  Alt+F4        : Cerrar ventana actual
  Ctrl+Alt+T    : Nueva terminal
  Win+x         : Abrir menú
  Win+q         : Cerrar sesión
  Ctrl+Alt+←/→  : Cambiar escritorio virtual

La terminal principal ocupa TODA la pantalla.
El escritorio está OCULTO pero los controladores se conservan.

Repositorio: https://github.com/XONIDU/xoniant32
HELP
EOF

chmod +x /usr/local/bin/xoni-*

# Mensaje de bienvenida
cat >> "$USER_HOME/.bashrc" << 'EOF'
echo "========================================"
echo "   XONIANT32 ULTIMATE - TERMINAL FIJA"
echo "   by Darian Alberto Camacho Salas"
echo "========================================"
echo "Comandos: xoni-help, xoni-menu, xoni-install"
echo ""
echo "ATAJOS DE TECLADO:"
echo "  Alt+Tab     : Cambiar ventana"
echo "  Alt+F4      : Cerrar ventana"
echo "  Ctrl+Alt+T  : Nueva terminal"
echo "  Win+x       : Menú"
echo "  Win+q       : Cerrar sesión"
echo "========================================"
EOF

chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config" "$USER_HOME/.xinitrc" "$USER_HOME/.bashrc"

# ============================================
# 9. LIMPIEZA FINAL
# ============================================
info "Eliminando dependencias no usadas..."
apt autoremove --purge -y

info "Limpiando caché..."
apt clean
apt autoclean

# ============================================
# 10. FINALIZACIÓN
# ============================================
echo "========================================"
echo "   INSTALACIÓN ULTIMATE COMPLETADA      "
echo "========================================"
echo ""
echo "✅ Se eliminaron automáticamente:"
echo "   - Impresión, Bluetooth, Wicd, Scanner"
echo "   - Juegos, otros gestores de ventanas"
echo ""
echo "✅ Se conservaron:"
echo "   - Controladores de video, audio, red, WiFi"
echo "   - Xorg, ALSA, PulseAudio"
echo ""
echo "✅ ATAJOS DE TECLADO CONFIGURADOS:"
echo "   - Alt+Tab     : Cambiar ventana"
echo "   - Alt+F4      : Cerrar ventana"
echo "   - Ctrl+Alt+T  : Nueva terminal"
echo "   - Win+x       : Menú"
echo "   - Win+q       : Cerrar sesión"
echo ""
echo "✅ Terminal fija que OCULTA el escritorio"
echo "✅ mpv optimizado para XoniTube v5.5"
echo ""
echo "▶ Para instalar xonitube:  xoni-install xonitube"
echo "▶ Para abrir el menú:        xoni-menu"
echo "▶ Para ayuda:                xoni-help"
echo ""
echo "Reinicia ahora: sudo reboot"
echo ""
echo "Usuario: $TARGET_USER"
echo "========================================"
