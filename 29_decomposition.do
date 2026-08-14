********************************************************************************
* ECON 580 Honors Thesis
* Author: Yiqing Zhang
* Date: August 2026
* File: 29_decomposition.do
* Purpose: Channel decomposition. The Manhattan benchmark (file 27) is PURE
*          incapacitation. E1 is incapacitation + spillover + chilling.
*          The DIFFERENCE between the two event-study paths isolates the
*          spillover-plus-chilling component that incapacitation alone cannot
*          explain -- the empirical version of the "no recovery at 1946"
*          argument.
*
*   CONSTRUCTION: pool E1 and the Manhattan benchmark into one dataset, both
*   measured against the SAME controls, and interact the treatment timing with
*   a group indicator (mh = 1 Manhattan, 0 E1). The interaction coefficients
*   are the E1-minus-benchmark differences, WITH standard errors.
*
*   Prediction:
*     - 1943-45 (both incapacitated): difference ~ 0
*     - 1946-48 (benchmark recovers, E1 does not): difference emerges (E1 lower)
*     - 1949+ (benchmark flat, E1 dives): difference = spillover + chilling
*
* Requires: two panels sharing the SAME 24 controls and identical variable
*   names: master_panel_v2.dta (E1) and manhattan_panel.dta (benchmark).
********************************************************************************
capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/29_decomposition.log", replace

*-------------------------------------------------------------------------------
* Step 0: Build the pooled dataset
*   Stack E1-treated + Manhattan-treated + controls (controls appear once).
*   mh = 1 for Manhattan physicists, 0 for E1. Controls carry treated==0 and
*   are shared; keep exactly one copy.
*-------------------------------------------------------------------------------
* --- E1 panel: keep treated + controls, tag group ---
use "Data/master_panel_v2.dta", clear
keep if year >= 1931 & year <= 1960
gen mh = 0                          // E1 side
gen src = "E1"
tempfile e1
save `e1'

* --- Manhattan panel: keep TREATED ONLY (controls come from E1 file) ---
use "Data/manhattan_panel.dta", clear
keep if year >= 1931 & year <= 1960
keep if treated == 1                // drop its control copy to avoid duplicates
gen mh = 1
gen src = "MH"
tempfile mh
save `mh'

* --- Stack ---
use `e1', clear
append using `mh'

* Rebuild a clean panel id across the pooled set
capture drop id
egen id = group(src name)           // src prevents control/treated id collision
* NOTE: controls exist only in the E1 file (src=="E1"), so they are not
* double-counted. E1-treated and MH-treated are distinct people by construction
* (MH was deduped against E1), so no name collides across groups.
xtset id year

*-------------------------------------------------------------------------------
* Step 1: Cumulative decomposition spec
*   treated  = in any treatment group (E1 or Manhattan)
*   mh       = 1 if Manhattan (benchmark), 0 if E1
*   post##T          = treatment effect pooled
*   post##T # mh     = Manhattan-minus-E1 difference at each break
*   The NEGATIVE of the interaction = E1-minus-Manhattan (spillover+chilling).
*-------------------------------------------------------------------------------
gen post42 = (year >= 1942)
gen post46 = (year >= 1946)
gen post49 = (year >= 1949)
gen post54 = (year >= 1954)

foreach p in 42 46 49 54 {
    gen post`p'T    = post`p' * treated          // pooled treatment
    gen post`p'T_mh = post`p' * treated * mh     // Manhattan differential
}

eststo clear
eststo decomp: xtreg pub_count ///
    post42T post46T post49T post54T ///
    post42T_mh post46T_mh post49T_mh post54T_mh ///
    i.year, fe vce(robust)

