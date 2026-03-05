#!/bin/bash
# XONIARCH32 - INSTALADOR COMPLETO DESDE LIVE USB (CORREGIDO)
# Autor: Darian Alberto Camacho Salas

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

error_exit() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
    exit 1
}

info() { echo -e "${GREEN}[INFO] $1${NC}"; }
warn() { echo -e "${YELLOW}[AVISO] $1${NC}"; }

# Verificar live USB
if [ ! -d /run/archiso ]; then
    error_exit "Este script debe ejecutarse desde el live USB de Arch Linux 32 bits."
fi

# Buscar mirror funcional
info "Buscando mirror funcional de archlinux32..."
MIRRORS=(
    "https://mirror.archlinux32.org"
    "https://ftp.halifax.rwth-aachen.de/archlinux32"
    "https://mirror.cyberbits.eu/archlinux32"
    "https://mirror.ubnt.net/archlinux32"
    "https://mirror.accum.se/mirror/archlinux32"
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
[ -z "$WORKING_MIRROR" ] && error_exit "No se encontró mirror funcional."
info "Mirror seleccionado: $WORKING_MIRROR"

# Configurar pacman
cat > /etc/pacman.conf <<EOF
[options]
HoldPkg         = pacman glibc
Architecture    = i686
SigLevel        = Never
LocalFileSigLevel = Never
RemoteFileSigLevel = Never
ParallelDownloads = 5
Color
CheckSpace
[core]
Server = $WORKING_MIRROR/\$arch/\$repo
[extra]
Server = $WORKING_MIRROR/\$arch/\$repo
[community]
Server = $WORKING_MIRROR/\$arch/\$repo
EOF

# Inicializar claves
info "Inicializando claves PGP..."
pacman-key --init 2>/dev/null || true
pacman-key --populate archlinux32 2>/dev/null || true
pacman -Sy --noconfirm archlinux32-keyring 2>/dev/null || true

# Mostrar discos y pedir selección
clear
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   XONIARCH32 - INSTALADOR COMPLETO    ${NC}"
echo -e "${GREEN}========================================${NC}\n"
echo -e "${YELLOW}Discos disponibles:${NC}"
lsblk -d -o NAME,SIZE,MODEL,TYPE | grep -E "disk|NAME"
echo ""
read -p "¿En qué disco quieres instalar Xoniarch32? (ej: sda): " DISK
if [ -z "$DISK" ]; then
    error_exit "No se seleccionó ningún disco."
fi
if [ ! -b "/dev/$DISK" ]; then
    error_exit "El disco /dev/$DISK no existe."
fi

# Confirmar borrado
echo ""
echo -e "${RED}¡ATENCIÓN! Se borrarán TODOS los datos en /dev/$DISK${NC}"
lsblk "/dev/$DISK"
echo ""
read -p "¿Estás seguro? (escribe YES en mayúsculas): " CONFIRM
if [ "$CONFIRM" != "YES" ]; then
    error_exit "Instalación cancelada."
fi

# Elegir particionado
echo ""
echo "Elige el tipo de particionado:"
echo "1) Automático (una partición root + swap opcional)"
echo "2) Manual (usar fdisk tú mismo)"
read -p "Opción [1/2]: " PART_OPT

if [ "$PART_OPT" = "1" ]; then
    read -p "¿Crear partición swap? (s/n): " SWAP_OPT
    if [[ "$SWAP_OPT" =~ ^[Ss]$ ]]; then
        read -p "Tamaño de swap en GB (ej: 1): " SWAP_SIZE
        [ -z "$SWAP_SIZE" ] && SWAP_SIZE=1
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
    mkfs.ext4 -F "/dev/$ROOT_PART"
    [ -n "$SWAP_PART" ] && mkswap "/dev/$SWAP_PART"
else
    info "Abriendo fdisk. Cuando termines, escribe 'exit' para continuar."
    fdisk "/dev/$DISK"
    echo ""
    lsblk "/dev/$DISK"
    read -p "Indica la partición raíz (ej: ${DISK}2): " ROOT_PART
    [ -z "$ROOT_PART" ] && error_exit "No se indicó partición raíz."
    read -p "Indica la partición swap (vacío si no hay): " SWAP_PART
fi

# Montar
info "Montando sistema..."
mount "/dev/$ROOT_PART" /mnt
[ -n "$SWAP_PART" ] && swapon "/dev/$SWAP_PART" 2>/dev/null || true

# Instalar base
info "Instalando sistema base (puede tardar)..."
pacstrap /mnt base base-devel linux-firmware grub networkmanager nano sudo git

# Fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Configuración inicial en chroot
cat > /mnt/root/chroot-config.sh << 'INNER'
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
grub-install --target=i386-pc /dev/__DISK__
grub-mkconfig -o /boot/grub/grub.cfg
INNER
sed -i "s|__DISK__|$DISK|g" /mnt/root/chroot-config.sh
chmod +x /mnt/root/chroot-config.sh
arch-chroot /mnt /root/chroot-config.sh

# Descargar y ejecutar personalización Xoniarch
info "Descargando personalización Xoniarch..."
curl -sSL https://raw.githubusercontent.com/XONIDU/xoniarch32/main/xoniarch-install.sh -o /mnt/root/xoniarch-install.sh
chmod +x /mnt/root/xoniarch-install.sh
arch-chroot /mnt /root/xoniarch-install.sh

# Limpiar
rm -f /mnt/root/chroot-config.sh /mnt/root/xoniarch-install.sh

# Desmontar
info "Desmontando..."
umount -R /mnt
[ -n "$SWAP_PART" ] && swapoff "/dev/$SWAP_PART" 2>/dev/null || true

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   INSTALACIÓN COMPLETADA               ${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Reinicia con: sudo reboot"
echo "Usuario: xoniarch | Contraseña: xoniarch"
echo "Root: root | Contraseña: root"
