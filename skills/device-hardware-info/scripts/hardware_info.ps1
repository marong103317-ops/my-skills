# Collect local hardware info on Windows.
# Run with: powershell -ExecutionPolicy Bypass -File hardware_info.ps1
$ErrorActionPreference = 'SilentlyContinue'

function Section($t) { Write-Output ""; Write-Output "=== $t ===" }

Section "Host"
Write-Output $env:COMPUTERNAME

Section "OS"
$os = Get-CimInstance Win32_OperatingSystem
Write-Output "$($os.Caption) build $($os.BuildNumber)"
$cs = Get-CimInstance Win32_ComputerSystem
Write-Output "Model: $($cs.Manufacturer) $($cs.Model)"

Section "CPU"
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
Write-Output "Model: $($cpu.Name.Trim())"
Write-Output "Cores: $($cpu.NumberOfCores) physical / $($cpu.NumberOfLogicalProcessors) logical"

Section "Memory"
$totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
Write-Output "Total: $totalGB GB, Free: $freeGB GB"

Section "Disk"
Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object {
  $sizeGB = [math]::Round($_.Size / 1GB, 1)
  $free = [math]::Round($_.FreeSpace / 1GB, 1)
  Write-Output "$($_.DeviceID) total $sizeGB GB, free $free GB"
}

Section "GPU"
Get-CimInstance Win32_VideoController | ForEach-Object { Write-Output $_.Name }

Section "Battery"
$batt = Get-CimInstance Win32_Battery | Select-Object -First 1
if ($batt) {
  Write-Output "Battery: $($batt.EstimatedChargeRemaining)%"
} else {
  Write-Output "No battery"
}
