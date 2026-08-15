# The Manhattan Incapacitation Benchmark

[← back to README](../README.md)

## Purpose

The core interpretive question is whether the suppression is **temporary incapacitation** or a
**persistent political/chilling channel**. To pin this down, I build a benchmark of Manhattan Project
physicists who were classified out of open publishing during 1943–45 but had **no Oppenheimer
network tie** — so they experience the incapacitation channel with no spillover or chilling. Their
publication path is what pure incapacitation looks like.

## Sample construction

| Stage | Physicists |
|---|---|
| AHF "Scientist" filter, 3 sites (Los Alamos, Chicago, Oak Ridge) | 237 |
| − overlap with IAS (E3) | −4 |
| − overlap with E1 | −3 |
| − overlap with E2 | −18 |
| − no pre-1942 *Physical Review* baseline | −138 |
| **Final benchmark** | **74** |

Names are deduped against E1, E2, and IAS so the benchmark isolates incapacitation with no
Oppenheimer connection. The pre-1942 baseline filter keeps only physicists with an established
pre-war *Physical Review* record — the correct sample for measuring a productivity *decline* (it
correctly drops health physicists, non-PR fields, and post-war entrants).

Full physicist-level data: [`manhattan_project_summary.md`](../manhattan_project_summary.md).

## The benchmark behaves as pure incapacitation

Reported in **absolute within-group terms** (each physicist against their own 1941 baseline), the
benchmark shows the textbook incapacitation signature:

| Window | Deviation from 1941 baseline | *p* | Reading |
|---|---|---|---|
| 1943–45 (wartime) | −0.572 | <0.001 | deep incapacitation |
| 1946–48 (post-war) | −0.068 | 0.537 | recovered to baseline |
| 1949–53 (political) | −0.024 | 0.837 | no political effect |

The wartime collapse recovers fully by 1946 and stays flat through the political era — exactly what a
group with no Oppenheimer tie should show. **This is the key contrast with E1, which does not recover
at 1946.**

## Channel decomposition — an honest, nuanced result

Subtracting the benchmark path from the E1 path (both differenced against the same controls, so the
control trajectory cancels) gives:

| Window | E1 − benchmark | *p* | |
|---|---|---|---|
| 1942–45 (both incapacitated) | −0.417 | 0.113 | validity check |
| 1946–48 (recovery gap) | −0.181 | 0.544 | |
| 1949–53 (cumulative) | +0.146 | 0.652 | |
| 1949 incremental (post49T × mh) | −0.326 | 0.044 | political channel |

The clean "recovery gap = spillover + chilling" story is **not** what the data show. Through 1948, E1
and the benchmark are statistically indistinguishable, so early E1 suppression is largely
**incapacitation**. The one place E1 diverges from pure incapacitation is the *incremental* 1949
interaction (−0.326, *p* = 0.044), consistent with the political channel operating through the
Oppenheimer tie.

**Honest reading:** incapacitation dominates the wartime and early post-war suppression; the
Oppenheimer-specific political channel appears distinctly at 1949. (Treated as suggestive pending
bootstrap.)

---

Related: [Results](03_results.md) · [Open questions](07_open_questions.md) · [Data](02_data.md)
