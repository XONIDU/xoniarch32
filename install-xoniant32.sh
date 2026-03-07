#!/bin/bash
# xoniant32 – Instalador desde live USB de antiX
# Autor: Darian Alberto Camacho Salas
# Repositorio: https://github.com/XONIDU/xoniant32
#
# Este script debe ejecutarse desde el entorno live de antiX (32 bits).
# Realiza la instalación completa en el disco seleccionado y aplica la personalización XONI.

set -euo pipefail
trap 'echo -e "\033[0;31m[ERROR] Falló en la línea $LINENO\033[0m" >&2' ERR

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

error_exit() { echo -e "${RED}[ERROR] $1${NC}" >&2; exit 1; }
info()  { echo -e "${GREEN}[INFO] $1${NC}"; }
warn()  { echo -e "${YELLOW}[AVISO] $1${NC}"; }

# ============================================
# 1. Verificar entorno live de antiX
# ============================================
clear
echo "========================================"
echo "   XONIANT32 - INSTALADOR DESDE LIVE   "
echo "   Basado en antiX Linux                "
echo "========================================"
echo ""

if [ ! -f /etc/antix-version ]; then
    error_exit "Este script debe ejecutarse desde el live USB de antiX Linux."
fi

# ============================================
# 2. Preguntar configuración regional
# ============================================
echo "========================================"
echo "   CONFIGURACIÓN REGIONAL               "
echo "========================================"
echo ""

read -p "Región (ej: America) [America]: " ZONE_REGION
ZONE_REGION=${ZONE_REGION:-America}

read -p "Ciudad (ej: Mexico_City) [Mexico_City]: " ZONE_CITY
ZONE_CITY=${ZONE_CITY:-Mexico_City}
TIMEZONE="$ZONE_REGION/$ZONE_CITY"

read -p "Idioma del sistema (ej: es_MX.UTF-8) [es_MX.UTF-8]: " LOCALE
LOCALE=${LOCALE:-es_MX.UTF-8}

read -p "Distribución de teclado (ej: es) [es]: " KEYMAP
KEYMAP=${KEYMAP:-es}

echo ""

# ============================================
# 3. Preguntar credenciales
# ============================================
echo "========================================"
echo "   CONFIGURACIÓN DE USUARIO             "
echo "========================================"
echo ""

read -p "Nombre del equipo (hostname) [xoniant32]: " HOSTNAME
HOSTNAME=${HOSTNAME:-xoniant32}

read -p "Nombre de usuario [xoniarch]: " USERNAME
USERNAME=${USERNAME:-xoniarch}

while true; do
    read -s -p "Contraseña para $USERNAME: " PASSWORD1
    echo
    read -s -p "Repite la contraseña: " PASSWORD2
    echo
    if [ "$PASSWORD1" = "$PASSWORD2" ] && [ -n "$PASSWORD1" ]; then
        PASSWORD="$PASSWORD1"
        break
    else
        echo "Las contraseñas no coinciden o están vacías. Intenta de nuevo."
    fi
done
echo ""

# ============================================
# 4. Seleccionar disco de instalación
# ============================================
echo "========================================"
echo "   SELECCIÓN DE DISCO                   "
echo "========================================"
echo ""

lsblk -d -o NAME,SIZE,MODEL,TYPE | grep -E "disk|NAME"
echo ""
read -p "¿En qué disco instalar? (ej: sda): " DISK
[ -z "$DISK" ] && error_exit "No se seleccionó ningún disco."
[ ! -b "/dev/$DISK" ] && error_exit "El disco /dev/$DISK no existe."

echo ""
echo "¡ATENCION! Se borrarán TODOS los datos en /dev/$DISK"
lsblk "/dev/$DISK"
read -p "¿Estás seguro? (escribe YES): " CONFIRM
[ "$CONFIRM" != "YES" ] && error_exit "Instalación cancelada."

# ============================================
# 5. Particionado automático
# ============================================
echo ""
echo "========================================"
echo "   PARTICIONADO                         "
echo "========================================"
echo ""

read -p "¿Crear partición swap? (s/n): " SWAP_OPT
if [[ "$SWAP_OPT" =~ ^[Ss]$ ]]; then
    read -p "Tamaño de swap en GB (ej: 1): " SWAP_SIZE
    SWAP_SIZE=${SWAP_SIZE:-1}
    info "Particionando con swap de ${SWAP_SIZE}G..."
    parted "/dev/$DISK" mklabel msdos
    parted "/dev/$DISK" mkpart primary linux-swap 1MiB "${SWAP_SIZE}GiB"
    parted "/dev/$DISK" mkpart primary ext4 "${SWAP_SIZE}GiB" 100%
    parted "/dev/$DISK" set 2 boot on
    ROOT_PART="${DISK}2"
    SWAP_PART="${DISK}1"
