## 2024-05-24 - PowerShell Pipeline Performance with Group-Object
**Learning:** Using Get-Process | Group-Object | Measure-Object in PowerShell pipelines has O(n²) complexity behavior under the hood and is extremely slow for memory aggregation. Iterating processes and accumulating values into a hash table is O(n) and over 3x faster.
**Action:** Use hash tables for aggregation over large sets of objects in PowerShell instead of Group-Object when performance matters.
