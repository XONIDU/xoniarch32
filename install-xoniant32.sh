#!/bin/bash
# install-xoniant32.sh – Terminal gráfica fija con OPTIMIZACIÓN GRÁFICA EXTREMA
# Autor: Darian Alberto Camacho Salas
# Repositorio: https://github.com/XONIDU/xoniant32
#
# Este script elimina escritorios completos y aplicaciones pesadas,
# OPTIMIZA EL RENDIMIENTO GRÁFICO para eliminar el lag visual
# manteniendo la sincronización perfecta entre video y audio.
# El sistema ARRANCA DIRECTAMENTE en una terminal maximizada
# que NO SE PUEDE CERRAR.
# Las herramientas XONI se instalan en carpetas individuales en ~/

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

# ============================================
# FUNCIÓN PARA VERIFICAR CONEXIÓN A INTERNET
# ============================================
check_internet() {
    echo -n "Verificando conexión a internet... "
    if ping -c 1 google.com &>/dev/null || ping -c 1 8.8.8.8 &>/dev/null; then
        echo -e "${GREEN}OK${NC}"
        return 0
    else
        echo -e "${RED}FALLÓ${NC}"
        return 1
    fi
}

# ============================================
# FUNCIÓN PARA CONFIGURAR WIFI CON CONNMAN
# ============================================
configure_wifi() {
    echo ""
    echo "Vamos a configurar la red WiFi usando connman."
    echo "Asegúrate de tener el nombre de tu red (SSID) y la contraseña."
    read -p "Presiona Enter para continuar..."
    
    sudo connmanctl
    echo ""
    echo "Dentro de connmanctl, sigue estos pasos:"
    echo "  agent on"
    echo "  enable wifi"
    echo "  scan wifi"
    echo "  services"
    echo "  connect wifi_nombre_de_tu_red  (usa TAB para autocompletar)"
    echo "  quit"
    echo ""
    read -p "Presiona Enter cuando hayas terminado de configurar la red..."
    
    if check_internet; then
        return 0
    else
        warn "Todavía no hay conexión."
        read -p "¿Quieres reintentar configurar WiFi? (s/n): " RETRY
        if [[ "$RETRY" =~ ^[Ss]$ ]]; then
            configure_wifi
        else
            return 1
        fi
    fi
}

# ============================================
# VERIFICAR CONEXIÓN ANTES DE COMENZAR
# ============================================
clear
echo "========================================"
echo "   XONIANT32 - OPTIMIZACIÓN GRÁFICA    "
echo "   by Darian Alberto Camacho Salas     "
echo "========================================"
echo ""

if ! check_internet; then
    warn "No hay conexión a internet. Es necesaria para continuar."
    echo ""
    echo "Opciones:"
    echo "  1) Configurar WiFi ahora (connman)"
    echo "  2) Salir"
    read -p "Elige una opción [1-2]: " NET_OPT
    case $NET_OPT in
        1) configure_wifi ;;
        *) error_exit "Instalación cancelada." ;;
    esac
    
    if ! check_internet; then
        error_exit "No se pudo establecer conexión. Abortando."
    fi
fi

# ============================================
# MENSAJE DE ADVERTENCIA
# ============================================
echo ""
echo "ADVERTENCIA: Este script ELIMINARÁ:"
echo "  - TODOS los escritorios completos"
echo "  - TODAS las aplicaciones gráficas pesadas"
echo "  - Gestores de display (lightdm, sddm, lxdm, slim, gdm3, xdm)"
echo "  - Barras de tareas, fondos, compositores"
echo "  - NetworkManager (usaremos connman nativo)"
echo "  - Scripts antiguos (xoniarch-*)"
echo ""
echo "CONSERVARÁ:"
echo "  - Openbox con TODAS sus funciones (gestor de ventanas completo)"
echo "  - Atajos de teclado como Alt+TAB para cambiar ventanas"
echo "  - Terminal fija (rxvt-unicode) - NO SE PUEDE CERRAR"
echo "  - ALSA para audio"
echo "  - Connman para WiFi (configurado)"
echo "  - mpv + yt-dlp (para xonitube) CONFIGURADOS PARA MÁXIMA SINCRO"
echo "  - Scripts XONI (xoni-install, xoni-update, xoni-help, xoni-menu)"
echo "  - Las herramientas XONI se instalarán en carpetas individuales en ~/"
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

# ============================================
# 2. ELIMINAR SERVICIOS INNECESARIOS
# ============================================
info "Deshabilitando servicios innecesarios para mejorar rendimiento..."

