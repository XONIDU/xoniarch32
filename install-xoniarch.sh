#!/bin/bash
# XONIARCH32 v4.2.0 Ultimate – Instalador único y completo
# Autor: Darian Alberto Camacho Salas
# Repositorio: https://github.com/XONIDU/xoniarch32
# 
# Este script instala Xoniarch32 en cualquier unidad de almacenamiento
# (SD, USB, disco interno). Usa PARTUUID para arranque independiente
# del orden de discos, ideal para sistemas externos.

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
# 1. Verificar entorno live
# ============================================
if [ ! -d /run/archiso ]; then
    error_exit "Este script debe ejecutarse desde el live USB de Arch Linux 32 bits."
fi

# ============================================
# 2. Seleccionar disco de instalación
# ============================================
clear
echo "========================================"
echo "   XONIARCH32 v4.2.0 ULTIMATE          "
echo "   Instalador para unidades externas   "
echo "========================================"
echo ""
echo "Discos disponibles:"
lsblk -d -o NAME,SIZE,MODEL,TYPE | grep -E "disk|NAME"
echo ""
read -p "¿En qué disco quieres instalar Xoniarch32? (ej: sda): " DISK
[ -z "$DISK" ] && error_exit "No se seleccionó ningún disco."
[ ! -b "/dev/$DISK" ] && error_exit "El disco /dev/$DISK no existe."

echo ""
echo "¡ATENCION! Se borrarán TODOS los datos en /dev/$DISK"
lsblk "/dev/$DISK"
read -p "¿Estás seguro? (escribe YES): " CONFIRM
[ "$CONFIRM" != "YES" ] && error_exit "Instalación cancelada."

# ============================================
# 3. Opciones de particionado
# ============================================
echo ""
echo "Elige el tipo de particionado:"
echo "1) Automático (swap opcional)"
echo "2) Manual (usar fdisk tú mismo)"
read -p "Opcion [1/2]: " PART_OPT

if [ "$PART_OPT" = "1" ]; then
    read -p "¿Crear partición swap? (s/n): " SWAP_OPT
    if [[ "$SWAP_OPT" =~ ^[Ss]$ ]]; then
        read -p "Tamaño de swap en GB (ej: 1): " SWAP_SIZE
        SWAP_SIZE=${SWAP_SIZE:-1}
        info "Particionando /dev/$DISK con swap de ${SWAP_SIZE}G..."
        parted "/dev/$DISK" mklabel msdos
        parted "/dev/$DISK" mkpart primary linux-swap 1MiB "${SWAP_SIZE}GiB"
        parted "/dev/$DISK" mkpart primary ext4 "${SWAP_SIZE}GiB" 100%
        parted "/dev/$DISK" set 2 boot on
        ROOT_PART="${DISK}2"
        SWAP_PART="${DISK}1"
    else
        info "Particionando /dev/$DISK sin swap..."
        parted "/dev/$DISK" mklabel msdos
        parted "/dev/$DISK" mkpart primary ext4 1MiB 100%
        parted "/dev/$DISK" set 1 boot on
        ROOT_PART="${DISK}1"
        SWAP_PART=""
    fi

    info "Formateando particiones..."
    mkfs.ext4 -F "/dev/$ROOT_PART"
    [ -n "$SWAP_PART" ] && mkswap "/dev/$SWAP_PART"
else
    info "Abriendo fdisk para particionado manual. Cuando termines, escribe 'exit' para continuar."
    fdisk "/dev/$DISK"
    echo ""
    lsblk "/dev/$DISK"
    read -p "Indica la partición raíz (ej: ${DISK}2): " ROOT_PART
    [ -z "$ROOT_PART" ] && error_exit "No se indicó partición raíz."
    read -p "Indica la partición swap (dejar vacío si no hay): " SWAP_PART
fi

# Montar sistema
info "Montando sistema en /mnt..."
mount "/dev/$ROOT_PART" /mnt
[ -n "$SWAP_PART" ] && swapon "/dev/$SWAP_PART" 2>/dev/null || true

# ============================================
# 4. Selección del mejor mirror de archlinux32
# ============================================
info "Buscando el mirror más rápido de archlinux32..."

