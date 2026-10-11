#!/usr/bin/env bash
# Collect local hardware info on macOS and Linux.
# Usage: bash hardware_info.sh
set -u

section() { printf '\n=== %s ===\n' "$1"; }

OS="$(uname -s)"
ARCH="$(uname -m)"

section "Host"
hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "unknown"

section "OS ($ARCH)"
case "$OS" in
  Darwin)
    echo "macOS $(sw_vers -productVersion 2>/dev/null) (build $(sw_vers -buildVersion 2>/dev/null))"
    echo "Model: $(sysctl -n hw.model 2>/dev/null || echo unknown)"
    ;;
  Linux)
    if [ -r /etc/os-release ]; then
      . /etc/os-release
      echo "${PRETTY_NAME:-Linux}"
    else
      echo "Linux"
    fi
    if [ -r /sys/devices/virtual/dmi/id/product_name ]; then
      echo "Model: $(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null)"
    fi
    ;;
  *)
    echo "Unsupported OS: $OS. On Windows run scripts/hardware_info.ps1 instead."
    exit 1
    ;;
esac

section "CPU"
case "$OS" in
  Darwin)
    echo "Model: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo unknown)"
    echo "Cores: $(sysctl -n hw.physicalcpu 2>/dev/null || echo '?') physical / $(sysctl -n hw.ncpu 2>/dev/null || echo '?') logical"
    ;;
  Linux)
    if command -v lscpu >/dev/null 2>&1; then
      lscpu 2>/dev/null | grep -E '^(Architecture|Model name|Socket\(s\)|Core\(s\) per socket|CPU\(s\)):' || true
    else
      grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2- || echo "Model: unknown"
      echo "Logical cores: $(nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo '?')"
    fi
    ;;
esac

section "Memory"
case "$OS" in
  Darwin)
    total_bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
    if [ "$total_bytes" -gt 0 ] 2>/dev/null; then
      echo "Total: $((total_bytes / 1073741824)) GB"
    fi
    top -l 1 2>/dev/null | grep -m1 PhysMem || true
    ;;
  Linux)
    free -h 2>/dev/null || awk '/MemTotal/ {printf "Total: %.1f GB\n", $2 / 1048576}' /proc/meminfo 2>/dev/null
    ;;
esac

section "Disk (root)"
df -h / 2>/dev/null | sed -n '1,2p'

section "GPU"
case "$OS" in
  Darwin)
    system_profiler SPDisplaysDataType 2>/dev/null | grep -E 'Chipset Model|Metal' | sed 's/^[[:space:]]*//' | head -6
    ;;
  Linux)
    gpu=""
    if command -v lspci >/dev/null 2>&1; then
      gpu="$(lspci 2>/dev/null | grep -Ei 'vga|3d controller|display controller')"
    fi
    if [ -z "$gpu" ] && command -v nvidia-smi >/dev/null 2>&1; then
      gpu="$(nvidia-smi -L 2>/dev/null)"
    fi
    if [ -n "$gpu" ]; then
      echo "$gpu"
    else
      echo "unknown (install pciutils for GPU info)"
    fi
    ;;
esac

section "Battery"
case "$OS" in
  Darwin)
    pmset -g batt 2>/dev/null | grep -E 'InternalBattery|Now drawing' | head -2
    if [ "$(pmset -g batt 2>/dev/null | grep -cE 'InternalBattery|Now drawing')" -eq 0 ]; then
      echo "No battery"
    fi
    ;;
  Linux)
    found=0
    for d in /sys/class/power_supply/BAT*; do
      if [ -e "$d/capacity" ]; then
        echo "$(basename "$d"): $(cat "$d/capacity" 2>/dev/null)% ($(cat "$d/status" 2>/dev/null))"
        found=1
      fi
    done
    if [ "$found" -eq 0 ]; then
      echo "No battery"
    fi
    ;;
esac

exit 0
