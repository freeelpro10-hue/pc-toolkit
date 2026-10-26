## 2024-05-24 - PowerShell Pipeline Grouping Performance
**Learning:** PowerShell pipelines with `Group-Object` followed by `Measure-Object` for summing properties across many objects (like `Get-Process`) are extremely slow. A benchmark showed that a pipeline approach takes ~1800ms while a simple hashtable accumulation loop takes ~50ms (36x faster).
**Action:** Always prefer manual accumulation in a hashtable over `Group-Object | Measure-Object -Sum` when processing large collections of objects in PowerShell scripts where performance matters.
