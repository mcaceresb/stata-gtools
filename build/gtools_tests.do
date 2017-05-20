* ---------------------------------------------------------------------
* Project: gtools
* Program: gtools_tests.do
* Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
* Created: Tue May 16 07:23:02 EDT 2017
* Updated: Sat May 20 14:03:27 EDT 2017
* Purpose: Unit tests for gtools
* Version: 0.3.0
* Manual:  help gcollapse, help gegen

* Stata start-up options
* ----------------------

version 13
clear all
set more off
set varabbrev off
capture log close _all
set seed 42

* Main program wrapper
* --------------------

program main
    syntax, [CAPture NOIsily checks BENCHmark]

    * Set up
    * ------

    local  progname tests
    local  start_time "$S_TIME $S_DATE"
    di "Start: `start_time'"

    * Run the things
    * --------------

    `capture' `noisily' {
        * do test_gcollapse.do
        * do test_gegen.do
        * do bench_gcollapse.do
        if ( ("`checks'" == "") & ("`benchmark'" == "") ) {
            di as err "Nothing to do. Specify -checks-, -bench-, or both"
            exit 198
        }

        if ( "`checks'" != "" ) {
            checks_byvars_gcollapse
            checks_options_gcollapse
            checks_byvars_gcollapse,  multi
            checks_options_gcollapse, multi

            checks_consistency_gegen
            checks_consistency_gegen, multi
            checks_consistency_gcollapse
            checks_consistency_gcollapse, multi
        }

        if ( "`benchmark'" != "" ) {
            bench_ftools y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(4) kmax(7) kvars(15)
            bench_ftools y1 y2 y3, by(x3)    kmin(4) kmax(7) kvars(3) stats(mean median)
            * This fails in Stata/MP 14.2 because fcollapse can't handle too many levels there
            * bench_ftools y1 y2 y3, by(x4 x6) kmin(4) kmax(7) kvars(3) stats(mean median)

            bench_group_size x1 x2,  by(group) obsexp(6) kmax(6)
            bench_group_size x1 x2,  by(group) obsexp(6) kmax(6) pct(median iqr p23 p77)
            bench_sample_size x1 x2, by(group) kmin(4)   kmax(7)
            bench_sample_size x1 x2, by(group) kmin(4)   kmax(7) pct(median iqr p23 p77)
        }
    }
    local rc = _rc

    exit_message, rc(`rc') progname(`progname') start_time(`start_time') `capture'
    exit `rc'
end

capture program drop exit_message
program exit_message
    syntax, rc(int) progname(str) start_time(str) [CAPture]
    local end_time "$S_TIME $S_DATE"
    local time     "Start: `start_time'" _n(1) "End: `end_time'"
    di ""
    if (`rc' == 0) {
        di "End: $S_TIME $S_DATE"
        local paux	  ran
        local message "`progname' finished running" _n(2) "`time'"
        local subject "`progname' `paux'"
    }
    else if ("`capture'" == "") {
        di "WARNING: $S_TIME $S_DATE"
        local paux ran with non-0 exit status
        local message "`progname' ran but Stata gave error code r(`rc')" _n(2) "`time'"
        local subject "`progname' `paux'"
    }
    else {
        di "ERROR: $S_TIME $S_DATE"
        local paux ran with errors
        local message "`progname' stopped with error code r(`rc')" _n(2) "`time'"
        local subject "`progname' `paux'"
    }
    di "`subject'"
    di ""
    di "`message'"
end

