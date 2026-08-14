********************************************************************************
* 23_exposure3_event_study.do
* Political Shocks and Scientific Network Productivity:
* Evidence from the Oppenheimer Affair
*
* Purpose : Unified event study for Exposure 3 (85 IAS Princeton physicists,
*           1947-54). Mirrors 19/22 with one E3-specific design point:
*           IAS exposure begins in 1947, so Incidents 1 (1942) and the 1946
*           return CANNOT causally affect E3 through the IAS channel.
*             - Primary cumulative spec: post49T, post54T only.
*             - Placebo spec: adds post42T, post46T; these should be ~0.
*             - Flexible event study keeps base year 1941 for comparability
*               with E1/E2 figures; treated interactions 1942-1948 are read
*               as placebo/pre-exposure coefficients.
*           (When the Manhattan Project roster arrives, E3-Inc1 exposure will
*           be redefined by site affiliation -- see June handout Section 5.1.)
* Author  : Yiqing Zhang
* Date    : July 2026
********************************************************************************

clear all
set more off
capture log close

global root   "/Users/serendipity/Study abroad/Oppenheimer"
global data   "$root/Data"
global output "$root/Output"
global log    "$root/Log"

log using "$log/23_exposure3_event_study.log", replace

*-------------------------------------------------------------------------------
* Step 1: Load E3 panel and set up
*-------------------------------------------------------------------------------
use "$data/exposure3_panel.dta", clear

capture confirm numeric variable id
if _rc {
    egen id = group(name)
}
xtset id year

assert inrange(year, 1931, 1960)
tab treated
bysort id: assert treated == treated[1]

*-------------------------------------------------------------------------------
* Step 2: Cumulative-shift specifications
*-------------------------------------------------------------------------------
gen post42 = (year >= 1942)
gen post46 = (year >= 1946)
gen post49 = (year >= 1949)
gen post54 = (year >= 1954)

gen post42T = post42 * treated
gen post46T = post46 * treated
gen post49T = post49 * treated
gen post54T = post54 * treated

eststo clear

* (a) Primary: only shocks that can reach E3 through the IAS channel
eststo e3_cum: xtreg pub_count post49T post54T i.year, fe vce(robust)

* Wild cluster bootstrap on the two shocks that reach E3
xtreg pub_count post49T post54T i.year, fe vce(robust)
boottest post49T, reps(9999) seed(19420816) nograph
boottest post54T, reps(9999) seed(19420816) nograph

lincom post49T
estadd scalar lvl_4953 = r(estimate) : e3_cum
estadd scalar se_4953  = r(se)       : e3_cum

lincom post49T + post54T
estadd scalar lvl_5460 = r(estimate) : e3_cum
estadd scalar se_5460  = r(se)       : e3_cum

* (b) Placebo: include pre-exposure shifts; post42T/post46T should be ~0.
*     A significant post42T here signals selection into IAS on prior
*     trajectory, not a causal effect.
eststo e3_placebo: xtreg pub_count post42T post46T post49T post54T i.year, ///
    fe vce(robust)

*-------------------------------------------------------------------------------
* Step 3: Flexible event study, base year 1941 (manual dummies)
*-------------------------------------------------------------------------------
forvalues y = 1931/1960 {
    if `y' != 1941 {
        gen tr`y' = treated * (year == `y')
    }
}

eststo e3_flex: xtreg pub_count tr19* i.year, fe vce(robust)

local kept : colnames e(b)
foreach v of varlist tr1931-tr1940 tr1942-tr1960 {
    if !`: list v in kept' {
        di as error "WARNING: `v' dropped from the model."
    }
}

* Joint pre-trend test (i): true pre-period, 1931-1940
testparm tr1931 tr1932 tr1933 tr1934 tr1935 tr1936 tr1937 tr1938 tr1939 tr1940
estadd scalar pretrend_F = r(F) : e3_flex
estadd scalar pretrend_p = r(p) : e3_flex
display as result "E3 joint pre-trend (1931-40): F = " r(F) ", p = " r(p)

* Joint placebo test (ii): pre-IAS-exposure years 1942-1948
testparm tr1942 tr1943 tr1944 tr1945 tr1946 tr1947 tr1948
estadd scalar placebo_F = r(F) : e3_flex
estadd scalar placebo_p = r(p) : e3_flex
display as result "E3 placebo 1942-48: F = " r(F) ", p = " r(p)

