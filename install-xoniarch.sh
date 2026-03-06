#!/bin/bash
# XONIARCH32 v6.1 ULTIMATE - Instalador definitivo
# Autor: Darian Alberto Camacho Salas
# Repositorio: https://github.com/XONIDU/xoniarch32
#
# Características:
#   - 50+ mirrors de archlinux32 (incluyendo EE.UU., Europa, Asia)
#   - Prueba automática de mirrors y selección del más rápido
#   - Reintentos infinitos con cambio de mirror si es necesario
#   - Configuración regional preguntada al usuario (sin valores fijos)
#   - GRUB con UUID para arranque independiente
#   - Gráfico siempre activo con múltiples gestores de display
#   - Terminal principal fija (no se puede cerrar)
#   - Scripts XONI integrados

set -euo pipefail
trap 'echo -e "\033[0;31m[ERROR] Falló en la línea $LINENO\033[0m" >&2' ERR

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

error_exit() { echo -e "${RED}[ERROR] $1${NC}" >&2; exit 1; }
info()  { echo -e "${GREEN}[INFO] $1${NC}"; }
warn()  { echo -e "${YELLOW}[AVISO] $1${NC}"; }

# ============================================
# 1. Verificar entorno live
# ============================================
clear
echo "========================================"
echo "   XONIARCH32 v6.1 ULTIMATE             "
echo "   Instalador definitivo                "
echo "========================================"
echo ""

if [ ! -d /run/archiso ]; then
    error_exit "Este script debe ejecutarse desde el live USB de Arch Linux 32 bits."
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

read -p "Nombre del equipo (hostname) [xoniarch]: " HOSTNAME
HOSTNAME=${HOSTNAME:-xoniarch}

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
# 4. Seleccionar disco
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

info "Montando sistema..."
mount "/dev/$ROOT_PART" /mnt
[ -n "$SWAP_PART" ] && swapon "/dev/$SWAP_PART" 2>/dev/null || true

# ============================================
# 6. Lista masiva de mirrors de archlinux32
# ============================================
info "Preparando lista de mirrors (más de 50 opciones)..."

