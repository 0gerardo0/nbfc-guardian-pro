#!/bin/bash
NBFC_PROFILE_FILE=/etc/nbfc-guardian/profile
NBFC_PROFILE=${NBFC_PROFILE:-$(cat $NBFC_PROFILE_FILE 2>/dev/null || echo HP_Preventive)}

TEMP_ALTA=65
TEMP_BAJA=50
TEMP_HEAVY=60
TEMP_CRITICAL=85
TEMP_PASIVO_REINICIO=60

FLAG_HEAVY="/tmp/nbfc-heavy"
FLAG_REPOSO="/tmp/nbfc-reposo"
FLAG_PASIVO="/tmp/nbfc-pasivo"

ESTADO="REPOSO"

ULTIMO_REINICIO=0
ULTIMO_REINICIO_PASIVO=0
INTERVALO_GRACIA=30
INTERVALO_PASIVO=180

set_fan_speed() {
    local speed=$1
    sudo nbfc set -s "$speed" 2>/dev/null
}

while true; do
    CURRENT_TEMP=$(nbfc status -a | grep "Temperature" | awk '{print $3}' | cut -d. -f1)
    
    if [[ -f "$FLAG_REPOSO" ]]; then
        if [[ "$CURRENT_TEMP" =~ ^[0-9]+$ ]]; then
            if [[ "$CURRENT_TEMP" -ge 80 ]]; then
                notify-send "NBFC REPOSO" "Temperatura alta: ${CURRENT_TEMP}°C - forzando máximo ventiladores." -u normal
                set_fan_speed 100
            elif [[ "$CURRENT_TEMP" -ge 70 ]]; then
                set_fan_speed 70
            elif [[ "$CURRENT_TEMP" -ge 60 ]]; then
                set_fan_speed 50
            elif [[ "$CURRENT_TEMP" -le 55 ]]; then
                set_fan_speed 30
            fi
        fi
        sleep 10
        continue
    fi
    
    if [[ -f "$FLAG_PASIVO" ]]; then
        if [[ "$CURRENT_TEMP" =~ ^[0-9]+$ ]]; then
            TIEMPO_ACTUAL=$(date +%s)
            TIEMPO_TRANSCURRIDO=$((TIEMPO_ACTUAL - ULTIMO_REINICIO_PASIVO))
            
            if [[ "$CURRENT_TEMP" -gt "$TEMP_PASIVO_REINICIO" ]]; then
                echo "PASIVO: Temp ${CURRENT_TEMP}°C > ${TEMP_PASIVO_REINICIO}°C - Ignorando, nbfc maneja solo."
            elif [[ "$TIEMPO_TRANSCURRIDO" -ge "$INTERVALO_PASIVO" ]]; then
                sudo /usr/bin/nbfc config -s "$NBFC_PROFILE" && sudo /usr/bin/nbfc restart
                ULTIMO_REINICIO_PASIVO=$TIEMPO_ACTUAL
                echo "PASIVO: Temp ${CURRENT_TEMP}°C <= ${TEMP_PASIVO_REINICIO}°C - Reinicio para mantener rpm bajas."
            else
                echo "PASIVO: Temp ${CURRENT_TEMP}°C en rango seguro, cooldown activo ($((INTERVALO_PASIVO - TIEMPO_TRANSCURRIDO))s restantes)."
            fi
        fi
        sleep 10
        continue
    fi
    
    if [[ "$CURRENT_TEMP" =~ ^[0-9]+$ ]]; then
        UMBRAL=$TEMP_ALTA
        [[ -f "$FLAG_HEAVY" ]] && UMBRAL=$TEMP_HEAVY
        
        TIEMPO_ACTUAL=$(date +%s)
        TIEMPO_TRANSCURRIDO=$((TIEMPO_ACTUAL - ULTIMO_REINICIO))

        if [[ "$CURRENT_TEMP" -ge "$UMBRAL" ]]; then
            if [[ "$CURRENT_TEMP" -ge "$TEMP_CRITICAL" ]]; then
                notify-send "NBFC CRÍTICO" "¡Emergencia Térmica! ${CURRENT_TEMP}°C detectados." -u critical
            fi

            if [[ "$ESTADO" == "REPOSO" ]] || [[ "$TIEMPO_TRANSCURRIDO" -ge "$INTERVALO_GRACIA" ]]; then
                sudo /usr/bin/nbfc config -s "$NBFC_PROFILE" && sudo /usr/bin/nbfc restart
                ULTIMO_REINICIO=$TIEMPO_ACTUAL
                
                if [[ "$ESTADO" == "REPOSO" ]]; then
                    echo "ALERTA: Forzando perfil $NBFC_PROFILE a ${CURRENT_TEMP}°C."
                    ESTADO="ENFRIANDO"
                fi
            fi

        elif [[ "$CURRENT_TEMP" -le "$TEMP_BAJA" ]] && [[ "$ESTADO" == "ENFRIANDO" ]]; then
            ESTADO="REPOSO"
            sudo /usr/bin/nbfc restart
            echo "INFO: Temperatura normalizada (${CURRENT_TEMP}°C). Volviendo a modo reposo."
        fi
    fi
    sleep 5
done
