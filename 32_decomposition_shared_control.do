********************************************************************************
* ECON 580 Honors Thesis
* Author: Yiqing Zhang
* Date: August 2026
* File: 32_decomposition_shared_control.do
* Purpose: Channel decomposition robust to the solid-state control surge.
*
*   KEY INSIGHT (the reason this works despite bad controls):
*   Both E1 and the Manhattan benchmark are differenced against the SAME 24/25
*   solid-state controls. Write each group's post-shock estimate as
*         group effect = (true suppression) - (control surge)
*   The control surge term is IDENTICAL for both groups. Taking the difference
*         E1 - benchmark = (incap+spillover+chilling) - (incap) = spillover+chilling
*   the control-surge term cancels. So the decomposition is clean EVEN THOUGH
*   each standalone estimate is contaminated (draft Section 6.4 surge).
*
*   CONDITION: both groups must use the IDENTICAL raw control set for the
*   cancellation to hold. This file therefore uses RAW shared controls for
*   BOTH E1 and the benchmark -- NOT the synthetic control used for the E1
*   headline (draft Section 6.5.1). Mixing synthetic-E1 with raw-benchmark
*   would break the cancellation because the two counterfactuals would differ.
*   The synthetic control remains the E1 headline robustness check; this file
*   deliberately uses raw shared controls so the common confounder differences
*   out of the E1-vs-benchmark contrast.
*
*   Files 28/29 preserved for a future flat-trajectory control group.
********************************************************************************
capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/32_decomposition_shared_control.log", replace

*-------------------------------------------------------------------------------
* Step 0: Pool E1-treated + Manhattan-treated + the SHARED raw controls
*-------------------------------------------------------------------------------
* E1 side: treated co-authors + the 24 raw controls
use "Data/master_panel_v2.dta", clear
keep if year >= 1931 & year <= 1960
keep name year pub_count treated
gen mh = 0
gen src = "E1"
tempfile e1
save `e1'

* Manhattan side: treated benchmark physicists ONLY (controls come from E1 file)
use "Data/manhattan_panel.dta", clear
keep if year >= 1931 & year <= 1960
keep if treated == 1
keep name year pub_count treated
gen mh = 1
gen src = "MH"
tempfile mh
save `mh'

use `e1', clear
append using `mh'

* Confirm the control set is identical for both groups (they share the E1 file's
* controls, since MH file contributed only treated). Controls have treated==0.
capture drop id
egen id = group(src name)
xtset id year
bysort id (year): assert _N == 30

*-------------------------------------------------------------------------------
* Step 1: Cumulative decomposition (DDD)
*   post##T     = pooled treatment effect (both groups vs shared controls)
*   post##T_mh  = Manhattan-minus-E1 differential at each break
*   The control surge is common to both groups' comparison and cancels in the
*   interaction terms (post##T_mh), which are the object of interest.
*-------------------------------------------------------------------------------
gen post42 = year>=1942
gen post46 = year>=1946
gen post49 = year>=1949
gen post54 = year>=1954
foreach p in 42 46 49 54 {
    gen post`p'T    = post`p' * treated
    gen post`p'T_mh = post`p' * treated * mh
}

eststo clear
eststo decomp: xtreg pub_count ///
    post42T post46T post49T post54T ///
    post42T_mh post46T_mh post49T_mh post54T_mh ///
    i.year, fe vce(robust)

*-------------------------------------------------------------------------------
* Step 2: Read the channel components
*   E1-minus-benchmark at each break = -(sum of post##T_mh up to that break).
*   Because the shared control surge cancels here, these differences are the
*   clean spillover+chilling estimates.
*-------------------------------------------------------------------------------
* Validity check: wartime (1942-45) should ~cancel -- both incapacitated
lincom -post42T_mh
display as result "E1 - benchmark, 1942-45 (want ~0, both incapacitated): " ///
    r(estimate) "  (p=" r(p) ")"

* Recovery break: E1 does not recover, benchmark does -> difference emerges
lincom -(post42T_mh + post46T_mh)
display as result "E1 - benchmark, cumulative 1946-48 (recovery gap): " ///
    r(estimate) "  (p=" r(p) ")"

* Political break: benchmark flat (no tie), E1 dives -> pure political channel
lincom -(post42T_mh + post46T_mh + post49T_mh)
display as result "E1 - benchmark, cumulative 1949-53 (spillover+chilling): " ///
    r(estimate) "  (p=" r(p) ")"

lincom -(post42T_mh + post46T_mh + post49T_mh + post54T_mh)
display as result "E1 - benchmark, cumulative 1954-60 (full spillover+chilling): " ///
    r(estimate) "  (p=" r(p) ")"

*-------------------------------------------------------------------------------
* Step 3: Overlaid event-study paths (E1 vs benchmark), same shared controls
*   The two lines share the control surge, so the VERTICAL GAP between them
*   after 1946 is the spillover+chilling wedge, purged of the control artifact.
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
    title("Channel decomposition (shared controls): E1 vs incapacitation benchmark") ///
    ytitle("Effect on annual Physical Review publications") ///
    note("Both differenced against the same solid-state controls, so the control surge is common to both lines. The gap after 1946 is spillover + chilling.")
graph export "Output/fig_decomposition_shared.png", replace width(2200)

esttab decomp using "Output/table_decomposition_shared.tex", replace ///
    keep(post42T post46T post49T post54T ///
         post42T_mh post46T_mh post49T_mh post54T_mh) ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Channel decomposition with shared raw controls") label booktabs

log close
********************************************************************************
* WRITE-UP NOTE:
*  - Standalone benchmark estimates (differenced) are contaminated by the
*    solid-state surge (Section 6.4). The DECOMPOSITION is not, because both
*    E1 and benchmark share those controls and the surge cancels in the
*    E1-minus-benchmark difference (a DDD).
*  - This file uses RAW shared controls for both groups by design. The
*    synthetic control (Section 6.5.1) is the E1 headline robustness check;
*    it is intentionally NOT used here, because a shared common counterfactual
*    is what makes the cancellation work.
*  - Expected pattern: 1942-45 difference ~0 (both incapacitated); a gap opens
*    at 1946 (benchmark recovers, E1 does not) and widens post-1949; that gap
*    is the spillover+chilling estimate.
********************************************************************************
