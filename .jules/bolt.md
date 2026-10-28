
## 2024-10-28 - PowerShell Pipeline Overhead
**Learning:** In PowerShell scripts, pipelines using `Group-Object` followed by nested `Measure-Object` are a performance anti-pattern. The overhead of object binding is significant compared to using hashtables.
**Action:** Replace `Group-Object` and `Measure-Object` pipelines with `foreach` loops and hashtable accumulation when analyzing large collections (like `Get-Process`).
