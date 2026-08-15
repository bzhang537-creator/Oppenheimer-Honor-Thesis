# Methods

[← back to README](../README.md)

## Why a unified event study

An earlier version of this project estimated **three separate 2×2 DiDs**, one per shock. That design
is invalid here: because the 1942 shock already moved the treated group, the pre-period baseline
that the 1949 and 1954 shocks are measured against is **contaminated**. Parallel trends cannot be
assumed for the later incidents, and windowing the sample (1946–60, 1950–60) does not fix it — the
baseline itself is the problem.

The remedy is a **single data-generating process**: one model spanning 1931–1960 in which all three
shocks live in the same specification, so every coefficient is measured against a baseline that
honestly accounts for everything before it.

## The specification

Let $Y_{it}$ be physicist $i$'s *Physical Review* count in year $t$, with individual fixed effects
$\alpha_i$ and year fixed effects $\gamma_t$.

**Cumulative form** (four treatment indicators, one per break):

$$Y_{it} = \alpha_i + \gamma_t + \delta_{42}(T_i \cdot \text{post42}_t) + \delta_{46}(T_i \cdot \text{post46}_t) + \delta_{49}(T_i \cdot \text{post49}_t) + \delta_{54}(T_i \cdot \text{post54}_t) + \varepsilon_{it}$$

Each $\delta$ is the *incremental* shift at a break; the level effect in any period is the running
sum, recovered by `lincom`. This follows Autor (2003) and Angrist & Pischke, *Mostly Harmless
Econometrics* §5.2.6.

**Flexible event-study form** (year-by-year interactions, base 1941):

$$Y_{it} = \alpha_i + \gamma_t + \sum_{\tau \neq 1941} \beta_\tau (T_i \cdot \mathbf{1}[t = \tau]) + \varepsilon_{it}$$

The pre-1942 $\beta_\tau$ jointly test parallel trends; the post-1942 $\beta_\tau$ trace the dynamic
path.

## Estimation

- **Baseline:** `xtreg, fe vce(robust)` / `reghdfe` with physicist and year fixed effects,
  cluster-robust SEs on physicist.
- **Count robustness:** FE-Poisson (`ppmlhdfe`), motivated by Azoulay et al. (2010) — respects the
  nonnegative integer support and tests whether the pre-trend is a level-scale artifact.

## The 1941 base-year fix

The June event-study plot did not normalize 1941 to zero: Stata's default omission dropped 1960
instead, shifting the pre-period. The fix builds the year×treated dummies **manually**, explicitly
omitting 1941 as the reference, so the base cannot be reassigned by collinearity handling. A
verification loop checks `colnames e(b)` to confirm no interaction term was silently dropped —
important because Poisson separation can drop wartime years with zero treated publications.

The fix did **not** collapse the pre-trend: E1 still rejects (F(10,35) = 3.59, *p* = 0.0023) and
survives under FE-Poisson (χ²(10) = 58.09, *p* < 0.001). It is therefore a real feature, addressed
in [Robustness](05_robustness.md), not a normalization error.

## Key references

Autor (2003); Angrist & Pischke, *Mostly Harmless Econometrics* §5.2.6; Azoulay, Graff Zivin & Wang
(2010, QJE); Cameron, Gelbach & Miller (2008); plus a Danish 2004 tax-reform paper (Qureshi) used as
a worked example of correct base-year normalization.

---

Related: [Results](03_results.md) · [Robustness](05_robustness.md) · [Reproduction](08_reproduction.md)
