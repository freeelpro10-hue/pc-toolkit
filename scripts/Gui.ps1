<#
.SYNOPSIS
    Interfaz grafica de PC Toolkit (WPF nativo de Windows, sin dependencias).
.DESCRIPTION
    Ventana con acceso a las herramientas del kit. Cada operacion corre
    en segundo plano para no congelar la UI; la salida se muestra en una
    consola integrada. Requiere scripts/Gui.xaml junto a este archivo.

    Nota de implementacion: los handlers de DispatcherTimer/eventos WPF se
    ejecutan fuera del scope de la funcion que los creo, por lo que todo
    estado compartido vive en $script: (ui, current).

    Modo especial para CI (no abre ventana, valida y sale):
    .\Gui.ps1 -SelfTest
#>
[CmdletBinding()]
param(
    [switch]$SelfTest
)

$ErrorActionPreference = 'Stop'
$scriptRoot = $PSScriptRoot
$xamlPath = Join-Path $scriptRoot 'Gui.xaml'

$requiredScripts = @(
    'Health-Check.ps1', 'Clean-Caches.ps1', 'Optimize-Gaming.ps1',
    'Monitor-GPU.ps1', 'Benchmark.ps1'
)
$requiredControls = @(
    'BtnHealth', 'BtnClean', 'BtnOptimize', 'BtnMonitor', 'BtnBench',
    'BtnBrowse', 'TxtGamePath', 'TxtStatus', 'TxtOutput'
)

# ============================================================
# Modo SelfTest: valida XAML y scripts, sin abrir ventana
# ============================================================
if ($SelfTest) {
    $failures = @()

    foreach ($f in $requiredScripts) {
        if (-not (Test-Path (Join-Path $scriptRoot $f))) { $failures += "Falta script: $f" }
    }
    if (-not (Test-Path $xamlPath)) { $failures += "Falta Gui.xaml" }

    if ($failures.Count -eq 0) {
        try {
            Add-Type -AssemblyName PresentationFramework
            $node = [Windows.Markup.XamlReader]::Parse((Get-Content $xamlPath -Raw))
            foreach ($name in $requiredControls) {
                if (-not $node.FindName($name)) { $failures += "XAML sin control: $name" }
            }
        } catch {
            $failures += "XAML no parsea: $($_.Exception.Message)"
        }
    }

    if ($failures.Count -gt 0) {
        Write-Host "SelfTest FALLO:" -ForegroundColor Red
        $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        exit 1
    }
    Write-Host "SelfTest OK: XAML valido, $($requiredControls.Count) controles presentes, $($requiredScripts.Count) scripts encontrados." -ForegroundColor Green
    exit 0
}

# ============================================================
# Modo normal: lanzar la aplicacion
# ============================================================
Add-Type -AssemblyName PresentationFramework
$window = [Windows.Markup.XamlReader]::Parse((Get-Content $xamlPath -Raw))

# Log de excepciones no manejadas de la UI (evita crash silencioso)
[System.Windows.Threading.Dispatcher]::CurrentDispatcher.add_UnhandledException({
    param($s, $e)
    try {
        Set-Content -Path (Join-Path $env:TEMP 'pc_toolkit_gui_error.log') -Value $e.Exception.ToString() -Encoding UTF8
    } catch { }
    $e.Handled = $true
})

$script:ui = @{}
foreach ($name in $requiredControls) { $script:ui[$name] = $window.FindName($name) }

# Estado de la corrida en curso (ps, handle, timer, label)
$script:current = $null
$script:running = $false

function Set-UiBusy([bool]$busy, [string]$status) {
    $script:running = $busy
    foreach ($btn in @($script:ui.BtnHealth, $script:ui.BtnClean, $script:ui.BtnOptimize, $script:ui.BtnMonitor, $script:ui.BtnBench)) {
        $btn.IsEnabled = -not $busy
    }
    $script:ui.TxtStatus.Text = $status
    $script:ui.TxtStatus.Foreground = if ($busy) { '#FAB387' } else { '#A6E3A1' }
}

