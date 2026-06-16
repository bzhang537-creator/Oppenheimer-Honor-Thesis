********************************************************************************
* ECON 580 Honors Thesis
* Author: Yiqing Zhang
* Date: May 2026
* File: 12_synthetic_control_e1_inc1.do
* Purpose: Synthetic control - Exposure 1, Incident 1 (Manhattan Project 1942)
********************************************************************************

capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/12_synthetic_control_inc1.log", replace

********************************************************************************
* STEP 1: Load and normalize
********************************************************************************

use "Data/master_panel_v2.dta", clear

* Calculate pre-treatment mean per physicist
bysort id: egen pre_mean = mean(pub_count) if year < 1942
bysort id: egen pre_mean_fill = max(pre_mean)

* Normalize using max(pre_mean, 1) to prevent explosion for near-zero physicists
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
    pcn(1931) pcn(1932) pcn(1933) ///
    pcn(1934) pcn(1935) pcn(1936) ///
    pcn(1937) pcn(1938) pcn(1939) ///
    pcn(1940) pcn(1941) ///
    , trunit(999) trperiod(1942) ///
    keep("Data/synth_inc1_results") replace

********************************************************************************
* STEP 4: Plot
********************************************************************************

use "Data/synth_inc1_results.dta", clear

rename _time year
rename _Y_treated treated_norm
rename _Y_synthetic synthetic_norm

twoway ///
    (line treated_norm year, lcolor(blue) lwidth(medium)) ///
    (line synthetic_norm year, lcolor(red) lpattern(dash) lwidth(medium)), ///
    xline(1942, lcolor(black) lpattern(dot)) ///
    xlabel(1931(5)1960) ///
    title("Synthetic Control: Exposure = 1, Incident 1 (1942)") ///
    xtitle("Year") ///
    ytitle("Normalized Publication Count") ///
    legend(label(1 "Treated (Oppenheimer co-authors)") ///
           label(2 "Synthetic Control")) ///
    note("Dotted line = 1942 Manhattan Project")

graph export "Output/synth_inc1.png", replace

log close