*-------------------------------------------------------------------------------
* Step 4: Treated-specific linear trend robustness
*-------------------------------------------------------------------------------
gen tr_trend = treated * (year - 1941)
eststo e3_trend: xtreg pub_count post49T post54T tr_trend i.year, ///
    fe vce(robust)

*-------------------------------------------------------------------------------
* Step 5: Export tables
*-------------------------------------------------------------------------------
esttab e3_cum e3_placebo e3_trend using "$output/table_e3_unified.tex", replace ///
    keep(post42T post46T post49T post54T tr_trend) ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    scalars("lvl_4953 Level 1949-53" "lvl_5460 Level 1954-60") ///
    mtitles("Primary" "Placebo" "Treated trend") ///
    title("E3 unified event study: incremental and level effects") ///
    label booktabs

esttab e3_flex using "$output/table_e3_eventstudy.tex", replace ///
    keep(tr19*) b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    scalars("pretrend_F Pre-trend F (1931-40)" "pretrend_p Pre-trend p" ///
            "placebo_F Placebo F (1942-48)"   "placebo_p Placebo p") ///
    title("E3 flexible event study, base 1941") ///
    label booktabs

*-------------------------------------------------------------------------------
* Step 6: Event study figure
*-------------------------------------------------------------------------------
estimates restore e3_flex
coefplot, keep(tr19*) ///
    rename(^tr([0-9]+)$ = \1, regex) ///
    vertical omitted baselevels ///
    yline(0, lcolor(gs10)) ///
    xline(11.5, lpattern(dash) lcolor(gs8))   /* 1942: placebo for E3 */ ///
    xline(15.5, lpattern(dash) lcolor(gs8))   /* 1946: placebo for E3 */ ///
    xline(16.5, lpattern(dot)  lcolor(blue))  /* 1947: IAS exposure begins */ ///
    xline(18.5, lpattern(dash) lcolor(red))   /* 1949 */ ///
    xline(23.5, lpattern(dash) lcolor(red))   /* 1954 */ ///
    xlabel(, angle(90) labsize(vsmall)) ///
    ciopts(recast(rcap)) ///
    title("E3 unified event study (base 1941)") ///
    ytitle("Effect on annual Physical Review publications") ///
    note("Red: shocks reaching E3 (1949, 1954). Grey: E1/E2 shocks, placebo for E3. Blue dotted: 1947 IAS exposure onset.")
graph export "$output/fig_e3_eventstudy.png", replace width(2000)

*-------------------------------------------------------------------------------
* Step 7: Control-group artifact check (drop Seitz/Shockley/Townes)
*   The positive post54T coefficient is driven by these three controls
*   leaving Physical Review, not by a real Inc3 treatment effect. Dropping
*   them should make post54T shrink toward zero / lose significance.
*-------------------------------------------------------------------------------
list name if inlist(name, "Frederick Seitz", "Charles Townes", "William Shockley")

preserve
    drop if inlist(name, "Frederick Seitz", "Charles Townes", "William Shockley")
    xtreg pub_count post49T post54T i.year, fe vce(robust)
    eststo e3_noartifact

    lincom post49T
    display as result "E3 (no artifact) 1949-53 level: " r(estimate) "  (p = " r(p) ")"
    lincom post49T + post54T
    display as result "E3 (no artifact) 1954-60 level: " r(estimate) "  (p = " r(p) ")"
restore

esttab e3_cum e3_noartifact using "$output/table_e3_artifact.tex", replace ///
    keep(post49T post54T) b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("All controls" "Drop Seitz/Shockley/Townes") ///
    title("E3 Inc3 control-group artifact check") label booktabs

log close
********************************************************************************
* NOTE 1: Base year 1941 is kept for cross-exposure figure comparability even
*         though E3 exposure begins in 1947; 1942-48 coefficients are placebo.
*         If Taber prefers a 1948 base for E3, change the omitted dummy and
*         the lincom sums accordingly -- flag this choice in the July report.
* NOTE 2: The Inc3 control-group artifact (Seitz/Shockley/Townes) applies here
*         too; re-run Steps 2-3 dropping those three controls as in file 15.
********************************************************************************