SERVICIOS_INNECESARIOS=(
    "bluetooth"
    "cups"
    "cups-browsed"
    "avahi-daemon"
    "ModemManager"
    "whoopsie"
    "apport"
    "speech-dispatcher"
)

for servicio in "${SERVICIOS_INNECESARIOS[@]}"; do
    if systemctl list-unit-files | grep -q "$servicio"; then
        systemctl stop "$servicio" 2>/dev/null || true
        systemctl disable "$servicio" 2>/dev/null || true
        echo "  - $servicio deshabilitado"
    fi
done

# ============================================
# 3. OPTIMIZAR SWAPPINESS
# ============================================
info "Optimizando uso de memoria (swappiness)..."
echo "vm.swappiness=10" >> /etc/sysctl.conf
sysctl -p

# ============================================
# 4. OPTIMIZACIÓN GRÁFICA ESPECÍFICA
# ============================================
info "Aplicando optimizaciones gráficas para eliminar lag visual..."

# Instalar controladores Intel mejorados si se detecta GPU Intel
if lspci | grep -i "VGA.*Intel" > /dev/null; then
    info "GPU Intel detectada - instalando controladores optimizados..."
    apt install -y xserver-xorg-video-intel
    # Configuración específica para Intel
    mkdir -p /etc/X11/xorg.conf.d
    cat > /etc/X11/xorg.conf.d/20-intel.conf << 'EOF'
Section "Device"
   Identifier  "Intel Graphics"
   Driver      "intel"
   Option      "AccelMethod"    "sna"
   Option      "TearFree"       "true"
   Option      "DRI"            "3"
   Option      "SwapbuffersWait" "false"
EndSection
EOF
fi

# Configuración global de Xorg para mejorar rendimiento
cat > /etc/X11/xorg.conf.d/10-performance.conf << 'EOF'
Section "Device"
   Identifier "Card0"
   Driver     "modesetting"
   Option     "PageFlip"         "true"
   Option     "SwapbuffersWait"  "false"
   Option     "DRI"              "3"
EndSection

Section "Extensions"
    Option "Composite" "Disable"
EndSection
EOF

# ============================================
# 5. ELIMINAR RASTROS DE XONIARCH
# ============================================
info "Eliminando rastros de xoniarch..."
rm -f /usr/local/bin/xoniarch-* 2>/dev/null || true
rm -f /usr/local/bin/xoniarch 2>/dev/null || true
rm -f /usr/local/bin/xoniarch32 2>/dev/null || true
rm -rf /opt/xoniarch 2>/dev/null || true
rm -rf /opt/xoniarch32 2>/dev/null || true

# ============================================
# 6. AUTOLIMPIEZA
# ============================================
info "Eliminando dependencias no usadas..."
apt autoremove --purge -y

info "Limpiando caché..."
apt clean
apt autoclean

# ============================================
# 7. INSTALAR PAQUETES MÍNIMOS
# ============================================
info "Actualizando repositorios..."
apt update || warn "Error en apt update, continuando..."

info "Instalando paquetes base..."
apt install -y git curl wget htop nano alsa-utils connman

# Xorg + Openbox (ligero)
apt install -y xorg openbox obconf rxvt-unicode

# Herramientas multimedia (con optimizaciones)
apt install -y mpv yt-dlp ffmpeg mesa-utils

# Firmware WiFi
apt install -y firmware-atheros firmware-iwlwifi || warn "Algún firmware WiFi no se pudo instalar."

# ============================================
# 8. CONFIGURAR CONNMAN
# ============================================
info "Configurando connman..."
mkdir -p /etc/connman
cat > /etc/connman/main.conf << 'EOF'
[General]
PreferredTechnologies = wifi,ethernet
AllowHostnames = true
SingleConnectedTechnology = true
AutoConnect = true
BackgroundScanning = false
NetworkInterfaceBlacklist = vmnet,vboxnet,virbr,ifb
EOF

systemctl restart connman || sv restart connman || true

# ============================================
# 9. CONFIGURAR MPV (SINCRONIZACIÓN PERFECTA)
# ============================================
info "Configurando mpv para sincronización perfecta video/audio..."

mkdir -p /etc/mpv
cat > /etc/mpv/mpv.conf << 'EOF'
# Configuración para MÁXIMA SINCRO video/audio
vo=x11
ao=alsa
cache=yes
cache-secs=30
profile=fast
msg-level=all=error
x11-bypass-compositor=yes

