# PC Toolkit

[![CI](https://github.com/freeelpro10-hue/pc-toolkit/actions/workflows/ci.yml/badge.svg)](https://github.com/freeelpro10-hue/pc-toolkit/actions/workflows/ci.yml)

Kit de herramientas en PowerShell para diagnosticar, limpiar y optimizar PCs con Windows, pensado para jugadores.

## ¿Por qué este proyecto?

Nació de un caso real: un i5-8400 + GTX 1660 SUPER con 49 GB libres que terminó con 95 GB, RAM optimizada, GPU forzada y ajustes de latencia aplicados. Cada script acá incluido fue ejecutado y verificado en esa máquina.

## Scripts

| Script | Qué hace |
|---|---|
| `scripts/Health-Check.ps1` | Chequeo completo: disco, RAM, GPU, procesos pesados, uptime |
| `scripts/Clean-Caches.ps1` | Libera espacio: cachés NVIDIA, Temp, npm, papelera (pide confirmación) |
| `scripts/Optimize-Gaming.ps1` | Game Mode, Game DVR off, GPU dedicada por juego, plan de energía |
| `scripts/Monitor-GPU.ps1` | Log en CSV del estado de GPU cada 5 s durante una partida |
| `scripts/Benchmark.ps1` | Mini benchmark: CPU, RAM, disco, estado de GPU |
| `scripts/Gui.ps1` | **Interfaz grafica** (WPF): todos los tools con consola integrada |

## Uso rápido

```powershell
# Interfaz gráfica (recomendado)
.\scripts\Gui.ps1

# Chequeo de salud
.\scripts\Health-Check.ps1

# Ver cuánto espacio se puede liberar (sin borrar nada)
.\scripts\Clean-Caches.ps1 -WhatIf

# Optimizar para juegos (aplica ajustes reversibles)
.\scripts\Optimize-Gaming.ps1 -GamePath "C:\ruta\al\juego.exe"

# Monitorear GPU mientras jugás
.\scripts\Monitor-GPU.ps1
```

> Todos los scripts requieren PowerShell 5.1+ (incluido en Windows 10/11).
> Los cambios que hacen son reversibles y están comentados en el código.

## Interfaz gráfica

Además de los scripts de consola, el kit incluye una app de escritorio nativa (WPF, sin dependencias externas):

- Botones para las 5 herramientas, con consola de salida integrada
- Selector de ejecutable para la optimización por-juego
- Confirmación con diálogo antes de borrar cachés
- Operaciones en segundo plano: la ventana nunca se congela
- Las corridas se validan en CI mediante `Gui.ps1 -SelfTest`

## Estructura

```
pc-toolkit/
├── scripts/          # 5 herramientas + interfaz gráfica (Gui.ps1 + Gui.xaml)
├── tests/            # Suite de tests Pester (Pester 5)
└── .github/          # CI con GitHub Actions
```

## Interfaz grafica

Ademas de los scripts de consola, el kit incluye una app de escritorio nativa (WPF, sin dependencias externas):

```powershell
.\scripts\Gui.ps1
```

- Botones para las 5 herramientas, con consola de salida integrada
- Selector de ejecutable para la optimizacion por-juego
- Confirmacion con dialogo antes de borrar caches
- Operaciones en segundo plano: la ventana nunca se congela
- Las corridas se validan en CI mediante `Gui.ps1 -SelfTest`

## Estructura

```
pc-toolkit/
├── scripts/          # 5 herramientas + interfaz grafica (Gui.ps1 + Gui.xaml)
├── tests/            # Suite de tests Pester (Pester 5)
└── .github/          # CI con GitHub Actions
```

## Tests y CI

El proyecto se valida automáticamente en cada push (GitHub Actions, runner Windows) y podés correr los tests localmente con Pester 5:

```powershell
Install-Module Pester -MinimumVersion 5.5.0 -Scope CurrentUser -SkipPublisherCheck
Invoke-Pester -Path tests
```

La suite valida: sintaxis de los scripts, documentación mínima, ausencia de URLs/IPs/descargas (el kit no se conecta a internet), ausencia de secretos, y que las operaciones destructivas pidan confirmación.

## Principios

1. **Nada destructivo sin confirmación** — cada borrado pide permiso o soporta `-WhatIf`
2. **Reversible** — cada ajuste indica cómo deshacerlo en comentarios
3. **Transparente** — imprime qué hace y por qué, sin ocultar nada

## Licencia

[MIT](LICENSE)
