********************************************************************************
* ECON 580 Honors Thesis
* Author: Yiqing Zhang
* Date: March 2026
* File: 05_exposure2_incident1.do
* Purpose: DiD - Exposure 2, Incident 1 (Manhattan Project 1942)
********************************************************************************

capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/05_exposure2_incident1.log", replace
use "Data/exposure2_panel.dta", clear

********************************************************************************
* STEP 1: Plot
********************************************************************************

preserve
collapse (mean) pub_count, by(year treated)

twoway ///
    (line pub_count year if treated == 1, lcolor(blue) lwidth(medium)) ///
    (line pub_count year if treated == 0, lcolor(red) lwidth(medium) lpattern(dash)), ///
    xline(1942, lcolor(black) lpattern(dot)) ///
    xlabel(1931(5)1960) ///
    title("Exposure = 2, Incident 1: Manhattan Project (1942)") ///
    xtitle("Year") ///
    ytitle("Mean Publication Count") ///
    legend(label(1 "Treated (co-authors of Exp=1)") ///
           label(2 "Control")) ///
    note("Dotted line = 1942")

graph export "Output/e2_inc1_trends.png", replace
restore

********************************************************************************
* STEP 2: DiD regression
********************************************************************************

xtreg pub_count i.post1##i.treated i.year, fe vce(robust)
estimates store e2_inc1_did

********************************************************************************
* STEP 3: Parallel trends test
********************************************************************************

xtreg pub_count i.year##i.treated if year < 1942, fe vce(robust)
estimates store e2_inc1_pt
testparm i.year#1.treated

gen pre_trend1 = treated * (year - 1931) if year < 1942
xtreg pub_count pre_trend1 i.year if year < 1942, fe vce(robust)
capture drop pre_trend1

********************************************************************************
* STEP 4: Save results
********************************************************************************

esttab e2_inc1_did e2_inc1_pt using "Output/e2_inc1_results.tex", ///
    replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Exposure 2, Incident 1: Manhattan Project (1942)") ///
    mtitles("DiD" "Parallel Trends") ///
    keep(1.post1#1.treated) ///
    label

log close
