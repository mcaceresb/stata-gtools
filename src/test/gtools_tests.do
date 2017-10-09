* ---------------------------------------------------------------------
* Project: gtools
* Program: gtools_tests.do
* Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
* Created: Tue May 16 07:23:02 EDT 2017
* Updated: Mon Oct  9 14:06:44 EDT 2017
* Purpose: Unit tests for gtools
* Version: 0.7.5
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
    syntax, [CAPture NOIsily legacy *]

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

            unit_test, `noisily' test(checks_corners, oncollision(error) debug_force_single `legacy')

            unit_test, `noisily' test(checks_byvars_gcollapse,  oncollision(error) debug_force_single `legacy')
            unit_test, `noisily' test(checks_byvars_gcollapse,  oncollision(error) debug_force_single forceio debug_io_read_method(0) `legacy')
            unit_test, `noisily' test(checks_byvars_gcollapse,  oncollision(error) debug_force_single forceio debug_io_read_method(1) `legacy')

            unit_test, `noisily' test(checks_options_gcollapse, oncollision(error) debug_force_single `legacy')
            unit_test, `noisily' test(checks_options_gcollapse, oncollision(error) debug_force_single debug_io_read_method(0) `legacy')
            unit_test, `noisily' test(checks_options_gcollapse, oncollision(error) debug_force_single debug_io_read_method(1) `legacy')

            if !inlist("`c(os)'", "Windows") {
                unit_test, `noisily' test(checks_corners, oncollision(error) debug_force_multi `legacy')

                unit_test, `noisily' test(checks_byvars_gcollapse,  oncollision(error) debug_force_multi `legacy')
                unit_test, `noisily' test(checks_byvars_gcollapse,  oncollision(error) debug_force_multi forceio debug_io_read_method(0) `legacy')
                unit_test, `noisily' test(checks_byvars_gcollapse,  oncollision(error) debug_force_multi forceio debug_io_read_method(1) `legacy')

                unit_test, `noisily' test(checks_options_gcollapse, oncollision(error) debug_force_multi `legacy')
                unit_test, `noisily' test(checks_options_gcollapse, oncollision(error) debug_force_multi debug_io_read_method(0) `legacy')
                unit_test, `noisily' test(checks_options_gcollapse, oncollision(error) debug_force_multi debug_io_read_method(1) `legacy')
            }

            di ""
            di "-----------------------------------------------------------"
            di "Consistency checks (vs collapse, egen) $S_TIME $S_DATE"
            di "-----------------------------------------------------------"

            consistency_gcollapse,       `noisily' oncollision(error) debug_force_single `legacy'
            consistency_gcollapse,       `noisily' oncollision(error) debug_force_single forceio debug_io_read_method(0) `legacy'
            consistency_gcollapse,       `noisily' oncollision(error) debug_force_single forceio debug_io_read_method(1) `legacy'
            consistency_gcollapse,       `noisily' oncollision(error) debug_force_single debug_io_check(1) debug_io_threshold(0.1) `legacy'
            consistency_gcollapse,       `noisily' oncollision(error) debug_force_single debug_io_check(1) debug_io_threshold(1000000) `legacy'
            consistency_gegen,           `noisily' oncollision(error) debug_force_single `legacy'
            consistency_gegen_gcollapse, `noisily' oncollision(error) debug_force_single `legacy'

            if !inlist("`c(os)'", "Windows") {
                consistency_gcollapse,       `noisily' oncollision(error) debug_force_multi `legacy'
                consistency_gcollapse,       `noisily' oncollision(error) debug_force_multi forceio debug_io_read_method(0) `legacy'
                consistency_gcollapse,       `noisily' oncollision(error) debug_force_multi forceio debug_io_read_method(1) `legacy'
                consistency_gcollapse,       `noisily' oncollision(error) debug_force_multi debug_io_check(1) debug_io_threshold(0.1) `legacy'
                consistency_gcollapse,       `noisily' oncollision(error) debug_force_multi debug_io_check(1) debug_io_threshold(1000000) `legacy'
                consistency_gegen,           `noisily' oncollision(error) debug_force_multi `legacy'
                consistency_gegen_gcollapse, `noisily' oncollision(error) debug_force_multi `legacy'
            }

            di ""
            di "--------------------------------"
            di "Check extra $S_TIME $S_DATE"     
            di "--------------------------------"

            unit_test, `noisily' test(checks_hashsort, `noisily' oncollision(error) `legacy')
            unit_test, `noisily' test(checks_isid,     `noisily' oncollision(error) `legacy')
            unit_test, `noisily' test(checks_levelsof, `noisily' oncollision(error) `legacy')

            compare_isid,     `noisily' oncollision(error) `legacy'
            compare_levelsof, `noisily' oncollision(error) `legacy'
            compare_hashsort, `noisily' oncollision(error) `legacy'
        }

        if ( `:list posof "bench_gtools" in options' ) {
            bench_switch_fcoll y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(4) kmax(7) kvars(15) style(ftools) gcoll(debug_force_single `legacy')
            bench_switch_fcoll y1 y2 y3,          by(x3)  kmin(4) kmax(7) kvars(3) stats(mean median)               style(ftools) gcoll(debug_force_single `legacy')
            bench_switch_fcoll y1 y2 y3 y4 y5 y6, by(x3)  kmin(4) kmax(7) kvars(6) stats(sum mean count min max)    style(ftools) gcoll(debug_force_single `legacy')
            bench_switch_fcoll x1 x2, margin(N) by(group) kmin(4) kmax(7) pct(median iqr p23 p77)                   style(gtools) gcoll(debug_force_single `legacy')
            bench_switch_fcoll x1 x2, margin(J) by(group) kmin(1) kmax(6) pct(median iqr p23 p77) obsexp(6)         style(gtools) gcoll(debug_force_single `legacy')
        }

        if ( `:list posof "test" in options' ) {
            cap ssc install ftools
            cap ssc install moremata

            di "Short (quick) versions of the benchmarks"
            bench_ftools y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(3) kmax(4) kvars(15) `legacy'
            bench_ftools y1 y2 y3,          by(x3) kmin(3) kmax(4) kvars(3) stats(mean median) `legacy'
            bench_ftools y1 y2 y3 y4 y5 y6, by(x3) kmin(3) kmax(4) kvars(6) stats(sum mean count min max) `legacy'
            bench_sample_size x1 x2, by(group) kmin(3) kmax(4) pct(median iqr p23 p77) `legacy'
            bench_group_size  x1 x2, by(group) kmin(2) kmax(3) pct(median iqr p23 p77) obsexp(3) `legacy'

            bench_switch_fcoll y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(3) kmax(4) kvars(15) style(ftools) `legacy'
            bench_switch_fcoll y1 y2 y3,          by(x3)    kmin(3) kmax(4) kvars(3) stats(mean median)             style(ftools) `legacy'
            bench_switch_fcoll y1 y2 y3 y4 y5 y6, by(x3)    kmin(3) kmax(4) kvars(6) stats(sum mean count min max)  style(ftools) `legacy'
            bench_switch_fcoll x1 x2, margin(N)   by(group) kmin(3) kmax(4) pct(median iqr p23 p77)                 style(gtools) `legacy'
            bench_switch_fcoll x1 x2, margin(J)   by(group) kmin(2) kmax(3) pct(median iqr p23 p77) obsexp(3)       style(gtools) `legacy'
        }

        if ( `:list posof "benchmark" in options' ) {
            cap ssc install ftools
            cap ssc install moremata

            bench_ftools y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(5) kmax(7) kvars(15) `legacy'
            bench_ftools y1 y2 y3,             by(x3)    kmin(5) kmax(7) kvars(3) stats(mean median) `legacy'
            bench_ftools y1 y2 y3 y4 y5 y6,    by(x3)    kmin(5) kmax(7) kvars(6) stats(sum mean count min max) `legacy'
            bench_sample_size x1 x2, margin(N) by(group) kmin(5) kmax(7) pct(median iqr p23 p77) `legacy'
            bench_group_size  x1 x2, margin(J) by(group) kmin(4) kmax(6) pct(median iqr p23 p77) obsexp(6) `legacy'
        }

        if ( `:list posof "bench_fcoll" in options' ) {
            cap ssc install ftools
            cap ssc install moremata

            bench_switch_fcoll y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(4) kmax(7) kvars(15) style(ftools) `legacy'
            bench_switch_fcoll y1 y2 y3,          by(x3)  kmin(4) kmax(7) kvars(3) stats(mean median)               style(ftools) `legacy'
            bench_switch_fcoll y1 y2 y3 y4 y5 y6, by(x3)  kmin(4) kmax(7) kvars(6) stats(sum mean count min max)    style(ftools) `legacy'
            bench_switch_fcoll x1 x2, margin(N) by(group) kmin(4) kmax(7) pct(median iqr p23 p77)                   style(gtools) `legacy'
            bench_switch_fcoll x1 x2, margin(J) by(group) kmin(1) kmax(6) pct(median iqr p23 p77) obsexp(6)         style(gtools) `legacy'
        }

        if ( `:list posof "bench_extra" in options' ) {
            compare_hashsort, bench(10) `legacy'
            bench_levelsof,   bench(10) `legacy'
            bench_isid,       bench(10) `legacy'
            bench_egen,       bench(10) `legacy'
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
* Run the things

* main, benchmark bench_extra
main, checks test
