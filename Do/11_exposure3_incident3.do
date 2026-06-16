********************************************************************************
* ECON 580 Honors Thesis
* Author: Yiqing Zhang
* Date: May 2026
* File: 11_exposure3_incident3.do
* Purpose: DiD robustness - Exposure 3, Incident 3 (Security Revocation 1954)
*          Drops Seitz, Shockley, Townes from control group
********************************************************************************

capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/18_exposure3_incident3_robustness.log", replace
use "Data/exposure3_panel.dta", clear
keep if year >= 1950 & year <= 1960

********************************************************************************
* STEP 1: Plot (baseline)
********************************************************************************

preserve
collapse (mean) pub_count, by(year treated)
twoway ///
    (line pub_count year if treated == 1, lcolor(blue) lwidth(medium)) ///
    (line pub_count year if treated == 0, lcolor(red) lwidth(medium) lpattern(dash)), ///
    xline(1954, lcolor(black) lpattern(dot)) ///
    xlabel(1950(2)1960) ///
    title("Exposure = 3, Incident 3: Security Revocation (1954)") ///
    xtitle("Year") ///
    ytitle("Mean Publication Count") ///
    legend(label(1 "Treated (IAS)") label(2 "Control")) ///
    note("Dotted line = 1954")
graph export "Output/e3_inc3_trends.png", replace
restore

********************************************************************************
* STEP 2: Plot (robustness - dropped controls)
********************************************************************************

preserve
keep if name != "Frederick Seitz" & name != "William Shockley" & name != "Charles Townes"
collapse (mean) pub_count, by(year treated)
twoway ///
    (line pub_count year if treated == 1, lcolor(blue) lwidth(medium)) ///
    (line pub_count year if treated == 0, lcolor(red) lwidth(medium) lpattern(dash)), ///
    xline(1954, lcolor(black) lpattern(dot)) ///
    xlabel(1950(2)1960) ///
    title("Exposure = 3, Incident 3: Robustness Check") ///
    xtitle("Year") ///
    ytitle("Mean Publication Count") ///
    legend(label(1 "Treated (IAS)") label(2 "Control")) ///
    note("Dotted line = 1954, Seitz/Shockley/Townes dropped")
graph export "Output/e3_inc3_trends_robustness.png", replace
restore

********************************************************************************
* STEP 3: DiD regression (baseline)
********************************************************************************

xtreg pub_count i.post3##i.treated i.year, fe vce(robust)
estimates store e3_inc3_did

********************************************************************************
* STEP 4: DiD regression (robustness - dropped controls)
********************************************************************************

xtreg pub_count i.post3##i.treated i.year ///
    if name != "Frederick Seitz" & name != "William Shockley" & name != "Charles Townes", ///
    fe vce(robust)
estimates store e3_inc3_did_robust

********************************************************************************
* STEP 5: Parallel trends test (baseline sample)
********************************************************************************

xtreg pub_count i.year##i.treated if year < 1954, fe vce(robust)
estimates store e3_inc3_pt
testparm i.year#1.treated

gen pre_trend3 = treated * (year - 1950) if year < 1954
xtreg pub_count pre_trend3 i.year if year < 1954, fe vce(robust)
capture drop pre_trend3

********************************************************************************
* STEP 6: Save results
********************************************************************************

esttab e3_inc3_did e3_inc3_did_robust using "Output/e3_inc3_robustness_results.tex", ///
    replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Exposure 3, Incident 3: Security Revocation (1954)") ///
    mtitles("DiD Baseline" "DiD Robustness") ///
    keep(1.post3#1.treated) ///
    label

log close
