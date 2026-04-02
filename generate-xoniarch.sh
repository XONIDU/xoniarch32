cat > generate-xoniarch.sh << 'GENERATE_EOF'
#!/bin/bash
set -e

buildFolder=$HOME"/xoniarch-build"
outFolder=$HOME"/xoniarch"

echo "##################################################################"
echo "Phase 1 : Building XONIARCH"
echo "##################################################################"

# Crear directorios
[ -d $buildFolder ] && sudo rm -rf $buildFolder
mkdir -p $buildFolder
mkdir -p $outFolder

# Copiar archivo de configuracion
echo "Copiando archivo de configuracion..."
cp -r archiso $buildFolder/

echo "##################################################################"
echo "Phase 2 : Building ISO"
echo "##################################################################"

cd $buildFolder/archiso/
sudo mkarchiso -v -w $buildFolder -o $outFolder $buildFolder/archiso/

echo "##################################################################"
echo "DONE"
echo "- Check your out folder : $outFolder"
echo "##################################################################"
GENERATE_EOF

chmod +x generate-xoniarch.sh
echo "Script generate-xoniarch.sh actualizado"
