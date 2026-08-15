# Oppenheimer Honors Thesis — `v2-prola` (archived)

**Archived history. No longer maintained.** This version replaced the Crossref data of `v1` with
publication counts collected directly from the **APS Physical Review Online Archive (PROLA)**, giving
complete and consistent *Physical Review* coverage for 1931–1960. It is the data foundation the current
work still builds on.

Methodologically, this branch estimated the three political shocks as **separate difference-in-differences
designs** (a set of 2×2 DiDs across the exposure tiers and incidents). That approach was later found to be
invalid here: the 1942 shock already moves the treated group, contaminating the baseline against which the
1949 and 1954 shocks are measured, so parallel trends cannot hold for the later incidents in isolation.
The fix — a single unified event study over the full 1931–1960 window — is developed on the current
branch. This branch is retained as a record of the separate-DiD stage.

**Current work lives on [`v3-unified-event-study`](https://github.com/bzhang537-creator/Oppenheimer-Honor-Thesis/tree/v3-unified-event-study); see the [`main`](https://github.com/bzhang537-creator/Oppenheimer-Honor-Thesis) branch for the project overview.**
