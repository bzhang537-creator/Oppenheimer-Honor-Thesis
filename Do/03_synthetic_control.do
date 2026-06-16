********************************************************************************
* ECON 580 Honors Tutorial
* Author: Yiqing Zhang
* Date: February 2026
* File: 03_synthetic_control_inc1.do
* Purpose: Synthetic control - Exposure 1, Incident 1 (Manhattan Project 1942)
********************************************************************************

capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/03_synthetic_control_inc1.log", replace

********************************************************************************
* STEP 1: Load and normalize BEFORE collapsing
********************************************************************************

use "Data/master_panel.dta", clear

* Calculate pre-treatment mean per physicist
bysort physicist_id: egen pre_mean = mean(pub_count) if year < 1942
bysort physicist_id: egen pre_mean_fill = max(pre_mean)

* Normalize using max(pre_mean, 1) as denominator
* This prevents explosion for near-zero pre-treatment physicists
gen denom = max(pre_mean_fill, 1)
gen pcn = pub_count / denom

* Verify normalization looks reasonable
summarize pcn

********************************************************************************
* STEP 2: Collapse treated group to single unit (ID = 999)
********************************************************************************

collapse (mean) pub_count pcn treated, by(year physicist_id)

replace physicist_id = 999 if treated == 1
collapse (mean) pub_count pcn treated, by(year physicist_id)

label values physicist_id .

tsset physicist_id year

********************************************************************************
* STEP 3: Run synthetic control
********************************************************************************

* Strip value label from physicist_id
label values physicist_id .

* Also make sure physicist_id is numeric
destring physicist_id, replace force

synth pcn ///
    pcn(1931) pcn(1932) pcn(1933) ///
    pcn(1934) pcn(1935) pcn(1936) ///
    pcn(1937) pcn(1938) pcn(1939) ///
    pcn(1940) pcn(1941) ///
    , trunit(999) trperiod(1942) ///
    keep("Data/synth_results") replace

********************************************************************************
* STEP 4: Plot synthetic control vs treated
********************************************************************************

use "Data/synth_results.dta", clear

* Set a minimum threshold of 1 paper per year average

********************************************************************************
* STEP 4: Plot synthetic control vs treated
********************************************************************************

use "Data/synth_results.dta", clear

rename _time year
rename _Y_treated treated_norm
rename _Y_synthetic synthetic_norm

twoway ///
    (line treated_norm year, lcolor(blue) lwidth(medium)) ///
    (line synthetic_norm year, lcolor(red) lpattern(dash) lwidth(medium)), ///
    xline(1942, lcolor(red) lpattern(dot)) ///
    xline(1949, lcolor(orange) lpattern(dot)) ///
    xline(1954, lcolor(blue) lpattern(dot)) ///
    xlabel(1931(5)1960) ///
    title("Synthetic Control: Manhattan Project 1942") ///
    xtitle("Year") ///
    ytitle("Normalized Publication Count") ///
    legend(label(1 "Treated (Oppenheimer network)") ///
           label(2 "Synthetic Control")) ///
    note("Red = 1942 Manhattan Project | Orange = 1949 Soviet Bomb | Blue = 1954 Clearance Revocation")
	
graph export "Output/synthetic_control_inc1.png", replace

log close
