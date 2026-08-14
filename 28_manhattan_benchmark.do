********************************************************************************
* ECON 580 Honors Thesis
* Author: Yiqing Zhang
* Date: August 2026
* File: 28_manhattan_benchmark.do
* Purpose: Pure-incapacitation benchmark (E3-Inc1). Manhattan Project
*          physicists (AHF Scientist filter, "Physicist" subtitle) with NO
*          Oppenheimer network tie -- deduped against E1, E2, and IAS(E3).
*
*   This group is incapacitated by wartime service (classified out of open
*   publishing ~1943-45) but carries NO spillover or chilling, because it has
*   no Oppenheimer association. Its event-study path is therefore the
*   empirical shape of the PURE INCAPACITATION CHANNEL.
*
*   SHOCK TIMING DIFFERS FROM E1/E2/E3. The live events here are the 1942
*   recruitment / 1946 return, NOT 1949/1954. Predictions:
*     - post42 (1942-45): NEGATIVE  (wartime incapacitation)
*     - post46 (1946+):   RECOVERY toward zero (physicists return)
*     - post49, post54:   ~0 PLACEBO (no Oppenheimer tie -> no political shock)
*   A null at 1949/1954 validates that the group is clean of spillover.
*
*   Base year 1941, manual dummies (same construction as 19/22/23).
* Requires: coefplot, boottest, reghdfe/ftools
********************************************************************************
capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/28_manhattan_benchmark.log", replace

*-------------------------------------------------------------------------------
* Step 0: Load benchmark panel and set up
*   manhattan_panel.dta must have: name, year (1931-1960), pub_count,
*   treated (1 = Manhattan physicist, 0 = same 24 controls as other exposures)
*   Build it from PROLA counts on manhattan_benchmark_final.csv survivors,
*   keeping only physicists with any PRE-1942 Physical Review presence
*   (drops health-physicists / no-baseline names automatically).
*-------------------------------------------------------------------------------
use "Data/manhattan_panel.dta", clear
keep if year >= 1931 & year <= 1960

capture confirm numeric variable id
if _rc {
    egen id = group(name)
}
xtset id year
assert inlist(treated, 0, 1)
bysort id: assert treated == treated[1]

* Verify the pre-1942 baseline filter was applied when the panel was built:
* every treated physicist should have >0 total pre-1942 publications.
bysort id (year): egen pre42_total = total(pub_count * (year < 1942))
count if treated == 1 & pre42_total == 0
if r(N) > 0 {
    di as error "WARNING: `r(N)' treated physician-panels have zero pre-1942 pubs."
    di as error "These have no measurable baseline -- consider dropping before running."
}
drop pre42_total

*-------------------------------------------------------------------------------
* Step 1: Cumulative-shift specification, incapacitation timing
*   post42 = wartime recruitment; post46 = return; post49/54 = placebo
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

* (a) Primary incapacitation spec: 1942 dip, 1946 recovery
eststo mh_cum: xtreg pub_count post42T post46T i.year, fe vce(robust)

lincom post42T
estadd scalar lvl_4245 = r(estimate) : mh_cum
estadd scalar se_4245  = r(se)       : mh_cum
display as result "Benchmark 1942-45 (incapacitation): " r(estimate) "  (p=" r(p) ")"

lincom post42T + post46T
estadd scalar lvl_4648 = r(estimate) : mh_cum
estadd scalar se_4648  = r(se)       : mh_cum
display as result "Benchmark 1946-48 (recovery): " r(estimate) "  (p=" r(p) ")"

* (b) Placebo spec: add 1949/1954. For a no-tie group these should be ~0.
*     Significant post49T/post54T here would mean the group is NOT clean of
*     the Oppenheimer channels (e.g. residual network overlap the dedup missed).
eststo mh_placebo: xtreg pub_count post42T post46T post49T post54T i.year, ///
    fe vce(robust)
