<#
.SYNOPSIS
    Mini benchmark: CPU, RAM, disco y estado de GPU.
.DESCRIPTION
    Solo lectura (crea y borra un archivo temporal de 512 MB).
    Sirve como linea de base antes/despues de optimizar.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "`n=== MINI BENCHMARK ===" -ForegroundColor Cyan

# --- CPU: carga matematica en 4 hilos ---
Write-Host "CPU: corriendo carga matematica en 4 hilos..." -ForegroundColor Yellow
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$jobs = 1..4 | ForEach-Object {
    Start-Job -ScriptBlock {
        $x = 0.0
        for ($i = 0; $i -lt 3000000; $i++) { $x += [math]::Sqrt($i) * [math]::Sin($i) }
        $x
    }
}
$jobs | Wait-Job | Out-Null
$jobs | Remove-Job
$sw.Stop()
$score = [math]::Round(12000 / $sw.Elapsed.TotalSeconds, 1)
Write-Host ("  CPU: {0} pts ({1:N2}s)" -f $score, $sw.Elapsed.TotalSeconds)

# --- RAM ---
$os = Get-CimInstance Win32_OperatingSystem
$totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$usedRAM = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 1)
Write-Host ("  RAM en uso: {0} / {1} GB" -f $usedRAM, $totalRAM)

# --- Disco: escritura y lectura secuencial 512 MB ---
$tmp = "$env:TEMP\pc_toolkit_bench.bin"
$buf = New-Object byte[] (64MB)
(New-Object Random).NextBytes($buf)

$fs = [System.IO.File]::Create($tmp)
$sw.Restart()
for ($i = 0; $i -lt 8; $i++) { $fs.Write($buf, 0, $buf.Length) }
$fs.Flush()
$sw.Stop()
$fs.Close()
$writeSpeed = [math]::Round(512 / $sw.Elapsed.TotalSeconds, 0)
Write-Host ("  Disco escritura: {0} MB/s" -f $writeSpeed)

$sw.Restart()
$fs = [System.IO.File]::OpenRead($tmp)
$readBuf = New-Object byte[] (64MB)
while ($fs.Read($readBuf, 0, $readBuf.Length) -gt 0) { }
$sw.Stop()
$fs.Close()
$readSpeed = [math]::Round(512 / $sw.Elapsed.TotalSeconds, 0)
Write-Host ("  Disco lectura:   {0} MB/s" -f $readSpeed)
Remove-Item $tmp -Force

# --- GPU ---
if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
    Write-Host "  GPU:" -ForegroundColor Yellow
    nvidia-smi --query-gpu=name,pstate,clocks.gr,temperature.gpu --format=csv,noheader | ForEach-Object {
        Write-Host ("    {0}" -f $_)
    }
    Write-Host "    (P0 + reloj alto en reposo = modo rendimiento activo)"
}

# --- Espacio ---
$drive = Get-PSDrive C
Write-Host ("  C: {0:N1} GB libres" -f ($drive.Free / 1GB))

Write-Host "`nBenchmark completo. Guarda estos numeros como linea de base.`n" -ForegroundColor Green
