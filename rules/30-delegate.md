## Delegate Large Generations — /delegate-edit

Prose outputs over ~4000 characters and mechanical multi-file sweeps go through `/delegate-edit`: write a brief under ~2000 chars that states outcomes and points at reference files instead of transcribing them, then review the returned diff. Never delegate load-bearing logic, tests, small edits, short texts, or hardlinked files. The `DELEGATE_ENFORCE=1` hook bounces oversized direct edits; `DELEGATE=0` turns delegation off. Requires the delegate-edit wrapper: `brew install sage-is/apps/work-delegation`.

