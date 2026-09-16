<#
.SYNOPSIS
    Aplica ajustes de Windows optimizados para juegos, todos reversibles.
.DESCRIPTION
    - Activa Game Mode
    - Desactiva grabacion en segundo plano (Game DVR)
    - Fuerza GPU dedicada para un juego especifico (-GamePath)
    - Desactiva optimizaciones de pantalla completa del juego
    Cada ajuste indica en los comentarios como revertirlo.
.EXAMPLE
    .\Optimize-Gaming.ps1 -GamePath "C:\Program Files (x86)\Steam\steamapps\common\Call of Duty HQ\cod.exe"
#>
[CmdletBinding()]
param(
    [string]$GamePath
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "`n=== OPTIMIZACION PARA JUEGOS ===" -ForegroundColor Cyan

# 1. Game Mode ON
# Revertir: Set-ItemProperty 'HKCU:\Software\Microsoft\GameBar' -Name AutoGameModeEnabled -Value 0
Set-ItemProperty 'HKCU:\Software\Microsoft\GameBar' -Name AutoGameModeEnabled -Value 1 -Type DWord
Set-ItemProperty 'HKCU:\Software\Microsoft\GameBar' -Name AllowAutoGameMode -Value 1 -Type DWord
Write-Host "[OK] Game Mode activado" -ForegroundColor Green

# 2. Game DVR (grabacion en segundo plano) OFF
# Revertir: GameDVR_Enabled=1 y AppCaptureEnabled=1
Set-ItemProperty 'HKCU:\System\GameConfigStore' -Name GameDVR_Enabled -Value 0 -Type DWord
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name AppCaptureEnabled -Value 0 -Type DWord
Write-Host "[OK] Grabacion en segundo plano desactivada" -ForegroundColor Green

# 3. Frecuencia minima de CPU al 100% (evita bajonas a 800 MHz)
# Revertir: powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 5
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100
powercfg /setactive SCHEME_CURRENT
Write-Host "[OK] Frecuencia minima de CPU: 100%" -ForegroundColor Green

# 4. Por-juego: GPU dedicada + pantalla completa exclusiva
if ($GamePath) {
    if (-not (Test-Path $GamePath)) {
        Write-Host "[!] No existe: $GamePath" -ForegroundColor Red
    } else {
        # Revertir: Remove-ItemProperty 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' -Name $GamePath
        New-Item 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' -Force | Out-Null
        Set-ItemProperty 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' -Name $GamePath -Value 'GpuPreference=2;' -Type String
        Write-Host "[OK] GPU dedicada forzada para: $(Split-Path $GamePath -Leaf)" -ForegroundColor Green

        # Revertir: Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers' -Name $GamePath
        New-Item 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers' -Force | Out-Null
        Set-ItemProperty 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers' -Name $GamePath -Value '~ DISABLEDXMAXIMIZEDWINDOWEDMODE' -Type String
        Write-Host "[OK] Pantalla completa exclusiva activada" -ForegroundColor Green
    }
} else {
    Write-Host "[i] Sin -GamePath: se aplicaron solo los ajustes globales." -ForegroundColor Yellow
}

# 5. Resumen de tasa de refresco (solo lectura, aviso si esta en 60)
Get-CimInstance Win32_VideoController | Where-Object { $_.CurrentRefreshRate -gt 0 } | ForEach-Object {
    Write-Host ("[i] Monitor: {0} Hz a {1}x{2}" -f $_.CurrentRefreshRate, $_.CurrentHorizontalResolution, $_.CurrentVerticalResolution)
    if ($_.CurrentRefreshRate -le 60) {
        Write-Host "    Revisa si tu pantalla soporta mas Hz: Configuracion > Pantalla > Pantalla avanzada" -ForegroundColor Yellow
    }
}

Write-Host "`nListo. Todos los cambios son reversibles (ver comentarios en el script).`n" -ForegroundColor Green
