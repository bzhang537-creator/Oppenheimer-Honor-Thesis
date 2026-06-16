********************************************************************************
* ECON 580 Honors Thesis
* Author: Yiqing Zhang
* Date: May 2026
* File: 14_synthetic_control_e1_inc3.do
* Purpose: Synthetic control - Exposure 1, Incident 3 (Security Revocation 1954)
********************************************************************************

capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/14_synthetic_control_inc3.log", replace

********************************************************************************
* STEP 1: Load, restrict window, and normalize
********************************************************************************

use "Data/master_panel_v2.dta", clear

* Restrict to Incident 3 window
keep if year >= 1950 & year <= 1960

* Calculate pre-treatment mean per physicist
bysort id: egen pre_mean = mean(pub_count) if year < 1954
bysort id: egen pre_mean_fill = max(pre_mean)

* Normalize
gen denom = max(pre_mean_fill, 1)
gen pcn = pub_count / denom

summarize pcn

********************************************************************************
* STEP 2: Collapse treated group to single unit (ID = 999)
********************************************************************************

collapse (mean) pub_count pcn treated, by(year id)
replace id = 999 if treated == 1
collapse (mean) pub_count pcn treated, by(year id)

label values id .
tsset id year

********************************************************************************
* STEP 3: Run synthetic control
********************************************************************************

synth pcn ///
    pcn(1950) pcn(1951) pcn(1952) pcn(1953) ///
    , trunit(999) trperiod(1954) ///
    keep("Data/synth_inc3_results") replace

********************************************************************************
* STEP 4: Plot
********************************************************************************

use "Data/synth_inc3_results.dta", clear

rename _time year
rename _Y_treated treated_norm
rename _Y_synthetic synthetic_norm

twoway ///
    (line treated_norm year, lcolor(blue) lwidth(medium)) ///
    (line synthetic_norm year, lcolor(red) lpattern(dash) lwidth(medium)), ///
    xline(1954, lcolor(black) lpattern(dot)) ///
    xlabel(1950(2)1960) ///
    title("Synthetic Control: Exposure = 1, Incident 3 (1954)") ///
    xtitle("Year") ///
    ytitle("Normalized Publication Count") ///
    legend(label(1 "Treated (Oppenheimer co-authors)") ///
           label(2 "Synthetic Control")) ///
    note("Dotted line = 1954 Security Revocation")

graph export "Output/synth_inc3.png", replace

log close
