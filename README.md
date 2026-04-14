# NBFC Guardian Pro 🛡️

Automated Thermal Protection and Performance Optimization for HP Laptops on Linux.

## Requisitos Previos

- [nbfc-linux](https://github.com/nbfc-linux/nbfc-linux) - Servicio base de control de ventiladores
- Usuario con acceso sudo

Este proyecto depende de nbfc-linux para el control base de ventiladores. El installer verificará que esté instalado antes de proceder.

## Why?
Many HP laptops (especially circa 2015) have buggy ACPI/Firmware that ignores OS fan control signals, prioritizing silence over hardware integrity. This leads to massive thermal throttling and system freezes.

**NBFC Guardian Pro** wins the fight by persistently forcing fan profiles and monitoring CPU health.

## Features
- **Brute Force Control:** Re-injects fan profiles every 30s to override ACPI hijacking.
- **Deep Hysteresis:** Avoids fan "stutter" by using a 10°C cooling gap.
- **Multiple Operating Modes:**
  - **Normal:** Default mode with 65°C threshold
  - **Heavy:** Aggressive cooling with 60°C threshold
  - **Pasivo:** Passive mode - ignores temp >60°C, cooldown 180s for quiet nights
  - **Reposo:** Manual fan control with soft curves, no restarts
- **User-space Service:** Runs as a systemd user service with smart process management.
- **CLI Tool (`nbfc-pro`):** Easy management of all modes and log monitoring.
- **Memory Safety:** Includes wrappers for memory-intensive apps (Electron) using cgroups.

## Installation

1. Primero instala [nbfc-linux](https://github.com/nbfc-linux/nbfc-linux):
   ```bash
   git clone https://github.com/nbfc-linux/nbfc-linux.git
   cd nbfc-linux
   ./install.sh
   ```

2. Luego instala NBFC Guardian Pro:
   ```bash
   git clone https://github.com/0gerardo0/nbfc-guardian-pro.git
   cd nbfc-guardian-pro
   ./install.sh
   ```

   El installer te preguntará qué perfil de ventiladores usar. Puedes seleccionar uno de los disponibles en `configs/` o usar el default.

## Perfiles Personalizados

Este proyecto soporta perfiles personalizados de ventiladores. Ver la guía avanzada en [docs/PERFILES.md](docs/PERFILES.md) para aprender a:

- Crear tu propio perfil JSON
- Usar herramientas como nbfc-discover y nbfc-qt
- Ajustar umbrales y curvas de ventiladores

### Cambiar perfil después de instalado:
```bash
nbfc-pro profile              # Ver perfil actual y disponibles
nbfc-pro profile Mi_Perfil     # Cambiar a otro perfil
```

## Usage
```bash
nbfc-pro status          # Ver estado actual
nbfc-pro heavy on        # Modo Heavy (umbral 55°C)
nbfc-pro heavy off       # Desactivar modo Heavy
nbfc-pro pasivo on       # Modo Pasivo (para noche, sin reinicios >60°C)
nbfc-pro pasivo off      # Desactivar modo Pasivo
nbfc-pro reposo on       # Modo Reposo (ventilador manual suave)
nbfc-pro reposo off      # Desactivar modo Reposo
nbfc-pro logs           # Ver logs del servicio
nbfc-pro profile        # Ver perfil actual
nbfc-pro profile NOMBRE # Cambiar perfil
```

## Mode Comparison
| Mode | Behavior | Use Case |
|------|----------|----------|
| Normal | Re-injects profile ≥65°C | Default |
| Heavy | Re-injects profile ≥60°C | Gaming/heavy load |
| Pasivo | Ignores >60°C, restart ≤60°C (180s cooldown) | Night/quiet |
| Reposo | Manual fan control, no restarts | Maximum silence |

## Performance Impact
In benchmarks, this system provided a **72% increase** in sustained CPU frequency under stress.

## License
MIT
