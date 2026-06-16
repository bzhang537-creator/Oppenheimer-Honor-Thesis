********************************************************************************
* ECON 580 Honors Thesis
* Author: Yiqing Zhang
* Date: March 2026
* File: 01_build_panel_v2.do
* Purpose: Build master panel from PROLA-sourced data (v2)
*          Includes updated Exposure = 1 treated, new controls,
*          and Exposure = 2 physicists
********************************************************************************

capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/01_build_panel_v2.log", replace

********************************************************************************
* PART A: EXPOSURE = 1 PANEL
********************************************************************************

* --- Import treated group (11 physicists) ---
import delimited "Data/treated_group_publications.csv", clear varnames(1)
gen treated = 1
gen exposure = 1
tempfile treated
save `treated'

* --- Import new controls batch 1 (12 physicists) ---
import delimited "Data/new_controls_batch1.csv", clear varnames(1)
gen treated = 0
gen exposure = 0
tempfile controls1
save `controls1'

* --- Import new controls batch 2 (14 physicists) ---
import delimited "Data/new_controls_batch2.csv", clear varnames(1)
gen treated = 0
gen exposure = 0
tempfile controls2
save `controls2'

* --- Combine Exposure = 1 panel ---
use `treated', clear
append using `controls1'
append using `controls2'

* --- Drop Joseph Doob (0 publications in Physical Review) ---
drop if name == "Joseph Doob"

* --- Rename for consistency ---
rename publication_count pub_count

* Destring if needed
capture destring pub_count, replace
capture destring year, replace

* --- Create post variables for three incidents ---
gen post1 = (year >= 1942)
gen post2 = (year >= 1949)
gen post3 = (year >= 1954)

* For backward compatibility with old do files
gen post = post1

* --- Create panel ID ---
encode name, gen(id)
xtset id year

* --- Verify panel structure ---
di "=== EXPOSURE = 1 PANEL SUMMARY ==="
tab treated
qui levelsof name if treated == 1
di "Treated physicists: `r(r)'"
qui levelsof name if treated == 0
di "Control physicists: `r(r)'"

* --- Save ---
save "Data/master_panel_v2.dta", replace
di "Exposure = 1 panel saved."

********************************************************************************
* PART B: EXPOSURE = 2 PANEL
********************************************************************************

* --- Import Exposure = 2 physicists ---
import delimited "Data/exposure2_all_publications.csv", clear varnames(1)
gen treated = 1
gen exposure = 2
tempfile exp2_treated
save `exp2_treated'

* --- Use same controls as Exposure = 1 ---
import delimited "Data/new_controls_batch1.csv", clear varnames(1)
gen treated = 0
gen exposure = 0
tempfile exp2_controls1
save `exp2_controls1'

* --- Import new controls batch 2 ---
import delimited "Data/new_controls_batch2.csv", clear varnames(1)
gen treated = 0
gen exposure = 0
tempfile exp2_controls2
save `exp2_controls2'

* --- Combine Exposure = 2 panel ---
use `exp2_treated', clear
append using `exp2_controls1'
append using `exp2_controls2'

* --- Drop Joseph Doob (0 publications in Physical Review) ---
drop if name == "Joseph Doob"

* --- Rename for consistency ---
rename publication_count pub_count

* Destring if needed
capture destring pub_count, replace
capture destring year, replace

* --- Drop physicists with 0 total publications (no usable data) ---
bysort name: egen total_pubs = total(pub_count)
tab name if total_pubs == 0
drop if total_pubs == 0
drop total_pubs

* --- Create post variables ---
gen post1 = (year >= 1942)
gen post2 = (year >= 1949)
gen post3 = (year >= 1954)
gen post = post1

* --- Create panel ID ---
encode name, gen(id)
xtset id year

* --- Verify panel structure ---
di "=== EXPOSURE = 2 PANEL SUMMARY ==="
tab treated
qui levelsof name if treated == 1
di "Treated physicists: `r(r)'"
qui levelsof name if treated == 0
di "Control physicists: `r(r)'"

* --- Save ---
save "Data/exposure2_panel.dta", replace
di "Exposure = 2 panel saved."

log close
