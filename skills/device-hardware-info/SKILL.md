---
name: device-hardware-info
description: Collect local hardware info (CPU, memory, disk, GPU, OS, battery) on macOS, Windows and Linux. Use when the user asks for 硬件信息, 设备信息, system specs, or machine specs of this device. Do not use for remote servers.
---

# Device Hardware Info

Report the local machine's hardware: host/model, OS version, CPU, memory, disk, GPU, battery.

## Steps

1. Detect the OS. Run `uname -s` in a shell — `Darwin` means macOS, `Linux` means Linux. Windows usually has no `uname`; assume Windows when running under PowerShell/cmd or when `uname -s` fails.
2. Run the matching script and capture its output.

   macOS / Linux:

   ```bash
   bash <skill-dir>/scripts/hardware_info.sh
   ```

   Windows (PowerShell):

   ```powershell
   powershell -ExecutionPolicy Bypass -File <skill-dir>\scripts\hardware_info.ps1
   ```

   `<skill-dir>` is this skill's own folder.
3. Summarize the output as a compact key-value table in the user's language. Keep the raw script output at hand in case the user wants details.

## Fallback probes (only when a script fails to run)

| Item | macOS | Linux | Windows (PowerShell) |
| --- | --- | --- | --- |
| OS / model | `sw_vers`, `sysctl -n hw.model` | `cat /etc/os-release` | `Get-CimInstance Win32_OperatingSystem` |
| CPU | `sysctl -n machdep.cpu.brand_string` | `lscpu` | `Get-CimInstance Win32_Processor` |
| Memory | `sysctl -n hw.memsize` | `free -h` | `Get-CimInstance Win32_OperatingSystem` |
| Disk | `df -h /` | `df -h /` | `Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3'` |
| GPU | `system_profiler SPDisplaysDataType` | `lspci` (filter VGA/3D lines) | `Get-CimInstance Win32_VideoController` |
| Battery | `pmset -g batt` | `cat /sys/class/power_supply/BAT*/capacity` | `Get-CimInstance Win32_Battery` |

## Rules

- Local machine only — never probe remote hosts or SSH targets with this skill.
- If one probe fails, report the rest and mark that item as unknown; do not abort the whole report.
- Do not install packages just to satisfy a probe (for example pciutils on Linux); report unknown instead.
