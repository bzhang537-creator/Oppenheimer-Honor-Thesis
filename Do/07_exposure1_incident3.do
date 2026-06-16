********************************************************************************
* ECON 580 Honors Tutorials
* Author: Yiqing Zhang
* Date: February 2026
* File: 07_exposure1_incident3.do
* Purpose: DiD analysis - Exposure 1, Incident 3 (Security Clearance Revocation 1954)
********************************************************************************

capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/07_exposure1_incident3.log", replace
use "Data/master_panel.dta", clear

* Restrict to sample window around Incident 3
* Pre-period: 1950-1953 (post-Soviet bomb, pre-clearance revocation)
* Post-period: 1954-1960
keep if year >= 1950 & year <= 1960

* Generate post indicator for Incident 3
gen post3 = (year >= 1954)

********************************************************************************
* STEP 1: Plot treated vs control trends
********************************************************************************

preserve
collapse (mean) pub_count, by(year treated)

twoway ///
    (line pub_count year if treated == 1, lcolor(blue) lwidth(medium)) ///
    (line pub_count year if treated == 0, lcolor(red) lwidth(medium) lpattern(dash)), ///
    xline(1954, lcolor(black) lpattern(dot)) ///
    xlabel(1950(2)1960) ///
    title("Average Publications: Treated vs Control") ///
    xtitle("Year") ///
    ytitle("Mean Publication Count") ///
    legend(label(1 "Treated (Oppenheimer network)") ///
           label(2 "Control")) ///
    note("Dotted line = 1954 Security Clearance Revocation")

graph export "Output/trends_treated_vs_control_inc3.png", replace
restore

********************************************************************************
* STEP 2: Real DiD regression
********************************************************************************

xtreg pub_count i.post3##i.treated i.year, fe vce(robust)
estimates store did_main_inc3

********************************************************************************
* STEP 3: Parallel trends test
********************************************************************************

* Test whether pre-treatment trends differ between treated and control
* Restrict to pre-treatment period only
xtreg pub_count i.year##i.treated if year < 1954, fe vce(robust)
estimates store parallel_trends_inc3

* Simple pre-trend test: interaction of treated with a linear time trend
gen pre_trend3 = treated * (year - 1950) if year < 1954
xtreg pub_count pre_trend3 i.year if year < 1954, fe vce(robust)

log close
