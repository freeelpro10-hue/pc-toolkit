
## 2024-05-24 - Group-Object | Measure-Object is a performance anti-pattern
**Learning:** In PowerShell scripts, pipelines using `Group-Object` followed by `Measure-Object` inside loops or over large sets of data cause significant performance overhead.
**Action:** Replace `Group-Object | Measure-Object` with a `foreach` loop and hashtable accumulation for summing and counting values.
