#!/bin/bash
# xoniant32 – Script de purga definitiva
# Autor: Darian Alberto Camacho Salas
# Repositorio: https://github.com/XONIDU/xoniant32
#
# Este script elimina todo lo innecesario de antiX y deja solo:
#   - Openbox + terminal fija
#   - Soporte de audio (ALSA)
#   - Connman para WiFi (como en antiX)
#   - Herramientas XONI
#   - NADA MÁS (sin escritorios, sin apps, sin nmtui, sin gestores)

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
echo "   XONIANT32 - PURGA DEFINITIVA        "
echo "========================================"
echo "ADVERTENCIA: Este script ELIMINARÁ:"
echo "  - TODOS los escritorios (XFCE, Fluxbox, IceWM, JWM)"
echo "  - TODAS las aplicaciones gráficas"
echo "  - TODOS los gestores de display"
echo "  - nmtui y NetworkManager"
echo ""
echo "SOLO DEJARÁ:"
echo "  - Openbox con terminal fija"
echo "  - ALSA para audio"
echo "  - Connman para WiFi"
echo "  - Scripts XONI"
echo "========================================"
echo ""
read -p "¿Estás seguro de continuar? (escribe YES): " CONFIRM
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

info "Purgando herramientas de desarrollo..."
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
# 3. INSTALAR PAQUETES ESENCIALES
# ============================================
info "Instalando paquetes esenciales mínimos..."

apt update

# Base mínima
apt install -y git curl wget htop nano

# Audio (ALSA puro, sin pulseaudio)
apt install -y alsa-utils

# Xorg mínimo
apt install -y xorg xserver-xorg-core xserver-xorg-input-all xserver-xorg-video-fbdev

# Openbox y terminal fija
apt install -y openbox obconf tint2 feh picom rxvt-unicode pcmanfm

# Connman (gestor WiFi nativo de antiX)
apt install -y connman

# ============================================
# 4. CONFIGURAR OPENBOX (TERMINAL FIJA)
# ============================================
info "Configurando Openbox con terminal fija..."

# Determinar usuario
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    TARGET_USER="$SUDO_USER"
else
    read -p "Nombre de usuario para configurar: " TARGET_USER
fi
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
    <keybind key="W-x"><action name="Execute"><command>xoniarch-menu</command></action></keybind>
    <keybind key="W-t"><action name="Execute"><command>urxvt</command></action></keybind>
    <keybind key="W-h"><action name="Execute"><command>xoniarch-help</command></action></keybind>
    <keybind key="W-i"><action name="Execute"><command>installxoni</command></action></keybind>
    <keybind key="W-q"><action name="Exit"/></keybind>
  </keyboard>
</openbox_config>
EOF

cat > "$USER_HOME/.config/openbox/menu.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<openbox_menu>
  <menu id="root-menu" label="Xoniant32">
    <item label="Nueva terminal"><action name="Execute"><command>urxvt</command></action></item>
    <item label="Instalar herramienta XONI"><action name="Execute"><command>urxvt -e installxoni</command></action></item>
    <item label="Ayuda"><action name="Execute"><command>urxvt -e xoniarch-help</command></action></item>
    <item label="Cerrar sesión"><action name="Exit"/></item>
  </menu>
</openbox_menu>
EOF

cat > "$USER_HOME/.config/openbox/autostart" << 'EOF'
# TERMINAL PRINCIPAL (NO SE PUEDE CERRAR)
urxvt -title "principal" &
feh --bg-scale /usr/share/backgrounds/default.jpg &
picom -b &
tint2 &
EOF

cat > "$USER_HOME/.xinitrc" << 'EOF'
#!/bin/sh
exec openbox-session
EOF
chmod +x "$USER_HOME/.xinitrc"

chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config" "$USER_HOME/.xinitrc"

# ============================================
# 5. CONFIGURAR CONNMAN (WiFi nativo)
# ============================================
info "Configurando Connman para WiFi..."

# Asegurar que connman esté habilitado en runit
mkdir -p /etc/sv/connman
cat > /etc/sv/connman/run << 'EOF'
#!/bin/bash
exec chpst -u root /usr/sbin/connmand -n
EOF
chmod +x /etc/sv/connman/run

ln -s /etc/sv/connman /etc/service/connman 2>/dev/null || true

# Mensaje recordatorio para el usuario
cat > "$USER_HOME/.connman-ayuda" << 'EOF'
╔═══════════════════════════════════════════════╗
║   CONECTARSE A WIFI EN XONIANT32              ║
╚═══════════════════════════════════════════════╝

Comando: sudo connmanctl

