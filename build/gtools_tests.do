* ---------------------------------------------------------------------
* Project: gtools
* Program: gtools_tests.do
* Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
* Created: Tue May 16 07:23:02 EDT 2017
* Updated: Sat Sep 30 22:21:18 EDT 2017
* Purpose: Unit tests for gtools
* Version: 0.6.21
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
ssc install ralpha

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
        * do test_hashsort.do
        * do test_gisid.do
        * do test_glevelsof.do
        * do bench_gcollapse.do

        if ( `:list posof "checks" in options' ) {

            di ""
            di "-------------------------------------"
            di "Basic unit-tests $S_TIME $S_DATE"
            di "-------------------------------------"

            unit_test, `noisily' test(checks_corners, oncollision(error) debug_force_single)

            unit_test, `noisily' test(checks_byvars_gcollapse,  oncollision(error) debug_force_single)
            unit_test, `noisily' test(checks_byvars_gcollapse,  oncollision(error) debug_force_single forceio debug_io_read_method(0))
            unit_test, `noisily' test(checks_byvars_gcollapse,  oncollision(error) debug_force_single forceio debug_io_read_method(1))

            unit_test, `noisily' test(checks_options_gcollapse, oncollision(error) debug_force_single)
            unit_test, `noisily' test(checks_options_gcollapse, oncollision(error) debug_force_single debug_io_read_method(0))
            unit_test, `noisily' test(checks_options_gcollapse, oncollision(error) debug_force_single debug_io_read_method(1))

            if !inlist("`c(os)'", "Windows") {
                unit_test, `noisily' test(checks_corners, oncollision(error) debug_force_multi)

                unit_test, `noisily' test(checks_byvars_gcollapse,  oncollision(error) debug_force_multi)
                unit_test, `noisily' test(checks_byvars_gcollapse,  oncollision(error) debug_force_multi forceio debug_io_read_method(0))
                unit_test, `noisily' test(checks_byvars_gcollapse,  oncollision(error) debug_force_multi forceio debug_io_read_method(1))

                unit_test, `noisily' test(checks_options_gcollapse, oncollision(error) debug_force_multi)
                unit_test, `noisily' test(checks_options_gcollapse, oncollision(error) debug_force_multi debug_io_read_method(0))
                unit_test, `noisily' test(checks_options_gcollapse, oncollision(error) debug_force_multi debug_io_read_method(1))
            }

            di ""
            di "-----------------------------------------------------------"
            di "Consistency checks (vs collapse, egen) $S_TIME $S_DATE"
            di "-----------------------------------------------------------"

            consistency_gcollapse,       `noisily' oncollision(error) debug_force_single
            consistency_gcollapse,       `noisily' oncollision(error) debug_force_single forceio debug_io_read_method(0)
            consistency_gcollapse,       `noisily' oncollision(error) debug_force_single forceio debug_io_read_method(1)
            consistency_gcollapse,       `noisily' oncollision(error) debug_force_single debug_io_check(1) debug_io_threshold(0.1)
            consistency_gcollapse,       `noisily' oncollision(error) debug_force_single debug_io_check(1) debug_io_threshold(1000000)
            consistency_gegen,           `noisily' oncollision(error) debug_force_single
            consistency_gegen_gcollapse, `noisily' oncollision(error) debug_force_single

            if !inlist("`c(os)'", "Windows") {
                consistency_gcollapse,       `noisily' oncollision(error) debug_force_multi
                consistency_gcollapse,       `noisily' oncollision(error) debug_force_multi forceio debug_io_read_method(0)
                consistency_gcollapse,       `noisily' oncollision(error) debug_force_multi forceio debug_io_read_method(1)
                consistency_gcollapse,       `noisily' oncollision(error) debug_force_multi debug_io_check(1) debug_io_threshold(0.1)
                consistency_gcollapse,       `noisily' oncollision(error) debug_force_multi debug_io_check(1) debug_io_threshold(1000000)
                consistency_gegen,           `noisily' oncollision(error) debug_force_multi
                consistency_gegen_gcollapse, `noisily' oncollision(error) debug_force_multi
            }

            di ""
            di "--------------------------------"
            di "Check extra $S_TIME $S_DATE"     
            di "--------------------------------"

            unit_test, `noisily' test(checks_hashsort, `noisily' oncollision(error))
            unit_test, `noisily' test(checks_isid,     `noisily' oncollision(error))
            unit_test, `noisily' test(checks_levelsof, `noisily' oncollision(error))

            compare_isid,     `noisily' oncollision(error)
            compare_levelsof, `noisily' oncollision(error)
            compare_hashsort, `noisily' oncollision(error)
        }

        if ( `:list posof "bench_gtools" in options' ) {
            bench_switch_fcoll y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(4) kmax(7) kvars(15) style(ftools) gcoll(debug_force_single)
            bench_switch_fcoll y1 y2 y3,          by(x3)  kmin(4) kmax(7) kvars(3) stats(mean median)               style(ftools) gcoll(debug_force_single)
            bench_switch_fcoll y1 y2 y3 y4 y5 y6, by(x3)  kmin(4) kmax(7) kvars(6) stats(sum mean count min max)    style(ftools) gcoll(debug_force_single)
            bench_switch_fcoll x1 x2, margin(N) by(group) kmin(4) kmax(7) pct(median iqr p23 p77)                   style(gtools) gcoll(debug_force_single)
            bench_switch_fcoll x1 x2, margin(J) by(group) kmin(1) kmax(6) pct(median iqr p23 p77) obsexp(6)         style(gtools) gcoll(debug_force_single)
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

            bench_ftools y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(5) kmax(7) kvars(15)
            bench_ftools y1 y2 y3,             by(x3)    kmin(5) kmax(7) kvars(3) stats(mean median)
            bench_ftools y1 y2 y3 y4 y5 y6,    by(x3)    kmin(5) kmax(7) kvars(6) stats(sum mean count min max)
            bench_sample_size x1 x2, margin(N) by(group) kmin(5) kmax(7) pct(median iqr p23 p77)
            bench_group_size  x1 x2, margin(J) by(group) kmin(4) kmax(6) pct(median iqr p23 p77) obsexp(6)
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

        if ( `:list posof "bench_extra" in options' ) {
            compare_hashsort, bench(10)
            bench_levelsof,   bench(10)
            bench_isid,       bench(10)
            bench_egen,       bench(10)
        }
    }
    local rc = _rc

    exit_message, rc(`rc') progname(`progname') start_time(`start_time') `capture'
    exit `rc'
end

* ---------------------------------------------------------------------
* Aux programs

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

capture program drop unit_test
program unit_test
    syntax, test(str) [NOIsily tab(int 4)]
    local tabs `""'
    forvalues i = 1 / `tab' {
        local tabs "`tabs' "
    }
    cap `noisily' `test'
    if ( _rc ) {
        di as error `"`tabs'test(failed): `test'"'
        exit _rc
    }
    else di as txt `"`tabs'test(passed): `test'"'
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
        if ( "`sortg'"     == "" ) sort rsort
        if ( "`groupmiss'" != "" ) replace group = . if runiform() < 0.1
        if ( "`outmiss'"   != "" ) replace rsort = . if runiform() < 0.1
        if ( "`outmiss'"   != "" ) replace rnorm = . if runiform() < 0.1
        if ( "`float'"     != "" ) replace group = group / `nj'
        if ( "`string'" != "" ) {
            tostring group,    `:di cond("`replace'" == "", "gen(groupstr)",    "replace")'
            tostring groupsub, `:di cond("`replace'" == "", "gen(groupsubstr)", "replace")'
            if ( "`replace'" == "replace" ) {
                replace group    = "" if group    == "."
                replace groupsub = "" if groupsub == "."
            }
            else {
                replace groupstr    = "" if mi(group)
                replace groupsubstr = "" if mi(groupsub)
            }
            local target `:di cond("`replace'" == "", "groupstr", "group")'
            replace `target' = "i am a modesly long string" + `target' if !mi(`target')
            local target `:di cond("`replace'" == "", "groupstr", "group")'
            replace `target' = "ss" + `target' if !mi(`target')
        }
        gen long grouplong = ceil(`nj' *  _n / _N) + `offset'
    }
    qui sum rsort
    di "Obs = " trim("`:di %21.0gc _N'") "; Groups = " trim("`:di %21.0gc `nj''")
    compress
    return local n  = `n'
    return local nj = `nj'
    return local offset = `offset'
    return local string = ("`string'" != "")
