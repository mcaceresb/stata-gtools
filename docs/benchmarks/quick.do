capture program drop bench
program bench
    gettoken timer call: 0,    p(:)
    gettoken colon call: call, p(:)
    cap timer clear `timer'
    timer on `timer'
    `call'
    timer off `timer'
    qui timer list
    c_local r`timer' `=r(t`timer')'
end

clear
set obs 10000000
gen groups = int(runiform() * 1000)
gen rsort  = rnormal()
gen rvar   = rnormal()
gen ix     = _n
sort rsort

timer clear

preserve
bench 11: gcollapse (sum) rvar (mean) mean = rvar, by(groups)
restore, preserve
bench 10: collapse (sum) rvar (mean) mean = rvar, by(groups)
restore

preserve
bench 16: gcollapse (sd) sd = rvar (median) med = rvar, by(groups)
restore, preserve
bench 15: collapse (sd) sd = rvar (median) med = rvar, by(groups)
restore

preserve
bench 21: greshape long r, i(ix) j(j) string
bench 26: greshape wide r, i(ix) j(j) string
restore, preserve
bench 20: reshape long r, i(ix) j(j) string
bench 25: reshape wide r, i(ix) j(j) string
restore

bench 31: gquantiles g_xtile = rvar, nq(10) xtile
bench 30: xtile s_xtile = rvar, nq(10)

bench 36: gquantiles g_pctile = rvar, nq(10) pctile
bench 35: pctile s_pctile = rvar, nq(10)

bench 41: gegen g_id = group(groups)
bench 40: egen  s_id = group(groups)

preserve
bench 46: gcontract groups
restore, preserve
bench 45: contract groups
restore

bench 51: gisid ix
bench 50: isid ix

preserve
bench 56: gduplicates drop groups, force
restore, preserve
bench 55: duplicates drop groups, force
restore

bench 61: qui glevelsof groups
bench 60: qui levelsof groups

bench 66: qui gdistinct groups
bench 65: qui distinct groups

bench 71: qui gstats winsor rvar, s(_wg)
bench 70: qui winsor2 groups

local commands     ///
        collapse   ///
        collapse   ///
        reshape    ///
        reshape    ///
        xtile      ///
        pctile     ///
        egen       ///
        contract   ///
        isid       ///
        duplicates ///
        levelsof   ///
        distinct   ///
        winsor

local bench_table `"     Versus | Native | gtools | % faster "'
local bench_table `"`bench_table'"' _n(1) `" ---------- | ------ | ------ | -------- "'
forvalues i = 10(5)70 {
    gettoken cmd commands: commands
    local pct      "`:disp %7.2f  100 * (`r`i'' - `r`=`i'+1'') / `r`i'''"
    local dnative  "`:disp %6.2f `r`i'''"
    local dgtools  "`:disp %6.2f `r`=`i'+1'''"
    local cmd      `"`:disp %10s "`cmd'"'"'
    local bench_table `"`bench_table'"' _n(1) `" `cmd' | `dnative' | `dgtools' | `pct'% "'
}
disp _n(1) `"`bench_table'"'
