#!/bin/bash
echo "========================================="
echo "Generando XONIARCH ISO"
echo "========================================="

# Verificar e instalar archiso si es necesario
if ! command -v mkarchiso &> /dev/null; then
    echo "mkarchiso no encontrado. Instalando archiso..."
    sudo pacman -S --noconfirm archiso
fi

buildFolder="$HOME/xoniarch-build"
outFolder="$(pwd)"

sudo rm -rf "$buildFolder"
mkdir -p "$buildFolder"
mkdir -p "$outFolder"

cp -rp "$(pwd)/archiso" "$buildFolder/"

cd "$buildFolder/archiso"
sudo mkarchiso -v -w "$buildFolder/work" -o "$outFolder" . 2>&1

if [ -f "$outFolder/xoniarch.iso" ]; then
    echo "ISO: $outFolder/xoniarch.iso"
elif [ -f "$outFolder/xoniarch--x86_64.iso" ]; then
    mv "$outFolder/xoniarch--x86_64.iso" "$outFolder/xoniarch.iso"
    echo "ISO: $outFolder/xoniarch.iso"
fi

sudo rm -rf "$buildFolder"
echo "Proceso completado"
