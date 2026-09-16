<#
.SYNOPSIS
    Libera espacio en disco borrando caches seguros, con confirmacion.
.DESCRIPTION
    Muestra cuanto se puede liberar y pide confirmacion antes de borrar.
    Soporta -WhatIf para simular sin borrar nada.
    NO toca documentos, juegos ni archivos personales.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    # Usada por la GUI: salta la confirmacion interactiva (la GUI ya confirmo con dialogo)
    [switch]$AutoConfirm
)

$ErrorActionPreference = 'SilentlyContinue'

$targets = @(
    @{ Name = "Cache NVIDIA DXCache";   Path = "$env:LOCALAPPDATA\NVIDIA\DXCache" }
    @{ Name = "Cache NVIDIA GLCache";   Path = "$env:LOCALAPPDATA\NVIDIA\GLCache" }
    @{ Name = "Temp del usuario";       Path = "$env:LOCALAPPDATA\Temp" }
    @{ Name = "Cache de npm";           Path = "$env:LOCALAPPDATA\npm-cache" }
    @{ Name = "Cache de pip";           Path = "$env:LOCALAPPDATA\pip\cache" }
    @{ Name = "Windows Update (Download)"; Path = "C:\Windows\SoftwareDistribution\Download" }
)

function Get-DirSize($path) {
    if (-not (Test-Path $path)) { return 0 }
    (Get-ChildItem $path -Recurse -File -Force -ErrorAction SilentlyContinue |
        Measure-Object Length -Sum).Sum
}

Write-Host "`n=== LIMPIEZA DE CACHES ===" -ForegroundColor Cyan

$totalGB = 0.0
$cleanable = @()
foreach ($t in $targets) {
    if (-not (Test-Path $t.Path)) { continue }
    $size = Get-DirSize $t.Path
    if ($size -gt 0) {
        $gb = $size / 1GB
        $totalGB += $gb
        $cleanable += $t
        $color = if ($gb -gt 1) { 'Yellow' } else { 'Gray' }
        Write-Host ("  {0,8:N2} GB  {1}" -f $gb, $t.Name) -ForegroundColor $color
    }
}

if ($cleanable.Count -eq 0) {
    Write-Host "`nNo hay caches para limpiar. Todo limpio.`n" -ForegroundColor Green
    return
}

Write-Host ("`nTotal liberable: {0:N2} GB" -f $totalGB) -ForegroundColor Cyan

if ($AutoConfirm) {
    $answer = 's'
} else {
    $answer = Read-Host "Borrar estos caches? (s/N)"
}
if ($answer -notmatch '^[sS]') {
    Write-Host "Cancelado. No se borro nada." -ForegroundColor Yellow
    return
}

foreach ($t in $cleanable) {
    if ($PSCmdlet.ShouldProcess($t.Name, "Eliminar contenido")) {
        Remove-Item "$($t.Path)\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host ("  [OK] {0}" -f $t.Name) -ForegroundColor Green
    }
}

$drive = Get-PSDrive C
Write-Host ("`nEspacio libre en C: ahora: {0:N1} GB`n" -f ($drive.Free / 1GB)) -ForegroundColor Cyan