lincom post49T
display as result "PLACEBO post49T (should be ~0): " r(estimate) "  (p=" r(p) ")"
lincom post54T
display as result "PLACEBO post54T (should be ~0): " r(estimate) "  (p=" r(p) ")"

*-------------------------------------------------------------------------------
* Step 2: Wild cluster bootstrap on the incapacitation coefficients
*-------------------------------------------------------------------------------
xtreg pub_count post42T post46T i.year, fe vce(robust)
boottest post42T, reps(9999) seed(19420816) nograph
boottest post46T, reps(9999) seed(19420816) nograph

*-------------------------------------------------------------------------------
* Step 3: Flexible event study, base 1941 (manual dummies)
*-------------------------------------------------------------------------------
forvalues y = 1931/1960 {
    if `y' != 1941 {
        capture drop tr`y'
        gen tr`y' = treated * (year == `y')
    }
}
eststo mh_flex: xtreg pub_count tr19* i.year, fe vce(robust)

* Drop-check (Poisson-style separation possible if wartime pubs hit zero)
local kept : colnames e(b)
foreach v of varlist tr1931-tr1940 tr1942-tr1960 {
    if !`: list v in kept' {
        di as error "WARNING: `v' dropped from the model."
    }
}

* Pre-trend test (true pre-period 1931-40)
testparm tr1931 tr1932 tr1933 tr1934 tr1935 tr1936 tr1937 tr1938 tr1939 tr1940
estadd scalar pretrend_F = r(F) : mh_flex
estadd scalar pretrend_p = r(p) : mh_flex
display as result "Benchmark pre-trend: F=" r(F) ", p=" r(p)

* Placebo test on the political-shock window (1949-60): should be jointly ~0
testparm tr1949 tr1950 tr1951 tr1952 tr1953 tr1954 tr1955 tr1956 ///
         tr1957 tr1958 tr1959 tr1960
estadd scalar placebo_F = r(F) : mh_flex
estadd scalar placebo_p = r(p) : mh_flex
display as result "Benchmark 1949-60 placebo (should NOT reject): F=" r(F) ", p=" r(p)

*-------------------------------------------------------------------------------
* Step 4: Export table and figure
*-------------------------------------------------------------------------------
esttab mh_cum mh_placebo using "Output/table_manhattan_benchmark.tex", replace ///
    keep(post42T post46T post49T post54T) b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    scalars("lvl_4245 1942-45 level" "lvl_4648 1946-48 level") ///
    mtitles("Incapacitation" "With placebo") ///
    title("Manhattan incapacitation benchmark") label booktabs

estimates restore mh_flex
coefplot, keep(tr19*) rename(^tr([0-9]+)$ = \1, regex) vertical ///
    yline(0, lcolor(gs10)) ///
    xline(11 15, lpattern(dash) lcolor(red))   /* 1942 recruit, 1946 return */ ///
    xline(18 23, lpattern(dot)  lcolor(gs9))   /* 1949, 1954 placebo */ ///
    xlabel(, angle(90) labsize(vsmall)) ciopts(recast(rcap)) ///
    title("Manhattan incapacitation benchmark (base 1941)") ///
    ytitle("Effect on annual Physical Review publications") ///
    note("Red: 1942 recruitment / 1946 return (incapacitation window). Grey dotted: 1949/1954 placebo (no Oppenheimer tie).")
graph export "Output/fig_manhattan_benchmark.png", replace width(2000)

log close
********************************************************************************
* READING THE BENCHMARK:
*  - If post42T < 0 and post46T recovers it toward 0, and post49T/post54T
*    are ~0, the group behaves as a clean incapacitation benchmark: a
*    temporary wartime dip that recovers, with no political-era effect.
*  - The 1946 RECOVERY is the key contrast with E1, which does NOT recover.
*    That gap is developed formally in 29_decomposition.do.
*  - A nonzero post49T would flag residual Oppenheimer-network overlap the
*    name dedup missed -> revisit the E1/E2/IAS merge.
********************************************************************************
