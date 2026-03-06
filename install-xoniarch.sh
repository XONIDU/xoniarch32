#!/bin/bash
# XONIARCH32 - INSTALADOR ÚNICO Y COMPLETO
# Autor: Darian Alberto Camacho Salas
# Este script contiene TODO lo necesario para instalar Xoniarch32

set -euo pipefail
trap 'echo -e "\033[0;31m[ERROR] Falló en la línea $LINENO\033[0m" >&2' ERR

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

error_exit() { echo -e "${RED}[ERROR] $1${NC}" >&2; exit 1; }
info() { echo -e "${GREEN}[INFO] $1${NC}"; }
warn() { echo -e "${YELLOW}[AVISO] $1${NC}"; }

# ============================================
# 1. VERIFICAR ENTORNO LIVE
# ============================================
if [ ! -d /run/archiso ]; then
    error_exit "Este script debe ejecutarse desde el live USB de Arch Linux 32 bits."
fi

# ============================================
# 2. SELECCIONAR DISCO
# ============================================
clear
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   XONIARCH32 - INSTALADOR COMPLETO    ${NC}"
echo -e "${GREEN}========================================${NC}\n"
echo -e "${YELLOW}Discos disponibles:${NC}"
lsblk -d -o NAME,SIZE,MODEL,TYPE | grep -E "disk|NAME"
echo ""
read -p "¿En qué disco quieres instalar? (ej: sda): " DISK
[ -z "$DISK" ] && error_exit "No se seleccionó ningún disco."
[ ! -b "/dev/$DISK" ] && error_exit "El disco /dev/$DISK no existe."

echo ""
echo -e "${RED}¡ATENCIÓN! Se borrarán TODOS los datos en /dev/$DISK${NC}"
lsblk "/dev/$DISK"
read -p "¿Estás seguro? (escribe YES): " CONFIRM
[ "$CONFIRM" != "YES" ] && error_exit "Instalación cancelada."

# ============================================
# 3. PARTICIONADO
# ============================================
echo ""
echo "Elige particionado:"
echo "1) Automático (swap opcional)"
echo "2) Manual (fdisk)"
read -p "Opción [1/2]: " PART_OPT

if [ "$PART_OPT" = "1" ]; then
    read -p "¿Crear swap? (s/n): " SWAP_OPT
    if [[ "$SWAP_OPT" =~ ^[Ss]$ ]]; then
        read -p "Tamaño swap en GB (ej: 1): " SWAP_SIZE
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
    mkfs.ext4 -F "/dev/$ROOT_PART"
    [ -n "$SWAP_PART" ] && mkswap "/dev/$SWAP_PART"
else
    info "Abriendo fdisk. Cuando termines, escribe 'exit'."
    fdisk "/dev/$DISK"
    lsblk "/dev/$DISK"
    read -p "Partición raíz (ej: ${DISK}2): " ROOT_PART
    read -p "Partición swap (vacío si no): " SWAP_PART
fi

# Montar
info "Montando sistema..."
mount "/dev/$ROOT_PART" /mnt
[ -n "$SWAP_PART" ] && swapon "/dev/$SWAP_PART" 2>/dev/null || true

# ============================================
# 4. CONFIGURAR PACMAN Y MIRRORS
# ============================================
info "Configurando mirrors..."
MIRRORS=(
    "https://mirror.archlinux32.org"
    "https://ftp.halifax.rwth-aachen.de/archlinux32"
    "https://mirror.cyberbits.eu/archlinux32"
)
WORKING_MIRROR=""
for mirror in "${MIRRORS[@]}"; do
    echo -n "Probando $mirror... "
    if curl -s --head --max-time 5 "${mirror}/core/os/i686/core.db" >/dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
        WORKING_MIRROR="$mirror"
        break
    else
        echo -e "${RED}FALLÓ${NC}"
    fi
done
WORKING_MIRROR=${WORKING_MIRROR:-"https://mirror.archlinux32.org"}

cat > /etc/pacman.conf << EOF
[options]
Architecture = i686
SigLevel = Never
LocalFileSigLevel = Never
RemoteFileSigLevel = Never
ParallelDownloads = 5
[core]
Server = $WORKING_MIRROR/\$arch/\$repo
[extra]
Server = $WORKING_MIRROR/\$arch/\$repo
[community]
Server = $WORKING_MIRROR/\$arch/\$repo
EOF

# Claves PGP
pacman-key --init 2>/dev/null || true
pacman-key --populate archlinux32 2>/dev/null || true
pacman -Sy --noconfirm archlinux32-keyring 2>/dev/null || true