* Wrapper for easy timer use
cap program drop mytimer
program mytimer, rclass
    * args number what step
    syntax anything, [minutes ts]

    tokenize `anything'
    local number `1'
    local what   `2'
    local step   `3'

    if ("`what'" == "end") {
        qui {
            timer clear `number'
            timer off   `number'
        }
        if ("`ts'" == "ts") mytimer_ts `step'
    }
    else if ("`what'" == "info") {
        qui {
            timer off `number'
            timer list `number'
        }
        local seconds = r(t`number')
        local prints  `:di trim("`:di %21.2gc `seconds''")' seconds
        if ("`minutes'" != "") {
            local minutes = `seconds' / 60
            local prints  `:di trim("`:di %21.3gc `minutes''")' minutes
        }
        mytimer_ts Step `step' took `prints'
        qui {
            timer clear `number'
            timer on    `number'
        }
    }
    else {
        qui {
            timer clear `number'
            timer on    `number'
            timer off   `number'
            timer list  `number'
            timer on    `number'
        }
        if ("`ts'" == "ts") mytimer_ts `step'
    }
end

capture program drop mytimer_ts
program mytimer_ts
    display _n(1) "{hline 79}"
    if ("`0'" != "") display `"`0'"'
    display `"        Base: $S_FN"'
    display  "        In memory: `:di trim("`:di %21.0gc _N'")' observations"
    display  "        Timestamp: $S_TIME $S_DATE"
    display  "{hline 79}" _n(1)
end

capture program drop sim
program sim, rclass
    syntax, [offset(str) n(int 100) nj(int 10) njsub(int 2) string float sortg replace groupmiss outmiss]
    qui {
        if ("`offset'" == "") local offset 0
        clear
        set obs `n'
        gen group  = ceil(`nj' *  _n / _N) + `offset'
        bys group: gen groupsub   = ceil(`njsub' *  _n / _N)
        bys group: gen groupfloat = ceil(`njsub' *  _n / _N) + 0.5
        gen rsort = runiform() - 0.5
        gen rnorm = rnormal()
        if ("`sortg'" == "")  sort rsort
        if ("`groupmiss'" != "") replace group = . if runiform() < 0.1
        if ("`outmiss'" != "") replace rsort = . if runiform() < 0.1
        if ("`float'" != "")  replace group = group / `nj'
        if ("`string'" != "") {
            tostring group, `:di cond("`replace'" == "", "gen(groupstr)", "replace")'
            local target `:di cond("`replace'" == "", "groupstr", "group")'
            replace `target' = "i am a modesly long string" + `target'
        }
        gen long grouplong = ceil(`nj' *  _n / _N) + `offset'
    }
    sum rsort
    di "Obs = " trim("`:di %21.0gc _N'") "; Groups = " trim("`:di %21.0gc `nj''")
    compress
    return local n  = `n'
    return local nj = `nj'
    return local offset = `offset'
    return local string = ("`string'" != "")
end

capture program drop checks_consistency_gcollapse
program checks_consistency_gcollapse
    syntax, [tol(real 1e-6) multi NOIsily]
    di _n(1) "{hline 80}" _n(1) "checks_consistency_gcollapse `multi'" _n(1) "{hline 80}" _n(1)

    local stats sum mean sd max min count percent first last firstnm lastnm median iqr
    local collapse_str ""
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') `stat' = rnorm
    }
    local collapse_str `collapse_str' (p23) p23 = rnorm
    local collapse_str `collapse_str' (p77) p77 = rnorm

    sim, n(50000) nj(8) njsub(4) string groupmiss outmiss
    mytimer 9
    qui `noisily' foreach i in 0 3 6 9 {
        if (`i' == 0) local by groupsub groupstr
        if (`i' == 3) local by groupstr
        if (`i' == 6) local by groupsub group
        if (`i' == 9) local by grouplong
    preserve
        mytimer 9 info
        gcollapse `collapse_str', by(`by') verbose benchmark `multi'
        mytimer 9 info "gcollapse to groups"
        tempfile f`i'
        save `f`i''
    * I originally was also testing fcollapse, but it can't do sd for
    * some reason, and you can't mix string and numeric variables...
    * restore, preserve
    *     mytimer 9 info
    *     if (`i' != 0) {
    *         fcollapse `collapse_str', by(`by') verbose
    *         mytimer 9 info "fcollapse to groups"
    *         tempfile f`:di `i' + 1'
    *         save `f`:di `i' + 1''
    *     }
    restore, preserve
        mytimer 9 info
        collapse `collapse_str', by(`by')
        mytimer 9 info "collapse to groups"
        tempfile f`:di `i' + 2'
        save `f`:di `i' + 2''
    restore
    }
    mytimer 9 off

    sim, n(50000) nj(8000) njsub(4) string groupmiss outmiss
    qui `noisily' foreach i in 12 15 18 21 {
        if (`i' == 12) local by groupsub groupstr
        if (`i' == 15) local by groupstr
        if (`i' == 18) local by groupsub group
        if (`i' == 21) local by grouplong
    preserve
        mytimer 9 info
        gcollapse `collapse_str', by(`by') verbose benchmark `multi'
        mytimer 9 info "gcollapse 2 groups"
        tempfile f`i'
        save `f`i''
    * restore, preserve
    *     mytimer 9 info
    *     if (`i' != 12) {
    *         fcollapse `collapse_str', by(`by') verbose
    *         mytimer 9 info "fcollapse to groups"
    *         tempfile f`:di `i' + 1'
    *         save `f`:di `i' + 1''
    *     }
    restore, preserve
        mytimer 9 info
        collapse `collapse_str', by(`by')
        mytimer 9 info "collapse to groups"
        tempfile f`:di `i' + 2'
        save `f`:di `i' + 2''
    restore
    }

    foreach i in 0 3 6 9 12 15 18 21 {
    preserve
    use `f`:di `i' + 2'', clear
        local bad_any = 0
        if (`i' == 0)  local bad groupsub groupstr
        if (`i' == 3)  local bad groupstr
        if (`i' == 6)  local bad groupsub group
        if (`i' == 9)  local bad grouplong
        if (`i' == 12) local bad groupsub groupstr
        if (`i' == 15) local bad groupstr
        if (`i' == 18) local bad groupsub group
        if (`i' == 21) local bad grouplong
        local by `bad'
        foreach var in `stats' p23 p77 {
            rename `var' c_`var'
        }
        qui merge 1:1 `by' using `f`i'', assert(3)
        foreach var in `stats' p23 p77 {
            qui count if ( (abs(`var' - c_`var') > `tol') & (`var' != c_`var'))
            if ( `r(N)' > 0 ) {
                gen bad_`var' = abs(`var' - c_`var') * (`var' != c_`var')
                local bad `bad' *`var'
                di "`var' has `:di r(N)' mismatches".
                local bad_any = 1
            }
        }
        if ( `bad_any' ) {
            order `bad'
            egen bad_any = rowmax(bad_*)
            l *count* `bad' if bad_any
            sum bad_*
            exit 9
        }
        else {
            di "gcollapse produced identical data to collapse (tol = `tol', `by')"
        }
    restore
    }

    * foreach i in 4 7 10 16 19 22 {
    * preserve
    * use `f`:di `i' + 1'', clear
    *     local bad_any = 0
    *     if (`i' == 4)  local bad groupstr
    *     if (`i' == 7)  local bad groupsub group
    *     if (`i' == 10) local bad grouplong
    *     if (`i' == 16) local bad groupstr
    *     if (`i' == 19) local bad groupsub group
    *     if (`i' == 22) local bad grouplong
    *     local by `bad'
    *     foreach var in `stats' p23 p77 {
    *         rename `var' c_`var'
    *     }
    *     qui merge 1:1 `bad' using `f`i'', assert(3)
    *     foreach var in `stats' p23 p77 {
    *         qui count if ( (abs(`var' - c_`var') > `tol') & (`var' != c_`var'))
    *         if ( `r(N)' > 0 ) {
    *             gen bad_`var' = abs(`var' - c_`var') * (`var' != c_`var')
    *             local bad `bad' *`var'
    *             di "`var' has `:di r(N)' mismatches".
    *             local bad_any = 1
    *         }
    *     }
    *     if ( `bad_any' ) {
    *         order `bad'
    *         egen bad_any = rowmax(bad_*)
    *         l *count* `bad' if bad_any & _n < 100
    *         sum bad_*
    *         di "fcollapse produced different data to collapse (tol = `tol', `by')"
    *     }
    *     else {
    *         di "fcollapse produced identical data to collapse (tol = `tol', `by')"
    *     }
    * restore
    * }

    di ""
    di as txt "Passed! checks_consistency_gcollapse `multi'"
end

capture program drop checks_byvars_gcollapse
program checks_byvars_gcollapse
    syntax, [multi]
    di _n(1) "{hline 80}" _n(1) "checks_byvars_gcollapse `multi'" _n(1) "{hline 80}" _n(1)

    sim, n(1000) nj(250) string
    set rmsg on
    preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupsub) verbose `multi'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(group) verbose `multi'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupstr) verbose `multi'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(grouplong) verbose `multi'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupsub) verbose `multi'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(group groupsub) verbose `multi'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(grouplong groupsub) verbose `multi'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupstr groupsub) verbose `multi'
    restore
    set rmsg off


    di ""
    di as txt "Passed! checks_byvars_gcollapse `multi'"
end

capture program drop checks_options_gcollapse
program checks_options_gcollapse
    syntax, [multi]
    di _n(1) "{hline 80}" _n(1) "checks_options_gcollapse `multi'" _n(1) "{hline 80}" _n(1)

    local stats mean count median iqr
    local collapse_str ""
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') `stat' = rnorm `stat'2 = rnorm
    }

    sim, n(200) nj(10) string outmiss
    preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark `multi'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose unsorted `multi'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark cw `multi'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) double `multi'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) merge `multi'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore

    sort groupstr groupsub
    preserve
        gcollapse `collapse_str', by(groupstr groupsub) verbose benchmark `multi'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr groupsub) verbose benchmark smart `multi'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupsub groupstr) verbose benchmark smart `multi'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark `multi'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark smart `multi'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupsub) verbose benchmark smart `multi'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupsub) verbose benchmark `multi'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore

    di ""
    di as txt "Passed! checks_options_gcollapse `multi'"
end

* TODO: Edge cases (nothing in anything, no -by-, should mimic collapse // 2017-05-16 08:03 EDT
capture program drop sim
program sim, rclass
    syntax, [offset(str) n(int 100) nj(int 10) njsub(int 2) string float sortg replace groupmiss outmiss]
    qui {
        if ("`offset'" == "") local offset 0
        clear
        set obs `n'
        gen group  = ceil(`nj' *  _n / _N) + `offset'
        bys group: gen groupsub   = ceil(`njsub' *  _n / _N)
        bys group: gen groupfloat = ceil(`njsub' *  _n / _N) + 0.5
        gen rsort = runiform() - 0.5
        gen rnorm = rnormal()
        if ("`sortg'" == "")  sort rsort
        if ("`groupmiss'" != "") replace group = . if runiform() < 0.1
        if ("`outmiss'" != "") replace rsort = . if runiform() < 0.1
        if ("`float'" != "")  replace group = group / `nj'
        if ("`string'" != "") {
            tostring group, `:di cond("`replace'" == "", "gen(groupstr)", "replace")'
            local target `:di cond("`replace'" == "", "groupstr", "group")'
            replace `target' = "i am a modesly long string" + `target'
        }
        gen long grouplong = ceil(`nj' *  _n / _N) + `offset'
    }
    sum rsort
    di "Obs = " trim("`:di %21.0gc _N'") "; Groups = " trim("`:di %21.0gc `nj''")
    compress
    return local n  = `n'
    return local nj = `nj'
    return local offset = `offset'
    return local string = ("`string'" != "")
end

capture program drop checks_consistency_gegen
program checks_consistency_gegen
    syntax, [tol(real 1e-6) multi]
    di _n(1) "{hline 80}" _n(1) "checks_consistency_gegen `multi'" _n(1) "{hline 80}" _n(1)

    local stats total sum mean sd max min count median iqr
    sim, n(500000) nj(10000) njsub(4) string groupmiss outmiss

    cap drop g*_*
    cap drop c*_*
    di "Checking full range"
    foreach fun of local stats {
        qui gegen g_`fun' = `fun'(rnorm), by(groupstr groupsub) v b
        qui  egen c_`fun' = `fun'(rnorm), by(groupstr groupsub)
        cap noi assert (g_`fun' == c_`fun') | abs(g_`fun' - c_`fun') < `tol'
        if ( _rc ) di as err "`fun' failed! (tol = `tol')"
        else di as txt "    `fun' was OK"
    }

    local fun tag
    {
        qui gegen g_`fun' = `fun'(groupstr groupsub)
        qui  egen c_`fun' = `fun'(groupstr groupsub)
        cap noi assert (g_`fun' == c_`fun') | abs(g_`fun' - c_`fun') < `tol'
        if ( _rc ) di as err "`fun' failed! (tol = `tol')"
        else di as txt "    `fun' was OK"
    }

    cap drop g*_*
    cap drop c*_*
    di "Checking if range"
    foreach fun of local stats {
        qui gegen gif_`fun' = `fun'(rnorm) if rsort > 0, by(groupstr groupsub)
        qui  egen cif_`fun' = `fun'(rnorm) if rsort > 0, by(groupstr groupsub)
        cap noi assert (gif_`fun' == cif_`fun') | abs(gif_`fun' - cif_`fun') < `tol'
        if ( _rc ) di as err "`fun' failed! (tol = `tol')"
        else di as txt "    `fun' was OK"
    }

    local fun tag
    {
        qui gegen gif_`fun' = `fun'(groupstr groupsub) if rsort > 0
        qui  egen cif_`fun' = `fun'(groupstr groupsub) if rsort > 0
        cap noi assert (gif_`fun' == cif_`fun') | abs(gif_`fun' - cif_`fun') < `tol'
        if ( _rc ) di as err "`fun' failed! (tol = `tol')"
        else di as txt "    `fun' was OK"
    }

    cap drop g*_*
    cap drop c*_*
    di "Checking in range"
    foreach fun of local stats {
        local in1 = ceil(runiform() * `=_N')
        local in2 = ceil(runiform() * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui gegen gin_`fun' = `fun'(rnorm) in `from' / `to', by(groupstr groupsub) v b
        qui  egen cin_`fun' = `fun'(rnorm) in `from' / `to', by(groupstr groupsub)
        cap noi assert (gin_`fun' == cin_`fun') | abs(gin_`fun' - cin_`fun') < `tol'
        if ( _rc ) di as err "`fun' failed! (tol = `tol')"
        else di as txt "    `fun' was OK"
    }

    local fun tag
    {
        local in1 = ceil(runiform() * `=_N')
        local in2 = ceil(runiform() * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui gegen gin_`fun' = `fun'(groupstr groupsub) in `from' / `to', v b
        qui  egen cin_`fun' = `fun'(groupstr groupsub) in `from' / `to'
        cap noi assert (gin_`fun' == cin_`fun') | abs(gin_`fun' - cin_`fun') < `tol'
        if ( _rc ) di as err "`fun' failed! (tol = `tol')"
        else di as txt "    `fun' was OK"
    }

    cap drop g*_*
    cap drop c*_*
    di "Checking if in range"
    foreach fun of local stats {
        local in1 = ceil(runiform() * `=_N')
        local in2 = ceil(runiform() * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui gegen gifin_`fun' = `fun'(rnorm) if rsort < 0 in `from' / `to', by(groupstr groupsub)
        qui  egen cifin_`fun' = `fun'(rnorm) if rsort < 0 in `from' / `to', by(groupstr groupsub)
        cap noi assert (gifin_`fun' == cifin_`fun') | abs(gifin_`fun' - cifin_`fun') < `tol'
        if ( _rc ) di as err "`fun' failed! (tol = `tol')"
        else di as txt "    `fun' was OK"
    }

    local fun tag
    {
        local in1 = ceil(runiform() * `=_N')
        local in2 = ceil(runiform() * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui gegen gifin_`fun' = `fun'(groupstr groupsub) if rsort < 0 in `from' / `to'
        qui  egen cifin_`fun' = `fun'(groupstr groupsub) if rsort < 0 in `from' / `to'
        cap noi assert (gifin_`fun' == cifin_`fun') | abs(gifin_`fun' - cifin_`fun') < `tol'
        if ( _rc ) di as err "`fun' failed! (tol = `tol')"
        else di as txt "    `fun' was OK"
    }

    di ""
    di as txt "Passed! checks_consistency_gegen `multi'"
end
***********************************************************************
*                           Data simulation                           *
***********************************************************************

capture program drop bench_sim
program bench_sim
    syntax, [n(int 100) nj(int 10) njsub(int 2) nvars(int 2)]
    local offset = -123456

    clear
    set obs `n'
    gen group  = ceil(`nj' *  _n / _N) + `offset'
    gen long grouplong = ceil(`nj' *  _n / _N) + `offset'
    bys group: gen groupsub      = ceil(`njsub' *  _n / _N)
    bys group: gen groupsubfloat = ceil(`njsub' *  _n / _N) + 0.5
    tostring group, gen(groupstr)
    replace groupstr = "i am a modesly long string" + groupstr

    forvalues i = 1 / `nvars' {
        gen x`i' = rnormal()
    }
    gen rsort = runiform() - 0.5
    sort rsort

    replace group = . if runiform() < 0.1
    replace rsort = . if runiform() < 0.1
end

capture program drop bench_sim_ftools
program bench_sim_ftools
	args n k
	clear
	qui set obs `n'
	noi di "(obs set)"
	loc m = ceil(`n' / 10)
	gen long x1  = ceil(uniform() * 10000) * 100
	gen int  x2  = ceil(uniform() * 3000)
	gen byte x3  = ceil(uniform() * 100)
	gen str  x4  = "u" + string(ceil(uniform() * 100), "%5.0f")
	gen long x5  = ceil(uniform() * 5000)
	gen str  x6  = "u" + string(ceil(uniform() * 10), "%5.0f")
	noi di "(Xs set)"
	forv i = 1 / `k' {
		gen double y`i' = 123.456 + runiform()
	}
	loc obs_k = ceil(`c(N)' / 1000)
end

***********************************************************************
*                       ftools-style benchmarks                       *
***********************************************************************

capture program drop bench_ftools
program bench_ftools
    syntax anything, by(str) [kvars(int 5) stats(str) kmin(int 4) kmax(int 7)]
    if ("`stats'" == "") local stats sum

    local collapse ""
    foreach stat of local stats {
        local collapse `collapse' (`stat')
        foreach var of local anything {
            local collapse `collapse' `stat'_`var' = `var'
        }
    }

    local i = 0
    local N ""
    di "Benchmarking N for J = 100; by(`by')"
    di "    vars  = `anything'"
    di "    stats = `stats'"
    forvalues k = `kmin' / `kmax' {
        di "    `:di %21.0gc `:di 2 * 10^`k'''"
        local N `N' `:di 2 * 10^`k''
        qui bench_sim_ftools `:di 2 * 10^`k'' `kvars'
        preserve
            local ++i
            timer clear
            timer on `i'
                qui gcollapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
        restore, preserve
            local ++i
            timer clear
            timer on `i'
                qui gcollapse `collapse', by(`by') multi
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
        restore, preserve
            local ++i
            timer clear
            timer on `i'
                qui fcollapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
        restore
    }

    local i = 1
    di "Results varying N for J = 100; by(`by')"
    di "|                     N | gcollapse | gcollapse (multi) | fcollapse |     ratio | ratio (multi) |"
    foreach nn in `N' {
        local ii  = `i' + 1
        local iii = `i' + 2
        di "| `:di %21.0gc `nn'' | `:di %9.2f `r`i''' | `:di %17.2f `r`ii''' | `:di %9.2f `r`iii''' | `:di %9.2f `r`iii'' / `r`i''' | `:di %13.2f `r`iii'' / `r`ii''' |"
        local ++i
        local ++i
        local ++i
    }
    timer clear
end

***********************************************************************
*                             benchmarks                              *
***********************************************************************

capture program drop bench_sample_size
program bench_sample_size
    syntax anything, by(str) [nj(int 10) pct(str) stats(str) kmin(int 4) kmax(int 7)]
    * NOTE: fcollapse can't do sd, apparently
    if ("`stats'" == "") local stats sum mean max min count percent first last firstnm lastnm
    local stats `stats' `pct'

    local collapse ""
    foreach stat of local stats {
        local collapse `collapse' (`stat')
        foreach var of local anything {
            local collapse `collapse' `stat'_`var' = `var'
        }
    }

    local i = 0
    local N ""
    di "Benchmarking N for J = `nj'; by(`by')"
    di "    vars  = `anything'"
    di "    stats = `stats'"
    forvalues k = `kmin' / `kmax' {
        di "    `:di %21.0gc `:di 2 * 10^`k'''"
        local N `N' `:di 2 * 10^`k''
        qui bench_sim, n(`:di 2 * 10^`k'') nj(`nj') njsub(2) nvars(2)
        preserve
            local ++i
            timer clear
            timer on `i'
                qui gcollapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
        restore, preserve
            local ++i
            timer clear
            timer on `i'
                qui gcollapse `collapse', by(`by') multi
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
        restore, preserve
            local ++i
            timer clear
            timer on `i'
                qui fcollapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
        restore
    }

    local i = 1
    di "Results varying N for J = `nj'; by(`by')"
    di "|                     N | gcollapse | gcollapse (multi) | fcollapse |     ratio | ratio (multi) |"
    foreach nn in `N' {
        local ii  = `i' + 1
        local iii = `i' + 2
        di "| `:di %21.0gc `nn'' | `:di %9.2f `r`i''' | `:di %17.2f `r`ii''' | `:di %9.2f `r`iii''' | `:di %9.2f `r`iii'' / `r`i''' | `:di %13.2f `r`iii'' / `r`ii''' |"
        local ++i
        local ++i
        local ++i
    }
    timer clear
end

capture program drop bench_group_size
program bench_group_size
    syntax anything, by(str) [pct(str) stats(str) obsexp(int 6) kmin(int 1) kmax(int 6)]
    * NOTE: fcollapse can't do sd, apparently
    if ("`stats'" == "") local stats sum mean max min count percent first last firstnm lastnm
    local stats `stats' `pct'

    local collapse ""
    foreach stat of local stats {
        local collapse `collapse' (`stat')
        foreach var of local anything {
            local collapse `collapse' `stat'_`var' = `var'
        }
    }

    local nstr = trim("`:di %21.0gc `:di 5 * 10^`obsexp'''")
    local i = 0
    local N ""
    di "Benchmarking J for N = `nstr'; by(`by')"
    di "    vars  = `anything'"
    di "    stats = `stats'"
    forvalues k = `kmin' / `kmax' {
        di "    `:di %21.0gc `:di 10^`k'''"
        local N `N' `:di 10^`k''
        qui bench_sim, n(`:di 5 * 10^`obsexp'') nj(`:di 10^`k'') njsub(2) nvars(2)
        preserve
            local ++i
            timer clear
            timer on `i'
                qui gcollapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
        restore, preserve
            local ++i
            timer clear
            timer on `i'
                qui gcollapse `collapse', by(`by') multi
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
        restore, preserve
            local ++i
            timer clear
            timer on `i'
                qui fcollapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
        restore
    }

    local i = 1
    di "Results varying J for N = `nstr'; by(`by')"
    di "|                     J | gcollapse | gcollapse (multi) | fcollapse |     ratio | ratio (multi) |"
    foreach nn in `N' {
        local ii  = `i' + 1
        local iii = `i' + 2
        di "| `:di %21.0gc `nn'' | `:di %9.2f `r`i''' | `:di %17.2f `r`ii''' | `:di %9.2f `r`iii''' | `:di %9.2f `r`iii'' / `r`i''' | `:di %13.2f `r`iii'' / `r`ii''' |"
        local ++i
        local ++i
        local ++i
    }
    timer clear
end

* !cd ..; ./build.py
* do gcollapse.ado
* do gegen.ado
* do gtools_tests.do

* Benchmarks in the README
* ------------------------

* bench_ftools y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(4) kmax(7) kvars(15)
* bench_ftools y1 y2 y3, by(x3)    kmin(4) kmax(7) kvars(3) stats(mean median)
* bench_ftools y1 y2 y3, by(x4 x6) kmin(4) kmax(7) kvars(3) stats(mean median)

* bench_group_size x1 x2,  by(group) obsexp(6) kmax(6)
* bench_group_size x1 x2,  by(group) obsexp(6) kmax(6) pct(median iqr p23 p77)
* bench_sample_size x1 x2, by(group) kmin(4)   kmax(7)
* bench_sample_size x1 x2, by(group) kmin(4)   kmax(7) pct(median iqr p23 p77)

* Misc
* ----

* bench_ftools y1 y2 y3 y4 y5, by(x3) kmin(2) kmax(5) kvars(5)
* bench_group_size  x1 x2,  by(group) obsexp(5) kmax(4)
* bench_group_size  x1 x2,  by(group) obsexp(5) kmax(4) pct(median iqr p23 p77)
* bench_sample_size x1 x2,  by(group) kmin(2)   kmax(5)
* bench_sample_size x1 x2,  by(group) kmin(2)   kmax(5) pct(median iqr p23 p77)

* bench_group_size x1 x2,  by(groupstr) obsexp(6) kmax(6)
* bench_group_size x1 x2,  by(groupstr) obsexp(6) kmax(6) pct(median iqr p23 p77)
* bench_sample_size x1 x2, by(groupstr) kmin(4)   kmax(7)
* bench_sample_size x1 x2, by(groupstr) kmin(4)   kmax(7) pct(median iqr p23 p77)

* ---------------------------------------------------------------------
* Run the things

main, cap noi checks
