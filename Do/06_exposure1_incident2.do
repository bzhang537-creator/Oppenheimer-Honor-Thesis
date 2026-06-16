********************************************************************************
* ECON 580 Honors Tutorials
* Author: Yiqing Zhang
* Date: February 2026
* File: 06_exposure1_incident2.do
* Purpose: DiD analysis - Exposure 1, Incident 2 (Soviet Atomic Bomb 1949)
********************************************************************************

capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/06_exposure1_incident2.log", replace
use "Data/master_panel.dta", clear

* Restrict to sample window around Incident 2
* Pre-period: 1946-1948 (post-WWII, pre-Soviet bomb)
* Post-period: 1949-1958
keep if year >= 1946 & year <= 1958

* Generate post indicator for Incident 2
gen post2 = (year >= 1949)

********************************************************************************
* STEP 1: Plot treated vs control trends
********************************************************************************

preserve
collapse (mean) pub_count, by(year treated)

twoway ///
    (line pub_count year if treated == 1, lcolor(blue) lwidth(medium)) ///
    (line pub_count year if treated == 0, lcolor(red) lwidth(medium) lpattern(dash)), ///
    xline(1949, lcolor(black) lpattern(dot)) ///
    xlabel(1946(2)1958) ///
    title("Average Publications: Treated vs Control") ///
    xtitle("Year") ///
    ytitle("Mean Publication Count") ///
    legend(label(1 "Treated (Oppenheimer network)") ///
           label(2 "Control")) ///
    note("Dotted line = 1949 Soviet Atomic Bomb")

graph export "Output/trends_treated_vs_control_inc2.png", replace
restore

********************************************************************************
* STEP 2: Real DiD regression
********************************************************************************

xtreg pub_count i.post2##i.treated i.year, fe vce(robust)
estimates store did_main_inc2

********************************************************************************
* STEP 3: Parallel trends test
********************************************************************************

* Test whether pre-treatment trends differ between treated and control
* Restrict to pre-treatment period only
xtreg pub_count i.year##i.treated if year < 1949, fe vce(robust)
estimates store parallel_trends_inc2

* Simple pre-trend test: interaction of treated with a linear time trend
gen pre_trend2 = treated * (year - 1946) if year < 1949
xtreg pub_count pre_trend2 i.year if year < 1949, fe vce(robust)

log close