# ============================================
# 5. INSTALAR SISTEMA BASE
# ============================================
info "Instalando sistema base (puede tardar)..."
pacstrap /mnt base base-devel linux-firmware grub networkmanager nano sudo git

# ============================================
# 6. CONFIGURACIÓN BÁSICA
# ============================================
info "Configurando sistema básico..."
genfstab -U /mnt >> /mnt/etc/fstab

# Crear script de configuración
cat > /mnt/root/chroot-config.sh << 'CONFIG'
#!/bin/bash
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc
echo "es_MX.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=es_MX.UTF-8" > /etc/locale.conf
echo "KEYMAP=es" > /etc/vconsole.conf
echo "xoniarch" > /etc/hostname
cat > /etc/hosts << HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   xoniarch.localdomain xoniarch
HOSTS
useradd -m -G wheel -s /bin/bash xoniarch
echo "xoniarch:xoniarch" | chpasswd
echo "root:root" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
systemctl enable NetworkManager
CONFIG

chmod +x /mnt/root/chroot-config.sh
arch-chroot /mnt /root/chroot-config.sh

# ============================================
# 7. INSTALAR GRUB
# ============================================
arch-chroot /mnt grub-install --target=i386-pc "/dev/$DISK"
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# ============================================
# 8. PERSONALIZACIÓN XONIARCH32 (TODO INCLUIDO)
# ============================================
info "Aplicando personalización Xoniarch32..."

# Crear estructura de directorios
arch-chroot /mnt mkdir -p /usr/local/bin /opt/xoniarch/bin /etc/skel/.config/openbox
arch-chroot /mnt mkdir -p /etc/skel/.config/tint2 /usr/share/backgrounds

# ============================================
# 8.1 INSTALAR PAQUETES ADICIONALES
# ============================================
info "Instalando paquetes adicionales..."
arch-chroot /mnt pacman -S --noconfirm \
    xorg-server xorg-xinit xorg-xrandr xterm \
    openbox obconf tint2 feh picom nitrogen \
    rxvt-unicode pcmanfm ranger geany mousepad \
    firefox mpv vlc ffmpeg yt-dlp \
    alsa-utils pulseaudio pavucontrol \
    xf86-video-intel xf86-video-vesa mesa \
    sddm tlp acpi acpid lm_sensors

# Habilitar servicios
arch-chroot /mnt systemctl enable sddm
arch-chroot /mnt systemctl enable tlp
arch-chroot /mnt systemctl enable acpid

# ============================================
# 8.2 CONFIGURACIÓN DE OPENBOX (TERMINAL FIJA)
# ============================================
cat > /mnt/etc/skel/.config/openbox/rc.xml << 'EOF'
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

cat > /mnt/etc/skel/.config/openbox/menu.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<openbox_menu>
  <menu id="root-menu" label="Xoniarch32">
    <item label="Nueva terminal"><action name="Execute"><command>urxvt</command></action></item>
    <item label="Instalar herramienta XONI"><action name="Execute"><command>urxvt -e installxoni</command></action></item>
    <item label="Configurar red"><action name="Execute"><command>urxvt -e nmtui</command></action></item>
    <item label="Monitor sistema"><action name="Execute"><command>urxvt -e htop</command></action></item>
    <item label="Ayuda"><action name="Execute"><command>urxvt -e xoniarch-help</command></action></item>
    <item label="Cerrar sesión"><action name="Exit"/></item>
  </menu>
</openbox_menu>
EOF

cat > /mnt/etc/skel/.config/openbox/autostart << 'EOF'
feh --bg-scale /usr/share/backgrounds/default.jpg &
picom -b &
tint2 &
urxvt -title "principal" &
EOF

cat > /mnt/etc/skel/.xinitrc << 'EOF'
#!/bin/sh
exec openbox-session
EOF

# ============================================
# 8.3 CONFIGURACIÓN DE TINT2
# ============================================
cat > /mnt/etc/skel/.config/tint2/tint2rc << 'EOF'
panel_items = LTSC
panel_size = 100% 30
panel_margin = 0 0
panel_padding = 2 2
font = Sans 9
background_color = #000000 80
taskbar_mode = multi_desktop
clock_format = %H:%M
EOF

