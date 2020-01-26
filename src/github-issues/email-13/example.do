use "test.dta", clear

local nq 10
bysort group (inc): gen w_cum=sum(w)
bysort group (inc): egen w_tot=sum(w)
gen cum_share=w_cum/w_tot

* Percentiles Manual
preserve
    gen dec=floor((w_cum/w_tot)*`nq')*(100/`nq')
    bysort group dec: egen min_dec=min(w_cum)
    gen dec_manual=inc if min_dec==w_cum

    * gen dec=ceil(cum_share * `nq') * (100/`nq')
    * bysort group dec (inc): gen dec_manual = inc[_N]

    keep if !missing(dec_manual)
    keep group dec dec_manual
    duplicates drop
    isid group dec
    save "dec_manual.dta", replace
restore

* Percentiles Stata
preserve
    levelsof group, local(group)
    foreach g of local group{
        pctile dec_stata`g'=inc [aw=w] if group==`g', nq(`nq') genp(dec`g')
    }
    keep if !missing(dec1)
    drop group
    reshape long dec_stata dec, i(cum_share) j(group)
    keep group dec dec_stata
    isid group dec
    save "dec_stata.dta", replace
restore

* Percentiles Gtools
preserve
    gquantiles dec_gtools=inc [aw=w], pctile cutby strict by(group) nq(`nq') genp(dec)
    keep if !missing(dec)
    keep group dec dec_gtools
    isid group dec
    save "dec_gtools.dta", replace
restore

* Merge for Comparison
use "dec_manual.dta", clear
merge 1:1 group dec using "dec_stata.dta",  keepusing(dec_stata) nogen
merge 1:1 group dec using "dec_gtools.dta", keepusing(dec_gtools) nogen

***********************************************************************
*                              Debugging                              *
***********************************************************************

* Narrowed the issue to this:
local nq = 10
sysuse auto, clear
    keep if foreign
    gen w = 1
    gquantiles g1=price [fw = 1], cutby pctile nq(`nq') by(foreign) strict
    gquantiles g2=price [fw = 1], cutby pctile nq(`nq') by(foreign) strict xtile(x1)

* g2 is correct but g1 is not. It turns out there was a bug in the code
* to read in the data with by() and weights when only pctile requested.
