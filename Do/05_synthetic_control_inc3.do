********************************************************************************
* ECON 580 Honors Tutorial
* Author: Yiqing Zhang
* Date: February 2026
* File: 05_synthetic_control_inc3.do
* Purpose: Synthetic control - Exposure 1, Incident 3 (Clearance Revocation 1954)
********************************************************************************

capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/05_synthetic_control_inc3.log", replace

********************************************************************************
* STEP 1: Load and normalize BEFORE collapsing
********************************************************************************

use "Data/master_panel.dta", clear

* Pre-treatment window is now 1931-1953
bysort physicist_id: egen pre_mean = mean(pub_count) if year < 1954
bysort physicist_id: egen pre_mean_fill = max(pre_mean)

gen denom = max(pre_mean_fill, 1)
gen pcn = pub_count / denom

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

label values physicist_id .
destring physicist_id, replace force

synth pcn ///
    pcn(1931) pcn(1932) pcn(1933) pcn(1934) pcn(1935) ///
    pcn(1936) pcn(1937) pcn(1938) pcn(1939) pcn(1940) ///
    pcn(1941) pcn(1942) pcn(1943) pcn(1944) pcn(1945) ///
    pcn(1946) pcn(1947) pcn(1948) pcn(1949) pcn(1950) ///
    pcn(1951) pcn(1952) pcn(1953) ///
    , trunit(999) trperiod(1954) ///
    keep("Data/synth_results_inc3") replace

********************************************************************************
* STEP 4: Plot
********************************************************************************

use "Data/synth_results_inc3.dta", clear

rename _time year
rename _Y_treated treated_norm
rename _Y_synthetic synthetic_norm

twoway ///
    (line treated_norm year, lcolor(blue) lwidth(medium)) ///
    (line synthetic_norm year, lcolor(red) lpattern(dash) lwidth(medium)), ///
    xline(1954, lcolor(blue) lpattern(dot)) ///
    xlabel(1931(5)1960) ///
    title("Synthetic Control: Security Clearance Revocation 1954") ///
    xtitle("Year") ///
    ytitle("Normalized Publication Count") ///
    legend(label(1 "Treated (Oppenheimer network)") ///
           label(2 "Synthetic Control")) ///
    note("Dotted line = 1954 Security Clearance Revocation")

graph export "Output/synthetic_control_inc3.png", replace
log close
