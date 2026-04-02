#!/bin/bash
#
##################################################################################################################
# Written to be used on 64 bits computers
# Author 	: 	Erik Dubois
# Website 	: 	http://www.erikdubois.be
##################################################################################################################
##################################################################################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
##################################################################################################################

echo "This gets all the existing githubs at once"
echo "Fill the array with the original folders first"

# use ls -d */ > list to get the list of the created githubs and copy/paste in

directories=(
xoniarch-calamares-config/
xoniarch-calamares-config-dev/
xoniarch-calamares-config-hardened/
xoniarch-calamares-config-lts/
xoniarch-calamares-config-pure/
xoniarch-calamares-config-xanmod/
xoniarch-calamares-config-zen/
xoniarch-dwm/
xoniarch-dwm-nemesis/
xoniarch-grub-theme/
xoniarch-iso/
xoniarch-iso-dev/
xoniarch-iso-hardened/
xoniarch-iso-lts/
xoniarch-iso-pure/
xoniarch-iso-xanmod/
xoniarch-iso-zen/
xoniarch-pkgbuild/
xoniarch_repo/
nemesis-wallpapers/
)

count=0

for name in "${directories[@]}"; do
	count=$[count+1]
	tput setaf 1;echo "Github "$count;tput sgr0;
	# if there is no folder then make one
	git clone https://github.com/arch-linux-calamares-installer/$name
	echo "#################################################"
	echo "################  "$(basename `pwd`)" done"
	echo "#################################################"
done
