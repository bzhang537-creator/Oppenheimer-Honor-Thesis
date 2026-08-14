********************************************************************************
* ECON 580 Honors Thesis
* Author: Yiqing Zhang
* Date: August 2026
* File: 30_benchmark_diagnostic.do
* Purpose: Diagnose why the Manhattan incapacitation benchmark shows a
*          significant post-1949 "decline" (placebo failure) when the group's
*          RAW publication rate recovered at 1946 and stayed flat.
*
*   Hypothesis: the decline is not in the benchmark physicists -- it is the
*   SOLID-STATE CONTROL GROUP surging during the post-war solid-state boom
*   (transistor / condensed-matter expansion, late 1940s-1950s). A control
*   group whose output climbs makes a flat treated group look like it fell.
*
*   Three diagnostics:
*     A. Raw group means by year (treated vs control) -- see the surge directly
*     B. Re-run benchmark dropping Seitz/Shockley/Townes (the boom leaders)
*     C. Descriptive: control mean pre-war vs post-war (quantify the surge)
********************************************************************************
capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/30_benchmark_diagnostic.log", replace

use "Data/manhattan_panel.dta", clear
xtset id year

*-------------------------------------------------------------------------------
* DIAGNOSTIC A: raw (un-differenced) group means by year
*   If treated recovers at 1946 and stays flat while control climbs post-war,
*   the placebo "decline" is a control artifact, not a benchmark problem.
*-------------------------------------------------------------------------------
preserve
    collapse (mean) meanpub = pub_count, by(treated year)
    reshape wide meanpub, i(year) j(treated)
    rename meanpub1 treated_mean
    rename meanpub0 control_mean
    list year treated_mean control_mean, sepby(year) noobs

    twoway (connected treated_mean year, lcolor(blue) mcolor(blue)) ///
           (connected control_mean year, lcolor(red)  mcolor(red)), ///
        xline(1942 1946, lpattern(dash) lcolor(gs8)) ///
        xline(1949, lpattern(dot) lcolor(gs10)) ///
        legend(order(1 "Manhattan benchmark (treated)" 2 "Solid-state controls")) ///
        ytitle("Mean annual Physical Review publications") ///
        xtitle("Year") ///
        title("Raw group means: does the control group surge post-war?") ///
        note("If controls climb after ~1946 while treated stays flat, the placebo failure is a control artifact.")
    graph export "Output/fig_benchmark_raw_means.png", replace width(2200)
restore

*-------------------------------------------------------------------------------
* DIAGNOSTIC C: quantify the control surge (pre-war vs post-war means)
*-------------------------------------------------------------------------------
foreach g in 0 1 {
    quietly summ pub_count if treated==`g' & inrange(year,1931,1941)
    local pre = r(mean)
    quietly summ pub_count if treated==`g' & inrange(year,1949,1960)
    local post = r(mean)
    local lbl = cond(`g'==1,"TREATED (benchmark)","CONTROL (solid-state)")
    di as result "`lbl': pre-war mean=" %5.3f `pre' ///
        "  political-era mean=" %5.3f `post' ///
        "  change=" %6.3f (`post'-`pre')
}
* Interpretation: if controls rise a lot 1931-41 -> 1949-60 while treated is
* flat, the differenced estimate mechanically shows a treated "decline."

*-------------------------------------------------------------------------------
* DIAGNOSTIC B: re-run the benchmark dropping the three solid-state boom
*   leaders (same three as the E3 Inc3 artifact check). If the placebo
*   coefficients shrink toward zero, the control group is the culprit.
*-------------------------------------------------------------------------------
gen post42 = year>=1942
gen post46 = year>=1946
gen post49 = year>=1949
gen post54 = year>=1954
foreach p in 42 46 49 54 {
    gen post`p'T = post`p' * treated
}

* Full controls (baseline for comparison)
eststo clear
eststo mh_allctrl: xtreg pub_count post42T post46T post49T post54T i.year, ///
    fe vce(robust)
di as result "=== FULL CONTROLS ==="
di as result "post46T (recovery): " _b[post46T] "  post49T (placebo): " _b[post49T]

* Drop the solid-state boom leaders
preserve
    drop if inlist(name, "Frederick Seitz", "Charles Townes", "William Shockley")
    eststo mh_noboom: xtreg pub_count post42T post46T post49T post54T i.year, ///
        fe vce(robust)
    di as result "=== DROPPING Seitz/Townes/Shockley ==="
    lincom post46T
    di as result "post46T (recovery): " r(estimate) "  (p=" r(p) ")"
    lincom post49T
    di as result "post49T (placebo, want ~0): " r(estimate) "  (p=" r(p) ")"
    lincom post54T
    di as result "post54T (placebo, want ~0): " r(estimate) "  (p=" r(p) ")"
restore

esttab mh_allctrl mh_noboom using "Output/table_benchmark_diagnostic.tex", replace ///
    keep(post42T post46T post49T post54T) b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("All controls" "Drop boom leaders") ///
    title("Benchmark sensitivity to solid-state boom controls") label booktabs

log close
********************************************************************************
* READING:
*  - Diagnostic A figure is the decisive one: if the RED (control) line climbs
*    steeply after ~1946 while BLUE (treated) recovers to its pre-war level and
*    stays flat, then the benchmark physicists behaved exactly as a clean
*    incapacitation group should, and the differenced "decline" is entirely
*    the control group's post-war surge.
*  - If dropping the 3 boom leaders (Diagnostic B) collapses post49T toward 0,
*    that confirms the solid-state controls are a poor post-war counterfactual.
*  - If BOTH point to the control group, the fix is a control-group problem,
*    not a benchmark problem -- see notes to Taber on counterfactual choice.
********************************************************************************
