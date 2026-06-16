********************************************************************************
* ECON 580 Honors Tutorials
* Author: Yiqing Zhang
* Date: February 2026
* File: 01_import_clean.do
* Purpose: Import treatment and control panels, merge into master dataset
********************************************************************************

capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/01_import_clean.log", replace

********************************************************************************
* STEP 1: Import pre-treatment sheet (1931-1941)
********************************************************************************

import excel "Data/treatment_panel_raw.xlsx", ///
    sheet("Pre-Treatment") firstrow clear

drop if Year == 1942

rename Name name
rename Year year
rename Count pub_count

gen treated = 1
save "Data/pre_treatment.dta", replace

********************************************************************************
* STEP 2: Import post-treatment sheet (1942-1960)
********************************************************************************

import excel "Data/treatment_panel_raw.xlsx", ///
    sheet("Post-Treatment") firstrow clear

rename Name name
rename Year year
rename Count pub_count

gen treated = 1
save "Data/post_treatment.dta", replace

********************************************************************************
* STEP 3: Combine treatment panel
********************************************************************************

append using "Data/pre_treatment.dta"
save "Data/treatment_full.dta", replace

********************************************************************************
* STEP 4: Import control panel
********************************************************************************

import delimited "Data/control_panel.csv", ///
    varnames(1) clear

rename name name
rename year year
rename count pub_count

* Drop problematic physicists
drop if name == "Furry"
drop if name == "Kemble"
drop if name == "Wu"
drop if name == "Dancoff"
drop if name == "S. Dancoff"
drop if name == "E. Feenberg"
drop if name == "A. Klein"

gen treated = 0
save "Data/control_full.dta", replace

********************************************************************************
* STEP 5: Merge treatment and control into master panel
********************************************************************************

use "Data/treatment_full.dta", clear
append using "Data/control_full.dta"

* Create post dummy
gen post = (year >= 1942)

* Create physicist ID
encode name, gen(physicist_id)

* Declare panel structure
xtset physicist_id year

* Check balance
xtdescribe
summarize

********************************************************************************
* STEP 6: Save master dataset
********************************************************************************

save "Data/master_panel.dta", replace

log close
