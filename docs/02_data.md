# Data

[← back to README](../README.md)

## Panel structure

A physicist-year panel of *Physical Review* publication counts, 1931–1960. Research articles only —
errata, comments, letters, and abstracts are excluded.

## The five groups

| Group | Definition | N |
|---|---|---|
| **E1** | Oppenheimer's direct *Physical Review* co-authors | 11 |
| **E2** | Co-authors of those co-authors (one network step further out) | 107 |
| **E3** | IAS Princeton physicists, 1947–1954 | 85 |
| **Control** | Solid-state / acoustics physicists, no network tie | 24 |
| **Benchmark** | Manhattan Project scientists (pure-incapacitation reference) | 74 |

Exposure tiers are defined on **pre-1942** network distance, so treatment status is fixed before any
of the shocks and cannot be an outcome of them.

## Sources

- **Publications:** Physical Review Online Archive (PROLA), `journals.aps.org`. Author searches run
  with `sort=oldest` so pre-1961 papers surface within the first 100 results for prolific authors.
- **Network (E1, E2):** co-authorship extracted from Oppenheimer's *Physical Review* record and
  extended one step out.
- **IAS membership (E3):** *Publications of Members 1930–1954*, Institute for Advanced Study
  ([source PDF](https://www.ias.edu/sites/default/files/library/pdfs/ar/publicationsofme00inst.pdf),
  directory begins p. 205).
- **Manhattan benchmark:** AHF Manhattan Project Veterans Database, "Scientist" filter across Los
  Alamos, Chicago Met Lab, and Oak Ridge. See [benchmark page](06_benchmark.md) for the sample trail.

## Name handling

Physicist names are stored as *first / short middle / last*. Deduplication across groups uses exact
full-string matching (or initial + surname where source formats differ, e.g. "R. Serber" vs. "Robert
Serber"), never surname-only matching, to avoid collapsing distinct physicists.

## Benchmark data appendix

The full physicist-level publication counts behind the Manhattan benchmark — 212 physicists across 7
collection batches, with per-person totals, peak years, and disambiguation notes — are documented in
[`manhattan_project_summary.md`](../manhattan_project_summary.md).

## Data files

| File | Contents |
|---|---|
| `master_panel_v2.dta` | E1 panel |
| `exposure2_panel.dta` | E2 panel |
| `exposure3_panel.dta` | E3 panel |
| `manhattan_panel.dta` | Benchmark panel (built in do-file 27) |

---

Related: [Overview](01_overview.md) · [Methods](04_methods.md) · [Reproduction](08_reproduction.md)
