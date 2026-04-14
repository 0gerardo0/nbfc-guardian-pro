#!/bin/bash
set -e

SCRIPT_DIR_HOME=$(cd $(dirname $0) && pwd)
cd $SCRIPT_DIR_HOME
SCRIPT_DIR=$SCRIPT_DIR_HOME/scripts
TARGET_DIR=/usr/local/bin
SERVICE_FILE=nbfc-guardian.service
DEFAULT_CONFIG=HP_Preventive.json
SERVICE_SRC=$SCRIPT_DIR_HOME/configs/$SERVICE_FILE
SERVICE_DST=$HOME/.config/systemd/user/$SERVICE_FILE
CONFIG_SRC=$SCRIPT_DIR_HOME/configs/$DEFAULT_CONFIG
CONFIG_DST=/usr/share/nbfc/configs
SUDOERS_FILE=/etc/sudoers.d/nbfc-guardian

echo ========================================
echo   NBFC Guardian Pro - Instalador
echo ========================================
echo

if [[ $EUID -eq 0 ]]; then
    echo ERROR: No ejecutes como root. Usa tu usuario normal.
    exit 1
fi

echo [1/8] Verificando nbfc-linux...
if ! command -v nbfc &> /dev/null; then
    echo       ERROR: nbfc no encontrado. Instala primero nbfc-linux
    echo       https://github.com/nbfc-linux/nbfc-linux
    exit 1
fi
echo       OK: nbfc-linux detectado

echo
echo [2/8] Seleccionando perfil de ventiladores...
echo
echo       Perfiles disponibles en repo:
ls -1 $SCRIPT_DIR_HOME/configs/*.json 2>/dev/null | while read f; do
    basename “$f”
done | while read name; do
    echo       - $name
done

DEFAULT_NAME=$(basename $DEFAULT_CONFIG .json)
echo
echo -n Perfil a usar default $DEFAULT_NAME:
read NBFC_PROFILE

if [[ -z $NBFC_PROFILE ]]; then
    NBFC_PROFILE=$DEFAULT_NAME
fi

CONFIG_FILE=$NBFC_PROFILE.json
CONFIG_SRC=$SCRIPT_DIR_HOME/configs/$CONFIG_FILE

if [[ ! -f “$CONFIG_SRC” ]]; then
    echo       ERROR: Perfil $CONFIG_FILE no encontrado en configs/
    ls -1 $SCRIPT_DIR_HOME/configs/
    exit 1
fi

echo       OK: Perfil seleccionado: $NBFC_PROFILE

echo
echo [3/8] Copiando scripts a $TARGET_DIR...
sudo cp $SCRIPT_DIR/nbfc-guardian.sh $TARGET_DIR/
sudo cp $SCRIPT_DIR/nbfc-pro $TARGET_DIR/
sudo chmod +x $TARGET_DIR/nbfc-guardian.sh
sudo chmod +x $TARGET_DIR/nbfc-pro
echo       OK: Scripts copiados

echo
echo [4/8] Verificando scripts...
if [[ -x $TARGET_DIR/nbfc-guardian.sh ]] && [[ -x $TARGET_DIR/nbfc-pro ]]; then
    echo       OK: Permisos correctos
else
    echo       ERROR: Error en permisos
    exit 1
fi

echo
echo [5/8] Copiando configuracion $NBFC_PROFILE...
sudo cp “$CONFIG_SRC” $CONFIG_DST/
echo       OK: Configuracion copiada a $CONFIG_DST/$CONFIG_FILE

echo
echo [6/8] Configurando sudoers NOPASSWD...
SUDOERS_CONTENT=$(whoami)' ALL=(root) NOPASSWD: /usr/bin/nbfc config -s *, /usr/bin/nbfc restart, /usr/bin/nbfc set -s *'

# Crear archivo temporal y moverlo
TMP_SUDOERS=/tmp/nbfc-guardian-temp
echo $SUDOERS_CONTENT > $TMP_SUDOERS
sudo mv $TMP_SUDOERS $SUDOERS_FILE
sudo chmod 440 $SUDOERS_FILE
echo       OK: sudoers configurado para cualquier perfil

echo
echo [7/8] Copiando servicio systemd...
mkdir -p $HOME/.config/systemd/user
cp “$SERVICE_SRC” $SERVICE_DST
echo       OK: Servicio copiado a $SERVICE_DST

echo
echo [8/8] Iniciando servicios...
systemctl --user daemon-reload
echo       OK: daemon-reload completado

sudo nbfc config -s “$NBFC_PROFILE”
echo       OK: Perfil $NBFC_PROFILE aplicado

sudo systemctl enable nbfc_service 2>/dev/null || true
sudo systemctl start nbfc_service 2>/dev/null || true
echo       OK: nbfc_service iniciado

systemctl --user enable –now nbfc-guardian.service
sleep 2

if systemctl –user is-active –quiet nbfc-guardian.service; then
    echo       OK: nbfc-guardian activo
else
    echo       ERROR: Error al iniciar nbfc-guardian
    systemctl –user status nbfc-guardian.service –no-pager
    exit 1
fi

echo
echo ========================================
echo   Instalacion completada!
echo ========================================
echo
echo Perfil instalado: $NBFC_PROFILE
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