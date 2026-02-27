# NBFC Guardian Pro 🛡️

Automated Thermal Protection and Performance Optimization for "Rebel" HP Laptops on Linux.

## Why?
Many HP laptops (especially circa 2015) have buggy ACPI/Firmware that ignores OS fan control signals, prioritizing silence over hardware integrity. This leads to massive thermal throttling and system freezes.

**NBFC Guardian Pro** wins the fight by persistently forcing fan profiles and monitoring CPU health.

## Features
- **Brute Force Control:** Re-injects fan profiles every 30s to override ACPI hijacking.
- **Deep Hysteresis:** Avoids fan "stutter" by using a 10°C cooling gap.
- **User-space Service:** Runs as a systemd user service with smart process management.
- **CLI Tool (`nbfc-pro`):** Easy management of "Heavy" modes and log monitoring.
- **Memory Safety:** Includes wrappers for memory-intensive apps (Electron) using cgroups.

## Installation
1. Install [nbfc-linux](https://github.com/nbfc-linux/nbfc-linux).
2. Copy your profile to `/usr/share/nbfc/configs/`.
3. Add sudoers rules for `nbfc config` and `nbfc restart`.
4. Enable the service:
   ```bash
   systemctl --user enable --now nbfc-guardian.service
   ```

## Performance Impact
In benchmarks, this system provided a **72% increase** in sustained CPU frequency under stress.

## License
MIT