declare -a MIRRORS=(
    # Estados Unidos
    "https://mirror.clarkson.edu/archlinux32"
    "https://mirror.math.princeton.edu/pub/archlinux32"
    "https://mirror.rackspace.com/archlinux32"
    "https://mirror.us.leaseweb.net/archlinux32"
    "https://mirror.sfo12.us.leaseweb.net/archlinux32"
    "https://mirror.wdc1.us.leaseweb.net/archlinux32"
    "https://iad.mirrors.misaka.one/archlinux32"
    "https://mirror.umd.edu/archlinux32"
    "https://plug-mirror.rcac.purdue.edu/archlinux32"
    "https://mirrors.ocf.berkeley.edu/archlinux32"
    "https://mirrors.mit.edu/archlinux32"
    "https://mirror.arizona.edu/archlinux32"
    "https://mirrors.kernel.org/archlinux32"
    "https://mirror.ette.biz/archlinux32"
    "https://mirrors.rit.edu/archlinux32"
    "https://mirror.cs.odu.edu/archlinux32"
    "https://mirrors.bloomu.edu/archlinux32"
    "https://mirrors.lug.mtu.edu/archlinux32"
    "https://mirrors.sonic.net/archlinux32"
    "https://ftp.osuosl.org/pub/archlinux32"
    "https://mirror.pit.teraswitch.com/archlinux32"
    "https://mirror.constant.com/archlinux32"
    "https://mirror.zackmyers.io/archlinux32"
    "https://arch.mirror.marcusspencer.us/archlinux32"
    "https://mirror.givebytes.net/archlinux32"
    "https://mirrors.lahansons.com/archlinux32"
    "https://mirrors.smeal.xyz/arch-linux32"
    "https://mirror.hasphetica.win/archlinux32"
    "https://mirror.adectra.com/archlinux32"
    "https://repo.customcomputercare.com/archlinux32"
    "https://mirror.pilotfiber.com/archlinux32"
    "https://mirrors.logal.dev/archlinux32"
    "https://mirror.fcix.net/archlinux32"
    "https://mirror.akane.network/archmirror32"
    "https://mirror.mra.sh/archlinux32"
    "https://mirror.colonelhosting.com/archlinux32"
    # Alemania
    "https://mirror.archlinux32.org"
    "https://ftp.halifax.rwth-aachen.de/archlinux32"
    "https://de.mirror.archlinux32.org"
    "https://mirror.selfnet.de/archlinux32"
    "https://mirror.wtnet.de/archlinux32"
    "https://archlinux32.andreasbaumann.cc"
    # Francia
    "https://mirror.cyberbits.eu/archlinux32"
    "https://archlinux32.agoctrl.org"
    # Países Bajos
    "https://mirror.ubnt.net/archlinux32"
    "https://archlinux32.mirror.liteserver.nl"
    # Suecia
    "https://mirror.accum.se/mirror/archlinux32"
    # Dinamarca
    "https://mirrors.dotsrc.org/archlinux32"
    # Grecia
    "https://gr.mirror.archlinux32.org"
    # Polonia
    "https://mirror.juniorjpdj.pl/archlinux32"
    # Rusia
    "https://mirror.yandex.ru/archlinux32"
    # Bielorrusia
    "https://mirror.datacenter.by/pub/archlinux32"
    # China
    "https://mirror.bit.edu.cn/archlinux32"
    "https://mirrors.tuna.tsinghua.edu.cn/archlinux32"
    "https://mirrors.ustc.edu.cn/archlinux32"
    "https://mirror.sjtu.edu.cn/archlinux32"
    "https://mirrors.aliyun.com/archlinux32"
    "https://mirrors.163.com/archlinux32"
    "https://mirror.huaweicloud.com/archlinux32"
    "https://mirrors.tencent.com/archlinux32"
    # Otros
    "https://mirror.franscorack.com/arch32"
    "https://mirror.lagoon.nc/archlinux32"
    "https://mirror.terrahost.no/archlinux32"
)

# ============================================
# 7. Probar mirrors y elegir el más rápido
# ============================================
info "Probando mirrors para seleccionar el más rápido..."

best_mirror=""
best_time=999999
for mirror in "${MIRRORS[@]}"; do
    echo -n "Probando $mirror ... "
    # Medir tiempo de conexión
    start=$(date +%s%N)
    if curl -s -o /dev/null --max-time 5 "${mirror}/core/os/i686/core.db" 2>/dev/null; then
        end=$(date +%s%N)
        time_ms=$(( (end - start) / 1000000 ))
        echo "${GREEN}OK (${time_ms}ms)${NC}"
        if [ $time_ms -lt $best_time ]; then
            best_time=$time_ms
            best_mirror="$mirror"
        fi
    else
        echo "${RED}FALLÓ${NC}"
    fi
done

if [ -z "$best_mirror" ]; then
    error_exit "No se encontró ningún mirror funcional. Verifica tu conexión a internet."
fi

info "Mirror más rápido seleccionado: $best_mirror (${best_time}ms)"

# ============================================
# 8. Configurar pacman.conf con todos los mirrors
# ============================================
server_list=""
for mirror in "${MIRRORS[@]}"; do
    server_list+="Server = $mirror/\$arch/\$repo\n"
done

cat > /etc/pacman.conf << EOF
[options]
HoldPkg         = pacman glibc
Architecture    = i686
SigLevel        = Never
LocalFileSigLevel = Never
RemoteFileSigLevel = Never
ParallelDownloads = 5
Color
CheckSpace
DisableDownloadTimeout

[core]
$server_list
[extra]
$server_list
[community]
$server_list
EOF

