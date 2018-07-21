* ----------------------------------------------------------------------------
* Project: gtools
* Program: gtools_tests.do
* Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
* Created: Tue May 16 07:23:02 EDT 2017
* Updated: Sat Jul 21 16:40:33 EDT 2018
* Purpose: Unit tests for gtools
* Version: 1.0.0
* Manual:  help gtools

* Stata start-up options
* ----------------------

version 13
clear all
set more off
set varabbrev off
set seed 42
set linesize 255
set type double

* Main program wrapper
* --------------------

program main
    syntax, [NOIsily *]

    if ( inlist("`c(os)'", "MacOSX") | strpos("`c(machine_type)'", "Mac") ) {
        local c_os_ macosx
    }
    else {
        local c_os_: di lower("`c(os)'")
    }
    log using gtools_tests_`c_os_'.log, text replace name(gtools_tests)

    * Set up
    * ------

    local  progname tests
    local  start_time "$S_TIME $S_DATE"

    di _n(1)
    di "Start:        `start_time'"
    di "Options:      `options'"
    di "OS:           `c(os)'"
    di "Machine Type: `c(machine_type)'"

    * Run the things
    * --------------

    cap noi {
        * qui do test_gquantiles_by.do
        * qui do test_gquantiles.do
        * qui do test_gcollapse.do
        * qui do test_gcontract.do
        * qui do test_gegen.do
        * qui do test_gisid.do
        * qui do test_gduplicates.do
        * qui do test_glevelsof.do
        * qui do test_gtoplevelsof.do
        * qui do test_gunique.do
        * qui do test_hashsort.do

        if ( `:list posof "dependencies" in options' ) {
            cap ssc install ralpha
            cap ssc install ftools
            cap ssc install unique
            cap ssc install distinct
            cap ssc install moremata
            cap ssc install fastxtile
            cap ssc install egenmisc
            cap ssc install egenmore
            ftools, compile
        }

        if ( `:list posof "basic_checks" in options' ) {

            di ""
            di "-------------------------------------"
            di "Basic unit-tests $S_TIME $S_DATE"
            di "-------------------------------------"

            unit_test, `noisily' test(checks_gcontract,     `noisily' oncollision(error))
            unit_test, `noisily' test(checks_isid,          `noisily' oncollision(error))
            unit_test, `noisily' test(checks_duplicates,    `noisily' oncollision(error))
            unit_test, `noisily' test(checks_levelsof,      `noisily' oncollision(error))
            unit_test, `noisily' test(checks_toplevelsof,   `noisily' oncollision(error))
            unit_test, `noisily' test(checks_unique,        `noisily' oncollision(error))
            unit_test, `noisily' test(checks_hashsort,      `noisily' oncollision(error))

            unit_test, `noisily' test(checks_gquantiles_by, `noisily' oncollision(error))
            unit_test, `noisily' test(checks_gquantiles_by, `noisily' oncollision(error) wgt([fw = int1]))
            unit_test, `noisily' test(checks_gquantiles_by, `noisily' oncollision(error) wgt([pw = int1]))
            unit_test, `noisily' test(checks_gquantiles_by, `noisily' oncollision(error) wgt([aw = int1]))
            unit_test, `noisily' test(checks_gquantiles,    `noisily' oncollision(error))
            unit_test, `noisily' test(checks_gquantiles,    `noisily' oncollision(error) wgt([fw = int1]))
            unit_test, `noisily' test(checks_gquantiles,    `noisily' oncollision(error) wgt([pw = int1]))
            unit_test, `noisily' test(checks_gquantiles,    `noisily' oncollision(error) wgt([aw = int1]))

            unit_test, `noisily' test(checks_gegen,         `noisily' oncollision(error))
            unit_test, `noisily' test(checks_gegen,         `noisily' oncollision(error) wgt([fw = int1]))
            unit_test, `noisily' test(checks_gegen,         `noisily' oncollision(error) wgt([iw = int1]))
            unit_test, `noisily' test(checks_gegen,         `noisily' oncollision(error) wgt([pw = int1]))
            unit_test, `noisily' test(checks_gegen,         `noisily' oncollision(error) wgt([aw = int1]))

            unit_test, `noisily' test(checks_gcollapse,     `noisily' oncollision(error))
            unit_test, `noisily' test(checks_gcollapse,     `noisily' oncollision(error) wgt([fw = int1]))
            unit_test, `noisily' test(checks_gcollapse,     `noisily' oncollision(error) wgt([iw = int1]))
            unit_test, `noisily' test(checks_gcollapse,     `noisily' oncollision(error) wgt([pw = int1]))
            unit_test, `noisily' test(checks_gcollapse,     `noisily' oncollision(error) wgt([aw = int1]))

            di _n(1)

            unit_test, `noisily' test(checks_corners, `noisily' oncollision(error))
        }

        if ( `:list posof "comparisons" in options' ) {

            di ""
            di "-----------------------------------------------------------"
            di "Consistency checks (v native commands) $S_TIME $S_DATE"
            di "-----------------------------------------------------------"

            compare_isid,          `noisily' oncollision(error)
            compare_duplicates,    `noisily' oncollision(error)
            compare_levelsof,      `noisily' oncollision(error)
            compare_unique,        `noisily' oncollision(error) distinct
            compare_hashsort,      `noisily' oncollision(error)
            compare_egen,          `noisily' oncollision(error)
            compare_gcontract,     `noisily' oncollision(error)
            compare_toplevelsof,   `noisily' oncollision(error) tol(1e-4)
            compare_toplevelsof,   `noisily' oncollision(error) tol(1e-4) wgt(both f)

            compare_gquantiles_by, `noisily' oncollision(error)
            compare_gquantiles_by, `noisily' oncollision(error) noaltdef wgt(both mix)
            compare_gquantiles,    `noisily' oncollision(error) noaltdef
            compare_gquantiles,    `noisily' oncollision(error) noaltdef wgt(both mix)

            compare_gcollapse,     `noisily' oncollision(error)
            compare_gcollapse,     `noisily' oncollision(error) wgt(g [fw = 1]) tol(1e-4)
            compare_gcollapse,     `noisily' oncollision(error) wgt(c [fw = 1]) tol(1e-4)
            compare_gcollapse,     `noisily' oncollision(error) wgt(both mix)   tol(1e-4)
        }

        if ( `:list posof "switches" in options' ) {
            gquantiles_switch_sanity v1
            gquantiles_switch_sanity v2
            gquantiles_switch_sanity v3
        }

        if ( `:list posof "bench_test" in options' ) {
            bench_gquantiles_by, n(100)  bench(100) `noisily' oncollision(error)
            bench_gquantiles,    n(1000) bench(1)   `noisily' oncollision(error)
            bench_contract,      n(1000) bench(1)   `noisily' oncollision(error)
            bench_egen,          n(1000) bench(1)   `noisily' oncollision(error)
            bench_isid,          n(1000) bench(1)   `noisily' oncollision(error)
            bench_duplicates,    n(1000) bench(1)   `noisily' oncollision(error)
            bench_levelsof,      n(100)  bench(1)   `noisily' oncollision(error)
            bench_toplevelsof,   n(1000) bench(1)   `noisily' oncollision(error)
            bench_unique,        n(1000) bench(1)   `noisily' oncollision(error)
            bench_unique,        n(1000) bench(1)   `noisily' oncollision(error) distinct
            bench_hashsort,      n(1000) bench(1)   `noisily' oncollision(error) benchmode

            bench_collapse, collapse fcollapse bench(10)  n(100)    style(sum)    vars(15) oncollision(error)
            bench_collapse, collapse fcollapse bench(10)  n(100)    style(ftools) vars(6)  oncollision(error)
            bench_collapse, collapse fcollapse bench(10)  n(100)    style(full)   vars(1)  oncollision(error)

            bench_collapse, collapse fcollapse bench(0.05) n(10000) style(sum)    vars(15) oncollision(error)
            bench_collapse, collapse fcollapse bench(0.05) n(10000) style(ftools) vars(6)  oncollision(error)
            bench_collapse, collapse fcollapse bench(0.05) n(10000) style(full)   vars(1)  oncollision(error)
        }

        if ( `:list posof "bench_full" in options' ) {
            bench_gquantiles_by, n(10000)   bench(1000) `noisily' oncollision(error)
            bench_gquantiles,    n(1000000) bench(10)   `noisily' oncollision(error)
            bench_contract,      n(10000)   bench(10)   `noisily' oncollision(error)
            bench_egen,          n(10000)   bench(10)   `noisily' oncollision(error)
            bench_isid,          n(10000)   bench(10)   `noisily' oncollision(error)
            bench_duplicates,    n(10000)   bench(10)   `noisily' oncollision(error)
            bench_levelsof,      n(100)     bench(100)  `noisily' oncollision(error)
            bench_toplevelsof,   n(10000)   bench(10)   `noisily' oncollision(error)
            bench_unique,        n(10000)   bench(10)   `noisily' oncollision(error)
            bench_unique,        n(10000)   bench(10)   `noisily' oncollision(error) distinct
            bench_hashsort,      n(10000)   bench(10)   `noisily' oncollision(error) benchmode

            bench_collapse, collapse fcollapse bench(1000) n(100)    style(sum)    vars(15) oncollision(error)
            bench_collapse, collapse fcollapse bench(1000) n(100)    style(ftools) vars(6)  oncollision(error)
            bench_collapse, collapse fcollapse bench(1000) n(100)    style(full)   vars(1)  oncollision(error)

            bench_collapse, collapse fcollapse bench(0.1)  n(1000000) style(sum)    vars(15) oncollision(error)
            bench_collapse, collapse fcollapse bench(0.1)  n(1000000) style(ftools) vars(6)  oncollision(error)
            bench_collapse, collapse fcollapse bench(0.1)  n(1000000) style(full)   vars(1)  oncollision(error)
        }
    }
    local rc = _rc

    exit_message, rc(`rc') progname(`progname') start_time(`start_time') `capture'
    log close gtools_tests
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

capture program drop gen_data
program gen_data
    syntax, [n(int 100) skipstr]
    clear
    set obs `n'

    * Random strings
    * --------------

    if ( "`skipstr'" == "" ) {
        qui ralpha str_long,  l(5)
        qui ralpha str_mid,   l(3)
        qui ralpha str_short, l(1)
    }

    * Generate does-what-it-says-on-the-tin variables
    * -----------------------------------------------

    local chars char(40 + mod(_n, 50))
    forvalues i = 1 / 50 {
        local chars `chars' + char(40 + mod(_n + `i', 50))
    }

    forvalues i = 35 / 115 {
        disp `i', char(`i')
    }

    if ( "`skipstr'" == "" ) {
        if ( `c(stata_version)' >= 14 ) {
            gen strL strL1 = str_long  + `chars'
            gen strL strL2 = str_mid   + `chars'
            gen strL strL3 = str_short + `chars'
            forvalues i = 1 / 42 {
                replace strL1 = strL1 + `chars'
                replace strL2 = strL2 + `chars'
                replace strL3 = strL3 + `chars'
            }
        }

        gen str32 str_32   = str_long + "this is some string padding"
        gen str12 str_12   = str_mid  + "padding" + str_short + str_short
        gen str4  str_4    = str_mid  + str_short
    }

    gen long   int1  = floor(uniform() * 1000)
    gen long   int2  = floor(rnormal())
    gen double int3  = floor(rnormal() * 5 + 10)

    gen double double1 = uniform() * 1000
    gen double double2 = rnormal()
    gen double double3 = rnormal() * 5 + 10

    * Mix up string lengths
    * ---------------------

    if ( "`skipstr'" == "" ) {
        replace str_32 = str_mid + str_short if mod(_n, 4) == 0
        replace str_12 = str_short + str_mid if mod(_n, 4) == 2
    }

    * Insert some blanks
    * ------------------

    if ( "`skipstr'" == "" ) {
        replace str_32 = "            " in 1 / 10
        replace str_12 = "   "          in 1 / 10
        replace str_4  = " "            in 1 / 10

        replace str_32 = "            " if mod(_n, 21) == 0
        replace str_12 = "   "          if mod(_n, 34) == 0
        replace str_4  = " "            if mod(_n, 55) == 0

        if ( `c(stata_version)' >= 14 ) {
            replace strL1 = "            " in 1 / 10
            replace strL2 = "   "          in 1 / 10
            replace strL3 = " "            in 1 / 10

            replace strL1 = "            " if mod(_n, 21) == 0
            replace strL2 = "   "          if mod(_n, 34) == 0
            replace strL3 = " "            if mod(_n, 55) == 0
        }
    }

    * Missing values
    * --------------

    if ( "`skipstr'" == "" ) {
        replace str_32 = "" if mod(_n, 10) ==  0
        replace str_12 = "" if mod(_n, 20) ==  0
        replace str_4  = "" if mod(_n, 20) == 10

        if ( `c(stata_version)' >= 14 ) {
            replace strL1 = "" if mod(_n, 10) ==  0
            replace strL2 = "" if mod(_n, 20) ==  0
            replace strL3 = "" if mod(_n, 20) == 10
        }
    }

    replace int2  = .   if mod(_n, 10) ==  0
    replace int3  = .a  if mod(_n, 20) ==  0
    replace int3  = .f  if mod(_n, 20) == 10

    replace double2 = .   if mod(_n, 10) ==  0
    replace double3 = .h  if mod(_n, 20) ==  0
    replace double3 = .p  if mod(_n, 20) == 10

    * Singleton groups
    * ----------------

    if ( "`skipstr'" == "" ) {
        replace str_32 = "|singleton|" in `n'
        replace str_12 = "|singleton|" in `n'
        replace str_4  = "|singleton|" in `n'
    }

    replace int1    = 99999  in `n'
    replace double1 = 9999.9 in `n'

    replace int3 = .  in 1
    replace int3 = .a in 2
    replace int3 = .b in 3
    replace int3 = .c in 4
    replace int3 = .d in 5
    replace int3 = .e in 6
    replace int3 = .f in 7
    replace int3 = .g in 8
    replace int3 = .h in 9
    replace int3 = .i in 10
    replace int3 = .j in 11
    replace int3 = .k in 12
    replace int3 = .l in 13
    replace int3 = .m in 14
    replace int3 = .n in 15
    replace int3 = .o in 16
    replace int3 = .p in 17
    replace int3 = .q in 18
    replace int3 = .r in 19
    replace int3 = .s in 20
    replace int3 = .t in 21
    replace int3 = .u in 22
    replace int3 = .v in 23
    replace int3 = .w in 24
    replace int3 = .x in 25
    replace int3 = .y in 26
    replace int3 = .z in 27

    replace double3 = .  in 1
    replace double3 = .a in 2
    replace double3 = .b in 3
    replace double3 = .c in 4
    replace double3 = .d in 5
    replace double3 = .e in 6
    replace double3 = .f in 7
    replace double3 = .g in 8
    replace double3 = .h in 9
    replace double3 = .i in 10
    replace double3 = .j in 11
    replace double3 = .k in 12
    replace double3 = .l in 13
    replace double3 = .m in 14
    replace double3 = .n in 15
    replace double3 = .o in 16
    replace double3 = .p in 17
    replace double3 = .q in 18
    replace double3 = .r in 19
    replace double3 = .s in 20
    replace double3 = .t in 21
    replace double3 = .u in 22
    replace double3 = .v in 23
    replace double3 = .w in 24
    replace double3 = .x in 25
    replace double3 = .y in 26
    replace double3 = .z in 27
end

capture program drop random_draws
program random_draws
    syntax, random(int) [binary(int 0) float double]
    forvalues i = 1 / `random' {
        gen `float'`double' random`i' = rnormal() * `i' * 5
        replace random`i' = . if mod(_n, 20) == 0
        if ( `binary' > 0 ) {
            replace random`i' = floor(runiform() * 1.99) if _n <= `=_N / `binary''
        }
    }
end

capture program drop checks_gcollapse
program checks_gcollapse
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_gcollapse, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(5000)
    qui expand 2
    qui `noisily' random_draws, random(2)
    gen long ix = _n

    checks_inner_collapse, `options'

    checks_inner_collapse -str_12,              `options'
    checks_inner_collapse str_12 -str_32,       `options'
    checks_inner_collapse str_12 -str_32 str_4, `options'

    checks_inner_collapse -double1,                 `options'
    checks_inner_collapse double1 -double2,         `options'
    checks_inner_collapse double1 -double2 double3, `options'

    checks_inner_collapse -int1,           `options'
    checks_inner_collapse int1 -int2,      `options'
    checks_inner_collapse int1 -int2 int3, `options'

    checks_inner_collapse -int1 -str_32 -double1,                                         `options'
    checks_inner_collapse int1 -str_32 double1 -int2 str_12 -double2,                     `options'
    checks_inner_collapse int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options'

    ****************
    *  Misc tests  *
    ****************

    clear
    cap gcollapse
    assert _rc == 198
    set obs 10
    cap gcollapse
    assert _rc == 198
    gen x = .
    gcollapse x

    clear
    set obs 10
    gen x = .
    gen w = .
    cap gcollapse x [w = w]
    assert _rc == 2000
    cap gcollapse x if w == 0
    assert _rc == 2000

    * untested here; run the examples
    * replace with merge
    * labelformat
    * labelprogram
end

capture program drop checks_inner_collapse
program checks_inner_collapse
    syntax [anything], [tol(real 1e-6) wgt(str) *]

    local 0 `anything' `wgt', `options'
    syntax [anything] [aw fw iw pw], [*]

    local percentiles p1 p10 p30.5 p50 p70.5 p90 p99
    local stats nunique sum mean max min count percent first last firstnm lastnm median iqr skew kurt
    if ( !inlist("`weight'", "pweight") )            local stats `stats' sd
    if ( !inlist("`weight'", "pweight", "iweight") ) local stats `stats' semean
    if (  inlist("`weight'", "fweight", "") )        local stats `stats' sebinomial sepoisson

    local collapse_str ""
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') r1_`stat' = random1
    }
    foreach pct of local percentiles {
        local collapse_str `collapse_str' (`pct') r1_`:subinstr local pct "." "_", all' = random1
    }
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') r2_`stat' = random2
    }
    foreach pct of local percentiles {
        local collapse_str `collapse_str' (`pct') r2_`:subinstr local pct "." "_", all' = random2
    }

    preserve
        gcollapse `collapse_str' `wgt', by(`anything') verbose `options'
    restore, preserve
        gcollapse `collapse_str' `wgt', by(`anything') verbose benchmark `options'
    restore, preserve
        gcollapse `collapse_str' `wgt', by(`anything') verbose forceio `options'
    restore, preserve
        gcollapse `collapse_str' `wgt', by(`anything') verbose forcemem `options'
    restore, preserve
        gcollapse `collapse_str' `wgt', by(`anything') verbose benchmark cw `options'
    restore, preserve
        gcollapse `collapse_str' `wgt', by(`anything') verbose benchmark fast `options'
    restore, preserve
        gcollapse `collapse_str' `wgt', by(`anything') double `options'
    restore, preserve
        gcollapse `collapse_str' `wgt', by(`anything') merge `options'
    restore, preserve
        gcollapse `collapse_str' `wgt', by(`anything') verbose `options' benchmark debug_io_check(0)
    restore
end

***********************************************************************
*                            Corner cases                             *
***********************************************************************

capture program drop checks_corners
program checks_corners
    syntax, [*]
    di _n(1) "{hline 80}" _n(1) "checks_corners `options'" _n(1) "{hline 80}" _n(1)

    * https://github.com/mcaceresb/stata-gtools/issues/39
    qui {
        clear
        set obs 5
        gen x = _n
        gen strL y = "hi"
        cap gcollapse (p70) x, by(y)
        assert _rc == 17002

        clear
        set obs 5
        gen x = _n
        gen strL y = "hi"
        cap gcollapse (p70) x, by(y) compress
        assert _rc == 0

        clear
        set obs 5
        gen x = _n
        gen strL y = "hi" + string(mod(_n, 2)) + char(9) + char(0)
        cap gcollapse (p70) x, by(y)
        assert _rc == 17002
        cap gcollapse (p70) x, by(y) compress
        assert _rc == 17004
    }

    * https://github.com/mcaceresb/stata-gtools/issues/38
    qui {
        clear
        set obs 5
        gen x = _n
        gcollapse (p70) x
        assert x == 4

        clear
        set obs 5
        gen x = _n
        gcollapse (p80) x
        assert x == 4.5

        clear
        set obs 5
        gen x = _n
        gcollapse (p80.0001) x
        assert x == 5

        clear
        set obs 3
        gen x = _n
        gcollapse (p50) x
        assert x == 2

        clear
        set obs 3
        gen x = _n
        gcollapse (p66.6) x
        assert x == 2

        clear
        set obs 3
        gen x = _n
        gcollapse (p66.7) x
        assert x == 3
    }

    * https://github.com/mcaceresb/stata-gtools/issues/32
    qui {
        clear
        sysuse auto
        set varabbrev on
        gcollapse head = head
        set varabbrev off
    }

    qui {
        clear
        set obs 10
        gen x = .
        gcollapse (sum) y = x, merge missing
        gcollapse (sum) z = x, merge
        assert y == .
        assert z == 0
    }

    * https://github.com/mcaceresb/stata-gtools/issues/27
    qui {
        clear
        set obs 10
        gen xxx = 1
        set varabbrev on
        cap confirm xx
        gcollapse xx = xxx
        cap confirm x
        set varabbrev off
    }

    qui {
        sysuse auto, clear
        gen price2 = price
        cap noi gcollapse price = price2 if price < 0
        assert _rc == 2000
    }

    qui {
        sysuse auto, clear
        gen price2 = price
        gcollapse price = price2
    }

    qui {
        sysuse auto, clear
        gen price2 = price
        gcollapse price = price2, by(make) v bench `options'
        gcollapse price in 1,     by(make) v bench `options'
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

***********************************************************************
*                               Compare                               *
***********************************************************************

capture program drop compare_gcollapse
program compare_gcollapse
    syntax, [tol(real 1e-6) NOIsily *]

    * This should be ignored for compare_inner_gcollapse_gegen bc of merge
    local debug_io debug_io_check(0) debug_io_threshold(0.0001)

    qui `noisily' gen_data, n(1000)
    qui expand 100
    qui `noisily' random_draws, random(2)

    di _n(1) "{hline 80}" _n(1) "consistency_gcollapse_gegen, `options'" _n(1) "{hline 80}" _n(1)

    compare_inner_gcollapse_gegen, `options' tol(`tol')

    compare_inner_gcollapse_gegen -str_12,              `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_gegen str_12 -str_32,       `options' tol(`tol') sort
    compare_inner_gcollapse_gegen str_12 -str_32 str_4, `options' tol(`tol') shuffle

    compare_inner_gcollapse_gegen -double1,                 `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_gegen double1 -double2,         `options' tol(`tol') sort
    compare_inner_gcollapse_gegen double1 -double2 double3, `options' tol(`tol') shuffle

    compare_inner_gcollapse_gegen -int1,           `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_gegen int1 -int2,      `options' tol(`tol') sort
    compare_inner_gcollapse_gegen int1 -int2 int3, `options' tol(`tol') shuffle

    compare_inner_gcollapse_gegen -int1 -str_32 -double1, `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_gegen int1 -str_32 double1 -int2 str_12 -double2, `options' tol(`tol') sort
    compare_inner_gcollapse_gegen int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options' tol(`tol') shuffle

    qui `noisily' gen_data, n(1000)
    qui expand 50
    qui `noisily' random_draws, random(2) binary(5)

    di _n(1) "{hline 80}" _n(1) "consistency_collapse, `options'" _n(1) "{hline 80}" _n(1)

    compare_inner_collapse, `options' tol(`tol')

    compare_inner_collapse str_12,              `options' tol(`tol') forcemem sort
    compare_inner_collapse str_12 str_32,       `options' tol(`tol') forceio shuffle
    compare_inner_collapse str_12 str_32 str_4, `options' tol(`tol') `debug_io'

    compare_inner_collapse double1,                 `options' tol(`tol') forcemem
    compare_inner_collapse double1 double2,         `options' tol(`tol') forceio sort
    compare_inner_collapse double1 double2 double3, `options' tol(`tol') `debug_io' shuffle

    compare_inner_collapse int1,           `options' tol(`tol') forcemem shuffle
    compare_inner_collapse int1 int2,      `options' tol(`tol') forceio
    compare_inner_collapse int1 int2 int3, `options' tol(`tol') `debug_io' sort

    compare_inner_collapse int1 str_32 double1,                                        `options' tol(`tol') forcemem
    compare_inner_collapse int1 str_32 double1 int2 str_12 double2,                    `options' tol(`tol') forceio
    compare_inner_collapse int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options' tol(`tol') `debug_io'

    qui `noisily' gen_data, n(1000)
    qui expand 50
    qui `noisily' random_draws, random(2) binary(5)

    di _n(1) "{hline 80}" _n(1) "consistency_gcollapse_skew_kurt, `options'" _n(1) "{hline 80}" _n(1)

    compare_inner_gcollapse_skew, `options' tol(`tol')

    compare_inner_gcollapse_skew -str_12,              `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_skew str_12 -str_32,       `options' tol(`tol') sort
    compare_inner_gcollapse_skew str_12 -str_32 str_4, `options' tol(`tol') shuffle

    compare_inner_gcollapse_skew -double1,                 `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_skew double1 -double2,         `options' tol(`tol') sort
    compare_inner_gcollapse_skew double1 -double2 double3, `options' tol(`tol') shuffle

    compare_inner_gcollapse_skew -int1,           `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_skew int1 -int2,      `options' tol(`tol') sort
    compare_inner_gcollapse_skew int1 -int2 int3, `options' tol(`tol') shuffle

    compare_inner_gcollapse_skew -int1 -str_32 -double1, `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_skew int1 -str_32 double1 -int2 str_12 -double2, `options' tol(`tol') sort
    compare_inner_gcollapse_skew int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options' tol(`tol') shuffle
end

***********************************************************************
*                            Compare gegen                            *
***********************************************************************

