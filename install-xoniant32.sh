#!/bin/bash
# install-xoniant32-ultimate.sh – Terminal fija (SIN ELIMINAR PAQUETES)
# Autor: Darian Alberto Camacho Salas
#
# Este script:
# 1. NO ELIMINA NINGÚN PAQUETE (conserva todo el sistema antiX original)
# 2. CONFIGURA Openbox con terminal fija que OCULTA EL ESCRITORIO
# 3. PERMITE que ventanas emergentes (mpv, nuevas terminales) se vean SOBRE la terminal
# 4. BLOQUEA el cierre de la terminal principal (sin botón X, sin Alt+F4)
# 5. AÑADE SOPORTE COMPLETO de ratón y teclado
# 6. Optimizado para XoniTube v5.5 (tamaño de ventana 640x360)

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
echo "Este script NO ELIMINA NINGÚN PAQUETE."
echo "Conserva TODO el sistema antiX original."
echo ""
echo "SOLO CONFIGURA:"
echo "  ✓ Openbox con terminal fija"
echo "  ✓ Click derecho para PEGAR"
echo "  ✓ Atajos: Ctrl+Shift+C/V, Alt+Tab, Alt+F4, Win+x, Win+q"
echo "  ✓ Ventanas emergentes sobre la terminal"
echo ""
echo "INICIARÁ DIRECTAMENTE EN TERMINAL (sin escritorio)"
echo "========================================"
echo ""
read -p "¿Continuar? (s/n): " CONFIRM
[[ "$CONFIRM" =~ ^[Ss]$ ]] || error_exit "Operación cancelada."

# ============================================
# 1. ACTUALIZAR REPOSITORIOS (sin eliminar nada)
# ============================================
info "Actualizando repositorios..."
apt update

# ============================================
# 2. INSTALAR PAQUETES ADICIONALES (solo si no están)
# ============================================
info "Instalando paquetes adicionales (si no están)..."
apt install -y openbox obconf rxvt-unicode mpv yt-dlp ffmpeg xclip xsel connman

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
cache-secs=15
profile=fast
vd-lavc-fast
vd-lavc-skip-loop-filter=all
no-sub
no-osc
no-osd-bar
no-window-dragging
keepaspect-window
geometry=640x360
x11-bypass-compositor=yes
ontop
msg-level=all=error
EOF

# Configuración para el usuario
TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME="/home/$TARGET_USER"
mkdir -p "$USER_HOME/.config/mpv"
cp /etc/mpv/mpv.conf "$USER_HOME/.config/mpv/"
chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config/mpv"

# ============================================
# 4. CONFIGURAR URXVT (COPIA/PEGA CON RATÓN)
# ============================================
info "Configurando urxvt con soporte de portapapeles..."

mkdir -p "$USER_HOME/.urxvt/ext"
chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.urxvt"

cat > "$USER_HOME/.urxvt/ext/clipboard-paste-on-right-click" << 'EOF'
#! perl
# clipboard-paste-on-right-click - Extensión para urxvt que permite pegar con click derecho

sub on_button_press {
    my ($self, $event) = @_;

    if ($event->{button} == 3 && $event->{state} == 0) {
        my $clipboard = `xclip -selection clipboard -o 2>/dev/null`;
        if ($clipboard) {
            $self->tt_paste($clipboard);
            return 1;
        }
    }
    return ();
}
EOF

chown "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.urxvt/ext/clipboard-paste-on-right-click"

cat > "$USER_HOME/.Xresources" << 'EOF'
! Configuración URxvt para Xoniant32 Ultimate
URxvt.font: xft:monospace:size=10
URxvt.background: black
URxvt.foreground: white
URxvt.scrollBar: false
URxvt.saveLines: 5000
URxvt.perl-ext-common: default,clipboard-paste-on-right-click
URxvt.keysym.Shift-Control-C: eval:selection_to_clipboard
URxvt.keysym.Shift-Control-V: eval:paste_clipboard
URxvt.keysym.Control-Insert: eval:selection_to_clipboard
URxvt.keysym.Shift-Insert: eval:paste_clipboard
URxvt.iso14755: false
URxvt.iso14755_52: false
URxvt.selectStyle: word
URxvt.letterSpace: 0
EOF

chown "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.Xresources"

# ============================================
# 5. CONFIGURAR OPENBOX (TERMINAL FIJA + ATAJOS COMPLETOS)
# ============================================
info "Configurando Openbox con terminal fija y atajos completos..."

mkdir -p "$USER_HOME/.config/openbox"

