<#
.SYNOPSIS
    Chequeo de salud del PC: disco, RAM, GPU, procesos pesados y uptime.
.DESCRIPTION
    Solo lectura: no modifica nada. Ideal para diagnosticar antes de optimizar.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "`n=== CHEQUEO DE SALUD ===" -ForegroundColor Cyan

# --- Disco ---
Write-Host "`n[Discos]" -ForegroundColor Yellow
Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null } | ForEach-Object {
    $totalGB = ($_.Used + $_.Free) / 1GB
    $freeGB = $_.Free / 1GB
    $pct = if ($totalGB -gt 0) { [math]::Round($freeGB / $totalGB * 100, 0) } else { 0 }
    $color = if ($pct -lt 10) { 'Red' } elseif ($pct -lt 20) { 'Yellow' } else { 'Green' }
    Write-Host ("  {0}: {1:N1} GB libres de {2:N1} GB ({3}%)" -f $_.Name, $freeGB, $totalGB, $pct) -ForegroundColor $color
}

# --- RAM ---
$os = Get-CimInstance Win32_OperatingSystem
$totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$usedRAM = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 1)
$ramPct = [math]::Round($usedRAM / $totalRAM * 100, 0)
Write-Host "`n[RAM]" -ForegroundColor Yellow
$color = if ($ramPct -gt 85) { 'Red' } elseif ($ramPct -gt 70) { 'Yellow' } else { 'Green' }
Write-Host ("  En uso: {0} / {1} GB ({2}%)" -f $usedRAM, $totalRAM, $ramPct) -ForegroundColor $color

# --- GPU (si es NVIDIA) ---
Write-Host "`n[GPU]" -ForegroundColor Yellow
$smi = "nvidia-smi"
if (Get-Command $smi -ErrorAction SilentlyContinue) {
    $raw = & $smi --query-gpu=name,utilization.gpu,memory.used,temperature.gpu --format=csv,noheader
    Write-Host ("  {0}" -f $raw)
} else {
    Get-CimInstance Win32_VideoController | ForEach-Object {
        Write-Host ("  {0} (driver {1})" -f $_.Name, $_.DriverVersion)
    }
}

# --- CPU ---
Write-Host "`n[CPU]" -ForegroundColor Yellow
(Get-CimInstance Win32_Processor) | ForEach-Object {
    Write-Host ("  {0}" -f $_.Name)
    Write-Host ("  Velocidad: {0} MHz | Carga: {1}%" -f $_.CurrentClockSpeed, $_.LoadPercentage)
}

# --- Procesos pesados ---
Write-Host "`n[Top 10 procesos por RAM]" -ForegroundColor Yellow
Get-Process | Group-Object Name | ForEach-Object {
    [PSCustomObject]@{
        Proceso    = $_.Name
        RAM_MB     = [math]::Round(($_.Group | Measure-Object WorkingSet64 -Sum).Sum / 1MB, 0)
        Instancias = $_.Count
    }
} | Sort-Object RAM_MB -Descending | Select-Object -First 10 | Format-Table -AutoSize

# --- Uptime ---
$up = (Get-Date) - $os.LastBootUpTime
Write-Host ("[Uptime] {0} dias {1} horas {2} min" -f $up.Days, $up.Hours, $up.Minutes)
if ($up.Days -ge 7) {
    Write-Host "  Sugerencia: hace mas de una semana que no reinicias." -ForegroundColor Yellow
}

Write-Host "`nChequeo completo. Sin cambios aplicados.`n" -ForegroundColor Green
