#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."
SCRIPT_DIR="$(pwd)"
TARGET_DIR="/usr/local/bin"
SERVICE_FILE="nbfc-guardian.service"
SERVICE_SRC="$SCRIPT_DIR/configs/$SERVICE_FILE"
SERVICE_DST="$HOME/.config/systemd/user/$SERVICE_FILE"

echo "========================================"
echo "  NBFC Guardian Pro - Instalador"
echo "========================================"
echo ""

if [[ $EUID -eq 0 ]]; then
    echo "ERROR: No ejecutes como root. Usa tu usuario normal."
    exit 1
fi

echo "[1/5] Copiando scripts a $TARGET_DIR..."
sudo cp "$SCRIPT_DIR/nbfc-guardian.sh" "$TARGET_DIR/"
sudo cp "$SCRIPT_DIR/nbfc-pro" "$TARGET_DIR/"
sudo chmod +x "$TARGET_DIR/nbfc-guardian.sh"
sudo chmod +x "$TARGET_DIR/nbfc-pro"
echo "      ✓ Scripts copiados"

echo ""
echo "[2/5] Verificando scripts..."
if [[ -x "$TARGET_DIR/nbfc-guardian.sh" ]] && [[ -x "$TARGET_DIR/nbfc-pro" ]]; then
    echo "      ✓ Permisos correctos"
else
    echo "      ✗ Error en permisos"
    exit 1
fi

echo ""
echo "[3/5] Copiando servicio systemd..."
mkdir -p "$HOME/.config/systemd/user"
cp "$SERVICE_SRC" "$SERVICE_DST"
echo "      ✓ Servicio copiado a $SERVICE_DST"

echo ""
echo "[4/5] Recargando systemd..."
systemctl --user daemon-reload
echo "      ✓ daemon-reload completado"

echo ""
echo "[5/5] Reiniciando servicio..."
systemctl --user restart nbfc-guardian.service
sleep 2

if systemctl --user is-active --quiet nbfc-guardian.service; then
    echo "      ✓ Servicio activo"
else
    echo "      ✗ Error al iniciar servicio"
    systemctl --user status nbfc-guardian.service --no-pager
    exit 1
fi

echo ""
echo "========================================"
echo "  Instalación completada!"
echo "========================================"
echo ""
echo "Comandos disponibles:"
echo "  nbfc-pro heavy on|off    - Modo Heavy (umbral 55°C)"
echo "  nbfc-pro pasivo on|off   - Modo Pasivo (sin reinicios >60°C)"
echo "  nbfc-pro reposo on|off   - Modo Reposo (ventilador manual)"
echo "  nbfc-pro status          - Ver estado"
echo "  nbfc-pro logs            - Ver logs"
echo ""
echo "Verificando estado actual:"
nbfc-pro status