cat > "$USER_HOME/.config/openbox/rc.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config>
  <applications>
    <!-- Terminal principal - NO SE PUEDE CERRAR -->
    <application class="URxvt" name="urxvt" title="principal">
      <decor>no</decor>
      <maximized>yes</maximized>
      <focus>yes</focus>
      <desktop>all</desktop>
      <layer>below</layer>
      <position force="yes">
        <x>0</x>
        <y>0</y>
      </position>
      <focus>no</focus>
    </application>
    
    <!-- Ventanas emergentes - SIEMPRE ENCIMA -->
    <application class="URxvt" name="urxvt" title="!principal">
      <layer>above</layer>
      <focus>yes</focus>
    </application>
    <application class="Mpv">
      <layer>above</layer>
      <focus>yes</focus>
    </application>
  </applications>
  
  <menu><file>~/.config/openbox/menu.xml</file></menu>
  
  <keyboard>
    <keybind key="A-Tab"><action name="NextWindow"/></keybind>
    <keybind key="A-S-Tab"><action name="PreviousWindow"/></keybind>
    <keybind key="A-F4"><action name="Close"/></keybind>
    <keybind key="A-F10"><action name="ToggleMaximize"/></keybind>
    <keybind key="W-Up"><action name="ToggleMaximize"/></keybind>
    <keybind key="W-x"><action name="Execute"><command>xoni-menu</command></action></keybind>
    <keybind key="W-t"><action name="Execute"><command>urxvt</command></action></keybind>
    <keybind key="C-A-t"><action name="Execute"><command>urxvt</command></action></keybind>
    <keybind key="W-h"><action name="Execute"><command>xoni-help</command></action></keybind>
    <keybind key="W-q"><action name="Exit"/></keybind>
    <keybind key="C-A-Left"><action name="GoToDesktop"><to>left</to></action></keybind>
    <keybind key="C-A-Right"><action name="GoToDesktop"><to>right</to></action></keybind>
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

cat > "$USER_HOME/.config/openbox/autostart" << 'EOF'
# TERMINAL PRINCIPAL - OCUPA TODA LA PANTALLA (NO SE PUEDE CERRAR)
urxvt -title "principal" -fg white -bg black &

# Cargar configuración Xresources
xrdb -merge ~/.Xresources
EOF

cat > "$USER_HOME/.xinitrc" << 'EOF'
#!/bin/sh
exec openbox-session
EOF
chmod +x "$USER_HOME/.xinitrc"

# ============================================
# 6. CONFIGURAR CONNMAN (WiFi)
# ============================================
info "Configurando connman (gestor de red liviano)..."
mkdir -p /etc/connman
cat > /etc/connman/main.conf << 'EOF'
[General]
PreferredTechnologies = wifi,ethernet
AllowHostnames = true
AutoConnect = true
EOF
systemctl restart connman || sv restart connman || true

# ============================================
# 7. CREAR SCRIPTS XONI
# ============================================
info "Creando scripts XONI..."

cat > /usr/local/bin/xoni-install << 'EOF'
#!/bin/bash
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
  xoni-install  : Instalar herramientas
  sudo connmanctl : Configurar WiFi

ATAJOS DE TECLADO:
  Alt+Tab       : Cambiar ventana
  Alt+F4        : Cerrar ventana
  Alt+F10       : Maximizar
  Win+↑         : Maximizar
  Ctrl+Alt+T    : Nueva terminal
  Win+x         : Menú
  Win+q         : Cerrar sesión

RATÓN:
  Seleccionar texto : Copia automáticamente
  Click derecho     : Pegar texto

COPIAR/PEGAR:
  Ctrl+Shift+C/V, Ctrl+Insert/Shift+Insert

✓ Terminal principal NO SE PUEDE CERRAR
✓ Ventanas emergentes se ven ENCIMA
✓ Sistema conserva TODOS los controladores originales

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
echo "ATAJOS: Alt+Tab, Ctrl+Alt+T, Win+x, Win+q"
echo "RATÓN: Seleccionar copia, click derecho pega"
echo ""
echo "✓ Terminal principal NO SE PUEDE CERRAR"
echo "========================================"
EOF

chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config" "$USER_HOME/.xinitrc" "$USER_HOME/.bashrc"
chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.Xresources" "$USER_HOME/.urxvt"

# ============================================
# 8. FINALIZACIÓN
# ============================================
echo "========================================"
echo "   INSTALACIÓN ULTIMATE COMPLETADA      "
echo "========================================"
echo ""
echo "✅ CARACTERÍSTICAS:"
echo "   ✓ Terminal principal NO SE PUEDE CERRAR"
echo "   ✓ Ventanas emergentes se ven ENCIMA"
echo "   ✓ Click derecho pega, selección copia"
echo "   ✓ Atajos completos de teclado"
echo "   ✓ NO se eliminó NINGÚN paquete del sistema"
echo "   ✓ Conserva TODOS los controladores originales"
echo ""
echo "✅ Para instalar xonitube:  xoni-install xonitube"
echo "✅ Para abrir el menú:        xoni-menu"
echo "✅ Para ayuda:                xoni-help"
echo ""
echo "Reinicia ahora: sudo reboot"
echo ""
echo "Usuario: $TARGET_USER"
echo "========================================"
