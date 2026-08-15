# Reproduction

[← back to README](../README.md)

## Dependencies

```stata
ssc install reghdfe, replace
ssc install ftools, replace
ssc install ppmlhdfe, replace
ssc install coefplot, replace
ssc install boottest, replace
```

## Repository layout

```
.
├── Do/            # numbered Stata do-files; append-only (never revised)
├── Data/          # .dta panels
├── Output/        # .tex tables and .png figures
├── docs/          # detailed section write-ups (this folder)
├── README.md
└── manhattan_project_summary.md
```

Set the project root at the top of each do-file, then run `Do/` in numeric order. Tables and figures
write to `Output/`.

## Do-file map

| File | Contents |
|---|---|
| 19–21 | E1 unified event study, FE-Poisson, stop-publishing margins |
| 22–23 | E2, E3 unified event studies |
| 26 | E1 treated-trend and wild-cluster bootstrap robustness |
| 27 | Build `manhattan_panel.dta` (baseline filter) |
| 28–29 | Benchmark and decomposition, differenced (preserved for a future control) |
| 30, 33 | Benchmark and control-group diagnostics |
| 31 | Benchmark, absolute within-group specification |
| 32 | Decomposition, shared-control cancellation |

## Conventions

- **Append-only do-files.** Existing numbered files are never edited; new work goes in new numbered
  files, so every stage stays reproducible from prior work.
- **Base year 1941** is explicitly omitted in event-study specifications; year×treated dummies are
  built manually rather than relying on Stata's default omission. See [Methods](04_methods.md#the-1941-base-year-fix).
- **Names** are matched on exact full strings (or initial + surname across differing source formats),
  never surname-only.

---

Related: [Methods](04_methods.md) · [Data](02_data.md)