function Invoke-Tool {
    param(
        [string]$ButtonLabel,
        [string]$ScriptFile,
        [string[]]$ExtraArgs = @()
    )
    if ($script:running) { return }

    Set-UiBusy $true "Ejecutando $ButtonLabel ..."
    $script:ui.TxtOutput.AppendText("`n========== $ButtonLabel ==========`n")
    $script:ui.TxtOutput.ScrollToEnd()

    # Escape seguro de comillas simples para literales '...'
    $esc = { param($s) $s -replace "'", "''" }

    $cmd = "& '$(& $esc (Join-Path $scriptRoot $ScriptFile))'"
    foreach ($a in $ExtraArgs) { $cmd += " '$(& $esc $a)'" }
    # Out-String -Stream convierte los objetos de formato (Format-Table) en
    # texto legible; sin esto la consola mostraria 'FormatStartData...'
    $cmd += " *>&1 | Out-String -Stream | ForEach-Object { `$_.TrimEnd() }"

    $ps = [PowerShell]::Create()
    $null = $ps.AddScript($cmd)

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(250)

    # Estado accesible desde el Tick (que corre fuera de este scope)
    $script:current = @{
        ps     = $ps
        handle = $ps.BeginInvoke()
        timer  = $timer
        label  = $ButtonLabel
    }

    $timer.Add_Tick({
        $cur = $script:current
        if (-not $cur -or -not $cur.handle.IsCompleted) { return }
        $cur.timer.Stop()
        try {
            $out = $cur.ps.EndInvoke($cur.handle)
            foreach ($line in $out) { $script:ui.TxtOutput.AppendText("$line`n") }
            if ($cur.ps.HadErrors) {
                Set-UiBusy $false "$($cur.label) termino con advertencias (ver consola)"
            } else {
                Set-UiBusy $false "$($cur.label) listo."
            }
        } catch {
            $script:ui.TxtStatus.Text = "Error: $($_.Exception.Message)"
            $script:ui.TxtStatus.Foreground = '#F38BA8'
            Set-UiBusy $false "Error."
        } finally {
            $cur.ps.Dispose()
            $script:current = $null
        }
        $script:ui.TxtOutput.ScrollToEnd()
    })
    $timer.Start()
}

# --- Eventos ---

$script:ui.BtnHealth.Add_Click({ Invoke-Tool -ButtonLabel 'Chequeo de salud' -ScriptFile 'Health-Check.ps1' })
$script:ui.BtnBench.Add_Click({ Invoke-Tool -ButtonLabel 'Benchmark' -ScriptFile 'Benchmark.ps1' })

$script:ui.BtnClean.Add_Click({
    if ($script:running) { return }
    $r = [System.Windows.MessageBox]::Show(
        "Se borraran solo caches regenerables (NVIDIA, Temp, npm, pip, Windows Update).`nNo toca documentos ni juegos.`n`nContinuar?",
        'Confirmar limpieza', 'YesNo', 'Question')
    if ($r -ne 'Yes') { return }
    Invoke-Tool -ButtonLabel 'Limpieza de caches' -ScriptFile 'Clean-Caches.ps1' -ExtraArgs @('-AutoConfirm')
})

$script:ui.BtnOptimize.Add_Click({
    $gamePath = $script:ui.TxtGamePath.Text.Trim()
    $args = @()
    if ($gamePath) {
        if (-not (Test-Path $gamePath)) {
            $script:ui.TxtStatus.Text = "Ruta de juego invalida: $gamePath"
            $script:ui.TxtStatus.Foreground = '#F38BA8'
            return
        }
        $args += @('-GamePath', $gamePath)
    }
    Invoke-Tool -ButtonLabel 'Optimizacion gaming' -ScriptFile 'Optimize-Gaming.ps1' -ExtraArgs $args
})

$script:ui.BtnMonitor.Add_Click({
    if ($script:running) { return }
    $script:ui.TxtOutput.AppendText("`n========== Monitoreo de GPU (muestra puntual) ==========`n")
    $raw = nvidia-smi --query-gpu=utilization.gpu,memory.used,power.draw,clocks.gr,temperature.gpu --format=csv,noheader,nounits 2>$null
    if ($raw) {
        $v = $raw -split ',\s*'
        $script:ui.TxtOutput.AppendText("  GPU $($v[0])% | VRAM $($v[1]) MB | $($v[2]) W | $($v[3]) MHz | $($v[4]) C`n")
        $script:ui.TxtStatus.Text = "Muestra tomada. Para log continuo en CSV: scripts\Monitor-GPU.ps1"
    } else {
        $script:ui.TxtOutput.AppendText("  nvidia-smi no disponible en este equipo.`n")
    }
    $script:ui.TxtOutput.ScrollToEnd()
})

$script:ui.BtnBrowse.Add_Click({
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = "Ejecutables (*.exe)|*.exe"
    $dlg.Title = "Elegir ejecutable del juego"
    if ($dlg.ShowDialog()) { $script:ui.TxtGamePath.Text = $dlg.FileName }
})

[void]$window.ShowDialog()