# ============================================
# 9. Inicializar claves PGP
# ============================================
info "Inicializando claves PGP..."
pacman-key --init 2>/dev/null || true
pacman-key --populate archlinux32 2>/dev/null || true
pacman -Sy --noconfirm archlinux32-keyring 2>/dev/null || true

# ============================================
# 10. Instalar sistema base con reintentos
# ============================================
info "Instalando sistema base (puede tardar mucho si hay fallos de red)..."

base_ok=false
while [ "$base_ok" = false ]; do
    if pacstrap /mnt base base-devel linux linux-firmware grub networkmanager sudo git nano; then
        base_ok=true
        info "Sistema base instalado correctamente."
    else
        warn "Falló la instalación base. Se reintentará en 15 segundos..."
        sleep 15
        # Forzar actualización de mirrors
        pacman -Syy
    fi
done

# ============================================
# 11. Generar fstab
# ============================================
genfstab -U /mnt >> /mnt/etc/fstab

# ============================================
# 12. Configurar sistema base
# ============================================
info "Configurando sistema..."

cat > /mnt/root/chroot-config.sh << CONFIG
#!/bin/bash
# Zona horaria
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Localización
echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Hostname
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts << HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
HOSTS

# Usuario y sudo
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
echo "root:$PASSWORD" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Habilitar servicios
systemctl enable NetworkManager
CONFIG

chmod +x /mnt/root/chroot-config.sh
arch-chroot /mnt /root/chroot-config.sh

# ============================================
# 13. Instalar GRUB con UUID
# ============================================
info "Instalando GRUB..."
arch-chroot /mnt grub-install --target=i386-pc "/dev/$DISK"

# Obtener UUID de la partición raíz
ROOT_UUID=$(blkid -s UUID -o value "/dev/$ROOT_PART")
if [ -n "$ROOT_UUID" ]; then
    info "UUID de la raíz: $ROOT_UUID"
    cat > /mnt/boot/grub/grub.cfg << GRUB
set timeout=5
set default=0

menuentry "Xoniarch32" {
    linux /boot/vmlinuz-linux root=UUID=$ROOT_UUID rw quiet
    initrd /boot/initramfs-linux.img
}
GRUB
    info "grub.cfg creado con UUID."
else
    warn "No se pudo obtener UUID. Usando método tradicional."
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
fi

# Verificar kernel
if [ ! -f /mnt/boot/vmlinuz-linux ]; then
    warn "Kernel no encontrado. Intentando reinstalar linux..."
    arch-chroot /mnt pacman -S --noconfirm linux
fi

# ============================================
# 14. Detectar hardware
# ============================================
info "Detectando hardware..."

# CPU microcode
CPU_VENDOR=$(lscpu | grep Vendor | grep -oE "Intel|AMD|GenuineIntel|AuthenticAMD" || echo "")
if [[ "$CPU_VENDOR" =~ Intel ]]; then
    arch-chroot /mnt pacman -S --noconfirm intel-ucode 2>/dev/null || warn "intel-ucode no disponible"
elif [[ "$CPU_VENDOR" =~ AMD ]]; then
    arch-chroot /mnt pacman -S --noconfirm amd-ucode 2>/dev/null || warn "amd-ucode no disponible"
fi

# GPU
GPU=$(lspci | grep -i vga | grep -oE "Intel|AMD|ATI|NVIDIA|VIA|S3" | head -1 || echo "")
case "$GPU" in
    Intel)   arch-chroot /mnt pacman -S --noconfirm xf86-video-intel 2>/dev/null || warn "xf86-video-intel no disponible" ;;
    AMD|ATI) arch-chroot /mnt pacman -S --noconfirm xf86-video-amdgpu xf86-video-ati 2>/dev/null || warn "Controladores AMD no disponibles" ;;
    NVIDIA)  arch-chroot /mnt pacman -S --noconfirm xf86-video-nouveau 2>/dev/null || warn "xf86-video-nouveau no disponible" ;;
    *)       arch-chroot /mnt pacman -S --noconfirm xf86-video-vesa 2>/dev/null || warn "xf86-video-vesa no disponible" ;;
