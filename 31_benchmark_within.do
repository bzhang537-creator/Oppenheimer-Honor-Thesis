********************************************************************************
* ECON 580 Honors Thesis
* Author: Yiqing Zhang
* Date: August 2026
* File: 31_benchmark_within.do
* Purpose: Report the Manhattan incapacitation benchmark (E3-Inc1) in
*          ABSOLUTE / within-treated terms, rather than differenced against
*          the solid-state controls.
*
*   WHY: the solid-state control group experiences a documented post-war
*   publication surge (transistor revolution; see draft Section 6.4). Because
*   the benchmark's own rate is flat across 1931-1960 (pre-war 0.638 ->
*   political-era 0.493, change -0.144) while controls quadruple (0.371 ->
*   1.573, change +1.202), the DIFFERENCED benchmark spuriously shows a
*   post-1949 "decline" that is entirely the control surge, not the benchmark.
*   Dropping Seitz/Shockley/Townes barely moves post49T (-1.18 -> -1.03),
*   confirming the problem is the solid-state FIELD, not three individuals.
*
*   Files 28 (differenced benchmark) and 29 (differenced decomposition) are
*   PRESERVED for use if a flat-trajectory control group becomes available.
*   This file (31) and 32 are the versions that hold given current controls.
*
*   APPROACH: characterize the benchmark against its OWN pre-war baseline
*   (treated units only, year FE from the treated group). This isolates the
*   incapacitation shape (dip 1943-45, recovery 1946) without a contaminated
*   counterfactual. Appropriate because E3-Inc1 is a MECHANICAL benchmark
*   ("incapacitation by construction"), not a causal treatment estimate.
********************************************************************************
capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/31_benchmark_within.log", replace

use "Data/manhattan_panel.dta", clear
keep if treated == 1          // TREATED benchmark physicists ONLY (no controls)
xtset id year

*-------------------------------------------------------------------------------
* Step 1: Raw trajectory (the descriptive headline)
*   Mean annual publications by year, treated group only. This is the figure
*   that shows incapacitation-and-recovery directly, no counterfactual needed.
*-------------------------------------------------------------------------------
preserve
    collapse (mean) meanpub = pub_count (sd) sd = pub_count (count) n = pub_count, ///
        by(year)
    gen se = sd / sqrt(n)
    gen lo = meanpub - 1.96*se
    gen hi = meanpub + 1.96*se
    twoway (rarea lo hi year, color(blue%15)) ///
           (connected meanpub year, lcolor(blue) mcolor(blue)), ///
        xline(1942 1946, lpattern(dash) lcolor(red)) ///
        xline(1949 1954, lpattern(dot) lcolor(gs10)) ///
        legend(off) ///
        ytitle("Mean annual Physical Review publications") xtitle("Year") ///
        title("Manhattan benchmark: own publication trajectory") ///
        note("Red dashed: 1942 recruitment / 1946 return. Dotted: 1949/1954. Recovery at 1946, flat thereafter = pure incapacitation.")
    graph export "Output/fig_benchmark_raw_trajectory.png", replace width(2200)
restore

*-------------------------------------------------------------------------------
* Step 2: Within-treated event study (each physicist vs own 1941 baseline)
*   Individual + year FE, treated units only. Manual 1941 base dummies.
*   Reads the incapacitation dip and recovery off the treated group's own
*   deviations from its pre-war level -- no control contrast.
*-------------------------------------------------------------------------------
* With treated-only data, treated==1 always, so year dummies ARE the event path
forvalues y = 1931/1960 {
    if `y' != 1941 {
        capture drop yr`y'
        gen yr`y' = (year == `y')
    }
}
eststo clear
eststo bench_within: xtreg pub_count yr19*, fe vce(robust)

* Incapacitation window: are the wartime years significantly below 1941?
lincom (yr1943 + yr1944 + yr1945)/3
display as result "Avg wartime (1943-45) deviation from 1941 baseline: " ///
    r(estimate) "  (p=" r(p) ")"

* Recovery: is 1946-48 back near baseline (not significantly below)?
lincom (yr1946 + yr1947 + yr1948)/3
display as result "Avg post-war (1946-48) deviation from 1941 baseline: " ///
    r(estimate) "  (p=" r(p) ")"

* Political era: is 1949-60 near baseline (confirming no political effect)?
lincom (yr1949 + yr1950 + yr1951 + yr1952 + yr1953)/5
display as result "Avg political-era (1949-53) deviation from 1941 baseline: " ///
    r(estimate) "  (p=" r(p) ")"

*-------------------------------------------------------------------------------
* Step 3: Within-treated event study figure
*-------------------------------------------------------------------------------
coefplot bench_within, keep(yr19*) rename(^yr([0-9]+)$ = \1, regex) vertical ///
    yline(0, lcolor(gs10)) ///
    xline(11 15, lpattern(dash) lcolor(red)) ///
    xline(18 23, lpattern(dot) lcolor(gs9)) ///
    xlabel(, angle(90) labsize(vsmall)) ciopts(recast(rcap)) ///
    title("Manhattan benchmark: within-group event study (base 1941)") ///
    ytitle("Deviation from own 1941 publication level") ///
    note("Dip at 1943-45, recovery at 1946, flat thereafter: the pure incapacitation shape.")
graph export "Output/fig_benchmark_within_eventstudy.png", replace width(2200)

log close
********************************************************************************
* READING (expected, from raw means 0.638 -> 0.063 -> 0.568 -> 0.611):
*   - Wartime (1943-45): significantly BELOW baseline (incapacitation).
*   - Post-war (1946-48): back NEAR baseline (recovery) -- the key contrast
*     with E1, which does not recover.
*   - Political era (1949-60): near baseline (no political effect, as expected
*     for a group with no Oppenheimer tie).
* This within-treated characterization is immune to the solid-state control
* surge. The differenced version (file 28) is contaminated by that surge and
* should not be used until a flat-trajectory control group is available.
********************************************************************************
