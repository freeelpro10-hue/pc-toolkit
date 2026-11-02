## 2025-02-12 - Optimize memory pipeline anti-pattern in PowerShell
**Learning:** In PowerShell scripts, pipelines using `Group-Object` followed by `Measure-Object` are a significant performance anti-pattern due to the overhead of building the pipeline and creating intermediate objects for each step.
**Action:** When summarizing data like process memory or file sizes, use a `foreach` loop to iterate over the collection and accumulate the results in a hashtable instead of using the pipeline. This approach takes roughly half the time to execute.
