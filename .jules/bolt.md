
## 2024-05-24 - Optimizing Process Memory Calculation in PowerShell
**Learning:** In PowerShell scripts, pipelines using `Group-Object` followed by `Measure-Object` are a severe performance anti-pattern. This codebase previously used this pattern in `scripts/Health-Check.ps1` to calculate the top processes by RAM.
**Action:** Replace `Group-Object | ForEach-Object { Measure-Object }` with a `foreach` loop and hashtable accumulation. This significantly reduces execution time (by more than 60% in our benchmark) and improves responsiveness.
