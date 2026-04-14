# Guía Avanzada: Perfiles Personalizados para NBFC Guardian Pro

## ¿Qué es un perfil de ventiladores?

Un perfil JSON define cómo NBFC controla los ventiladores de tu laptop. Incluye:
- Registers del Embedded Controller (EC)
- Umbrales de temperatura
- Curva de velocidad del ventilador
- Configuración de escritura de registros

---

## Estructura de un Perfil

```json
{
  // Identificación
  “NotebookModel”: “Mi_Perfil_Custom”,
  “Author”: “Tu_Nombre”,
  
  // Configuración general
  “EcPollInterval”: 80,
  “CriticalTemperature”: 92,
  “ReadWriteWords”: false,
  
  // Configuración de ventiladores
  “FanConfigurations”: [
    {
      “FanDisplayName”: “CPU Fan”,
      “ReadRegister”: 17,
      “WriteRegister”: 20,
      “MinSpeedValue”: 20,
      “MaxSpeedValue”: 59,
      
      // Sensores de temperatura
      “TemperatureAlgorithmType”: “Average”,
      “Sensors”: [“coretemp”, “k10temp”],
      
      // Umbrales de temperatura
      “TemperatureThresholds”: [
        { “UpThreshold”: 35, “DownThreshold”: 25, “FanSpeed”: 40.0 },
        { “UpThreshold”: 45, “DownThreshold”: 35, “FanSpeed”: 70.0 },
        { “UpThreshold”: 55, “DownThreshold”: 45, “FanSpeed”: 100.0 }
      ],
      
      // Overrides de velocidad
      “FanSpeedPercentageOverrides”: [
        { “FanSpeedPercentage”: 100, “FanSpeedValue”: 59, “TargetOperation”: “ReadWrite” }
      ]
    }
  ],
  
  // Configuración de registros
  “RegisterWriteConfigurations”: [
    {
      “WriteMode”: “Set”,
      “WriteOccasion”: “OnInitialization”,
      “Register”: 15,
      “Value”: 8,
      “Description”: “Override Manual Control”
    }
  ]
}
```

---

## Campos Detallados

### Campos Principales (ModelConfig)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `NotebookModel` | String | Nombre único de tu perfil |
| `Author` | String | Tu nombre |
| `EcPollInterval` | Integer | Intervalo de muestreo en ms (recomendado: 80-3000) |
| `CriticalTemperature` | Integer | Temperatura crítica (ventilador al 100%) |
| `CriticalTemperatureOffset` | Integer | Offset para reanudar operación normal |
| `ReadWriteWords` | Boolean | Usar registros de 16 bits |

### FanConfiguration

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `FanDisplayName` | String | Nombre identificador del ventilador |
| `ReadRegister` | Integer (0-255) | Registro EC para lectura de velocidad |
| `WriteRegister` | Integer (0-255) | Registro EC para escribir velocidad |
| `MinSpeedValue` | Integer | Valor para velocidad mínima (0 = apagado) |
| `MaxSpeedValue` | Integer | Valor para velocidad máxima (100%) |
| `ResetRequired` | Boolean | Si necesita reset al cerrar |
| `FanSpeedResetValue` | Integer | Valor para reset |
| `Sensors` | Array | Sensores de temperatura (nombres, rutas, grupos) |
| `TemperatureAlgorithmType` | String | “Average”, “Min”, “Max” |

### TemperatureThresholds

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `UpThreshold` | Integer | Temperatura para SUBIR velocidad |
| `DownThreshold` | Integer | Temperatura para BAJAR velocidad |
| `FanSpeed` | Float (0-100) | Velocidad objetivo del ventilador |

**Patrón de diseño de umbrales:**

```json
// 1. Apagado/silencioso (opcional)
{ “UpThreshold”: 35, “DownThreshold”: 0, “FanSpeed”: 0.0 }

// 2. Velocidad baja
{ “UpThreshold”: 45, “DownThreshold”: 35, “FanSpeed”: 40.0 }

// 3. Velocidad media
{ “UpThreshold”: 55, “DownThreshold”: 45, “FanSpeed”: 70.0 }

// 4. Velocidad máxima
{ “UpThreshold”: 65, “DownThreshold”: 55, “FanSpeed”: 100.0 }
```

### RegisterWriteConfigurations

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `WriteMode` | String | “Set”, “And”, “Or” |
| `WriteOccasion` | String | “OnInitialization” o “OnWriteFanSpeed” |
| `Register` | Integer (0-255) | Registro EC a escribir |
| `Value` | Integer | Valor a escribir |
| `ResetRequired` | Boolean | Reset al cerrar servicio |
| `ResetValue` | Integer | Valor para reset |

---

## Cómo Crear tu Propio Perfil

### Método 1: Usando nbfc-discover (Recomendado para principiantes)

```bash
# Instalar dependencias
sudo pacman -S acpi

# Ejecutar asistente de descubrimiento
sudo nbfc-discover

# Esto escaneará tu hardware EC y sugerirá configuraciones
```

### Método 2: Usando nbfc-qt (Interfaz gráfica)

```bash
# Instalar
sudo pacman -S nbfc-qt

# Ejecutar
nbfc-qt

# Ir a Configuration > Create New Profile
# Seguir el asistente gráfico
```

### Método 3: Explorando Registros EC

```bash
# Ver registros disponibles
ec_probe --list

# Monitorear un registro específico
sudo ec_probe --monitor 0x17

#dump de todos los registros
sudo ec_probe --dump
```

