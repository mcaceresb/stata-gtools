* ---------------------------------------------------------------------
* Project: gtools
* Program: gtools_tests.do
* Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
* Created: Tue May 16 07:23:02 EDT 2017
* Updated: Fri Jun 16 17:37:39 EDT 2017
* Purpose: Unit tests for gtools
* Version: 0.6.4
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

* ---------------------------------------------------------------------
* Run the things

main, cap noi checks test
