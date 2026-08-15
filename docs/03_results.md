# Results

[← back to README](../README.md)

## Headline: monotone attenuation at the 1949 trough

The cumulative-level effect at the 1949 trough falls cleanly as network distance from Oppenheimer
increases — the central prediction of the thesis.

| Exposure tier | 1949–53 level effect | *p* | Clusters |
|---|---|---|---|
| **E1** (direct co-authors) | **−1.598** | 0.002 | 36 |
| **E2** (co-authors of co-authors) | **−1.385** | 0.000 | 128 |
| **E3** (IAS physicists) | **−1.079** | 0.003 | 109 |

The ordering |E1| > |E2| > |E3| holds. Each step outward through the network shrinks the effect.

## E1 cumulative-level path

The full E1 event study shows a decline that is **monotone and never recovers**:

| Period | Level effect | *p* |
|---|---|---|
| 1942–45 | −0.649 | 0.027 |
| 1946–48 | −0.746 | 0.081 |
| 1949–53 | −1.598 | 0.002 |
| 1954–60 | −1.544 | 0.000 |

Three things stand out:

1. **No recovery at 1946.** Under pure incapacitation, output should rebound when physicists return
   from Los Alamos. It does not — the key fact separating a political channel from incapacitation.
2. **Deepest break at 1949**, coinciding with the Soviet-test shock.
3. **1954 incremental effect ≈ 0** because the series has already bottomed out by then.

<!-- Replace with your exported figures -->
![E1 unified event study](../Output/e1_event_study.png)

## Identification: E2 and E3 are clean; only E1 needs a defense

| Test | Statistic | *p* | Reading |
|---|---|---|---|
| E2 pre-trend | F(10,127) = 0.93 | 0.505 | holds cleanly |
| E3 pre-trend | F(10,108) = 1.24 | 0.274 | holds cleanly |
| E3 placebo (1942–48, pre-IAS exposure) | F(7,108) = 1.39 | 0.218 | not selection into IAS on prior trajectory |
| E1 pre-trend | F(10,35) = 3.59 | 0.0023 | rejects — defended in [Robustness](05_robustness.md) |

The larger treated groups average out the idiosyncratic late-1930s volatility that produces the E1
pre-trend, so only E1 requires a pre-trend defense. That defense (positive pre-trend biases effects
toward zero; a smooth trend cannot produce the sharp 1949 break) is in the
[robustness section](05_robustness.md).

## The 1954 positive coefficient is a control-group artifact

At every exposure level the *incremental* 1954 coefficient is positive. It disappears once three
control physicists with post-1950 career transitions unrelated to Oppenheimer are dropped
(Seitz → administration, Shockley → semiconductor entrepreneurship, Townes → maser research). For
E3, the 1954 coefficient falls from +0.646 (*p* = 0.054) to +0.235 (*p* = 0.366), while the 1949
effect is essentially unchanged. This confirms the positive is a control artifact, not a real
Incident 3 effect.

---

Related: [Methods](04_methods.md) · [Robustness](05_robustness.md) · [Benchmark](06_benchmark.md)
