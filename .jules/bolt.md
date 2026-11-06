
## 2024-05-18 - PowerShell Pipeline Overheads (Group-Object/Measure-Object)
**Learning:** In PowerShell scripts (like Health-Check.ps1), pipelines using `Group-Object` followed by `Measure-Object` are a severe performance anti-pattern. They cause unnecessary object creation and drastically increase execution time (e.g. from ~56ms to ~168ms).
**Action:** Replace `Group-Object` pipelines with a `foreach` loop and hashtable accumulation (`$hash[$key] = ...`) whenever aggregating data on large sets of objects.
