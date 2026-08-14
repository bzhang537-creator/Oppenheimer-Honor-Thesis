********************************************************************************
* 22_exposure2_event_study.do
* Political Shocks and Scientific Network Productivity:
* Evidence from the Oppenheimer Affair
*
* Purpose : Unified event study for Exposure 2 (107 co-authors of co-authors)
*           mirroring 19_exposure1_event_study.do.
*           (a) Cumulative-shift specification (post42/post46/post49/post54)
*           (b) Flexible event study, base year 1941 (manual tr dummies,
*               1941 omitted by construction -- NOT Stata's default omission)
*           (c) Joint pre-trend test, lincom level effects, coefplot
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

log using "$log/22_exposure2_event_study.log", replace

*-------------------------------------------------------------------------------
* Step 1: Load E2 panel and set up
*-------------------------------------------------------------------------------
use "$data/exposure2_panel.dta", clear

capture confirm numeric variable id
if _rc {
    egen id = group(name)
}
xtset id year

* Sanity checks
assert inrange(year, 1931, 1960)
tab treated
bysort id: assert treated == treated[1]   // time-invariant group membership

*-------------------------------------------------------------------------------
* Step 2: Cumulative-shift specification (eq. 1 of June handout)
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
eststo e2_cum: xtreg pub_count post42T post46T post49T post54T i.year, ///
    fe vce(robust)

* Cumulative level effects via lincom, stored with estadd
lincom post42T
estadd scalar lvl_4245 = r(estimate) : e2_cum
estadd scalar se_4245  = r(se)       : e2_cum

lincom post42T + post46T
estadd scalar lvl_4648 = r(estimate) : e2_cum
estadd scalar se_4648  = r(se)       : e2_cum

lincom post42T + post46T + post49T
estadd scalar lvl_4953 = r(estimate) : e2_cum
estadd scalar se_4953  = r(se)       : e2_cum

lincom post42T + post46T + post49T + post54T
estadd scalar lvl_5460 = r(estimate) : e2_cum
estadd scalar se_5460  = r(se)       : e2_cum

*-------------------------------------------------------------------------------
* Step 3: Flexible event study, base year 1941 (manual dummies)
*         1941 is omitted BY CONSTRUCTION -- do not let Stata pick the base.
*-------------------------------------------------------------------------------
forvalues y = 1931/1960 {
    if `y' != 1941 {
        gen tr`y' = treated * (year == `y')
    }
}

eststo e2_flex: xtreg pub_count tr19* i.year, fe vce(robust)

local kept : colnames e(b)
foreach v of varlist tr1931-tr1940 tr1942-tr1960 {
    if !`: list v in kept' {
        di as error "WARNING: `v' dropped from the model."
    }
}
* Joint pre-trend test: all pre-1942 interactions
testparm tr1931 tr1932 tr1933 tr1934 tr1935 tr1936 tr1937 tr1938 tr1939 tr1940
estadd scalar pretrend_F = r(F)   : e2_flex
estadd scalar pretrend_p = r(p)   : e2_flex
display as result "E2 joint pre-trend test: F = " r(F) ", p = " r(p)

*-------------------------------------------------------------------------------
* Step 4: Treated-specific linear trend robustness (pre-trend defense)
*-------------------------------------------------------------------------------
gen tr_trend = treated * (year - 1941)
eststo e2_trend: xtreg pub_count post42T post46T post49T post54T tr_trend ///
    i.year, fe vce(robust)

*-------------------------------------------------------------------------------
* Step 5: Export tables
*-------------------------------------------------------------------------------
esttab e2_cum e2_trend using "$output/table_e2_unified.tex", replace ///
    keep(post42T post46T post49T post54T tr_trend) ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    scalars("lvl_4245 Level 1942-45" "lvl_4648 Level 1946-48" ///
            "lvl_4953 Level 1949-53" "lvl_5460 Level 1954-60") ///
    mtitles("Cumulative" "Treated trend") ///
    title("E2 unified event study: incremental and level effects") ///
    label booktabs

esttab e2_flex using "$output/table_e2_eventstudy.tex", replace ///
    keep(tr19*) b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    scalars("pretrend_F Pre-trend F" "pretrend_p Pre-trend p") ///
    title("E2 flexible event study, base 1941") ///
    label booktabs

*-------------------------------------------------------------------------------
* Step 6: Event study figure
*-------------------------------------------------------------------------------
estimates restore e2_flex
coefplot, keep(tr19*) ///
    rename(^tr([0-9]+)$ = \1, regex) ///
    vertical omitted baselevels ///
    yline(0, lcolor(gs10)) ///
    xline(11.5, lpattern(dash) lcolor(red))   /* 1942 */ ///
    xline(15.5, lpattern(dash) lcolor(red))   /* 1946 */ ///
    xline(18.5, lpattern(dash) lcolor(red))   /* 1949 */ ///
    xline(23.5, lpattern(dash) lcolor(red))   /* 1954 */ ///
    xlabel(, angle(90) labsize(vsmall)) ///
    ciopts(recast(rcap)) ///
    title("E2 unified event study (base 1941)") ///
    ytitle("Effect on annual Physical Review publications") ///
    note("Vertical lines: 1942 Manhattan Project, 1946 return, 1949 Soviet test, 1954 clearance revocation")
graph export "$output/fig_e2_eventstudy.png", replace width(2000)

log close
********************************************************************************
* NOTE: xline positions assume 29 plotted coefficients (1931-1940, 1942-1960)
* in calendar order. If coefplot reorders, verify positions against the
* rendered axis before exporting.
********************************************************************************
