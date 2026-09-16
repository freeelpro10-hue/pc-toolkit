<#
.SYNOPSIS
    Suite de tests Pester para PC Toolkit.
.DESCRIPTION
    Valida estructura, sintaxis, seguridad (sin secretos/red) y contrato
    de cada script. No ejecuta acciones destructivas: los scripts con
    impacto se prueban solo a nivel de parametro/sintaxis.
#>
[CmdletBinding()]
param()

Describe "PC Toolkit - estructura del proyecto" {

    BeforeAll {
        $projectRoot = Split-Path $PSCommandPath -Parent | Split-Path -Parent
        $scriptsDir = Join-Path $projectRoot 'scripts'
    }

    It "existe el README" {
        Test-Path (Join-Path $projectRoot 'README.md') | Should -Be $true
    }

    It "existe la licencia" {
        Test-Path (Join-Path $projectRoot 'LICENSE') | Should -Be $true
    }

    It "existe el .gitignore" {
        Test-Path (Join-Path $projectRoot '.gitignore') | Should -Be $true
    }

    It "contiene los scripts esperados" {
        $scripts = Get-ChildItem $scriptsDir -Filter *.ps1
        $scripts.Count | Should -Be 6
        @('Health-Check.ps1','Clean-Caches.ps1','Optimize-Gaming.ps1','Monitor-GPU.ps1','Benchmark.ps1','Gui.ps1') | ForEach-Object {
            Test-Path (Join-Path $scriptsDir $_) | Should -Be $true
        }
    }

    It "la GUI tiene su XAML junto al script" {
        Test-Path (Join-Path $scriptsDir 'Gui.xaml') | Should -Be $true
    }

    It "la GUI pasa su SelfTest (XAML y controles validos)" {
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scriptsDir 'Gui.ps1') -SelfTest
        ($out -join "`n") | Should -Match 'SelfTest OK'
    }
}

Describe "PC Toolkit - calidad y seguridad del codigo" {

    BeforeAll {
        $projectRoot = Split-Path $PSCommandPath -Parent | Split-Path -Parent
        $scripts = Get-ChildItem (Join-Path $projectRoot 'scripts') -Filter *.ps1
        $scriptsDir = Join-Path $projectRoot 'scripts'
    }

    It "todos los scripts tienen sintaxis valida" {
        foreach ($s in $scripts) {
            $tokens = $null; $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($s.FullName, [ref]$tokens, [ref]$errors)
            $errors.Count | Should -Be 0 -Because "el script $($s.Name) no debe tener errores de sintaxis"
        }
    }

    It "todos los scripts documentan su synopsis" {
        foreach ($s in $scripts) {
            $content = Get-Content $s.FullName -Raw
            $content | Should -Match '\.SYNOPSIS' -Because "$($s.Name) debe tener documentacion"
        }
    }

    It "ningun script contiene URLs, IPs ni endpoints de red" {
        foreach ($s in $scripts) {
            $content = Get-Content $s.FullName -Raw
            $content | Should -Not -Match 'https?://' -Because "$($s.Name) no debe conectarse a internet"
            $content | Should -Not -Match '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b' -Because "$($s.Name) no debe apuntar a IPs"
            $content | Should -Not -Match 'Invoke-WebRequest|Invoke-RestMethod|DownloadString|Net\.WebClient' -Because "$($s.Name) no debe descargar nada"
        }
    }

    It "ningun script contiene secretos ni credenciales" {
        foreach ($s in $scripts) {
            $content = Get-Content $s.FullName -Raw
            $content | Should -Not -Match '(?i)password\s*=\s*["'']' -Because "$($s.Name) no debe contener contrasenas"
            $content | Should -Not -Match '(?i)apikey|api_key|secret["'']?\s*=' -Because "$($s.Name) no debe contener API keys"
            $content | Should -Not -Match 'ghp_[A-Za-z0-9]{30,}' -Because "$($s.Name) no debe contener tokens de GitHub"
        }
    }

    It "Clean-Caches soporta -WhatIf (seguridad)" {
        $content = Get-Content (Join-Path $scriptsDir 'Clean-Caches.ps1') -Raw
        $content | Should -Match 'SupportsShouldProcess'
        $content | Should -Match 'ShouldProcess'
    }

    It "Clean-Caches pide confirmacion antes de borrar" {
        $content = Get-Content (Join-Path $scriptsDir 'Clean-Caches.ps1') -Raw
        $content | Should -Match 'Read-Host'
    }
}
