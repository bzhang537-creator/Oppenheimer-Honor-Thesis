********************************************************************************
* ECON 580 Honors Thesis
* Author: Yiqing Zhang
* Date: August 2026
* File: 27_build_manhattan_panel.do
* Purpose: Construct manhattan_panel.dta for the pure-incapacitation benchmark
*          (E3-Inc1) from raw PROLA publication counts.
*
*   INPUTS:
*     Data/manhattan_prola_final.csv  -- long format: name, year, pub_count
*         (212 physicists x 30 years, 1931-1960; already deduped against
*          E1, E2, and IAS during list construction)
*     Data/control_group_clean.csv    -- the 24 shared control physicists
*         (must have their own PROLA counts panel; see note below)
*
*   OUTPUT:
*     Data/manhattan_panel.dta        -- treated (74 Manhattan physicists that
*         pass the pre-1942 baseline filter) + 24 controls, balanced 1931-1960
*
*   SAMPLE RULE: keep a Manhattan physicist only if they have >=1 Physical
*   Review publication BEFORE 1942 (a pre-treatment baseline). This drops
*   health-physicists / non-PR physicists (no baseline) and post-1942 entrants
*   (no pre-treatment period to measure a decline against). Documented in
*   Data/manhattan_baseline_status_final.csv.
********************************************************************************
capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/27_build_manhattan_panel.do", replace

*-------------------------------------------------------------------------------
* Step 1: Load raw Manhattan PROLA counts (long format)
*-------------------------------------------------------------------------------
import delimited "Data/manhattan_prola_final.csv", clear varnames(1) ///
    stringcols(1)
* expected columns: name, year, pub_count
destring year pub_count, replace force
drop if missing(year)

* Integrity: every physicist should have exactly 30 year-rows
bysort name (year): gen _nyr = _N
quietly summ _nyr
assert r(min) == 30 & r(max) == 30
drop _nyr

* Balance check: years span 1931-1960
assert inrange(year, 1931, 1960)

*-------------------------------------------------------------------------------
* Step 2: Apply the pre-1942 baseline filter
*-------------------------------------------------------------------------------
bysort name (year): egen pre1942 = total(pub_count * (year < 1942))
bysort name (year): egen alltime = total(pub_count)

* Record who is kept vs dropped (for the sample-construction appendix)
preserve
    bysort name: keep if _n == 1
    keep name pre1942 alltime
    gen keep = pre1942 > 0
    export delimited "Output/manhattan_sample_construction.csv", replace
    quietly count if keep
    di as result "Physicists passing pre-1942 baseline filter: " r(N)
    quietly count if !keep
    di as result "Physicists dropped (no pre-1942 baseline): " r(N)
restore

keep if pre1942 > 0     // KEEP treated benchmark physicists only
drop pre1942 alltime

gen treated = 1
tempfile manhattan_treated
save `manhattan_treated'

*-------------------------------------------------------------------------------
* Step 3: Bring in the 24 shared controls
*   IMPORTANT: controls must be measured on the SAME outcome (Physical Review,
*   1931-1960) as every other exposure level, so the benchmark is comparable
*   to E1/E2/E3. If you already have a controls panel from the E1 build, load
*   that instead of re-importing, to guarantee identical control counts.
*-------------------------------------------------------------------------------
* Option A (preferred): reuse the exact controls already in master_panel_v2
use "Data/master_panel_v2.dta", clear
keep if treated == 0            // the 24 controls, with their PR counts
keep name year pub_count treated
tempfile controls
save `controls'

* Option B (fallback, if controls not stored in master_panel_v2):
*   import delimited "Data/control_group_panel.dta", clear   // must be long PR counts
*   Then set treated = 0.

*-------------------------------------------------------------------------------
* Step 4: Stack treated + controls into the benchmark panel
*-------------------------------------------------------------------------------
use `manhattan_treated', clear
append using `controls'

* Panel id
egen id = group(name)
xtset id year

* Final integrity checks
bysort id (year): assert _N == 30          // balanced
bysort id: assert treated == treated[1]    // time-invariant group
assert inlist(treated, 0, 1)
tab treated

* Confirm no control accidentally also appears among treated (name collision)
bysort name: gen _ngrp = treated[1] != treated[_N]
assert _ngrp == 0
drop _ngrp

label var pub_count "Physical Review research articles per year"
label var treated   "1 = Manhattan benchmark physicist, 0 = control"

*-------------------------------------------------------------------------------
* Step 5: Save
*-------------------------------------------------------------------------------
save "Data/manhattan_panel.dta", replace
di as result "Saved Data/manhattan_panel.dta"
quietly levelsof id if treated==1, local(nt)
di as result "Treated (benchmark) physicists: " `: word count `nt''
quietly levelsof id if treated==0, local(nc)
di as result "Control physicists: " `: word count `nc''

log close
********************************************************************************
* NEXT: run 28_manhattan_benchmark.do to estimate the incapacitation event
* study (1942 dip / 1946 recovery / 1949 placebo), then 29_decomposition.do
* for the E1-minus-benchmark channel decomposition.
********************************************************************************