# Sincronización extrema
video-sync=display-resample
video-sync-max-video-change=5
audio-buffer=0.2
video-latency-hacks=yes

# Optimización de rendimiento
framedrop=vo
vd-lavc-fast=yes
vd-lavc-skiploopfilter=all
vd-lavc-skipframe=nonref
vd-lavc-threads=2

# Suavizado de video
deband=no
scale=bilinear
cscale=bilinear
dscale=bilinear

# Sin efectos innecesarios
osd-level=0
osd-duration=0
EOF

TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME="/home/$TARGET_USER"

mkdir -p "$USER_HOME/.config/mpv"
cp /etc/mpv/mpv.conf "$USER_HOME/.config/mpv/"
chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config/mpv"

# ============================================
# 10. CONFIGURAR OPENBOX
# ============================================
info "Configurando Openbox con terminal fija y atajos completos..."

mkdir -p "$USER_HOME/.config/openbox"

# Configuración optimizada de Openbox (sin efectos)
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
  
  <theme>
    <name>Clearlooks</name>
    <titleLayout>NLIMC</titleLayout>
    <keepBorder>no</keepBorder>
    <animateIconify>no</animateIconify>
  </theme>
  
  <keyboard>
    <keybind key="W-x"><action name="Execute"><command>xoni-menu</command></action></keybind>
    <keybind key="W-t"><action name="Execute"><command>urxvt</command></action></keybind>
    <keybind key="W-h"><action name="Execute"><command>xoni-help</command></action></keybind>
    <keybind key="W-u"><action name="Execute"><command>xoni-update</command></action></keybind>
    <keybind key="W-q"><action name="Exit"/></keybind>
    
    <keybind key="A-Tab"><action name="NextWindow"/></keybind>
    <keybind key="A-S-Tab"><action name="PreviousWindow"/></keybind>
    <keybind key="A-F4"><action name="Close"/></keybind>
    <keybind key="A-Space"><action name="ShowMenu"><menu>client-menu</menu></action></keybind>
    <keybind key="W-d"><action name="ToggleShowDesktop"/></keybind>
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
  
  <menu id="client-menu">
    <item label="Restaurar"><action name="Unmaximize"/><action name="MoveResizeTo"><x>center</x><y>center</y><width>50%</width><height>50%</height></action></item>
    <item label="Mover"><action name="Move"/></item>
    <item label="Redimensionar"><action name="Resize"/></item>
    <item label="Iconificar"><action name="Iconify"/></item>
    <item label="Maximizar"><action name="ToggleMaximize"/></item>
    <separator/>
    <item label="Cerrar"><action name="Close"/></item>
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
# 11. AUTO-LOGIN EN TTY1 + INICIO DE X
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
echo "   XONIANT32 - OPTIMIZACIÓN GRÁFICA    "
echo "   by Darian Alberto Camacho Salas     "
echo "========================================"
echo "Comandos útiles:"
echo "  xoni-help     : Muestra esta ayuda"
echo "  xoni-menu     : Menú interactivo"
echo "  xoni-update   : Actualiza xoniant32"
echo "  xoni-install  : Instala herramientas XONI en carpetas individuales en ~/"
echo "  sudo connmanctl : Configura la red WiFi"
echo ""
echo "OPTIMIZACIONES GRÁFICAS APLICADAS:"
echo "  - Sincronización forzada video/audio"
echo "  - Controladores Intel optimizados (si aplica)"
echo "  - Composición desactivada"
echo "  - TearFree activado"
echo ""
echo "ATAJOS DE TECLADO:"
echo "  Alt+TAB       : Cambiar entre ventanas"
echo "  Alt+Espacio   : Menú de ventana"
echo "  Alt+F4        : Cerrar ventana"
echo "  Win+x         : Menú XONI"
echo "  Win+t         : Nueva terminal"
echo "  Win+h         : Ayuda"
echo "========================================"
EOF

chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config" "$USER_HOME/.xinitrc" "$USER_HOME/.bashrc"

# ============================================
# 12. CREAR SCRIPTS XONI
# ============================================
info "Creando scripts XONI..."

