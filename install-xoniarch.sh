#!/bin/bash
echo "========================================="
echo "  XONIARCH - Instalador"
echo "========================================="
DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -f "$DIR/config/packages.txt" ]; then
    sudo pacman -Sy --noconfirm $(cat "$DIR/config/packages.txt" | grep -v '^#')
fi

mkdir -p ~/.config/openbox
cp "$DIR/config/openbox-rc.txt" ~/.config/openbox/rc.xml
cp "$DIR/config/openbox-autostart.txt" ~/.config/openbox/autostart
chmod +x ~/.config/openbox/autostart
cp "$DIR/config/Xresources.txt" ~/.Xresources
xrdb -merge ~/.Xresources
cp "$DIR/config/xinitrc.txt" ~/.xinitrc
chmod +x ~/.xinitrc
cat "$DIR/config/bashrc.txt" >> ~/.bashrc

sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo cp "$DIR/config/autologin.txt" /etc/systemd/system/getty@tty1.service.d/autologin.conf
sudo cp "$DIR/config/profile.txt" /etc/profile.d/xoniarch.sh
sudo chmod +x /etc/profile.d/xoniarch.sh

for script in "$DIR"/scripts/xoniarch-*; do
    if [ -f "$script" ]; then
        sudo cp "$script" /usr/local/bin/
        sudo chmod +x "/usr/local/bin/$(basename "$script")"
    fi
done

echo "Instalacion completada. Reinicia: sudo reboot"
