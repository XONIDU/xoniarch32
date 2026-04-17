#!/bin/bash
# ============================================================================
# install-xoniarch.sh - Instalador completo de XONIARCH en disco duro
# ============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

error_exit() { echo -e "${RED}[ERROR] $1${NC}" >&2; exit 1; }
info() { echo -e "${GREEN}[INFO] $1${NC}"; }
warn() { echo -e "${YELLOW}[AVISO] $1${NC}"; }

# ============================================================================
# 1. Selección de disco (con reintentos)
# ============================================================================
select_disk() {
    while true; do
        echo ""
        info "Discos disponibles:"
        lsblk -d -o NAME,SIZE,MODEL | grep -E "^sd|^nvme|^vd" || echo "No se encontraron discos"
        echo ""
        read -p "Introduce el disco (ej: sda, nvme0n1, vda): " DISK
        DISK_PATH="/dev/$DISK"
        if [ -b "$DISK_PATH" ]; then
            break
        else
            warn "El disco $DISK_PATH no existe. Intenta de nuevo."
        fi
    done
    echo -e "${RED}ADVERTENCIA: Se borrarán TODOS los datos de $DISK_PATH${NC}"
    read -p "¿Estás seguro? (escribe 'YES' para continuar): " CONFIRM
    if [ "$CONFIRM" != "YES" ]; then
        error_exit "Instalación cancelada por el usuario."
    fi
}

