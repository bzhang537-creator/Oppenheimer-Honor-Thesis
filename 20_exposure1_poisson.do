********************************************************************************
* ECON 580 Honors Thesis
* Author: Yiqing Zhang
* Date: July 2026
* File: 20_exposure1_poisson.do
* Purpose: FE-Poisson robustness for unified event study (Exposure 1)
*          Proportional-effects check on the linear results in 19_*.do
*          Tests whether (a) the late-1930s pre-trend is a level-scale
*          artifact and (b) the post-1949 plateau is mechanical under a
*          multiplicative model.
* Note: Robustness only. Linear event study (19_*.do) remains the headline,
*       consistent with Angrist & Pischke. Poisson precedent = Azoulay,
*       Graff Zivin & Wang (2010), not MHE.
* Requires: ppmlhdfe (one-time: ssc install ppmlhdfe, replace)
*           coefplot, estout (already installed for 19_*.do)
********************************************************************************
capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/20_exposure1_poisson.log", replace
use "Data/master_panel_v2.dta", clear
keep if year >= 1931 & year <= 1960
********************************************************************************
* STEP 0: Cumulative treatment indicators (same as 19_*.do)
********************************************************************************
gen post42 = (year >= 1942)
gen post46 = (year >= 1946)
gen post49 = (year >= 1949)
gen post54 = (year >= 1954)
********************************************************************************
* STEP 1: FE-Poisson cumulative-shift specification
*   Coefficients are SEMI-ELASTICITIES: exp(b)-1 = proportional change in
*   the publication RATE. These are NOT directly comparable to the linear
*   level coefficients in 19_*.do; compare signs, significance, and the
*   recovery/plateau PATTERN, not magnitudes.
********************************************************************************
ppmlhdfe pub_count ///
    c.treated#c.post42 c.treated#c.post46 ///
    c.treated#c.post49 c.treated#c.post54, ///
    absorb(id year) vce(cluster id)
estimates store e1_pois_cum
* Cumulative (running-sum) semi-elasticities + % interpretation
lincom c.treated#c.post42, eform
lincom c.treated#c.post42 + c.treated#c.post46, eform
lincom c.treated#c.post42 + c.treated#c.post46 + c.treated#c.post49, eform
lincom c.treated#c.post42 + c.treated#c.post46 + ///
       c.treated#c.post49 + c.treated#c.post54, eform
*   (eform reports exp(b): 0.60 means rate multiplied by 0.60 = 40% drop)
********************************************************************************
* STEP 2: FE-Poisson flexible event study  -- CORRECTED (1941 base)
*   Manual tr* dummies, 1941 omitted by construction, so Stata cannot
*   reassign the base via collinearity handling (same fix as 19_*.do).
*   Pre-1942 coefficients = pre-trend test on the PROPORTIONAL scale.
*   KEY DIAGNOSTIC: if the late-1930s pre-trend flattens here relative to
*   the linear plot, the linear "violation" was a level-scale artifact.
*   Note: Poisson drops never-positive panels; some early years may be
*   absorbed by separation. Check -estimates replay- before testparm.
********************************************************************************
forvalues y = 1931/1960 {
    if `y' != 1941 {
        capture drop tr`y'
        gen tr`y' = treated * (year == `y')
    }
}
ppmlhdfe pub_count tr1931-tr1940 tr1942-tr1960, ///
    absorb(id year) vce(cluster id)
estimates store e1_pois_flex
* Joint pre-trend test (drop any term Poisson omitted by separation;
* check the replayed term list first and delete missing years from below)
testparm tr1931 tr1932 tr1933 tr1934 tr1935 tr1936 tr1937 tr1938 tr1939 tr1940
********************************************************************************
* STEP 3: Overlay plot - linear vs Poisson flexible event study
*   Poisson coefs are on the log scale; this overlays SHAPES, not levels.
*   Re-estimate linear here so both are in memory for coefplot.
*   Positions (1941 not plotted): 1931=1...1940=10, 1942=11, 1946=15,
*   1949=18, 1954=23, 1960=29
********************************************************************************
xtreg pub_count i.year tr1931-tr1940 tr1942-tr1960, fe vce(robust)
estimates store e1_lin_flex
coefplot e1_pois_flex, ///
    keep(tr*) vertical ///
    rename(^tr([0-9]+)$ = \1, regex) ///
    yline(0, lcolor(black) lpattern(dash)) ///
    xline(11 15 18 23, lcolor(black) lpattern(dash)) ///
    ytitle("Log effect on publication rate") ///
    xtitle("Year") ///
    title("Exposure = 1: FE-Poisson Event Study (1931-1960)") ///
    note("Dashed lines = 1942, 1946, 1949, 1954; base = 1941") ///
    ciopts(recast(rcap)) ///
    xlabel(, angle(90) labsize(vsmall))

graph export "Output/e1_poisson_event_study.png", replace
********************************************************************************
* STEP 4: Save results
********************************************************************************
esttab e1_pois_cum using "Output/e1_poisson_results.tex", ///
    replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) eform ///
    title("Exposure 1: FE-Poisson Robustness (exp(b) = rate ratios)") ///
    mtitles("FE-Poisson") ///
    keep(c.treated#c.post42 c.treated#c.post46 ///
         c.treated#c.post49 c.treated#c.post54) ///
    label
log close