capture program drop compare_inner_gcollapse_gegen
program compare_inner_gcollapse_gegen
    syntax [anything], [tol(real 1e-6) sort shuffle wgt(str) *]

    gettoken wfun wfoo: wgt
    local wfun `wfun'
    local wfoo `wfoo'
    if ( `"`wfoo'"' == "mix" ) {
        local wgen_a  qui gen unif_0_100 = 100 * runiform() if mod(_n, 100)
        local wcall_a "[aw = unif_0_100]"
        local wgen_f  qui gen int_unif_0_100 = int(100 * runiform()) if mod(_n, 100)
        local wcall_f "[fw = int_unif_0_100]"
        local wgen_p  qui gen float_unif_0_1 = runiform() if mod(_n, 100)
        local wcall_p "[pw = float_unif_0_1]"
        local wgen_i  qui gen rnormal_0_10 = 10 * rnormal() if mod(_n, 100)
        local wcall_i "[iw = rnormal_0_10]"
    }
    else {
        local wgt wgt(`wgt')
    }

    tempvar rsort
    if ( "`shuffle'" != "" ) gen `rsort' = runiform()
    if ( "`shuffle'" != "" ) sort `rsort'
    if ( ("`sort'" != "") & ("`anything'" != "") ) qui hashsort `anything'

    local N = trim("`: di %15.0gc _N'")
    local hlen = 45 + length("`anything'") + length("`N'")
    di _n(2) "Checking gegen vs gcollapse. N = `N'; varlist = `anything'" _n(1) "{hline `hlen'}"

    preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_a'
            local wgt wgt(both `wcall_a')
        }
        _compare_inner_gcollapse_gegen `anything', `options' tol(`tol') `wgt'
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_f'
            local wgt wgt(both `wcall_f')
        }
        if ( "`shuffle'" != "" ) sort `rsort'
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_gcollapse_gegen  `anything' in `from' / `to', `options' `wgt' tol(`tol')
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_i'
            local wgt wgt(both `wcall_i')
        }
        _compare_inner_gcollapse_gegen `anything' if random2 > 0, `options' `wgt' tol(`tol')
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_p'
            local wgt wgt(both `wcall_p')
        }
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_gcollapse_gegen `anything' if random2 < 0 in `from' / `to', `options' `wgt' tol(`tol')
    restore
end

capture program drop _compare_inner_gcollapse_gegen
program _compare_inner_gcollapse_gegen
    syntax [anything] [if] [in], [tol(real 1e-6) wgt(str) *]

    gettoken wfun wgt: wgt
    local wgt `wgt'

    if ( "`wgt'" != "" ) {
        if inlist("`wfun'", "both", "g") {
            local wgt_gc `wgt'
        }
        if inlist("`wfun'", "both", "c") {
            local wgt_ge `wgt'
        }
        if ( "`wfun'" == "both" ) {
            local wtxt " `wgt'"
        }
        else if ( "`wfun'" == "g" ) {
            local wtxt " `wgt' (gcollapse only)"
        }
        else if ( "`wfun'" == "c" ) {
            local wtxt " `wgt' (gegen only)"
        }
    }

    local ifin `if' `in'
    local anything_ `anything'
    local options_  `options'
    local 0 `wgt'
    syntax [aw fw iw pw]
    local anything `anything_'
    local options  `options_'

    local sestats
    local stats nunique sum mean max min percent first last firstnm lastnm median iqr skew kurt
    if ( !inlist("`weight'", "pweight") ) {
        local stats   `stats'   sd
        local sestats `sestats' sd
    }
    if ( !inlist("`weight'", "pweight", "iweight") ) {
        local stats   `stats'   semean
        local sestats `sestats' semean
    }
    if (  inlist("`weight'", "fweight", "") ) {
        local stats   `stats'   sebinomial sepoisson
        local sestats `sestats' sebinomial sepoisson
    }

    gegen id = group(`anything'), missing

    gegen double nunique = nunique (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double percent = percent (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double mean    = mean    (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double sum     = sum     (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double median  = median  (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double min     = min     (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double max     = max     (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double iqr     = iqr     (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double first   = first   (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double last    = last    (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double firstnm = firstnm (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double lastnm  = lastnm  (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double skew    = skew    (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double kurt    = kurt    (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double q10     = pctile  (random1) `ifin' `wgt_ge',  by(`anything') p(10.5)
    gegen double q30     = pctile  (random1) `ifin' `wgt_ge',  by(`anything') p(30)
    gegen double q70     = pctile  (random1) `ifin' `wgt_ge',  by(`anything') p(70)
    gegen double q90     = pctile  (random1) `ifin' `wgt_ge',  by(`anything') p(90.5)

    local gextra
    foreach extra of local sestats {
        gegen double `extra' = `extra'(random1) `ifin' `wgt_ge',  by(`anything')
        local gextra `gextra' (`extra') g_`extra' = random1
    }

    qui `noisily' {
        gcollapse (nunique)    g_nunique    = random1 ///
                  (percent)    g_percent    = random1 ///
                  (mean)       g_mean       = random1 ///
                  (sum)        g_sum        = random1 ///
                  (median)     g_median     = random1 ///
                  (min)        g_min        = random1 ///
                  (max)        g_max        = random1 ///
                  (iqr)        g_iqr        = random1 ///
                  (first)      g_first      = random1 ///
                  (last)       g_last       = random1 ///
                  (firstnm)    g_firstnm    = random1 ///
                  (lastnm)     g_lastnm     = random1 ///
                  (skew)       g_skew       = random1 ///
                  (kurt)       g_kurt       = random1 ///
                  (p10.5)      g_q10        = random1 ///
                  (p30)        g_q30        = random1 ///
                  (p70)        g_q70        = random1 ///
                  (p90.5)      g_q90        = random1 ///
                  `gextra'                            ///
              `ifin' `wgt_gc', by(id) benchmark verbose `options' merge double
    }

    if ( "`ifin'" == "" ) {
        di _n(1) "Checking full range`wtxt': `anything'"
    }
    else if ( "`ifin'" != "" ) {
        di _n(1) "Checking [`ifin']`wtxt' range: `anything'"
    }

    foreach fun in `stats' q10 q30 q70 q90 {
        cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
        if ( _rc ) {
            if inlist("`fun'", "skew", "kurt") {
                local a1 ((g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol')
                local a2 (inlist(g_`fun', 1, -1) & mi(`fun'))
                local a3 (inlist(`fun', 1, -1)   & mi(g_`fun'))
                local a4 (nunique == 1)
                cap noi assert `a1' | ((`a2' | `a3') & `a4')
                if ( _rc ) {
                    di as err "    compare_gegen_gcollapse (failed): `fun'`wtxt' yielded different results (tol = `tol')"
                    keep `ifin'
                    keep if !(`a1' | ((`a2' | `a3') & `a4'))
                    save /tmp/xx, replace
                    exit _rc
                }
                else di as txt "    compare_gegen_gcollapse (imprecision): `fun'`wtxt' yielded similar results (tol = `tol')"
            }
            else {
                recast double g_`fun' `fun'
                cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
                if ( _rc ) {
                    di as err "    compare_gegen_gcollapse (failed): `fun'`wtxt' yielded different results (tol = `tol')"
                    save /tmp/xx, replace
                    exit _rc
                }
                else di as txt "    compare_gegen_gcollapse (passed): `fun'`wtxt' yielded same results (tol = `tol')"
            }
        }
        else di as txt "    compare_gegen_gcollapse (passed): `fun'`wtxt' yielded same results (tol = `tol')"
    }
end

***********************************************************************
*                          Compare collapse                           *
***********************************************************************

capture program drop compare_inner_collapse
program compare_inner_collapse
    syntax [anything], [tol(real 1e-6) sort shuffle wgt(str) *]

    gettoken wfun wfoo: wgt
    local wfun `wfun'
    local wfoo `wfoo'
    if ( `"`wfoo'"' == "mix" ) {
        local wgen_a  qui gen unif_0_100 = 100 * runiform() if mod(_n, 100)
        local wcall_a "[aw = unif_0_100]"
        local wgen_f  qui gen int_unif_0_100 = int(100 * runiform())
        local wcall_f "[fw = int_unif_0_100]"
        local wgen_i  qui gen rnormal_0_10 = 10 * rnormal()
        local wcall_i "[iw = rnormal_0_10]"
        local wgen_p  qui gen float_unif_0_1 = runiform()
        local wcall_p "[pw = float_unif_0_1]"
    }
    else {
        local wgt wgt(`wgt')
    }

    tempvar rsort
    if ( "`shuffle'" != "" ) gen `rsort' = runiform()
    if ( "`shuffle'" != "" ) sort `rsort'
    if ( ("`sort'" != "") & ("`anything'" != "") ) qui hashsort `anything'

    local N = trim("`: di %15.0gc _N'")
    local hlen = 35 + length("`anything'") + length("`N'")
    di _n(2) "Checking collapse. N = `N'; varlist = `anything'" _n(1) "{hline `hlen'}"

    preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_a'
            local wgt wgt(both `wcall_a')
        }
        _compare_inner_collapse `anything', `options' `wgt' tol(`tol')
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_f'
            local wgt wgt(both `wcall_f')
        }
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_collapse  `anything' in `from' / `to', `options' `wgt' tol(`tol')
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_i'
            local wgt wgt(both `wcall_i')
        }
        _compare_inner_collapse `anything' if random2 > 0, `options' `wgt' tol(`tol')
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_p'
            local wgt wgt(both `wcall_p')
        }
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_collapse `anything' if random2 < 0 in `from' / `to', `options' `wgt' tol(`tol')
    restore
end

capture program drop _compare_inner_collapse
program _compare_inner_collapse
    syntax [anything] [if] [in], [tol(real 1e-6) wgt(str) *]

    gettoken wfun wgt: wgt
    local wgt `wgt'

    if ( "`wgt'" != "" ) {
        if inlist("`wfun'", "both", "g") {
            local wgt_gc `wgt'
        }
        if inlist("`wfun'", "both", "c") {
            local wgt_ge `wgt'
        }
        if ( "`wfun'" == "both" ) {
            local wtxt " `wgt'"
        }
        else if ( "`wfun'" == "g" ) {
            local wtxt " `wgt' (gcollapse only)"
        }
        else if ( "`wfun'" == "c" ) {
            local wtxt " `wgt' (collapse only)"
        }
    }

    local ifin `if' `in'
    local anything_ `anything'
    local options_  `options'
    local 0 `wgt'
    syntax [aw fw iw pw]
    local anything `anything_'
    local options  `options_'

    local stats sum mean max min count first last firstnm lastnm median iqr
    if ( !inlist("`weight'", "pweight") )            local stats `stats' sd
    if ( !inlist("`weight'", "pweight", "iweight") ) local stats `stats' semean
    if (  inlist("`weight'", "fweight", "") )        local stats `stats' sebinomial sepoisson

    local percentiles p1 p13 p30 p50 p70 p87 p99
    local collapse_str ""
    local k1 ""
    local k2 ""
    local k3 ""

    foreach pct of local percentiles {
        local k1 `k1' r1_`pct'
        local collapse_str `collapse_str' (`pct') r1_`pct' = random1
    }
    foreach stat of local stats {
        local k1 `k1' r1_`stat'
        local collapse_str `collapse_str' (`stat') r1_`stat' = random1
    }
    foreach pct of local percentiles {
        local k2 `k2' r2_`pct'
        local collapse_str `collapse_str' (`pct') r2_`pct' = random2
    }
    foreach stat of local stats {
        local k2 `k2' r2_`stat'
        local collapse_str `collapse_str' (`stat') r2_`stat' = random2
    }
    local k3 r1_percent r2_percent
    local collapse_str `collapse_str' (percent) r1_percent = random1 r2_percent = random2

    if ( "`wgt'" == "" ) {
        local freq freq(freq)
        local wgt_gc [fw = 42]
    }

    local sopts by(`anything') verbose benchmark `options' `freq'
    preserve
        qui `noisily' gcollapse `collapse_str' `ifin' `wgt_gc', `sopts' rawstat(`k1')
        if ( "`wgt'" == "" ) {
            drop `k2'
        }
        else {
            drop `k1'
        }
        tempfile fg1
        qui save `fg1'
    restore, preserve
        qui `noisily' gcollapse `collapse_str' `ifin' `wgt_gc', `sopts' rawstat(`k2')
        if ( "`wgt'" == "" ) {
            drop `k1'
        }
        else {
            drop `k2'
        }
        tempfile fg2
        qui save `fg2'
    restore, preserve
        use `fg1', clear
            qui ds *
            local mergevars `r(varlist)'
            local mergevars: list mergevars - k1
            local mergevars: list mergevars - k2
            local mergevars: list mergevars - k3
            if ( "`mergevars'" == "" ) {
                local mergevars _n
            }
            qui merge 1:1 `mergevars' using `fg2', assert(3) nogen
        tempfile fg
        qui save `fg'
    restore

    preserve
        if ( "`wgt'" == "" ) {
            qui gen long freq = 1
            qui `noisily' collapse `collapse_str' (sum) freq `ifin' `wgt_ge', by(`anything')
        }
        else {
            qui `noisily' collapse `collapse_str' `ifin' `wgt_ge', by(`anything')
        }
        tempfile fc
        qui save `fc'
    restore

    preserve
    use `fc', clear
        local bad_any = 0
        local bad `anything'
        local by  `anything'
        foreach var in `stats' `percentiles' {
            rename r1_`var' c_r1_`var'
            rename r2_`var' c_r2_`var'
        }
        cap rename freq c_freq
        if ( "`by'" == "" ) {
            qui merge 1:1 _n using `fg', assert(3)
        }
        else {
            qui merge 1:1 `by' using `fg', assert(3)
        }
        foreach var in `stats' `percentiles' {

            * I am not entirely sure why this check is here. I figured
            * it had to be a corner case where I might return . and
            * stata 0 or the converse... Not 100% why that changes if
            * there is a weight, where it failed.

            if inlist("`var'", "sd", "semean") {
                local nonz1 & (r1_`var' != 0 & c_r1_`var' != .) & (r1_`var' != . & c_r1_`var' != 0)
                local nonz2 & (r2_`var' != 0 & c_r2_`var' != .) & (r2_`var' != . & c_r2_`var' != 0)
            }
            else {
                local nonz1
                local nonz2
            }

            qui count if ( (abs(r1_`var' - c_r1_`var') > `tol') & (r1_`var' != c_r1_`var')) `nonz1'
            if ( `r(N)' > 0 ) {
                gen bad_r1_`var' = abs(r1_`var' - c_r1_`var') * (r1_`var' != c_r1_`var')
                local bad `bad' *r1_`var'
                di "    r1_`var' has `:di r(N)' mismatches".
                local bad_any = 1
                order *r1_`var'
            }

            qui count if ( (abs(r2_`var' - c_r2_`var') > `tol') & (r2_`var' != c_r2_`var')) `nonz2'
            if ( `r(N)' > 0 ) {
                gen bad_r2_`var' = abs(r2_`var' - c_r2_`var') * (r2_`var' != c_r2_`var')
                local bad `bad' *r2_`var'
                di "    r2_`var' has `:di r(N)' mismatches".
                local bad_any = 1
                order *r2_`var'
            }
        }
        if ( "`wgt'" == "" ) {
            qui count if ( (abs(freq - c_freq) > `tol') & (freq != c_freq))
            if ( `r(N)' > 0 ) {
                gen bad_freq = abs(freq - c_freq) * (freq != c_freq)
                local bad `bad' *freq
                di "    freq has `:di r(n)' mismatches".
                local bad_any = 1
                order *freq
            }
        }
        if ( `bad_any' ) {
            if ( "`ifin'" == "" ) {
                di "    compare_collapse (failed): full range`wtxt', `anything'"
            }
            else if ( "`ifin'" != "" ) {
                di "    compare_collapse (failed): [`ifin']`wtxt', `anything'"
            }
            order `bad'
            egen bad_any = rowmax(bad_*)
            * l *count* *mean* `bad' if bad_any
            sum bad_*
            desc
            exit 9
        }
        else {
            if ( "`ifin'" == "" ) {
                di "    compare_collapse (passed): full range`wtxt', gcollapse results equal to collapse (tol = `tol')"
            }
            else if ( "`ifin'" != "" ) {
                di "    compare_collapse (passed): [`ifin']`wtxt', gcollapse results equal to collapse (tol = `tol')"
            }
        }
    restore
end

***********************************************************************
*                           Check skewness                            *
***********************************************************************

capture program drop compare_inner_gcollapse_skew
program compare_inner_gcollapse_skew
    syntax [anything], [tol(real 1e-6) sort shuffle wgt(str) *]

    * iw and pw not allowed in -sum, detail-

    gettoken wfun wfoo: wgt
    local wfun `wfun'
    local wfoo `wfoo'
    if ( `"`wfoo'"' == "mix" ) {
        local wgen_a  qui gen unif_0_100 = 100 * runiform() if mod(_n, 100)
        local wcall_a "[aw = unif_0_100]"
        local wgen_f  qui gen int_unif_0_100 = int(100 * runiform()) if mod(_n, 100)
        local wcall_f "[fw = int_unif_0_100]"
        local wgen_p  `wgen_a'
        local wcall_p `wcall_a'
        local wgen_i  `wgen_f'
        local wcall_i `wcall_f'
    }
    else {
        local wgt wgt(`wgt')
    }

    tempvar rsort
    if ( "`shuffle'" != "" ) gen `rsort' = runiform()
    if ( "`shuffle'" != "" ) sort `rsort'
    if ( ("`sort'" != "") & ("`anything'" != "") ) qui hashsort `anything'

    local N = trim("`: di %15.0gc _N'")
    local hlen = 45 + length("`anything'") + length("`N'")
    di _n(2) "Checking skewness and kurtosis. N = `N'; varlist = `anything'" _n(1) "{hline `hlen'}"

    preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_a'
            local wgt wgt(both `wcall_a')
        }
        _compare_inner_gcollapse_skew `anything', `options' tol(`tol') `wgt'
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_f'
            local wgt wgt(both `wcall_f')
        }
        if ( "`shuffle'" != "" ) sort `rsort'
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_gcollapse_skew  `anything' in `from' / `to', `options' `wgt' tol(`tol')
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_i'
            local wgt wgt(both `wcall_i')
        }
        _compare_inner_gcollapse_skew `anything' if random2 > 0, `options' `wgt' tol(`tol')
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_p'
            local wgt wgt(both `wcall_p')
        }
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_gcollapse_skew `anything' if random2 < 0 in `from' / `to', `options' `wgt' tol(`tol')
    restore
end

capture program drop _compare_inner_gcollapse_skew
program _compare_inner_gcollapse_skew
    syntax [anything] [if] [in], [tol(real 1e-6) wgt(str) *]

    gettoken wfun wgt: wgt
    local wgt `wgt'

    if ( "`wgt'" != "" ) {
        if inlist("`wfun'", "both", "g") {
            local wgt_gc `wgt'
        }
        if inlist("`wfun'", "both", "c") {
            local wgt_ge `wgt'
        }
        if ( "`wfun'" == "both" ) {
            local wtxt " `wgt'"
        }
        else if ( "`wfun'" == "g" ) {
            local wtxt " `wgt' (gcollapse only)"
        }
        else if ( "`wfun'" == "c" ) {
            local wtxt " `wgt' (gegen only)"
        }
    }

    local ifin `in' `if'
    if ( `"`if'"' == "" ) {
        local sifin `in' if id ==
    }
    else {
        local sifin `in' `if' & id ==
    }

    local anything_ `anything'
    local options_   `options'
    local 0 `wgt'
    syntax [aw fw iw pw]
    local anything `anything_'
    local options  `options_'

    qui gegen id = group(`anything') `ifin', missing
    qui gunique id `ifin', missing
    local J = `r(J)'
    qui sum id
    local maxid = `r(max)'
    * gquantiles id, pctile(idlevel) cutpoints(id) dedup

    local checks
    forvalues i = 1 / 10 {
        local j = ceil(runiform() * `J')
        qui sum random1 `sifin' `j' `wgt_gc', d
        local sd_`j'   = r(sd)
        local skew_`j' = r(skewness)
        local kurt_`j' = r(kurtosis)
        local checks `checks' `j'
    }

    qui sum random1 `sifin' `maxid' `wgt_gc', d
    local sd_`maxid'   = r(sd)
    local skew_`maxid' = r(skewness)
    local kurt_`maxid' = r(kurtosis)
    local checks `checks' `maxid'

    qui gcollapse (skew) skew = random1 (kurt) kurt = random1 (nunique) nq = random1 ///
        `ifin' `wgt_gc', by(id) benchmark verbose `options' double

    if ( "`ifin'" == "" ) {
        di _n(1) "Checking full range`wtxt': `anything'"
    }
    else if ( "`ifin'" != "" ) {
        di _n(1) "Checking [`ifin']`wtxt' range: `anything'"
    }

    * For skewness and kurtosis, numerical imprecision can cause the
    * result to be -1 or 1 when it should really be missing. Internally
    * 0 / 0 is computed as ε / ε for some ε small.

    foreach fun in kurt skew {
        local imprecise 0
        foreach j in `checks' {
            * disp "`j'"
            cap assert ``fun'_`j'' == `fun'[`j'] | abs(``fun'_`j'' - `fun'[`j']) < `tol'
            if ( _rc & (nq[`j'] > 1) ) {
                cap noi assert 0
                di as err "    compare_`fun'_gcollapse (failed): sum`wtxt' yielded different results (tol = `tol')"
                disp "``fun'_`j'' vs `=`fun'[`j']'; diff `=abs(``fun'_`j'' - `fun'[`j'])'"
                exit _rc
            }
            else if ( _rc & (nq[`j'] == 1) ) {
                local ++imprecise
            }
        }

        if ( `imprecise' ) {
            di as txt "    compare_`fun'_gcollapse (imprecision): sum`wtxt' yielded similar results (tol = `tol'; `imprecise' imprecisions)"
        }
        else {
            di as txt "    compare_`fun'_gcollapse (passed): sum`wtxt' yielded same results (tol = `tol')"
        }
    }
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_collapse
program bench_collapse
    syntax, [tol(real 1e-6) bench(real 1) n(int 1000) NOIsily style(str) vars(int 1) collapse fcollapse *]

    qui gen_data, n(`n')
    qui expand `=100 * `bench''
    qui `noisily' random_draws, random(`vars') double
    qui hashsort random1

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    if ( "`style'" == "full" ) {
        local ststr "all available plus percentiles 10, 30, 70, 90"
    }
    else if ( "`style'" == "ftools" ) {
        local ststr "mean median min max"
    }
    else {
        local ststr "sum"
    }

    if ( `vars' > 1 ) {
        local vstr "x1-x`vars'"
    }
    else {
        local vstr x1
    }

    di as txt _n(1)
    di as txt "Benchmark vs collapse (in seconds)"
    di as txt "    - obs:     `N'"
    di as txt "    - groups:  `J'"
    di as txt "    - vars:    `vstr' ~ N(0, 10)"
    di as txt "    - stats:   `ststr'"
    di as txt "    - options: fast"
    di as txt _n(1)
    di as txt "    collapse | fcollapse | gcollapse | ratio (c/g) | ratio (f/g) | varlist"
    di as txt "    -------- | --------- | --------- | ----------- | ----------- | -------"

    local options `options' style(`style') vars(`vars')
    versus_collapse,                         `options' `collapse' `fcollapse'
    versus_collapse str_12 str_32 str_4,     `options' `collapse' `fcollapse'
    versus_collapse double1 double2 double3, `options' `collapse' `fcollapse'
    versus_collapse int1 int2,               `options' `collapse' `fcollapse'
    versus_collapse int3 str_32 double1,     `options' `collapse'

    di _n(1) "{hline 80}" _n(1) "bench_collapse, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop versus_collapse
program versus_collapse, rclass
    syntax [anything], [fcollapse collapse style(str) vars(int 1) *]

    local stats       ""
    local percentiles ""

    if ( "`style'" == "full" ) {
        local stats sum mean sd max min count median iqr percent first last firstnm lastnm
        local percentiles p10 p30 p70 p90
    }
    else if ( "`style'" == "ftools" ) {
        local stats mean median min max
    }
    else {
        local stats sum
    }

    local collapse_str ""
    foreach stat of local stats {
        forvalues k = 1 / `vars' {
            local collapse_str `collapse_str' (`stat') r`k'_`stat' = random`k'
        }
    }
    foreach pct of local percentiles {
        forvalues k = 1 / `vars' {
            local collapse_str `collapse_str' (`pct') r`k'_`pct' = random`k'
        }
    }

    if ( "`collapse'" == "collapse" ) {
    preserve
        timer clear
        timer on 42
        qui collapse `collapse_str', by(`anything') fast
        timer off 42
        qui timer list
        local time_collapse = r(t42)
    restore
    }
    else {
        local time_collapse = .
    }

    preserve
        timer clear
        timer on 43
        qui gcollapse `collapse_str', by(`anything') `options' fast
        timer off 43
        qui timer list
        local time_gcollapse = r(t43)
    restore

    if ( "`fcollapse'" == "fcollapse" ) {
    preserve
        timer clear
        timer on 44
        qui fcollapse `collapse_str', by(`anything') fast
        timer off 44
        qui timer list
        local time_fcollapse = r(t44)
    restore
    }
    else {
        local time_fcollapse = .
    }

    local rs = `time_collapse'  / `time_gcollapse'
    local rf = `time_fcollapse' / `time_gcollapse'
    di as txt "    `:di %8.3g `time_collapse'' | `:di %9.3g `time_fcollapse'' | `:di %9.3g `time_gcollapse'' | `:di %11.3g `rs'' | `:di %11.3g `rf'' | `anything'"
end
capture program drop checks_gcontract
program checks_gcontract
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_gcontract, `options'" _n(1) "{hline 80}" _n(1)

    * https://github.com/mcaceresb/stata-gtools/issues/32
    qui {
        clear
        sysuse auto
        set varabbrev on
        gcontract head
        set varabbrev off
    }

    * https://github.com/mcaceresb/stata-gtools/issues/39
    qui {
        clear
        set obs 5
        gen x = _n
        gen strL y = "hi"
        cap gcontract y
        assert _rc == 17002

        clear
        set obs 5
        gen x = _n
        gen strL y = "hi"
        cap gcontract y, compress
        assert _rc == 0

        clear
        set obs 5
        gen x = _n
        gen strL y = "hi" + string(mod(_n, 2)) + char(9) + char(0)
        cap gcontract y
        assert _rc == 17002
        cap gcontract y, compress
        assert _rc == 17004
    }

    qui `noisily' gen_data, n(5000)
    qui expand 2
    qui `noisily' random_draws, random(2)
    gen long ix = _n

    cap gcontract
    assert _rc == 100

    checks_inner_contract -str_12,              `options' nomiss
    checks_inner_contract str_12 -str_32,       `options'
    checks_inner_contract str_12 -str_32 str_4, `options'

    checks_inner_contract -double1,                 `options' fast
    checks_inner_contract double1 -double2,         `options' unsorted
    checks_inner_contract double1 -double2 double3, `options' v bench

    checks_inner_contract -int1,           `options'
    checks_inner_contract int1 -int2,      `options'
    checks_inner_contract int1 int2  int3, `options' z

    checks_inner_contract -int1 -str_32 -double1,                                         `options'
    checks_inner_contract int1 -str_32 double1 -int2 str_12 -double2,                     `options'
    checks_inner_contract int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options'

    ****************
    *  Misc tests  *
    ****************

    clear
    set obs 10
    gen x = _n
    gen y = string(mod(_n, 2))
    gcontract x y , zero

    clear
    cap gcontract
    assert _rc == 2000
    set obs 10
    cap gcontract
    assert _rc == 100
    gen x = .
    gcontract x

    clear
    set obs 10
    gen x = .
    gen w = .
    cap gcontract x [w = w]
    assert _rc == 2000
    cap gcontract x if w == 0
    assert _rc == 2000
end

capture program drop checks_inner_contract
program checks_inner_contract
    syntax [anything], [tol(real 1e-6) *]

    preserve
        gcontract `anything', `options' freq(freq)
    restore, preserve
        gcontract `anything', `options' freq(freq) cf(cf)
    restore, preserve
        gcontract `anything', `options' freq(freq)        p(p)        format(%5.1g)
    restore, preserve
        gcontract `anything', `options' freq(freq)             cp(cp) float
    restore, preserve
        gcontract `anything', `options' freq(freq) cf(cf) p(p)        float
    restore, preserve
        gcontract `anything', `options' freq(freq) cf(cf)      cp(cp) format(%5.1g)
    restore, preserve
        gcontract `anything', `options' freq(freq)        p(p) cp(cp) format(%5.1g)
    restore, preserve
        gcontract `anything', `options' freq(freq) cf(cf) p(p) cp(cp) float
    restore
end

***********************************************************************
*                               Compare                               *
***********************************************************************

capture program drop compare_gcontract
program compare_gcontract
    syntax, [tol(real 1e-6) NOIsily *]

    qui `noisily' gen_data, n(1000)
    qui expand 50
    qui `noisily' random_draws, random(2) binary(2)

    di as txt _n(1) "{hline 80}" _n(1) "consistency_gcontract, `options'" _n(1) "{hline 80}" _n(1)

    compare_inner_contract str_12,              `options' tol(`tol') nomiss
    compare_inner_contract str_12 str_32,       `options' tol(`tol') sort
    compare_inner_contract str_12 str_32 str_4, `options' tol(`tol') shuffle

    compare_inner_contract double1,                 `options' tol(`tol') shuffle
    compare_inner_contract double1 double2,         `options' tol(`tol') nomiss
    compare_inner_contract double1 double2 double3, `options' tol(`tol') sort

    compare_inner_contract int1,           `options' tol(`tol') sort
    compare_inner_contract int1 int2,      `options' tol(`tol') shuffle
    compare_inner_contract int1 int2 int3, `options' tol(`tol') nomiss

    compare_inner_contract int1 str_32 double1,                                        `options' tol(`tol')
    compare_inner_contract int1 str_32 double1 int2 str_12 double2,                    `options' tol(`tol')
    compare_inner_contract int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options' tol(`tol')
end

capture program drop compare_inner_contract
program compare_inner_contract
    syntax [anything], [tol(real 1e-6) sort shuffle *]

    tempvar rsort
    if ( "`shuffle'" != "" ) gen `rsort' = runiform()
    if ( "`shuffle'" != "" ) sort `rsort'
    if ( ("`sort'" != "") & ("`anything'" != "") ) hashsort `anything'

    local N = trim("`: di %15.0gc _N'")
    local hlen = 35 + length("`anything'") + length("`N'")
    di as txt _n(2) "Checking contract. N = `N'; varlist = `anything'" _n(1) "{hline `hlen'}"

    preserve
        _compare_inner_contract `anything', `options' tol(`tol')
    restore, preserve
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_contract  `anything' in `from' / `to', `options' tol(`tol')
    restore, preserve
        _compare_inner_contract `anything' if random2 > 0, `options' tol(`tol')
    restore, preserve
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_contract `anything' if random2 < 0 in `from' / `to', `options' tol(`tol')
    restore
end

capture program drop _compare_inner_contract
program _compare_inner_contract
    syntax [anything] [if] [in], [tol(real 1e-6) *]

    local opts freq(freq) cf(cf) p(p) cp(cp)

    preserve
        timer clear
        timer on 43
        qui `noisily' gcontract `anything' `if' `in', `opts'
        timer off 43
        qui timer list
        local time_gcontract = r(t43)
        tempfile fg
        qui save `fg'
    restore

    preserve
        timer clear
        timer on 42
        qui `noisily' contract `anything' `if' `in', `opts'
        timer off 42
        qui timer list
        local time_gcontract = r(t42)
        tempfile fc
        qui save `fc'
    restore

    preserve
    use `fc', clear
        local bad_any = 0
        local bad `anything'
        foreach var in freq cf p cp {
            rename `var' c_`var'
        }
        qui merge 1:1 `anything' using `fg', assert(3)
        foreach var in freq cf p cp {
            qui count if ( (abs(`var' - c_`var') > `tol') & (`var' != c_`var'))
            if ( `r(N)' > 0 ) {
                gen bad_`var' = abs(`var' - c_`var') * (`var' != c_`var')
                local bad `bad' *`var'
                di "    `var' has `:di r(N)' mismatches".
                local bad_any = 1
                order *`var'
            }
        }
        if ( `bad_any' ) {
            if ( "`if'`in'" == "" ) {
                di "    compare_contract (failed): full range, `anything'"
            }
            else if ( "`if'`in'" != "" ) {
                di "    compare_contract (failed): [`if' `in'], `anything'"
            }
            order `bad'
            egen bad_any = rowmax(bad_*)
            l `bad' if bad_any
            sum bad_*
            desc
            exit 9
        }
        else {
            if ( "`if'`in'" == "" ) {
                di "    compare_contract (passed): full range, gcontract results equal to contract (tol = `tol')"
            }
            else if ( "`if'`in'" != "" ) {
                di "    compare_contract (passed): [`if' `in'], gcontract results equal to contract (tol = `tol')"
            }
        }
    restore
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_contract
program bench_contract
    syntax, [tol(real 1e-6) bench(real 1) n(int 1000) NOIsily *]

    qui gen_data, n(`n')
    qui expand `=100 * `bench''
    qui `noisily' random_draws, random(1) double
    qui hashsort random1

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    di as txt _n(1)
    di as txt "Benchmark vs contract, obs = `N', J = `J' (in seconds)"
    di as txt "    contract | gcontract | ratio (c/g) | varlist"
    di as txt "    -------- | --------- | ----------- | -------"

    versus_contract str_12,              `options'
    versus_contract str_12 str_32,       `options'
    versus_contract str_12 str_32 str_4, `options'

    versus_contract double1,                 `options'
    versus_contract double1 double2,         `options'
    versus_contract double1 double2 double3, `options'

    versus_contract int1,           `options'
    versus_contract int1 int2,      `options'
    versus_contract int1 int2 int3, `options'

    versus_contract int1 str_32 double1,                                        `options'
    versus_contract int1 str_32 double1 int2 str_12 double2,                    `options'
    versus_contract int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    di _n(1) "{hline 80}" _n(1) "bench_contract, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop versus_contract
program versus_contract, rclass
    syntax [anything], [*]

    local stats       ""
    local percentiles ""

    local opts freq(freq) cf(cf) p(p) cp(cp)

    preserve
        timer clear
        timer on 42
        qui contract `anything' `if' `in', `opts'
        timer off 42
        qui timer list
        local time_contract = r(t42)
    restore

    preserve
        timer clear
        timer on 43
        qui gcontract `anything' `if' `in', `opts'
        timer off 43
        qui timer list
        local time_gcontract = r(t43)
    restore

    local rs = `time_contract'  / `time_gcontract'
    di as txt "    `:di %8.3g `time_contract'' | `:di %9.3g `time_gcontract'' | `:di %11.3g `rs'' | `anything'"
end
* pctile, xtile tests
*     - [X] nquantiles
*     - [X] cutpoints
*     - [X] quantiles
*     - [X] cutoffs
*     - [X] cutquantiles
* _pctile tests
*     - [X] nquantiles
*     - [X] cutpoints (fail w/o gen)
*     - [X] quantiles
*     - [X] cutoffs (fail w/o bincount)
*     - [X] cutquantiles (fail w/o gen)
* options (all):
*     - [X] altdef
*     - [X] genp()
*     - [X] binfreq
*     - [X] pctile() with xtile
*     - [X] xtile() with pctile
* consistency, xtile:
*     - [X] xtile,  nquantiles()   == xtile, cutpoints(pctile, nquantiles())
*     - [X] xtile,  cutpoints()    == xtile, cutoffs()
*     - [X] xtile,  cutquantiles() == xtile, quantiles()
* consistency, pctile == _pctile:
*     - [X] nquantiles
*     - [X] cutpoints
*     - [X] quantiles
*     - [X] cutoffs
*     - [X] cutquantiles
* sanity:
*     - [X] replace
*     - [X] minmax
*     - [X] strict
* todo:
*     by(str)
*     method

capture program drop checks_gquantiles
program checks_gquantiles
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_gquantiles, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(5000) skipstr
    qui expand 2
    qui `noisily' random_draws, random(2)
    gen long   ix = _n
    gen double ru = runiform() * 100
    gen double rn = rnormal() * 100

    cap gquantiles
    assert _rc == 198
    cap gquantiles, xtile
    assert _rc == 198
    cap gquantiles, _pctile
    assert _rc == 198
    cap gquantiles, pctile
    assert _rc == 198

    local options `options'  `noisily'

    checks_inner_gquantiles double1, `options' method(1)
    checks_inner_gquantiles double3, `options' method(2)
    checks_inner_gquantiles ru,      `options'

    checks_inner_gquantiles int1, `options'
    checks_inner_gquantiles int3, `options' method(1)
    checks_inner_gquantiles ix,   `options' method(2)

    checks_inner_gquantiles int1^2 + 3 * double1,          `options' method(2)
    checks_inner_gquantiles log(double1) + 2 * int1,       `options'
    checks_inner_gquantiles exp(double3) + int1 * double3, `options' method(1)

    *****************
    *  Misc checks  *
    *****************

    clear
    cap fasterxtile
    assert _rc == 2000

    clear
    gen z = 1
    cap fasterxtile x = z
    assert _rc == 2000

    clear
    set obs 10
    gen z = _n
    cap fasterxtile x = z if 0
    assert _rc == 2000
    cap fasterxtile x = z if 1 [w = .]
    assert _rc == 2000
    cap fasterxtile x = z if 1 [w = 0]
    assert _rc == 2000

    clear
    set obs 100
    gen x = runiform()
    gen w = 10 * runiform()
    gen z = 10 * rnormal()
    gen a = mod(_n, 7)
    gen b = "str" + string(mod(_n, 3))
    gen c = x in 1/5

    matrix qq = 1, 10, 70, 1
    matrix cc = 0.1, 0.05, 0.1000, 0.9
    gquantiles x, p(1 10 70) _pctile
    gquantiles x, q(1 10 70) _pctile
    gquantiles x, _pctile quantmatrix(qq)
    cap gquantiles x, cutq(x) _pctile
    assert _rc == 198
    cap gquantiles x, cut(x) _pctile
    assert _rc == 198
    cap gquantiles x, cut(x) _pctile
    assert _rc == 198

    clear
    set obs 100
    gen x = runiform()
    gen w = 10 * runiform()
    gen z = 10 * rnormal()
    gen a = mod(_n, 7)
    gen b = "str" + string(mod(_n, 3))

    fasterxtile gx0 = x
    fasterxtile gx1 = log(x) + 1 if mod(_n, 10) in 20 / 80
    fasterxtile gx2 = x [w = w],  nq(7) method(1)
    fasterxtile gx3 = x [aw = w], nq(7) method(2)
    fasterxtile gx4 = x [pw = w], nq(7) method(0)
    cap fasterxtile gx5 = x [fw = w], nq(7)
    assert _rc == 401
    fasterxtile gx5 = x [fw = int(w)], nq(108)
    cap fasterxtile gx6 = x [fw = int(w)], altdef
    assert _rc == 198

    assert gx2 == gx3
    assert gx3 == gx4

    drop gx*

    fasterxtile gx0 = x, by(a)
    fasterxtile gx1 = log(x) + 1 if mod(_n, 10) in 20 / 80, by(b)
    fasterxtile gx2 = x [w = w],  nq(7) by(a b)
    fasterxtile gx3 = x [aw = w], nq(7) by(a b)
    fasterxtile gx4 = x [pw = w], nq(7) by(a b)
    cap fasterxtile gx5 = x [fw = w], nq(7) by(b a)
    assert _rc == 401
    fasterxtile gx5 = x [fw = int(w)], nq(108) by(-a b)

    fasterxtile gx6 = x [fw = int(w)], by(-a b) method(1)
    fasterxtile gx7 = x [fw = int(w)], by(-a b) method(2)
    fasterxtile gx8 = x [fw = int(w)], by(-a b) method(0)

    fasterxtile gx9 = x, by(-a b) method(1) altdef
    fasterxtile gx10 = x, by(-a b) method(0) altdef
    fasterxtile gx11 = x, by(-a b) method(2) altdef

    assert gx2 == gx3
    assert gx3 == gx4

    drop gx*
    gquantiles cp = x, nq(10)

    fasterxtile gx0 = x , c(cp)
    fasterxtile gx1 = log(x) + 1 if mod(_n , 10) in 20 / 80, c(cp)

    fasterxtile gx2 = x [w = w]      if mod(_n , 10) in 20 / 80 , nq(7) by(a b) c(cp) method(1)
    fasterxtile gx3 = x [aw = w]     if mod(_n , 10) in 20 / 80 , nq(7) by(a b) c(cp) method(2)
    fasterxtile gx4 = x [pw = w]     if mod(_n , 10) in 20 / 80 , nq(7) by(a b) c(cp) method(0)
    cap fasterxtile gx5 = x [fw = w] if mod(_n , 10) in 20 / 80 , nq(7) by(b a) c(cp)
    assert _rc == 401
    fasterxtile gx5 = x [fw = int(w)], nq(108) by(-a b)

    drop gx*

    fasterxtile gx0 = x in 1
    cap fasterxtile gx1 = log(x) + 1 if mod(_n, 10) in 20 / 80, strict nq(100)
    disp _rc
    fasterxtile gx2 = log(x) + 1 if mod(_n, 10) in 20 / 80, by(a) strict nq(100)
    assert gx2 == .
end

capture program drop checks_inner_gquantiles
program checks_inner_gquantiles
    syntax anything, [tol(real 1e-6) NOIsily wgt(str)  *]
    cap drop __*
    local qui = cond("`noisily'" == "", "qui", "noisily")

    local 0 `anything' `wgt', `options'
    syntax anything [aw fw pw], [*]

    `qui' {
        gquantiles __p1 = `anything' `wgt', pctile `options' nq(10)
        l in 1/10

        gquantiles __p2 = `anything' `wgt', pctile `options' cutpoints(__p1)
        gquantiles __p3 = `anything' `wgt', pctile `options' quantiles(10 30 50 70 90)
        gquantiles __p4 = `anything' `wgt', pctile `options' cutoffs(10 30 50 70 90)
        cap gquantiles __p5 = `anything' `wgt', pctile `options' cutquantiles(rn)
        assert _rc == 198
        gquantiles __p5 = `anything' `wgt', pctile `options' cutquantiles(ru)


        fasterxtile __fx1 = `anything' `wgt', `options' nq(10)
        fasterxtile __fx2 = `anything' `wgt', `options' cutpoints(__p1)
        fasterxtile __fx3 = `anything',       `options' cutpoints(__p1) altdef
        fasterxtile __fx4 = `anything',       `options' nq(10) altdef


        gquantiles __x1 = `anything' `wgt', xtile `options' nq(10)
        gquantiles __x2 = `anything' `wgt', xtile `options' cutpoints(__p1)
        gquantiles __x3 = `anything' `wgt', xtile `options' quantiles(10 30 50 70 90)
        gquantiles __x4 = `anything' `wgt', xtile `options' cutoffs(10 30 50 70 90)
        cap gquantiles __x5 = `anything' `wgt', xtile `options' cutquantiles(rn)
        assert _rc == 198
        gquantiles __x5 = `anything' `wgt', xtile `options' cutquantiles(ru)

        gquantiles `anything' `wgt', _pctile `options' nq(10)


        cap gquantiles `anything' `wgt', _pctile `options' cutpoints(__p1)
        assert _rc == 198
        gquantiles `anything' `wgt', _pctile `options' cutpoints(__p1) pctile(__p2) replace

        gquantiles `anything' `wgt', _pctile `options' quantiles(10 30 50 70 90)

        cap gquantiles `anything' `wgt', _pctile `options' cutoffs(10 30 50 70 90)
        assert _rc == 198
        gquantiles `anything' `wgt', _pctile `options' cutoffs(10 30 50 70 90) binfreq

        cap gquantiles `anything' `wgt', _pctile `options' cutquantiles(ru)
        assert _rc == 198
        gquantiles `anything' `wgt', _pctile `options' cutpoints(__p1)  xtile(__x5) replace
    }

    if ( "`wgt'" != "" ) exit 0

    `qui' {
        gquantiles __p1 = `anything', pctile altdef binfreq `options' nq(10) replace
        matrix list r(quantiles_binfreq)

        drop __*
        cap gquantiles __p1 = `anything' in 1/5, pctile altdef binfreq `options' nq(10) replace strict
        assert inlist(_rc, 198, 2000)
        cap gquantiles __p1 = `anything' in 1/5, pctile altdef binfreq `options' nq(10) replace
        assert inlist(_rc, 0, 2000)
        gquantiles __p1 = `anything', pctile altdef binfreq `options' nq(10) replace

        cap gquantiles __p2 = `anything', pctile altdef binfreq `options' cutpoints(__p1)
        assert inlist(_rc, 198, 110)
        gquantiles __p2 = `anything', pctile altdef binfreq(__f2) `options' cutpoints(__p1)

        cap gquantiles __p2 = `anything' in 10 / 20, pctile altdef binfreq(__f2) `options' cutpoints(__p1) replace
        assert inlist(_rc, 0, 2000)
        cap gquantiles __p2 = `anything' in 10 / 20, pctile altdef binfreq(__f2) `options' cutpoints(__p1) replace cutifin
        assert inlist(_rc, 198, 2000)
        cap gquantiles __p2_ii = `anything' if inlist(_n, 1, 3, 7), pctile altdef `options' cutifin cutpoints(__p1)
        * assert __p2_ii[1] == __p1[1]
        * assert __p2_ii[2] == __p1[3]
        * assert __p2_ii[3] == __p1[7]
        gquantiles __p2 = `anything', pctile altdef binfreq(__f2) `options' cutpoints(__p1) replace


        gquantiles __p3 = `anything', pctile altdef binfreq `options' quantiles(10 30 50 70 90)
        matrix list r(quantiles_binfreq)


        gquantiles __p4 = `anything', pctile altdef binfreq `options' cutoffs(10 30 50 70 90)
        matrix list r(cutoffs_binfreq)


        cap gquantiles __p5 = `anything', pctile altdef binfreq `options' cutquantiles(ru)
        assert inlist(_rc, 198, 110)
        gquantiles __p5 = `anything', pctile altdef binfreq(__f5) `options' cutquantiles(ru)
        gquantiles __p5 = `anything', pctile altdef binfreq(__f5) `options' cutquantiles(ru) replace

        gquantiles __x1 = `anything', pctile altdef binfreq `options' nq(10) replace
        matrix list r(quantiles_binfreq)



        gquantiles __x1 = `anything', pctile altdef binfreq `options' nq(10) replace
        cap gquantiles __x1 = `anything' in 1/5, pctile altdef binfreq `options' nq(10) replace
        assert inlist(_rc, 0, 2000)
        cap gquantiles __x1 = `anything' in 1/5, pctile altdef binfreq `options' nq(10) replace strict
        assert inlist(_rc, 198, 2000)

        cap gquantiles __x2 = `anything', pctile altdef binfreq `options' cutpoints(__p1)
        assert _rc == 198
        gquantiles __x2 = `anything', pctile altdef binfreq(__xf2) `options' cutpoints(__p1)
        gquantiles __x2 = `anything', pctile altdef binfreq(__xf2) `options' cutpoints(__p1) replace

        gquantiles __x3 = `anything', pctile altdef binfreq `options' quantiles(10 30 50 70 90)
        matrix list r(quantiles_binfreq)

        gquantiles __x4 = `anything', pctile altdef binfreq `options' cutoffs(10 30 50 70 90)
        matrix list r(cutoffs_binfreq)

        cap gquantiles __x5 = `anything', pctile altdef binfreq `options' cutquantiles(ru)
        assert _rc == 198
        gquantiles __x5 = `anything', pctile altdef binfreq(__xf5) `options' cutquantiles(ru)
        gquantiles __x5 = `anything', pctile altdef binfreq(__xf5) `options' cutquantiles(ru) replace



        cap sum `anything', meanonly
        if ( _rc ) {
            tempvar zz
            qui gen `zz' = `anything'
            qui sum `zz', meanonly
        }
        local rmin = r(min)
        local rmax = r(max)
        gquantiles `anything', altdef _pctile `options' nq(10) minmax
        disp abs(`rmin' - r(min)), abs(`rmax' - r(max))
        cap gquantiles `anything' in 1/5, altdef _pctile `options' nq(10) minmax
        assert inlist(_rc, 0, 2000)
        cap gquantiles `anything' in 1/5, altdef _pctile `options' nq(10) minmax strict
        assert inlist(_rc, 198, 2000)

        cap gquantiles `anything', altdef _pctile `options' cutpoints(__p1) minmax
        assert _rc == 198
        gquantiles `anything', _pctile altdef `options' cutpoints(__p1) pctile(__p2) replace minmax
        disp abs(`rmin' - r(min)), abs(`rmax' - r(max))

        gquantiles `anything', _pctile altdef `options' quantiles(10 30 50 70 90) minmax
        disp abs(`rmin' - r(min)), abs(`rmax' - r(max))

        cap gquantiles `anything', _pctile altdef `options' cutoffs(10 30 50 70 90) minmax
        assert _rc == 198
        gquantiles `anything', _pctile altdef `options' cutoffs(10 30 50 70 90) binfreq minmax
        disp abs(`rmin' - r(min)), abs(`rmax' - r(max))

        cap gquantiles `anything', _pctile altdef `options' cutquantiles(ru) minmax
        assert _rc == 198
        gquantiles `anything', _pctile altdef `options' cutpoints(__p1)  xtile(__x5) replace minmax
        disp abs(`rmin' - r(min)), abs(`rmax' - r(max))
    }
end

***********************************************************************
*                        Internal Consistency                         *
***********************************************************************

capture program drop compare_gquantiles
program compare_gquantiles
    syntax, [NOIsily noaltdef wgt(str) *]
    local options `options' `noisily'

    gettoken wfun wfoo: wgt
    local wfun `wfun'
    local wfoo `wfoo'
    if ( `"`wfoo'"' == "mix" ) {
        local wcall_a "[aw = unif_0_100]"
        local wcall_f "[fw = int_unif_0_100]"
        local wcall_p "[pw = float_unif_0_1]"
        local wgen_a qui gen unif_0_100 = 100 * runiform() if mod(_n, 100)
        local wgen_f qui gen int_unif_0_100 = int(100 * runiform()) if mod(_n, 100)
        local wgen_p qui gen float_unif_0_1 = runiform() if mod(_n, 100)
    }

    compare_gquantiles_stata, n(10000) bench(10) `altdef' `options' wgt(`wcall_a') wgen(`wgen_a')

    local N = trim("`: di %15.0gc _N'")
    di _n(1) "{hline 80}" _n(1) "consistency_gquantiles_pctile_xtile, N = `N', `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(10000) skipstr
    qui expand 10
    qui `noisily' random_draws, random(2) double
    gen long   ix = _n
    gen double ru = runiform() * 100
    qui replace ix = . if mod(_n, 10000) == 0
    qui replace ru = . if mod(_n, 10000) == 0
    qui sort random1
    `wgen_a'
    `wgen_f'
    `wgen_p'

    _consistency_inner_gquantiles, `options' wgt(`wcall_f')
    _consistency_inner_gquantiles in 1 / 5, `options' corners wgt(`wcall_p')

    local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
    local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
    local from = cond(`in1' < `in2', `in1', `in2')
    local to   = cond(`in1' > `in2', `in1', `in2')
    _consistency_inner_gquantiles in `from' / `to', `options' wgt(`wcall_a')

    _consistency_inner_gquantiles if random2 > 0, `options' wgt(`wcall_p')

    local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
    local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
    local from = cond(`in1' < `in2', `in1', `in2')
    local to   = cond(`in1' > `in2', `in1', `in2')
    _consistency_inner_gquantiles `anything' if random2 < 0 in `from' / `to', `options' wgt(`wcall_f')

    local N = trim("`: di %15.0gc _N'")
    di _n(1) "{hline 80}" _n(1) "consistency_gquantiles_internals, N = `N', `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop _consistency_inner_gquantiles
program _consistency_inner_gquantiles
    syntax [if] [in], [tol(real 1e-15) tolmat(real 1e-6) NOIsily corners *]

    if ( "`corners'" == "" ) {
    _consistency_inner_full double1 `if' `in', `options'
    _consistency_inner_full double3 `if' `in', `options'
    _consistency_inner_full ru      `if' `in', `options'

    _consistency_inner_full int1 `if' `in', `options'
    _consistency_inner_full int3 `if' `in', `options'
    _consistency_inner_full ix   `if' `in', `options'

    _consistency_inner_full int1^2 + 3 * double1          `if' `in', `options'
    _consistency_inner_full log(double1) + 2 * int1       `if' `in', `options'
    _consistency_inner_full exp(double3) + int1 * double3 `if' `in', `options'
    }
    else {
    _consistency_inner_full double1 `if' `in', `options'
    _consistency_inner_full ru      `if' `in', `options'
    _consistency_inner_full int1    `if' `in', `options'
    _consistency_inner_full ix      `if' `in', `options'
    }
end

capture program drop _consistency_inner_full
program  _consistency_inner_full
    syntax anything [if] [in], [wgt(str) *]

    if ( "`wgt'" != "" ) {
        local wtxt " `wgt'"
    }

    if ( "`if'`in'" != "" ) {
        local ifinstr ""
        if ( "`if'" != "" ) local ifinstr `ifinstr' [`if']
        if ( "`in'" != "" ) local ifinstr `ifinstr' [`in']
    }

    local hlen = length("Internal consistency for gquantiles `anything', `ifinstr'`wtxt'")
    di as txt _n(1) "Internal consistency for gquantiles `anything', `ifinstr'`wtxt'" _n(1) "{hline `hlen'}" _n(1)

    _consistency_inner_nq `anything' `if' `in', `options' wgt(`wgt') nq(2)
    _consistency_inner_nq `anything' `if' `in', `options' wgt(`wgt') nq(10)
    _consistency_inner_nq `anything' `if' `in', `options' wgt(`wgt') nq(100)
    _consistency_inner_nq `anything' `if' `in', `options' wgt(`wgt') nq(801)
    _consistency_inner_nq `anything' `if' `in', `options' wgt(`wgt') nq(`=_N + 1')

    if ( `"`wgt'"' != "" ) exit 0

    _consistency_inner_nq `anything' `if' `in', altdef `options' nq(2)
    _consistency_inner_nq `anything' `if' `in', altdef `options' nq(10)
    _consistency_inner_nq `anything' `if' `in', altdef `options' nq(100)
    _consistency_inner_nq `anything' `if' `in', altdef `options' nq(801)
    _consistency_inner_nq `anything' `if' `in', altdef `options' nq(`=_N + 1')
end

capture program drop _consistency_inner_nq
program _consistency_inner_nq
    syntax anything [if] [in], [tol(real 1e-15) tolmat(real 1e-6) nq(real 2) wgt(str) *]
    cap drop __*
    local rc = 0

    qui {
    gquantiles __p1 = `anything' `if' `in' `wgt', pctile `options' nq(`nq') genp(__g1) binfreq(__f1) xtile(__x1)
    gquantiles __p2 = `anything' `if' `in' `wgt', pctile `options' cutpoints(__p1) binfreq(__f2) xtile(__x2)
    if ( `nq' <= 801 ) {
        if ( `nq' > 10 ) set matsize `=`nq' - 1'
        mkmat __g1 in 1 / `=`nq' - 1', mat(__mg1)
        mkmat __p1 in 1 / `=`nq' - 1', mat(__mp1)

        gquantiles __p3 = `anything' `if' `in' `wgt', pctile `options' quantmatrix(__mg1) binfreq binfreq(__f3) xtile(__x3)
        scalar ___s3   = r(nqused)
        matrix ___mp3  = r(quantiles_used)
        matrix ___mf3  = r(quantiles_binfreq)

        gquantiles __p4 = `anything' `if' `in' `wgt', pctile `options' cutmatrix(__mp1) binfreq binfreq(__f4) xtile(__x4)
        scalar ___s4   = r(nqused)
        matrix ___mp4  = r(cutoffs_used)
        matrix ___mf4  = r(cutoffs_binfreq)
    }
    gquantiles __p5 = `anything' `if' `in' `wgt', pctile `options' cutquantiles(__g1) binfreq(__f5) xtile(__x5)
    }

    * NOTE(mauricio): At one point I do exp(X) which blows this up.
    * xtile and binfreq are still good, but the pctile discrepancy
    * is relatively large because of it. Hence I also do relative
    * comparisons here. // 2017-11-19 13:04 EST

    _compare_inner_nqvars `tol' `tolmat' `nq'
    if ( `rc' ) {
        tempvar relcmp
        qui gen double `relcmp' = __p1 * `tolmat' in 1/`=`nq'-1'
        qui replace `relcmp'    = cond(`relcmp' < `tolmat', `tolmat', `relcmp') in 1/`=`nq'-1'
        local rc = 0
        foreach perc of varlist __p? {
            cap assert (abs(__p1 - `perc') < `relcmp') | mi(__p1)
            local rc = max(`rc', _rc)
        }
        if ( `rc' ) {
            di as err "    consistency_internal_gquantiles (failed): pctile via nq(`nq') `options' not all equal"
            exit `rc'
        }
        else {
            qui su `relcmp'
            _compare_inner_nqvars `tol' `=r(max)' `nq'
            if ( `rc' ) {
                di as err "    consistency_internal_gquantiles (failed): pctile via nq(`nq') `options' not all equal"
                exit `rc'
            }
        }
    }

    qui {
    cap drop __*
    gquantiles __x1 = `anything' `if' `in' `wgt', xtile `options' nq(`nq') genp(__g1) binfreq(__f1) pctile(__p1)
    gquantiles __x2 = `anything' `if' `in' `wgt', xtile `options' cutpoints(__p1) binfreq(__f2) pctile(__p2)
    if ( `nq' <= 801 ) {
        if ( `nq' > 10 ) set matsize `=`nq' - 1'
        mkmat __g1 in 1 / `=`nq' - 1', mat(__mg1)
        mkmat __p1 in 1 / `=`nq' - 1', mat(__mp1)

        gquantiles __x3 = `anything' `if' `in' `wgt', xtile `options' quantmatrix(__mg1) binfreq binfreq(__f3) pctile(__p3)
        scalar ___s3   = r(nqused)
        matrix ___mp3  = r(quantiles_used)
        matrix ___mf3  = r(quantiles_binfreq)

        gquantiles __x4 = `anything' `if' `in' `wgt', xtile `options' cutmatrix(__mp1) binfreq binfreq(__f4) pctile(__p4)
        scalar ___s4   = r(nqused)
        matrix ___mp4  = r(cutoffs_used)
        matrix ___mf4  = r(cutoffs_binfreq)
    }
    gquantiles __x5 = `anything' `if' `in' `wgt', xtile `options' cutquantiles(__g1) binfreq(__f5) pctile(__p5)
    }

    _compare_inner_nqvars `tol' `tolmat' `nq'
    if ( `rc' ) {
        tempvar relcmp
        qui gen double `relcmp' = __p1 * `tolmat' in 1/`=`nq'-1'
        qui replace `relcmp'    = cond(`relcmp' < `tolmat', `tolmat', `relcmp') in 1/`=`nq'-1'
        local rc = 0
        foreach perc of varlist __p? {
            cap assert (abs(__p1 - `perc') < `relcmp') | mi(__p1)
            local rc = max(`rc', _rc)
        }
        if ( `rc' ) {
            di as err "    consistency_internal_gquantiles (failed): xtile via nq(`nq') `options' not all equal"
            exit `rc'
        }
        else {
            qui su `relcmp'
            _compare_inner_nqvars `tol' `=r(max)' `nq'
            if ( `rc' ) {
                di as err "    consistency_internal_gquantiles (failed): xtile via nq(`nq') `options' not all equal"
                exit `rc'
            }
        }
    }

    qui if ( `nq' <= 801 ) {
        if ( `nq' > 10 ) set matsize `=`nq' - 1'
        mkmat __g1 in 1 / `=`nq' - 1', mat(__mg1)
        mkmat __p1 in 1 / `=`nq' - 1', mat(__mp1)

        gquantiles `anything' `if' `in' `wgt', _pctile `options' nq(`nq') genp(__g1) binfreq(__f1) pctile(__p1) xtile(__x1) replace
        gquantiles `anything' `if' `in' `wgt', _pctile `options' cutpoints(__p1) binfreq(__f2) pctile(__p2) xtile(__x2) replace

        gquantiles `anything' `if' `in' `wgt', _pctile `options' quantmatrix(__mg1) binfreq binfreq(__f3) pctile(__p3) xtile(__x3) replace
        scalar ___s3   = r(nqused)
        matrix ___mp3  = r(quantiles_used)
        matrix ___mf3  = r(quantiles_binfreq)

        gquantiles `anything' `if' `in' `wgt', _pctile `options' cutmatrix(__mp1) binfreq binfreq(__f4) pctile(__p4) xtile(__x4) replace
        scalar ___s4   = r(nqused)
        matrix ___mp4  = r(cutoffs_used)
        matrix ___mf4  = r(cutoffs_binfreq)

        gquantiles `anything' `if' `in' `wgt', _pctile `options' cutquantiles(__g1) binfreq(__f5) pctile(__p5) xtile(__x5) replace

        _compare_inner_nqvars `tol' `tolmat' `nq'
        if ( `rc' ) {
            tempvar relcmp
            qui gen double `relcmp' = __p1 * `tolmat' in 1/`=`nq'-1'
            qui replace `relcmp'    = cond(`relcmp' < `tolmat', `tolmat', `relcmp') in 1/`=`nq'-1'
            local rc = 0
            foreach perc of varlist __p? {
                cap assert (abs(__p1 - `perc') < `relcmp') | mi(__p1)
                local rc = max(`rc', _rc)
            }
            if ( `rc' ) {
                di as err "    consistency_internal_gquantiles (failed): _pctile via nq(`nq') `options' not all equal"
                exit `rc'
            }
            else {
                qui su `relcmp'
                _compare_inner_nqvars `tol' `=r(max)' `nq'
                if ( `rc' ) {
                    di as err "    consistency_internal_gquantiles (failed): _pctile via nq(`nq') `options' not all equal"
                    exit `rc'
                }
            }
        }
    }

    di as txt "    consistency_internal_gquantiles (passed): xtile, pctile, and _pctile via nq(`nq') `options'" ///
              "(tol = `:di %6.2g `tol'', tolmat = `:di %6.2g `tolmat'')"
end

capture program drop _compare_inner_nqvars
program _compare_inner_nqvars, rclass
    args tol tolmat nq
    local rc = 0

    * NOTE(mauricio): Percentiles need not be super precise. The
    * important property is that they preserve xtile and binfreq, which
    * is why that tolerance is super small whereas the tolerance for
    * percentiles is larger. // 2017-11-19 12:33 EST

    _compare_inner_nqvars_rc __p1 __p2 `tolmat'
    local rc = max(`rc', `r(rc)')
    _compare_inner_nqvars_rc __f1 __f2 `tol'
    local rc = max(`rc', `r(rc)')
    _compare_inner_nqvars_rc __x1 __x2 `tol'
    local rc = max(`rc', `r(rc)')

    if ( `nq' <= 801 ) {
        _compare_inner_nqvars_rc __p1 __p3 `tolmat'
        local rc = max(`rc', `r(rc)')
        _compare_inner_nqvars_rc __f1 __f3 `tol'
        local rc = max(`rc', `r(rc)')
        _compare_inner_nqvars_rc __x1 __x3 `tol'
        local rc = max(`rc', `r(rc)')

        _compare_inner_nqvars_rc __p1 __p4 `tolmat'
        local rc = max(`rc', `r(rc)')
        _compare_inner_nqvars_rc __f1 __f4 `tol'
        local rc = max(`rc', `r(rc)')
        _compare_inner_nqvars_rc __x1 __x4 `tol'
        local rc = max(`rc', `r(rc)')

        assert scalar(___s3) == scalar(___s4)
        cap mata: assert(all(abs(st_matrix("___mp3")  :- st_matrix("___mp4"))  :< `tolmat'))
        local rc = max(`rc', _rc)
        cap mata: assert(all(abs(st_matrix("___mf3")  :- st_matrix("___mf4"))  :< `tolmat'))
        local rc = max(`rc', _rc)

        cap mata: assert(all(abs(st_matrix("___mp3")  :- st_data(1::st_numscalar("___s3"), "__p1"))  :< `tolmat'))
        local rc = max(`rc', _rc)
        cap mata: assert(all(abs(st_matrix("___mf3")  :- st_data(1::st_numscalar("___s3"), "__f3"))  :< `tolmat'))
        local rc = max(`rc', _rc)

        cap mata: assert(all(abs(st_matrix("___mp4")  :- st_data(1::st_numscalar("___s4"), "__p1"))  :< `tolmat'))
        local rc = max(`rc', _rc)
        cap mata: assert(all(abs(st_matrix("___mf4")  :- st_data(1::st_numscalar("___s4"), "__f4"))  :< `tolmat'))
        local rc = max(`rc', _rc)
    }

    _compare_inner_nqvars_rc __p1 __p5 `tolmat'
    local rc = max(`rc', `r(rc)')
    _compare_inner_nqvars_rc __f1 __f5 `tol'
    local rc = max(`rc', `r(rc)')
    _compare_inner_nqvars_rc __x1 __x5 `tol'
    local rc = max(`rc', `r(rc)')

    c_local rc `rc'
end

capture program drop _compare_inner_nqvars_rc
program _compare_inner_nqvars_rc, rclass
    args v1 v2 tol
    cap assert `v1' == `v2'
    if ( _rc ) {
        cap assert abs(`v1' - `v2') < `tol' | mi(`v1')
    }
    return scalar rc = _rc
end


***********************************************************************
*                               Compare                               *
***********************************************************************

capture program drop bench_gquantiles
program bench_gquantiles
    syntax, [bench(int 10) n(int 10000) *]
    compare_inner_quantiles, n(`n') bench(`bench') benchmode qopts(p(0.1 5 10 30 50 70 90 95 99.9))  qwhich(_pctile)
    compare_inner_quantiles, n(`n') bench(`bench') benchmode qopts(nq(10))  qwhich(_pctile)
    compare_inner_quantiles, n(`n') bench(`bench') benchmode qopts(nq(10))  qwhich(xtile)
    compare_inner_quantiles, n(`n') bench(`bench') benchmode qopts(nq(10))  qwhich(pctile)
end

capture program drop compare_gquantiles_stata
program compare_gquantiles_stata
    syntax, [bench(int 10) n(int 10000) noaltdef *]

    if ( "`altdef'" != "noaltdef" ) {
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(500))  qwhich(xtile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(100))  qwhich(xtile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(10))   qwhich(xtile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(2))    qwhich(xtile) `options'

    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef p(0.1 5 10 30 50 70 90 95 99.9)) qwhich(_pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(801)) qwhich(_pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(100)) qwhich(_pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(10))  qwhich(_pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(2))   qwhich(_pctile) `options'

    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(500))  qwhich(pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(100))  qwhich(pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(10))   qwhich(pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(2))    qwhich(pctile) `options'
    }

    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(500))  qwhich(pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(100))  qwhich(pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(10))   qwhich(pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(2))    qwhich(pctile) `options'

    compare_inner_quantiles, n(`n') bench(`bench') qopts(p(0.1 5 10 30 50 70 90 95 99.9)) qwhich(_pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(801)) qwhich(_pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(100)) qwhich(_pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(10))  qwhich(_pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(2))   qwhich(_pctile) `options'

    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(500))  qwhich(xtile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(100))  qwhich(xtile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(10))   qwhich(xtile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(2))    qwhich(xtile) `options'
end

capture program drop compare_inner_quantiles
program compare_inner_quantiles
    syntax, [bench(int 5) n(real 100000) benchmode wgen(str) *]
    local options `options' `benchmode'

    qui `noisily' gen_data, n(`n') skipstr
    qui expand `bench'
    qui `noisily' random_draws, random(2) double
    gen long   ix = _n
    gen double ru = runiform() * 100
    qui replace ix = . if mod(_n, `n') == 0
    qui replace ru = . if mod(_n, `n') == 0
    qui sort random1
    `wgen'

    _compare_inner_gquantiles, `options'

    if ( "`benchmode'" == "" ) {
        _compare_inner_gquantiles in 1 / 5, `options' corners

        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_gquantiles in `from' / `to', `options'

        _compare_inner_gquantiles if random2 > 0, `options'

        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_gquantiles `anything' if random2 < 0 in `from' / `to', `options'
    }
end

***********************************************************************
*                             Comparisons                             *
***********************************************************************

capture program drop _compare_inner_gquantiles
program _compare_inner_gquantiles
    syntax [if] [in], [tol(real 1e-6) NOIsily qopts(str) qwhich(str) benchmode table corners wgt(str) *]

    if ( "`if'`in'" != "" ) {
        local ifinstr ""
        if ( "`if'" != "" ) local ifinstr `ifinstr' [`if']
        if ( "`in'" != "" ) local ifinstr `ifinstr' [`in']

        if ( ("`corners'" != "")  & ("`qwhich'" == "xtile")) {
            disp as txt "(note: skipped `ifinstr' tests for xtile; this test is for pctile and _pctile only)"
            exit 0
        }
    }

    local options `options' `benchmode' `table' qopts(`qopts') wgt(`wgt')

    local N = trim("`: di %15.0gc _N'")
    di as txt _n(1)
    di as txt "Compare `qwhich'"
    di as txt "     - opts:   `qopts'"
    di as txt "     - if in:  `ifinstr'"
    di as txt "     - weight: `wgt'"
    di as txt "     - obs:    `N'"
    if ( ("`benchmode'" != "") | ("`table'" != "") ) {
    if ( "`qwhich'" == "xtile" ) {
    di as txt "    xtile | fastxtile | gquantiles | ratio (x/g) | ratio (f/g) | varlist"
    di as txt "    ----- | --------- | ---------- | ----------- | ----------- | -------"
    }
    if ( "`qwhich'" == "pctile" ) {
    di as txt "    pctile | gquantiles | ratio (p/g) | varlist"
    di as txt "    ------ | ---------- | ----------- | -------"
    }
    if ( "`qwhich'" == "_pctile" ) {
    di as txt "    _pctile | gquantiles | ratio (_/g) | varlist"
    di as txt "    ------- | ---------- | ----------- | -------"
    }
    }

    if ( "`corners'" == "" ) {
    _compare_inner_`qwhich' double1 `if' `in', `options' note("~ U(0,  1000), no missings, groups of size 10")
    _compare_inner_`qwhich' double3 `if' `in', `options' note("~ N(10, 5), many missings, groups of size 10")
    _compare_inner_`qwhich' ru      `if' `in', `options' note("~ N(0, 100), few missings, unique")

    _compare_inner_`qwhich' int1 `if' `in', `options' note("discrete (no missings, many groups)")
    _compare_inner_`qwhich' int3 `if' `in', `options' note("discrete (many missings, few groups)")
    _compare_inner_`qwhich' ix   `if' `in', `options' note("discrete (few missings, unique)")

    _compare_inner_`qwhich' int1^2 + 3 * double1          `if' `in', `options'
    _compare_inner_`qwhich' log(double1) + 2 * int1       `if' `in', `options'
    _compare_inner_`qwhich' exp(double3) + int1 * double3 `if' `in', `options'
    }
    else {
    _compare_inner_`qwhich' double1 `if' `in', `options' note("~ U(0,  1000), no missings, groups of size 10")
    _compare_inner_`qwhich' ru      `if' `in', `options' note("~ N(0, 100), few missings, unique")
    _compare_inner_`qwhich' int1    `if' `in', `options' note("discrete (no missings, many groups)")
    _compare_inner_`qwhich' ix      `if' `in', `options' note("discrete (few missings, unique)")
    }
end

***********************************************************************
*                              Internals                              *
***********************************************************************

capture program drop _compare_inner_xtile
program _compare_inner_xtile
    syntax anything [if] [in], [note(str) benchmode table qopts(str) sorted wgt(str) *]
    tempvar xtile fxtile gxtile

    if ( "`sorted'" != "" ) {
        cap sort `anything'
        if ( _rc ) {
            tempvar sort
            qui gen double `sort' = `anything'
            sort `sort'
        }
    }

    timer clear
    timer on 43
    qui gquantiles `gxtile' = `anything' `if' `in' `wgt', xtile `qopts' `options'
    timer off 43
    qui timer list
    local time_gxtile = r(t43)

    timer clear
    timer on 42
    qui xtile `xtile' = `anything' `if' `in' `wgt', `qopts'
    timer off 42
    qui timer list
    local time_xtile = r(t42)

    timer clear
    timer on 44
    cap fastxtile `fxtile' = `anything' `if' `in' `wgt', `qopts'
    local rc_f = _rc
    timer off 44
    qui timer list
    local time_fxtile = r(t44)
    if ( `rc_f' ) {
        local time_fxtile = .
        di "(note: fastxtile failed where xtile succeeded)"
    }

    local warnings 0
    cap assert `xtile' == `gxtile'
    if ( _rc ) {
        tempvar diff
        qui gen `diff' = `xtile' - `gxtile'
        gtoplevelsof `diff', nowarn
        if ( strpos("`qopts'", "altdef") ) {
            local qopts: subinstr local qopts "altdef" " ", all
            qui gquantiles `anything' `if' `in', xtile(`gxtile') `qopts' replace
            cap assert `xtile' == `gxtile'
            if ( _rc ) {
                di as err "    compare_xtile (failed): gquantiles xtile = `anything' gave different levels to xtile"
                di as err ""
                di as err `"Stata's built-in xtile, altdef can sometimes be imprecise. See"'
                di as err ""
                di as err `"    {browse "https://www.statalist.org/forums/forum/general-stata-discussion/general/1418732"}"'
                di as err ""
                di as err `"Add option {cmd:noaltdef} to compare_gquantiles to skip this check."'
                count if `xtile' != `gxtile'
                sum `xtile' `gxtile' `diff'
                l `xtile' `gxtile' `diff' in 1/20
            }
            else {
                qui findfile xtile.ado
                di as err  "    compare_xtile (???)"                                                               ///
                     _n(2) "Note: gquantiles xtile = `anything', altdef gave different levels to xtile, altdef."   ///
                     _n(1) "However, gquantiles xtile = `anything' without altdef was the same.  On some systems," ///
                     _n(1) "xtile.ado has a typo in line 135 that explains this. Please go to:"                    ///
                     _n(2) `"    {stata doedit `"`r(fn)'"'}"'                                                      ///
                     _n(2) "and change 'altdev' to 'altdef' (or add option {cmd:noaltdef} to compare_gquantiles)."
            }
            exit 198
        }
        else {
            qui count if `xtile' != `gxtile'
            local fail = `r(N)'
            local warnings 1
            if ( `=max(`=`fail' / _N' < 0.05, `fail' == 1)' & ("`wgt'" != "") ) {
                di as err "    compare_xtile (warning): gquantiles xtile = `anything' gave different levels to xtile"
                di as err ""
                di as err "using weights in xtile seems to give incorrect results under some" ///
                    _n(1) "circumstances. Only `fail' / `=_N' xtiles were off."
                di as err ""
            }
            else {
                di as err "    compare_xtile (failed): gquantiles xtile = `anything' gave different levels to xtile"
                cap assert `xtile' == `fxtile'
                if ( _rc & (`rc_f' == 0) ) {
                    di as txt "    (note: fastxtile also gave different levels)"
                }
                count if `xtile' != `gxtile'
                sum `xtile' `gxtile' `diff'
                l `xtile' `gxtile' `diff' in 1/20
                exit 198
            }
        }
    }

    cap assert `xtile' == `fxtile'
    if ( _rc & (`rc_f' == 0) ) {
        di as txt "    (note: fastxtile gave different levels to xtile)"
    }

    if ( ("`benchmode'" == "") & (`warnings' == 0) ) {
        di as txt "    compare_xtile (passed): gquantiles xtile = `anything' was the same as xtile"
        exit 0
    }

    if ( ("`table'" != "") | ("`benchmode'" != "") ) {
        local rs = `time_xtile'  / `time_gxtile'
        local rf = `time_fxtile' / `time_gxtile'
        di as txt "    `:di %5.3g `time_xtile'' | `:di %9.3g `time_fxtile'' | `:di %10.3g `time_gxtile'' | `:di %11.3g `rs'' | `:di %11.3g `rf'' | `anything' (`note')"
    }
end

capture program drop _compare_inner_pctile
program _compare_inner_pctile
    syntax anything [if] [in], [benchmode table qopts(str) reltol(real 1e-8) tol(real 1e-6) note(str) sorted wgt(str) *]
    tempvar pctile pctpct gpctile gpctpct

    if ( "`sorted'" != "" ) {
        cap sort `anything'
        if ( _rc ) {
            tempvar sort
            qui gen double `sort' = `anything'
            sort `sort'
        }
    }

    if ( "`benchmode'" == "" ) {
        local gqopts `qopts' genp(`gpctpct')
        local  qopts `qopts' genp(`pctpct')
    }
    else {
        local gqopts `qopts'
        local  qopts `qopts'
    }

    timer clear
    timer on 43
    qui gquantiles `gpctile' = `anything' `if' `in' `wgt', pctile `gqopts' `options'
    timer off 43
    qui timer list
    local time_gpctile = r(t43)

    timer clear
    timer on 42
    qui pctile `pctile' = `anything' `if' `in' `wgt', `qopts'
    timer off 42
    qui timer list
    local time_pctile = r(t42)

    local warnings 0
    tempvar comp
    qui gen double `comp' = .
    * qui gen double `comp' = `pctile' * `reltol' if !mi(`pctile')
    * qui replace `comp'    = cond(`comp' < `tol', `tol', `comp') if !mi(`pctile')
    cap assert abs(`pctile' - `gpctile') < `tol' | (mi(`pctile') & mi(`gpctile'))
    if ( _rc ) {
        di as err "    compare_pctile (warning): gquantiles pctile = `anything' gave different percentiles to pctile (tol = `:di %6.2g `tol'')"
        if ( strpos("`qopts'", "altdef") ) {
                di as err ""
                di as err `"Stata's built-in pctile, altdef can sometimes be imprecise. See"'
                di as err ""
                di as err `"    {browse "https://www.statalist.org/forums/forum/general-stata-discussion/general/1418732"}"'
                di as err ""
                di as err `"Add option {cmd:noaltdef} to compare_gquantiles to skip this check."'
        }

        tempvar gpctile2
        qui gen `:type `pctile'' `gpctile2' = `gpctile'
        qui replace `comp' = abs(1 - `gpctile2' / `pctile') if !mi(`pctile') & !mi(`gpctile')
        cap assert abs(`comp') < `reltol' | (mi(`pctile') & mi(`gpctile'))
        * cap assert abs(`pctile' - `gpctile2') < `comp' | ( mi(`pctile') & mi(`gpctile'))
        if ( _rc ) {
            local warnings 1
            qui sum `comp' if !(abs(`comp') < `reltol' | (mi(`pctile') & mi(`gpctile')))
            local error: disp %9.3g `r(mean)'
            local error `error'
            qui count if !mi(`pctile') | !mi(`gpctile')
            local total = `r(N)'
            qui count if !(abs(`comp') < `reltol' | (mi(`pctile') & mi(`gpctile')))
            local fail = `r(N)'
            if ( `=max(`=`fail' / `total'' < 0.1, `fail' == 1)' & ("`wgt'" != "") ) {
                di as err "    compare_pctile (warning): gquantiles pctile = `anything' gave different percentiles to pctile (reltol = `:di %6.2g `reltol'')"
                di as err ""
                di as err "using weights in pctile seems to give incorrect results under some"     ///
                    _n(1) "circumstances. Only `fail' / `total' pctiles were off by an average of" ///
                    _n(1) "`error'. This is likely due to this quirk in pctile rather than an"     ///
                    _n(1) "error in your code (pay special attention to the weighted gcollapse"    ///
                    _n(1) "comparison to check)"
                di as err ""
            }
            else {
                di as err "    compare_pctile (failed): gquantiles pctile = `anything' gave different percentiles to pctile (reltol = `:di %6.2g `reltol'')"
                di as err "`fail' / `total' failed"
                drop if mi(`pctile') & mi(`gpctile')
                hashsort -`comp' -`pctile' -`gpctile'
                sum `pctile' `gpctile' `comp'
                l `pctile' `gpctile' `comp' in 1/20
                exit 198
            }
        }
    }

    if ( "`benchmode'" == "" ) {
        cap assert abs(`pctpct' - `gpctpct') < `tol' | ( mi(`pctpct') & mi(`gpctpct'))
        if ( _rc ) {
            tempvar gpctpct2
            qui gen `:type `pctpct'' `gpctpct2' = `gpctpct'
            * qui replace `comp' = `pctpct' * `reltol' if !mi(`pctpct')
            * qui replace `comp' = cond(`comp' < `tol', `tol', `comp') if !mi(`pctpct')
            * cap assert abs(`pctpct' - `gpctpct2') < `comp' | ( mi(`pctile') & mi(`gpctile'))
            qui replace `comp' = abs(1 - `gpctpct2' / `pctpct') if !mi(`pctpct') & !mi(`gpctpct')
            cap assert abs(`comp') < `reltol' | (mi(`pctpct') & mi(`gpctpct'))
            if ( _rc ) {
                di as err "    compare_pctile (failed): gquantiles pctile = `anything', genp() gave different percentages to pctile, genp()"
                drop if mi(`pctpct') & mi(`gpctpct')
                hashsort -`comp'
                sum `pctpct' `gpctpct' `comp'
                l `pctpct' `gpctpct' in 1/20
                exit 198
            }
            else if ( `warnings' == 0 ) {
                di as txt "    compare_pctile (passed): gquantiles pctile = `anything', genp() gave similar results to pctile (reltol = `:di %6.2g `reltol'', tol = `:di %6.2g `tol'')"
            }
        }
        else if ( `warnings' == 0 ) {
            di as txt "    compare_pctile (passed): gquantiles pctile = `anything', genp() gave similar results to pctile (reltol = `:di %6.2g `reltol'', tol = `:di %6.2g `tol'')"
        }
    }

    if ( ("`table'" != "") | ("`benchmode'" != "") ) {
        local rs = `time_pctile'  / `time_gpctile'
        di as txt "    `:di %6.3g `time_pctile'' | `:di %10.3g `time_gpctile'' | `:di %11.3g `rs'' | `anything' (`note')"
    }
end

capture program drop _compare_inner__pctile
program _compare_inner__pctile
    syntax anything [if] [in], [benchmode table qopts(str) reltol(real 1e-8) tol(real 1e-6) note(str) sorted wgt(str) *]
    tempvar exp
    qui gen double `exp' = `anything'

    if ( "`sorted'" != "" ) {
        sort `exp'
    }

    timer clear
    timer on 43
    qui gquantiles `exp' `if' `in' `wgt', _pctile `qopts' `options'
    timer off 43
    qui timer list
    local time_gpctile = r(t43)
    local nq = `r(nqused)'
    forvalues q = 1 / `nq' {
        scalar qr_`q' = `r(r`q')'
    }

    timer clear
    timer on 42
    qui _pctile `exp' `if' `in' `wgt', `qopts'
    timer off 42
    qui timer list
    local time_pctile = r(t42)
    forvalues q = 1 / `nq' {
        scalar r_`q' = `r(r`q')'
    }

    local warnings 0
    forvalues q = 1 / `nq' {
        if ( abs(scalar(qr_`q') - scalar(r_`q')) > `tol' ) {

            if ( "`wgt'" == "" ) {
                di as err "    compare__pctile (warning): gquantiles `anything', _pctile gave different percentiles to _pctile (tol = `:di %6.2g `tol'')"
                if ( strpos("`qopts'", "altdef") ) {
                    di as err ""
                    di as err `"Stata's built-in _pctile, altdef can sometimes be imprecise. See"'
                    di as err ""
                    di as err `"    {browse "https://www.statalist.org/forums/forum/general-stata-discussion/general/1418732"}"'
                    di as err ""
                    di as err `"Add option {cmd:noaltdef} to compare_gquantiles to skip this check."'
                }
            }

            * scalar comp = `=scalar(r_`q')' * `reltol'
            * scalar comp = cond(scalar(comp) < `tol', `tol', scalar(comp))
            * if ( abs(scalar(qr_`q') - scalar(r_`q')) > `comp' ) {
            if ( abs(1 - scalar(qr_`q') / scalar(r_`q')) > `reltol' ) {
                if ( "`wgt'" != "" ) {
                    local ++warnings
                    di as err "        compare__pctile (warning): `=scalar(r_`q')' (_pctile) vs `=scalar(qr_`q')'"
                }
                else {
                    di as err "    compare__pctile (failed): gquantiles `anything', _pctile gave different percentiles to _pctile (reltol = `:di %6.2g `reltol'')"
                    qui gquantiles `exp' `if' `in', _pctile `qopts' `options' method(1)
                    local q1r_`q' = `r(r`q')'
                    qui gquantiles `exp' `if' `in', _pctile `qopts' `options' method(2)
                    local q2r_`q' = `r(r`q')'
                    disp "_pctile r(`q') = `=scalar(r_`q')'"
                    disp "gquantiles r(`q') = `=scalar(qr_`q')'"
                    disp "gquantiles, method(1) r(`q') = `q1r_`q''"
                    disp "gquantiles, method(2) r(`q') = `q2r_`q''"
                    exit 198
                }
            }
        }
        cap scalar drop qr_`q'
        cap scalar drop r_`q'
        cap scalar drop comp
    }

    if ( "`benchmode'" == "" ) {
        if ( `warnings' ) {
            di as txt "    compare__pctile (warning): gquantiles `anything', _pctile gave different results to _pctile (reltol = `:di %6.2g `reltol'', tol = `:di %6.2g `tol'')"
            di as err ""
            di as err "using weights in _pctile seems to give incorrect results under some"    ///
                _n(1) "circumstances. The `warnings' _pctiles that were off are likely due to" ///
                _n(1) "this quirk in pctile rather than an error in your code (pay special"    ///
                _n(1) "attention to the weighted gcollapse comparison to check)"
            di as err ""
        }
        else {
            di as txt "    compare__pctile (passed): gquantiles `anything', _pctile gave similar results to _pctile (reltol = `:di %6.2g `reltol'', tol = `:di %6.2g `tol'')"
        }
    }

    if ( ("`table'" != "") | ("`benchmode'" != "") ) {
        local rs = `time_pctile'  / `time_gpctile'
        di as txt "    `:di %7.3g `time_pctile'' | `:di %10.3g `time_gpctile'' | `:di %11.3g `rs'' | `anything' (`note')"
    }
end

***********************************************************************
*                                Misc                                 *
***********************************************************************

capture program drop gquantiles_switch_sanity
program gquantiles_switch_sanity
    args ver

    di _n(1) "{hline 80}"
    if ( "`ver'" == "v1" ) {
        di "gquantiles_switch_sanity (many duplicates)"
    }
    else if ( "`ver'" == "v2" ) {
        di "gquantiles_switch_sanity (some duplicates)"
    }
    else {
        di "gquantiles_switch_sanity (no duplicates)"
    }
    di "{hline 80}" _n(1)


    di as txt ""
    di as txt "Testing whether gquantiles method switch code is sane for quantiles."
    di as txt "The table shows the actual ratio between method 1 and method 2 vs the"
    di as txt "ratio used to decide between the two. Method 2 is chosen if the ratio"
    di as txt "in parenthesis is > 1, and method 1 is chosen otherwise."
    di as txt ""
    di as txt "    - Good choice: Both are larger than 1 or less than 1."
    di as txt "    - OK choice: Actual ratio is close to 1 and decision ratio was off."
    di as txt "    - Poor choice: Actual ratio is far from 1 and decision ratio was off."
    di as txt ""
    di as txt "I think 'far from one' is a deviation of 0.2 or more."
    di as txt ""
    di as txt "|            N |   nq |        pctile | pctile, binfreq | pctile, binfreq, xtile |"
    di as txt "| ------------ | ---- | ------------- | --------------- | ---------------------- |"
    _gquantiles_switch_nq   100000  2 `ver'
    _gquantiles_switch_nq   100000  5 `ver'
    _gquantiles_switch_nq   100000 10 `ver'
    _gquantiles_switch_nq   100000 20 `ver'
    _gquantiles_switch_nq   100000 30 `ver'
    _gquantiles_switch_nq   100000 40 `ver'
    di as txt "| ------------ | ---- | ------------- | --------------- | ---------------------- |"
    _gquantiles_switch_nq  1000000  2 `ver'
    _gquantiles_switch_nq  1000000  5 `ver'
    _gquantiles_switch_nq  1000000 10 `ver'
    _gquantiles_switch_nq  1000000 20 `ver'
    _gquantiles_switch_nq  1000000 30 `ver'
    _gquantiles_switch_nq  1000000 40 `ver'
    di as txt "| ------------ | ---- | ------------- | --------------- | ---------------------- |"
    _gquantiles_switch_nq 10000000  2 `ver'
    _gquantiles_switch_nq 10000000  5 `ver'
    _gquantiles_switch_nq 10000000 10 `ver'
    _gquantiles_switch_nq 10000000 20 `ver'
    _gquantiles_switch_nq 10000000 30 `ver'
    _gquantiles_switch_nq 10000000 40 `ver'

    di as txt ""
    di as txt "Testing whether gquantiles method switch code is sane for cutoffs."
    di as txt "The table shows the actual ratio between method 1 and method 2 vs the"
    di as txt "ratio used to decide between the two. Method 2 is chosen if the ratio"
    di as txt "in parenthesis is > 1, and method 1 is chosen otherwise. Note that"
    di as txt "there is no quantile selection here, so the rule must be different."
    di as txt ""
    di as txt "    - Good choice: Both are larger than 1 or less than 1."
    di as txt "    - OK choice: Actual ratio is close to 1 and decision ratio was off."
    di as txt "    - Poor choice: Actual ratio is far from 1 and decision ratio was off."
    di as txt ""
    di as txt "I think 'far from one' is a deviation of 0.2 or more."
    di as txt ""
    di as txt "|            N | cutoffs |        pctile | pctile, binfreq | pctile, binfreq, xtile |"
    di as txt "| ------------ | ------- | ------------- | --------------- | ---------------------- |"
    _gquantiles_switch_cutoffs   100000    2 `ver'
    _gquantiles_switch_cutoffs   100000   50 `ver'
    _gquantiles_switch_cutoffs   100000  100 `ver'
    _gquantiles_switch_cutoffs   100000  200 `ver'
    _gquantiles_switch_cutoffs   100000  500 `ver'
    _gquantiles_switch_cutoffs   100000 1000 `ver'
    di as txt "| ------------ | ------- | ------------- | --------------- | ---------------------- |"
    _gquantiles_switch_cutoffs  1000000    2 `ver'
    _gquantiles_switch_cutoffs  1000000   50 `ver'
    _gquantiles_switch_cutoffs  1000000  100 `ver'
    _gquantiles_switch_cutoffs  1000000  200 `ver'
    _gquantiles_switch_cutoffs  1000000  500 `ver'
    _gquantiles_switch_cutoffs  1000000 1000 `ver'
    di as txt "| ------------ | ------- | ------------- | --------------- | ---------------------- |"
    _gquantiles_switch_cutoffs 10000000    2 `ver'
    _gquantiles_switch_cutoffs 10000000   50 `ver'
    _gquantiles_switch_cutoffs 10000000  100 `ver'
    _gquantiles_switch_cutoffs 10000000  200 `ver'
    _gquantiles_switch_cutoffs 10000000  500 `ver'
    _gquantiles_switch_cutoffs 10000000 1000 `ver'
end

capture program drop _gquantiles_switch_cutoffs
program _gquantiles_switch_cutoffs
    args n nq ver

    qui {
        clear
        if ( "`ver'" == "v1" ) {
            set obs `=`n' / 10000'
            gen x = rnormal() * 100
            expand 10000
        }
        else if ( "`ver'" == "v2" ) {
            set obs `n'
            gen x = int(rnormal() * 100)
        }
        else {
            set obs `n'
            gen x = rnormal() * 100
        }
        gen c = rnormal() in 1 / `nq'

        timer clear
        timer on 42
        gquantiles __p1 = x, pctile c(c) v bench(2) method(1)
        local est_ratio_1 = r(method_ratio)
        timer off 42
        qui timer list
        local time_m1_1 = r(t42)

        timer clear
        timer on 42
        gquantiles __p2 = x, pctile c(c) v bench(2) method(2)
        timer off 42
        qui timer list
        local time_m2_1 = r(t42)

        drop __*
        timer clear
        timer on 42
        gquantiles __p1 = x, pctile binfreq(__bf1) c(c) v bench(2) method(1)
        local est_ratio_2 = r(method_ratio)
        timer off 42
        qui timer list
        local time_m1_2 = r(t42)

        timer clear
        timer on 42
        gquantiles __p2 = x, pctile binfreq(__bf2) c(c) v bench(2) method(2)
        timer off 42
        qui timer list
        local time_m2_2 = r(t42)

        drop __*
        timer clear
        timer on 42
        gquantiles __p1 = x, pctile xtile(__x1) binfreq(__bf1) c(c) v bench(2) method(1)
        local est_ratio_3 = r(method_ratio)
        timer off 42
        qui timer list
        local time_m1_3 = r(t42)

        timer clear
        timer on 42
        gquantiles __p2 = x, pctile xtile(__x2) binfreq(__bf2) c(c) v bench(2) method(2)
        timer off 42
        qui timer list
        local time_m2_3 = r(t42)
    }

    local ratio_1 = `time_m1_1' / `time_m2_1'
    local ratio_2 = `time_m1_2' / `time_m2_2'
    local ratio_3 = `time_m1_3' / `time_m2_3'

        local est_ratio_3 = r(method_ratio)
    di as txt "| `:di %12.0gc `=_N'' | `:di %7.0g `nq'' | `:di %5.3g `ratio_1'' (`:di %5.3g `est_ratio_1'') | `:di %7.3g `ratio_2'' (`:di %5.3g `est_ratio_2'') | `:di %13.3g `ratio_3'' (`:di %6.3g `est_ratio_3'') |
end

capture program drop _gquantiles_switch_nq
program _gquantiles_switch_nq
    args n nq ver

    qui {
        clear
        if ( "`ver'" == "v1" ) {
            set obs `=`n' / 10000'
            gen x = rnormal() * 100
            expand 10000
        }
        else if ( "`ver'" == "v2" ) {
            set obs `n'
            gen x = int(rnormal() * 100)
        }
        else {
            set obs `n'
            gen x = rnormal() * 100
        }

        timer clear
        timer on 42
        gquantiles __p1 = x, pctile nq(`nq') v bench(2) method(1)
        local est_ratio_1 = r(method_ratio)
        timer off 42
        qui timer list
        local time_m1_1 = r(t42)

        timer clear
        timer on 42
        gquantiles __p2 = x, pctile nq(`nq') v bench(2) method(2)
        timer off 42
        qui timer list
        local time_m2_1 = r(t42)

        drop __*
        timer clear
        timer on 42
        gquantiles __p1 = x, pctile binfreq(__bf1) nq(`nq') v bench(2) method(1)
        local est_ratio_2 = r(method_ratio)
        timer off 42
        qui timer list
        local time_m1_2 = r(t42)

        timer clear
        timer on 42
        gquantiles __p2 = x, pctile binfreq(__bf2) nq(`nq') v bench(2) method(2)
        timer off 42
        qui timer list
        local time_m2_2 = r(t42)

        drop __*
        timer clear
        timer on 42
        gquantiles __p1 = x, pctile xtile(__x1) binfreq(__bf1) nq(`nq') v bench(2) method(1)
        local est_ratio_3 = r(method_ratio)
        timer off 42
        qui timer list
        local time_m1_3 = r(t42)

        timer clear
        timer on 42
        gquantiles __p2 = x, pctile xtile(__x2) binfreq(__bf2) nq(`nq') v bench(2) method(2)
        timer off 42
        qui timer list
        local time_m2_3 = r(t42)
    }

    local ratio_1 = `time_m1_1' / `time_m2_1'
    local ratio_2 = `time_m1_2' / `time_m2_2'
    local ratio_3 = `time_m1_3' / `time_m2_3'

    local est_ratio_3 = r(method_ratio)
    di as txt "| `:di %12.0gc `=_N'' | `:di %4.0g `nq'' | `:di %5.3g `ratio_1'' (`:di %5.3g `est_ratio_1'') | `:di %7.3g `ratio_2'' (`:di %5.3g `est_ratio_2'') | `:di %13.3g `ratio_3'' (`:di %6.3g `est_ratio_3'') |
end
capture program drop checks_gquantiles_by
program checks_gquantiles_by
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_gqantiles_by, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(1000)
    qui expand 10
    qui `noisily' random_draws, random(2)
    gen long   ix  = _n
    gen double ru  = runiform() * 100
    gen double rn  = rnormal() * 100
    gen byte   one = 1

    local options `options'  `noisily'

    _checks_gquantiles_by one, `options'

    _checks_gquantiles_by -str_12,              `options'
    _checks_gquantiles_by str_12 -str_32,       `options'
    _checks_gquantiles_by str_12 -str_32 str_4, `options'

    _checks_gquantiles_by -double1,                 `options'
    _checks_gquantiles_by double1 -double2,         `options'
    _checks_gquantiles_by double1 -double2 double3, `options'

    _checks_gquantiles_by -int1,           `options'
    _checks_gquantiles_by int1 -int2,      `options'
    _checks_gquantiles_by int1 int2  int3, `options'

    _checks_gquantiles_by -int1 -str_32 -double1,                                         `options'
    _checks_gquantiles_by int1 -str_32 double1 -int2 str_12 -double2,                     `options'
    _checks_gquantiles_by int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options'

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        _checks_gquantiles_by -strL1,             `options' `forcestrl'
        _checks_gquantiles_by strL1 -strL2,       `options' `forcestrl'
        _checks_gquantiles_by strL1 strL2  strL3, `options' `forcestrl'
    }
end

capture program drop _checks_gquantiles_by
program _checks_gquantiles_by
    syntax [anything], [tol(real 1e-6) NOIsily *]
    local by by(`anything')

    cap gquantiles, `by'
    assert _rc == 198
    cap gquantiles, `by' xtile
    assert _rc == 198
    cap gquantiles, `by' _pctile
    assert _rc == 198
    cap gquantiles, `by' pctile
    assert _rc == 198

    checks_inner_gquantiles_by ru,      `by' `options'
    checks_inner_gquantiles_by ix,      `by' `options'
    checks_inner_gquantiles_by random1, `by' `options'

    checks_inner_gquantiles_by int1^2 + 3 * double1,          `by' `options'
    checks_inner_gquantiles_by log(double1) + 2 * int1,       `by' `options'
    checks_inner_gquantiles_by exp(double3) + int1 * double3, `by' `options'
end

capture program drop checks_inner_gquantiles_by
program checks_inner_gquantiles_by
    syntax anything, [tol(real 1e-6) NOIsily wgt(str) *]
    cap drop __*
    local qui = cond("`noisily'" == "", "qui", "noisily")

    local 0 `anything' `wgt', `options'
    syntax anything [aw fw pw], [*]

    `qui' {
        gquantiles __p1 = `anything' `wgt', pctile `options' nq(10) strict
        l in 1/10

        gquantiles __p2 = `anything' `wgt', pctile `options' cutpoints(__p1) strict
        gquantiles __p3 = `anything' `wgt', pctile `options' quantiles(10 30 50 70 90) strict
        gquantiles __p4 = `anything' `wgt', pctile `options' cutoffs(10 30 50 70 90) strict
        cap gquantiles __p5 = `anything' `wgt', pctile `options' cutquantiles(rn) strict
        assert _rc == 198
        gquantiles __p5 = `anything' `wgt', pctile `options' cutquantiles(ru) strict


        fasterxtile __fx1 = `anything' `wgt', `options' nq(10)
        fasterxtile __fx2 = `anything' `wgt', `options' cutpoints(__p1)
        fasterxtile __fx3 = `anything', `options' cutpoints(__p1) altdef
        fasterxtile __fx4 = `anything', `options' nq(10) altdef


        gquantiles __x1 = `anything' `wgt', xtile `options' nq(10)
        gquantiles __x2 = `anything' `wgt', xtile `options' cutpoints(__p1)
        gquantiles __x3 = `anything' `wgt', xtile `options' quantiles(10 30 50 70 90)
        gquantiles __x4 = `anything' `wgt', xtile `options' cutoffs(10 30 50 70 90)
        cap gquantiles __x5 = `anything' `wgt', xtile `options' cutquantiles(rn)
        assert _rc == 198
        gquantiles __x5 = `anything' `wgt', xtile `options' cutquantiles(ru)

        cap gquantiles `anything' `wgt', _pctile `options' nq(10)
        assert _rc == 198
    }

    if ( "`wgt'" != "" ) exit 0

    `qui' {
        cap gquantiles __p1 = `anything', pctile altdef binfreq `options' nq(10) replace strict
        assert _rc == 198
        gquantiles __p1 = `anything', pctile altdef `options' nq(10) replace strict

        drop __*
        cap gquantiles __p1 = `anything' in 1/5, pctile altdef binfreq `options' nq(10) replace strict
        assert inlist(_rc, 198, 2000)
        cap gquantiles __p1 = `anything' in 1/5, pctile altdef binfreq(__bf1) `options' nq(10) replace strict
        assert inlist(_rc, 0, 2000)
        gquantiles __p1 = `anything', pctile altdef `options' nq(10) replace strict

        cap gquantiles __p2 = `anything', pctile altdef binfreq `options' cutpoints(__p1) strict
        assert _rc == 198
        cap gquantiles __p2 = `anything', pctile altdef binpct `options' cutpoints(__p1) strict
        assert _rc == 198
        cap gquantiles __p2 = `anything', pctile altdef binfreq(__f2) binpct(__fp2) `options' cutpoints(__p1) strict
        assert _rc == 198
        gquantiles __p2 = `anything', pctile altdef binfreq(__f2) `options' cutpoints(__p1) strict
        cap gquantiles __p2 = `anything' in 10 / 20, pctile altdef binfreq(__f2) `options' cutpoints(__p1) replace strict
        assert inlist(_rc, 0, 2000)
        cap gquantiles __p2 = `anything' in 10 / 20, pctile altdef binfreq(__f2) `options' cutpoints(__p1) replace cutifin cutby strict
        assert inlist(_rc, 0, 198, 2000)
        cap gquantiles __p2_ii = `anything' if inlist(_n, 1, 3, 7), pctile altdef `options' cutifin cutpoints(__p1) strict
        gquantiles __p2 = `anything', pctile altdef binfreq(__f2) `options' cutpoints(__p1) replace strict


        gquantiles __p3 = `anything', pctile altdef `options' quantiles(10 30 50 70 90) strict
        gquantiles __p4 = `anything', pctile altdef `options' cutoffs(10 30 50 70 90) strict


        cap gquantiles __p5 = `anything', pctile altdef binpct `options' cutquantiles(ru) strict
        assert _rc == 198
        cap gquantiles __p5 = `anything', pctile altdef binfreq `options' cutquantiles(ru) strict
        assert _rc == 198
        gquantiles __p5 = `anything', pctile altdef binfreq(__f5) `options' cutquantiles(ru) strict
        cap gquantiles __p5 = `anything', pctile altdef binfreq(__f5) `options' cutquantiles(ru) strict
        assert inlist(_rc, 110, 198)
        gquantiles __p5 = `anything', pctile altdef binfreq(__f5) `options' cutquantiles(ru) replace strict

        gquantiles __x1 = `anything', pctile altdef binfreq(__bf1) `options' nq(10) replace strict



        gquantiles __x1 = `anything', pctile altdef binfreq(__bf1) `options' nq(10) replace strict
        cap gquantiles __x1 = `anything' in 1/5, pctile altdef binfreq(__bf1) `options' nq(10) replace strict
        assert inlist(_rc, 0, 2000)
        cap gquantiles __x1 = `anything' in 1/5, pctile altdef binfreq(__bf1) `options' nq(10) replace strict
        assert inlist(_rc, 0, 2000)

        cap gquantiles __x2 = `anything', pctile altdef binfreq `options' cutpoints(__p1) strict
        assert _rc == 198
        cap gquantiles __x2 = `anything', pctile altdef binpct `options' cutpoints(__p1) strict
        assert _rc == 198
        gquantiles __x2 = `anything', pctile altdef binfreq(__xf2) `options' cutpoints(__p1) strict
        cap gquantiles __x2 = `anything', pctile altdef binfreq(__xf2) `options' cutpoints(__p1) strict
        assert inlist(_rc, 110, 198)
        gquantiles __x2 = `anything', pctile altdef binfreq(__xf2) `options' cutpoints(__p1) replace strict

        gquantiles __x3 = `anything', pctile altdef binfreq(__xf3) `options' quantiles(10 30 50 70 90) strict
        gquantiles __x4 = `anything', pctile altdef binfreq(__xf4) `options' cutoffs(10 30 50 70 90) strict

        cap gquantiles __x5 = `anything', pctile altdef binpct `options' cutquantiles(ru) strict
        assert _rc == 198
        cap gquantiles __x5 = `anything', pctile altdef binfreq `options' cutquantiles(ru) strict
        assert _rc == 198
        gquantiles __x5 = `anything', pctile altdef binfreq(__xf5) `options' cutquantiles(ru) strict
        cap gquantiles __x5 = `anything', pctile altdef binfreq(__xf5) `options' cutquantiles(ru) strict
        assert inlist(_rc, 110, 198)
        gquantiles __x5 = `anything', pctile altdef binfreq(__xf5) `options' cutquantiles(ru) replace strict
    }
end

***********************************************************************
*                        Internal Consistency                         *
***********************************************************************

capture program drop compare_gquantiles_by
program compare_gquantiles_by
    syntax, [NOIsily noaltdef wgt(str) *]
    local options `options' `noisily'

    gettoken wfun wfoo: wgt
    local wfun `wfun'
    local wfoo `wfoo'
    if ( `"`wfoo'"' == "mix" ) {
        local wcall_a "[aw = unif_0_100]"
        local wcall_f "[fw = int_unif_0_100]"
        local wcall_p "[pw = float_unif_0_1]"
        local wgen_a qui gen unif_0_100     = 100 * runiform() if mod(_n, 100)
        local wgen_f qui gen int_unif_0_100 = int(100 * runiform()) if mod(_n, 100)
        local wgen_p qui gen float_unif_0_1 = runiform() if mod(_n, 100)

        * This is for the benefit of comparing with fasterxtile from egenmisc
        local wcall_stata [aw = unif_0_100_]
        local wgen_stata  qui gen unif_0_100_ = 100 * runiform()
    }

    compare_gquantiles_stata_by, n(10000) bench(10) `altdef' `options' wgt(`wcall_stata') wgen(`wgen_stata')

    local N = trim("`: di %15.0gc _N'")
    di _n(1) "{hline 80}" _n(1) "consistency_gquantiles_pctile_xtile_by, N = `N', `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(10000)
    qui expand 10
    qui `noisily' random_draws, random(3) double
    gen long   ix = _n
    gen double ru = runiform() * 100
    qui replace ix = . if mod(_n, 10000) == 0
    qui replace ru = . if mod(_n, 10000) == 0
    gen byte    one = 1
    qui sort random3
    `wgen_a'
    `wgen_f'
    `wgen_p'

    _consistency_inner_gquantiles_by ru, `options' wgt(`wcall_f')
    _consistency_inner_gquantiles_by ru in 1 / 5, `options' corners wgt(`wcall_p')

    local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
    local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
    local from = cond(`in1' < `in2', `in1', `in2')
    local to   = cond(`in1' > `in2', `in1', `in2')
    _consistency_inner_gquantiles_by ru      in `from' / `to', `options' wgt(`wcall_a')
    _consistency_inner_gquantiles_by random1 in `from' / `to', `options' wgt(`wcall_f')

    _consistency_inner_gquantiles_by ru      if random2 > 0, `options' wgt(`wcall_p')
    _consistency_inner_gquantiles_by random1 if random2 > 0, `options' wgt(`wcall_a')

    local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
    local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
    local from = cond(`in1' < `in2', `in1', `in2')
    local to   = cond(`in1' > `in2', `in1', `in2')
    _consistency_inner_gquantiles_by ru      `anything' if random2 < 0 in `from' / `to', `options' wgt(`wcall_f')
    _consistency_inner_gquantiles_by random1 `anything' if random2 < 0 in `from' / `to', `options' wgt(`wcall_p')

    local N = trim("`: di %15.0gc _N'")
    di _n(1) "{hline 80}" _n(1) "consistency_gquantiles_internals_by, N = `N', `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop _consistency_inner_gquantiles_by
program _consistency_inner_gquantiles_by
    syntax anything [if] [in], [tol(real 1e-15) tolpct(real 1e-6) NOIsily corners *]
    _consistency_inner_full_by one               `if' `in', `options' var(`anything')
    _consistency_inner_full_by ix                `if' `in', `options' var(`anything')

    _consistency_inner_full_by -str_12           `if' `in', `options' var(`anything')
    _consistency_inner_full_by -double1          `if' `in', `options' var(`anything')

    _consistency_inner_full_by str_12 -str_32    `if' `in', `options' var(`anything')
    _consistency_inner_full_by double1 -double2  `if' `in', `options' var(`anything')

    _consistency_inner_full_by -int1             `if' `in', `options' var(`anything')
    _consistency_inner_full_by int1 -int2        `if' `in', `options' var(`anything')

    local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
    if ( `c(stata_version)' >= 14 ) {
        _consistency_inner_full_by -strL1        `if' `in', `options' var(`anything') `forcestrl'
        _consistency_inner_full_by strL1 -strL2  `if' `in', `options' var(`anything') `forcestrl'
    }

    _consistency_inner_full_by str_12 -str_4 double2 -double3 `if' `in', `options' var(`anything')
    if ( `c(stata_version)' >= 14 ) {
        _consistency_inner_full_by str_12 -str_4 double2 -double3 strL3 `if' `in', `options' var(`anything') `forcestrl'
    }
end

capture program drop _consistency_inner_full_by
program _consistency_inner_full_by
    syntax anything [if] [in], [var(str) wgt(str) *]

    if ( "`wgt'" != "" ) {
        local wtxt " `wgt'"
    }

    if ( "`if'`in'" != "" ) {
        local ifinstr ""
        if ( "`if'" != "" ) local ifinstr `ifinstr' [`if']
        if ( "`in'" != "" ) local ifinstr `ifinstr' [`in']
    }

    local hlen = length("Internal consistency_by for gquantiles `var', by(`anything') `ifinstr'`wtxt'")
    di as txt _n(1) "Internal consistency_by for gquantiles `var', by(`anything') `ifinstr'`wtxt'" _n(1) "{hline `hlen'}" _n(1)

    _consistency_inner_nq_by `var' `if' `in', by(`anything') `options' wgt(`wgt') nq(2)
    _consistency_inner_nq_by `var' `if' `in', by(`anything') `options' wgt(`wgt') nq(20)
    _consistency_inner_nq_by `var' `if' `in', by(`anything') `options' wgt(`wgt') nq(`=_N + 1')

    if ( `"`wgt'"' != "" ) exit 0

    _consistency_inner_nq_by `var' `if' `in', by(`anything') altdef `options' nq(2)
    _consistency_inner_nq_by `var' `if' `in', by(`anything') altdef `options' nq(20)
    _consistency_inner_nq_by `var' `if' `in', by(`anything') altdef `options' nq(`=_N + 1')
end

capture program drop _consistency_inner_nq_by
program _consistency_inner_nq_by
    syntax anything [if] [in], [tol(real 1e-15) tolpct(real 1e-6) nq(real 2) by(str) wgt(str) *]
    cap drop __* _*
    local rc = 0

    local options `options' by(`by')

    qui {
    gquantiles __p1 = `anything' `if' `in' `wgt', strict pctile `options' binfreq(__f1) xtile(__x1) nq(`nq') genp(__g1)
    gquantiles __p2 = `anything' `if' `in' `wgt', strict pctile `options' binfreq(__f2) xtile(__x2) cutpoints(__p1) cutby
    gquantiles __p5 = `anything' `if' `in' `wgt', strict pctile `options' binfreq(__f5) xtile(__x5) cutquantiles(__g1) genp(__g5) cutby

    _compare_inner_nqvars_by `tol' `tolpct'
    if ( `rc' ) {
        di as err "    consistency_internal_gquantiles_by (failed): pctile via nq(`nq') `options' not all equal"
        exit `rc'
    }

    cap drop __*
    gquantiles __x1 = `anything' `if' `in' `wgt', strict xtile `options' binfreq(__f1) pctile(__p1) nq(`nq') genp(__g1)
    gquantiles __x2 = `anything' `if' `in' `wgt', strict xtile `options' binfreq(__f2) pctile(__p2) cutpoints(__p1) cutby
    gquantiles __x5 = `anything' `if' `in' `wgt', strict xtile `options' binfreq(__f5) pctile(__p5) cutquantiles(__g1) cutby

    _compare_inner_nqvars_by `tol' `tolpct'
    if ( `rc' ) {
        di as err "    consistency_internal_gquantiles_by (failed): xtile via nq(`nq') `options' not all equal"
        exit `rc'
    }
    }

    di as txt "    consistency_internal_gquantiles_by (passed): xtile, pctile, and _pctile via nq(`nq') `options' (tol = `:di %6.2g `tol'')"
end

capture program drop _compare_inner_nqvars_by
program _compare_inner_nqvars_by, rclass
    args tol tolpct
    local rc = 0

    * NOTE(mauricio): Percentiles need not be super precise. The
    * important property is that they preserve xtile and binfreq, which
    * is why that tolerance is super small whereas the tolerance for
    * percentiles is larger. // 2017-11-19 12:33 EST

    _compare_inner_nqvars_rc_by __p1 __p2 `tolpct'
    local rc = max(`rc', `r(rc)')
    _compare_inner_nqvars_rc_by __f1 __f2 `tol'
    local rc = max(`rc', `r(rc)')
    _compare_inner_nqvars_rc_by __x1 __x2 `tol'
    local rc = max(`rc', `r(rc)')

    local rc = 0
    _compare_inner_nqvars_rc_by __p1 __p5 `tolpct'
    local rc = max(`rc', `r(rc)')
    _compare_inner_nqvars_rc_by __f1 __f5 `tol'
    local rc = max(`rc', `r(rc)')
    _compare_inner_nqvars_rc_by __x1 __x5 `tol'
    local rc = max(`rc', `r(rc)')

    c_local rc `rc'
end

capture program drop _compare_inner_nqvars_rc_by
program _compare_inner_nqvars_rc_by, rclass
    args v1 v2 tol
    cap assert `v1' == `v2'
    if ( _rc ) {
        cap assert abs(`v1' - `v2') < `tol' | mi(`v1')
    }
    return scalar rc = _rc
end

***********************************************************************
*                            Compare Stata                            *
***********************************************************************

capture program drop bench_gquantiles_by
program bench_gquantiles_by
    syntax, [bench(int 10) n(int 10000) *]
    compare_inner_quantiles_by, n(`n') bench(`bench') benchmode qopts(nq(10))
    compare_inner_quantiles_by, n(`n') bench(`bench') benchmode nlist(2(2)20)
    compare_inner_quantiles_by, n(`n') bench(`bench') benchmode nqlist(2(2)20)
end

capture program drop compare_gquantiles_stata_by
program compare_gquantiles_stata_by
    syntax, [bench(int 10) n(int 10000) noaltdef *]

    if ( "`altdef'" != "noaltdef" ) {
    compare_inner_quantiles_by, n(`n') bench(`bench') qopts(altdef nq(10)) `options'
    compare_inner_quantiles_by, n(`n') bench(`bench') qopts(altdef nq(2))  `options'
    }

    compare_inner_quantiles_by, n(`n') bench(`bench') qopts(nq(10)) `options'
    compare_inner_quantiles_by, n(`n') bench(`bench') qopts(nq(2))  `options'
end

capture program drop compare_inner_quantiles_by
program compare_inner_quantiles_by
    syntax, [bench(int 100) n(real 1000) benchmode wgen(str) *]
    local options `options' `benchmode' j(`n')

    qui `noisily' gen_data, n(`n')
    qui expand `bench'
    qui `noisily' random_draws, random(2) double
    gen long   ix = _n
    gen double ru = runiform() * 100
    gen double rn = rnormal() * 100
    qui replace ix = . if mod(_n, `n') == 0
    qui replace ru = . if mod(_n, `n') == 0
    qui replace rn = . if mod(_n, `n') == 0
    qui sort random1
    `wgen'

    _compare_inner_gquantiles_by, `options'

    if ( "`benchmode'" == "" ) {
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_gquantiles_by in `from' / `to', `options'

        _compare_inner_gquantiles_by if random2 > 0, `options'

        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_gquantiles_by `anything' if random2 < 0 in `from' / `to', `options'
    }
end

***********************************************************************
*                             Comparisons                             *
***********************************************************************

capture program drop _compare_inner_gquantiles_by
program _compare_inner_gquantiles_by
    syntax [if] [in], [tol(real 1e-6) NOIsily qopts(str) nqlist(numlist) nlist(numlist) benchmode table J(real 0) wgt(str) *]

    if ( "`if'`in'" != "" ) {
        local ifinstr ""
        if ( "`if'" != "" ) local ifinstr `ifinstr' [`if']
        if ( "`in'" != "" ) local ifinstr `ifinstr' [`in']
    }

    qui gunique int1
    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `j''")

    if ( "`nqlist'`nlist'" == "" ) {
        local options `options' `benchmode' `table' qopts(`qopts') wgt(`wgt')

        di as txt _n(1)
        di as txt "Compare xtile"
        di as txt "     - if in:  `ifinstr'"
        di as txt "     - weight: `wgt'"
        di as txt "     - obs:    `N'"
        di as txt "     - J:      `J'"
        di as txt "     - call:   fcn xtile = x, by(varlist) opts"
        di as txt "     - opts:   `qopts'"
        di as txt "     - x:      x ~ N(0, 100)"
        if ( ("`benchmode'" != "") | ("`table'" != "") ) {
        di as txt "          | egenmisc  |            |             |             |        "
        di as txt "   astile | fastxtile | gquantiles | ratio (a/g) | ratio (f/g) | varlist"
        di as txt "   ------ | --------- | ---------- | ----------- | ----------- | -------"
        }

        _compare_inner_xtile_by str_12          `if' `in',  `options'
        _compare_inner_xtile_by str_12 str_32   `if' `in',  `options'

        _compare_inner_xtile_by double1         `if' `in', `options'
        _compare_inner_xtile_by double1 double2 `if' `in', `options'

        _compare_inner_xtile_by int1            `if' `in', `options'
        _compare_inner_xtile_by int1 int2       `if' `in', `options'

        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        if ( `c(stata_version)' >= 14 ) {
            _compare_inner_xtile_by strL1       `if' `in', `options' `forcestrl'
            _compare_inner_xtile_by strL1 strL2 `if' `in', `options' `forcestrl'
        }
    }
    else if ( "`nqlist'" != "" ) {
        local options `options' `benchmode' `table' wgt(`wgt')

        di as txt _n(1)
        di as txt "Compare xtile"
        di as txt "     - if in:   `ifinstr'"
        di as txt "     - weight:  `wgt'"
        di as txt "     - obs:     `N'"
        di as txt "     - J:       `J'"
        di as txt "     - call:    fcn xtile = x, by(varlist)"
        di as txt "     - varlist: int1"
        di as txt "     - x:       x ~ N(0, 100)"
        if ( ("`benchmode'" != "") | ("`table'" != "") ) {
        di as txt "         |        | egenmisc  |            |             |            "
        di as txt "      nq | astile | fastxtile | gquantiles | ratio (a/g) | ratio (f/g)"
        di as txt "  ------ | ------ | --------- | ---------- | ----------- | -----------"
        }
        foreach nq in `nqlist' {
            _compare_inner_xtile_by int1 `if' `in', `options' nq(`nq')
        }
    }
    else if ( "`nlist'" != "" ) {
        local from = `j'
        local to   = `=_N'
        local exp  = round(`to' / `from', 1)
        local step = round(`exp' / 10, 1)

        qui `noisily' gen_data, n(`j') skipstr
        qui `noisily' random_draws, random(1) double

        di as txt _n(1)
        di as txt "Compare xtile"
        di as txt "     - if in:   `ifinstr'"
        di as txt "     - weight:  `wgt'"
        di as txt "     - J:       `J'"
        di as txt "     - call:    fcn xtile = x, by(varlist) nq(10)"
        di as txt "     - varlist: int1"
        di as txt "     - x:       x ~ N(0, 100)"
        if ( ("`benchmode'" != "") | ("`table'" != "") ) {
        di as txt "               |        | egenmisc  |            |             |            "
        di as txt "             N | astile | fastxtile | gquantiles | ratio (a/g) | ratio (f/g)"
        di as txt "  ------------ | ------ | --------- | ---------- | ----------- | -----------"
        }

        local options `options' `benchmode' `table' wgt(`wgt')
        forvalues i = `step'(`step')`exp' {
        preserve
            qui expand `i'
            gen double rn = rnormal() * 100
            qui sort random1
            _compare_inner_xtile_by int1 `if' `in', `options' n(`=_N')
        restore
        }
    }
end

capture program drop _compare_inner_xtile_by
program _compare_inner_xtile_by
    syntax anything [if] [in], [benchmode table qopts(str) sorted FORCEcmp nq(str) n(str) wgt(str) *]
    tempvar axtile fxtile gxtile

    local 0 `anything' `if' `in' `wgt', `options'
    syntax anything [if] [in] [aw fw pw/], [*]
    if ( "`weight'" != "" ) local weight weight(`exp')

    if ( "`sorted'" != "" ) {
        cap sort `anything'
        if ( _rc ) {
            tempvar sort
            qui gen double `sort' = `anything'
            sort `sort'
        }
    }

    if ( "`nq'" != "" ) local qopts `qopts' nq(`nq')

    timer clear
    timer on 43
    qui gquantiles `gxtile' = rn `if' `in' `wgt', `qopts' by(`anything') `options' xtile
    timer off 43
    qui timer list
    local time_gxtile = r(t43)

    if ( "`wgt'" == "" ) {
        timer clear
        timer on 42
        cap astile `axtile' = rn `if' `in', `qopts' by(`anything')
        local rc_a = _rc
        timer off 42
        qui timer list
        local time_axtile = r(t42)
    }
    else local rc_a = 9

    timer clear
    timer on 44
    cap egen `fxtile' = fastxtile(rn) `if' `in', `qopts' by(`anything') `weight'
    local rc_f = _rc
    timer off 44
    qui timer list
    local time_fxtile = r(t44)

    if ( `rc_f' ) {
        local time_fxtile = .
        di "(note: fastxtile[egenmisc] failed)"
    }

    if ( `rc_a' ) {
        local time_fxtile = .
        di "(note: astile failed)"
    }

    cap assert `gxtile' == `axtile'
    if ( _rc & (`rc_a' == 0) ) {
        * if ( "`forcecmp'" == "" ) {
        *     di as err "    compare_xtile_by (failed): gquantiles, by(`anything') gave different levels to astile"
        *     exit 198
        * }
        * else {
        *     di as txt "    (note: astile gave different levels)"
        * }
        di as txt "    (note: astile gave different levels)"
    }

    cap assert `gxtile' == `fxtile'
    if ( _rc & (`rc_f' == 0) ) {
        if ( "`forcecmp'" == "" ) {
            tempvar diff
            qui gen `diff' = `fxtile' - `gxtile'
            gtoplevelsof `diff', nowarn
            qui count if `fxtile' != `gxtile'
            local fail = `r(N)'
            if ( `=max(`=`fail' / _N' < 0.05, `fail' == 1)' & ("`wgt'" != "") ) {
                di as err "    compare_xtile_by (warning): gquantiles, by(`anything') gave different levels to fastxtile[egenmisc]"
                di as err ""
                di as err "using weights in fastxtile[egenmisc] seems to give incorrect results" ///
                    _n(1) "under some circumstances. Only `fail' / `=_N' xtiles were off."
                di as err ""
            }
            else {
                di as err "    compare_xtile_by (failed): gquantiles, by(`anything') gave different levels to fastxtile[egenmisc]"
                exit 198
            }
        }
        else {
            di as txt "    (note: fastxtile[egenmisc] gave different levels)"
        }
    }
    else if ( "`benchmode'" == "" ) {
        di as txt "    compare_xtile_by (passed): gquantiles, by(`anything') was the same as fastxtile[egenmisc]"
    }

    if ( ("`table'" != "") | ("`benchmode'" != "") ) {
        local rs = `time_axtile' / `time_gxtile'
        local rf = `time_fxtile' / `time_gxtile'
        if ( "`n'" != "" ) {
        di as txt "  `:di %12.0gc `n'' | `:di %6.3g `time_axtile'' | `:di %9.3g `time_fxtile'' | `:di %10.3g `time_gxtile'' | `:di %11.3g `rs'' | `:di %11.3g `rf''"
        }
        else if ( "`nq'" != "" ) {
        di as txt "  `:di %6.0g `nq'' | `:di %6.3g `time_axtile'' | `:di %9.3g `time_fxtile'' | `:di %10.3g `time_gxtile'' | `:di %11.3g `rs'' | `:di %11.3g `rf''"
        }
        else {
        di as txt "    `:di %5.3g `time_axtile'' | `:di %9.3g `time_fxtile'' | `:di %10.3g `time_gxtile'' | `:di %11.3g `rs'' | `:di %11.3g `rf'' | `anything'"
        }
    }
end
capture program drop checks_gegen
program checks_gegen
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_egen, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(5000)
    qui expand 2
    qui `noisily' random_draws, random(2)
    gen long ix = _n

    checks_inner_egen, `options'

    checks_inner_egen -str_12,              `options' hash(0)
    checks_inner_egen str_12 -str_32,       `options' hash(1)
    checks_inner_egen str_12 -str_32 str_4, `options' hash(2)

    checks_inner_egen -double1,                 `options' hash(2)
    checks_inner_egen double1 -double2,         `options' hash(0)
    checks_inner_egen double1 -double2 double3, `options' hash(1)

    checks_inner_egen -int1,           `options' hash(1)
    checks_inner_egen int1 -int2,      `options' hash(2)
    checks_inner_egen int1 -int2 int3, `options' hash(0)

    checks_inner_egen -int1 -str_32 -double1,                                         `options'
    checks_inner_egen int1 -str_32 double1 -int2 str_12 -double2,                     `options'
    checks_inner_egen int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options'

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        checks_inner_egen -strL1,             `options' hash(1) `forcestrl'
        checks_inner_egen strL1 -strL2,       `options' hash(2) `forcestrl'
        checks_inner_egen strL1 -strL2 strL3, `options' hash(0) `forcestrl'
    }

    clear
    set obs 10
    gen x = .
    gegen y = total(x), missing
    gegen z = total(x)
    assert y == .
    assert z == 0

    clear
    gen x = 1
    cap gegen y = group(x)
    assert _rc == 111

    clear
    set obs 10
    gen x = 1
    gegen y = group(x) if x > 1
    gegen z = tag(x)   if x > 1

    clear
    sysuse auto
    tempfile auto
    save `"`auto'"'

    clear
    set obs 5
    gen x = _n
    gen strL y = "hi" + string(mod(_n, 2)) + char(9) + char(0)
    replace y  = fileread(`"`auto'"') in 1
    cap gegen z = group(y)
    if ( `c(stata_version)' < 14 ) {
        assert _rc == 17002
    }
    else {
        assert _rc == 17005
    }

    clear
    cap gegen
    assert _rc == 100
    gegen x = group(y)
    assert _rc == 111
    set obs 10
    gen x = .
    gegen y = group(x)
    assert y == .
    gegen y = group(x), missing replace
    assert y == 1

    clear
    set obs 10
    gen x = _n
    gegen y = group(x) if 0
    assert y == .
    gegen z = group(x) if 1
    assert z == x
    gegen z = group(x) in 1 / 3, replace
    assert z == x | mi(z)
    gegen z = group(x) in 8, replace
    assert z == 1 | mi(z)

    gegen z = sum(x) in 1 / 3, by(x) replace
    assert z == x | mi(z)
    gegen z = sum(x) if x == 7, by(x) replace
    assert z == x | mi(z)
    gegen z = count(x) if x == 8, by(x) replace
    assert z == 1 | mi(z)

    clear
    set obs 10
    gen x = 1
    gen w = .
    gegen z = sum(x) [w = w]
    drop z
    replace w = 0
    gegen z = sum(x) [w = w]
    drop z
    gegen z = sum(x) [w = w] if w == 3.14
end

capture program drop checks_inner_egen
program checks_inner_egen
    syntax [anything], [tol(real 1e-6) wgt(str) *]

    local 0 `anything' `wgt', `options'
    syntax [anything] [aw fw iw pw], [*]

    local percentiles 1 10 30.5 50 70.5 90 99
    local stats nunique total sum mean max min count median iqr percent first last firstnm lastnm skew kurt
    if ( !inlist("`weight'", "pweight") )            local stats `stats' sd
    if ( !inlist("`weight'", "pweight", "iweight") ) local stats `stats' semean
    if (  inlist("`weight'", "fweight", "") )        local stats `stats' sebinomial sepoisson

    tempvar gvar
    foreach fun of local stats {
        `noisily' gegen `gvar' = `fun'(random1) `wgt', by(`anything') replace `options'
        if ( "`weight'" == "" ) {
        `noisily' gegen `gvar' = `fun'(random*) `wgt', by(`anything') replace `options'
        }
    }

    foreach p in `percentiles' {
        `noisily' gegen `gvar' = pctile(random1) `wgt', p(`p') by(`anything') replace `options'
        if ( "`weight'" == "" ) {
        `noisily' gegen `gvar' = pctile(random*) `wgt', p(`p') by(`anything') replace `options'
        }
    }

    if ( "`anything'" != "" ) {
        `noisily' gegen `gvar' = tag(`anything')   `wgt', replace `options'
        `noisily' gegen `gvar' = group(`anything') `wgt', replace `options'
        `noisily' gegen `gvar' = count(1)          `wgt', by(`anything') replace `options'
    }
end

***********************************************************************
*                               Compare                               *
***********************************************************************

capture program drop compare_egen
program compare_egen
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "consistency_egen, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(1000)
    * qui expand 100
    qui `noisily' random_draws, random(2) float
    qui expand 10

    compare_inner_egen, `options' tol(`tol')

    compare_inner_egen str_12,              `options' tol(`tol') hash(1)
    compare_inner_egen str_12 str_32,       `options' tol(`tol') hash(0) sort
    compare_inner_egen str_12 str_32 str_4, `options' tol(`tol') hash(2) shuffle

    compare_inner_egen double1,                 `options' tol(`tol') hash(2) shuffle
    compare_inner_egen double1 double2,         `options' tol(`tol') hash(1)
    compare_inner_egen double1 double2 double3, `options' tol(`tol') hash(0) sort

    compare_inner_egen int1,           `options' tol(`tol') hash(0) sort
    compare_inner_egen int1 int2,      `options' tol(`tol') hash(2) shuffle
    compare_inner_egen int1 int2 int3, `options' tol(`tol') hash(1)

    compare_inner_egen int1 str_32 double1,                                        `options' tol(`tol')
    compare_inner_egen int1 str_32 double1 int2 str_12 double2,                    `options' tol(`tol')
    compare_inner_egen int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options' tol(`tol')

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        compare_inner_egen strL1,             `options' tol(`tol') hash(0) `forcestrl' sort
        compare_inner_egen strL1 strL2,       `options' tol(`tol') hash(2) `forcestrl' shuffle
        compare_inner_egen strL1 strL2 strL3, `options' tol(`tol') hash(1) `forcestrl' 
    }
end

capture program drop compare_inner_egen
program compare_inner_egen
    syntax [anything], [tol(real 1e-6) sort shuffle *]

    tempvar rsort
    if ( "`shuffle'" != "" ) gen `rsort' = runiform()
    if ( "`shuffle'" != "" ) sort `rsort'
    if ( ("`sort'" != "") & ("`anything'" != "") ) hashsort `anything'

    local N = trim("`: di %15.0gc _N'")
    local hlen = 31 + length("`anything'") + length("`N'")

    di _n(2) "Checking egen. N = `N'; varlist = `anything'" _n(1) "{hline `hlen'}"

    _compare_inner_egen `anything', `options' tol(`tol')

    local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
    local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
    local from = cond(`in1' < `in2', `in1', `in2')
    local to   = cond(`in1' > `in2', `in1', `in2')
    _compare_inner_egen `anything' in `from' / `to', `options' tol(`tol')

    _compare_inner_egen `anything' if random2 > 0, `options' tol(`tol')

    local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
    local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
    local from = cond(`in1' < `in2', `in1', `in2')
    local to   = cond(`in1' > `in2', `in1', `in2')
    _compare_inner_egen `anything' if random2 < 0 in `from' / `to', `options' tol(`tol')
end

capture program drop _compare_inner_egen
program _compare_inner_egen
    syntax [anything] [if] [in], [tol(real 1e-6) *]

    local stats       total sum mean sd max min count median iqr skew kurt
    local percentiles 1 10 30 50 70 90 99

    cap drop g*_*
    cap drop c*_*

    tempvar g_fun

    if ( "`if'`in'" == "" ) {
        di _n(1) "Checking full egen range: `anything'"
    }
    else if ( "`if'`in'" != "" ) {
        di _n(1) "Checking [`if' `in'] egen range: `anything'"
    }

    foreach fun of local stats {
        timer clear
        timer on 43
        qui `noisily' gegen float `g_fun' = `fun'(random1) `if' `in', by(`anything') replace `options'
        timer off 43
        qui timer list
        local time_gegen = r(t43)

        timer clear
        timer on 42
        qui `noisily'  egen float c_`fun' = `fun'(random1) `if' `in', by(`anything')
        timer off 42
        qui timer list
        local time_egen = r(t42)

        local rs = `time_egen'  / `time_gegen'
        local tinfo `:di %4.3g `time_gegen'' vs `:di %4.3g `time_egen'', ratio `:di %4.3g `rs''

        cap noi assert (`g_fun' == c_`fun') | abs(`g_fun' - c_`fun') < `tol'
        if ( _rc ) {
            di as err "    compare_egen (failed): gegen `fun' not equal to egen (tol = `tol'; `tinfo')"
            exit _rc
        }
        else di as txt "    compare_egen (passed): gegen `fun' results similar to egen (tol = `tol'; `tinfo')"
    }

    foreach p in `percentiles' {
        timer clear
        timer on 43
        qui  `noisily' gegen float `g_fun' = pctile(random1) `if' `in', by(`anything') p(`p') replace `options'
        timer off 43
        qui timer list
        local time_gegen = r(t43)


        timer clear
        timer on 42
        qui  `noisily'  egen float c_p`p'  = pctile(random1) `if' `in', by(`anything') p(`p')
        timer off 42
        qui timer list
        local time_egen = r(t42)

        local rs = `time_egen'  / `time_gegen'
        local tinfo `:di %4.3g `time_gegen'' vs `:di %4.3g `time_egen'', ratio `:di %4.3g `rs''

        cap noi assert (`g_fun' == c_p`p') | abs(`g_fun' - c_p`p') < `tol'
        if ( _rc ) {
            di as err "    compare_egen (failed): gegen percentile `p' not equal to egen (tol = `tol'; `tinfo')"
            exit _rc
        }
        else di as txt "    compare_egen (passed): gegen percentile `p' results similar to egen (tol = `tol'; `tinfo')"
    }

    foreach fun in tag group {
        timer clear
        timer on 43
        qui  `noisily' gegen float `g_fun' = `fun'(`anything') `if' `in', replace `options'
        timer off 43
        qui timer list
        local time_gegen = r(t43)


        timer clear
        timer on 42
        qui  `noisily'  egen float c_`fun' = `fun'(`anything') `if' `in'
        timer off 42
        qui timer list
        local time_egen = r(t42)

        local rs = `time_egen'  / `time_gegen'
        local tinfo `:di %4.3g `time_gegen'' vs `:di %4.3g `time_egen'', ratio `:di %4.3g `rs''

        cap noi assert (`g_fun' == c_`fun') | abs(`g_fun' - c_`fun') < `tol'
        if ( _rc ) {
            di as err "    compare_egen (failed): gegen `fun' not equal to egen (tol = `tol'; `tinfo')"
            exit _rc
        }
        else di as txt "    compare_egen (passed): gegen `fun' results similar to egen (tol = `tol'; `tinfo')"

        timer clear
        timer on 43
        qui  `noisily' gegen float `g_fun' = `fun'(`anything') `if' `in', missing replace `options'
        timer off 43
        qui timer list
        local time_gegen = r(t43)


        timer clear
        timer on 42
        qui  `noisily'  egen float c_`fun'2 = `fun'(`anything') `if' `in', missing
        timer off 42
        qui timer list
        local time_egen = r(t42)

        local rs = `time_egen'  / `time_gegen'
        local tinfo `:di %4.3g `time_gegen'' vs `:di %4.3g `time_egen'', ratio `:di %4.3g `rs''

        cap noi assert (`g_fun' == c_`fun'2) | abs(`g_fun' - c_`fun'2) < `tol'
        if ( _rc ) {
            di as err "    compare_egen (failed): gegen `fun', missing not equal to egen (tol = `tol'; `tinfo')"
            exit _rc
        }
        else di as txt "    compare_egen (passed): gegen `fun', missing results similar to egen (tol = `tol'; `tinfo')"
    }

    {
        qui  `noisily' gegen g_g1 = group(`anything') `if' `in', counts(g_c1) fill(.) v `options' missing
        qui  `noisily' gegen g_g2 = group(`anything') `if' `in', counts(g_c2)         v `options' missing
        qui  `noisily' gegen g_c3 = count(1) `if' `in', by(`anything')
        qui  `noisily'  egen c_t1 = tag(`anything') `if' `in',  missing
        cap noi assert ( (g_c1 == g_c3) | ((c_t1 == 0) & (g_c1 == .)) ) & (g_c2 == g_c3)
        if ( _rc ) {
            di as err "    compare_egen (failed): gegen `fun' counts not equal to gegen count (tol = `tol')"
            exit _rc
        }
        else di as txt "    compare_egen (passed): gegen `fun' counts results similar to gegen count (tol = `tol')"
    }

    cap drop g_*
    cap drop c_*
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_egen
program bench_egen
    syntax, [tol(real 1e-6) bench(int 1) n(int 1000) NOIsily *]

    qui gen_data, n(`n')
    qui expand `=100 * `bench''
    qui `noisily' random_draws, random(1)
    qui sort random1

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    di _n(1)
    di "Benchmark vs egen, obs = `N', J = `J' (in seconds)"
    di "     egen | fegen | gegen | ratio (e/g) | ratio (f/g) | varlist"
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

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        versus_egen strL1,             `options' `forcestrl'
        versus_egen strL1 strL2,       `options' `forcestrl'
        versus_egen strL1 strL2 strL3, `options' `forcestrl'
    }

    di _n(1) "{hline 80}" _n(1) "bench_egen, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop versus_egen
program versus_egen, rclass
    syntax varlist, [fegen *]

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
capture program drop checks_unique
program checks_unique
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_unique, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(5000)
    qui expand 2
    gen long ix = _n

    checks_inner_unique str_12,              `options'
    checks_inner_unique str_12 str_32,       `options' by(str_4) replace
    checks_inner_unique str_12 str_32 str_4, `options'

    checks_inner_unique double1,                 `options'
    checks_inner_unique double1 double2,         `options' by(double3) replace
    checks_inner_unique double1 double2 double3, `options'

    checks_inner_unique int1,           `options'
    checks_inner_unique int1 int2,      `options' by(int3) replace
    checks_inner_unique int1 int2 int3, `options'

    checks_inner_unique int1 str_32 double1,                                        `options'
    checks_inner_unique int1 str_32 double1 int2 str_12 double2,                    `options' by(int3 str_4 double3) replace
    checks_inner_unique int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")

        * This is for the benefit of gtop, which can only handle strings that are so long
        qui `noisily' gen_data, n(50)
        qui expand 200
        gen long ix = _n

        checks_inner_unique strL1,             `options' `forcestrl'
        checks_inner_unique strL1 strL2,       `options' `forcestrl' by(strL3) replace
        checks_inner_unique strL1 strL2 strL3, `options' `forcestrl'
    }

    clear
    gen x = 1
    cap gunique x
    assert _rc == 2000

    clear
    set obs 10
    gen x = 1
    cap gunique x if x < 0
    assert _rc == 0
    cap gunique x if 0
    assert _rc == 0
    replace x = .
    cap gunique x if 0
    assert _rc == 0
end

capture program drop checks_inner_unique
program checks_inner_unique
    syntax varlist, [*]
    cap gunique `varlist', `options' v bench miss
    assert _rc == 0

    cap gunique `varlist' in 1, `options' miss d
    assert _rc == 0
    assert `r(N)' == `r(J)'
    assert `r(J)' == 1

    cap gunique `varlist' if _n == 1, `options' miss
    assert _rc == 0
    assert `r(N)' == `r(J)'
    assert `r(J)' == 1

    cap gunique `varlist' if _n < 10 in 5, `options' miss d
    assert _rc == 0
    assert `r(N)' == `r(J)'
    assert `r(J)' == 1
end

***********************************************************************
*                               Compare                               *
***********************************************************************

capture program drop compare_unique
program compare_unique
    syntax, [tol(real 1e-6) NOIsily distinct unique *]

    if ( "`distinct'`unique'" == "" ) local unique unique
    if ( ("`distinct'" != "") & ("`unique'" != "") ) {
        di as err "Specify only one of: unique distinct"
        exit 198
    }

    qui `noisily' gen_data, n(1000)
    qui expand 100

    local N    = trim("`: di %15.0gc _N'")
    local hlen = 22 + length("`options'") + length("`N'")
    di _n(1) "{hline 80}" _n(1) "compare_`distinct'`unique', N = `N', `options'" _n(1) "{hline 80}" _n(1)

    local options `options' `distinct'`unique'

    compare_inner_unique str_12,              `options' sort
    compare_inner_unique str_12 str_32,       `options' shuffle
    compare_inner_unique str_12 str_32 str_4, `options'

    compare_inner_unique double1,                 `options'
    compare_inner_unique double1 double2,         `options' sort
    compare_inner_unique double1 double2 double3, `options' shuffle

    compare_inner_unique int1,           `options' shuffle
    compare_inner_unique int1 int2,      `options'
    compare_inner_unique int1 int2 int3, `options' sort

    compare_inner_unique int1 str_32 double1,                                        `options'
    compare_inner_unique int1 str_32 double1 int2 str_12 double2,                    `options'
    compare_inner_unique int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        compare_inner_unique strL1,             `options' `forcestrl' shuffle
        compare_inner_unique strL1 strL2,       `options' `forcestrl' 
        compare_inner_unique strL1 strL2 strL3, `options' `forcestrl' sort
    }
end

capture program drop compare_inner_unique
program compare_inner_unique
    syntax varlist, [distinct unique sort shuffle *]

    tempvar rsort
    if ( "`shuffle'" != "" ) gen `rsort' = runiform()
    if ( "`shuffle'" != "" ) sort `rsort'
    if ( ("`sort'" != "") & ("`anything'" != "") ) hashsort `anything'

    if ( "`distinct'" != "" ) {
        local joint joint
        local rname ndistinct
    }
    else {
        local joint
        local rname unique
    }

    local options `options' `joint'

    tempvar rsort ix
    gen `rsort' = runiform()
    gen long `ix' = _n

    cap `distinct'`unique' `varlist', `joint'
    local nJ_`distinct'`unique' = `r(`rname')'
    cap g`distinct'`unique' `varlist', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( `varlist') `distinct'`unique'

    cap `distinct'`unique' `ix' `varlist', `joint'
    local nJ_`distinct'`unique' = `r(`rname')'
    cap g`distinct'`unique' `ix' `varlist', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( ix `varlist') `distinct'`unique'

    cap `distinct'`unique' `rsort' `varlist', `joint'
    local nJ_`distinct'`unique' = `r(`rname')'
    cap g`distinct'`unique' `rsort' `varlist', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( rsort `varlist') `distinct'`unique'

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    qui replace `ix' = `=_N / 2' if _n > `=_N / 2'
    cap `distinct'`unique' `ix', `joint'
    local nJ_`distinct'`unique' = `r(`rname')'
    cap g`distinct'`unique' `ix', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( ix) `distinct'`unique'

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    preserve
        qui keep in 100 / `=ceil(`=_N / 2')'
        cap `distinct'`unique' `ix' `varlist', `joint'
        local nJ_`distinct'`unique' = `r(`rname')'
    restore
    cap g`distinct'`unique' `ix' `varlist' in 100 / `=ceil(`=_N / 2')', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels  `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( ix `varlist' in 100 / `=ceil(`=_N / 2')') `distinct'`unique'

    preserve
        qui keep in `=ceil(`=_N / 2')' / `=_N'
        cap `distinct'`unique' `ix' `varlist', `joint'
        local nJ_`distinct'`unique' = `r(`rname')'
    restore
    cap g`distinct'`unique' `ix' `varlist' in `=ceil(`=_N / 2')' / `=_N', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels  `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( ix `varlist' in `=ceil(`=_N / 2')' / `=_N') `distinct'`unique'

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    preserve
        qui keep if _n < `=_N / 2'
        cap `distinct'`unique' `ix' `varlist', `joint'
        local nJ_`distinct'`unique' = `r(`rname')'
    restore
    cap g`distinct'`unique' `ix' `varlist' if _n < `=_N / 2', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels  `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( ix `varlist' if _n < `=_N / 2') `distinct'`unique'

    preserve
        qui keep if _n > `=_N / 2'
        cap `distinct'`unique' `ix' `varlist', `joint'
        local nJ_`distinct'`unique' = `r(`rname')'
    restore
    cap g`distinct'`unique' `ix' `varlist' if _n > `=_N / 2', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels  `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( ix `varlist' if _n > `=_N / 2') `distinct'`unique'

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    qui replace `ix' = 100 in 1 / 100

    preserve
        qui keep if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')'
        cap `distinct'`unique' `ix' `varlist', `joint'
        local nJ_`distinct'`unique' = `r(`rname')'
    restore
    cap g`distinct'`unique' `ix' `varlist' if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels  `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( ix `varlist' if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')') `distinct'`unique'

    preserve
        qui keep if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N'
        cap `distinct'`unique' `ix' `varlist', `joint'
        local nJ_`distinct'`unique' = `r(`rname')'
    restore
    cap g`distinct'`unique' `ix' `varlist' if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels  `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( ix `varlist' if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N') `distinct'`unique'

    di _n(1)
end

capture program drop check_nlevels
program check_nlevels
    syntax anything, by(str) [distinct unique]

    tokenize `anything'
    local nJ   `1'
    local nJ_g `2'

    if ( `nJ' != `nJ_g' ) {
        di as err "    compare_`distinct'`unique' (failed): `distinct'`unique' `by' gave `nJ' levels but g`distinct'`unique' gave `nJ_g'"
        exit 198
    }
    else {
        di as txt "    compare_`distinct'`unique' (passed): `distinct'`unique' and g`distinct'`unique' `by' gave the same number of levels"
    }
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_unique
program bench_unique
    syntax, [tol(real 1e-6) bench(int 1) n(int 1000) NOIsily distinct joint distunique *]

    if ( "`distinct'" != "" ) {
        local dstr distinct
        local dsep --------
    }
    else {
        local dstr unique
        local dsep ------
    }

    if ( "`joint'" != "" ) {
        local dj   , joint;
    }
    else {
        local dj   ,
    }

    local options `options' `distinct' `joint' `distunique'

    qui `noisily' gen_data, n(`n')
    qui expand `=100 * `bench''
    qui gen rsort = rnormal()
    qui sort rsort

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    if ( ("`distunique'" != "") & ("`joint'" != "") ) {
        di as txt _n(1)
        di as txt "Benchmark vs `dstr'`dj' obs = `N', all calls include a unique index (in seconds)"
        di as txt "     `dstr' |    unique | g`dstr' | ratio (d/g) | ratio (u/g) | varlist"
        di as txt "     `dsep' | -`dsep' | -`dsep' | ----------- | ----------- | -------"
    }
    else {
        di as txt _n(1)
        di as txt "Benchmark vs `dstr'`dj' obs = `N', all calls include a unique index (in seconds)"
        di as txt "     `dstr' | f`dstr' | g`dstr' | ratio (d/g) | ratio (u/g) | varlist"
        di as txt "     `dsep' | -`dsep' | -`dsep' | ----------- | ----------- | -------"
    }

    versus_unique str_12,              `options' unique
    versus_unique str_12 str_32,       `options' unique
    versus_unique str_12 str_32 str_4, `options' unique

    versus_unique double1,                 `options' unique
    versus_unique double1 double2,         `options' unique
    versus_unique double1 double2 double3, `options' unique

    versus_unique int1,           `options' unique
    versus_unique int1 int2,      `options' unique
    versus_unique int1 int2 int3, `options' unique

    * versus_unique str_12,              `options' funique unique
    * versus_unique str_12 str_32,       `options' funique unique
    * versus_unique str_12 str_32 str_4, `options' funique unique
    *
    * versus_unique double1,                 `options' funique unique
    * versus_unique double1 double2,         `options' funique unique
    * versus_unique double1 double2 double3, `options' funique unique
    *
    * versus_unique int1,           `options' funique unique
    * versus_unique int1 int2,      `options' funique unique
    * versus_unique int1 int2 int3, `options' funique unique

    versus_unique int1 str_32 double1,                                        unique `options'
    versus_unique int1 str_32 double1 int2 str_12 double2,                    unique `options'
    versus_unique int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, unique `options'

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        versus_unique strL1,             `options' `forcestrl' unique
        versus_unique strL1 strL2,       `options' `forcestrl' unique
        versus_unique strL1 strL2 strL3, `options' `forcestrl' unique
    }

    if ( ("`distunique'" != "") & ("`joint'" != "") ) {
        di as txt _n(1)
        di as txt "Benchmark vs `dstr'`dj' obs = `N', J = `J' (in seconds)"
        di as txt "     `dstr' |    unique | g`dstr' | ratio (d/g) | ratio (u/g) | varlist"
        di as txt "     `dsep' | -`dsep' | -`dsep' | ----------- | ----------- | -------"
    }
    else {
        di as txt _n(1)
        di as txt "Benchmark vs `dstr'`dj' obs = `N', J = `J' (in seconds)"
        di as txt "     `dstr' | f`dstr' | g`dstr' | ratio (u/g) | ratio (f/g) | varlist"
        di as txt "     `dsep' | -`dsep' | -`dsep' | ----------- | ----------- | -------"
    }

    versus_unique str_12,              `options'
    versus_unique str_12 str_32,       `options'
    versus_unique str_12 str_32 str_4, `options'

    versus_unique double1,                 `options'
    versus_unique double1 double2,         `options'
    versus_unique double1 double2 double3, `options'

    versus_unique int1,           `options'
    versus_unique int1 int2,      `options'
    versus_unique int1 int2 int3, `options'

    * versus_unique str_12,              `options' funique
    * versus_unique str_12 str_32,       `options' funique
    * versus_unique str_12 str_32 str_4, `options' funique
    *
    * versus_unique double1,                 `options' funique
    * versus_unique double1 double2,         `options' funique
    * versus_unique double1 double2 double3, `options' funique
    *
    * versus_unique int1,           `options' funique
    * versus_unique int1 int2,      `options' funique
    * versus_unique int1 int2 int3, `options' funique

    versus_unique int1 str_32 double1,                                        `options'
    versus_unique int1 str_32 double1 int2 str_12 double2,                    `options'
    versus_unique int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        versus_unique strL1,             `options' `forcestrl'
        versus_unique strL1 strL2,       `options' `forcestrl'
        versus_unique strL1 strL2 strL3, `options' `forcestrl'
    }

    di as txt _n(1) "{hline 80}" _n(1) "bench_unique, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop versus_unique
program versus_unique, rclass
    syntax varlist, [funique unique distinct joint distunique *]
    if ( "`unique'" == "unique" ) {
        tempvar ix
        gen `ix' = `=_N' - _n
        if ( strpos("`varlist'", "str") ) qui tostring `ix', replace
    }

    preserve
        timer clear
        timer on 42
        cap unique `varlist' `ix'
        assert inlist(_rc, 0, 459)
        timer off 42
        qui timer list
        local time_unique = r(t42)
    restore

    preserve
        timer clear
        timer on 43
        cap gunique `varlist' `ix', `options'
        assert inlist(_rc, 0, 459)
        timer off 43
        qui timer list
        local time_gunique = r(t43)
    restore

    if ( ("`funique'" == "funique") & ("`distinct'" == "") ) {
    preserve
        timer clear
        timer on 44
        cap funique `varlist' `ix'
        assert inlist(_rc, 0, 459)
        timer off 44
        qui timer list
        local time_funique = r(t44)
    restore
    }
    else if ( "`distunique'" != "" ) {
    preserve
        timer clear
        timer on 44
        cap unique `varlist' `ix'
        assert inlist(_rc, 0, 459)
        timer off 44
        qui timer list
        local time_funique = r(t44)
    restore
    }
    else {
        local time_funique = .
    }

    local rs = `time_unique'  / `time_gunique'
    local rf = `time_funique' / `time_gunique'

    if ( "`distinct'" == "" ) {
    di as txt "    `:di %7.3g `time_unique'' | `:di %7.3g `time_funique'' | `:di %7.3g `time_gunique'' | `:di %11.3g `rs'' | `:di %11.3g `rf'' | `varlist'"
    }
    else {
    di as txt "    `:di %9.3g `time_unique'' | `:di %9.3g `time_funique'' | `:di %9.3g `time_gunique'' | `:di %11.3g `rs'' | `:di %11.3g `rf'' | `varlist'"
    }
end

* Prototype of -unique-
* ---------------------

* cap mata: mata drop funique()
* mata:
* mata set matastrict off
* void funique(string scalar varlist, real scalar detail)
* {
* 	class Factor scalar F
* 	F = factor(varlist)
* 	printf("{txt}Number of unique values of turn is {res}%-11.0f{txt}\n", F.num_levels)
* 	printf("{txt}Number of records is {res}%-11.0f{txt}\n", F.num_obs)
* 	if (detail) {
* 		(void) st_addvar("long", tempvar=st_tempname())
* 		st_store(1::F.num_levels, tempvar, F.counts)
* 		st_varlabel(tempvar, "Records per " + invtokens(F.varlist))
* 		stata("su " + tempvar + ", detail")
* 	}
* }
* end
*
* cap program drop funique
* program funique
* 	syntax varlist [if] [in], [Detail]
* 	
* 	mata: funique("`varlist'", "`detail'"!="")
* end
capture program drop checks_levelsof
program checks_levelsof
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_levelsof, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(50)
    qui expand 200
    gen long ix = _n

    checks_inner_levelsof str_12,              `options'
    checks_inner_levelsof str_12 str_32,       `options'
    checks_inner_levelsof str_12 str_32 str_4, `options'

    checks_inner_levelsof double1,                 `options'
    checks_inner_levelsof double1 double2,         `options'
    checks_inner_levelsof double1 double2 double3, `options'

    checks_inner_levelsof int1,           `options'
    checks_inner_levelsof int1 int2,      `options'
    checks_inner_levelsof int1 int2 int3, `options'

    checks_inner_levelsof int1 str_32 double1,                                        `options'
    checks_inner_levelsof int1 str_32 double1 int2 str_12 double2,                    `options'
    checks_inner_levelsof int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        qui `noisily' gen_data, n(50)
        qui expand 200
        gen long ix = _n

        checks_inner_levelsof strL1,             `options' `forcestrl'
        checks_inner_levelsof strL1 strL2,       `options' `forcestrl'
        checks_inner_levelsof strL1 strL2 strL3, `options' `forcestrl'
    }

    clear
    set obs 10
    gen x = _n
    glevelsof x if 0
    glevelsof x if 0, gen(z)

    clear
    gen x = 1
    cap glevelsof x
    assert _rc == 2000

    clear
    set obs 100000
    gen x = _n
    cap glevelsof x in 1 / 10000 if mod(x, 3) == 0
    assert _rc == 0

    clear
    set obs 10
    gen x = string(_n)
    gen y = cond(mod(_n, 2), "a", "b")
    gen z = _n
    gen w = runiform()
    gen strL s = "s"
    expand 3

    cap glevelsof x,     gen(z, replace) nolocal
    assert _rc == 198
    cap glevelsof x,     gen(a, replace) nolocal
    assert _rc == 198
    cap glevelsof x y w, gen(z b)   nolocal
    assert _rc == 198
    cap glevelsof x y w, gen(a b)   nolocal
    assert _rc == 198
    cap glevelsof x y w, gen(a b z) nolocal
    assert _rc == 198

    cap glevelsof x y w, gen(a b c) nolocal
    assert _rc == 0
    cap glevelsof x y,   gen(z)
    assert _rc == 0
    cap glevelsof x y,   gen(a) nolocal
    assert _rc == 0

    cap glevelsof s, gen(a) nolocal
    assert _rc == 17002

    clear
    set obs 100000
    gen x = "a long string appeared" + string(_n)
    qui glevelsof x
    assert _rc == 920
    cap glevelsof x, gen(uniq) nolocal
    assert _rc == 0
end

capture program drop checks_inner_levelsof
program checks_inner_levelsof
    syntax varlist, [*]
    cap glevelsof `varlist', `options' v bench clean
    assert _rc == 0

    cap glevelsof `varlist' in 1, `options' miss
    assert _rc == 0

    cap glevelsof `varlist' if _n == 1, `options' local(hi) miss
    assert _rc == 0
    assert `"`r(levels)'"' == `"`hi'"'

    cap glevelsof `varlist' if _n < 10 in 5, `options' s(" | ") cols(", ") miss
    assert _rc == 0
end

***********************************************************************
*                               Compare                               *
***********************************************************************

capture program drop compare_levelsof
program compare_levelsof
    syntax, [tol(real 1e-6) NOIsily *]

    qui `noisily' gen_data, n(50)
    qui expand 10000

    local N    = trim("`: di %15.0gc _N'")
    local hlen = 24 + length("`options'") + length("`N'")
    di _n(1) "{hline 80}" _n(1) "compare_levelsof, N = `N', `options'" _n(1) "{hline 80}" _n(1)

    compare_inner_levelsof str_12, `options' sort
    compare_inner_levelsof str_32, `options' shuffle
    compare_inner_levelsof str_4,  `options'

    compare_inner_levelsof double1, `options' round
    compare_inner_levelsof double2, `options' round sort
    compare_inner_levelsof double3, `options' round shuffle

    compare_inner_levelsof int1, `options' shuffle
    compare_inner_levelsof int2, `options'
    compare_inner_levelsof int3, `options' sort

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        compare_inner_levelsof strL1, `options' `forcestrl'
        compare_inner_levelsof strL2, `options' `forcestrl'
        compare_inner_levelsof strL3, `options' `forcestrl'
    }

    qui `noisily' gen_data, n(1000)
    qui expand 100

    local N    = trim("`: di %15.0gc _N'")
    local hlen = 24 + length("`options'") + length("`N'")
    di _n(1) "{hline 80}" _n(1) "compare_levelsof_gen, N = `N', `options'" _n(1) "{hline 80}" _n(1)

    compare_inner_levelsof_gen str_12,              `options' sort
    compare_inner_levelsof_gen str_12 str_32,       `options' shuffle
    compare_inner_levelsof_gen str_12 str_32 str_4, `options'

    compare_inner_levelsof_gen double1,                 `options'
    compare_inner_levelsof_gen double1 double2,         `options' sort
    compare_inner_levelsof_gen double1 double2 double3, `options' shuffle

    compare_inner_levelsof_gen int1,           `options' shuffle
    compare_inner_levelsof_gen int1 int2,      `options'
    compare_inner_levelsof_gen int1 int2 int3, `options' sort

    compare_inner_levelsof_gen int1 str_32 double1,                                        `options'
    compare_inner_levelsof_gen int1 str_32 double1 int2 str_12 double2,                    `options'
    compare_inner_levelsof_gen int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'
end

capture program drop compare_inner_levelsof
program compare_inner_levelsof
    syntax varlist, [round shuffle sort *]

    tempvar rsort
    if ( "`shuffle'" != "" ) gen `rsort' = runiform()
    if ( "`shuffle'" != "" ) sort `rsort'
    if ( ("`sort'" != "") & ("`anything'" != "") ) hashsort `anything'

    cap  levelsof `varlist', s(" | ") local(l_stata)
    cap glevelsof `varlist', s(" | ") local(l_gtools) `options'
    if ( `"`l_stata'"' != `"`l_gtools'"' ) {
        if ( "`round'" != "" ) {
            while ( `"`l_stata'`l_gtools'"' != "" ) {
                gettoken l_scmp l_stata:  l_stata,  p(" | ")
                gettoken _      l_stata:  l_stata,  p(" | ")
                gettoken l_gcmp l_gtools: l_gtools, p(" | ")
                gettoken _      l_gtools: l_gtools, p(" | ")
                if ( `"`l_gcmp'"' != `"`l_scmp'"' ) {
                    cap assert abs(`l_gcmp' - `l_scmp') < 1e-15
                    if ( _rc ) {
                        di as err "    compare_levelsof (failed): glevelsof `varlist' returned different levels with rounding"
                        exit 198
                    }
                }
            }
            di as txt "    compare_levelsof (passed): glevelsof `varlist' returned similar levels as levelsof (tol = 1e-15)"
        }
        else {
            di as err "    compare_levelsof (failed): glevelsof `varlist' returned different levels to levelsof"
            exit 198
        }
    }
    else {
        di as txt "    compare_levelsof (passed): glevelsof `varlist' returned the same levels as levelsof"
    }

    cap  levelsof `varlist', local(l_stata)  miss
    cap glevelsof `varlist', local(l_gtools) miss `options'
    if ( `"`l_stata'"' != `"`l_gtools'"' ) {
        if ( "`round'" != "" ) {
            while ( `"`l_stata'`l_gtools'"' != "" ) {
                gettoken l_scmp l_stata:  l_stata,  p(" | ")
                gettoken _      l_stata:  l_stata,  p(" | ")
                gettoken l_gcmp l_gtools: l_gtools, p(" | ")
                gettoken _      l_gtools: l_gtools, p(" | ")
                if ( `"`l_gcmp'"' != `"`l_scmp'"' ) {
                    cap assert abs(`l_gcmp' - `l_scmp') < 1e-15
                    if ( _rc ) {
                        di as err "    compare_levelsof (failed): glevelsof `varlist' returned different levels with rounding"
                        exit 198
                    }
                }
            }
            di as txt "    compare_levelsof (passed): glevelsof `varlist' returned similar levels as levelsof (tol = 1e-15)"
        }
        else {
            di as err "    compare_levelsof (failed): glevelsof `varlist' returned different levels to levelsof"
            exit 198
        }
    }
    else {
        di as txt "    compare_levelsof (passed): glevelsof `varlist' returned the same levels as levelsof"
    }

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

        cap  levelsof `varlist' in 100 / `=ceil(`=_N / 2')', local(l_stata)  miss
        cap glevelsof `varlist' in 100 / `=ceil(`=_N / 2')', local(l_gtools) miss `options'
        if ( `"`l_stata'"' != `"`l_gtools'"' ) {
            if ( "`round'" != "" ) {
                while ( `"`l_stata'`l_gtools'"' != "" ) {
                    gettoken l_scmp l_stata:  l_stata,  p(" | ")
                    gettoken _      l_stata:  l_stata,  p(" | ")
                    gettoken l_gcmp l_gtools: l_gtools, p(" | ")
                    gettoken _      l_gtools: l_gtools, p(" | ")
                    if ( `"`l_gcmp'"' != `"`l_scmp'"' ) {
                        cap assert abs(`l_gcmp' - `l_scmp') < 1e-15
                        if ( _rc ) {
                            di as err "    compare_levelsof (failed): glevelsof `varlist' [in] returned different levels with rounding"
                            exit 198
                        }
                    }
                }
                di as txt "    compare_levelsof (passed): glevelsof `varlist' [in] returned similar levels as levelsof (tol = 1e-15)"
            }
            else {
                di as err "    compare_levelsof (failed): glevelsof `varlist' [in] returned different levels to levelsof"
                exit 198
            }
        }
        else {
            di as txt "    compare_levelsof (passed): glevelsof `varlist' [in] returned the same levels as levelsof"
        }

        cap glevelsof `varlist' in `=ceil(`=_N / 2')' / `=_N', local(l_stata)
        cap glevelsof `varlist' in `=ceil(`=_N / 2')' / `=_N', local(l_gtools) `options'
        if ( `"`l_stata'"' != `"`l_gtools'"' ) {
            if ( "`round'" != "" ) {
                while ( `"`l_stata'`l_gtools'"' != "" ) {
                    gettoken l_scmp l_stata:  l_stata,  p(" | ")
                    gettoken _      l_stata:  l_stata,  p(" | ")
                    gettoken l_gcmp l_gtools: l_gtools, p(" | ")
                    gettoken _      l_gtools: l_gtools, p(" | ")
                    if ( `"`l_gcmp'"' != `"`l_scmp'"' ) {
                        cap assert abs(`l_gcmp' - `l_scmp') < 1e-15
                        if ( _rc ) {
                            di as err "    compare_levelsof (failed): glevelsof `varlist' [in] returned different levels with rounding"
                            exit 198
                        }
                    }
                }
                di as txt "    compare_levelsof (passed): glevelsof `varlist' [in] returned similar levels as levelsof (tol = 1e-15)"
            }
            else {
                di as err "    compare_levelsof (failed): glevelsof `varlist' [in] returned different levels to levelsof"
                exit 198
            }
        }
        else {
            di as txt "    compare_levelsof (passed): glevelsof `varlist' [in] returned the same levels as levelsof"
        }

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

        cap  levelsof `varlist' if _n > `=_N / 2', local(l_stata)  miss
        cap glevelsof `varlist' if _n > `=_N / 2', local(l_gtools) miss `options'
        if ( `"`l_stata'"' != `"`l_gtools'"' ) {
            if ( "`round'" != "" ) {
                while ( `"`l_stata'`l_gtools'"' != "" ) {
                    gettoken l_scmp l_stata:  l_stata,  p(" | ")
                    gettoken _      l_stata:  l_stata,  p(" | ")
                    gettoken l_gcmp l_gtools: l_gtools, p(" | ")
                    gettoken _      l_gtools: l_gtools, p(" | ")
                    if ( `"`l_gcmp'"' != `"`l_scmp'"' ) {
                        cap assert abs(`l_gcmp' - `l_scmp') < 1e-15
                        if ( _rc ) {
                            di as err "    compare_levelsof (failed): glevelsof `varlist' [if] returned different levels with rounding"
                            exit 198
                        }
                    }
                }
                di as txt "    compare_levelsof (passed): glevelsof `varlist' [if] returned similar levels as levelsof (tol = 1e-15)"
            }
            else {
                di as err "    compare_levelsof (failed): glevelsof `varlist' [if] returned different levels to levelsof"
                exit 198
            }
        }
        else {
            di as txt "    compare_levelsof (passed): glevelsof `varlist' [if] returned the same levels as levelsof"
        }

        cap glevelsof `varlist' if _n < `=_N / 2', local(l_stata)
        cap glevelsof `varlist' if _n < `=_N / 2', local(l_gtools) `options'
        if ( `"`l_stata'"' != `"`l_gtools'"' ) {
            if ( "`round'" != "" ) {
                while ( `"`l_stata'`l_gtools'"' != "" ) {
                    gettoken l_scmp l_stata:  l_stata,  p(" | ")
                    gettoken _      l_stata:  l_stata,  p(" | ")
                    gettoken l_gcmp l_gtools: l_gtools, p(" | ")
                    gettoken _      l_gtools: l_gtools, p(" | ")
                    if ( `"`l_gcmp'"' != `"`l_scmp'"' ) {
                        cap assert abs(`l_gcmp' - `l_scmp') < 1e-15
                        if ( _rc ) {
                            di as err "    compare_levelsof (failed): glevelsof `varlist' [if] returned different levels with rounding"
                            exit 198
                        }
                    }
                }
                di as txt "    compare_levelsof (passed): glevelsof `varlist' [if] returned similar levels as levelsof (tol = 1e-15)"
            }
            else {
                di as err "    compare_levelsof (failed): glevelsof `varlist' [if] returned different levels to levelsof"
                exit 198
            }
        }
        else {
            di as txt "    compare_levelsof (passed): glevelsof `varlist' [if] returned the same levels as levelsof"
        }

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

        cap  levelsof `varlist' if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')', local(l_stata)  miss
        cap glevelsof `varlist' if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')', local(l_gtools) miss `options'
        if ( `"`l_stata'"' != `"`l_gtools'"' ) {
            if ( "`round'" != "" ) {
                while ( `"`l_stata'`l_gtools'"' != "" ) {
                    gettoken l_scmp l_stata:  l_stata,  p(" | ")
                    gettoken _      l_stata:  l_stata,  p(" | ")
                    gettoken l_gcmp l_gtools: l_gtools, p(" | ")
                    gettoken _      l_gtools: l_gtools, p(" | ")
                    if ( `"`l_gcmp'"' != `"`l_scmp'"' ) {
                        cap assert abs(`l_gcmp' - `l_scmp') < 1e-15
                        if ( _rc ) {
                            di as err "    compare_levelsof (failed): glevelsof `varlist' [if] [in] returned different levels with rounding"
                            exit 198
                        }
                    }
                }
                di as txt "    compare_levelsof (passed): glevelsof `varlist'  if] [in] returned similar levels as levelsof (tol = 1e-15)"
            }
            else {
                di as err "    compare_levelsof (failed): glevelsof `varlist' [if] [in] returned different levels to levelsof"
                exit 198
            }
        }
        else {
            di as txt "    compare_levelsof (passed): glevelsof `varlist' [if] [in] returned the same levels as levelsof"
        }

        cap glevelsof `varlist' if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N', local(l_stata)
        cap glevelsof `varlist' if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N', local(l_gtools) `options'
        if ( `"`l_stata'"' != `"`l_gtools'"' ) {
            if ( "`round'" != "" ) {
                while ( `"`l_stata'`l_gtools'"' != "" ) {
                    gettoken l_scmp l_stata:  l_stata,  p(" | ")
                    gettoken _      l_stata:  l_stata,  p(" | ")
                    gettoken l_gcmp l_gtools: l_gtools, p(" | ")
                    gettoken _      l_gtools: l_gtools, p(" | ")
                    if ( `"`l_gcmp'"' != `"`l_scmp'"' ) {
                        cap assert abs(`l_gcmp' - `l_scmp') < 1e-15
                        if ( _rc ) {
                            di as err "    compare_levelsof (failed): glevelsof `varlist' [if] [in] returned different levels with rounding"
                            exit 198
                        }
                    }
                }
                di as txt "    compare_levelsof (passed): glevelsof `varlist'  if] [in] returned similar levels as levelsof (tol = 1e-15)"
            }
            else {
                di as err "    compare_levelsof (failed): glevelsof `varlist' [if] [in] returned different levels to levelsof"
                exit 198
            }
        }
        else {
            di as txt "    compare_levelsof (passed): glevelsof `varlist' [if] [in] returned the same levels as levelsof"
        }

    di _n(1)
end

capture program drop compare_inner_levelsof_gen
program compare_inner_levelsof_gen
    syntax varlist, [shuffle sort *]

    tempvar rsort
    if ( "`shuffle'" != "" ) gen `rsort' = runiform()
    if ( "`shuffle'" != "" ) sort `rsort'
    if ( ("`sort'" != "") & ("`anything'" != "") ) hashsort `anything'

    local ifin1
    local ifin2 if _n < `=_N / 2'
    local ifin3 in `=ceil(`=_N / 2')' / `=_N'
    local ifin4 if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N'

    local iftxt1
    local iftxt2 " [if]"
    local iftxt3 " [in]"
    local iftxt4 " [if] [in]"

    forvalues i = 1 / 4 {
        preserve
            keep `varlist'
            glevelsof `varlist' `ifin`i'', nolocal gen(, replace) missing `options'
            qui keep in 1 / `r(J)'
            tempfile glevels
            qui save `"`glevels'"'
        restore, preserve
            if  ( "`ifin`i''" != "" ) qui keep `ifin`i''
            keep `varlist'
            qui duplicates drop
            cap merge 1:1 `varlist' using `"`glevels'"', assert(3) nogen
            if ( _rc ) {
                di as err "    compare_levelsof (failed): glevelsof `varlist'`iftxt`i'', gen(, replace) returned different levels to duplicates drop"
            }
            else {
                di as err "    compare_levelsof (passed): glevelsof `varlist'`iftxt`i'', gen(, replace) returned the same levels as  duplicates drop"
            }
        restore
    }

    di _n(1)
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_levelsof
program bench_levelsof
    syntax, [tol(real 1e-6) bench(int 1) n(int 100) NOIsily *]

    qui `noisily' gen_data, n(`n')
    qui expand `=1000 * `bench''
    qui gen rsort = rnormal()
    qui sort rsort

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    di as txt _n(1)
    di as txt "Benchmark vs levelsof, obs = `N', J = `J' (in seconds)"
    di as txt "    levelsof | flevelsof | glevelsof | ratio (l/g) | ratio (f/g) | varlist"
    di as txt "    -------- | --------- | --------- | ----------- | ----------- | -------"

    versus_levelsof str_12, `options' flevelsof
    versus_levelsof str_32, `options' flevelsof
    versus_levelsof str_4,  `options' flevelsof

    versus_levelsof double1, `options' flevelsof
    versus_levelsof double2, `options' flevelsof
    versus_levelsof double3, `options' flevelsof

    versus_levelsof int1, `options' flevelsof
    versus_levelsof int2, `options' flevelsof
    versus_levelsof int3, `options' flevelsof

    di as txt _n(1) "{hline 80}" _n(1) "bench_levelsof, `options'" _n(1) "{hline 80}" _n(1)
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
    di as txt "    `:di %8.3g `time_levelsof'' | `:di %9.3g `time_flevelsof'' | `:di %9.3g `time_glevelsof'' | `:di %11.3g `rs'' | `:di %11.3g `rf'' | `varlist'"
end
capture program drop checks_toplevelsof
program checks_toplevelsof
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_toplevelsof, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(50)
    qui expand 200
    gen long ix = _n

    checks_inner_toplevelsof -str_12,              `options'
    checks_inner_toplevelsof str_12 -str_32,       `options'
    checks_inner_toplevelsof str_12 -str_32 str_4, `options'

    checks_inner_toplevelsof -double1,                 `options'
    checks_inner_toplevelsof double1 -double2,         `options'
    checks_inner_toplevelsof double1 -double2 double3, `options'

    checks_inner_toplevelsof -int1,           `options'
    checks_inner_toplevelsof int1 -int2,      `options'
    checks_inner_toplevelsof int1 -int2 int3, `options'

    checks_inner_toplevelsof -int1 -str_32 -double1,                                         `options'
    checks_inner_toplevelsof int1 -str_32 double1 -int2 str_12 -double2,                     `options'
    checks_inner_toplevelsof int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options'

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        checks_inner_toplevelsof -strL1,             `options' `forcestrl'
        checks_inner_toplevelsof strL1 -strL2,       `options' `forcestrl'
        checks_inner_toplevelsof strL1 -strL2 strL3, `options' `forcestrl'
    }

    clear
    set obs 10
    gen x = _n
    gen w = runiform()
    gtoplevelsof x [w = w]
    gtop x [w = w]
    gtop x [w = .]
    gtop x [w = 0]
    gtop x if 0

    clear
    gen x = 1
    gtoplevelsof x

    clear
    set obs 100000
    gen x = _n
    gtoplevelsof x in 1 / 10000 if mod(x, 3) == 0
    gtoplevelsof x if _n < 1
end

capture program drop checks_inner_toplevelsof
program checks_inner_toplevelsof
    syntax anything, [*]
    gtoplevelsof `anything' in 1, `options' miss
    gtoplevelsof `anything' in 1, `options' miss
    gtoplevelsof `anything' if _n == 1, `options' local(hi) miss
    gtoplevelsof `anything' if _n < 10 in 5, `options' s(" | ") cols(", ") miss
    gtoplevelsof `anything', `options' v bench
    gtoplevelsof `anything', `options' ntop(2)
    gtoplevelsof `anything', `options' ntop(0)
    gtoplevelsof `anything', `options' ntop(0) noother
    gtoplevelsof `anything', `options' ntop(0) missrow
    gtoplevelsof `anything', `options' freqabove(10000)
    gtoplevelsof `anything', `options' pctabove(5)
    gtoplevelsof `anything', `options' pctabove(100)
    gtoplevelsof `anything', `options' pctabove(100) noother
    gtoplevelsof `anything', `options' groupmiss
    gtoplevelsof `anything', `options' nomiss
    gtoplevelsof `anything', `options' nooth
    gtoplevelsof `anything', `options' oth
    gtoplevelsof `anything', `options' oth(I'm some other group)
    gtoplevelsof `anything', `options' missrow
    gtoplevelsof `anything', `options' missrow(Hello, I'm missing)
    gtoplevelsof `anything', `options' pctfmt(%15.6f)
    gtoplevelsof `anything', `options' novaluelab
    gtoplevelsof `anything', `options' hidecont
    gtoplevelsof `anything', `options' varabb(5)
    gtoplevelsof `anything', `options' colmax(3)
    gtoplevelsof `anything', `options' colstrmax(2)
    gtoplevelsof `anything', `options' numfmt(%9.4f)
    gtoplevelsof `anything', `options' s(", ") cols(" | ")
    gtoplevelsof `anything', `options' v bench
    gtoplevelsof `anything', `options' colstrmax(0) numfmt(%.5g) colmax(0) varabb(1) freqabove(100) nooth
    gtoplevelsof `anything', `options' missrow nooth groupmiss pctabove(2.5)
    gtoplevelsof `anything', `options' missrow groupmiss pctabove(2.5)
    gtoplevelsof `anything', `options' missrow groupmiss pctabove(99)
    gtoplevelsof `anything', `options' s(|) cols(<<) missrow("I am missing ):")
    gtoplevelsof `anything', `options' s(|) cols(<<) matrix(zz) loc(oo)
    gtoplevelsof `anything', `options' loc(toplevels) mat(topmat)
    disp `"`toplevels'"'
    matrix list topmat
end

***********************************************************************
*                               Compare                               *
***********************************************************************

capture program drop compare_toplevelsof
program compare_toplevelsof
    syntax, [tol(real 1e-6) NOIsily wgt(str) *]

    gettoken wfun wfoo: wgt
    local wfun `wfun'
    local wfoo `wfoo'
    if ( `"`wfoo'"' == "f" ) {
        local wcall_f "[fw = int_unif_0_100]"
        local wgen_f qui gen int_unif_0_100 = int(100 * runiform()) if mod(_n, 100)
    }

    qui `noisily' gen_data, n(1000)
    qui expand 100
    qui `noisily' random_draws, random(2)
    `wgen_f'

    local N = trim("`: di %15.0gc _N'")
    di _n(1) "{hline 80}" _n(1) "consistency_gtoplevelsof_gcontract, N = `N', `options' `wgt'" _n(1) "{hline 80}" _n(1)

    compare_inner_gtoplevelsof -str_12,              `options' tol(`tol') wgt(`wcall_f')
    compare_inner_gtoplevelsof str_12 -str_32,       `options' tol(`tol') wgt(`wcall_f')
    compare_inner_gtoplevelsof str_12 -str_32 str_4, `options' tol(`tol') wgt(`wcall_f')

    compare_inner_gtoplevelsof -double1,                 `options' tol(`tol') wgt(`wcall_f')
    compare_inner_gtoplevelsof double1 -double2,         `options' tol(`tol') wgt(`wcall_f')
    compare_inner_gtoplevelsof double1 -double2 double3, `options' tol(`tol') wgt(`wcall_f')

    compare_inner_gtoplevelsof -int1,           `options' tol(`tol') wgt(`wcall_f')
    compare_inner_gtoplevelsof int1 -int2,      `options' tol(`tol') wgt(`wcall_f')
    compare_inner_gtoplevelsof int1 -int2 int3, `options' tol(`tol') wgt(`wcall_f')

    compare_inner_gtoplevelsof -int1 -str_32 -double1,                                         `options' tol(`tol') wgt(`wcall_f')
    compare_inner_gtoplevelsof int1 -str_32 double1 -int2 str_12 -double2,                     `options' tol(`tol') wgt(`wcall_f')
    compare_inner_gtoplevelsof int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options' tol(`tol') wgt(`wcall_f')

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        compare_inner_gtoplevelsof strL1,             `options' tol(`tol') contract `forcestrl' wgt(`wcall_f')
        compare_inner_gtoplevelsof strL1 strL2,       `options' tol(`tol') contract `forcestrl' wgt(`wcall_f')
        compare_inner_gtoplevelsof strL1 strL2 strL3, `options' tol(`tol') contract `forcestrl' wgt(`wcall_f')
    }
end

capture program drop compare_inner_gtoplevelsof
program compare_inner_gtoplevelsof
    syntax [anything], [tol(real 1e-6) wgt(str) *]

    if ( "`wgt'" != "" ) {
        local wtxt "; `wgt'"
    }

    local N = trim("`: di %15.0gc _N'")
    local hlen = 36 + length("`anything'") + length("`N'") + length("`wtxt'")
    di as txt _n(2) "Checking contract. N = `N'; varlist = `anything'`wtxt'" _n(1) "{hline `hlen'}"

    preserve
        _compare_inner_gtoplevelsof `anything', `options' tol(`tol') wgt(`wgt')
    restore, preserve
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_gtoplevelsof  `anything' in `from' / `to', `options' tol(`tol') wgt(`wgt')
    restore, preserve
        _compare_inner_gtoplevelsof `anything' if random2 > 0, `options' tol(`tol') wgt(`wgt')
    restore, preserve
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_gtoplevelsof `anything' if random2 < 0 in `from' / `to', `options' tol(`tol') wgt(`wgt')
    restore
end

capture program drop _compare_inner_gtoplevelsof
program _compare_inner_gtoplevelsof
    syntax [anything] [if] [in], [tol(real 1e-6) contract wgt(str) *]

    if ( "`contract'" == "" ) local contract gcontract

    * cf(Cum) p(Pct) cp(PctCum)
    local opts freq(N)
    preserve
        qui {
            `noisily' `contract' `anything' `if' `in' `wgt', `opts'
            qui sum N, meanonly
            local r_N = `r(sum)'
            hashsort -N `anything'
            keep in 1/10
            set obs 11
            gen byte ID = 1
            replace ID  = 3 in 11
            gen long ix = _n
            gen long Cum = sum(N)
            gen double Pct = 100 * N / `r_N'
            gen double PctCum = 100 * Cum / `r_N'
            replace Pct       = 100 - PctCum[10] in 11
            replace PctCum    = 100 in 11
            replace N         = `r_N' - Cum[10] in 11
            replace Cum       = `r_N' in 11
        }
        tempfile fg
        qui save `fg'
    restore

    tempname gmat
    preserve
        qui {
            `noisily' gtoplevelsof `anything' `if' `in' `wgt', mat(`gmat')
            clear
            svmat `gmat', names(col)
            gen long ix = _n
        }
        tempfile fc
        qui save `fc'
    restore

    preserve
    use `fc', clear
        local bad_any = 0
        local bad `anything'
        local bad: subinstr local bad "-" "", all
        local bad: subinstr local bad "+" "", all
        foreach var in N Cum Pct PctCum {
            rename `var' c_`var'
        }
        qui merge 1:1 ix using `fg', assert(3)
        foreach var in N Cum Pct PctCum {
            qui count if ( (abs(`var' - c_`var') > `tol') & (`var' != c_`var'))
            if ( `r(N)' > 0 ) {
                gen bad_`var' = abs(`var' - c_`var') * (`var' != c_`var')
                local bad `bad' *`var'
                di "    `var' has `:di r(N)' mismatches".
                local bad_any = 1
                order *`var'
            }
        }
        if ( `bad_any' ) {
            if ( "`if'`in'" == "" ) {
                di "    compare_gtoplevelsof_gcontract (failed): full range, `anything'"
            }
            else if ( "`if'`in'" != "" ) {
                di "    compare_gtoplevelsof_gcontract (failed): [`if' `in'], `anything'"
            }
            order `bad'
            egen bad_any = rowmax(bad_*)
            l `bad' if bad_any
            sum bad_*
            desc
            exit 9
        }
        else {
            if ( "`if'`in'" == "" ) {
                di "    compare_gtoplevelsof_gcontract (passed): full range, gcontract results equal to contract (tol = `tol')"
            }
            else if ( "`if'`in'" != "" ) {
                di "    compare_gtoplevelsof_gcontract (passed): [`if' `in'], gcontract results equal to contract (tol = `tol')"
            }
        }
    restore
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_toplevelsof
program bench_toplevelsof
    syntax, [tol(real 1e-6) bench(real 1) n(int 1000) NOIsily *]

    qui gen_data, n(`n')
    qui expand `=100 * `bench''
    qui `noisily' random_draws, random(1) double
    qui hashsort random1

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    di as txt _n(1)
    di as txt "Benchmark toplevelsof vs contract (unsorted), obs = `N', J = `J' (in seconds)"
    di as txt "    gcontract | gtoplevelsof | ratio (c/t) | varlist"
    di as txt "    --------- | ------------ | ----------- | -------"

    versus_toplevelsof str_12,              `options'
    versus_toplevelsof str_12 str_32,       `options'
    versus_toplevelsof str_12 str_32 str_4, `options'

    versus_toplevelsof double1,                 `options'
    versus_toplevelsof double1 double2,         `options'
    versus_toplevelsof double1 double2 double3, `options'

    versus_toplevelsof int1,           `options'
    versus_toplevelsof int1 int2,      `options'
    versus_toplevelsof int1 int2 int3, `options'

    versus_toplevelsof int1 str_32 double1,                                        `options'
    versus_toplevelsof int1 str_32 double1 int2 str_12 double2,                    `options'
    versus_toplevelsof int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    di as txt _n(1)
    di as txt "Benchmark toplevelsof vs contract (plus preserve, sort, keep, restore), obs = `N', J = `J' (in seconds)"
    di as txt "    gcontract | gtoplevelsof | ratio (c/t) | varlist"
    di as txt "    --------- | ------------ | ----------- | -------"

    versus_toplevelsof str_12,              `options' sorted
    versus_toplevelsof str_12 str_32,       `options' sorted
    versus_toplevelsof str_12 str_32 str_4, `options' sorted

    versus_toplevelsof double1,                 `options' sorted
    versus_toplevelsof double1 double2,         `options' sorted
    versus_toplevelsof double1 double2 double3, `options' sorted

    versus_toplevelsof int1,           `options' sorted
    versus_toplevelsof int1 int2,      `options' sorted
    versus_toplevelsof int1 int2 int3, `options' sorted

    versus_toplevelsof int1 str_32 double1,                                        `options' sorted
    versus_toplevelsof int1 str_32 double1 int2 str_12 double2,                    `options' sorted
    versus_toplevelsof int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options' sorted

    di _n(1) "{hline 80}" _n(1) "bench_toplevelsof, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop versus_toplevelsof
program versus_toplevelsof, rclass
    syntax [anything], [sorted *]

    local stats       ""
    local percentiles ""

    local opts freq(freq) cf(cf) p(p) cp(cp)

    if ( "`sorted'" == "" ) {
    preserve
        timer clear
        timer on 42
        qui gcontract `anything' `if' `in', `opts'
        timer off 42
        qui timer list
        local time_contract = r(t42)
    restore
    }
    else {
        timer clear
        timer on 42
        qui {
            preserve
            gcontract `anything' `if' `in', `opts'
            hashsort -freq `anything'
            keep in 1/10
            restore
        }
        timer off 42
        qui timer list
        local time_contract = r(t42)
    }

    timer clear
    timer on 43
    qui gtoplevelsof `anything' `if' `in'
    timer off 43
    qui timer list
    local time_gcontract = r(t43)

    local rs = `time_contract'  / `time_gcontract'
    di as txt "    `:di %9.3g `time_contract'' | `:di %12.3g `time_gcontract'' | `:di %11.3g `rs'' | `anything'"
end
capture program drop checks_isid
program checks_isid
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_isid, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(5000)
    qui expand 2
    gen long ix  = _n
    gen byte ind = 0

    checks_inner_isid str_12,              `options'
    checks_inner_isid str_12 str_32,       `options'
    checks_inner_isid str_12 str_32 str_4, `options'

    checks_inner_isid double1,                 `options'
    checks_inner_isid double1 double2,         `options'
    checks_inner_isid double1 double2 double3, `options'

    checks_inner_isid int1,           `options'
    checks_inner_isid int1 int2,      `options'
    checks_inner_isid int1 int2 int3, `options'

    checks_inner_isid int1 str_32 double1,                                        `options'
    checks_inner_isid int1 str_32 double1 int2 str_12 double2,                    `options'
    checks_inner_isid int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        checks_inner_isid strL1,             `options' `forcestrl'
        checks_inner_isid strL1 strL2,       `options' `forcestrl'
        checks_inner_isid strL1 strL2 strL3, `options' `forcestrl'
    }

    clear
    gen x = 1
    cap gisid x
    assert _rc == 0

    clear
    set obs 4
    gen x = 1
    gen y = _n
    gen z = _n
    replace y = 1 in 1/2
    replace x = 2 in 3/4
    gisid x y z, v

    gisid x y z if 0, v
    gisid x y z if x, v
    gisid x y z in 1, v

    replace y = x
    replace z = 1 in 1/2
    cap noi gisid x y z, v
    assert _rc == 459
end

capture program drop checks_inner_isid
program checks_inner_isid
    syntax varlist, [*]
    cap gisid `varlist', `options' v bench missok
    assert _rc == 459

    cap gisid `varlist' in 1, `options' missok
    assert _rc == 0

    cap gisid `varlist' if _n == 1, `options' missok
    assert _rc == 0

    cap gisid `varlist' if _n < 10 in 5, `options' missok
    assert _rc == 0

    cap gisid ix `varlist', `options' v bench missok
    assert _rc == 0

    preserve
    sort `varlist'
    cap gisid `varlist' ix, `options' v bench missok
    assert _rc == 0

    qui replace ix  = _n
    qui replace ix  = 1 in 1/2
    qui replace ind = 1 in 3/4
    cap gisid  ind ix `varlist', `options' v bench missok
    assert _rc == 459
    restore
end

***********************************************************************
*                               Compare                               *
***********************************************************************

capture program drop compare_isid
program compare_isid
    syntax, [tol(real 1e-6) NOIsily *]

    qui `noisily' gen_data, n(1000)
    qui expand 100

    local N    = trim("`: di %15.0gc _N'")
    local hlen = 20 + length("`options'") + length("`N'")
    di _n(1) "{hline 80}" _n(1) "compare_isid, N = `N', `options'" _n(1) "{hline 80}" _n(1)

    compare_inner_isid str_12,              `options'
    compare_inner_isid str_12 str_32,       `options'
    compare_inner_isid str_12 str_32 str_4, `options'

    compare_inner_isid double1,                 `options'
    compare_inner_isid double1 double2,         `options'
    compare_inner_isid double1 double2 double3, `options'

    compare_inner_isid int1,           `options'
    compare_inner_isid int1 int2,      `options'
    compare_inner_isid int1 int2 int3, `options'

    compare_inner_isid int1 str_32 double1,                                        `options'
    compare_inner_isid int1 str_32 double1 int2 str_12 double2,                    `options'
    compare_inner_isid int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        compare_inner_isid strL1,             `options' `forcestrl'
        compare_inner_isid strL1 strL2,       `options' `forcestrl'
        compare_inner_isid strL1 strL2 strL3, `options' `forcestrl'
    }
end

capture program drop compare_inner_isid
program compare_inner_isid
    syntax varlist, [*]

    tempvar rsort ix
    gen `rsort' = runiform()
    sort `rsort'
    gen long `ix' = _n

    cap isid `varlist', missok
    local rc_isid = _rc
    cap gisid `varlist', missok `options'
    local rc_gisid = _rc
    check_rc `rc_isid' `rc_gisid' , by( `varlist')

    * make sure sorted check gives same result
    hashsort `varlist'
    cap gisid `varlist', missok `options'
    local rc_gisid = _rc
    check_rc `rc_isid' `rc_gisid' , by([sorted] `varlist')

    cap isid `ix' `varlist', missok
    local rc_isid = _rc
    cap gisid `ix' `varlist', missok `options'
    local rc_gisid = _rc
    check_rc `rc_isid' `rc_gisid' , by( ix `varlist')

    * make sure sorted check gives same result
    hashsort `ix' `varlist'
    cap gisid `ix' `varlist', missok `options'
    local rc_gisid = _rc
    check_rc `rc_isid' `rc_gisid' , by([sorted] ix `varlist')

    cap isid `rsort' `varlist', missok
    local rc_isid = _rc
    cap gisid `rsort' `varlist', missok `options'
    local rc_gisid = _rc
    check_rc `rc_isid' `rc_gisid' , by( rsort `varlist')

    * make sure sorted check gives same result
    hashsort `rsort' `varlist'
    cap isid `rsort' `varlist', missok
    local rc_isid = _rc
    cap gisid `rsort' `varlist', missok `options'
    local rc_gisid = _rc
    check_rc `rc_isid' `rc_gisid' , by([sorted] rsort `varlist')

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    qui replace `ix' = `=_N / 2' if _n > `=_N / 2'
    cap isid `ix'
    local rc_isid = _rc
    cap gisid `ix', `options'
    local rc_gisid = _rc
    check_rc `rc_isid' `rc_gisid' , by( ix)

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    preserve
        qui keep in 100 / `=ceil(`=_N / 2')'
        cap isid `ix' `varlist', missok
        local rc_isid = _rc
    restore
    cap gisid `ix' `varlist' in 100 / `=ceil(`=_N / 2')', missok `options'
    local rc_gisid = _rc
    check_rc  `rc_isid' `rc_gisid' , by( ix `varlist' in 100 / `=ceil(`=_N / 2')')

    preserve
        qui keep in `=ceil(`=_N / 2')' / `=_N'
        cap isid `ix' `varlist', missok
        local rc_isid = _rc
    restore
    cap gisid `ix' `varlist' in `=ceil(`=_N / 2')' / `=_N', missok `options'
    local rc_gisid = _rc
    check_rc  `rc_isid' `rc_gisid' , by( ix `varlist' in `=ceil(`=_N / 2')' / `=_N')

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    preserve
        qui keep if _n < `=_N / 2'
        cap isid `ix' `varlist', missok
        local rc_isid = _rc
    restore
    cap gisid `ix' `varlist' if _n < `=_N / 2', missok
    local rc_gisid = _rc
    check_rc  `rc_isid' `rc_gisid' , by( ix `varlist' if _n < `=_N / 2')

    preserve
        qui keep if _n > `=_N / 2'
        cap isid `ix' `varlist', missok
        local rc_isid = _rc
    restore
    cap gisid `ix' `varlist' if _n > `=_N / 2', missok `options'
    local rc_gisid = _rc
    check_rc  `rc_isid' `rc_gisid' , by( ix `varlist' if _n > `=_N / 2')

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    qui replace `ix' = 100 in 1 / 100

    preserve
        qui keep if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')'
        cap isid `ix' `varlist', missok
        local rc_isid = _rc
    restore
    cap gisid `ix' `varlist' if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')', missok `options'
    local rc_gisid = _rc
    check_rc  `rc_isid' `rc_gisid' , by( ix `varlist' if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')')

    preserve
        qui keep if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N'
        cap isid `ix' `varlist', missok
        local rc_isid = _rc
    restore
    cap gisid `ix' `varlist' if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N', missok
    local rc_gisid = _rc
    check_rc  `rc_isid' `rc_gisid' , by( ix `varlist' if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N')

    di _n(1)
end

capture program drop check_rc
program check_rc
    syntax anything, by(str)

    tokenize `anything'
    local rc_isid  `1'
    local rc_gisid `2'

    if ( `rc_isid' != `rc_gisid' ) {
        if ( `rc_isid' & (`rc_gisid' == 0) ) {
            di as err "    compare_isid (failed): gisid `by' was an id but isid returned error r(`rc_isid')"
            exit `rc_isid'
        }
        else if ( (`rc_isid' == 0) & `rc_gisid' ) {
            di as err "    compare_isid (failed): isid `by' was an id but gisid returned error r(`rc_gisid')"
            exit `rc_gisigd'
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
    syntax, [tol(real 1e-6) bench(int 1) n(int 1000) NOIsily *]

    qui `noisily' gen_data, n(`n')
    qui expand `=100 * `bench''
    qui gen rsort = rnormal()
    qui sort rsort

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    di as txt _n(1)
    di as txt "Benchmark vs isid, obs = `N', all calls include an index to ensure uniqueness (in seconds)"
    di as txt "     isid | fisid | gisid | ratio (i/g) | ratio (f/g) | varlist"
    di as txt "     ---- | ----- | ----- | ----------- | ----------- | -------"

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

    di as txt _n(1)
    di as txt "Benchmark vs isid, obs = `N', J = `J' (in seconds)"
    di as txt "     isid | fisid | gisid | ratio (i/g) | ratio (f/g) | varlist"
    di as txt "     ---- | ----- | ----- | ----------- | ----------- | -------"

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

    di as txt _n(1) "{hline 80}" _n(1) "bench_isid, `options'" _n(1) "{hline 80}" _n(1)
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
        cap isid `varlist' `ix', missok
        assert inlist(_rc, 0, 459)
        timer off 42
        qui timer list
        local time_isid = r(t42)
    restore

    preserve
        timer clear
        timer on 43
        cap gisid `varlist' `ix', `options' missok
        assert inlist(_rc, 0, 459)
        timer off 43
        qui timer list
        local time_gisid = r(t43)
    restore

    if ( "`fisid'" == "fisid" ) {
    preserve
        timer clear
        timer on 44
        cap fisid `varlist' `ix', missok
        if ( inlist(_rc, 0, 459) ) {
            timer off 44
            qui timer list
            local time_fisid = r(t44)
        }
        else {
            di "(note: fisid failed)"
            timer off 44
            local time_fisid = .
        }
    restore
    }
    else {
        local time_fisid = .
    }

    local rs = `time_isid'  / `time_gisid'
    local rf = `time_fisid' / `time_gisid'
    di as txt "    `:di %5.3g `time_isid'' | `:di %5.3g `time_fisid'' | `:di %5.3g `time_gisid'' | `:di %11.3g `rs'' | `:di %11.3g `rf'' | `varlist'"
end
capture program drop checks_duplicates
program checks_duplicates
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_duplicates, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(5000)
    qui expand 2

    checks_inner_duplicates str_12,              `options'
    checks_inner_duplicates str_12 str_32,       `options'
    checks_inner_duplicates str_12 str_32 str_4, `options'

    checks_inner_duplicates double1,                 `options'
    checks_inner_duplicates double1 double2,         `options'
    checks_inner_duplicates double1 double2 double3, `options'

    checks_inner_duplicates int1,           `options'
    checks_inner_duplicates int1 int2,      `options'
    checks_inner_duplicates int1 int2 int3, `options'

    checks_inner_duplicates int1 str_32 double1,                                        `options'
    checks_inner_duplicates int1 str_32 double1 int2 str_12 double2,                    `options'
    checks_inner_duplicates int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        checks_inner_duplicates strL1,             `options' `forcestrl'
        checks_inner_duplicates strL1 strL2,       `options' `forcestrl'
        checks_inner_duplicates strL1 strL2 strL3, `options' `forcestrl'
    }

    sysuse auto, clear
    gen idx = _n
    qui gduplicates report foreign,       `options'
    assert r(unique_value) == 2
    qui gduplicates report foreign price, `options'
    assert r(unique_value) == _N
    qui gduplicates report foreign make,  `options'
    assert r(unique_value) == _N
    qui gduplicates report idx,           `options' gtools(v bench)
end

capture program drop checks_inner_duplicates
program checks_inner_duplicates
    syntax varlist, [*]
    preserve
    tempvar tag
    qui gduplicates report   `varlist', gtools(`options')
    qui gduplicates examples `varlist', gtools(`options')
    qui gduplicates list     `varlist', gtools(`options')
    qui gduplicates tag      `varlist', gtools(`options') gen(`tag')
    cap gduplicates drop     `varlist', gtools(`options')
    assert _rc == 198
    qui gduplicates drop     `varlist', force
    restore
end

***********************************************************************
*                               Compare                               *
***********************************************************************

capture program drop compare_duplicates
program compare_duplicates
    syntax, [tol(real 1e-6) NOIsily bench(int 1) n(int 1000) *]

    qui `noisily' gen_data, n(`n')
    qui expand `=100 * `bench''
    qui `noisily' random_draws, random(2)
    qui gen rsort = rnormal()
    qui sort rsort

    compare_duplicates_internal str_12,              `options'
    compare_duplicates_internal str_12 str_32,       `options'
    compare_duplicates_internal str_12 str_32 str_4, `options'

    compare_duplicates_internal double1,                 `options'
    compare_duplicates_internal double1 double2,         `options'
    compare_duplicates_internal double1 double2 double3, `options'

    compare_duplicates_internal int1,           `options'
    compare_duplicates_internal int1 int2,      `options'
    compare_duplicates_internal int1 int2 int3, `options'

    compare_duplicates_internal int1 str_32 double1,                                        `options'
    compare_duplicates_internal int1 str_32 double1 int2 str_12 double2,                    `options'
    compare_duplicates_internal int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        compare_duplicates_internal strL1,             `options' `forcestrl'
        compare_duplicates_internal strL1 strL2,       `options' `forcestrl'
        compare_duplicates_internal strL1 strL2 strL3, `options' `forcestrl'
    }
end

capture program drop compare_duplicates_internal
program compare_duplicates_internal
    syntax varlist, [*]

    if ( "`benchmode'" == "" )  {
        di _n(2) "Checking duplicates; varlist = `varlist'" _n(1) "{hline `hlen'}"
    }

    preserve
        _compare_duplicates `varlist' `if' `in', `options' report
        _compare_duplicates `varlist' `if' `in', `options' tag
        _compare_duplicates `varlist' `if' `in', `options' drop
    restore, preserve
        if ( "`shuffle'" != "" ) sort `rsort'
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_duplicates `varlist' in `from' / `to', `options' report
        _compare_duplicates `varlist' in `from' / `to', `options' tag
        _compare_duplicates `varlist' in `from' / `to', `options' drop
    restore, preserve
        _compare_duplicates `varlist' if random2 > 0, `options' report
        _compare_duplicates `varlist' if random2 > 0, `options' tag
        _compare_duplicates `varlist' if random2 > 0, `options' drop
    restore, preserve
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_duplicates `varlist' if random2 < 0 in `from' / `to', `options' report
        _compare_duplicates `varlist' if random2 < 0 in `from' / `to', `options' tag
        _compare_duplicates `varlist' if random2 < 0 in `from' / `to', `options' drop
    restore
end

***********************************************************************
*                              Benchmark                              *
***********************************************************************

capture program drop bench_duplicates
program bench_duplicates
    syntax, [tol(real 1e-6) NOIsily bench(int 1) n(int 1000) *]
    local options `options' benchmode

    qui `noisily' gen_data, n(`n')
    qui expand `=100 * `bench''
    qui gen rsort = rnormal()
    qui sort rsort

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    di as txt _n(1)
    di as txt "Benchmark vs duplicates report, obs = `N', J = `J' (in seconds)"
    di as txt "    duplicates | gduplicates | ratio (g/h) | varlist"
    di as txt "    ---------- | ----------- | ----------- | -------"

    _compare_duplicates str_12,              `options' report
    _compare_duplicates str_12 str_32,       `options' report
    _compare_duplicates str_12 str_32 str_4, `options' report

    _compare_duplicates double1,                 `options' report
    _compare_duplicates double1 double2,         `options' report
    _compare_duplicates double1 double2 double3, `options' report

    _compare_duplicates int1,           `options' report
    _compare_duplicates int1 int2,      `options' report
    _compare_duplicates int1 int2 int3, `options' report

    _compare_duplicates int1 str_32 double1,                                        `options' report
    _compare_duplicates int1 str_32 double1 int2 str_12 double2,                    `options' report
    _compare_duplicates int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options' report

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        _compare_duplicates strL1,             `options' report `forcestrl'
        _compare_duplicates strL1 strL2,       `options' report `forcestrl'
        _compare_duplicates strL1 strL2 strL3, `options' report `forcestrl'
    }

    di as txt _n(1)
    di as txt "Benchmark vs duplicates drop, obs = `N', J = `J' (in seconds; output compared via {opt cf})"
    di as txt "    duplicates | gduplicates | ratio (g/h) | varlist"
    di as txt "    ---------- | ----------- | ----------- | -------"

    _compare_duplicates str_12,              `options' drop
    _compare_duplicates str_12 str_32,       `options' drop
    _compare_duplicates str_12 str_32 str_4, `options' drop

    _compare_duplicates double1,                 `options' drop
    _compare_duplicates double1 double2,         `options' drop
    _compare_duplicates double1 double2 double3, `options' drop

    _compare_duplicates int1,           `options' drop
    _compare_duplicates int1 int2,      `options' drop
    _compare_duplicates int1 int2 int3, `options' drop

    _compare_duplicates int1 str_32 double1,                                        `options' drop
    _compare_duplicates int1 str_32 double1 int2 str_12 double2,                    `options' drop
    _compare_duplicates int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options' drop

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        _compare_duplicates strL1,             `options' drop `forcestrl'
        _compare_duplicates strL1 strL2,       `options' drop `forcestrl'
        _compare_duplicates strL1 strL2 strL3, `options' drop `forcestrl'
    }

    di _n(1) "{hline 80}" _n(1) "compare_duplicates, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop _compare_duplicates
program _compare_duplicates, rclass
    syntax varlist [if] [in], [drop report tag benchmode *]

    tempvar r_tag g_tag
    if ( "`drop'" != "" ) {
        local force force
    }
    else if ( "`tag'" != "" ) {
        local r_gen gen(`r_tag')
        local g_gen gen(`g_tag')
    }

    timer clear
    if ( "`drop'" != "" ) preserve
        timer on 42
        qui duplicates `tag' `drop' `report' `varlist' `if' `in', `force' `r_gen'
        timer off 42
        if ( "`report'" != "" ) {
            local r_duplicates = `r(unique_value)'
        }
        else if ( "`drop'" != "" ) {
            tempfile file_duplicates
            qui save `file_duplicates'
        }
        else if ( "`tag'" != "" ) {
        }
    if ( "`drop'" != "" ) restore
    qui timer list
    local time_duplicates = r(t42)

    timer clear
    if ( "`drop'" != "" ) preserve
        timer on 43
        qui gduplicates `tag' `drop' `report' `varlist' `if' `in', `force' gtools(`options') `g_gen'
        timer off 43
        if ( "`report'" != "" ) {
            cap noi assert `r(unique_value)' == `r_duplicates'
            if ( _rc ) exit _rc
            local rc = _rc
        }
        else if ( "`drop'" != "" ) {
            cap noi cf * using `file_duplicates'
            local rc = _rc
        }
        else if ( "`tag'" != "" ) {
            cap noi assert `r_tag' == `g_tag'
            local rc = _rc
        }
        else {
            local rc 0
        }
    if ( "`drop'" != "" ) restore

    if ( "`benchmode'" == "" ) {
        local dstr: di %7s "`drop'`report'`tag'"

        if ( `rc' ) {
            di as err "    compare_gduplicates (failed): `dstr' `if' `in' yielded different results"
        }
        else {
            di as txt "    compare_gduplicates (passed): `dstr' `if' `in' yielded identical results"
        }
        exit `rc'
    }

    qui timer list
    local time_gduplicates = r(t43)

    local rs = `time_duplicates'  / `time_gduplicates'
    di as txt "    `:di %10.3g `time_duplicates'' | `:di %11.3g `time_gduplicates'' | `:di %11.3g `rs'' | `varlist'"
end
capture program drop checks_hashsort
program checks_hashsort
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_hashsort, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(5000)
    qui expand 2
    gen long ix = _n

    checks_inner_hashsort -str_12,              `options'
    checks_inner_hashsort str_12 -str_32,       `options'
    checks_inner_hashsort str_12 -str_32 str_4, `options'

    checks_inner_hashsort -double1,                 `options'
    checks_inner_hashsort double1 -double2,         `options'
    checks_inner_hashsort double1 -double2 double3, `options'

    checks_inner_hashsort -int1,           `options'
    checks_inner_hashsort int1 -int2,      `options'
    checks_inner_hashsort int1 -int2 int3, `options'

    checks_inner_hashsort -int1 -str_32 -double1,                                         `options'
    checks_inner_hashsort int1 -str_32 double1 -int2 str_12 -double2,                     `options'
    checks_inner_hashsort int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options'

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        checks_inner_hashsort -strL1,             `options' `forcestrl'
        checks_inner_hashsort strL1 -strL2,       `options' `forcestrl'
        checks_inner_hashsort strL1 -strL2 strL3, `options' `forcestrl'
    }

    sysuse auto, clear
    gen idx = _n
    hashsort -foreign rep78 make -mpg, `options'
    hashsort idx,                      `options'
    hashsort -foreign -rep78,          `options'
    hashsort idx,                      `options'
    hashsort foreign rep78 mpg,        `options'
    hashsort idx,                      `options' v bench

    * https://github.com/mcaceresb/stata-gtools/issues/31
    qui {
        clear
        set obs 10
        gen x = "hi"
        replace x = "" in 1 / 5
        gen y = floor(_n / 3)
        replace y = .a in 1
        replace y = .b in 2
        replace y = .c in 3
        replace y = .  in 4

        preserve
            gsort x -y
            tempfile a
            save "`a'"
        restore
        hashsort x -y, mlast
        cf * using "`a'"
    }

    ****************
    *  Misc tests  *
    ****************

    clear
    gen x = 1
    hashsort x

    clear
    set obs 10
    gen x = _n
    expand 3
    hashsort x, gen(y) sortgen
    assert "`:sortedby'" == "y"
    hashsort x, v
    assert "`:sortedby'" == "x"
    hashsort x, skipcheck v
    hashsort x, gen(y) replace
    assert "`:sortedby'" == "x"
end

capture program drop checks_inner_hashsort
program checks_inner_hashsort
    syntax anything, [*]
    tempvar ix
    hashsort `anything', `options' gen(`ix')
    hashsort `: subinstr local anything "-" "", all', `options'
    hashsort ix, `options'
end

capture program drop bench_hashsort
program bench_hashsort
    compare_hashsort `0'
end

capture program drop compare_hashsort
program compare_hashsort
    syntax, [tol(real 1e-6) NOIsily bench(int 1) n(int 1000) benchmode *]
    local options `options' `benchmode'
    if ( "`benchmode'" == "" ) {
        local benchcomp Comparison
    }
    else {
        local benchcomp Benchmark
    }

    cap gen_data, n(`n')
    qui expand 10 * `bench'
    qui gen rsort = rnormal()
    qui sort rsort

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    di _n(1)
    di "`benchcomp' vs gsort, obs = `N', J = `J' (in seconds; datasets are compared via {opt cf})"
    di "    gsort | hashsort | ratio (g/h) | varlist"
    di "    ----- | -------- | ----------- | -------"

    compare_gsort -str_12,              `options' mfirst
    compare_gsort str_12 -str_32,       `options' mfirst
    compare_gsort str_12 -str_32 str_4, `options' mfirst

    compare_gsort -double1,                 `options' mfirst
    compare_gsort double1 -double2,         `options' mlast
    compare_gsort double1 -double2 double3, `options' mfirst

    compare_gsort -int1,           `options' mfirst
    compare_gsort int1 -int2,      `options' mfirst
    compare_gsort int1 -int2 int3, `options' mlast

    compare_gsort -int1 -str_32 -double1,                                         `options' mlast
    compare_gsort int1 -str_32 double1 -int2 str_12 -double2,                     `options' mfirst
    compare_gsort int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options' mfirst

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        compare_gsort -strL1,             `options' mfirst `forcestrl'
        compare_gsort strL1 -strL2,       `options' mfirst `forcestrl'
        compare_gsort strL1 -strL2 strL3, `options' mlast  `forcestrl'
    }

    qui expand 10
    local N = trim("`: di %15.0gc _N'")
    cap drop rsort
    qui gen rsort = rnormal()
    qui sort rsort

    di _n(1)
    di "`benchcomp' vs sort (stable), obs = `N', J = `J' (in seconds; datasets are compared via {opt cf})"
    di "     sort | fsort | hashsort | ratio (s/h) | ratio (f/h) | varlist"
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

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        compare_sort strL1,             `options' mfirst `forcestrl'
        compare_sort strL1 strL2,       `options' mfirst `forcestrl'
        compare_sort strL1 strL2 strL3, `options' mlast  `forcestrl'
    }

    di _n(1) "{hline 80}" _n(1) "compare_hashsort, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop compare_sort
program compare_sort, rclass
    syntax varlist, [fsort benchmode *]
    local rc = 0

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
        * if ( _rc ) {
        *     qui ds *
        *     local memvars `r(varlist)'
        *     local firstvar: word 1 of `varlist'
        *     local compvars: list memvars - firstvar
        *     if ( "`compvars'" != "" ) {
        *         cf `compvars' using `file_sort'
        *     }
        *     keep `firstvar'
        *     tempfile file_first
        *     qui save `file_first'
        *
        *     use `firstvar' using `file_sort', clear
        *     rename `firstvar' c_`firstvar'
        *     qui merge 1:1 _n using `file_first'
        *     cap noi assert (`firstvar' == c_`firstvar') | (abs(`firstvar' - c_`firstvar') < 1e-15)
        *     if ( _rc ) {
        *         local rc = _rc
        *         di as err "hashsort gave different sort order to sort"
        *     }
        *     else {
        *         if ("`benchmode'" == "") di as txt "    hashsort same as sort but sortpreserve trick caused some loss of precision (< 1e-15)"
        *     }
        * }

        * Make sure already sorted check is OK
        qui gen byte one = 1
        hashsort one `varlist', `options'
        qui drop one
        cf * using `file_sort'
        * if ( _rc ) {
        *     qui ds *
        *     local memvars `r(varlist)'
        *     local firstvar: word 1 of `varlist'
        *     local compvars: list memvars - firstvar
        *     if ( "`compvars'" != "" ) {
        *         cf `compvars' using `file_sort'
        *     }
        *     keep `firstvar'
        *     tempfile file_one
        *     qui save `file_one'
        *
        *     use `firstvar' using `file_sort', clear
        *     rename `firstvar' c_`firstvar'
        *     qui merge 1:1 _n using `file_one'
        *     cap noi assert (`firstvar' == c_`firstvar') | (abs(`firstvar' - c_`firstvar') < 1e-15)
        *     if ( _rc ) {
        *         local rc = _rc
        *         di as err "hashsort gave different sort order to sort"
        *     }
        *     else {
        *         if ("`benchmode'" == "") di as txt "    hashsort same as sort but sortpreserve trick caused some loss of precision (< 1e-15)"
        *     }
        * }
    restore
    qui timer list
    local time_hashsort = r(t43)

    if ( `rc' ) exit `rc'

    if ( "`fsort'" == "fsort" ) {
        timer clear
        preserve
            timer on 44
            cap fsort `varlist'
            local rc_f = _rc
            timer off 44
            if ( `rc_f' ) {
                disp as err "(warning: fsort `varlist' failed)"
            }
            else {
                cap noi cf * using `file_sort'
                if ( _rc ) {
                    disp as txt "(note: ftools `varlist' returned different data vs sort, stable)"
                }
            }
        restore
        if ( `rc_f' ) {
            local time_fsort = .
        }
        else {
            qui timer list
            local time_fsort = r(t44)
        }
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
    syntax anything, [benchmode mfirst mlast *]
    tempvar ix
    gen long `ix' = _n
    if ( "`benchmode'" == "" ) local gstable `ix'

    timer clear
    preserve
        timer on 42
        gsort `anything' `gstable', `mfirst'
        timer off 42
        tempfile file_sort
        qui save `file_sort'
    restore
    qui timer list
    local time_sort = r(t42)

    timer clear
    preserve
        timer on 43
        qui hashsort `anything', `mlast'  `options'
        timer off 43
        cf `:di subinstr("`anything'", "-", "", .)' using `file_sort'
    restore
    qui timer list
    local time_hashsort = r(t43)

    local rs = `time_sort'  / `time_hashsort'
    di "    `:di %5.3g `time_sort'' | `:di %8.3g `time_hashsort'' | `:di %11.3g `rs'' | `anything'"
end

* ---------------------------------------------------------------------
* Run the things

main, dependencies basic_checks comparisons switches bench_test
