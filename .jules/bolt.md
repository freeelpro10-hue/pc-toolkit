## 2024-05-15 - PowerShell Pipeline Performance Anti-Pattern
**Learning:** In PowerShell, using `Group-Object` followed by processing in a pipeline (e.g., `Get-Process | Group-Object Name | ForEach-Object { ... Measure-Object ... }`) is extremely slow due to the overhead of creating and passing objects through the pipeline and running `Measure-Object` for each group.
**Action:** Replace `Group-Object | ForEach-Object { Measure-Object }` constructs with a simple `foreach` loop and hashtables for manual aggregation. This significantly improves performance while maintaining readability.
