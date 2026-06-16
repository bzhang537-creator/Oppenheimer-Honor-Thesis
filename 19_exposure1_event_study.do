********************************************************************************
* ECON 580 Honors Thesis
* Author: Yiqing Zhang
* Date: July 2026
* File: 19_exposure1_event_study.do
* Purpose: Unified event study - Exposure 1, all three incidents (1942/1949/1954)
*          Single DGP across 1931-1960; replaces three separate 2x2 DiDs
* Note: Requires coefplot (one-time: ssc install coefplot, replace)
********************************************************************************
capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/19_exposure1_event_study.log", replace
use "Data/master_panel_v2.dta", clear
keep if year >= 1931 & year <= 1960
********************************************************************************
* STEP 0: Cumulative treatment indicators (five periods)
*   pre-1942 | 1942-45 | 1946-48 | 1949-53 | 1954-60
*   Each indicator is an INCREMENTAL shift; period level = running sum
********************************************************************************
gen post42 = (year >= 1942)
gen post46 = (year >= 1946)
gen post49 = (year >= 1949)
gen post54 = (year >= 1954)
********************************************************************************
* STEP 1: Cumulative-shift specification (parsimonious headline)
********************************************************************************
xtreg pub_count i.year ///
    c.treated#c.post42 c.treated#c.post46 ///
    c.treated#c.post49 c.treated#c.post54, ///
    fe vce(robust)
estimates store e1_event_cum
* Period LEVEL effects (running sums) - stored so they export to table
lincom c.treated#c.post42
estadd scalar lvl_4245 = r(estimate)
estadd scalar se_4245  = r(se)

lincom c.treated#c.post42 + c.treated#c.post46
estadd scalar lvl_4648 = r(estimate)
estadd scalar se_4648  = r(se)

lincom c.treated#c.post42 + c.treated#c.post46 + c.treated#c.post49
estadd scalar lvl_4953 = r(estimate)
estadd scalar se_4953  = r(se)

lincom c.treated#c.post42 + c.treated#c.post46 + ///
       c.treated#c.post49 + c.treated#c.post54
estadd scalar lvl_5460 = r(estimate)
estadd scalar se_5460  = r(se)
********************************************************************************
* STEP 2: Fully flexible event study (1941 = base year)
*   Pre-1942 coefficients = pre-trend test; post = dynamic path
* Use 1941 as base year
********************************************************************************
xtreg pub_count ib1941.year ib1941.year#i.treated, fe vce(robust) 
estimates store e1_event_flex
* Joint pre-trend test: all pre-1942 interactions = 0
* (testparm does NOT accept an if-qualifier; name the pre-period terms)
testparm 1931.year#1.treated 1932.year#1.treated 1933.year#1.treated ///
         1934.year#1.treated 1935.year#1.treated 1936.year#1.treated ///
         1937.year#1.treated 1938.year#1.treated 1939.year#1.treated ///
         1940.year#1.treated
********************************************************************************
* STEP 3: Event-study plot (vertical markers at 1942, 1946, 1949, 1954)
*   Positions: 1931=1, so 1942=12, 1946=16, 1949=19, 1954=24
********************************************************************************
coefplot e1_event_flex, ///
    keep(*.year#1.treated) vertical ///
    yline(0, lcolor(black) lpattern(dash)) ///
    xline(12 16 19 24, lcolor(black) lpattern(dot)) ///
    ytitle("Effect on Publication Count") ///
    xtitle("Year") ///
    title("Exposure = 1: Unified Event Study (1931-1960)") ///
    note("Dotted lines = 1942, 1946, 1949, 1954; base year = 1941") ///
    ciopts(recast(rcap)) ///
    coeflabels(, notick) ///
    xlabel(1 "1931" 6 "1936" 12 "1942" 16 "1946" 19 "1949" 24 "1954" 30 "1960", angle(0))
graph export "Output/e1_event_study.png", replace
********************************************************************************
* STEP 4: Save results
*   Table A: raw incremental coefficients (both specifications)
*   Table B: cumulative LEVEL effects per period (from Step 1 lincom)
********************************************************************************
esttab e1_event_cum e1_event_flex using "Output/e1_event_results.tex", ///
    replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Exposure 1: Unified Event Study (1942/1946/1949/1954)") ///
    mtitles("Cumulative" "Flexible") ///
    keep(c.treated#c.post42 c.treated#c.post46 ///
         c.treated#c.post49 c.treated#c.post54) ///
    label

esttab e1_event_cum using "Output/e1_event_levels.tex", ///
    replace cells(none) ///
    stats(lvl_4245 se_4245 lvl_4648 se_4648 ///
          lvl_4953 se_4953 lvl_5460 se_5460, ///
          fmt(3) ///
          labels("1942-45 level" "  (se)" "1946-48 level" "  (se)" ///
                 "1949-53 level" "  (se)" "1954-60 level" "  (se)")) ///
    title("Exposure 1: Cumulative Level Effects by Period")
log close