Dentro de connmanctl:
  agent on                  # Activar agente para contraseñas
  enable wifi               # Habilitar WiFi
  scan wifi                 # Escanear redes
  services                  # Listar redes disponibles
  connect wifi_nombre       # Conectar (usa TAB para autocompletar)
  quit                      # Salir

Ejemplo:
  $ sudo connmanctl
  connmanctl> agent on
  connmanctl> enable wifi
  connmanctl> scan wifi
  connmanctl> services
  connmanctl> connect wifi_MyHomeNetwork_managed_psk
  connmanctl> quit
EOF

chown "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.connman-ayuda"

# ============================================
# 6. CREAR SCRIPTS XONI
# ============================================
info "Creando scripts XONI..."

cat > /usr/local/bin/installxoni << 'EOF'
#!/bin/bash
REPO_BASE="https://github.com/XONIDU"
DIR="/opt/xoniarch"
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

cat > /usr/local/bin/xoniarch-update << 'EOF'
#!/bin/bash
cd /opt/xoniarch
for tool in */; do
    [ -d "$tool" ] && (cd "$tool" && git pull)
done
echo "[OK] Actualización completada"
EOF

cat > /usr/local/bin/xoniarch-help << 'EOF'
#!/bin/bash
cat << 'HELP'
========================================
   XONIANT32 - AYUDA
========================================
COMANDOS:
  installxoni <herramienta>  : Instalar desde GitHub
  xoniarch-update            : Actualizar herramientas
  xoniarch-menu              : Menú interactivo
  sudo connmanctl            : Configurar WiFi

AUDIO:
  alsamixer                  : Ajustar volumen
  speaker-test               : Probar audio

ATAJOS:
  Win + x   : Menú principal
  Win + t   : Nueva terminal
  Win + h   : Ayuda
  Win + i   : Instalar herramienta
  Win + q   : Cerrar sesión

El sistema ARRANCA DIRECTAMENTE EN MODO GRÁFICO
La terminal principal es FIJA (no se puede cerrar)

REPOSITORIO: https://github.com/XONIDU/xoniant32
HELP
EOF

cat > /usr/local/bin/xoniarch-menu << 'EOF'
#!/bin/bash
while true; do
    clear
    echo "========================================"
    echo "      XONIANT32 - MENU PRINCIPAL"
    echo "========================================"
    echo "1) Nueva terminal"
    echo "2) Instalar herramienta XONI"
    echo "3) Ayuda"
    echo "4) Cerrar sesión"
    echo ""
    read -p "Opción [1-4]: " opt
    case $opt in
        1) urxvt ;;
        2) urxvt -e installxoni ; read -p "Presiona Enter..." ;;
        3) xoniarch-help ; read -p "Presiona Enter..." ;;
        4) openbox --exit ;;
        *) echo "Opción inválida"; sleep 2 ;;
    esac
done
EOF

chmod +x /usr/local/bin/*

# ============================================
# 7. CONFIGURAR ARRANQUE AUTOMÁTICO
# ============================================
info "Configurando arranque automático a X..."

# Auto-login en tty1
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $TARGET_USER --noclear %I 38400 linux
EOF

# Arranque de X en .bashrc
cat >> "$USER_HOME/.bashrc" << 'BASHRC'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
fi

alias ll='ls -la'
alias la='ls -A'
alias update='xoniarch-update'
alias menu='xoniarch-menu'
alias help='xoniarch-help'
alias wifi='sudo connmanctl'
BASHRC

chown "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.bashrc"

# ============================================
# 8. LIMPIEZA FINAL
# ============================================
info "Limpiando paquetes residuales..."
apt autoremove --purge -y
apt clean

echo "========================================"
echo "   PURGA COMPLETADA                     "
echo "========================================"
echo ""
echo "✅ antiX ha sido transformado en xoniant32"
echo ""
echo "📋 RESULTADO FINAL:"
echo "   ✓ Escritorios eliminados"
echo "   ✓ Apps gráficas eliminadas"
echo "   ✓ Gestores de display eliminados"
echo "   ✓ NetworkManager eliminado"
echo "   ✓ Openbox + terminal fija instalados"
echo "   ✓ ALSA para audio"
echo "   ✓ Connman para WiFi"
echo "   ✓ Scripts XONI instalados"
echo ""
echo "🌐 CONECTARSE A WIFI:"
echo "   $ sudo connmanctl"
echo "   (sigue las instrucciones en ~/.connman-ayuda)"
echo ""
echo "🎯 PRÓXIMOS PASOS:"
echo "   1. Reinicia: sudo reboot"
echo "   2. Al arrancar, entrarás directamente a X"
echo "   3. Usa 'xoniarch-help' para ver comandos"
echo ""
echo "Usuario: $TARGET_USER"
echo "Contraseña: la misma de antiX"
echo ""
echo "¡Disfruta tu xoniant32 minimalista!"