MIRRORS=(
    "https://mirror.archlinux32.org"
    "https://ftp.halifax.rwth-aachen.de/archlinux32"
    "https://mirror.cyberbits.eu/archlinux32"
    "https://mirror.ubnt.net/archlinux32"
    "https://mirror.accum.se/mirror/archlinux32"
    "https://de.mirror.archlinux32.org"
    "https://gr.mirror.archlinux32.org"
    "https://mirror.clarkson.edu/archlinux32"
    "https://mirror.math.princeton.edu/pub/archlinux32"
    "https://archlinux32.andreasbaumann.cc"
)

best_mirror=""
best_time=999999
for mirror in "${MIRRORS[@]}"; do
    echo -n "Probando $mirror ... "
    start=$(date +%s%N)
    if curl -s --head --max-time 5 "${mirror}/core/os/i686/core.db" >/dev/null 2>&1; then
        end=$(date +%s%N)
        time_ms=$(( (end - start) / 1000000 ))
        echo "OK (${time_ms}ms)"
        if [ $time_ms -lt $best_time ]; then
            best_time=$time_ms
            best_mirror="$mirror"
        fi
    else
        echo "FALLÓ"
    fi
done

if [ -z "$best_mirror" ]; then
    warn "No se encontró ningún mirror funcional. Usando el mirror por defecto."
    best_mirror="https://mirror.archlinux32.org"
else
    info "Mirror más rápido: $best_mirror (${best_time}ms)"
fi

# Configurar pacman con ese mirror y varios de respaldo
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
Timeout = 30

[core]
Server = $best_mirror/\$arch/\$repo
Server = https://mirror.archlinux32.org/\$arch/\$repo
Server = https://ftp.halifax.rwth-aachen.de/archlinux32/\$arch/\$repo

[extra]
Server = $best_mirror/\$arch/\$repo
Server = https://mirror.archlinux32.org/\$arch/\$repo
Server = https://ftp.halifax.rwth-aachen.de/archlinux32/\$arch/\$repo

[community]
Server = $best_mirror/\$arch/\$repo
Server = https://mirror.archlinux32.org/\$arch/\$repo
Server = https://ftp.halifax.rwth-aachen.de/archlinux32/\$arch/\$repo
EOF

# ============================================
# 5. Inicializar claves PGP
# ============================================
info "Inicializando claves PGP..."
pacman-key --init 2>/dev/null || true
pacman-key --populate archlinux32 2>/dev/null || true
pacman -Sy --noconfirm archlinux32-keyring 2>/dev/null || true

# ============================================
# 6. Instalar sistema base (con reintentos)
# ============================================
info "Instalando sistema base (puede tardar 10-20 minutos)..."
max_retries=5
retry=0
while [ $retry -lt $max_retries ]; do
    if pacstrap /mnt base base-devel linux-firmware grub networkmanager nano sudo git; then
        break
    else
        retry=$((retry+1))
        warn "Falló la instalación base. Reintento $retry de $max_retries en 10 segundos..."
        sleep 10
    fi
done
if [ $retry -eq $max_retries ]; then
    error_exit "Falló la instalación base después de varios intentos. Revisa la conexión a internet."
fi

# ============================================
# 7. Generar fstab
# ============================================
info "Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# ============================================
# 8. Configuración básica dentro del chroot
# ============================================
info "Configurando sistema base..."

cat > /mnt/root/chroot-config.sh << 'CONFIG'
#!/bin/bash
# Zona horaria
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc

# Localización
echo "es_MX.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=es_MX.UTF-8" > /etc/locale.conf
echo "KEYMAP=es" > /etc/vconsole.conf

# Hostname
echo "xoniarch" > /etc/hostname
cat > /etc/hosts << HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   xoniarch.localdomain xoniarch
HOSTS

# Usuario y sudo
useradd -m -G wheel -s /bin/bash xoniarch
echo "xoniarch:xoniarch" | chpasswd
echo "root:root" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Habilitar servicios
systemctl enable NetworkManager
CONFIG

chmod +x /mnt/root/chroot-config.sh
arch-chroot /mnt /root/chroot-config.sh