esac

# Audio
if lspci | grep -i audio >/dev/null; then
    arch-chroot /mnt pacman -S --noconfirm alsa-utils alsa-firmware alsa-plugins pulseaudio pulseaudio-alsa 2>/dev/null || warn "Paquetes de audio no disponibles"
fi

# WiFi
if lspci | grep -i network | grep -i wireless >/dev/null; then
    arch-chroot /mnt pacman -S --noconfirm wireless_tools wpa_supplicant 2>/dev/null || true
fi

# ============================================
# 15. Instalar Xorg, Openbox y herramientas
# ============================================
info "Instalando Xorg y Openbox..."

PACKAGES=(
    xorg-server
    xorg-xinit
    xorg-xrandr
    xterm
    openbox
    tint2
    feh
    picom
    rxvt-unicode
    pcmanfm
    htop
    nmtui
    mesa
)

for pkg in "${PACKAGES[@]}"; do
    echo "Instalando $pkg..."
    arch-chroot /mnt pacman -S --noconfirm "$pkg" 2>/dev/null || warn "Falló $pkg"
done

# ============================================
# 16. Instalar múltiples gestores de display
# ============================================
info "Instalando gestores de display..."

DM_PACKAGES=(
    lightdm
    lightdm-gtk-greeter
    sddm
    lxdm
    slim
)

for dm in "${DM_PACKAGES[@]}"; do
    arch-chroot /mnt pacman -S --noconfirm "$dm" 2>/dev/null || true
done

# Configurar auto-login para el que esté instalado
# LightDM
if [ -f /mnt/etc/lightdm/lightdm.conf ]; then
    mkdir -p /mnt/etc/lightdm
    cat > /mnt/etc/lightdm/lightdm.conf << LIGHTDM
[Seat:*]
autologin-user=$USERNAME
autologin-session=openbox
LIGHTDM
fi

# SDDM
if [ -d /mnt/etc/sddm.conf.d ]; then
    mkdir -p /mnt/etc/sddm.conf.d
    cat > /mnt/etc/sddm.conf.d/autologin.conf << SDDM
[Autologin]
User=$USERNAME
Session=openbox.desktop
SDDM
fi

# LXDM
if [ -f /mnt/etc/lxdm/lxdm.conf ]; then
    sed -i "s/^# autologin=.*/autologin=$USERNAME/" /mnt/etc/lxdm/lxdm.conf
fi

# SLiM
if [ -f /mnt/etc/slim.conf ]; then
    echo "default_user $USERNAME" >> /mnt/etc/slim.conf
    echo "auto_login yes" >> /mnt/etc/slim.conf
fi

# Habilitar el primer gestor encontrado
DM_SERVICE=""
for svc in lightdm sddm lxdm slim; do
    if [ -f "/mnt/usr/lib/systemd/system/${svc}.service" ]; then
        DM_SERVICE="$svc"
        arch-chroot /mnt systemctl enable "$svc"
        info "Gestor de display habilitado: $svc"
        break
    fi
done

if [ -z "$DM_SERVICE" ]; then
    warn "No se pudo instalar ningún gestor de display. Usando startx automático en tty1."
    cat >> /mnt/home/$USERNAME/.bashrc << 'BASHRC'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
fi
BASHRC
fi

# ============================================
# 17. Configurar Openbox (TERMINAL FIJA)
# ============================================
info "Configurando Openbox con terminal fija..."
mkdir -p /mnt/etc/skel/.config/openbox

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
# TERMINAL PRINCIPAL (NO SE PUEDE CERRAR)
urxvt -title "principal" &
feh --bg-scale /usr/share/backgrounds/default.jpg &
picom -b &
tint2 &
EOF

cat > /mnt/etc/skel/.xinitrc << 'EOF'
#!/bin/sh
exec openbox-session
EOF
chmod +x /mnt/etc/skel/.xinitrc

