## 2024-05-24 - Avoid Group-Object and Measure-Object in pipelines
**Learning:** In PowerShell, pipelines using `Group-Object` followed by `Measure-Object` are a performance anti-pattern. The creation of intermediate `GroupInfo` objects slows down execution significantly.
**Action:** Replace `Group-Object` pipelines with a `foreach` loop and hashtable accumulators for O(n) performance.
