# Open Questions & Next Steps

[← back to README](../README.md)

## The control-group problem

The benchmark decomposition surfaced a problem with the control pool. Screening all 24 controls on
their publication trajectory (post-war mean minus pre-war mean) shows the pool is broadly
contaminated:

- **22 of 24** controls are non-flat, spanning a contamination gradient from −0.70 (post-war
  *collapse*) to +4.14 (post-war *boom* — the transistor-era solid-state surge).
- The only two flat controls (Turnbull, +0.08; Lyons, +0.17) are near-zero *Physical Review*
  publishers (pre-war means 0.09 and 0.00), so they cannot serve as productivity counterfactuals.
- **No flat, productive control exists anywhere in the current pool.**

This is why:

1. the standalone benchmark is reported in **absolute within-group terms** (immune to the control
   surge), and
2. the decomposition relies on the surge **cancelling** in the E1-minus-benchmark difference rather
   than on any single group's differenced estimate.

Synthetic control does not fix it: the donor pool is all solid-state boomers, the pre-period already
matches, and the problem is in the post-period.

## The question for the advisor

Given that (i) the standalone incapacitation benchmark is clean in absolute terms and (ii) the
current control pool cannot support a flat, productive counterfactual — is it worth collecting a new
control group of ~15–20 flat, productive, *Physical Review*-active, non-war-incapacitated,
network-clean physicists (e.g. from spectroscopy / optics / acoustics) to sharpen the *differenced*
decomposition? Or report the absolute benchmark and the honest nuanced decomposition, treating a new
control collection as future work?

## Other open items

- **Decomposition framing.** Present the decomposition as "incapacitation dominates early; the
  political channel appears at 1949" rather than as a single spillover+chilling wedge — the data
  support the former.
- **E3 trend sensitivity.** Report both headline and trend-adjusted E3 estimates, leading with the
  clean pre-period test.
- **Broader journals.** Extend the outcome beyond *Physical Review* by collecting additional journals
  for **all** groups and merging on a consistent name crosswalk (with explicit zero-handling). This
  must be symmetric across all groups or cross-group comparability breaks — treated as a later
  robustness pass, not a near-term task.
- **PhD-student channel** as a potential fourth exposure tier (E4).

---

Related: [Benchmark](06_benchmark.md) · [Robustness](05_robustness.md) · [Overview](01_overview.md)
