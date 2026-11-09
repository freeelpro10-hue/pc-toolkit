## 2024-11-09 - [Performance optimization of PowerShell grouping]
**Learning:** `Group-Object` followed by `Measure-Object` is a performance anti-pattern in PowerShell. Using a `foreach` loop and hashtables for accumulation provides a significant speedup. Note that PowerShell hashtables (`@{}`) are case-insensitive by default.
**Action:** Replace `Group-Object | Measure-Object` with explicit hashtable accumulation loops.