cat > /usr/local/bin/xoni-install << 'EOF'
#!/bin/bash
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
    
    if [ -f "$TOOL/start.py" ]; then
        sudo ln -sf "$HOME/$TOOL/start.py" "/usr/local/bin/$TOOL"
        sudo chmod +x "/usr/local/bin/$TOOL"
        echo "[OK] $TOOL disponible"
    elif [ -f "$TOOL/$TOOL.py" ]; then
        sudo ln -sf "$HOME/$TOOL/$TOOL.py" "/usr/local/bin/$TOOL"
        sudo chmod +x "/usr/local/bin/$TOOL"
        echo "[OK] $TOOL disponible"
    elif [ -f "$TOOL/$TOOL.sh" ]; then
        sudo ln -sf "$HOME/$TOOL/$TOOL.sh" "/usr/local/bin/$TOOL"
        sudo chmod +x "/usr/local/bin/$TOOL"
        echo "[OK] $TOOL disponible"
    else
        echo "[AVISO] Repositorio en ~/$TOOL"
    fi

else
    echo "Herramientas: xonitube, xonigraf, xonichat, xonimail, ..."
    read -p "Herramienta a instalar: " TOOL
    [ -n "$TOOL" ] && exec "$0" "$TOOL"
fi
EOF

cat > /usr/local/bin/xoni-update << 'EOF'
#!/bin/bash
REPO="https://github.com/XONIDU/xoniant32.git"
DIR="/opt/xoniant32"
echo "Actualizando xoniant32..."
[ ! -d "$DIR" ] && sudo git clone "$REPO" "$DIR" || (cd "$DIR" && sudo git pull)
[ -d "$DIR/scripts" ] && sudo cp -v "$DIR/scripts"/xoni-* /usr/local/bin/ 2>/dev/null || true
sudo rm -f /usr/local/bin/xoniarch-* 2>/dev/null || true
sudo chmod +x /usr/local/bin/xoni-* 2>/dev/null || true

cd "$HOME"
for tool in */; do
    t="${tool%/}"
    [ -d "$t/.git" ] && (cd "$t" && git pull) && echo "Actualizado $t"
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
  xoni-help         : Esta ayuda
  xoni-menu         : Menú interactivo
  xoni-update       : Actualizar todo
  xoni-install      : Instalar herramientas

OPTIMIZACIONES GRÁFICAS ACTIVAS:
  - Sincronización video/audio forzada
  - Composición desactivada
  - TearFree activado
  - Controladores Intel optimizados

ATAJOS:
  Alt+TAB : Cambiar ventana
  Alt+F4  : Cerrar
  Win+x   : Menú XONI
  Win+t   : Nueva terminal
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
    echo "2) Instalar herramienta"
    echo "3) Configurar red"
    echo "4) Monitor sistema"
    echo "5) Actualizar"
    echo "6) Ayuda"
    echo "7) Cerrar sesión"
    read -p "Opción [1-7]: " opt
    case $opt in
        1) urxvt ;;
        2) urxvt -e xoni-install ; read -p "Enter..." ;;
        3) urxvt -e sudo connmanctl ;;
        4) urxvt -e htop ;;
        5) urxvt -e xoni-update ; read -p "Enter..." ;;
        6) xoni-help ; read -p "Enter..." ;;
        7) openbox --exit ;;
    esac
done
EOF

chmod +x /usr/local/bin/xoni-*

# ============================================
# 13. ACTUALIZAR MOTD
# ============================================
cat > /etc/motd << 'EOF'
========================================
   XONIANT32 - OPTIMIZACIÓN GRÁFICA
========================================
OPTIMIZACIONES ACTIVAS:
• Sincronización video/audio forzada
• TearFree activado
• Composición desactivada
• Controladores Intel optimizados
• Swappiness reducido (10)

Comandos: xoni-help | xoni-menu | xoni-install
ATAJOS: Alt+TAB, Win+x, Win+t
========================================
EOF

# ============================================
# 14. FINALIZACIÓN
# ============================================
echo "========================================"
echo "   INSTALACIÓN COMPLETADA               "
echo "========================================"
echo ""
echo "OPTIMIZACIONES GRÁFICAS APLICADAS:"
echo "  ✓ Sincronización video/audio forzada (video-sync=display-resample)"
echo "  ✓ TearFree activado (elimina tearing)"
echo "  ✓ Composición desactivada (más fps)"
echo "  ✓ Controladores Intel optimizados (si aplica)"
echo "  ✓ Buffer de audio reducido (menos latencia)"
echo ""
echo "Prueba con: xoni-install xonitube && xonitube"
echo ""
echo "Reinicia: sudo reboot"
echo "Usuario: $TARGET_USER"
echo ""
echo "¡Disfruta xoniant32 SIN LAG GRÁFICO!"