# ============================================
# 9. Instalar GRUB (con PARTUUID para arranque externo)
# ============================================
info "Instalando GRUB y configurando con PARTUUID..."
arch-chroot /mnt grub-install --target=i386-pc "/dev/$DISK"

# Obtener PARTUUID de la partición raíz
root_uuid=$(blkid -s PARTUUID -o value "/dev/$ROOT_PART")
if [ -n "$root_uuid" ]; then
    info "PARTUUID de la raíz: $root_uuid"
    # Crear grub.cfg manual con PARTUUID
    cat > /mnt/boot/grub/grub.cfg << GRUB
set timeout=5
set default=0

menuentry "Xoniarch32 (desde unidad externa)" {
    linux /boot/vmlinuz-linux root=PARTUUID=$root_uuid rw quiet
    initrd /boot/initramfs-linux.img
}
GRUB
    info "grub.cfg creado con PARTUUID."
else
    warn "No se pudo obtener PARTUUID. Usando método tradicional."
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
fi

# ============================================
# 10. Instalar paquetes adicionales con verificación de arquitectura
# ============================================
info "Instalando paquetes adicionales (esto puede tardar)..."

# Lista de paquetes deseados (solo nombres)
PACKAGES=(
    xorg-server
    xorg-xinit
    xorg-xrandr
    xorg-xinput
    xorg-xauth
    xterm
    openbox
    obconf
    tint2
    feh
    picom
    nitrogen
    rxvt-unicode
    pcmanfm
    ranger
    geany
    mousepad
    mpv
    ffmpeg
    alsa-utils
    pulseaudio
    pavucontrol
    xf86-video-intel
    xf86-video-vesa
    mesa
    sddm
    tlp
    acpi
    acpid
    lm_sensors
)

# Función para verificar si un paquete existe y es de arquitectura i686
check_package() {
    pkg=$1
    # Buscar información del paquete en el mirror
    if pacman -Sp --print-format "%n %a" "$pkg" 2>/dev/null | grep -q "i686"; then
        return 0
    else
        return 1
    fi
}

# Instalar paquetes con verificación previa
for pkg in "${PACKAGES[@]}"; do
    echo "Verificando $pkg..."
    if check_package "$pkg"; then
        arch-chroot /mnt pacman -S --noconfirm "$pkg" 2>/dev/null && echo "[OK] $pkg instalado" || warn "Falló instalación de $pkg"
    else
        warn "$pkg no está disponible para i686 o no existe. Omitiendo."
    fi
done

# Habilitar servicios adicionales (si existen)
arch-chroot /mnt systemctl enable sddm 2>/dev/null || warn "sddm no disponible"
arch-chroot /mnt systemctl enable tlp 2>/dev/null || true
arch-chroot /mnt systemctl enable acpid 2>/dev/null || true

# ============================================
# 11. Configuración de Openbox (terminal fija)
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
# 12. Configuración de tint2
# ============================================
mkdir -p /mnt/etc/skel/.config/tint2
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
# 13. Scripts personalizados de Xoniarch (sin herramientas preinstaladas)
# ============================================
info "Creando scripts de Xoniarch..."

# installxoni: instala herramientas desde GitHub
cat > /mnt/usr/local/bin/installxoni << 'EOF'
#!/bin/bash
REPO_BASE="https://github.com/XONIDU"
DIR="/opt/xoniarch"
[ ! -d "$DIR" ] && mkdir -p "$DIR"
cd "$DIR"
if [ -z "$1" ]; then
    read -p "Herramienta a instalar (ej: xonitube): " TOOL
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
    ln -sf "$(pwd)/$f" "/usr/local/bin/$(basename $f .sh)" 2>/dev/null || true
done
echo "[OK] $TOOL instalado"
EOF

# xoniarch-update: actualiza todas las herramientas instaladas
cat > /mnt/usr/local/bin/xoniarch-update << 'EOF'
#!/bin/bash
cd /opt/xoniarch
for tool in */; do
    [ -d "$tool" ] && (cd "$tool" && git pull)
done
echo "[OK] Actualización completada"
EOF

# xoniarch-help: muestra ayuda
cat > /mnt/usr/local/bin/xoniarch-help << 'EOF'
#!/bin/bash
cat << 'HELP'
========================================
   XONIARCH32 v4.2.0 - AYUDA
