********************************************************************************
* ECON 580 Honors Thesis
* Author: Yiqing Zhang
* Date: June 2026
* File: 21_exposure1_stop_publishing.do
* Purpose: Mechanism decomposition for Exposure 1 via the dependent variable.
*          Separates INCAPACITATION (temporary dip, recovers, no permanent
*          exit) from CHILLING (permanent exit, elevated after 1949/1954)
*          by changing the OUTCOME, not the design. Same unified event study
*          as 19_*.do.
*
*   Three outcomes:
*     (A) anypub   - extensive margin, annual: published at all this year?
*                    LPM (OLS on 0/1) -> coef = pp change in P(publish).
*                    Recovers if incapacitation; persists if chilling.
*     (B) stopped  - ABSORBING exit: =1 from a physicist's last-ever paper
*                    onward. Tests whether shocks ENDED careers (chilling),
*                    not just produced quiet years (incapacitation).
*     (C) pub_count | pubs>0 - intensive margin, counts among publishers.
*                    DESCRIPTIVE ONLY: selects on a post-treatment outcome
*                    (MHE 3.2.3 bad control). Not a causal object.
*
*   Causal objects: count effect (19_*.do), (A), and (B).
*   (C) is descriptive decomposition only.
********************************************************************************
capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/21_exposure1_stop_publishing.log", replace
use "Data/master_panel_v2.dta", clear
keep if year >= 1931 & year <= 1960
xtset id year
********************************************************************************
* STEP 0: Cumulative treatment indicators (same as 19_*.do)
********************************************************************************
gen post42 = (year >= 1942)
gen post46 = (year >= 1946)
gen post49 = (year >= 1949)
gen post54 = (year >= 1954)
********************************************************************************
* STEP 1: Build the three outcomes
********************************************************************************
* (A) Extensive margin, annual: 1 if any publication this year
gen anypub = (pub_count > 0)

* (B) Absorbing stop-publishing indicator.
*   Logic: sum publications from each physicist's LAST year backward.
*   cumfuture = total papers in year t AND all later years. Once that
*   running-from-the-end total hits 0, the physician has published their
*   last-ever paper, so stopped=1 from that point to 1960. This makes exit
*   an ABSORBING state (once stopped, stays stopped), which is what
*   distinguishes a permanent career end from a one-off quiet year.
gsort id -year
by id: gen cumfuture = sum(pub_count)
gsort id year
gen stopped = (cumfuture == 0)
*   Sanity check: stopped should be weakly increasing within id (0...0,1...1)
*   and never revert. Spot-check a few physicists if unsure:
*   list id year pub_count cumfuture stopped if id <= 2, sepby(id)

* (C) Intensive margin handled inline via -if pub_count > 0- (no new var)
********************************************************************************
* STEP 2: (A) Extensive margin - annual P(publish), LPM with FE
*   Cumulative-shift specification (matches 19_*.do headline form)
********************************************************************************
xtreg anypub i.year ///
    c.treated#c.post42 c.treated#c.post46 ///
    c.treated#c.post49 c.treated#c.post54, ///
    fe vce(robust)
estimates store e1_anypub_cum
* Period LEVEL effects (pp changes in P(publish)) - stored for export
lincom c.treated#c.post42
estadd scalar a_4245 = r(estimate)
estadd scalar a_se42 = r(se)
lincom c.treated#c.post42 + c.treated#c.post46
estadd scalar a_4648 = r(estimate)
estadd scalar a_se46 = r(se)
lincom c.treated#c.post42 + c.treated#c.post46 + c.treated#c.post49
estadd scalar a_4953 = r(estimate)
estadd scalar a_se49 = r(se)
lincom c.treated#c.post42 + c.treated#c.post46 + ///
       c.treated#c.post49 + c.treated#c.post54
estadd scalar a_5460 = r(estimate)
estadd scalar a_se54 = r(se)
********************************************************************************
* STEP 3: (B) Absorbing exit - P(permanently stopped), LPM with FE
*   This is the cleanest chilling test: does exposure raise the probability
*   of having permanently exited publishing, rising after 1949/1954?
********************************************************************************
xtreg stopped i.year ///
    c.treated#c.post42 c.treated#c.post46 ///
    c.treated#c.post49 c.treated#c.post54, ///
    fe vce(robust)
