********************************************************************************
* ECON 580 Honors Thesis
* Author: Yiqing Zhang
* Date: March 2026
* File: 02_exposure1_incident1_v2.do
* Purpose: DiD analysis - Exposure 1, Incident 1 (Manhattan Project 1942)
*          Using updated PROLA data and new control group
********************************************************************************

capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/02_exposure1_incident1_v2.log", replace
use "Data/master_panel_v2.dta", clear

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
    title("Exposure = 1, Incident 1: Manhattan Project (1942)") ///
    xtitle("Year") ///
    ytitle("Mean Publication Count") ///
    legend(label(1 "Treated (Oppenheimer)") ///
           label(2 "Control (solid-state/other)")) ///
    note("Dotted line = 1942")

graph export "Output/e1_inc1_trends_v2.png", replace
restore

********************************************************************************
* STEP 2: DiD regression
********************************************************************************

xtreg pub_count i.post1##i.treated i.year, fe vce(robust)
estimates store e1_inc1_did

********************************************************************************
* STEP 3: Parallel trends test
********************************************************************************

* Full pre-period (1931-1941)
xtreg pub_count i.year##i.treated if year < 1942, fe vce(robust)
estimates store e1_inc1_pt_full
testparm i.year#1.treated

* Restricted pre-period (1938-1941)
xtreg pub_count i.year##i.treated if year >= 1938 & year < 1942, fe vce(robust)
estimates store e1_inc1_pt
testparm i.year#1.treated

* Linear pre-trend test (secondary check, restricted window)
gen pre_trend1 = treated * (year - 1938) if year >= 1938 & year < 1942
xtreg pub_count pre_trend1 i.year if year >= 1938 & year < 1942, fe vce(robust)
capture drop pre_trend1

********************************************************************************
* STEP 4: Save results
********************************************************************************

esttab e1_inc1_did e1_inc1_pt using "Output/e1_inc1_results.tex", ///
    replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Exposure 1, Incident 1: Manhattan Project (1942)") ///
    mtitles("DiD" "Parallel Trends") ///
    keep(1.post1#1.treated) ///
    label

log close
