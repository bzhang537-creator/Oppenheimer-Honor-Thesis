********************************************************************************
* File: 15_summary_figure.do
* Purpose: Mean publication counts by treatment group, 1931-1960
********************************************************************************

capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/15_summary_figure.log", replace

use "Data/master_panel_v2.dta", clear
collapse (mean) pub_count, by(year treated)

tempfile e1_treated e1_control
preserve
    keep if treated == 1
    rename pub_count e1_treated
    keep year e1_treated
    save `e1_treated'
restore
preserve
    keep if treated == 0
    rename pub_count control
    keep year control
    save `e1_control'
restore

use "Data/exposure2_panel.dta", clear
collapse (mean) pub_count, by(year treated)
keep if treated == 1
rename pub_count e2_treated
keep year e2_treated
tempfile e2_treated
save `e2_treated'

use "Data/exposure3_panel.dta", clear
collapse (mean) pub_count, by(year treated)
keep if treated == 1
rename pub_count e3_treated
keep year e3_treated
tempfile e3_treated
save `e3_treated'

use `e1_control', clear
merge 1:1 year using `e1_treated', nogen
merge 1:1 year using `e2_treated', nogen
merge 1:1 year using `e3_treated', nogen

twoway ///
    (line e1_treated year, lcolor(navy) lwidth(medthick) lpattern(solid)) ///
    (line e2_treated year, lcolor(cranberry) lwidth(medium) lpattern(dash)) ///
    (line e3_treated year, lcolor(dkgreen) lwidth(medium) lpattern(longdash)) ///
    (line control year, lcolor(gs10) lwidth(medium) lpattern(dot)), ///
    xline(1942, lcolor(gs6) lpattern(dot) lwidth(thin)) ///
    xline(1949, lcolor(gs6) lpattern(dot) lwidth(thin)) ///
    xline(1954, lcolor(gs6) lpattern(dot) lwidth(thin)) ///
    xlabel(1931(5)1960, labsize(small)) ///
	xscale(range(1931 1960)) ///
    ylabel(0(0.5)3, labsize(small)) ///
    xtitle("Year", size(small)) ///
    ytitle("Mean Publication Count", size(small)) ///
    title("Mean Annual Publication Counts by Treatment Group, 1931-1960", ///
          size(medsmall) margin(b=3)) ///
    legend(order(1 "Exposure = 1 (direct co-authors)" ///
                 2 "Exposure = 2 (co-authors of co-authors)" ///
                 3 "Exposure = 3 (IAS affiliates)" ///
                 4 "Control (solid-state/acoustics)") ///
           rows(2) size(vsmall) position(6) ring(1) ///
           region(lstyle(none))) ///
    note("Vertical dotted lines: 1942, 1949, 1954 shocks", size(vsmall)) ///
    graphregion(color(white)) ///
    plotregion(margin(l=2 r=2 t=2 b=2)) ///
    scheme(s2color)

graph export "Output/summary_figure.png", replace width(2400) height(1600)

log close
