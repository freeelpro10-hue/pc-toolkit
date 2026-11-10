## 2024-05-19 - Fast Process Grouping in PowerShell
**Learning:** `Group-Object | Measure-Object` is a performance anti-pattern in PowerShell because of pipeline overhead and reflection.
**Action:** Always use manual accumulation in a Hashtable with a `foreach` loop instead when aggregating process metrics in PowerShell scripts.
