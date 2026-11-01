
## 2024-11-01 - Pipeline with Group-Object anti-pattern in PowerShell
**Learning:** In PowerShell scripts, pipelines using `Group-Object` followed by `Measure-Object` are a performance anti-pattern.
**Action:** Replacing them with a `foreach` loop and hashtable accumulation is a proven optimization that significantly reduces process aggregation time.
