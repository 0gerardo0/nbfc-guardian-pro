# NBFC Guardian Pro: Análisis de Ingeniería y Optimización Térmica en Arch Linux

## 1. Introducción y Contexto del Hardware
El proyecto surge de la necesidad de estabilizar una laptop **HP (Modelo 2015) con procesador AMD A9-9420**. Este hardware presenta una limitación crítica: el firmware (BIOS/ACPI) prioriza el silencio sobre la integridad térmica, manteniendo los ventiladores al mínimo incluso cuando el procesador alcanza los **99°C**.

### El Desafío Técnico
1. **Bugs de Firmware:** Errores de `APIC ID mismatch` y `ACPI symbols not found` que impiden que el kernel gestione correctamente las interrupciones y la energía.
2. **Conflicto de Control:** El *Embedded Controller* (EC) de HP sobrescribe cualquier cambio de software cada 30-60 segundos, volviendo al modo silencioso.
3. **Fugas de Recursos:** Aplicaciones pesadas (Electron) como Antigravity provocan picos de memoria que congelan el bus de datos USB y el sistema completo.

---

## 2. Evolución de la Solución (Cronología de Versiones)

### Fase I: Gestión de Memoria (Seguridad)
Inicialmente se intentó `ulimit` para contener a Antigravity, pero esto causaba un `Trace/breakpoint trap` porque Electron requiere mapear grandes bloques de memoria virtual.
* **Solución Final:** Migración a **cgroups v2** vía `systemd-run`.
* **Comando:**
  ```bash
  systemd-run --user --scope -p MemoryMax=4G -p MemoryHigh=3.5G /opt/antigravity/antigravity
  ```

### Fase II: Automatización Térmica (El Motor)
Se creó un script en Bash para monitorear `/sys/class/thermal/` y ejecutar `nbfc restart`.
* **Problema:** El sistema entraba en "ciclos de rebote" (prende/apaga cada 5 segundos).
* **Solución:** Implementación de **Histéresis Profunda** (Activa a 60°C, apaga a 50°C).

### Fase III: La "Fuerza Bruta" contra el ACPI
Se descubrió que el ACPI de HP recuperaba el control incluso con el Guardián activo.
* **Estrategia Final:** Reinyección forzada del perfil de configuración en cada ciclo.
* **Comando de Insistencia:**
  ```bash
  sudo nbfc config -s "HP_Preventive" && sudo nbfc restart
  ```

---

## 3. Análisis de Evidencia Empírica

Se realizaron dos pruebas de estrés controladas de 120 segundos utilizando `stress` y monitoreadas con `s-tui`.

### Comparativa de Datos Crudos
| Métrica | Sistema ACPI (Stock) | NBFC Guardian Pro | Delta |
| :--- | :--- | :--- | :--- |
| **Frecuencia Media** | 1541.4 MHz | 2655.2 MHz | **+72.2%** |
| **Frecuencia Mínima** | 1.5 MHz | 1796.7 MHz | **Estabilidad Total** |
| **Temperatura Media** | 61.4 °C | 83.6 °C | Gestión Forzada |
| **Temperatura Máxima** | 89.1 °C | 93.2 °C | Límite Seguro |

### Interpretación
El sistema ACPI de fábrica "mutila" el CPU bajando la frecuencia a casi 0 MHz para reducir el calor por falta de ventilación. **NBFC Guardian Pro** permite que el procesador trabaje a su máxima capacidad sostenida al garantizar que el ventilador nunca se detenga bajo carga.

---

## 4. Implementación Técnica Final

### A. El Servicio de Usuario (`nbfc-guardian.service`)
Configurado con `KillMode=process` para evitar conflictos de permisos entre los procesos root de NBFC y el script de usuario.

### B. El Guardián (`nbfc-guardian.sh`)
```bash
# Lógica de insistencia (cada 30s)
if [[ "$ESTADO" == "REPOSO" ]] || [[ "$TIEMPO_TRANSCURRIDO" -ge 30 ]]; then
    sudo nbfc config -s "HP_Preventive" && sudo nbfc restart
fi
```

### C. Herramienta de Gestión (`nbfc-pro`)
Interfaz CLI para activar el **Modo Heavy** (baja el umbral de activación de 65°C a 60°C) y consultar logs en tiempo real.

---

## 5. Conclusiones y Lecciones Aprendidas
1. **Linux en Laptops HP:** El ACPI es el enemigo número uno. No basta con pedirle al ventilador que encienda; hay que insistir constantemente.
2. **Cgroups > Ulimit:** Para aplicaciones modernas basadas en Chromium, `systemd-run` es la única forma segura de limitar recursos sin romper el binario.
3. **La Potencia Oculta:** Un hardware de 2015 no es necesariamente lento; está limitado por su propia gestión térmica conservadora.
