## 2024-05-14 - Replace Group-Object and Measure-Object pipelines with Hashtables
**Learning:** PowerShell pipelines utilizing `Group-Object` followed by `Measure-Object` represent a significant performance anti-pattern.
**Action:** Replace `Group-Object | ForEach-Object { Measure-Object }` pipelines with manual `foreach` iteration and hashtable state accumulation, then pipe the result using `$()`.
