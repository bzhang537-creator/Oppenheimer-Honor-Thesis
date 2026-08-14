********************************************************************************
* 24_exposure4_phd_students.do
* Political Shocks and Scientific Network Productivity:
* Evidence from the Oppenheimer Affair
*
* Purpose : Unified event study for Exposure 4 -- pre-1942 PhD students of
*           Oppenheimer, EXCLUDING anyone already in E1 or E2 (mentorship
*           tie only, no co-authorship contamination).
*           Precedent: Waldinger (2010, JPE) -- PhD students of dismissed
*           professors in Nazi Germany.
*
* STATUS  : SKELETON. Waiting on data collection. Runs as-is once
*           exposure4_panel.dta exists with the variables below.
*
* Required panel structure (match master_panel_v2.dta conventions):
*   name       string   physicist name (panel unit)
*   year       int      1931-1960, balanced
*   pub_count  int      annual Physical Review publication count
*   treated    byte     1 = E4 (pre-1942 Oppenheimer PhD student, not in
*                            E1 or E2), 0 = control (same 24 controls)
*   phd_year   int      year of PhD completion -- MUST be <= 1941 for all
*                       treated units (pre-determined exposure)
*
* Data sources for the student roster:
*   - AIP Niels Bohr Library & Archives (Oppenheimer collection)
*   - Physics Tree (academictree.org/physics) for advisor-student links
*   - Published lists of Oppenheimer's Berkeley doctoral students
* Cross-check every student against the E1 (11) and E2 (107) name lists
* BEFORE building the panel; drop any overlap.
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

log using "$log/24_exposure4_phd_students.log", replace

*-------------------------------------------------------------------------------
* Step 1: Load E4 panel and validate design constraints
*-------------------------------------------------------------------------------
use "$data/exposure4_panel.dta", clear

capture confirm numeric variable id
if _rc {
    egen id = group(name)
}
xtset id year

assert inrange(year, 1931, 1960)
bysort id: assert treated == treated[1]

* Exposure must be pre-determined: no treated unit with post-1941 PhD
assert phd_year <= 1941 if treated == 1

*-------------------------------------------------------------------------------
* Step 2: Cumulative-shift specification
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
eststo e4_cum: xtreg pub_count post42T post46T post49T post54T i.year, ///
    fe vce(robust)

lincom post42T
estadd scalar lvl_4245 = r(estimate) : e4_cum
lincom post42T + post46T
estadd scalar lvl_4648 = r(estimate) : e4_cum
lincom post42T + post46T + post49T
estadd scalar lvl_4953 = r(estimate) : e4_cum
lincom post42T + post46T + post49T + post54T
estadd scalar lvl_5460 = r(estimate) : e4_cum

*-------------------------------------------------------------------------------
* Step 3: Flexible event study, base year 1941 (manual dummies)
*-------------------------------------------------------------------------------
forvalues y = 1931/1960 {
    if `y' != 1941 {
        gen tr`y' = treated * (year == `y')
    }
}

eststo e4_flex: xtreg pub_count tr19* i.year, fe vce(robust)

testparm tr1931 tr1932 tr1933 tr1934 tr1935 tr1936 tr1937 tr1938 tr1939 tr1940
estadd scalar pretrend_F = r(F) : e4_flex
estadd scalar pretrend_p = r(p) : e4_flex

* CAUTION: young students may have near-zero pre-1942 publications (still in
* training), which mechanically flattens the pre-period. If pre-1942 treated
* counts are mostly zero, say so in the write-up rather than claiming a
* clean parallel-trends test.
count if treated == 1 & year < 1942 & pub_count > 0
display as result "Treated pre-1942 physicist-years with >0 pubs: " r(N)

*-------------------------------------------------------------------------------
* Step 4: Export
*-------------------------------------------------------------------------------
esttab e4_cum using "$output/table_e4_unified.tex", replace ///
    keep(post42T post46T post49T post54T) ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    scalars("lvl_4245 Level 1942-45" "lvl_4648 Level 1946-48" ///
            "lvl_4953 Level 1949-53" "lvl_5460 Level 1954-60") ///
    title("E4 (PhD students) unified event study") ///
    label booktabs

estimates restore e4_flex
coefplot, keep(tr19*) ///
    rename(^tr([0-9]+)$ = \1, regex) ///
    vertical omitted baselevels ///
    yline(0, lcolor(gs10)) ///
    xline(11.5, lpattern(dash) lcolor(red)) ///
    xline(15.5, lpattern(dash) lcolor(red)) ///
    xline(18.5, lpattern(dash) lcolor(red)) ///
    xline(23.5, lpattern(dash) lcolor(red)) ///
    xlabel(, angle(90) labsize(vsmall)) ///
    ciopts(recast(rcap)) ///
    title("E4 (PhD students) unified event study (base 1941)") ///
    ytitle("Effect on annual Physical Review publications")
graph export "$output/fig_e4_eventstudy.png", replace width(2000)

log close
********************************************************************************
* FRAMING NOTE: Do not present E4 as "network distance 4." A doctoral
* advising tie is a different TYPE of tie (mentorship), plausibly closer
* than E2. The comparison of interest is E4 vs E1: does political contagion
* travel through training relationships as strongly as through collaboration?
********************************************************************************