else
    info "Particionando sin swap..."
    parted "/dev/$DISK" mklabel msdos
    parted "/dev/$DISK" mkpart primary ext4 1MiB 100%
    parted "/dev/$DISK" set 1 boot on
    ROOT_PART="${DISK}1"
    SWAP_PART=""
fi

info "Formateando particiones..."
mkfs.ext4 -F "/dev/$ROOT_PART"
[ -n "$SWAP_PART" ] && mkswap "/dev/$SWAP_PART"

info "Montando sistema en /mnt..."
mount "/dev/$ROOT_PART" /mnt
[ -n "$SWAP_PART" ] && swapon "/dev/$SWAP_PART" 2>/dev/null || true

# ============================================
# 6. Copiar sistema live al destino (excluyendo sistemas de archivos virtuales)
# ============================================
info "Copiando sistema live al disco de destino (puede tardar varios minutos)..."
rsync -aAXv / --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} /mnt/ || error_exit "Falló la copia del sistema."

# ============================================
# 7. Preparar el sistema para el chroot
# ============================================
info "Montando sistemas virtuales para el chroot..."
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys

# ============================================
# 8. Configurar sistema base dentro del chroot
# ============================================
info "Configurando el sistema dentro del chroot..."

cat > /mnt/tmp/chroot-config.sh << CONFIG
#!/bin/bash
# Zona horaria
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Localización
echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
update-locale LANG=$LOCALE

# Teclado
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "XKBLAYOUT=$KEYMAP" > /etc/default/keyboard
dpkg-reconfigure keyboard-configuration -f noninteractive

# Hostname
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts << HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
HOSTS

# Usuario y sudo
useradd -m -G sudo -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
echo "root:$PASSWORD" | chpasswd

# Habilitar sudo para el grupo sudo
sed -i 's/^# %sudo ALL=(ALL:ALL) ALL/%sudo ALL=(ALL:ALL) ALL/' /etc/sudoers

# Actualizar repositorios
apt update

# Instalar paquetes adicionales (Xorg, Openbox, herramientas, gestores de display)
apt install -y git curl wget htop neofetch build-essential
apt install -y xorg openbox obconf tint2 feh picom rxvt-unicode pcmanfm
apt install -y alsa-utils pulseaudio pavucontrol
apt install -y lightdm lightdm-gtk-greeter sddm lxdm slim
apt install -y network-manager nmtui
apt install -y mpv ffmpeg yt-dlp

# Configurar auto-login en lightdm (si está instalado)
if [ -f /etc/lightdm/lightdm.conf ]; then
    mkdir -p /etc/lightdm/lightdm.conf.d
    cat > /etc/lightdm/lightdm.conf.d/autologin.conf << LIGHTDM
[Seat:*]
autologin-user=$USERNAME
autologin-session=openbox
LIGHTDM
fi

# Configurar SDDM (si está instalado)
if [ -d /etc/sddm.conf.d ]; then
    mkdir -p /etc/sddm.conf.d
    cat > /etc/sddm.conf.d/autologin.conf << SDDM
[Autologin]
User=$USERNAME
Session=openbox.desktop
SDDM
fi

# Configurar LXDM (si está instalado)
if [ -f /etc/lxdm/lxdm.conf ]; then
    sed -i "s/^# autologin=.*/autologin=$USERNAME/" /etc/lxdm/lxdm.conf
fi

# Configurar SLiM (si está instalado)
if [ -f /etc/slim.conf ]; then
    echo "default_user $USERNAME" >> /etc/slim.conf
    echo "auto_login yes" >> /etc/slim.conf
fi

# Habilitar el primer gestor de display encontrado
DM_SERVICE=""
for svc in lightdm sddm lxdm slim; do
    if systemctl list-unit-files | grep -q "$svc.service"; then
        DM_SERVICE="$svc"
        systemctl enable "$svc"
        echo "Gestor de display habilitado: $svc"
        break
    fi
done

if [ -z "$DM_SERVICE" ]; then
    echo "No se instaló ningún gestor de display. Se usará startx manual."
fi

# Habilitar NetworkManager
systemctl enable NetworkManager

# ============================================
# Configurar Openbox con terminal fija
# ============================================
mkdir -p /home/$USERNAME/.config/openbox
cat > /home/$USERNAME/.config/openbox/rc.xml << 'EOF'
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

cat > /home/$USERNAME/.config/openbox/menu.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<openbox_menu>
  <menu id="root-menu" label="Xoniant32">
    <item label="Nueva terminal"><action name="Execute"><command>urxvt</command></action></item>
    <item label="Instalar herramienta XONI"><action name="Execute"><command>urxvt -e installxoni</command></action></item>
    <item label="Configurar red"><action name="Execute"><command>urxvt -e nmtui</command></action></item>
    <item label="Monitor sistema"><action name="Execute"><command>urxvt -e htop</command></action></item>
    <item label="Ayuda"><action name="Execute"><command>urxvt -e xoniarch-help</command></action></item>
    <item label="Cerrar sesión"><action name="Exit"/></item>
  </menu>
