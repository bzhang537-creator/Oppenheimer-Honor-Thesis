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
* STEP 2: FE-Poisson flexible event study
*   Pre-1942 coefficients = pre-trend test on the PROPORTIONAL scale.
*   KEY DIAGNOSTIC: if the late-1930s pre-trend flattens here relative to
*   the linear plot, the linear "violation" was a level-scale artifact.
*   Note: Poisson drops never-positive panels; some early years may be
*   absorbed. Check the term list with -estimates replay- before testparm.
********************************************************************************
ppmlhdfe pub_count ib1941.year ib1941.year#i.treated, ///
    absorb(id) vce(cluster id)
estimates store e1_pois_flex
* Joint pre-trend test (drop any term Poisson omitted; check replay first)
testparm 1931.year#1.treated 1932.year#1.treated 1933.year#1.treated ///
         1934.year#1.treated 1935.year#1.treated 1936.year#1.treated ///
         1937.year#1.treated 1938.year#1.treated 1939.year#1.treated ///
         1940.year#1.treated
********************************************************************************
* STEP 3: Overlay plot - linear vs Poisson flexible event study
*   Poisson coefs are on the log scale; this overlays SHAPES, not levels.
*   Re-estimate linear here so both are in memory for coefplot.
********************************************************************************
xtreg pub_count ib1941.year ib1941.year#i.treated, fe vce(robust)
estimates store e1_lin_flex
coefplot e1_pois_flex, ///
    keep(*.year#1.treated) vertical ///
    yline(0, lcolor(black) lpattern(dash)) ///
    xline(12 16 19 24, lcolor(black) lpattern(dot)) ///
    ytitle("Log effect on publication rate") ///
    xtitle("Year") ///
    title("Exposure = 1: FE-Poisson Event Study (1931-1960)") ///
    note("Proportional (log) scale; dotted lines = 1942, 1946, 1949, 1954; base = 1941") ///
    ciopts(recast(rcap)) ///
    coeflabels(, notick) ///
    xlabel(1 "1931" 6 "1936" 12 "1942" 16 "1946" 19 "1949" 24 "1954" 30 "1960", angle(0))
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
