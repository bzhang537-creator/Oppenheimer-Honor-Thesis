********************************************************************************
* ECON 580 Honors Thesis
* Author: Yiqing Zhang
* Date: March 2026
* File: 08_combined_results_tables.do
* Purpose: Compile all DiD results into combined LaTeX tables
********************************************************************************
capture log close
cd "/Users/serendipity/Study abroad/Oppenheimer"
log using "Log/09_combined_results_tables.log", replace
********************************************************************************
* STEP 1: Run all do-files to reload estimates
********************************************************************************
do "Do/02_exposure1_incident1_v2.do"
do "Do/03_exposure1_incident2_v2.do"
do "Do/04_exposure1_incident3_v2.do"
do "Do/05_exposure2_incident1.do"
do "Do/06_exposure2_incident2.do"
do "Do/07_exposure2_incident3.do"
********************************************************************************
* STEP 2: Table 1 - Exposure = 1 results
********************************************************************************
esttab e1_inc1_did e1_inc2_did e1_inc3_did ///
    using "Output/table1_exposure1.tex", ///
    replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Table 1: Exposure = 1 — Direct Oppenheimer Co-authors") ///
    mtitles("Incident 1 (1942)" "Incident 2 (1949)" "Incident 3 (1954)") ///
    keep(1.post1#1.treated 1.post2#1.treated 1.post3#1.treated) ///
    varlabels(1.post1#1.treated "Post × Treated" ///
              1.post2#1.treated "Post × Treated" ///
              1.post3#1.treated "Post × Treated") ///
    stats(N r2_w, labels("Observations" "R-sq (within)") fmt(%9.0f %9.3f)) ///
    label
********************************************************************************
* STEP 3: Table 2 - Exposure = 2 results (with robustness for Incident 3)
********************************************************************************
esttab e2_inc1_did e2_inc2_did e2_inc3_did e2_inc3_did_robust ///
    using "Output/table2_exposure2.tex", ///
    replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Table 2: Exposure = 2 — Co-authors of Co-authors") ///
    mtitles("Incident 1 (1942)" "Incident 2 (1949)" "Incident 3 (1954)" "Incident 3 (Robustness)") ///
    keep(1.post1#1.treated 1.post2#1.treated 1.post3#1.treated) ///
    varlabels(1.post1#1.treated "Post × Treated" ///
              1.post2#1.treated "Post × Treated" ///
              1.post3#1.treated "Post × Treated") ///
    stats(N r2_w, labels("Observations" "R-sq (within)") fmt(%9.0f %9.3f)) ///
    addnotes("Fixed effects: individual and year." ///
             "Robust standard errors in parentheses." ///
             "Robustness column drops Seitz, Shockley, and Townes (career transitions unrelated to Oppenheimer).") ///
    label
********************************************************************************
* STEP 4: Table 3 - Cross-exposure comparison
********************************************************************************
esttab e1_inc1_did e2_inc1_did e1_inc2_did e2_inc2_did e1_inc3_did e2_inc3_did e2_inc3_did_robust ///
    using "Output/table3_comparison.tex", ///
    replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Table 3: Network Attenuation — Exposure = 1 vs Exposure = 2") ///
    mtitles("E1: Inc 1" "E2: Inc 1" "E1: Inc 2" "E2: Inc 2" "E1: Inc 3" "E2: Inc 3" "E2: Inc 3 (Rob.)") ///
    keep(1.post1#1.treated 1.post2#1.treated 1.post3#1.treated) ///
    varlabels(1.post1#1.treated "Post × Treated" ///
              1.post2#1.treated "Post × Treated" ///
              1.post3#1.treated "Post × Treated") ///
    stats(N r2_w, labels("Observations" "R-sq (within)") fmt(%9.0f %9.3f)) ///
    addnotes("Fixed effects: individual and year." ///
             "Robust standard errors clustered by individual in parentheses." ///
             "Exposure = 1: direct Oppenheimer co-authors. Exposure = 2: co-authors of co-authors." ///
             "Robustness column drops Seitz, Shockley, and Townes (career transitions unrelated to Oppenheimer).") ///
    label