# ============================================================================
# 2. Datos del usuario
# ============================================================================
get_user_data() {
    echo ""
    info "Configuración de usuario"
    while true; do
        read -p "Nombre de usuario (minúsculas, sin espacios): " USERNAME
        if [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
            break
        else
            warn "Nombre inválido. Usa solo letras minúsculas, números, guiones."
        fi
    done
    while true; do
        read -sp "Contraseña: " USER_PASS
        echo
        read -sp "Confirmar contraseña: " USER_PASS2
        echo
        if [ "$USER_PASS" = "$USER_PASS2" ] && [ -n "$USER_PASS" ]; then
            break
        else
            warn "Las contraseñas no coinciden o están vacías."
        fi
    done
}

# ============================================================================
# 3. Configuración del sistema (keymap, timezone, hostname)
# ============================================================================
get_system_config() {
    echo ""
    info "Mapa de teclado (keymap)"
    echo "Ejemplos comunes: us, es, de, fr, la-latin1, uk, it, br"
    read -p "Keymap: " KEYMAP
    [ -z "$KEYMAP" ] && KEYMAP="us"
    if ! localectl list-keymaps 2>/dev/null | grep -qx "$KEYMAP"; then
        warn "Mapa '$KEYMAP' no encontrado. Se usará 'us'."
        KEYMAP="us"
    fi

    echo ""
    info "Zona horaria"
    echo "Ejemplos: America/Mexico_City, America/Argentina/Buenos_Aires, Europe/Madrid, UTC"
    read -p "Zona horaria: " TIMEZONE
    if [ -z "$TIMEZONE" ]; then
        TIMEZONE="America/Mexico_City"
    fi
    if [ ! -e "/usr/share/zoneinfo/$TIMEZONE" ]; then
        warn "Zona '$TIMEZONE' no válida. Usando UTC."
        TIMEZONE="UTC"
    fi

    echo ""
    read -p "Nombre del host (ej: xoniarch): " HOSTNAME
    [ -z "$HOSTNAME" ] && HOSTNAME="xoniarch"
}

# ============================================================================
# 4. Opción de gestor de display (SDDM) o startx
# ============================================================================
ask_display_manager() {
    echo ""
    read -p "¿Instalar SDDM (gestor de display gráfico)? (s/n): " INSTALL_SDDM
    if [[ "$INSTALL_SDDM" =~ ^[sS]$ ]]; then
        USE_SDDM=true
        info "Se instalará SDDM (inicio gráfico directo)."
    else
        USE_SDDM=false
        info "No se instalará SDDM. Se usará 'startx' desde tty1."
    fi
}

# ============================================================================
# 5. Particionado y formateo (detecta UEFI/BIOS)
# ============================================================================
partition_disk() {
    info "Particionando disco $DISK_PATH"
    sudo wipefs -a "$DISK_PATH"
    if [ -d /sys/firmware/efi ]; then
        BOOT_MODE="UEFI"
        info "Modo UEFI detectado"
        sudo parted -s "$DISK_PATH" mklabel gpt
        sudo parted -s "$DISK_PATH" mkpart primary fat32 1MiB 501MiB
        sudo parted -s "$DISK_PATH" set 1 esp on
        sudo parted -s "$DISK_PATH" mkpart primary ext4 501MiB 100%
        sudo mkfs.fat -F32 "${DISK_PATH}1"
        sudo mkfs.ext4 -F "${DISK_PATH}2"
        EFI_PART="${DISK_PATH}1"
        ROOT_PART="${DISK_PATH}2"
    else
        BOOT_MODE="BIOS"
        info "Modo BIOS detectado"
        sudo parted -s "$DISK_PATH" mklabel msdos
        sudo parted -s "$DISK_PATH" mkpart primary ext4 1MiB 100%
        sudo parted -s "$DISK_PATH" set 1 boot on
        sudo mkfs.ext4 -F "${DISK_PATH}1"
        ROOT_PART="${DISK_PATH}1"
        EFI_PART=""
    fi
}

# ============================================================================
# 6. Montaje e instalación base
# ============================================================================
install_base() {
    info "Montando particiones"
    sudo mount "$ROOT_PART" /mnt
    if [ "$BOOT_MODE" = "UEFI" ]; then
        sudo mkdir -p /mnt/boot
        sudo mount "$EFI_PART" /mnt/boot
    fi

    info "Instalando sistema base (puede tardar varios minutos)"
    sudo pacstrap -K /mnt base base-devel linux linux-firmware grub efibootmgr networkmanager nano
    sudo genfstab -U /mnt >> /mnt/etc/fstab
}

# ============================================================================
# 7. Configuración del sistema instalado (chroot)
# ============================================================================
configure_system() {
    info "Configurando sistema instalado"

    # Copiar todo el repositorio XONIARCH al sistema destino
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    sudo mkdir -p /mnt/opt/xoniarch
    sudo cp -r "$SCRIPT_DIR"/* /mnt/opt/xoniarch/

    # Crear script de configuración para ejecutar dentro del chroot
    cat << EOF | sudo arch-chroot /mnt /bin/bash
set -e

# Configuración básica
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "$HOSTNAME" > /etc/hostname
echo "LANG=en_US.UTF-8" > /etc/locale.conf
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

# Crear usuario y contraseñas
useradd -m -G wheel,audio,video,storage,optical $USERNAME
echo "$USERNAME:$USER_PASS" | chpasswd
echo "root:$USER_PASS" | chpasswd

# Configurar sudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Instalar paquetes de XONIARCH (desde config/packages.txt)
pacman -Sy --noconfirm \$(cat /opt/xoniarch/config/packages.txt | grep -v '^#')

# Configurar Openbox para el usuario
mkdir -p /home/$USERNAME/.config/openbox
cp /opt/xoniarch/config/openbox-rc.txt /home/$USERNAME/.config/openbox/rc.xml
cp /opt/xoniarch/config/openbox-autostart.txt /home/$USERNAME/.config/openbox/autostart
chmod +x /home/$USERNAME/.config/openbox/autostart
cp /opt/xoniarch/config/Xresources.txt /home/$USERNAME/.Xresources
cp /opt/xoniarch/config/xinitrc.txt /home/$USERNAME/.xinitrc
chmod +x /home/$USERNAME/.xinitrc
cat /opt/xoniarch/config/bashrc.txt >> /home/$USERNAME/.bashrc

# Configurar scripts XONIARCH
cp /opt/xoniarch/scripts/xoniarch-* /usr/local/bin/
chmod +x /usr/local/bin/xoniarch-*

# Configurar NetworkManager
systemctl enable NetworkManager

# Configurar GRUB
if [ "$BOOT_MODE" = "UEFI" ]; then
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=XONIARCH
else
    grub-install --target=i386-pc $DISK_PATH
fi
grub-mkconfig -o /boot/grub/grub.cfg

# Configurar autologin y display manager
if [ "$USE_SDDM" = true ]; then
    pacman -S --noconfirm sddm
    systemctl enable sddm
    mkdir -p /etc/sddm.conf.d
    cat > /etc/sddm.conf.d/autologin.conf << SDDMEOF
[Autologin]
User=$USERNAME
Session=openbox.desktop
SDDMEOF
    # Crear archivo de sesión para Openbox
    mkdir -p /usr/share/xsessions
    cat > /usr/share/xsessions/openbox.desktop << DESKEOF
[Desktop Entry]
Name=Openbox
Comment=Openbox Window Manager
Exec=openbox-session
Type=Application
DESKEOF
else
    # Configurar autologin en tty1 y startx automático
    mkdir -p /etc/systemd/system/getty@tty1.service.d
    cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << AUTOLOGINEOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USERNAME --noclear %I 38400 linux
AUTOLOGINEOF
    # Asegurar que profile.txt esté presente (inicia startx)
    cp /opt/xoniarch/config/profile.txt /etc/profile.d/xoniarch.sh
    chmod +x /etc/profile.d/xoniarch.sh
fi

# Cambiar propietario de los archivos del usuario
chown -R $USERNAME:$USERNAME /home/$USERNAME

echo "Configuración dentro del chroot completada."
EOF

    if [ $? -ne 0 ]; then
        error_exit "Error durante la configuración dentro del chroot."
    fi
}

# ============================================================================
# 8. Finalización y reinicio
# ============================================================================
finish_installation() {
    info "Desmontando particiones"
    sudo umount -R /mnt
    echo ""
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}              INSTALACIÓN COMPLETADA EXITOSAMENTE               ${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo ""
    echo -e "Usuario: ${YELLOW}$USERNAME${NC}"
    echo -e "Contraseña: ${YELLOW}la que configuraste${NC}"
    echo ""
    echo -e "${YELLOW}Reinicia el sistema y bootea desde el disco${NC}"
    echo ""
    read -p "Presiona Enter para reiniciar..."
    sudo reboot
}

# ============================================================================
# Ejecución principal
# ============================================================================
main() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "Este script debe ejecutarse como root (sudo)."
    fi

    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}                XONIARCH - Instalador en Disco Duro                ${NC}"
    echo -e "${BLUE}================================================================${NC}"

    select_disk
    get_user_data
    get_system_config
    ask_display_manager
    partition_disk
    install_base
    configure_system
    finish_installation
}

main
