#!/bin/bash
# XONIARCH32 - INSTALADOR ROBUSTO DESDE LIVE USB
# Autor: Darian Alberto Camacho Salas
# Versión: 4.2.0
# Repositorio: https://github.com/XONIDU/xoniarch32

set -euo pipefail
trap 'echo -e "\033[0;31m[ERROR] Falló el script en la línea $LINENO\033[0m" >&2' ERR

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

error_exit() { echo -e "${RED}[ERROR] $1${NC}" >&2; exit 1; }
info()  { echo -e "${GREEN}[INFO] $1${NC}"; }
warn()  { echo -e "${YELLOW}[AVISO] $1${NC}"; }

# ============================================
# 1. VERIFICAR ENTORNO LIVE
# ============================================
if [ ! -d /run/archiso ]; then
    error_exit "Este script debe ejecutarse desde el live USB de Arch Linux 32 bits."
fi

# ============================================
# 2. SELECCIONAR DISCO DE INSTALACIÓN
# ============================================
clear
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   XONIARCH32 - INSTALADOR ROBUSTO     ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Discos disponibles:${NC}"
echo "----------------------------------------"
lsblk -d -o NAME,SIZE,MODEL,TYPE | grep -E "disk|NAME"
echo "----------------------------------------"
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

# ============================================
# 3. OPCIONES DE PARTICIONADO
# ============================================
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

    # Formatear
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
# 4. CONFIGURAR PACMAN CON MIRRORS DE ARCHLINUX32
# ============================================
info "Configurando mirrors de archlinux32..."

# Lista extensa de mirrors (con prioridad)
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

# Probar mirrors y elegir el primero funcional
WORKING_MIRROR=""
for mirror in "${MIRRORS[@]}"; do
    echo -n "Probando $mirror... "
    if curl -s --head --max-time 5 "${mirror}/core/os/i686/core.db" > /dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
        WORKING_MIRROR="$mirror"
        break
    else
        echo -e "${RED}FALLÓ${NC}"
    fi
done

if [ -z "$WORKING_MIRROR" ]; then
    warn "No se encontró ningún mirror funcional. Usando mirror por defecto (archlinux32.org)."
    WORKING_MIRROR="https://mirror.archlinux32.org"
fi

info "Mirror seleccionado: $WORKING_MIRROR"

# Escribir pacman.conf
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

[core]
Server = $WORKING_MIRROR/\$arch/\$repo
Server = https://mirror.archlinux32.org/\$arch/\$repo
Server = https://ftp.halifax.rwth-aachen.de/archlinux32/\$arch/\$repo

[extra]
Server = $WORKING_MIRROR/\$arch/\$repo
Server = https://mirror.archlinux32.org/\$arch/\$repo
Server = https://ftp.halifax.rwth-aachen.de/archlinux32/\$arch/\$repo

[community]
Server = $WORKING_MIRROR/\$arch/\$repo
Server = https://mirror.archlinux32.org/\$arch/\$repo
Server = https://ftp.halifax.rwth-aachen.de/archlinux32/\$arch/\$repo
EOF

# ============================================
# 5. INICIALIZAR CLAVES PGP Y SINCRONIZAR
# ============================================
info "Inicializando claves PGP (esto puede tardar)..."
pacman-key --init 2>/dev/null || true
pacman-key --populate archlinux32 2>/dev/null || true
pacman -Sy --noconfirm archlinux32-keyring 2>/dev/null || true

info "Sincronizando bases de datos..."
pacman -Sy --noconfirm || error_exit "Fallo al sincronizar bases de datos. Verifica conexión a internet."

# ============================================
# 6. INSTALAR SISTEMA BASE
# ============================================
info "Instalando sistema base (puede tardar 10-20 minutos)..."
pacstrap /mnt base base-devel linux-firmware grub networkmanager nano sudo git || error_exit "Falló la instalación base."

# ============================================
# 7. GENERAR FSTAB
# ============================================
info "Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# ============================================
# 8. CONFIGURACIÓN INICIAL EN CHROOT
# ============================================
info "Configurando el sistema..."

cat > /mnt/root/chroot-config.sh << 'EOF'
#!/bin/bash
# Configuración básica dentro del chroot

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

# GRUB (el disco se pasa desde el script principal)
grub-install --target=i386-pc /dev/__DISK__
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# Reemplazar marcador con el disco real
sed -i "s|__DISK__|$DISK|g" /mnt/root/chroot-config.sh
chmod +x /mnt/root/chroot-config.sh
arch-chroot /mnt /root/chroot-config.sh

# ============================================
# 9. DESCARGAR Y EJECUTAR PERSONALIZACIÓN XONIARCH
# ============================================
info "Descargando script de personalización Xoniarch..."
if curl -sSL https://raw.githubusercontent.com/XONIDU/xoniarch32/main/xoniarch-install.sh -o /mnt/root/xoniarch-install.sh; then
    chmod +x /mnt/root/xoniarch-install.sh
    info "Ejecutando personalización..."
    arch-chroot /mnt /root/xoniarch-install.sh
else
    warn "No se pudo descargar xoniarch-install.sh. El sistema base está listo, pero faltarán herramientas XONI."
fi

# ============================================
# 10. LIMPIEZA
# ============================================
rm -f /mnt/root/chroot-config.sh /mnt/root/xoniarch-install.sh 2>/dev/null || true

# ============================================
# 11. DESMONTAR Y FINALIZAR
# ============================================
info "Desmontando particiones..."
umount -R /mnt 2>/dev/null || true
[ -n "$SWAP_PART" ] && swapoff "/dev/$SWAP_PART" 2>/dev/null || true

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   INSTALACIÓN COMPLETADA EXITOSAMENTE ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Puedes reiniciar ahora:"
echo "  sudo reboot"
echo ""
echo "Usuario: xoniarch | Contraseña: xoniarch"
echo "Root: root | Contraseña: root"
echo ""
echo "Después del reinicio, ejecuta 'xoniarch-help' para más información."
