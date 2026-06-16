********************************************************************************
* ECON 580 Honors Thesis
* Author: Yiqing Zhang
* Date: March 2026
* File: 03_exposure1_incident2_v2.do
* Purpose: DiD - Exposure 1, Incident 2 (Soviet Bomb Test 1949)
********************************************************************************

capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/03_exposure1_incident2_v2.log", replace
use "Data/master_panel_v2.dta", clear

* Restrict to post-Incident 1 window
keep if year >= 1946 & year <= 1960

********************************************************************************
* STEP 1: Plot
********************************************************************************

preserve
collapse (mean) pub_count, by(year treated)

twoway ///
    (line pub_count year if treated == 1, lcolor(blue) lwidth(medium)) ///
    (line pub_count year if treated == 0, lcolor(red) lwidth(medium) lpattern(dash)), ///
    xline(1949, lcolor(black) lpattern(dot)) ///
    xlabel(1946(2)1960) ///
    title("Exposure = 1, Incident 2: Soviet Bomb Test (1949)") ///
    xtitle("Year") ///
    ytitle("Mean Publication Count") ///
    legend(label(1 "Treated") label(2 "Control")) ///
    note("Dotted line = 1949")

graph export "Output/e1_inc2_trends_v2.png", replace
restore

********************************************************************************
* STEP 2: DiD
********************************************************************************

xtreg pub_count i.post2##i.treated i.year, fe vce(robust)
estimates store e1_inc2_did

********************************************************************************
* STEP 3: Parallel trends
********************************************************************************

* Full pre-period (1946-1948)
xtreg pub_count i.year##i.treated if year < 1949, fe vce(robust)
estimates store e1_inc2_pt
testparm i.year#1.treated

* Linear pre-trend test (secondary check)
gen pre_trend2 = treated * (year - 1946) if year < 1949
xtreg pub_count pre_trend2 i.year if year < 1949, fe vce(robust)
capture drop pre_trend2

********************************************************************************
* STEP 4: Save results
********************************************************************************

esttab e1_inc2_did e1_inc2_pt using "Output/e1_inc2_results.tex", ///
    replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Exposure 1, Incident 2: Soviet Atomic Bomb (1949)") ///
    mtitles("DiD" "Parallel Trends") ///
    keep(1.post2#1.treated) ///
    label

log close