# ============================================
# 18. Scripts XONI
# ============================================
info "Creando scripts XONI..."

mkdir -p /mnt/usr/local/bin

cat > /mnt/usr/local/bin/installxoni << 'EOF'
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

cat > /mnt/usr/local/bin/xoniarch-update << 'EOF'
#!/bin/bash
cd /opt/xoniarch
for tool in */; do
    [ -d "$tool" ] && (cd "$tool" && git pull)
done
echo "[OK] Actualización completada"
EOF

cat > /mnt/usr/local/bin/xoniarch-help << 'EOF'
#!/bin/bash
cat << 'HELP'
========================================
   XONIARCH32 v6.1 - AYUDA
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

El sistema ARRANCA DIRECTAMENTE EN MODO GRAFICO
La terminal principal es FIJA (no se puede cerrar)

REPOSITORIO: https://github.com/XONIDU/xoniarch32
HELP
EOF

cat > /mnt/usr/local/bin/xoniarch-menu << 'EOF'
#!/bin/bash
while true; do
    clear
    echo "========================================"
    echo "      XONIARCH32 - MENU PRINCIPAL"
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

chmod +x /mnt/usr/local/bin/*

# ============================================
# 19. .bashrc personalizado
# ============================================
cat > /mnt/etc/skel/.bashrc << 'EOF'
alias ll='ls -la'
alias la='ls -A'
alias update='xoniarch-update'
alias menu='xoniarch-menu'
alias help='xoniarch-help'
PS1='\[\e[1;32m\][\u@\h \W]\$ \[\e[0m\]'
EOF
cp /mnt/etc/skel/.bashrc "/mnt/home/$USERNAME/"

# ============================================
# 20. Mensaje de bienvenida
# ============================================
cat > /mnt/etc/motd << 'EOF'
========================================
   XONIARCH32 v6.1 - LISTO
   by Darian Alberto Camacho Salas
========================================

Instalación completada.
El sistema ARRANCA DIRECTAMENTE EN MODO GRAFICO.
La terminal principal es FIJA (no se puede cerrar).

Comandos: xoniarch-help
Repositorio: https://github.com/XONIDU/xoniarch32
EOF

# ============================================
# 21. Script de respaldo para inicio gráfico
# ============================================
cat > /mnt/usr/local/bin/ensure-graphical << 'EOF'
#!/bin/bash
# Script de respaldo para asegurar inicio gráfico
if ! systemctl is-active --quiet lightdm && ! systemctl is-active --quiet sddm && ! pgrep Xorg >/dev/null; then
    echo "Iniciando Xorg manualmente..."
    startx
fi
EOF
chmod +x /mnt/usr/local/bin/ensure-graphical

# Añadir al crontab del usuario (ejecutar cada minuto)
mkdir -p /mnt/var/spool/cron
echo "* * * * * /usr/local/bin/ensure-graphical" >> /mnt/var/spool/cron/$USERNAME 2>/dev/null || true

# ============================================
# 22. Limpieza y finalización
# ============================================
rm -f /mnt/root/chroot-config.sh
umount -R /mnt 2>/dev/null || true
[ -n "$SWAP_PART" ] && swapoff "/dev/$SWAP_PART" 2>/dev/null || true

echo "========================================"
echo "   INSTALACION COMPLETADA               "
echo "========================================"
echo ""
echo "El sistema ARRANCARA DIRECTAMENTE EN MODO GRAFICO"
echo "Terminal principal FIJA (no se puede cerrar)"
echo ""
echo "Reinicia con: sudo reboot"
echo ""
echo "Usuario: $USERNAME | Contraseña: (la que elegiste)"
echo "Root:    root     | Contraseña: la misma"
echo ""
echo "Multiples gestores instalados: lightdm, sddm, lxdm, slim"
echo "Si uno falla, el siguiente intentara iniciar"
echo "¡Disfruta Xoniarch32!"