========================================
COMANDOS:
  installxoni <herramienta>  : Instalar herramienta XONI desde GitHub
  xoniarch-update            : Actualizar todas las herramientas instaladas
  xoniarch-menu               : Abrir menú interactivo
  nmtui                       : Configurar red WiFi/Ethernet
  htop                        : Monitor del sistema
  pcmanfm                     : Gestor de archivos
  alsamixer                   : Ajustar volumen

ATAJOS DE TECLADO:
  Win + x   : Menú principal
  Win + t   : Nueva terminal
  Win + h   : Ayuda
  Win + i   : Instalar herramienta
  Win + q   : Cerrar sesión

USUARIO: xoniarch / CONTRASEÑA: xoniarch
ROOT:    root     / CONTRASEÑA: root

REPOSITORIO: https://github.com/XONIDU/xoniarch32
HELP
EOF

# xoniarch-menu: menú interactivo
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
    echo "5) Gestor de archivos (pcmanfm)"
    echo "6) Ayuda"
    echo "7) Cerrar sesion"
    echo ""
    read -p "Opcion [1-7]: " opt
    case $opt in
        1) urxvt ;;
        2) urxvt -e installxoni ; read -p "Presiona Enter..." ;;
        3) urxvt -e nmtui ;;
        4) urxvt -e htop ;;
        5) pcmanfm ;;
        6) xoniarch-help ; read -p "Presiona Enter..." ;;
        7) openbox --exit ;;
        *) echo "Opcion invalida"; sleep 2 ;;
    esac
done
EOF

chmod +x /mnt/usr/local/bin/*

# ============================================
# 14. SDDM con auto-login (si está instalado)
# ============================================
if [ -d /mnt/etc/sddm.conf.d ]; then
    cat > /mnt/etc/sddm.conf.d/autologin.conf << EOF
[Autologin]
User=xoniarch
Session=openbox.desktop
EOF
else
    warn "SDDM no instalado, el arranque será en modo terminal. Usa 'startx' para iniciar el entorno gráfico."
fi

# ============================================
# 15. .bashrc personalizado
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
# 16. Fondo de pantalla por defecto
# ============================================
mkdir -p /mnt/usr/share/backgrounds
if command -v convert >/dev/null 2>&1; then
    convert -size 1024x768 gradient:blue-navy /mnt/usr/share/backgrounds/default.jpg
else
    touch /mnt/usr/share/backgrounds/default.jpg
fi

# ============================================
# 17. Mensaje de bienvenida (MOTD)
# ============================================
cat > /mnt/etc/motd << 'EOF'
========================================
   XONIARCH32 v4.2.0 ULTIMATE - LISTO
   by Darian Alberto Camacho Salas
========================================

Instalacion completada con exito.
Usuario: xoniarch / Contrasena: xoniarch
Root:    root     / Contrasena: root

El sistema arrancara directamente en modo grafico (si SDDM esta instalado).
La terminal principal es fija (no se puede cerrar).

Comandos utiles:
  xoniarch-help     : Ayuda completa
  xoniarch-menu     : Menu interactivo
  installxoni       : Instalar herramientas XONI desde GitHub
  xoniarch-update   : Actualizar herramientas
  nmtui             : Configurar red

Repositorio: https://github.com/XONIDU/xoniarch32
EOF

# ============================================
# 18. Verificar GRUB nuevamente
# ============================================
if [ ! -f /mnt/boot/grub/grub.cfg ]; then
    warn "grub.cfg no se generó. Intentando una última vez..."
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
fi

# ============================================
# 19. Limpieza y finalización
# ============================================
rm -f /mnt/root/chroot-config.sh
umount -R /mnt 2>/dev/null || true
[ -n "$SWAP_PART" ] && swapoff "/dev/$SWAP_PART" 2>/dev/null || true

echo "========================================"
echo "   INSTALACION COMPLETADA              "
echo "========================================"
echo ""
echo "Reinicia el sistema con: sudo reboot"
echo ""
echo "Usuario: xoniarch | Contrasena: xoniarch"
echo "Root:    root     | Contrasena: root"
echo ""
echo "Despues del reinicio, ejecuta 'xoniarch-help' para mas informacion."