</openbox_menu>
EOF

cat > /home/$USERNAME/.config/openbox/autostart << 'EOF'
# TERMINAL PRINCIPAL (NO SE PUEDE CERRAR)
urxvt -title "principal" &
feh --bg-scale /usr/share/backgrounds/default.jpg &
picom -b &
tint2 &
EOF

cat > /home/$USERNAME/.xinitrc << 'EOF'
#!/bin/sh
exec openbox-session
EOF
chmod +x /home/$USERNAME/.xinitrc

chown -R $USERNAME:$USERNAME /home/$USERNAME/.config
chown $USERNAME:$USERNAME /home/$USERNAME/.xinitrc

# ============================================
# Crear scripts XONI
# ============================================
mkdir -p /usr/local/bin

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
  nmtui                      : Configurar red
  htop                       : Monitor del sistema

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
    echo "3) Configurar red (nmtui)"
    echo "4) Monitor del sistema (htop)"
    echo "5) Ayuda"
    echo "6) Cerrar sesión"
    echo ""
    read -p "Opción [1-6]: " opt
    case $opt in
        1) urxvt ;;
        2) urxvt -e installxoni ; read -p "Presiona Enter..." ;;
        3) urxvt -e nmtui ;;
        4) urxvt -e htop ;;
        5) xoniarch-help ; read -p "Presiona Enter..." ;;
        6) openbox --exit ;;
        *) echo "Opción inválida"; sleep 2 ;;
    esac
done
EOF

chmod +x /usr/local/bin/*

# ============================================
# Configurar .bashrc para el usuario
# ============================================
cat >> /home/$USERNAME/.bashrc << 'BASHRC'
alias ll='ls -la'
alias la='ls -A'
alias update='xoniarch-update'
alias menu='xoniarch-menu'
alias help='xoniarch-help'
PS1='\[\e[1;32m\][\u@\h \W]\$ \[\e[0m\]'
BASHRC

chown $USERNAME:$USERNAME /home/$USERNAME/.bashrc

# ============================================
# Generar fstab
# ============================================
cat > /etc/fstab << FSTAB
# /etc/fstab: información del sistema de archivos
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
$(blkid -s UUID -o value "/dev/$ROOT_PART") / ext4 defaults 0 1
EOF

[ -n "$SWAP_PART" ] && echo "$(blkid -s UUID -o value "/dev/$SWAP_PART") none swap sw 0 0" >> /etc/fstab

CONFIG

chmod +x /mnt/tmp/chroot-config.sh
chroot /mnt /tmp/chroot-config.sh

# ============================================
# 9. Instalar GRUB (usando UUID para mayor compatibilidad)
# ============================================
info "Instalando GRUB..."
chroot /mnt grub-install --target=i386-pc "/dev/$DISK"
chroot /mnt update-grub

# ============================================
# 10. Preguntar por creación de ISO personalizada
# ============================================
echo ""
info "¿Quieres crear una ISO personalizada de xoniant32?"
echo "Esto usará la herramienta remaster-live de antiX"
read -p "¿Crear ISO? (s/n): " CREATE_ISO

if [[ "$CREATE_ISO" =~ ^[Ss]$ ]]; then
    info "Preparando remasterización..."
    echo ""
    echo "Pasos a seguir:"
    echo "1. El script remaster-live se ejecutará automáticamente"
    echo "2. Guardará tu sistema personalizado como una nueva ISO"
    echo ""
    read -p "Presiona Enter para continuar..."
    
    chroot /mnt remaster-live
fi

# ============================================
# 11. Limpieza y desmontaje
# ============================================
info "Desmontando sistemas..."
umount /mnt/dev
umount /mnt/proc
umount /mnt/sys
umount /mnt
[ -n "$SWAP_PART" ] && swapoff "/dev/$SWAP_PART" 2>/dev/null || true

echo "========================================"
echo "   INSTALACIÓN COMPLETADA               "
echo "========================================"
echo ""
echo "El sistema ARRANCARÁ DIRECTAMENTE EN MODO GRÁFICO"
echo "Terminal principal FIJA (no se puede cerrar)"
echo ""
echo "Reinicia con: sudo reboot"
echo ""
echo "Usuario: $USERNAME | Contraseña: la que elegiste"
echo "Root:    root     | Contraseña: la misma"
echo ""
echo "Múltiples gestores instalados: lightdm, sddm, lxdm, slim"
echo "Si uno falla, el siguiente intentará iniciar"
echo "¡Disfruta xoniant32!"