# ============================================
# 8.4 SCRIPTS PRINCIPALES XONIARCH
# ============================================
cat > /mnt/usr/local/bin/installxoni << 'EOF'
#!/bin/bash
REPO_BASE="https://github.com/XONIDU"
DIR="/opt/xoniarch"
[ ! -d "$DIR" ] && mkdir -p "$DIR"
cd "$DIR"
if [ -z "$1" ]; then
    read -p "Herramienta a instalar: " TOOL
else
    TOOL="$1"
fi
if [ -d "$TOOL" ]; then
    cd "$TOOL" && git pull && cd ..
else
    git clone "$REPO_BASE/$TOOL.git"
fi
find "$TOOL" -name "*.py" -o -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
for f in $(find "$TOOL" -maxdepth 2 -name "*.py" -o -name "*.sh" 2>/dev/null | grep -v "__"); do
    ln -sf "$(pwd)/$f" "/usr/local/bin/$(basename $f .py)" 2>/dev/null || true
done
echo "✓ $TOOL instalado"
EOF

cat > /mnt/usr/local/bin/xoniarch-update << 'EOF'
#!/bin/bash
cd /opt/xoniarch
for tool in */; do
    [ -d "$tool" ] && (cd "$tool" && git pull)
done
echo "✓ Actualización completada"
EOF

cat > /mnt/usr/local/bin/xoniarch-help << 'EOF'
#!/bin/bash
cat << 'HELP'
╔════════════════════════════════════╗
║    XONIARCH32 - AYUDA              ║
╚════════════════════════════════════╝
COMANDOS:
  installxoni <herramienta>  : Instalar herramienta XONI
  xoniarch-update            : Actualizar todo
  xoniarch-menu               : Menú interactivo
  nmtui                       : Configurar red
  htop                        : Monitor sistema
ATAJOS:
  Win+x : Menú | Win+t : Terminal | Win+h : Ayuda
USUARIO: xoniarch / Contraseña: xoniarch
HELP
EOF

cat > /mnt/usr/local/bin/xoniarch-menu << 'EOF'
#!/bin/bash
while true; do
    clear
    echo "========================================"
    echo "      XONIARCH32 - MENÚ"
    echo "========================================"
    echo "1) Nueva terminal"
    echo "2) Instalar herramienta XONI"
    echo "3) Configurar red"
    echo "4) Monitor sistema"
    echo "5) Ayuda"
    echo "6) Cerrar sesión"
    read -p "Opción [1-6]: " opt
    case $opt in
        1) urxvt ;;
        2) urxvt -e installxoni ; read -p "Enter..." ;;
        3) urxvt -e nmtui ;;
        4) urxvt -e htop ;;
        5) xoniarch-help ; read -p "Enter..." ;;
        6) openbox --exit ;;
        *) echo "Opción inválida"; sleep 2 ;;
    esac
done
EOF

chmod -R +x /mnt/usr/local/bin/

# ============================================
# 8.5 SDDM AUTO-LOGIN
# ============================================
mkdir -p /mnt/etc/sddm.conf.d
cat > /mnt/etc/sddm.conf.d/autologin.conf << EOF
[Autologin]
User=xoniarch
Session=openbox.desktop
EOF

# ============================================
# 8.6 .bashrc PERSONALIZADO
# ============================================
cat > /mnt/etc/skel/.bashrc << 'EOF'
alias ll='ls -la'
alias la='ls -A'
alias update='xoniarch-update'
alias menu='xoniarch-menu'
alias help='xoniarch-help'
PS1='\[\e[1;32m\][\u@Xoniarch32 \W]\$ \[\e[0m\]'
EOF
cp /mnt/etc/skel/.bashrc /mnt/home/xoniarch/ 2>/dev/null || true

# ============================================
# 8.7 MENSAJE DE BIENVENIDA
# ============================================
cat > /mnt/etc/motd << 'EOF'
╔════════════════════════════════════╗
║    XONIARCH32 - LISTO              ║
║    by Darian Alberto Camacho Salas ║
╚════════════════════════════════════╝
Usuario: xoniarch / Contraseña: xoniarch
Comandos: xoniarch-help
Reinicia: sudo reboot
EOF

# ============================================
# 9. LIMPIEZA Y FINALIZACIÓN
# ============================================
rm -f /mnt/root/chroot-config.sh
umount -R /mnt 2>/dev/null || true
[ -n "$SWAP_PART" ] && swapoff "/dev/$SWAP_PART" 2>/dev/null || true

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   INSTALACIÓN COMPLETADA              ${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Reinicia: sudo reboot"
echo "Usuario: xoniarch | Contraseña: xoniarch"
echo "Root: root | Contraseña: root"