*-------------------------------------------------------------------------------
* Step 2: Read off the channel components
*   For E1 (mh=0), the effect at each break is post##T (pooled).
*   For Manhattan (mh=1), it is post##T + post##T_mh.
*   The DIFFERENCE (E1 minus Manhattan) at each break is  -post##T_mh.
*   Spillover+chilling that E1 carries beyond pure incapacitation is captured
*   by the interactions being POSITIVE (Manhattan less negative than E1),
*   especially at 1946+ (benchmark recovers, E1 does not) and 1949+.
*-------------------------------------------------------------------------------
* E1-minus-Manhattan at the recovery break (1946): the headline contrast
lincom -(post42T_mh + post46T_mh)
display as result "E1-minus-benchmark, cumulative through 1946-48: " ///
    r(estimate) "  (p=" r(p) ")"

* E1-minus-Manhattan at the political break (1949)
lincom -(post42T_mh + post46T_mh + post49T_mh)
display as result "E1-minus-benchmark, cumulative through 1949-53: " ///
    r(estimate) "  (p=" r(p) ")"

* Full-period spillover+chilling residual (through 1954-60)
lincom -(post42T_mh + post46T_mh + post49T_mh + post54T_mh)
display as result "E1-minus-benchmark, cumulative through 1954-60 " ///
    "(=spillover+chilling): " r(estimate) "  (p=" r(p) ")"

* Wartime cancellation check: 1942-45 difference should be ~0 (both incapacitated)
lincom -post42T_mh
display as result "E1-minus-benchmark, 1942-45 (should be ~0): " ///
    r(estimate) "  (p=" r(p) ")"

*-------------------------------------------------------------------------------
* Step 3: Flexible overlaid event studies (E1 vs benchmark)
*   Estimate each group's path separately for the two-line figure.
*-------------------------------------------------------------------------------
forvalues y = 1931/1960 {
    if `y' != 1941 {
        capture drop tr`y'
        gen tr`y' = treated * (year == `y')
    }
}
eststo path_e1: xtreg pub_count tr19* i.year if mh==0 | treated==0, fe vce(robust)
eststo path_mh: xtreg pub_count tr19* i.year if mh==1 | treated==0, fe vce(robust)

coefplot (path_e1, label("E1 (co-authors)") msymbol(O)) ///
         (path_mh, label("Manhattan benchmark") msymbol(D)), ///
    keep(tr19*) rename(^tr([0-9]+)$ = \1, regex) vertical ///
    yline(0, lcolor(gs10)) ///
    xline(11 15, lpattern(dash) lcolor(red)) ///
    xline(18 23, lpattern(dot) lcolor(gs9)) ///
    xlabel(, angle(90) labsize(vsmall)) ciopts(recast(rcap)) ///
    title("Channel decomposition: E1 vs pure-incapacitation benchmark") ///
    ytitle("Effect on annual Physical Review publications") ///
    note("Gap between the two lines after 1946 = spillover + chilling (what incapacitation cannot explain).")
graph export "Output/fig_decomposition.png", replace width(2200)

*-------------------------------------------------------------------------------
* Step 4: Export
*-------------------------------------------------------------------------------
esttab decomp using "Output/table_decomposition.tex", replace ///
    keep(post42T post46T post49T post54T ///
         post42T_mh post46T_mh post49T_mh post54T_mh) ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Channel decomposition: pooled E1 + Manhattan benchmark") ///
    label booktabs

log close
********************************************************************************
* INTERPRETATION:
*  - post##T are the POOLED treatment effects; post##T_mh are how much the
*    Manhattan benchmark DIFFERS from E1 at each break.
*  - Since the benchmark should recover at 1946 while E1 does not, expect
*    post46T_mh > 0 (Manhattan higher = less suppressed). The -lincom values
*    report E1-minus-benchmark = the spillover+chilling wedge.
*  - The 1942-45 difference (~0) is the validity check: if both groups are
*    equally incapacitated during the war, the war years cancel, and what
*    survives post-1946 is the Oppenheimer-specific channel.
*  - This is the empirical decomposition Taber pointed to: it turns the
*    "no recovery at 1946" argument from verbal into estimated, with SEs.
*  CAVEAT: the benchmark is a NON-RANDOM AHF sample (documented profiles,
*  skewed to prominent physicists). Frame the decomposition as characterizing
*  the incapacitation channel's SHAPE, not a causal population estimate.
********************************************************************************
