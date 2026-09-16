<#
.SYNOPSIS
    Modo Juego: libera RAM y VRAM cerrando apps de IA y wallpaper antes de jugar.
.DESCRIPTION
    Detiene unicamente los procesos de una lista blanca conocida (LM Studio,
    Bionic, Ollama, Wallpaper Engine), que son los que compiten por RAM y VRAM
    con los juegos. Nunca toca ningun otro proceso del sistema.

    Con -Restore relanza las apps de la lista blanca que estaban abiertas
    cuando se activo el modo juego.
.EXAMPLE
    .\Game-Mode.ps1          # Activa modo juego (cierra IA + wallpaper)
    .\Game-Mode.ps1 -Restore # Vuelve a abrir lo que estaba abierto
#>
[CmdletBinding()]
param(
    [switch]$Restore
)

$ErrorActionPreference = 'SilentlyContinue'

# Lista blanca: Name = nombre de proceso, Exe = ruta para relanzar en -Restore
$Targets = @(
    @{ Name = 'llama-server'; Exe = $null },
    @{ Name = 'Bionic';       Exe = 'C:\Program Files\Bionic\Bionic.exe' },
    @{ Name = 'ollama';       Exe = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe" },
    @{ Name = 'ollama app';   Exe = "$env:LOCALAPPDATA\Programs\Ollama\ollama app.exe" },
    @{ Name = 'wallpaper64';  Exe = 'C:\Program Files (x86)\Steam\steamapps\common\wallpaper_engine\wallpaper64.exe' },
    @{ Name = 'wallpaper32';  Exe = 'C:\Program Files (x86)\Steam\steamapps\common\wallpaper_engine\wallpaper32.exe' }
)

function Get-FreeRAMGB {
    $os = Get-CimInstance Win32_OperatingSystem
    [math]::Round($os.FreePhysicalMemory / 1MB, 1)
}

if ($Restore) {
    Write-Host "`n=== RESTAURANDO APPS DE IA Y WALLPAPER ===" -ForegroundColor Cyan
    foreach ($t in $Targets) {
        if (-not $t.Exe) { continue }
        if (-not (Test-Path $t.Exe)) { continue }
        $running = Get-Process -Name $t.Name -ErrorAction SilentlyContinue
        if (-not $running) {
            Start-Process -FilePath $t.Exe
            Write-Host ("  [>] Relanzado: {0}" -f $t.Name) -ForegroundColor Green
        }
        else {
            Write-Host ("  [=] Ya corriendo: {0}" -f $t.Name)
        }
    }
    Write-Host ("`nRAM libre ahora: {0} GB" -f (Get-FreeRAMGB)) -ForegroundColor Yellow
    return
}

Write-Host "`n=== MODO JUEGO ACTIVADO ===" -ForegroundColor Cyan
$before = Get-FreeRAMGB
$freedMB = 0

foreach ($t in $Targets) {
    $procs = Get-Process -Name $t.Name -ErrorAction SilentlyContinue
    if ($procs) {
        $mb = ($procs | Measure-Object WorkingSet64 -Sum).Sum / 1MB
        $procs | Stop-Process -Force
        $freedMB += $mb
        Write-Host ("  [x] Cerrado: {0} ({1} procesos, {2:N0} MB)" -f $t.Name, $procs.Count, $mb) -ForegroundColor Green
    }
    else {
        Write-Host ("  [-] No estaba: {0}" -f $t.Name)
    }
}

Start-Sleep -Seconds 1
$after = Get-FreeRAMGB
Write-Host ("`nRAM liberada: {0:N0} MB ({1} -> {2} GB libres)" -f $freedMB, $before, $after) -ForegroundColor Yellow
Write-Host "Listo para jugar. Cuando termines, corre: .\Game-Mode.ps1 -Restore" -ForegroundColor Cyan