### Método 4: Basándote en Perfiles Existentes

```bash
# Ver todos los perfiles disponibles
ls /usr/share/nbfc/configs/

# Ver un perfil existente como ejemplo
cat /usr/share/nbfc/configs/HP_Preventive.json

# Copiar y modificar uno existente
cp /usr/share/nbfc/configs/HP_Preventive.json ~/Mi_Perfil.json
```

---

## Encontrar los Registros Correctos

### Paso 1: Identificar tu modelo

```bash
nbfc get-model-name
```

### Paso 2: Listar configuraciones recomendadas

```bash
sudo nbfc config --recommend
```

### Paso 3: Probar configuraciones existentes

```bash
# Listar todas
sudo nbfc config --list

# Probar una
sudo nbfc config --set HP_ProBook_640_G2
sudo nbfc restart
nbfc status -a
```

### Paso 4: Ajustar registros manualmente

Si ninguna configuración funciona, necesitas encontrar los registros EC:

1. **Encontrar registro de lectura:**
   ```bash
   # Monitorea cambios mientras mueves el ventilador
   sudo ec_probe --monitor <registro>
   ```

2. **Encontrar registro de escritura:**
   ```bash
   # Escribe valores y observa cambios
   sudo nbfc set --speed 50
   sudo ec_probe --monitor <registro>
   ```

---

## Grupos de Sensores

| Grupo | Descripción | Sensores típicos |
|-------|-------------|-------------------|
| `@CPU` | CPU | coretemp, k10temp, zenpower |
| `@GPU` | Gráfica | amdgpu, nvidia, nouveau, radeon |
| por nombre | hwmon | “temp1_input”, “k10temp” |
| por ruta | específico | “/sys/class/hwmon/hwmon4/temp1_input” |
| por comando | custom | “$ echo 42000” |

Ejemplo:
```json
“Sensors”: [“coretemp”, “k10temp”, “@CPU”]
```

---

## Usar Perfiles con NBFC Guardian Pro

### Instalación con Perfil Personalizado

```bash
./install.sh
# El instalador preguntará qué perfil usar
```

### Cambiar Perfil Después de Instalado

```bash
# Opción 1: Variable de entorno
export NBFC_PROFILE=Mi_Perfil_Custom

# Opción 2: Comando directo
sudo nbfc config -s Mi_Perfil_Custom
sudo nbfc restart
```

### nbfc-pro con Perfil Personalizado

```bash
nbfc-pro status --profile Mi_Perfil_Custom
```

---

## Casos de Uso y Ejemplos

### Para Gaming (enfriar más)

```json
{
  “NotebookModel”: “Mi_Gaming”,
  “CriticalTemperature”: 85,
  “TemperatureThresholds”: [
    { “UpThreshold”: 40, “DownThreshold”: 0, “FanSpeed”: 30.0 },
    { “UpThreshold”: 50, “DownThreshold”: 40, “FanSpeed”: 50.0 },
    { “UpThreshold”: 60, “DownThreshold”: 50, “FanSpeed”: 70.0 },
    { “UpThreshold”: 70, “DownThreshold”: 60, “FanSpeed”: 100.0 }
  ]
}
```

### Para Silencio (nocturno)

```json
{
  “NotebookModel”: “Mi_Silencioso”,
  “CriticalTemperature”: 95,
  “TemperatureThresholds”: [
    { “UpThreshold”: 50, “DownThreshold”: 0, “FanSpeed”: 0.0 },
    { “UpThreshold”: 65, “DownThreshold”: 50, “FanSpeed”: 30.0 },
    { “UpThreshold”: 80, “DownThreshold”: 65, “FanSpeed”: 60.0 },
    { “UpThreshold”: 90, “DownThreshold”: 80, “FanSpeed”: 100.0 }
  ]
}
```

### Para Desarrollo (balance)

```json
{
  “NotebookModel”: “Mi_Dev_Balance”,
  “EcPollInterval”: 100,
  “CriticalTemperature”: 90,
  “TemperatureThresholds”: [
    { “UpThreshold”: 45, “DownThreshold”: 0, “FanSpeed”: 0.0 },
    { “UpThreshold”: 55, “DownThreshold”: 45, “FanSpeed”: 40.0 },
    { “UpThreshold”: 65, “DownThreshold”: 55, “FanSpeed”: 70.0 },
    { “UpThreshold”: 75, “DownThreshold”: 65, “FanSpeed”: 100.0 }
  ]
}
```

---

## Troubleshooting

### El ventilador no responde

1. Verifica que el servicio esté corriendo:
   ```bash
   systemctl status nbfc_service
   ```

2. Revisa los registros EC:
   ```bash
   sudo ec_probe --dump
   ```

3. Verifica los permisos:
   ```bash
   ls -la /dev/ec
   ```

### La temperatura no se lee

1. Verifica los sensores:
   ```bash
   nbfc status -a
   ```

2. Especifica sensores manualmente en tu perfil:
   ```json
   “Sensors”: [“/sys/class/hwmon/hwmon2/temp1_input”]
   ```

### Conflictos con ACPI

Si el BIOS ignora los comandos:

1. Usa el modo “fuerza bruta” de Guardian (reinyecta cada 30s)
2. Configura RegisterWriteConfigurations para inicialización

---

## Referencias

- Repositorio principal: https://github.com/nbfc-linux/nbfc-linux
- Wiki: https://github.com/nbfc-linux/nbfc-linux/wiki
- Configuraciones existentes: `/usr/share/nbfc/configs/`