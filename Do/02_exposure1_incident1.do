********************************************************************************
* ECON 580 Honors Tutorials
* Author: Yiqing Zhang
* Date: February 2026
* File: 02_exposure1_incident1.do
* Purpose: DiD analysis - Exposure 1, Incident 1 (Manhattan Project 1942)
********************************************************************************

capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/02_exposure1_incident1.log", replace
use "Data/master_panel.dta", clear

********************************************************************************
* STEP 1: Plot treated vs control trends
********************************************************************************

preserve
collapse (mean) pub_count, by(year treated)

twoway ///
    (line pub_count year if treated == 1, lcolor(blue) lwidth(medium)) ///
    (line pub_count year if treated == 0, lcolor(red) lwidth(medium) lpattern(dash)), ///
    xline(1942, lcolor(black) lpattern(dot)) ///
    xlabel(1931(5)1960) ///
    title("Average Publications: Treated vs Control") ///
    xtitle("Year") ///
    ytitle("Mean Publication Count") ///
    legend(label(1 "Treated (Oppenheimer network)") ///
           label(2 "Control")) ///
    note("Dotted line = 1942 Manhattan Project")

graph export "Output/trends_treated_vs_control.png", replace
restore

********************************************************************************
* STEP 2: Real DiD regression
********************************************************************************

xtreg pub_count i.post##i.treated i.year, fe vce(robust)
estimates store did_main

********************************************************************************
* STEP 3: Parallel trends test
********************************************************************************

* Test whether pre-treatment trends differ between treated and control
* Restrict to pre-treatment period only
xtreg pub_count i.year##i.treated if year < 1942, fe vce(robust)
estimates store parallel_trends

* Simple pre-trend test: interaction of treated with a linear time trend
gen pre_trend = treated * (year - 1931) if year < 1942
xtreg pub_count pre_trend i.year if year < 1942, fe vce(robust)

********************************************************************************
* STEP 4: Poisson regression (robustness check)
********************************************************************************

* Fixed effects Poisson DiD
xtpoisson pub_count i.post##i.treated i.year, fe vce(robust)
estimates store did_poisson

* Test for overdispersion
* If alpha is significant, use negative binomial instead
xtnbreg pub_count i.post##i.treated i.year, fe
estimates store did_nbreg

log close
