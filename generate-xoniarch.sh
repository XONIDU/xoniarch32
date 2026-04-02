#!/bin/bash
# XONIARCH - Generador de ISO

if lsblk -f | grep btrfs > /dev/null 2>&1 ; then
    echo
    echo "################################################################## "
    echo "Message"
    echo "This script has been known to cause issues on a Btrfs filesystem"
    echo "Make backups before continuing"
    echo "Continue at your own risk"
    echo
    read -p "Press Enter to continue... CTRL + C to stop"
fi

echo
echo "################################################################## "
echo "Phase 1 : "
echo "- Setting General parameters"
echo "################################################################## "
echo

archisoRequiredVersion="archiso 83-1"
buildFolder="$HOME/xoniarch-build"
outFolder="$HOME/xoniarch"
archisoVersion=$(sudo pacman -Q archiso)

echo "################################################################## "
echo "Do you have the right archiso version? : $archisoVersion"
echo "What is the required archiso version?  : $archisoRequiredVersion"
echo "Build folder                           : $buildFolder"
echo "Out folder                             : $outFolder"
echo "################################################################## "

if [ "$archisoVersion" == "$archisoRequiredVersion" ]; then
    echo "##################################################################"
    echo "Archiso has the correct version. Continuing ..."
    echo "##################################################################"
else
    echo "###################################################################################################"
    echo "You need to install the correct version of Archiso"
    echo "Use 'sudo downgrade archiso' to do that"
    echo "or update your system"
    echo "###################################################################################################"
fi

echo
echo "################################################################## "
echo "Phase 2 :"
echo "- Checking if archiso is installed"
echo "- Making mkarchiso verbose"
echo "################################################################## "
echo

package="archiso"

if pacman -Qi $package &> /dev/null; then
    echo "Archiso is already installed"
else
    if pacman -Qi yay &> /dev/null; then
        yay -S --noconfirm $package
    elif pacman -Qi trizen &> /dev/null; then
        trizen -S --noconfirm --needed --noedit $package
    fi
fi

echo
echo "Making mkarchiso verbose"
sudo sed -i 's/quiet="y"/quiet="n"/g' /usr/bin/mkarchiso 2>/dev/null || true

echo
echo "################################################################## "
echo "Phase 3 :"
echo "- Deleting the build folder if one exists"
echo "- Copying the Archiso folder to build folder"
echo "################################################################## "
echo

echo "Deleting the build folder if one exists - takes some time"
[ -d $buildFolder ] && sudo rm -rf $buildFolder
echo
echo "Copying the Archiso folder to build work"
echo
mkdir -p $buildFolder
cp -r archiso $buildFolder/

echo
echo "################################################################## "
echo "Phase 7 :"
echo "- Building the iso - this can take a while - be patient"
echo "################################################################## "
echo

[ -d $outFolder ] || mkdir $outFolder
cd $buildFolder/archiso/
sudo mkarchiso -v -w $buildFolder -o $outFolder $buildFolder/archiso/

echo
echo "Renaming ISO to xoniarch.iso"
echo "########################"

# Renombrar la ISO generada
cd $outFolder
if [ -f "xoniarch.iso" ]; then
    mv "xoniarch.iso" "xoniarch.iso"
elif [ -f "archlinux-*.iso" ]; then
    mv archlinux-*.iso xoniarch.iso 2>/dev/null
fi

echo
echo "Moving pkglist.x86_64.txt"
echo "########################"
rename=$(date +%Y-%m-%d)
cp $buildFolder/iso/arch/pkglist.x86_64.txt $outFolder/xoniarch-$rename-pkglist.txt 2>/dev/null || true

echo
echo "##################################################################"
echo "DONE"
echo "- ISO: $outFolder/xoniarch.iso"
echo "##################################################################"
echo
