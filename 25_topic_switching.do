********************************************************************************
* 25_topic_switching.do
* Political Shocks and Scientific Network Productivity:
* Evidence from the Oppenheimer Affair
*
* Purpose : Mechanism test for the research-skepticism (chilling) channel:
*           did treated physicists move AWAY from nuclear/politically
*           sensitive topics? Precedent: Borjas & Doran (2012, QJE) field
*           reallocation of American mathematicians.
*
* Design  : Decompose the UNCONDITIONAL annual count:
*               pub_count = pub_nuclear + pub_other
*           and run the unified event study on each piece. Both outcomes are
*           unconditional (zero in non-publishing years), so this avoids the
*           MHE 3.2.3 bad-control problem that a "share of nuclear papers
*           among published papers" outcome would create.
*           Chilling prediction: delta path for pub_nuclear is deeper and
*           non-recovering; pub_other path is flatter (or even positive if
*           physicists substituted toward safe topics).
*
* STATUS  : Runs once paper-level title data are classified. Requires a
*           paper-level file (one row per paper) with: name, year, title.
* Author  : Yiqing Zhang
* Date    : July 2026
********************************************************************************

clear all
set more off
capture log close

global root   "/Users/serendipity/Study abroad/Oppenheimer"
global data   "$root/Data"
global output "$root/Output"
global log    "$root/Log"

log using "$log/25_topic_switching.log", replace

*-------------------------------------------------------------------------------
* Step 1: Classify papers by title keywords (paper-level file)
*-------------------------------------------------------------------------------
use "$data/papers_e1.dta", clear    // one row per paper: name, year, title

gen title_l = lower(title)

* Keyword dictionary -- nuclear / particle / politically sensitive topics.
* Refine after eyeballing 30-50 titles; this is a starting list, not final.
gen byte nuclear_topic = 0
foreach kw in "nuclear" "nucleus" "nuclei" "fission" "neutron" "proton" ///
              "meson" "deuteron" "uranium" "plutonium" "isotope" ///
              "radioactiv" "cosmic ray" "scattering of neutron" ///
              "chain reaction" "reactor" {
    replace nuclear_topic = 1 if strpos(title_l, "`kw'") > 0
}

* Manual verification sample: export 50 random titles per class for checking
preserve
    set seed 19310401
    sample 50, count by(nuclear_topic)
    export delimited name year title nuclear_topic ///
        using "$output/topic_classification_check.csv", replace
restore

*-------------------------------------------------------------------------------
* Step 2: Collapse to physicist-year counts and merge into the E1 panel
*-------------------------------------------------------------------------------
gen byte one = 1
collapse (sum) pub_nuclear = nuclear_topic (count) pub_total = one, ///
    by(name year)
gen pub_other = pub_total - pub_nuclear
tempfile topiccounts
save `topiccounts'

use "$data/master_panel_v2.dta", clear
merge 1:1 name year using `topiccounts', keep(master match) nogen
* Non-publishing years: zero in both components (unconditional outcome)
replace pub_nuclear = 0 if missing(pub_nuclear)
replace pub_other   = 0 if missing(pub_other)

* Consistency check: components must sum to the headline outcome
assert pub_nuclear + pub_other == pub_count

capture confirm numeric variable id
if _rc {
    egen id = group(name)
}
xtset id year

*-------------------------------------------------------------------------------
* Step 3: Unified event study on each component
*-------------------------------------------------------------------------------
gen post42T = (year >= 1942) * treated
gen post46T = (year >= 1946) * treated
gen post49T = (year >= 1949) * treated
gen post54T = (year >= 1954) * treated

eststo clear
foreach y in pub_nuclear pub_other pub_count {
    eststo es_`y': xtreg `y' post42T post46T post49T post54T i.year, ///
        fe vce(robust)

    lincom post42T
    estadd scalar lvl_4245 = r(estimate) : es_`y'
    lincom post42T + post46T
    estadd scalar lvl_4648 = r(estimate) : es_`y'
    lincom post42T + post46T + post49T
    estadd scalar lvl_4953 = r(estimate) : es_`y'
    lincom post42T + post46T + post49T + post54T
    estadd scalar lvl_5460 = r(estimate) : es_`y'
}

esttab es_pub_nuclear es_pub_other es_pub_count ///
    using "$output/table_topic_decomposition.tex", replace ///
    keep(post42T post46T post49T post54T) ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    scalars("lvl_4245 Level 1942-45" "lvl_4648 Level 1946-48" ///
            "lvl_4953 Level 1949-53" "lvl_5460 Level 1954-60") ///
    mtitles("Nuclear topics" "Other topics" "All (headline)") ///
    title("Topic decomposition of the publication effect (unconditional counts)") ///
    label booktabs

*-------------------------------------------------------------------------------
* Step 4: Overlaid flexible event studies (nuclear vs other)
*-------------------------------------------------------------------------------
forvalues y = 1931/1960 {
    if `y' != 1941 {
        gen tr`y' = treated * (year == `y')
    }
}

eststo flex_nuc:   xtreg pub_nuclear tr19* i.year, fe vce(robust)
eststo flex_other: xtreg pub_other   tr19* i.year, fe vce(robust)

coefplot (flex_nuc,   label("Nuclear topics") msymbol(O)) ///
         (flex_other, label("Other topics")   msymbol(D)), ///
    keep(tr19*) ///
    rename(^tr([0-9]+)$ = \1, regex) ///
    vertical omitted baselevels ///
    yline(0, lcolor(gs10)) ///
    xline(11.5, lpattern(dash) lcolor(red)) ///
    xline(15.5, lpattern(dash) lcolor(red)) ///
    xline(18.5, lpattern(dash) lcolor(red)) ///
    xline(23.5, lpattern(dash) lcolor(red)) ///
    xlabel(, angle(90) labsize(vsmall)) ///
    ciopts(recast(rcap)) ///
    title("Topic-split event studies, E1 (base 1941)") ///
    ytitle("Effect on annual publication count")
graph export "$output/fig_topic_split_eventstudy.png", replace width(2000)

log close
********************************************************************************
* WRITE-UP NOTES:
* 1. Keyword classification is noisy -- report the manual-verification rate
*    from the 100-title check before trusting the split.
* 2. Interpretation: pub_nuclear collapsing while pub_other holds up (or
*    rises) is the chilling signature; both collapsing equally is more
*    consistent with a general productivity shock (incapacitation/spillover).
* 3. Do NOT report share-of-nuclear-among-published as a causal outcome --
*    that conditions on publishing (MHE 3.2.3), same as margin (C).
********************************************************************************
