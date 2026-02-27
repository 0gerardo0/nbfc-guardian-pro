#!/bin/bash
TEMP_ALTA=65
TEMP_BAJA=50
TEMP_HEAVY=60
TEMP_CRITICAL=85
FLAG_HEAVY="/tmp/nbfc-heavy"
ESTADO="REPOSO"

ULTIMO_REINICIO=0
INTERVALO_GRACIA=30

while true; do
    CURRENT_TEMP=$(nbfc status -a | grep "Temperature" | awk '{print $3}' | cut -d. -f1)
    
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
                # FUERZA BRUTA: Re-aplicar configuración y reiniciar
                sudo /usr/bin/nbfc config -s "HP_Preventive" && sudo /usr/bin/nbfc restart
                ULTIMO_REINICIO=$TIEMPO_ACTUAL
                
                if [[ "$ESTADO" == "REPOSO" ]]; then
                    echo "ALERTA: Forzando perfil HP_Preventive a ${CURRENT_TEMP}°C."
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