end

* ---------------------------------------------------------------------
capture program drop consistency_gcollapse
program consistency_gcollapse
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "consistency_gcollapse, `options'" _n(1) "{hline 80}" _n(1)

    local stats sum mean sd max min count percent first last firstnm lastnm median iqr
    local percentiles p1 p13 p30 p50 p70 p87 p99
    local collapse_str ""
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') `stat' = rnorm
    }
    foreach pct of local percentiles {
        local collapse_str `collapse_str' (`pct') `pct' = rnorm
    }

    qui sim, n(50000) nj(8) njsub(4) string groupmiss outmiss float
    mytimer 9
    qui `noisily' foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by groupsub groupstr
        if ( `i' == 3 ) local by groupstr groupsubstr 
        if ( `i' == 6 ) local by groupsub group
        if ( `i' == 9 ) local by grouplong
    preserve
        mytimer 9 info
        gcollapse `collapse_str', by(`by') verbose benchmark `options'
        mytimer 9 info "gcollapse to groups"
        tempfile f`i'
        save `f`i''
    restore, preserve
        mytimer 9 info
        collapse `collapse_str', by(`by')
        mytimer 9 info "collapse to groups"
        tempfile f`:di `i' + 2'
        save `f`:di `i' + 2''
    restore
    }
    mytimer 9 off

    qui sim, n(50000) nj(8000) njsub(4) string groupmiss outmiss
    qui `noisily' foreach i in 12 15 18 21 {
        if (`i' == 12) local by groupsub groupstr
        if (`i' == 15) local by groupstr
        if (`i' == 18) local by groupsub group
        if (`i' == 21) local by grouplong
    preserve
        mytimer 9 info
        gcollapse `collapse_str', by(`by') verbose benchmark `options'
        mytimer 9 info "gcollapse to groups"
        tempfile f`i'
        save `f`i''
    restore, preserve
        mytimer 9 info
        collapse `collapse_str', by(`by')
        mytimer 9 info "collapse to groups"
        tempfile f`:di `i' + 2'
        save `f`:di `i' + 2''
    restore
    }

    qui sim, n(50000) nj(8000) njsub(4) string groupmiss outmiss
    qui `noisily' foreach i in 24 27 30 33 {
        if (`i' == 24) local by groupsub groupstr
        if (`i' == 27) local by groupstr
        if (`i' == 30) local by groupsub group
        if (`i' == 33) local by grouplong
        local in1  = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2  = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        local ifin if rsort < 0 in `from' / `to'
        qui count `ifin'
        if (`r(N)' == 0) {
            local in1  = ceil(runiform() * 10)
            local in2  = ceil(`=_N' - runiform() * 10)
            local from = cond(`in1' < `in2', `in1', `in2')
            local to   = cond(`in1' > `in2', `in1', `in2')
            local ifin if rsort < 0 in `from' / `to'
        }
    preserve
        mytimer 9 info
        gcollapse `collapse_str' `ifin', by(`by') verbose benchmark `options'
        mytimer 9 info "gcollapse to groups"
        tempfile f`i'
        save `f`i''
    restore, preserve
        mytimer 9 info
        collapse `collapse_str' `ifin', by(`by')
        mytimer 9 info "collapse to groups"
        tempfile f`:di `i' + 2'
        save `f`:di `i' + 2''
    restore
    }

    foreach i in 0 3 6 9 12 15 18 21 24 27 30 33 {
    preserve
    use `f`:di `i' + 2'', clear
        local bad_any = 0
        if (`i' == 0  ) local bad groupsub groupstr
        if (`i' == 3  ) local bad groupstr groupsubstr 
        if (`i' == 6  ) local bad groupsub group
        if (`i' == 9  ) local bad grouplong
        if (`i' == 12 ) local bad groupsub groupstr
        if (`i' == 15 ) local bad groupstr
        if (`i' == 18 ) local bad groupsub group
        if (`i' == 21 ) local bad grouplong
        if (`i' == 24 ) local bad groupsub groupstr
        if (`i' == 27 ) local bad groupstr
        if (`i' == 30 ) local bad groupsub group
        if (`i' == 33 ) local bad grouplong
        if ( `i' == 0 ) {
            di _n(1) "Comparing collapse for N = 50,000 with J1 = 8 and J2 = 4"
        }
        if ( `i' == 12 ) {
            di _n(1) "Comparing collapse for N = 50,000 with J1 = 8,000 and J2 = 4"
        }
        if ( `i' == 24 ) {
            di _n(1) "Comparing collapse for N = 50,000 with J1 = 8,000 and J2 = 4 (if in)"
        }
        local by `bad'
        foreach var in `stats' `percentiles' {
            rename `var' c_`var'
        }
        qui merge 1:1 `by' using `f`i'', assert(3)
        foreach var in `stats' `percentiles' {
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
            di "    compare_collapse (passed): gcollapse results equal to collapse (tol = `tol', `by')"
        }
    restore
    }
end

capture program drop checks_byvars_gcollapse
program checks_byvars_gcollapse
    syntax, [*]
    di _n(1) "{hline 80}" _n(1) "checks_byvars_gcollapse `options'" _n(1) "{hline 80}" _n(1)

    sim, n(1000) nj(250) string

    set rmsg on
    preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, verbose `options' by(groupstr)
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, verbose `options' by(group)
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, verbose `options' by(groupsub)
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, verbose `options' by(grouplong)
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, verbose `options' by(groupsub)
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, verbose `options' by(group groupsub)
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, verbose `options' by(grouplong groupsub)
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, verbose `options' by(groupstr groupsub)
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
        gcollapse `collapse_str', by(groupstr) verbose benchmark cw `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark fast `options'
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

    preserve
        gcollapse `collapse_str', verbose benchmark `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse rnorm (mean) mean_rnorm = rnorm, by(groupstr groupsub) verbose benchmark `options'
        assert rnorm == mean_rnorm
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse rnorm, verbose benchmark `options'
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

capture program drop checks_corners
program checks_corners
    syntax, [*]
    di _n(1) "{hline 80}" _n(1) "checks_corners `options'" _n(1) "{hline 80}" _n(1)

    qui {
        sysuse auto, clear
        gen price2 = price
        gcollapse price = price2, by(make)
        gcollapse price in 1, by(make)
    }

    qui {
        clear
        set matsize 100
        set obs 10
        forvalues i = 1/101 {
            gen x`i' = 10
        }
        gen zz = runiform()
        preserve
            gcollapse zz, by(x*) `options'
        restore, preserve
            gcollapse x*, by(zz) `options'
        restore
    }

    qui {
        clear
        set matsize 400
        set obs 10
        forvalues i = 1/300 {
            gen x`i' = 10
        }
        gen zz = runiform()
        preserve
            gcollapse zz, by(x*) `options'
        restore, preserve
            gcollapse x*, by(zz) `options'
        restore
    }

    qui {
        clear
        set obs 10
        forvalues i = 1/800 {
            gen x`i' = 10
        }
        gen zz = runiform()
        preserve
            gcollapse zz, by(x*) `options'
        restore, preserve
            gcollapse x*, by(zz) `options'
        restore

        * Only fails in Stata/IC
        * gen x801 = 10
        * preserve
        *     collapse zz, by(x*) `options'
        * restore, preserve
        *     collapse x*, by(zz) `options'
        * restore
    }

    di ""
    di as txt "Passed! checks_corners `options'"
end
capture program drop consistency_gegen
program consistency_gegen
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "consistency_gegen, `options'" _n(1) "{hline 80}" _n(1)

    local stats total sum mean sd max min count median iqr
    local percentiles 1 10 30 50 70 90 99
    qui `noisily' sim, n(500000) nj(10000) njsub(4) string groupmiss outmiss

    cap drop g*_*
    cap drop c*_*
    di _n(1) "Checking full egen range"
    foreach fun of local stats {
        qui `noisily' gegen g_`fun' = `fun'(rnorm), by(groupstr groupsub) `options'
        qui `noisily'  egen c_`fun' = `fun'(rnorm), by(groupstr groupsub)
        cap noi assert (g_`fun' == c_`fun') | abs(g_`fun' - c_`fun') < `tol'
        if ( _rc ) {
            di as err "    compare_egen (failed): gegen `fun' not equal to egen (tol = `tol')"
            exit _rc
        }
        else di as txt "    compare_egen (passed): gegen `fun' results similar to egen (tol = `tol')"

    }

    foreach p in `percentiles' {
        qui  `noisily' gegen g_p`p' = pctile(rnorm), by(groupstr groupsub) p(`p') `options'
        qui  `noisily'  egen c_p`p' = pctile(rnorm), by(groupstr groupsub) p(`p')
        cap noi assert (g_p`p' == c_p`p') | abs(g_p`p' - c_p`p') < `tol'
        if ( _rc ) {
            di as err "    compare_egen (failed): gegen percentile `p' not equal to egen (tol = `tol')"
            exit _rc
        }
        else di as txt "    compare_egen (passed): gegen percentile `p' results similar to egen (tol = `tol')"
    }

    foreach fun in tag group {
        qui  `noisily' gegen g_`fun' = `fun'(groupstr groupsub), v `options'
        qui  `noisily'  egen c_`fun' = `fun'(groupstr groupsub)
        cap noi assert (g_`fun' == c_`fun') | abs(g_`fun' - c_`fun') < `tol'
        if ( _rc ) {
            di as err "    compare_egen (failed): gegen `fun' not equal to egen (tol = `tol')"
            exit _rc
        }
        else di as txt "    compare_egen (passed): gegen `fun' results similar to egen (tol = `tol')"
    }

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    cap drop g*_*
    cap drop c*_*
    di "Checking egen if range"
    foreach fun of local stats {
        qui  `noisily' gegen gif_`fun' = `fun'(rnorm) if rsort > 0, by(groupstr groupsub) `options'
        qui  `noisily'  egen cif_`fun' = `fun'(rnorm) if rsort > 0, by(groupstr groupsub)
        cap noi assert (gif_`fun' == cif_`fun') | abs(gif_`fun' - cif_`fun') < `tol'
        if ( _rc ) {
            di as err "    compare_egen_if (failed): gegen `fun' not equal to egen (tol = `tol')"
            exit _rc
        }
        else di as txt "    compare_egen_if (passed): gegen `fun' results similar to egen (tol = `tol')"
    }

    foreach p in `percentiles' {
        qui  `noisily' gegen g_p`p' = pctile(rnorm) if rsort > 0, by(groupstr groupsub) p(`p') `options'
        qui  `noisily'  egen c_p`p' = pctile(rnorm) if rsort > 0, by(groupstr groupsub) p(`p')
        cap noi assert (g_p`p' == c_p`p') | abs(g_p`p' - c_p`p') < `tol'
        if ( _rc ) {
            di as err "    compare_egen_if (failed): gegen percentile `p' not equal to egen (tol = `tol')"
            exit _rc
        }
        else di as txt "    compare_egen_if (passed): gegen percentile `p' results similar to egen (tol = `tol')"
    }

    foreach fun in tag group {
        qui  `noisily' gegen gif_`fun' = `fun'(groupstr groupsub) if rsort > 0, v `options'
        qui  `noisily'  egen cif_`fun' = `fun'(groupstr groupsub) if rsort > 0
        cap noi assert (gif_`fun' == cif_`fun') | abs(gif_`fun' - cif_`fun') < `tol'
        if ( _rc ) {
            di as err "    compare_egen_if (failed): gegen `fun' not equal to egen (tol = `tol')"
            exit _rc
        }
        else di as txt "    compare_egen_if (passed): gegen `fun' results similar to egen (tol = `tol')"
    }

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    cap drop g*_*
    cap drop c*_*
    di "Checking egen in range"
    foreach fun of local stats {
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui  `noisily' gegen gin_`fun' = `fun'(rnorm) in `from' / `to', by(groupstr groupsub) `options'
        qui  `noisily'  egen cin_`fun' = `fun'(rnorm) in `from' / `to', by(groupstr groupsub)
        cap noi assert (gin_`fun' == cin_`fun') | abs(gin_`fun' - cin_`fun') < `tol'
        if ( _rc ) {
            di as err "    compare_egen_in (failed): gegen `fun' not equal to egen (tol = `tol')"
            exit _rc
        }
        else di as txt "    compare_egen_in (passed): gegen `fun' results similar to egen (tol = `tol')"
    }

    foreach p in `percentiles' {
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui  `noisily' gegen g_p`p' = pctile(rnorm) in `from' / `to', by(groupstr groupsub) p(`p') `options'
        qui  `noisily'  egen c_p`p' = pctile(rnorm) in `from' / `to', by(groupstr groupsub) p(`p')
        cap noi assert (g_p`p' == c_p`p') | abs(g_p`p' - c_p`p') < `tol'
        if ( _rc ) {
            di as err "    compare_egen_in (failed): gegen percentile `p' not equal to egen (tol = `tol')"
            exit _rc
        }
        else di as txt "    compare_egen_in (passed): gegen percentile `p' results similar to egen (tol = `tol')"
    }

    foreach fun in tag group {
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui  `noisily' gegen gin_`fun' = `fun'(groupstr groupsub) in `from' / `to', v b `options'
        qui  `noisily'  egen cin_`fun' = `fun'(groupstr groupsub) in `from' / `to'
        cap noi assert (gin_`fun' == cin_`fun') | abs(gin_`fun' - cin_`fun') < `tol'
        if ( _rc ) {
            di as err "    compare_egen_in (failed): gegen `fun' not equal to egen (tol = `tol')"
            exit _rc
        }
        else di as txt "    compare_egen_in (passed): gegen `fun' results similar to egen (tol = `tol')"
    }

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    cap drop g*_*
    cap drop c*_*
    di "Checking egen if in range"
    foreach fun of local stats {
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui  `noisily' gegen gifin_`fun' = `fun'(rnorm) if rsort < 0 in `from' / `to', by(groupstr groupsub) `options'
        qui  `noisily'  egen cifin_`fun' = `fun'(rnorm) if rsort < 0 in `from' / `to', by(groupstr groupsub)
        cap noi assert (gifin_`fun' == cifin_`fun') | abs(gifin_`fun' - cifin_`fun') < `tol'
        if ( _rc ) {
            di as err "    compare_egen_ifin (failed): gegen `fun' not equal to egen (tol = `tol')"
            exit _rc
        }
        else di as txt "    compare_egen_ifin (passed): gegen `fun' results similar to egen (tol = `tol')"
    }

    foreach p in `percentiles' {
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui  `noisily' gegen g_p`p' = pctile(rnorm) if rsort < 0 in `from' / `to', by(groupstr groupsub) p(`p') `options'
        qui  `noisily'  egen c_p`p' = pctile(rnorm) if rsort < 0 in `from' / `to', by(groupstr groupsub) p(`p')
        cap noi assert (g_p`p' == c_p`p') | abs(g_p`p' - c_p`p') < `tol'
        if ( _rc ) {
            di as err "    compare_egen_ifin (failed): gegen percentile `p' not equal to egen (tol = `tol')"
            exit _rc
        }
        else di as txt "    compare_egen_ifin (passed): gegen percentile `p' results similar to egen (tol = `tol')"
    }

    foreach fun in tag group {
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui  `noisily' gegen gifin_`fun' = `fun'(groupstr groupsub) if rsort < 0 in `from' / `to', v `options'
        qui  `noisily'  egen cifin_`fun' = `fun'(groupstr groupsub) if rsort < 0 in `from' / `to'
        cap noi assert (gifin_`fun' == cifin_`fun') | abs(gifin_`fun' - cifin_`fun') < `tol'
        if ( _rc ) {
            di as err "    compare_egen_ifin (failed): gegen `fun' not equal to egen (tol = `tol')"
            exit _rc
        }
        else di as txt "    compare_egen_ifin (passed): gegen `fun' results similar to egen (tol = `tol')"
    }
end

capture program drop consistency_gegen_gcollapse
program consistency_gegen_gcollapse
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "consistency_gegen_gcollapse, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' {
        sim, n(20000) nj(100) njsub(2) string outmiss
        gegen id = group(groupstr groupsub), `options'
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
    }

    di _n(1) "Checking gegen vs gcollapse full range"
    foreach fun in mean sum median sd iqr first last firstnm lastnm q10 q30 q70 q90 {
        cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
        if ( _rc ) {
            recast double g_`fun' `fun'
            cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
            if ( _rc ) {
                di as err "    compare_gegen_gcollapse (failed): `fun' yielded different results (tol = `tol')"
                exit _rc
            }
            else di as txt "    compare_gegen_gcollapse (passed): `fun' yielded same results (tol = `tol')"
        }
        else di as txt "    compare_gegen_gcollapse (passed): `fun' yielded same results (tol = `tol')"
    }

    qui `noisily' {
        sim, n(20000) nj(100) njsub(2) string outmiss

        local in1  = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2  = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui count if rsort < 0 in `from' / `to'
        if ( `r(N)' == 0 ) {
            local in1  = ceil(runiform() * 10)
            local in2  = ceil(`=_N' - runiform() * 10)
            local from = cond(`in1' < `in2', `in1', `in2')
            local to   = cond(`in1' > `in2', `in1', `in2')
        }

        gegen id = group(groupstr groupsub) in `from' / `to', `options'
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
    }

    di _n(1) "Checking gegen vs gcollapse in range"
    foreach fun in mean sum median sd iqr first last firstnm lastnm q10 q30 q70 q90 {
        cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
        if ( _rc ) {
            recast double g_`fun' `fun'
            cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
            if ( _rc ) {
                di as err "    compare_gegen_gcollapse_in (failed): `fun' yielded different results (tol = `tol')"
                exit _rc
            }
            else di as txt "    compare_gegen_gcollapse_in (passed): `fun' yielded same results (tol = `tol')"
        }
        else di as txt "    compare_gegen_gcollapse_in (passed): `fun' yielded same results (tol = `tol')"
    }

    qui `noisily' {
        sim, n(20000) nj(100) njsub(2) string outmiss

        local in1  = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2  = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        qui count if rsort < 0 in `from' / `to'
        if ( `r(N)' == 0 ) {
            local in1  = ceil(runiform() * 10)
            local in2  = ceil(`=_N' - runiform() * 10)
            local from = cond(`in1' < `in2', `in1', `in2')
            local to   = cond(`in1' > `in2', `in1', `in2')
        }

        gegen id = group(groupstr groupsub)   if rsort < 0 in `from' / `to', `options'
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
    }

    di _n(1) "Checking gegen vs gcollapse if in range"
    foreach fun in mean sum median sd iqr first last firstnm lastnm q10 q30 q70 q90 {
        cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
        if ( _rc ) {
            recast double g_`fun' `fun'
            cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
            if ( _rc ) {
                di as err "    compare_gegen_gcollapse_ifin (failed): `fun' yielded different results (tol = `tol')"
                exit _rc
            }
            else di as txt "    compare_gegen_gcollapse_ifin (passed): `fun' yielded same results (tol = `tol')"
        }
        else di as txt "    compare_gegen_gcollapse_ifin (passed): `fun' yielded same results (tol = `tol')"
    }
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_egen
program bench_egen
    syntax, [tol(real 1e-6) bench(int 1) NOIsily *]

    cap gen_data, n(10000) expand(`=100 * `bench'')
    qui gen rsort = rnormal()
    qui sort rsort

    local N = trim("`: di %15.0gc _N'")

    di _n(1)
    di "Benchmark vs egen, obs = `N', J = 10,000 (in seconds)"
    di "     egen | fegen | gegen | ratio (i/g) | ratio (f/g) | varlist"
    di "     ---- | ----- | ----- | ----------- | ----------- | -------"

    versus_egen str_12,              `options' fegen
    versus_egen str_12 str_32,       `options' fegen
    versus_egen str_12 str_32 str_4, `options' fegen

    versus_egen double1,                 `options' fegen
    versus_egen double1 double2,         `options' fegen
    versus_egen double1 double2 double3, `options' fegen

    versus_egen int1,           `options' fegen
    versus_egen int1 int2,      `options' fegen
    versus_egen int1 int2 int3, `options' fegen

    versus_egen int1 str_32 double1,                                        `options'
    versus_egen int1 str_32 double1 int2 str_12 double2,                    `options'
    versus_egen int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    di _n(1) "{hline 80}" _n(1) "bench_egen, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop gen_data
program gen_data
    syntax, [n(int 100) expand(int 1)]
    clear
    set obs `n'
    qui ralpha str_long,  l(5)
    qui ralpha str_mid,   l(3)
    qui ralpha str_short, l(1)
    gen str32 str_32   = str_long + "this is some string padding"
    gen str12 str_12   = str_mid  + "padding" + str_short + str_short
    gen str4  str_4    = str_mid  + str_short

    gen long int1  = floor(rnormal())
    gen long int2  = floor(uniform() * 1000)
    gen long int3  = floor(rnormal() * 5 + 10)

    gen double double1 = rnormal()
    gen double double2 = uniform() * 1000
    gen double double3 = rnormal() * 5 + 10

    qui expand `expand'
end

capture program drop versus_egen
program versus_egen, rclass
    syntax varlist, [fegen unique *]

    preserve
        timer clear
        timer on 42
        cap egen id = group(`varlist')
        timer off 42
        qui timer list
        local time_egen = r(t42)
    restore

    preserve
        timer clear
        timer on 43
        cap gegen id = group(`varlist'), `options'
        timer off 43
        qui timer list
        local time_gegen = r(t43)
    restore

    if ( "`fegen'" == "fegen" ) {
    preserve
        timer clear
        timer on 44
        cap fegen id = group(`varlist')
        timer off 44
        qui timer list
        local time_fegen = r(t44)
    restore
    }
    else {
        local time_fegen = .
    }

    local rs = `time_egen'  / `time_gegen'
    local rf = `time_fegen' / `time_gegen'
    di "    `:di %5.3g `time_egen'' | `:di %5.3g `time_fegen'' | `:di %5.3g `time_gegen'' | `:di %11.3g `rs'' | `:di %11.3g `rf'' | `varlist'"
end
capture program drop checks_isid
program checks_isid
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "consistency_isid, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' sim, n(5000) nj(100) njsub(4) string groupmiss outmiss
    gen ix = _n

    foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by groupsub groupstr
        if ( `i' == 3 ) local by groupstr groupsubstr 
        if ( `i' == 6 ) local by groupsub group
        if ( `i' == 9 ) local by grouplong
        cap gisid `by', `options' v b missok
        assert _rc == 459

        cap gisid `by' in 1, `options'
        assert _rc == 0

        cap gisid `by' if _n == 1, `options'
        assert _rc == 0

        cap gisid `by' if _n < 10 in 5, `options'
        assert _rc == 0
    }

    clear
    gen x = 1
    cap gisid x
    assert _rc == 0
end

capture program drop compare_isid
program compare_isid
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "consistency_isid, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' sim, n(500000) nj(10000) njsub(4) string groupmiss outmiss
    gen ix = _n

    local i 0
    foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by groupsub groupstr
        if ( `i' == 3 ) local by groupstr groupsubstr 
        if ( `i' == 6 ) local by groupsub group
        if ( `i' == 9 ) local by grouplong
        cap isid `by', missok
        local rc_isid = _rc
        cap gisid `by', missok `options'
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by(`by')
    }

    foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by rsort rnorm groupsub groupstr
        if ( `i' == 3 ) local by rsort rnorm groupstr
        if ( `i' == 6 ) local by rsort rnorm groupsub group
        if ( `i' == 9 ) local by rsort rnorm grouplong
        cap isid `by', missok
        local rc_isid = _rc
        cap gisid `by', missok
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by(`by')
    }

    foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by ix groupsub groupstr
        if ( `i' == 3 ) local by ix groupstr
        if ( `i' == 6 ) local by ix groupsub group
        if ( `i' == 9 ) local by ix grouplong
        cap isid `by', missok
        local rc_isid = _rc
        cap gisid `by', missok `options'
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by(`by')
    }

    qui replace ix = `=_N / 2' if _n > `=_N / 2'
    cap isid ix
    local rc_isid = _rc
    cap gisid ix, `options'
    local rc_gisid = _rc
    check_rc `rc_isid' `rc_gisid' , by(ix)

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by ix groupsub groupstr
        if ( `i' == 3 ) local by ix groupstr
        if ( `i' == 6 ) local by ix groupsub group
        if ( `i' == 9 ) local by ix grouplong

        preserve
            qui keep in 100 / `=ceil(`=_N / 2')'
            cap isid `by', missok
            local rc_isid = _rc
        restore
        cap gisid `by' in 100 / `=ceil(`=_N / 2')', missok `options'
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by( `by' in 100 / `=ceil(`=_N / 2')')

        preserve
            qui keep in `=ceil(`=_N / 2')' / `=_N'
            cap isid `by', missok
            local rc_isid = _rc
        restore
        cap gisid `by' in `=ceil(`=_N / 2')' / `=_N', missok `options'
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by(`by' in `=ceil(`=_N / 2')' / `=_N')

    di _n(1)

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

        preserve
            qui keep if _n < `=_N / 2'
            cap isid `by', missok
            local rc_isid = _rc
        restore
        cap gisid `by' if _n < `=_N / 2', missok
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by(`by' if _n < `=_N / 2')

        preserve
            qui keep if _n > `=_N / 2'
            cap isid `by', missok
            local rc_isid = _rc
        restore
        cap gisid `by' if _n > `=_N / 2', missok `options'
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by(`by' if _n > `=_N / 2')

    di _n(1)

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

        qui replace ix = 100 in 1 / 100

        preserve
            qui keep if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')'
            cap isid `by', missok
            local rc_isid = _rc
        restore
        cap gisid `by' if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')', missok `options'
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by( `by' if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')')

        preserve
            qui keep if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N'
            cap isid `by', missok
            local rc_isid = _rc
        restore
        cap gisid `by' if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N', missok
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by( `by' if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N')

        qui replace ix = _n in 1 / 100
    }
end

capture program drop check_rc
program check_rc
    syntax anything, by(str)

    tokenize `anything'
    local rc_isid  `1'
    local rc_gisid `2'

    if ( `rc_isid' != `rc_gisid' ) {
        if ( `rc_isid' & (`rc_gisid' == 0) ) {
            di as err "    compare_isid (failed): isid `by' was an id but gisid returned error r(`rc_isid')"
            exit `rc_gisid'
        }
        else if ( (`rc_isid' == 0) & `rc_gisid' ) {
            di as err "    compare_isid (failed): gisid `by' was an id but isid returned error r(`rc_gisid')"
            exit `rc_isid'
        }
        else {
            di as err "    compare_isid (failed): `by' was not an id but isid and gisid returned different errors r(`rc_isid') vs r(`rc_gisid')"
            exit `rc_gisid'
        }
    }
    else {
        if ( _rc ) {
            di as txt "    compare_isid (passed): `by' was not an id"
        }
        else {
            di as txt "    compare_isid (passed): `by' was an id"
        }
    }
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_isid
program bench_isid
    syntax, [tol(real 1e-6) bench(int 1) NOIsily *]

    cap gen_data, n(10000) expand(`=100 * `bench'')
    qui gen rsort = rnormal()
    qui sort rsort

    local N = trim("`: di %15.0gc _N'")

    di _n(1)
    di "Benchmark vs isid, obs = `N', all calls include an index to ensure uniqueness (in seconds)"
    di "     isid | fisid | gisid | ratio (i/g) | ratio (f/g) | varlist"
    di "     ---- | ----- | ----- | ----------- | ----------- | -------"

    versus_isid str_12,              `options' fisid unique
    versus_isid str_12 str_32,       `options' fisid unique
    versus_isid str_12 str_32 str_4, `options' fisid unique

    versus_isid double1,                 `options' fisid unique
    versus_isid double1 double2,         `options' fisid unique
    versus_isid double1 double2 double3, `options' fisid unique

    versus_isid int1,           `options' fisid unique
    versus_isid int1 int2,      `options' fisid unique
    versus_isid int1 int2 int3, `options' fisid unique

    versus_isid int1 str_32 double1,                                        unique `options'
    versus_isid int1 str_32 double1 int2 str_12 double2,                    unique `options'
    versus_isid int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, unique `options'

    di _n(1)
    di "Benchmark vs isid, obs = `N', J = 10,000 (in seconds)"
    di "     isid | fisid | gisid | ratio (i/g) | ratio (f/g) | varlist"
    di "     ---- | ----- | ----- | ----------- | ----------- | -------"

    versus_isid str_12,              `options' fisid
    versus_isid str_12 str_32,       `options' fisid
    versus_isid str_12 str_32 str_4, `options' fisid

    versus_isid double1,                 `options' fisid
    versus_isid double1 double2,         `options' fisid
    versus_isid double1 double2 double3, `options' fisid

    versus_isid int1,           `options' fisid
    versus_isid int1 int2,      `options' fisid
    versus_isid int1 int2 int3, `options' fisid

    versus_isid int1 str_32 double1,                                        `options'
    versus_isid int1 str_32 double1 int2 str_12 double2,                    `options'
    versus_isid int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    di _n(1) "{hline 80}" _n(1) "bench_isid, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop gen_data
program gen_data
    syntax, [n(int 100) expand(int 1)]
    clear
    set obs `n'
    qui ralpha str_long,  l(5)
    qui ralpha str_mid,   l(3)
    qui ralpha str_short, l(1)
    gen str32 str_32   = str_long + "this is some string padding"
    gen str12 str_12   = str_mid  + "padding" + str_short + str_short
    gen str4  str_4    = str_mid  + str_short

    gen long int1  = floor(rnormal())
    gen long int2  = floor(uniform() * 1000)
    gen long int3  = floor(rnormal() * 5 + 10)

    gen double double1 = rnormal()
    gen double double2 = uniform() * 1000
    gen double double3 = rnormal() * 5 + 10

    qui expand `expand'
end

capture program drop versus_isid
program versus_isid, rclass
    syntax varlist, [fisid unique *]
    if ( "`unique'" == "unique" ) {
        tempvar ix
        gen `ix' = `=_N' - _n
        if ( strpos("`varlist'", "str") ) qui tostring `ix', replace
    }

    preserve
        timer clear
        timer on 42
        cap isid `varlist' `ix'
        assert inlist(_rc, 0, 459)
        timer off 42
        qui timer list
        local time_isid = r(t42)
    restore

    preserve
        timer clear
        timer on 43
        cap gisid `varlist' `ix', `options'
        assert inlist(_rc, 0, 459)
        timer off 43
        qui timer list
        local time_gisid = r(t43) 
    restore

    if ( "`fisid'" == "fisid" ) {
    preserve
        timer clear
        timer on 44
        cap fisid `varlist' `ix'
        assert inlist(_rc, 0, 459)
        timer off 44
        qui timer list
        local time_fisid = r(t44)
    restore
    }
    else {
        local time_fisid = .
    }

    local rs = `time_isid'  / `time_gisid'
    local rf = `time_fisid' / `time_gisid'
    di "    `:di %5.3g `time_isid'' | `:di %5.3g `time_fisid'' | `:di %5.3g `time_gisid'' | `:di %11.3g `rs'' | `:di %11.3g `rf'' | `varlist'"
end
capture program drop checks_hashsort
program checks_hashsort
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_hashsort, `options'" _n(1) "{hline 80}" _n(1)
    sysuse auto, clear
    gen idx = _n
    hashsort -foreign rep78 make -mpg, `options'
    hashsort idx, `options'
    hashsort -foreign rep78, `options'
    hashsort idx, `options'
    hashsort foreign rep78 mpg, `options'
    hashsort idx, v b `options'
end

capture program drop compare_hashsort
program compare_hashsort
    syntax, [tol(real 1e-6) NOIsily bench(int 1) *]

    cap gen_data, n(10000)
    qui expand 10 * `bench'
    qui gen rsort = rnormal()
    qui sort rsort

    local N = trim("`: di %15.0gc _N'")

    di _n(1)
    di "Benchmark vs gsort, obs = `N', J = 10,000 (in seconds; datasets are compared via {opt cf})"
    di "    gsort | hashsort | ratio (g/h) | varlist"
    di "    ----- | -------- | ----------- | -------"

    compare_gsort -str_12,              `options'
    compare_gsort str_12 -str_32,       `options'
    compare_gsort str_12 -str_32 str_4, `options'

    compare_gsort -double1,                 `options'
    compare_gsort double1 -double2,         `options'
    compare_gsort double1 -double2 double3, `options'

    compare_gsort -int1,           `options'
    compare_gsort int1 -int2,      `options'
    compare_gsort int1 -int2 int3, `options'

    compare_gsort -int1 -str_32 -double1,                                         `options'
    compare_gsort int1 -str_32 double1 -int2 str_12 -double2,                     `options'
    compare_gsort int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options'

    qui expand 10
    local N = trim("`: di %15.0gc _N'")

    di _n(1)
    di "Benchmark vs sort, obs = `N', J = 10,000 (in seconds; datasets are compared via {opt cf})"
    di "     sort | fsort | hashsort | ratio (g/h) | ratio (f/h) | varlist"
    di "     ---- | ----- | -------- | ----------- | ----------- | -------"

    compare_sort str_12,              `options' fsort
    compare_sort str_12 str_32,       `options' fsort
    compare_sort str_12 str_32 str_4, `options' fsort

    compare_sort double1,                 `options' fsort
    compare_sort double1 double2,         `options' fsort
    compare_sort double1 double2 double3, `options' fsort

    compare_sort int1,           `options' fsort
    compare_sort int1 int2,      `options' fsort
    compare_sort int1 int2 int3, `options' fsort

    compare_sort int1 str_32 double1,                                        `options'
    compare_sort int1 str_32 double1 int2 str_12 double2,                    `options'
    compare_sort int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    * cap gen_data, n(100)
    * qui expand 10000
    * compare_sort int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'
    * compare_gsort int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options'

    di _n(1) "{hline 80}" _n(1) "compare_hashsort, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop gen_data
program gen_data
    syntax, [n(int 100)]
    clear
    set obs `n'
    qui ralpha str_long,  l(5)
    qui ralpha str_mid,   l(3)
    qui ralpha str_short, l(1)
    gen str32 str_32   = str_long + "this is some string padding"
    gen str12 str_12   = str_mid  + "padding" + str_short + str_short
    gen str4  str_4    = str_mid  + str_short

    gen long int1  = floor(rnormal())
    gen long int2  = floor(uniform() * 1000)
    gen long int3  = floor(rnormal() * 5 + 10)

    gen double double1 = rnormal()
    gen double double2 = uniform() * 1000
    gen double double3 = rnormal() * 5 + 10
end

capture program drop compare_sort
program compare_sort, rclass
    syntax varlist, [fsort *]

    timer clear
    preserve
        timer on 42
        sort `varlist' , stable
        timer off 42
        tempfile file_sort
        qui save `file_sort'
    restore
    qui timer list
    local time_sort = r(t42)

    timer clear
    preserve
        timer on 43
        qui hashsort `varlist', `options'
        timer off 43
        cf * using `file_sort'
    restore
    qui timer list
    local time_hashsort = r(t43) 

    if ( "`fsort'" == "fsort" ) {
        timer clear
        preserve
            timer on 44
            qui fsort `varlist'
            timer off 44
            cf * using `file_sort'
        restore
        qui timer list
        local time_fsort = r(t44)
    }
    else {
        local time_fsort = .
    }

    local rs = `time_sort'  / `time_hashsort'
    local rf = `time_fsort' / `time_hashsort'
    di "    `:di %5.3g `time_sort'' | `:di %5.3g `time_fsort'' | `:di %8.3g `time_hashsort'' | `:di %11.3g `rs'' | `:di %11.3g `rf'' | `varlist'"
end

capture program drop compare_gsort
program compare_gsort, rclass
    syntax anything, [*]
    tempvar ix
    gen long `ix' = _n

    timer clear
    preserve
        timer on 42
        gsort `anything'
        timer off 42
        tempfile file_sort
        qui save `file_sort'
    restore
    qui timer list
    local time_sort = r(t42)

    timer clear
    preserve
        timer on 43
        qui hashsort `anything', `options'
        timer off 43
        cf `:di subinstr("`anything'", "-", "", .)' using `file_sort'
    restore
    qui timer list
    local time_hashsort = r(t43) 

    local rs = `time_sort'  / `time_hashsort'
    di "    `:di %5.3g `time_sort'' | `:di %8.3g `time_hashsort'' | `:di %11.3g `rs'' | `anything'"
end
capture program drop checks_levelsof
program checks_levelsof
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "consistency_levelsof, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' sim, n(5000) nj(100) njsub(4) string groupmiss outmiss
    gen ix = _n

    foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by groupsub groupstr
        if ( `i' == 3 ) local by groupstr groupsubstr 
        if ( `i' == 6 ) local by groupsub group
        if ( `i' == 9 ) local by grouplong
        cap noi glevelsof `by', `options' v b clean silent
        assert _rc == 0

        cap glevelsof `by' in 1, `options' silent
        assert _rc == 0

        cap glevelsof `by' in 1, `options' miss
        assert _rc == 0

        cap glevelsof `by' if _n == 1, `options' local(hi)
        assert _rc == 0
        assert `"`r(levels)'"' == `"`hi'"'

        cap glevelsof `by' if _n < 10 in 5, `options' s(" | ") cols(", ")
        assert _rc == 0
    }

    clear
    gen x = 1
    cap glevelsof x
    assert _rc == 2000

    clear
    set obs 100000
    gen x = _n
    cap glevelsof x in 1 / 10000 if mod(x, 3) == 0
    assert _rc == 0
end

capture program drop compare_levelsof
program compare_levelsof
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "consistency_levelsof, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' sim, n(500000) nj(10000) njsub(4) string groupmiss outmiss
    gen ix = _n

    foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by groupsub
        if ( `i' == 3 ) local by groupstr  
        if ( `i' == 6 ) local by groupsubstr
        if ( `i' == 9 ) local by grouplong
        cap  levelsof `by', s(" | ") local(l_stata)
        cap glevelsof `by', s(" | ") local(l_gtools) `options'
        if ( `"`l_stata'"' != `"`l_gtools'"' ) {
            di as err "    compare_levelsof (failed): glevelsof `by' returned different levels to levelsof"
            exit 198
        }
        else {
            di as txt "    compare_levelsof (passed): glevelsof `by' returned the same levels as levelsof"
        }
    }

    foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by groupsub
        if ( `i' == 3 ) local by groupstr  
        if ( `i' == 6 ) local by groupsubstr
        if ( `i' == 9 ) local by grouplong
        cap  levelsof `by', local(l_stata)  miss
        cap glevelsof `by', local(l_gtools) miss `options'
        if ( `"`l_stata'"' != `"`l_gtools'"' ) {
            di as err "    compare_levelsof (failed): glevelsof `by' returned different levels to levelsof"
            exit 198
        }
        else {
            di as txt "    compare_levelsof (passed): glevelsof `by' returned the same levels as levelsof"
        }
    }

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    di _n(1)

    foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by groupsub
        if ( `i' == 3 ) local by groupstr  
        if ( `i' == 6 ) local by groupsubstr
        if ( `i' == 9 ) local by grouplong

        cap  levelsof `by' in 100 / `=ceil(`=_N / 2')', local(l_stata)  miss
        cap glevelsof `by' in 100 / `=ceil(`=_N / 2')', local(l_gtools) miss `options'
        if ( `"`l_stata'"' != `"`l_gtools'"' ) {
            di as err "    compare_levelsof (failed): glevelsof `by' [in] returned different levels to levelsof"
            exit 198
        }
        else {
            di as txt "    compare_levelsof (passed): glevelsof `by' [in] returned the same levels as levelsof"
        }

        cap glevelsof `by' in `=ceil(`=_N / 2')' / `=_N', local(l_stata)
        cap glevelsof `by' in `=ceil(`=_N / 2')' / `=_N', local(l_gtools) `options'
        if ( `"`l_stata'"' != `"`l_gtools'"' ) {
            di as err "    compare_levelsof (failed): glevelsof `by' [in] returned different levels to levelsof"
            exit 198
        }
        else {
            di as txt "    compare_levelsof (passed): glevelsof `by' [in] returned the same levels as levelsof"
        }

    di _n(1)

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

        cap  levelsof `by' if _n > `=_N / 2', local(l_stata)  miss
        cap glevelsof `by' if _n > `=_N / 2', local(l_gtools) miss `options'
        if ( `"`l_stata'"' != `"`l_gtools'"' ) {
            di as err "    compare_levelsof (failed): glevelsof `by' [if] returned different levels to levelsof"
            exit 198
        }
        else {
            di as txt "    compare_levelsof (passed): glevelsof `by' [if] returned the same levels as levelsof"
        }

        cap glevelsof `by' if _n < `=_N / 2', local(l_stata)
        cap glevelsof `by' if _n < `=_N / 2', local(l_gtools) `options'
        if ( `"`l_stata'"' != `"`l_gtools'"' ) {
            di as err "    compare_levelsof (failed): glevelsof `by' [if] returned different levels to levelsof"
            exit 198
        }
        else {
            di as txt "    compare_levelsof (passed): glevelsof `by' [if] returned the same levels as levelsof"
        }

    di _n(1)

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

        cap  levelsof `by' if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')', local(l_stata)  miss
        cap glevelsof `by' if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')', local(l_gtools) miss `options'
        if ( `"`l_stata'"' != `"`l_gtools'"' ) {
            di as err "    compare_levelsof (failed): glevelsof `by' [if] [in] returned different levels to levelsof"
            exit 198
        }
        else {
            di as txt "    compare_levelsof (passed): glevelsof `by' [if] [in] returned the same levels as levelsof"
        }

        cap glevelsof `by' if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N', local(l_stata)
        cap glevelsof `by' if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N', local(l_gtools) `options'
        if ( `"`l_stata'"' != `"`l_gtools'"' ) {
            di as err "    compare_levelsof (failed): glevelsof `by' [if] [in] returned different levels to levelsof"
            exit 198
        }
        else {
            di as txt "    compare_levelsof (passed): glevelsof `by' [if] [in] returned the same levels as levelsof"
        }
    }
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_levelsof
program bench_levelsof
    syntax, [tol(real 1e-6) bench(int 1) NOIsily *]

    cap gen_data, n(100) expand(`=10000 * `bench'')
    qui gen rsort = rnormal()
    qui sort rsort

    local N = trim("`: di %15.0gc _N'")

    di _n(1)
    di "Benchmark vs levelsof, obs = `N', J = 100 (in seconds)"
    di "    levelsof | flevelsof | glevelsof | ratio (i/g) | ratio (f/g) | varlist"
    di "    -------- | --------- | --------- | ----------- | ----------- | -------"

    versus_levelsof str_12, `options' flevelsof
    versus_levelsof str_32, `options' flevelsof
    versus_levelsof str_4,  `options' flevelsof

    versus_levelsof double1, `options' flevelsof
    versus_levelsof double2, `options' flevelsof
    versus_levelsof double3, `options' flevelsof

    versus_levelsof int1, `options' flevelsof
    versus_levelsof int2, `options' flevelsof
    versus_levelsof int3, `options' flevelsof

    di _n(1) "{hline 80}" _n(1) "bench_levelsof, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop gen_data
program gen_data
    syntax, [n(int 100) expand(int 1)]
    clear
    set obs `n'
    qui ralpha str_long,  l(5)
    qui ralpha str_mid,   l(3)
    qui ralpha str_short, l(1)
    gen str32 str_32   = str_long + "this is some string padding"
    gen str12 str_12   = str_mid  + "padding" + str_short + str_short
    gen str4  str_4    = str_mid  + str_short

    gen long int1  = floor(rnormal())
    gen long int2  = floor(uniform() * 1000)
    gen long int3  = floor(rnormal() * 5 + 10)

    gen double double1 = rnormal()
    gen double double2 = uniform() * 1000
    gen double double3 = rnormal() * 5 + 10

    qui expand `expand'
end

capture program drop versus_levelsof
program versus_levelsof, rclass
    syntax varlist, [flevelsof unique *]
    if ( "`unique'" == "unique" ) {
        tempvar ix
        gen `ix' = `=_N' - _n
        if ( strpos("`varlist'", "str") ) qui tostring `ix', replace
    }

    preserve
        timer clear
        timer on 42
        qui levelsof `varlist' `ix'
        timer off 42
        qui timer list
        local time_levelsof = r(t42)
    restore

    preserve
        timer clear
        timer on 43
        qui glevelsof `varlist' `ix', `options'
        timer off 43
        qui timer list
        local time_glevelsof = r(t43) 
    restore

    if ( "`flevelsof'" == "flevelsof" ) {
    preserve
        timer clear
        timer on 44
        qui flevelsof `varlist' `ix'
        timer off 44
        qui timer list
        local time_flevelsof = r(t44)
    restore
    }
    else {
        local time_flevelsof = .
    }

    local rs = `time_levelsof'  / `time_glevelsof'
    local rf = `time_flevelsof' / `time_glevelsof'
    di "    `:di %8.3g `time_levelsof'' | `:di %9.3g `time_flevelsof'' | `:di %9.3g `time_glevelsof'' | `:di %11.3g `rs'' | `:di %11.3g `rf'' | `varlist'"
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
                gcollapse `collapse', by(`by') fast
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" collapse ")
                qui collapse `collapse', by(`by') fast
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
                qui gcollapse `collapse', by(`by') fast
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" collapse ")
                qui collapse `collapse', by(`by') fast
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
                qui gcollapse `collapse', by(`by') fast
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" collapse ")
                qui collapse `collapse', by(`by') fast
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
    syntax anything, style(str) [GCOLLapse(str) *]
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

    if ( "`gcollapse'" == "" ) local w f
    else local w g

    forvalues k = 1 / `:di `kmax' - `kmin' + 1' {
        mata: st_local("sim",   sim_matrix[`k'])
        qui `sim'
        mata: printf(print_matrix[`k'])
        preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" gcollapse-default `options'")
                qui gcollapse `collapse', by(`by') `options' fast
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" `w'collapse `gcollapse'")
                qui `w'collapse `collapse', by(`by') fast `gcollapse'
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') \n")
        restore
    }

    local i = 1
    di "Results varying `L' for `dstr'; by(`by')"
    di "|              `L' | gcollapse | `w'collapse | ratio (f/g) |"
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

* main, benchmark bench_extra
main, checks test
