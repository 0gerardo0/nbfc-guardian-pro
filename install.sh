#!/bin/bash
set -e

SCRIPT_DIR_HOME=$(cd $(dirname $0) && pwd)
cd $SCRIPT_DIR_HOME
SCRIPT_DIR=$SCRIPT_DIR_HOME/scripts
TARGET_DIR=/usr/local/bin
SERVICE_FILE=nbfc-guardian.service
CONFIG_FILE=HP_Preventive.json
SERVICE_SRC=$SCRIPT_DIR_HOME/configs/$SERVICE_FILE
SERVICE_DST=$HOME/.config/systemd/user/$SERVICE_FILE
CONFIG_SRC=$SCRIPT_DIR_HOME/configs/$CONFIG_FILE
CONFIG_DST=/usr/share/nbfc/configs/$CONFIG_FILE
SUDOERS_FILE=/etc/sudoers.d/nbfc-guardian

echo ========================================
echo   NBFC Guardian Pro - Instalador
echo ========================================
echo

if [[ $EUID -eq 0 ]]; then
    echo ERROR: No ejecutes como root. Usa tu usuario normal.
    exit 1
fi

echo [1/7] Verificando nbfc-linux...
if ! command -v nbfc &> /dev/null; then
    echo       ✗ nbfc no encontrado. Instala primero nbfc-linux
    echo       https://github.com/nbfc-linux/nbfc-linux
    exit 1
fi
echo       ✓ nbfc-linux detectado

echo
echo [2/7] Copiando scripts a $TARGET_DIR...
sudo cp $SCRIPT_DIR/nbfc-guardian.sh $TARGET_DIR/
sudo cp $SCRIPT_DIR/nbfc-pro $TARGET_DIR/
sudo chmod +x $TARGET_DIR/nbfc-guardian.sh
sudo chmod +x $TARGET_DIR/nbfc-pro
echo       ✓ Scripts copiados

echo
echo [3/7] Verificando scripts...
if [[ -x $TARGET_DIR/nbfc-guardian.sh ]] && [[ -x $TARGET_DIR/nbfc-pro ]]; then
    echo       ✓ Permisos correctos
else
    echo       ✗ Error en permisos
    exit 1
fi

echo
echo [4/7] Copiando configuracion HP_Preventive...
if [[ -f $CONFIG_SRC ]]; then
    sudo cp $CONFIG_SRC $CONFIG_DST
    echo       ✓ Configuracion copiada a $CONFIG_DST
else
    echo       ⚠ Configuracion no encontrada, saltando
fi

echo
echo [5/7] Configurando sudoers NOPASSWD...
SUDOERS_LINE=$(whoami)' ALL=(root) NOPASSWD: /usr/bin/nbfc config -s HP_Preventive, /usr/bin/nbfc restart, /usr/bin/nbfc set -s *'
echo $SUDOERS_LINE | sudo tee $SUDOERS_FILE > /dev/null
sudo chmod 440 $SUDOERS_FILE
echo       ✓ sudoers configurado

echo
echo [6/7] Copiando servicio systemd...
mkdir -p $HOME/.config/systemd/user
cp $SERVICE_SRC $SERVICE_DST
echo       ✓ Servicio copiado a $SERVICE_DST

echo
echo [7/7] Iniciando servicios...
systemctl --user daemon-reload
echo       ✓ daemon-reload completado

sudo systemctl enable nbfc_service 2>/dev/null || true
sudo systemctl start nbfc_service 2>/dev/null || true
echo       ✓ nbfc_service iniciado

systemctl --user enable --now nbfc-guardian.service
sleep 2

if systemctl --user is-active --quiet nbfc-guardian.service; then
    echo       ✓ nbfc-guardian activo
else
    echo       ✗ Error al iniciar nbfc-guardian
    systemctl --user status nbfc-guardian.service --no-pager
    exit 1
fi

echo
echo ========================================
echo   Instalacion completada!
echo ========================================
echo
echo Comandos disponibles:
echo   nbfc-pro heavy on/off    - Modo Heavy umbrales 55 grados
echo   nbfc-pro pasivo on/off   - Modo Pasivo sin reinicios mayor a 60 grados
echo   nbfc-pro reposo on/off   - Modo Reposo ventilado manual
echo   nbfc-pro status          - Ver estado
echo   nbfc-pro logs            - Ver logs
echo
echo Verificando estado actual:
nbfc-pro status