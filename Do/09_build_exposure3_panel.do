********************************************************************************
* ECON 580 Honors Thesis
* Author: Yiqing Zhang
* Date: April 2026
* File: build_exposure3_panel.do
* Purpose: Build exposure3_panel.dta from raw CSV data
********************************************************************************

capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/build_exposure3_panel.log", replace

********************************************************************************
* STEP 1: Import raw panel
********************************************************************************

import delimited "Data/exposure3_panel.csv", clear varnames(1) stringcols(1)

* Label variables
label variable name "Physicist Name"
label variable year "Year"
label variable pub_count "Publication Count"
label variable treated "Treatment Indicator"

********************************************************************************
* STEP 2: Generate post-treatment indicators
********************************************************************************

* Incident 1 (1942) - Manhattan Project
* Note: IAS treatment is NOT relevant for Incident 1
* Incident 2 (1949) - Soviet Bomb Test
gen post2 = (year >= 1949)
label variable post2 "Post Soviet Bomb Test (1949)"

* Incident 3 (1954) - Security Revocation
gen post3 = (year >= 1954)
label variable post3 "Post Security Revocation (1954)"

********************************************************************************
* STEP 3: Generate numeric ID for xtset
********************************************************************************

egen id = group(name)
label variable id "Physicist ID"

********************************************************************************
* STEP 4: Set panel structure
********************************************************************************

xtset id year
xtdescribe

********************************************************************************
* STEP 5: Summary statistics
********************************************************************************

* Count treated vs control
tab treated
tabstat pub_count, by(treated) stats(mean sd min max n)

* Check panel is balanced
tab year if treated == 1
tab year if treated == 0

********************************************************************************
* STEP 6: Save
********************************************************************************

save "Data/exposure3_panel.dta", replace

log close
