# Political Shocks and Scientific Network Productivity — `v3-unified-event-study` (active)

**Evidence from the Oppenheimer Affair**

Yiqing Zhang · Economics Honors Thesis, University of Wisconsin–Madison <br>
Advisor: Prof. Christopher Taber (James J. Heckman Professor of Economics) <br>
Status: active development branch · full thesis due May 2027 · *last updated August 2026*

---

This is the **live working branch** — the current data, code, and results. It is more detailed and
more provisional than the [`main`](../../tree/main) overview, which is the polished summary. Readers
who want the run-ready code and the full state of the analysis are in the right place; readers who
want a clean two-minute overview should start on `main`.

## The question

Between 1942 and 1954, J. Robert Oppenheimer absorbed three political shocks: recruitment to lead the
Manhattan Project (1942), the Soviet atomic test that recast him as a security concern (1949), and the
revocation of his security clearance (1954). This thesis asks whether those shocks propagated through
Oppenheimer's *Physical Review* co-authorship network and suppressed the publication output of the
physicists connected to him. Treatment is defined by pre-1942 network distance across three concentric
tiers — **E1** (11 direct co-authors), **E2** (107 co-authors of co-authors), **E3** (85 IAS Princeton
physicists) — against a control group of 24 solid-state / acoustics physicists.

## Design

A single **unified event study** over 1931–1960 (one data-generating process, cumulative treatment
indicators at 1942 / 1946 / 1949 / 1954, base year 1941), estimated by fixed-effects OLS and FE-Poisson
(`ppmlhdfe`), with wild-cluster bootstrap inference for the small-cluster E1 tier. This design replaces
the separate 2×2 DiDs of the earlier `v2` branch, which were invalid because the 1942 shock already
moves the treated group and contaminates the baseline for the later incidents.

## Current headline results

| Exposure tier | 1949–53 level effect | *p* | Clusters |
|---|---|---|---|
| **E1** — direct co-authors | **−1.598** | 0.002 | 36 |
| **E2** — co-authors of co-authors | **−1.385** | 0.000 | 128 |
| **E3** — IAS physicists | **−1.079** | 0.003 | 109 |

The 1949 suppression **attenuates monotonically with network distance** from Oppenheimer — the thesis's
central claim. For the innermost tier there is **no recovery at 1946** after the wartime dip, which
distinguishes a genuine political channel from simple wartime incapacitation. A Manhattan Project
benchmark of 74 network-unconnected physicists shows the pure-incapacitation shape (deep wartime dip,
full recovery at 1946, flat thereafter), against which the political channel is identified.

## What's on this branch

- `Do/` — numbered Stata do-files (append-only; existing files are never revised)
- `Data/` — physicist-year panels (`master_panel_v2.dta`, `exposure2_panel.dta`, `exposure3_panel.dta`, `manhattan_panel.dta`)
- `Output/` — exported `.tex` tables and `.png` event-study figures
- `docs/` — detailed section write-ups (question, data, results, methods, robustness, benchmark, open questions, reproduction)

## Open question

The 24 solid-state / acoustics controls surge post-war (the transistor revolution), which contaminates
differenced comparisons. The benchmark is currently reported in absolute within-group terms; whether to
assemble a new pool of flat, productive, network-clean controls is an open decision. See
[`docs/07_open_questions.md`](docs/07_open_questions.md).

---

Archived history: [`v1-crossref`](../../tree/v1-crossref) (early Crossref data) · [`v2-prola`](../../tree/v2-prola) (PROLA data, separate DiDs). Project overview on [`main`](../../tree/main).
