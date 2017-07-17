* ---------------------------------------------------------------------
* Project: gtools
* Program: gtools_tests.do
* Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
* Created: Tue May 16 07:23:02 EDT 2017
* Updated: Fri Jun 16 17:37:39 EDT 2017
* Purpose: Unit tests for gtools
* Version: 0.6.6
* Manual:  help gcollapse, help gegen

* Stata start-up options
* ----------------------

version 13
clear all
set more off
set varabbrev off
* set seed 42
set seed 1729
set linesize 128

* Main program wrapper
* --------------------

program main
    syntax, [CAPture NOIsily *]

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
        if ( `:list posof "checks" in options' ) {
            checks_byvars_gcollapse,  debug_force_single
            checks_options_gcollapse, debug_force_single
            if !inlist("`c(os)'", "Windows") {
                checks_byvars_gcollapse,  debug_force_multi
                checks_options_gcollapse, debug_force_multi
            }

            checks_options_gegen, debug_force_single
            if !inlist("`c(os)'", "Windows") {
                checks_options_gegen, debug_force_multi
            }

            checks_consistency_gcollapse, debug_checkhash
            checks_consistency_gcollapse, forceio debug_io_read_method(0)
            checks_consistency_gcollapse, forceio debug_io_read_method(1)
            checks_consistency_gcollapse, debug_io_check(1) debug_io_threshold(0)
            checks_consistency_gcollapse, debug_io_check(1) debug_io_threshold(1000000)
            checks_consistency_gcollapse, debug_force_single
            if !inlist("`c(os)'", "Windows") {
                checks_consistency_gcollapse, debug_force_multi
            }

            checks_consistency_gegen, debug_force_single b
            if !inlist("`c(os)'", "Windows") {
                checks_consistency_gegen, debug_force_multi  b
            }
        }

        if ( `:list posof "test" in options' ) {
            cap ssc install ftools
            cap ssc install moremata

            di "Short (quick) versions of the benchmarks"
            bench_ftools y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(3) kmax(4) kvars(15)
            bench_ftools y1 y2 y3,          by(x3) kmin(3) kmax(4) kvars(3) stats(mean median)
            bench_ftools y1 y2 y3 y4 y5 y6, by(x3) kmin(3) kmax(4) kvars(6) stats(sum mean count min max)
            bench_sample_size x1 x2, by(group) kmin(3) kmax(4) pct(median iqr p23 p77)
            bench_group_size  x1 x2, by(group) kmin(2) kmax(3) pct(median iqr p23 p77) obsexp(3)

            bench_switch_fcoll y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(3) kmax(4) kvars(15) style(ftools)
            bench_switch_fcoll y1 y2 y3,          by(x3)    kmin(3) kmax(4) kvars(3) stats(mean median)             style(ftools)
            bench_switch_fcoll y1 y2 y3 y4 y5 y6, by(x3)    kmin(3) kmax(4) kvars(6) stats(sum mean count min max)  style(ftools)
            bench_switch_fcoll x1 x2, margin(N)   by(group) kmin(3) kmax(4) pct(median iqr p23 p77)                 style(gtools)
            bench_switch_fcoll x1 x2, margin(J)   by(group) kmin(2) kmax(3) pct(median iqr p23 p77) obsexp(3)       style(gtools)
        }

        if ( `:list posof "benchmark" in options' ) {
            cap ssc install ftools
            cap ssc install moremata

            bench_ftools y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(4) kmax(7) kvars(15)
            bench_ftools y1 y2 y3,             by(x3)    kmin(4) kmax(7) kvars(3) stats(mean median)
            bench_ftools y1 y2 y3 y4 y5 y6,    by(x3)    kmin(4) kmax(7) kvars(6) stats(sum mean count min max)
            bench_sample_size x1 x2, margin(N) by(group) kmin(4) kmax(7) pct(median iqr p23 p77)
            bench_group_size  x1 x2, margin(J) by(group) kmin(3) kmax(6) pct(median iqr p23 p77) obsexp(6)
        }

        if ( `:list posof "bench_fcoll" in options' ) {
            cap ssc install ftools
            cap ssc install moremata

            bench_switch_fcoll y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(4) kmax(7) kvars(15) style(ftools)
            bench_switch_fcoll y1 y2 y3,          by(x3)  kmin(4) kmax(7) kvars(3) stats(mean median)               style(ftools)
            bench_switch_fcoll y1 y2 y3 y4 y5 y6, by(x3)  kmin(4) kmax(7) kvars(6) stats(sum mean count min max)    style(ftools)
            bench_switch_fcoll x1 x2, margin(N) by(group) kmin(4) kmax(7) pct(median iqr p23 p77)                   style(gtools)
            bench_switch_fcoll x1 x2, margin(J) by(group) kmin(1) kmax(6) pct(median iqr p23 p77) obsexp(6)         style(gtools)
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
        local paux      ran
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
        if ("`outmiss'" != "") replace rnorm = . if runiform() < 0.1
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
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_consistency_gcollapse `options'" _n(1) "{hline 80}" _n(1)

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
        gcollapse `collapse_str', by(`by') verbose benchmark `options'
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
        gcollapse `collapse_str', by(`by') verbose benchmark `options'
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
    di as txt "Passed! checks_consistency_gcollapse `options'"