estimates store e1_stopped_cum
lincom c.treated#c.post42
estadd scalar s_4245 = r(estimate)
estadd scalar s_se42 = r(se)
lincom c.treated#c.post42 + c.treated#c.post46
estadd scalar s_4648 = r(estimate)
estadd scalar s_se46 = r(se)
lincom c.treated#c.post42 + c.treated#c.post46 + c.treated#c.post49
estadd scalar s_4953 = r(estimate)
estadd scalar s_se49 = r(se)
lincom c.treated#c.post42 + c.treated#c.post46 + ///
       c.treated#c.post49 + c.treated#c.post54
estadd scalar s_5460 = r(estimate)
estadd scalar s_se54 = r(se)
********************************************************************************
* STEP 4: (C) Intensive margin - counts CONDITIONAL on publishing
*   DESCRIPTIVE ONLY (bad control: conditions on post-treatment pub_count>0).
*   If (C) is small while (A)/(B) are large, suppression works on the
*   extensive margin (going silent) rather than the intensive margin
*   (slowing down) - which points to chilling over incapacitation.
********************************************************************************
xtreg pub_count i.year ///
    c.treated#c.post42 c.treated#c.post46 ///
    c.treated#c.post49 c.treated#c.post54 if pub_count > 0, ///
    fe vce(robust)
estimates store e1_intensive_cum
********************************************************************************
* STEP 5: Flexible event study for the absorbing-exit outcome
*   Visual analogue of the 19_*.do plot, for the stop-publishing margin.
********************************************************************************
xtreg stopped ib1941.year ib1941.year#i.treated, fe vce(robust)
estimates store e1_stopped_flex
coefplot e1_stopped_flex, ///
    keep(*.year#1.treated) vertical ///
    yline(0, lcolor(black) lpattern(dash)) ///
    xline(12 16 19 24, lcolor(black) lpattern(dot)) ///
    ytitle("Effect on P(permanently stopped)") ///
    xtitle("Year") ///
    title("Exposure = 1: Stop-Publishing Event Study (1931-1960)") ///
    note("Dotted lines = 1942, 1946, 1949, 1954; base year = 1941") ///
    ciopts(recast(rcap)) ///
    coeflabels(, notick) ///
    xlabel(1 "1931" 6 "1936" 12 "1942" 16 "1946" 19 "1949" 24 "1954" 30 "1960", angle(0))
graph export "Output/e1_stopped_event_study.png", replace
********************************************************************************
* STEP 6: Save results
*   Table 1: three cumulative-shift specifications side by side
*   Table 2: cumulative LEVEL effects for the two causal margins (A) and (B)
********************************************************************************
esttab e1_anypub_cum e1_stopped_cum e1_intensive_cum ///
    using "Output/e1_margins_results.tex", ///
    replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Exposure 1: Extensive vs Intensive Margins") ///
    mtitles("P(publish)" "P(stopped)" "Count|pub>0") ///
    keep(c.treated#c.post42 c.treated#c.post46 ///
         c.treated#c.post49 c.treated#c.post54) ///
    label ///
    addnotes("Col 3 (intensive) is descriptive: conditions on post-treatment outcome.")

esttab e1_anypub_cum e1_stopped_cum using "Output/e1_margins_levels.tex", ///
    replace cells(none) ///
    stats(a_4245 a_4648 a_4953 a_5460 s_4245 s_4648 s_4953 s_5460, ///
          fmt(3) ///
          labels("P(pub) 1942-45" "P(pub) 1946-48" "P(pub) 1949-53" "P(pub) 1954-60" ///
                 "P(stop) 1942-45" "P(stop) 1946-48" "P(stop) 1949-53" "P(stop) 1954-60")) ///
    title("Exposure 1: Cumulative Level Effects, Extensive Margins")
log close
