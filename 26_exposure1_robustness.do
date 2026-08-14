********************************************************************************
* ECON 580 Honors Thesis
* Author: Yiqing Zhang
* Date: July 2026
* File: 26_exposure1_robustness.do
* Purpose: Two robustness checks for the Exposure 1 unified event study,
*          answering the two open questions from the June handout.
*
*   BLOCK A - Treated-specific linear trend (identification robustness).
*     Answers Q2: is the post-1949 effect real, or a pre-existing
*     differential trend continuing? Adds a treated x linear-time term
*     that soaks up smooth differential drift; if post49T/post54T survive,
*     the effect is not the pre-trend in disguise. Precedent: Autor (2003).
*
*   BLOCK B - Wild cluster bootstrap (inference robustness).
*     Answers Q4: with only 36 clusters, cluster-robust SEs are biased
*     down and p-values too small. boottest (Cameron, Gelbach & Miller
*     2008) gives size-correct p-values and CIs for the same coefficients.
*
* Requires: boottest  (one-time: ssc install boottest, replace)
*           reghdfe, ftools already installed
* Runs AFTER 19_*.do conventions; rebuilds the same cumulative indicators
* so this file is self-contained.
********************************************************************************
capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/26_exposure1_robustness.log", replace
use "Data/master_panel_v2.dta", clear
keep if year >= 1931 & year <= 1960
xtset id year
assert inlist(treated, 0, 1)

********************************************************************************
* STEP 0: Cumulative treatment indicators (identical to 19_*.do)
********************************************************************************
gen post42 = (year >= 1942)
gen post46 = (year >= 1946)
gen post49 = (year >= 1949)
gen post54 = (year >= 1954)

gen post42T = post42 * treated
gen post46T = post46 * treated
gen post49T = post49 * treated
gen post54T = post54 * treated

********************************************************************************
* BLOCK A: TREATED-SPECIFIC LINEAR TREND
*   tr_trend = treated x (year - 1941): a straight line, treated-only,
*   centered at the base year. Absorbs any constant differential drift.
*   What post49T/post54T explain AFTER this is the part of the decline a
*   smooth trend CANNOT produce (the sharp break at 1949).
********************************************************************************
gen tr_trend = treated * (year - 1941)

* (A0) Baseline for comparison - headline cumulative spec, NO trend
eststo clear
eststo A_base: xtreg pub_count post42T post46T post49T post54T ///
    i.year, fe vce(robust)
lincom post42T
estadd scalar lvl_4245 = r(estimate) : A_base
lincom post42T + post46T
estadd scalar lvl_4648 = r(estimate) : A_base
lincom post42T + post46T + post49T
estadd scalar lvl_4953 = r(estimate) : A_base
lincom post42T + post46T + post49T + post54T
estadd scalar lvl_5460 = r(estimate) : A_base

* (A1) Same spec WITH the treated linear trend
eststo A_trend: xtreg pub_count post42T post46T post49T post54T tr_trend ///
    i.year, fe vce(robust)
lincom post42T
estadd scalar lvl_4245 = r(estimate) : A_trend
lincom post42T + post46T
estadd scalar lvl_4648 = r(estimate) : A_trend
lincom post42T + post46T + post49T
estadd scalar lvl_4953 = r(estimate) : A_trend
lincom post42T + post46T + post49T + post54T
estadd scalar lvl_5460 = r(estimate) : A_trend

* Report the trend coefficient itself: is there a significant treated drift?
lincom tr_trend
display as result "Treated linear trend per year: " r(estimate) ///
    "  (p = " r(p) ")"

* Side-by-side table: how much do the level effects move when the trend
* is absorbed? Small movement = effect is not trend-driven.
esttab A_base A_trend using "Output/e1_trend_robustness.tex", replace ///
    keep(post42T post46T post49T post54T tr_trend) ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    scalars("lvl_4245 Level 1942-45" "lvl_4648 Level 1946-48" ///
            "lvl_4953 Level 1949-53" "lvl_5460 Level 1954-60") ///
    mtitles("No trend" "Treated trend") ///
    title("E1 robustness: treated-specific linear trend") label booktabs

********************************************************************************
* BLOCK B: WILD CLUSTER BOOTSTRAP
*   36 clusters -> cluster-robust SEs biased down. boottest rebuilds the
*   null distribution by re-randomizing cluster-level signs. Run on the
*   coefficients we make claims about: post49T (headline) and post54T
*   (marginal in the analytic output). Compare bootstrap p and CI to the
*   analytic ones printed by xtreg above.
*
*   Run boottest on the SAME estimates in memory. Re-estimate the headline
*   (no trend) so the analytic and bootstrap p-values refer to the same
*   model the thesis reports.
********************************************************************************
xtreg pub_count post42T post46T post49T post54T i.year, fe vce(robust)

* Headline shock (should be rock-solid)
boottest post49T, reps(9999) seed(19420816) nograph
* Marginal shock (this is the one that may move above 0.10)
boottest post54T, reps(9999) seed(19420816) nograph

* Optional: bootstrap the two earlier margins too, for completeness
boottest post42T, reps(9999) seed(19420816) nograph
boottest post46T, reps(9999) seed(19420816) nograph

********************************************************************************
* NOTES FOR THE JULY EMAIL
*  - Block A: report lvl_4953 and lvl_5460 in both columns. If they stay
*    large/significant with tr_trend absorbed, state the effect is robust
*    to a treated linear trend. Note the short-pre-window caveat: trend and
*    level shift are hard to separate over 10 pre-years, so modest shrinkage
*    is expected and not damaging; total collapse would be.
*  - Block B: report the boottest p-value and 95% CI for post49T and
*    post54T next to the analytic ones. If post49T survives (it will) the
*    headline is hardened; if post54T's bootstrap p exceeds 0.10, that is
*    consistent with the series having bottomed out by 1954 (no separate
*    1954 increment), which the thesis already argues.
*  - Having settled inference on E1, reuse boottest for E2/E3 (files 22-23).
********************************************************************************
log close