end

capture program drop checks_byvars_gcollapse
program checks_byvars_gcollapse
    syntax, [*]
    di _n(1) "{hline 80}" _n(1) "checks_byvars_gcollapse `options'" _n(1) "{hline 80}" _n(1)

    sim, n(1000) nj(250) string
    set rmsg on
    preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupsub) verbose `options'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(group) verbose `options'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupstr) verbose `options'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(grouplong) verbose `options'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupsub) verbose `options'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(group groupsub) verbose `options'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(grouplong groupsub) verbose `options'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupstr groupsub) verbose `options'
    restore
    set rmsg off


    di ""
    di as txt "Passed! checks_byvars_gcollapse `options'"
end

capture program drop checks_options_gcollapse
program checks_options_gcollapse
    syntax, [*]
    di _n(1) "{hline 80}" _n(1) "checks_options_gcollapse `options'" _n(1) "{hline 80}" _n(1)

    local stats mean count median iqr
    local collapse_str ""
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') `stat' = rnorm `stat'2 = rnorm
    }

    sim, n(200) nj(10) string outmiss
    preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose forceio `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose forcemem `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose unsorted `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark cw `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) double `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) merge `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore

    sort groupstr groupsub
    preserve
        gcollapse `collapse_str', by(groupstr groupsub) verbose benchmark `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr groupsub) verbose benchmark smart `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupsub groupstr) verbose benchmark smart `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark smart `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupsub) verbose benchmark smart `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupsub) verbose benchmark `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore

    di ""
    di as txt "Passed! checks_options_gcollapse `options'"
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
        if ("`outmiss'" != "") replace rnorm = . if runiform() < 0.1
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
    syntax, [tol(real 1e-6) *]
    di _n(1) "{hline 80}" _n(1) "checks_consistency_gegen `options'" _n(1) "{hline 80}" _n(1)

    local stats total sum mean sd max min count median iqr
    sim, n(500000) nj(10000) njsub(4) string groupmiss outmiss

    cap drop g*_*
    cap drop c*_*
    di "Checking full range"
    foreach fun of local stats {
        qui gegen g_`fun' = `fun'(rnorm), by(groupstr groupsub) `options'
        qui  egen c_`fun' = `fun'(rnorm), by(groupstr groupsub)
        cap noi assert (g_`fun' == c_`fun') | abs(g_`fun' - c_`fun') < `tol'
        if ( _rc ) {
            di as err "`fun' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    `fun' was OK"
    }

    foreach p in 10 30 70 90 {
        qui gegen g_p`p' = pctile(rnorm), by(groupstr groupsub) p(`p') `options'
        qui  egen c_p`p' = pctile(rnorm), by(groupstr groupsub) p(`p')
        cap noi assert (g_p`p' == c_p`p') | abs(g_p`p' - c_p`p') < `tol'
        if ( _rc ) {
            di as err "percentile `p' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    percentile `p' was OK"
    }

    local fun tag
    {
        qui gegen g_`fun' = `fun'(groupstr groupsub), v `options'
        qui  egen c_`fun' = `fun'(groupstr groupsub)
        cap noi assert (g_`fun' == c_`fun') | abs(g_`fun' - c_`fun') < `tol'
        if ( _rc ) {
            di as err "`fun' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    `fun' was OK"
    }

    cap drop g*_*
    cap drop c*_*
    di "Checking if range"
    foreach fun of local stats {
        qui gegen gif_`fun' = `fun'(rnorm) if rsort > 0, by(groupstr groupsub) `options'
        qui  egen cif_`fun' = `fun'(rnorm) if rsort > 0, by(groupstr groupsub)
        cap noi assert (gif_`fun' == cif_`fun') | abs(gif_`fun' - cif_`fun') < `tol'
        if ( _rc ) {
            di as err "`fun' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    `fun' was OK"
    }

    foreach p in 10 30 70 90 {
        qui gegen g_p`p' = pctile(rnorm) if rsort > 0, by(groupstr groupsub) p(`p') `options'
        qui  egen c_p`p' = pctile(rnorm) if rsort > 0, by(groupstr groupsub) p(`p')
        cap noi assert (g_p`p' == c_p`p') | abs(g_p`p' - c_p`p') < `tol'
        if ( _rc ) {
            di as err "percentile `p' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    percentile `p' was OK"
    }

    local fun tag
    {
        qui gegen gif_`fun' = `fun'(groupstr groupsub) if rsort > 0, v `options'
        qui  egen cif_`fun' = `fun'(groupstr groupsub) if rsort > 0
        cap noi assert (gif_`fun' == cif_`fun') | abs(gif_`fun' - cif_`fun') < `tol'
        if ( _rc ) {
            di as err "`fun' failed! (tol = `tol')"
            exit _rc
        }
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
        qui gegen gin_`fun' = `fun'(rnorm) in `from' / `to', by(groupstr groupsub) `options'
        qui  egen cin_`fun' = `fun'(rnorm) in `from' / `to', by(groupstr groupsub)
        cap noi assert (gin_`fun' == cin_`fun') | abs(gin_`fun' - cin_`fun') < `tol'
        if ( _rc ) {
            di as err "`fun' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    `fun' was OK"
    }

    foreach p in 10 30 70 90 {
        local in1 = ceil(runiform() * `=_N')
        local in2 = ceil(runiform() * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui gegen g_p`p' = pctile(rnorm) in `from' / `to', by(groupstr groupsub) p(`p') `options'
        qui  egen c_p`p' = pctile(rnorm) in `from' / `to', by(groupstr groupsub) p(`p')
        cap noi assert (g_p`p' == c_p`p') | abs(g_p`p' - c_p`p') < `tol'
        if ( _rc ) {
            di as err "percentile `p' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    percentile `p' was OK"
    }

    local fun tag
    {
        local in1 = ceil(runiform() * `=_N')
        local in2 = ceil(runiform() * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui gegen gin_`fun' = `fun'(groupstr groupsub) in `from' / `to', v b `options'
        qui  egen cin_`fun' = `fun'(groupstr groupsub) in `from' / `to'
        cap noi assert (gin_`fun' == cin_`fun') | abs(gin_`fun' - cin_`fun') < `tol'
        if ( _rc ) {
            di as err "`fun' failed! (tol = `tol')"
            exit _rc
        }
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
        qui gegen gifin_`fun' = `fun'(rnorm) if rsort < 0 in `from' / `to', by(groupstr groupsub) `options'
        qui  egen cifin_`fun' = `fun'(rnorm) if rsort < 0 in `from' / `to', by(groupstr groupsub)
        cap noi assert (gifin_`fun' == cifin_`fun') | abs(gifin_`fun' - cifin_`fun') < `tol'
        if ( _rc ) {
            di as err "`fun' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    `fun' was OK"
    }

    foreach p in 10 30 70 90 {
        local in1 = ceil(runiform() * `=_N')
        local in2 = ceil(runiform() * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui gegen g_p`p' = pctile(rnorm) if rsort < 0 in `from' / `to', by(groupstr groupsub) p(`p') `options'
        qui  egen c_p`p' = pctile(rnorm) if rsort < 0 in `from' / `to', by(groupstr groupsub) p(`p')
        cap noi assert (g_p`p' == c_p`p') | abs(g_p`p' - c_p`p') < `tol'
        if ( _rc ) {
            di as err "percentile `p' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    percentile `p' was OK"
    }

    local fun tag
    {
        local in1 = ceil(runiform() * `=_N')
        local in2 = ceil(runiform() * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui gegen gifin_`fun' = `fun'(groupstr groupsub) if rsort < 0 in `from' / `to', v `options'
        qui  egen cifin_`fun' = `fun'(groupstr groupsub) if rsort < 0 in `from' / `to'
        cap noi assert (gifin_`fun' == cifin_`fun') | abs(gifin_`fun' - cifin_`fun') < `tol'
        if ( _rc ) {
            di as err "`fun' failed! (tol = `tol')"
            exit _rc
        }
        else di as txt "    `fun' was OK"
    }

    di ""
    di as txt "Passed! checks_consistency_gegen `options'"
end

capture program drop checks_options_gegen
program checks_options_gegen
    syntax, [tol(real 1e-6) *]
    di _n(1) "{hline 80}" _n(1) "checks_options_gegen `options'" _n(1) "{hline 80}" _n(1)

    sim, n(20000) nj(100) njsub(2) string outmiss

    gegen id = group(groupstr groupsub)
    gegen double mean    = mean   (rnorm),  by(groupstr groupsub) verbose benchmark `options'
    gegen double sum     = sum    (rnorm),  by(groupstr groupsub) `options'
    gegen double median  = median (rnorm),  by(groupstr groupsub) `options'
    gegen double sd      = sd     (rnorm),  by(groupstr groupsub) `options'
    gegen double iqr     = iqr    (rnorm),  by(groupstr groupsub) `options'
    gegen double first   = first  (rnorm),  by(groupstr groupsub) `options' v b
    gegen double last    = last   (rnorm),  by(groupstr groupsub) `options'
    gegen double firstnm = firstnm(rnorm),  by(groupstr groupsub) `options'
    gegen double lastnm  = lastnm (rnorm),  by(groupstr groupsub) `options'
    gegen double q10     = pctile (rnorm),  by(groupstr groupsub) `options' p(10.5)
    gegen double q30     = pctile (rnorm),  by(groupstr groupsub) `options' p(30)
    gegen double q70     = pctile (rnorm),  by(groupstr groupsub) `options' p(70)
    gegen double q90     = pctile (rnorm),  by(groupstr groupsub) `options' p(90.5)

    gcollapse (mean)    g_mean    = rnorm  ///
              (sum)     g_sum     = rnorm  ///
              (median)  g_median  = rnorm  ///
              (sd)      g_sd      = rnorm  ///
              (iqr)     g_iqr     = rnorm  ///
              (first)   g_first   = rnorm  ///
              (last)    g_last    = rnorm  ///
              (firstnm) g_firstnm = rnorm  ///
              (lastnm)  g_lastnm  = rnorm  ///
              (p10.5)   g_q10     = rnorm  ///
              (p30)     g_q30     = rnorm  ///
              (p70)     g_q70     = rnorm  ///
              (p90.5)   g_q90     = rnorm, by(id) benchmark verbose `options' merge double

    foreach fun in mean sum median sd iqr first last firstnm lastnm q10 q30 q70 q90 {
        cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
        if ( _rc ) {
            recast double g_`fun' `fun'
            cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
            if ( _rc ) {
                di as err "`fun' vs gcollapse failed! (tol = `tol')"
                exit _rc
            }
        }
        else di as txt "    `fun' vs gcollapse was OK"
    }

    sim, n(20000) nj(100) njsub(2) string outmiss

    local in1 = ceil(runiform() * `=_N')
    local in2 = ceil(runiform() * `=_N')
    local from = cond(`in1' < `in2', `in1', `in2')
    local to   = cond(`in1' > `in2', `in1', `in2')

    gegen id = group(groupstr groupsub) in `from' / `to'
    gegen double mean    = mean   (rnorm) in `from' / `to',  by(groupstr groupsub) verbose benchmark `options'
    gegen double sum     = sum    (rnorm) in `from' / `to',  by(groupstr groupsub) `options'
    gegen double median  = median (rnorm) in `from' / `to',  by(groupstr groupsub) `options'
    gegen double sd      = sd     (rnorm) in `from' / `to',  by(groupstr groupsub) `options'
    gegen double iqr     = iqr    (rnorm) in `from' / `to',  by(groupstr groupsub) `options'
    gegen double first   = first  (rnorm) in `from' / `to',  by(groupstr groupsub) `options' v b
    gegen double last    = last   (rnorm) in `from' / `to',  by(groupstr groupsub) `options'
    gegen double firstnm = firstnm(rnorm) in `from' / `to',  by(groupstr groupsub) `options'
    gegen double lastnm  = lastnm (rnorm) in `from' / `to',  by(groupstr groupsub) `options'
    gegen double q10     = pctile (rnorm) in `from' / `to',  by(groupstr groupsub) `options' p(10.5)
    gegen double q30     = pctile (rnorm) in `from' / `to',  by(groupstr groupsub) `options' p(30)
    gegen double q70     = pctile (rnorm) in `from' / `to',  by(groupstr groupsub) `options' p(70)
    gegen double q90     = pctile (rnorm) in `from' / `to',  by(groupstr groupsub) `options' p(90.5)

    gcollapse (mean)    g_mean    = rnorm  ///
              (sum)     g_sum     = rnorm  ///
              (median)  g_median  = rnorm  ///
              (sd)      g_sd      = rnorm  ///
              (iqr)     g_iqr     = rnorm  ///
              (first)   g_first   = rnorm  ///
              (last)    g_last    = rnorm  ///
              (firstnm) g_firstnm = rnorm  ///
              (lastnm)  g_lastnm  = rnorm  ///
              (p10.5)   g_q10     = rnorm  ///
              (p30)     g_q30     = rnorm  ///
              (p70)     g_q70     = rnorm  ///
              (p90.5)   g_q90     = rnorm in `from' / `to', by(id) benchmark verbose `options' merge double

    foreach fun in mean sum median sd iqr first last firstnm lastnm q10 q30 q70 q90 {
        cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
        if ( _rc ) {
            recast double g_`fun' `fun'
            cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
            if ( _rc ) {
                di as err "`fun' vs gcollapse (in) failed! (tol = `tol')"
                exit _rc
            }
        }
        else di as txt "    `fun' vs gcollapse (in) was OK"
    }

    sim, n(20000) nj(100) njsub(2) string outmiss

    local in1 = ceil(runiform() * `=_N')
    local in2 = ceil(runiform() * `=_N')
    local from = cond(`in1' < `in2', `in1', `in2')
    local to   = cond(`in1' > `in2', `in1', `in2')
    qui count if rsort < 0 in `from' / `to'
    if !( `r(N)' < `=_N' ) {
        local from = 100
        local to = 19000
    }

    gegen id = group(groupstr groupsub)   if rsort < 0 in `from' / `to'
    gegen double mean    = mean   (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) verbose benchmark `options'
    gegen double sum     = sum    (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options'
    gegen double median  = median (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options'
    gegen double sd      = sd     (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options'
    gegen double iqr     = iqr    (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options'
    gegen double first   = first  (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options' v b
    gegen double last    = last   (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options'
    gegen double firstnm = firstnm(rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options'
    gegen double lastnm  = lastnm (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options'
    gegen double q10     = pctile (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options' p(10.5)
    gegen double q30     = pctile (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options' p(30)
    gegen double q70     = pctile (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options' p(70)
    gegen double q90     = pctile (rnorm) if rsort < 0 in `from' / `to',  by(groupstr groupsub) `options' p(90.5)

    keep if rsort < 0 in `from' / `to'
    gcollapse (mean)    g_mean    = rnorm  ///
              (sum)     g_sum     = rnorm  ///
              (median)  g_median  = rnorm  ///
              (sd)      g_sd      = rnorm  ///
              (iqr)     g_iqr     = rnorm  ///
              (first)   g_first   = rnorm  ///
              (last)    g_last    = rnorm  ///
              (firstnm) g_firstnm = rnorm  ///
              (lastnm)  g_lastnm  = rnorm  ///
              (p10.5)   g_q10     = rnorm  ///
              (p30)     g_q30     = rnorm  ///
              (p70)     g_q70     = rnorm  ///
              (p90.5)   g_q90     = rnorm, by(id) benchmark verbose `options' merge double

    foreach fun in mean sum median sd iqr first last firstnm lastnm q10 q30 q70 q90 {
        cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
        if ( _rc ) {
            recast double g_`fun' `fun'
            cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
            if ( _rc ) {
                di as err "`fun' vs gcollapse (if in) failed! (tol = `tol')"
                exit _rc
            }
        }
        else di as txt "    `fun' vs gcollapse (if in) was OK"
    }

    di ""
    di as txt "Passed! checks_options_gegen `options'"
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
    replace groupstr = "i am a modestly long string" + groupstr

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
    syntax anything, by(str) [kvars(int 5) stats(str) kmin(int 4) kmax(int 7) *]
    if ("`stats'" == "") local stats sum

    local collapse ""
    foreach stat of local stats {
        local collapse `collapse' (`stat')
        foreach var of local anything {
            local collapse `collapse' `stat'_`var' = `var'
        }
    }

    * First set of benchmarks: default vs collapse, fcollapse
    * -------------------------------------------------------

    local i = 0
    local N ""
    di "Benchmarking N for J = 100; by(`by')"
    di "    vars  = `anything'"
    di "    stats = `stats'"
    forvalues k = `kmin' / `kmax' {
        mata: printf("    `:di %21.0gc `:di 2 * 10^`k'''")
        local N `N' `:di %21.0g 2 * 10^`k''
        qui bench_sim_ftools `:di %21.0g 2 * 10^`k'' `kvars'
        preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" gcollapse ")
                qui gcollapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" collapse ")
                qui collapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" fcollapse ")
                qui fcollapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'')\n")
        restore
    }

    local i = 1
    di "Results varying N for J = 100; by(`by')"
    di "|              N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |"
    di "| -------------- | --------- | --------- | --------- | ----------- | ----------- |"
    foreach nn in `N' {
        local ii  = `i' + 1
        local iii = `i' + 2
        di "| `:di %14.0gc `nn'' | `:di %9.2f `r`i''' | `:di %9.2f `r`ii''' | `:di %9.2f `r`iii''' | `:di %11.2f `r`iii'' / `r`i''' | `:di %11.2f `r`ii'' / `r`i''' |"
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
    syntax anything, by(str) [nj(int 10) pct(str) stats(str) kmin(int 4) kmax(int 7) *]
    * NOTE: sometimes, fcollapse can't do sd
    if ("`stats'" == "") local stats sum mean max min count percent first last firstnm lastnm
    local stats `stats' `pct'

    local collapse ""
    foreach stat of local stats {
        local collapse `collapse' (`stat')
        foreach var of local anything {
            local collapse `collapse' `stat'_`var' = `var'
        }
    }

    * First set of benchmarks: default vs collapse, fcollapse
    * -------------------------------------------------------

    local i = 0
    local N ""
    di "Benchmarking N for J = `nj'; by(`by')"
    di "    vars  = `anything'"
    di "    stats = `stats'"
    forvalues k = `kmin' / `kmax' {
        mata: printf("    `:di %21.0gc `:di 2 * 10^`k'''")
        local N `N' `:di %21.0g 2 * 10^`k''
        qui bench_sim, n(`:di %21.0g 2 * 10^`k'') nj(`nj') njsub(2) nvars(2)
        preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" gcollapse ")
                qui gcollapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" collapse ")
                qui collapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" fcollapse ")
                qui fcollapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'')\n")
        restore
    }

    local i = 1
    di "Results varying N for J = `nj'; by(`by')"
    di "|              N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |"
    di "| -------------- | --------- | --------- | --------- | ----------- | ----------- |"
    foreach nn in `N' {
        local ii  = `i' + 1
        local iii = `i' + 2
        di "| `:di %14.0gc `nn'' | `:di %9.2f `r`i''' | `:di %9.2f `r`ii''' | `:di %9.2f `r`iii''' | `:di %11.2f `r`iii'' / `r`i''' | `:di %11.2f `r`ii'' / `r`i''' |"
        local ++i
        local ++i
        local ++i
    }
    timer clear
end

capture program drop bench_group_size
program bench_group_size
    syntax anything, by(str) [pct(str) stats(str) obsexp(int 6) kmin(int 1) kmax(int 6) *]
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

    * First set of benchmarks: default vs collapse, fcollapse
    * -------------------------------------------------------

    local nstr = trim("`:di %21.0gc `:di 5 * 10^`obsexp'''")
    local i = 0
    local N ""
    di "Benchmarking J for N = `nstr'; by(`by')"
    di "    vars  = `anything'"
    di "    stats = `stats'"
    forvalues k = `kmin' / `kmax' {
        mata: printf("    `:di %21.0gc `:di 10^`k'''")
        local N `N' `:di %21.0g 10^`k''
        qui bench_sim, n(`:di %21.0g 5 * 10^`obsexp'') nj(`:di %21.0g 10^`k'') njsub(2) nvars(2)
        preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" gcollapse ")
                qui gcollapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" collapse ")
                qui collapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" fcollapse ")
                qui fcollapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'')\n")
        restore
    }

    local i = 1
    di "Results varying J for N = `nstr'; by(`by')"
    di "|              J | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |"
    di "| -------------- | --------- | --------- | --------- | ----------- | ----------- |"
    foreach nn in `N' {
        local ii  = `i' + 1
        local iii = `i' + 2
        di "| `:di %14.0gc `nn'' | `:di %9.2f `r`i''' | `:di %9.2f `r`ii''' | `:di %9.2f `r`iii''' | `:di %11.2f `r`iii'' / `r`i''' | `:di %11.2f `r`ii'' / `r`i''' |"
        local ++i
        local ++i
        local ++i
    }
    timer clear
end

***********************************************************************
*                      Benchmark fcollapse only                       *
***********************************************************************

capture program drop bench_switch_fcoll
program bench_switch_fcoll
    syntax anything, style(str) [*]
    if !inlist("`style'", "ftools", "gtools") {
        di as error "Don't know benchmark style '`style''; available: ftools, gtools"
        exit 198
    }

    local 0 `anything', `options'
    if ( "`style'" == "ftools" ) {
        syntax anything, by(str) [kvars(int 5) stats(str) kmin(int 4) kmax(int 7) *]
        if ("`stats'" == "") local stats sum
        local i = 0
        local N ""
        local L N
        local dstr J = 100
        di "Benchmarking `L' for `dstr'; by(`by')"
        di "    vars  = `anything'"
        di "    stats = `stats'"

        mata: print_matrix = J(1, 0, "")
        mata: sim_matrix   = J(1, 0, "")
        forvalues k = `kmin' / `kmax' {
            mata: print_matrix = print_matrix, "    `:di %21.0gc `:di 2 * 10^`k'''"
            mata: sim_matrix   = sim_matrix,   "bench_sim_ftools `:di %21.0g 2 * 10^`k'' `kvars'"
            local N `N' `:di %21.0g 2 * 10^`k''
        }
    }
    else {
        * syntax anything, by(str) [margin(str) nj(int 10) pct(str) stats(str) obsexp(int 6) kmin(int 1) kmax(int 6) *]
        syntax anything, by(str) [margin(str) nj(int 10) pct(str) stats(str) obsexp(int 6) kmin(int 4) kmax(int 7) nvars(int 2) *]
        if !inlist("`margin'", "N", "J") {
            di as error "Don't know margin '`margin''; available: N, J"
            exit 198
        }

        if ("`stats'" == "") local stats sum mean max min count percent first last firstnm lastnm
        local stats `stats' `pct'
        local i = 0
        local N ""
        local L `margin'
        local jstr = trim("`:di %21.0gc `nj''")
        local nstr = trim("`:di %21.0gc `:di 5 * 10^`obsexp'''")
        local dstr = cond("`L'" == "N", "J = `jstr'", "N = `nstr'")
        di "Benchmarking `L' for `dstr'; by(`by')"
        di "    vars  = `anything'"
        di "    stats = `stats'"

        mata: print_matrix = J(1, 0, "")
        mata: sim_matrix   = J(1, 0, "")
        forvalues k = `kmin' / `kmax' {
            if ( "`L'" == "N" ) {
                mata: print_matrix = print_matrix, "    `:di %21.0gc `:di 2 * 10^`k'''"
                mata: sim_matrix   = sim_matrix, "bench_sim, n(`:di %21.0g 2 * 10^`k'') nj(`nj') njsub(2) nvars(`nvars')"
            }
            else {
                mata: print_matrix = print_matrix, "    `:di %21.0gc `:di 10^`k'''"
                mata: sim_matrix   = sim_matrix, "bench_sim, n(`:di %21.0g 5 * 10^`obsexp'') nj(`:di %21.0g 10^`k'') njsub(2) nvars(`nvars')"
            }
            local J `J' `:di %21.0g 10^`k''
            local N `N' `:di %21.0g 2 * 10^`k''
        }
    }

    local collapse ""
    foreach stat of local stats {
        local collapse `collapse' (`stat')
        foreach var of local anything {
            local collapse `collapse' `stat'_`var' = `var'
        }
    }

    forvalues k = 1 / `:di `kmax' - `kmin' + 1' {
        mata: st_local("sim",   sim_matrix[`k'])
        qui `sim'
        mata: printf(print_matrix[`k'])
        preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" gcollapse-default ")
                qui gcollapse `collapse', by(`by') `options' fast
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" fcollapse ")
                qui fcollapse `collapse', by(`by') fast
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') \n")
        restore
    }

    local i = 1
    di "Results varying `L' for `dstr'; by(`by')"
    di "|              `L' | gcollapse | fcollapse | ratio (f/g) |"
    di "| -------------- | --------- | --------- | ----------- |"
    foreach nn in ``L'' {
        local ii  = `i' + 1
        di "| `:di %14.0gc `nn'' | `:di %9.2f `r`i''' | `:di %9.2f `r`ii''' | `:di %11.2f `r`ii'' / `r`i''' |"
        local ++i
        local ++i
    }
    timer clear
end

* Benchmarks in the README
* ------------------------

* bench_ftools y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(4) kmax(7) kvars(15)
* bench_ftools y1 y2 y3,   by(x3) kmin(4) kmax(7) kvars(3) stats(mean median)
* bench_ftools y1 y2 y3 y4 y5 y6 y7 y8 y9 y10, by(x3) kmin(4) kmax(7) kvars(10) stats(mean median min max)
* bench_sample_size x1 x2, by(groupstr) kmin(4) kmax(7) pct(median iqr p23 p77)
* bench_group_size x1 x2,  by(groupstr) kmin(1) kmax(6) pct(median iqr p23 p77) obsexp(6) 

* Misc
* ----

* bench_ftools y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(5) kmax(8) kvars(15)
* bench_ftools y1 y2 y3,   by(x3) kmin(5) kmax(8) kvars(3) stats(mean median)
* bench_ftools y1 y2 y3 y4 y5 y6 y7 y8 y9 y10, by(x3) kmin(5) kmax(8) kvars(10) stats(mean median min max)
* bench_sample_size x1 x2, by(groupstr) kmin(5) kmax(8) pct(median iqr p23 p77)
* bench_group_size x1 x2,  by(groupstr) kmin(1) kmax(7) pct(median iqr p23 p77) obsexp(7)

* ---------------------------------------------------------------------
* Run the things

main, cap noi checks test
