<#
.SYNOPSIS
    Registra el uso de GPU en un CSV cada 5 segundos mientras jugas.
.DESCRIPTION
    Genera gpu_log.csv en el Escritorio. Para con Ctrl+C o cuando
    cierras el juego. Sirve para correlacionar FPS con uso de GPU.
.EXAMPLE
    .\Monitor-GPU.ps1
#>
[CmdletBinding()]
param(
    [int]$IntervalSeconds = 5
)

$ErrorActionPreference = 'SilentlyContinue'

if (-not (Get-Command nvidia-smi -ErrorAction SilentlyContinue)) {
    Write-Host "Este script requiere una GPU NVIDIA con nvidia-smi en el PATH." -ForegroundColor Red
    return
}

$log = "$env:USERPROFILE\Desktop\gpu_log.csv"
"hora,uso_gpu_pct,vram_MB,potencia_W,reloj_MHz,temp_C" | Out-File $log -Encoding utf8

Write-Host "Monitoreando GPU cada $IntervalSeconds s. Ctrl+C para parar." -ForegroundColor Yellow
Write-Host "Log: $log" -ForegroundColor Yellow

while ($true) {
    $raw = nvidia-smi --query-gpu=utilization.gpu,memory.used,power.draw,clocks.gr,temperature.gpu --format=csv,noheader,nounits
    $v = $raw -split ',\s*'
    $linea = "{0},{1},{2},{3},{4},{5}" -f (Get-Date -Format 'HH:mm:ss'), $v[0], $v[1], $v[2], $v[3], $v[4]
    $linea | Out-File $log -Append -Encoding utf8
    Write-Host ("  GPU {0}% | VRAM {1} MB | {2} W | {3} MHz | {4} C" -f $v[0], $v[1], $v[2], $v[3], $v[4])
    Start-Sleep -Seconds $IntervalSeconds
}
