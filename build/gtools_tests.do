* ----------------------------------------------------------------------------
* Project: gtools
* Program: gtools_tests.do
* Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
* Created: Tue May 16 07:23:02 EDT 2017
* Updated: Mon Dec 05 09:39:49 EST 2022
* Purpose: Unit tests for gtools
* Version: 1.11.8
* Manual:  help gtools
* Note:    You may need to run `ftools, compile` and `reghdfe, compile`
*          to test gtools against ftools functions and reghdfe.

* Stata start-up options
* ----------------------

version 13
clear all
set more off
set varabbrev off
set seed 42
set linesize 255
set type double
global GTOOLS_BETA = 1

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
    di "Stata v:      `c(stata_version)'"

    * Run the things
    * --------------

    cap noi {
        * qui do gtools_tests.do
        * qui do test_gcollapse.do
        * qui do test_gcontract.do
        * qui do test_gduplicates.do
        * qui do test_gegen.do
        * qui do test_gisid.do
        * qui do test_glevelsof.do
        * qui do test_gquantiles.do
        * qui do test_gquantiles_by.do
        * qui do test_gtoplevelsof.do
        * qui do test_gunique.do
        * qui do test_hashsort.do
        * qui do test_gstats.do
        * qui do test_greshape.do
        * qui do test_gregress.do

        * qui do docs/examples/gcollapse.do
        * qui do docs/examples/gcontract.do
        * qui do docs/examples/gdistinct.do
        * qui do docs/examples/gduplicates.do
        * qui do docs/examples/gquantiles.do
        * qui do docs/examples/gtoplevelsof.do
        * qui do docs/examples/gunique.do
        * qui do docs/examples/hashsort.do
        * qui do docs/examples/gegen.do,     nostop
        * qui do docs/examples/gisid.do,     nostop
        * qui do docs/examples/glevelsof.do, nostop
        * qui do docs/examples/gstats_summarize.do
        * qui do docs/examples/gstats_transform.do
        * qui do docs/examples/gstats_winsor.do
        * qui do docs/examples/gstats_hdfe.do
        * qui do docs/examples/greshape.do
        * qui do docs/examples/gregress.do
        * qui do docs/examples/givregress.do
        * qui do docs/examples/gglm.do

        if ( `:list posof "dependencies" in options' ) {
            cap ssc install hdfe,      replace
            cap ssc install ralpha,    replace
            cap ssc install ftools,    replace
            cap ssc install unique,    replace
            cap ssc install winsor2,   replace
            cap ssc install distinct,  replace
            cap ssc install moremata,  replace
            cap ssc install fastxtile, replace
            cap ssc install egenmisc,  replace
            cap ssc install egenmore,  replace
            cap ssc install rangestat, replace
            cap ssc install reghdfe,   replace
            * ftools,  compile
            * reghdfe, compile
        }

        if ( `:list posof "basic_checks" in options' ) {

            di ""
            di "-------------------------------------"
            di "Basic unit-tests $S_TIME $S_DATE"
            di "-------------------------------------"

            unit_test, `noisily' test(checks_gcontract,     `noisily' oncollision(error))
            unit_test, `noisily' test(checks_isid,          `noisily' oncollision(error))
            unit_test, `noisily' test(checks_duplicates,    `noisily' oncollision(error))
            unit_test, `noisily' test(checks_toplevelsof,   `noisily' oncollision(error))
            unit_test, `noisily' test(checks_levelsof,      `noisily' oncollision(error))
            unit_test, `noisily' test(checks_unique,        `noisily' oncollision(error))
            unit_test, `noisily' test(checks_hashsort,      `noisily' oncollision(error))
            unit_test, `noisily' test(checks_gregress,      `noisily' oncollision(error))
            unit_test, `noisily' test(checks_greshape,      `noisily' oncollision(error))
            unit_test, `noisily' test(checks_gstats,        `noisily' oncollision(error))

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
            compare_gstats,        `noisily' oncollision(error)
            compare_greshape,      `noisily' oncollision(error)
            * compare_gregress,      `noisily' oncollision(error)

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
            bench_gstats,        n(1000) bench(1)   `noisily' oncollision(error)
            bench_greshape,      n(1000) bench(1)   `noisily' oncollision(error)
            * bench_gregress,      n(1000) bench(1)   `noisily' oncollision(error)

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
            bench_gstats,        n(10000)   bench(10)   `noisily' oncollision(error)
            bench_greshape,      n(10000)   bench(10)   `noisily' oncollision(error)
            * bench_gregress,      n(10000)   bench(10)   `noisily' oncollision(error)

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
    gen double int2  = floor(rnormal())
    gen long   int3  = floor(rnormal() * 5 + 10)

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

capture program drop quickGini
program quickGini, sortpreserve
    syntax varname [if] [in] [aw fw pw iw], gen(name) [by(varname) keepneg dropneg]
    tempvar w ysum iysum wsum N
    local y: copy local varlist

    qui {
        if ( `"`dropneg'"' != "" ) {
            tempvar y
            gen double `y' = `varlist' if `varlist' >= 0
        }
        else if ( `"`dropneg'`keepneg'"' == "" ) {
            tempvar y
            gen double `y' = 0
            replace `y' = `varlist' if `varlist' >= 0
        }

        tempvar touse
        if ( `"`exp'"' != "" ) {
            gen double `w' `exp'
            mark `touse' `if' `in' [`weight'=`w']
            sort `touse' `by' `y'
            replace `w' = 0 if mi(`y')
            if ( `"`dropneg'"' != "" ) {
                replace `y' = 0 if mi(`y')
            }
            by `touse' `by': gen double `ysum'  = sum(`y' * `w') if `touse'
            by `touse' `by': gen double `wsum'  = sum(`w')       if `touse'
            by `touse' `by': gen double `iysum' = sum(`y' * `w' * (2 * `wsum' - `w')) if `touse'
            by `touse' `by': gen double `gen'  = ((`iysum'[_N]) / (`wsum'[_N] * `ysum'[_N])) - 1 if `touse'
        }
        else {
            mark `touse' `if' `in'
            sort `touse' `by' `y'
            gegen long `N' = count(`y') if `touse', by(`by')
            if ( `"`dropneg'"' != "" ) {
                replace `y' = 0 if mi(`y')
            }
            by `touse' `by': gen double `ysum'  = sum(`y')      if `touse'
            by `touse' `by': gen double `iysum' = sum(`y' * _n) if `touse'
            by `touse' `by': gen double `gen'  = ((2 * `iysum'[_N]) / (`N' * `ysum'[_N])) - ((`N' + 1) / `N') if `touse'
        }
    }
end

* ---------------------------------------------------------------------
capture program drop checks_gcollapse
program checks_gcollapse
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_gcollapse, `options'" _n(1) "{hline 80}" _n(1)
    local options `options' tol(`tol')

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

    **************************************
    *  Misc tests of new options in 1.4  *
    **************************************

    sysuse auto, clear

    local gcall
    local gcall `gcall' (mean)         mean         = price
    local gcall `gcall' (geomean)      geomean      = price
    local gcall `gcall' (gini)         gini         = price
    local gcall `gcall' (gini|dropneg) gini_dropneg = price
    local gcall `gcall' (gini|keepneg) gini_keepneg = price
    local gcall `gcall' (sd)           sd           = price
    local gcall `gcall' (variance)     variance     = price
    local gcall `gcall' (cv)           cv           = price
    local gcall `gcall' (min)          min          = price
    local gcall `gcall' (max)          max          = price
    local gcall `gcall' (range)        range        = price
    local gcall `gcall' (select1)      select1      = price
    local gcall `gcall' (select2)      select2      = price
    local gcall `gcall' (select3)      select3      = price
    local gcall `gcall' (select99)     select99     = price
    local gcall `gcall' (select-99)    select_99    = price
    local gcall `gcall' (select-3)     select_3     = price
    local gcall `gcall' (select-2)     select_2     = price
    local gcall `gcall' (select-1)     select_1     = price

    gcollapse `gcall', by(foreign) merge
    assert abs((sd / mean) - cv) < `tol'
    assert abs((sd^2 - variance) / min(sd^2, variance)) < `tol'
    assert abs((range) - (max - min)) < `tol'

    bys foreign (price): assert abs(price[1] - select1) < `tol'
    bys foreign (price): assert abs(price[2] - select2) < `tol'
    bys foreign (price): assert abs(price[3] - select3) < `tol'
    bys foreign (price): assert abs(price[_N - 2] - select_3) < `tol'
    bys foreign (price): assert abs(price[_N - 1] - select_2) < `tol'
    bys foreign (price): assert abs(price[_N - 0] - select_1) < `tol'

    assert mi(select99)
    assert mi(select_99)

    clear
    qui {
        set obs 10
        gen x = _n
        gen w = 1.5
        replace x = .  in 1/2
        replace x = .a in 3
        replace x = .b in 4
        replace x = .c in 5
        replace x = .d in 6
    }
    gsort -x

        local gcall
        local gcall `gcall' (min)   min   = x
        local gcall `gcall' (max)   max   = x
        local gcall `gcall' (range) range = x
    preserve
        gcollapse `gcall'
        assert min == 7
        assert max == 10
        assert range == 3
    restore, preserve
        gcollapse `gcall' if mi(x)
        assert min == .
        assert max == .d
        assert range == .
    restore, preserve
        gcollapse `gcall' if x > .
        assert min == .a
        assert max == .d
        assert range == .
    restore

        local gcall
        local gcall `gcall' (select1)   select1   = x
        local gcall `gcall' (select2)   select2   = x
        local gcall `gcall' (select3)   select3   = x
        local gcall `gcall' (select99)  select99  = x
        local gcall `gcall' (select-99) select_99 = x
        local gcall `gcall' (select-3)  select_3  = x
        local gcall `gcall' (select-2)  select_2  = x
        local gcall `gcall' (select-1)  select_1  = x
        local rawstat select1 select2 select3 select99 select_99 select_3 select_2 select_1
    preserve
        gcollapse `gcall'
        assert select1   == 7
        assert select2   == 8
        assert select3   == 9
        assert select99  == .
        assert select_99 == .
        assert select_3  == 8
        assert select_2  == 9
        assert select_1  == 10
    restore, preserve
        gcollapse `gcall' if mi(x)
        assert select1   == .
        assert select2   == .
        assert select3   == .a
        assert select99  == .
        assert select_99 == .
        assert select_3  == .b
        assert select_2  == .c
        assert select_1  == .d
    restore, preserve
        gcollapse `gcall' if x > .
        assert select1   == .a
        assert select2   == .b
        assert select3   == .c
        assert select99  == .
        assert select_99 == .
        assert select_3  == .b
        assert select_2  == .c
        assert select_1  == .d
    restore

    preserve
        gcollapse `gcall' [w = w], rawstat(`rawstat')
        assert select1   == 7
        assert select2   == 8
        assert select3   == 9
        assert select99  == .
        assert select_99 == .
        assert select_3  == 8
        assert select_2  == 9
        assert select_1  == 10
    restore, preserve
        gcollapse `gcall' if mi(x) [w = w], rawstat(`rawstat')
        assert select1   == .
        assert select2   == .
        assert select3   == .a
        assert select99  == .
        assert select_99 == .
        assert select_3  == .b
        assert select_2  == .c
        assert select_1  == .d
    restore, preserve
        gcollapse `gcall' if x > . [w = w], rawstat(`rawstat')
        assert select1   == .a
        assert select2   == .b
        assert select3   == .c
        assert select99  == .
        assert select_99 == .
        assert select_3  == .b
        assert select_2  == .c
        assert select_1  == .d
    restore

    preserve
        gcollapse `gcall' [w = w]
        assert select1   == 7
        assert select2   == 8
        assert select3   == 8
        assert select99  == .
        assert select_99 == .
        assert select_3  == 9
        assert select_2  == 9
        assert select_1  == 10
    restore, preserve
        gcollapse `gcall' if mi(x) [w = w]
        assert select1   == .
        assert select2   == .
        assert select3   == .
        assert select99  == .
        assert select_99 == .
        assert select_3  == .
        assert select_2  == .
        assert select_1  == .
    restore, preserve
        gcollapse `gcall' if x > . [w = w]
        assert select1   == .
        assert select2   == .
        assert select3   == .
        assert select99  == .
        assert select_99 == .
        assert select_3  == .
        assert select_2  == .
        assert select_1  == .
    restore

        local gcall
        local gcall `gcall' (select1)   select1   = x
        local gcall `gcall' (select2)   select2   = x
        local gcall `gcall' (select3)   select3   = x
        local gcall `gcall' (select99)  select99  = x
        local gcall `gcall' (select-99) select_99 = x
        local gcall `gcall' (select-3)  select_3  = x
        local gcall `gcall' (select-2)  select_2  = x
        local gcall `gcall' (select-1)  select_1  = x
        local gcall `gcall' (rawselect1)   rawselect1   = x
        local gcall `gcall' (rawselect2)   rawselect2   = x
        local gcall `gcall' (rawselect3)   rawselect3   = x
        local gcall `gcall' (rawselect99)  rawselect99  = x
        local gcall `gcall' (rawselect-99) rawselect_99 = x
        local gcall `gcall' (rawselect-3)  rawselect_3  = x
        local gcall `gcall' (rawselect-2)  rawselect_2  = x
        local gcall `gcall' (rawselect-1)  rawselect_1  = x
        local rawstat select1 select2 select3 select99 select_99 select_3 select_2 select_1
    preserve
        gcollapse `gcall' [w = w], rawstat(`rawstat')
        assert (select1   == 7)  & (select1   == rawselect1)
        assert (select2   == 8)  & (select2   == rawselect2)
        assert (select3   == 9)  & (select3   == rawselect3)
        assert (select99  == .)  & (select99  == rawselect99)
        assert (select_99 == .)  & (select_99 == rawselect_99)
        assert (select_3  == 8)  & (select_3  == rawselect_3)
        assert (select_2  == 9)  & (select_2  == rawselect_2)
        assert (select_1  == 10) & (select_1  == rawselect_1)
    restore, preserve
        gcollapse `gcall' if mi(x) [w = w], rawstat(`rawstat')
        assert (select1   == .)   & (select1   == rawselect1)
        assert (select2   == .)   & (select2   == rawselect2)
        assert (select3   == .a)  & (select3   == rawselect3)
        assert (select99  == .)   & (select99  == rawselect99)
        assert (select_99 == .)   & (select_99 == rawselect_99)
        assert (select_3  == .b)  & (select_3  == rawselect_3)
        assert (select_2  == .c)  & (select_2  == rawselect_2)
        assert (select_1  == .d)  & (select_1  == rawselect_1)
    restore, preserve
        gcollapse `gcall' if x > . [w = w], rawstat(`rawstat')
        assert (select1   == .a)  & (select1   == rawselect1)
        assert (select2   == .b)  & (select2   == rawselect2)
        assert (select3   == .c)  & (select3   == rawselect3)
        assert (select99  == .)   & (select99  == rawselect99)
        assert (select_99 == .)   & (select_99 == rawselect_99)
        assert (select_3  == .b)  & (select_3  == rawselect_3)
        assert (select_2  == .c)  & (select_2  == rawselect_2)
        assert (select_1  == .d)  & (select_1  == rawselect_1)
    restore

    **************************
    *  Undocumented options  *
    **************************

    clear
    set obs 100
    gen x = _n
    gen y = mod(_n, 13)
    gen z = mod(_n, 3)
    gegen dmx = mean(x), _subtract
    gegen dmy = mean(y), _subtract
    gegen  mx = mean(x)
    gegen  my = mean(y)
    assert abs(dmx - (x - mx)) < `tol'
    assert abs(dmy - (y - my)) < `tol'

    drop *m?
    gcollapse (mean) dmx = x dmy = y, merge _subtract
    gcollapse (mean)  mx = x  my = y, merge
    assert abs(dmx - (x - mx)) < `tol'
    assert abs(dmy - (y - my)) < `tol'

    drop *m?
    gegen dmx = mean(x), by(z) _subtract
    gegen dmy = mean(y), by(z) _subtract
    gegen  mx = mean(x), by(z)
    gegen  my = mean(y), by(z)
    assert abs(dmx - (x - mx)) < `tol'
    assert abs(dmy - (y - my)) < `tol'

    drop *m?
    gcollapse (mean) dmx = x dmy = y, by(z) merge _subtract
    gcollapse (mean)  mx = x  my = y, by(z) merge
    assert abs(dmx - (x - mx)) < `tol'
    assert abs(dmy - (y - my)) < `tol'

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

    clear
    set obs 10
    gen x = _n
    gen y = 1
    gcollapse (kurt) mx = x, merge
    cap gcollapse (kurt) mx = x, merge
    assert _rc == 110
    gcollapse mx = x, merge replace
    gcollapse mx = x, merge by(y) replace
    cap gcollapse y = x,  merge by(y)
    assert _rc == 110
    cap gcollapse y = x,  merge by(y) replace
    assert _rc == 110
    gcollapse y = x,  merge by(y) debug_replaceby
    cap gcollapse x = x,  merge by(y)
    assert _rc == 110
    gcollapse x = x,  merge by(y) replace
    cap gcollapse mx = x,  merge by(y)
    assert _rc == 110

    * Weird stuff happens when you try to use tempvar names without
    * calling tempvar. DON'T!

    * clear
    * set obs 10
    * gen x = _n
    * gen y = 1
    * gcollapse __000000 = x __000001 = x __000002 = x,         merge by(y)
    * gcollapse __000000 = x __000001 = x __000002 = x if 1,    merge by(y)
    * gcollapse __000000 = x __000001 = x __000002 = x [w = y], merge by(y)

    clear
    set obs 10
    gen byte x = _n
    replace x = . in 1/5
    gen y = mi(x)
    preserve
        gcollapse (nmissing) nm = x ///
                  (sum) s = x       ///
                  (rawsum) rs = x   ///
                  (nansum) ns = x   ///
                  (rawnansum) rns = x, by(y)
        l
        assert !mi(s) & !mi(rs)
        assert  mi(ns[2]) &  mi(rns[2])
        assert !mi(ns[1]) & !mi(rns[1])
        assert (nm[1] == 0) & (nm[2] == 5)
    restore, preserve
        gcollapse (nmissing) nm = x ///
                  (sum) s = x       ///
                  (rawsum) rs = x   ///
                  (nansum) ns = x   ///
                  (rawnansum) rns = x [fw = 9123], by(y)
        assert !mi(s) & !mi(rs)
        assert  mi(ns[2]) &  mi(rns[2])
        assert !mi(ns[1]) & !mi(rns[1])
        assert (nm[1] == 0) & (nm[2] == 5 * 9123)
    restore, preserve
        gcollapse (nmissing) nm = x ///
                  (sum) s = x       ///
                  (rawsum) rs = x   ///
                  (nansum) ns = x   ///
                  (rawnansum) rns = x [pw = 987654321], by(y)
        assert !mi(s) & !mi(rs)
        assert  mi(ns[2]) &  mi(rns[2])
        assert !mi(ns[1]) & !mi(rns[1])
        assert (nm[1] == 0) & (nm[2] == 5 * 987654321)
    restore, preserve
        gcollapse (nmissing) nm = x ///
                  (sum) s = x       ///
                  (rawsum) rs = x   ///
                  (nansum) ns = x   ///
                  (rawnansum) rns = x [aw = 2323.412], by(y)
        assert !mi(s) & !mi(rs)
        assert  mi(ns[2]) &  mi(rns[2])
        assert !mi(ns[1]) & !mi(rns[1])
        assert (nm[1] == 0) & (nm[2] == 5)
    restore
    gcollapse (nmissing) nm = x ///
              (sum) s = x       ///
              (rawsum) rs = x   ///
              (nansum) ns = x   ///
              (rawnansum) rns = x, by(y) missing
    assert s == ns
    assert rs == rns
    assert  mi(ns[2]) &  mi(rns[2])
    assert !mi(ns[1]) & !mi(rns[1])
    assert (nm[1] == 0) & (nm[2] == 5)

    exit 0
end

capture program drop checks_inner_collapse
program checks_inner_collapse
    syntax [anything], [tol(real 1e-6) wgt(str) *]

    local 0 `anything' `wgt', `options'
    syntax [anything] [aw fw iw pw], [*]

    local percentiles p1 p10 p30.5 p50 p70.5 p90 p99
    local selections  select1 select2 select5 select999999 select-999999 select-5 select-2 select-1
    local stats nunique nmissing sum mean geomean max min range count percent first last firstnm lastnm median iqr skew kurt gini gini|dropneg gini|keepneg
    if ( !inlist("`weight'", "pweight") )            local stats `stats' sd variance cv
    if ( !inlist("`weight'", "pweight", "iweight") ) local stats `stats' semean
    if (  inlist("`weight'", "fweight", "") )        local stats `stats' sebinomial sepoisson

    local collapse_str ""
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') r1_`:subinstr local stat "|" "_", all' = random1
    }
    foreach pct of local percentiles {
        local collapse_str `collapse_str' (`pct') r1_`:subinstr local pct "." "_", all' = random1
    }
    if ( !inlist("`weight'", "iweight") ) {
        foreach sel of local selections {
            local collapse_str `collapse_str' (`sel') s1_`:subinstr local sel "-" "_", all' = random1
        }
    }

    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') r2_`:subinstr local stat "|" "_", all' = random2
    }
    foreach pct of local percentiles {
        local collapse_str `collapse_str' (`pct') r2_`:subinstr local pct "." "_", all' = random2
    }
    if ( !inlist("`weight'", "iweight") ) {
        foreach sel of local selections {
            local collapse_str `collapse_str' (`sel') s2_`:subinstr local sel "-" "_", all' = random2
        }
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

    qui {
        mac drop GTOOLS_BETA
        cap gregress
        assert _rc == 198
        cap givregress
        assert _rc == 198
        cap gpoisson
        assert _rc == 198
        global GTOOLS_BETA = 1

        clear
        gregress
        givregress
        gpoisson
    }

    * Select used to not correctly select amonghts missing values
    qui {
        clear
        set obs 3
        gen value = .
        replace value = .a in 3
        replace value = .b in 2
        gen date = 1

        gstats range (select1 . . date)  x1 = value
        gstats range (select1)           x2 = value
        gstats range (select2)           x3 = value
        gstats range (select3)           x4 = value
        gstats range (select-1)          x5 = value
        gstats range (select-2 . . date) x6 = value

        assert x1 == .
        assert x2 == .
        assert x3 == .a
        assert x4 == .b
        assert x5 == .b
        assert x6 == .a

        drop x?
        gstats range (rawselect1 . . date)  x1 = value [fw = 1]
        gstats range (rawselect1)           x2 = value [fw = 1]
        gstats range (rawselect2)           x3 = value [fw = 1]
        gstats range (rawselect3)           x4 = value [fw = 1]
        gstats range (rawselect-1)          x5 = value [fw = 1]
        gstats range (rawselect-2 . . date) x6 = value [fw = 1]

        assert x1 == .
        assert x2 == .
        assert x3 == .a
        assert x4 == .b
        assert x5 == .b
        assert x6 == .a
    }

    * Negative or zero values for geomean
    qui {
        clear
        set obs 10
        gen g = mod(_n, 2)
        gen x = _n - 6
        gen w = cond(x < 0, 0, _n)
        preserve
            gcollapse (geomean) x, by(g)
            assert mi(x)
        restore, preserve
            gcollapse (geomean) x if x > 0, by(g)
            assert x != 0 & !mi(x)
        restore, preserve
            gcollapse (geomean) x if x >= 0, by(g)
            assert x[1] == 0 & !mi(x[2])
        restore, preserve
            gcollapse (geomean) x [aw = w], by(g)
            assert x[1] == 0 & !mi(x[2])
        restore, preserve
            gcollapse (geomean) x [fw = w], by(g)
            assert x[1] == 0 & !mi(x[2])
        restore
    }

    * Parsing by: in gegen
    qui {
        clear
        set obs 10
        gen var = mod(_n, 3)
        gen y   = _n
        gen u   = runiform()
        cap noi by var: gegen x = mean(max(y, y[1]))
        by var (u), sort: gegen x = mean(max(y, y[1]))
        sort y
        bys var (u): gegen z = mean(max(y, y[1]))
        bys var (u):  egen w = mean(max(y, y[1]))
        assert x == z
        assert x == w
    }

    * Parsing negatives
    qui {
        sysuse auto, clear
        gtop * if foreign [w = rep78]
        gtop -* if foreign [w = rep78]
        gen bye = 1
        gtop bye *n*
        gtop bye -*n*

        glevelsof *  if (27 * foreign)
        glevelsof -* if (27 * foreign)

        sysuse auto, clear
        gcontract * if foreign [w = rep78]

        sysuse auto, clear
        gcontract foreign -*n* price if price > 5000 [w = rep78]

        sysuse auto, clear
        gcollapse price if price > 5000 [w = rep78], by(*n*)

        sysuse auto, clear
        gcollapse price if price > 5000 [w = rep78], by(foreign -*n*)

        clear
        set obs 3
        gen  i = _n
        gen x1 = 1
        gen x2 = 2
        gen y3 = _n
        cap noi greshape long x y
        cap noi greshape wide x y
        cap noi greshape spread x y
        cap noi greshape spread x y
        greshape long x y, i(i) j(j)
        greshape wide x y, i(i) j(j)
        greshape long x y, by(i) j(j)
        greshape wide x y, by(i) j(j)
        greshape long x y, i(i) keys(j)
        greshape wide x y, i(i) keys(j)
        greshape long x y, by(i) keys(j)
        greshape wide x y, by(i) keys(j)
        greshape long x y, by(i) keys(j)
        gen k = _N - _n
        greshape wide x y, by(i) keys(j k)
        cap noi greshape
        greshape long x y, by(i) keys(j) string
        replace j = "" in 1 / 10
        cap noi greshape wide x y, by(i) keys(j) nomisscheck
        replace j = " " in 1 / 10
        cap noi greshape wide x y, by(i) keys(j) nomisscheck
        replace j = "" in 1 / 10
        gen j2 = j
        cap noi greshape wide x y, by(i) keys(j j2) nomisscheck
    }

    * https://github.com/mcaceresb/stata-gtools/issues/45
    qui {
        clear
        set obs 5
        gen long id1 = 0
        gen int id2  = 0
        replace id1 = 3 in 1
        replace id1 = 3 in 2
        replace id1 = 9 in 3
        replace id1 = 4 in 4
        replace id1 = 9 in 5
        replace id2 = 6 in 1
        replace id2 = 7 in 2
        replace id2 = 1 in 3
        replace id2 = 1 in 4
        replace id2 = 1 in 5
        gen id3 = _n
        tostring id1 id2, gen(sid1 sid2)
        cap noi gisid id1 id2, v
        assert _rc == 459
        cap noi gisid sid1 sid2, v
        assert _rc == 459

        sort id1 id2
        cap noi gisid id1 id2, v
        assert _rc == 459
        sort sid1 sid2
        cap noi gisid sid1 sid2, v
        assert _rc == 459

        gen sid3 = string(_n)
        cap noi gisid id1 id2 id3, v
        assert _rc == 0
        cap noi gisid sid1 sid2 sid3, v
        assert _rc == 0
    }

    * https://github.com/mcaceresb/stata-gtools/issues/44
    qui {
        * 1. byte, int, long upgraded to int, long, double
        * 2. byte, int, long preserved
        * 3. float always upgraded
        * 4. float, double never downgraded
        * 5. Overflow warning
        clear
        set obs 10
        gen byte    b1 = 1
        gen int     i1 = 2
        gen long    l1 = 3
        gen float   f1 = 3.14
        gen double  d1 = 3.141592
        gen byte    b2 = maxbyte()
        gen int     i2 = maxint()
        gen long    l2 = maxlong()
        gen float   f2 = maxfloat()
        gen double  d2 = maxdouble()

        preserve
            gcollapse (sum) *
            foreach var of varlist * {
                assert "`:type `var''" == "double"
            }
        restore, preserve
            gcollapse (sum) *, sumcheck
            foreach var of varlist f1 d1 l2 f2 d2 {
                assert "`:type `var''" == "double"
            }
            assert "`:type b1'" == "byte"
            assert "`:type i1'" == "int"
            assert "`:type l1'" == "long"
            assert "`:type b2'" == "int"
            assert "`:type i2'" == "long"
        restore, preserve
            gcollapse (mean) m_* = * (sum) * (max) mx_* = *, sumcheck wild
            foreach var of varlist f1 d1 l2 f2 d2 {
                assert "`:type `var''" == "double"
            }
            assert "`:type b1'" == "byte"
            assert "`:type i1'" == "int"
            assert "`:type l1'" == "long"
            assert "`:type b2'" == "int"
            assert "`:type i2'" == "long"
        restore, preserve
            gcollapse (sum) s_* = * (mean) m_* = * (max) mx_* = *, sumcheck wild
            foreach var of varlist s_f1 s_d1 s_l2 s_f2 s_d2 {
                assert "`:type `var''" == "double"
            }
            assert "`:type s_b1'" == "byte"
            assert "`:type s_i1'" == "int"
            assert "`:type s_l1'" == "long"
            assert "`:type s_b2'" == "int"
            assert "`:type s_i2'" == "long"
        restore, preserve
            gcollapse (sum) s_* = * (mean) * (max) mx_* = *, sumcheck wild
            foreach var of varlist s_f1 s_d1 s_l2 s_f2 s_d2 {
                assert "`:type `var''" == "double"
            }
            assert "`:type s_b1'" == "byte"
            assert "`:type s_i1'" == "byte"
            assert "`:type s_l1'" == "byte"
            assert "`:type s_b2'" == "int"
            assert "`:type s_i2'" == "long"
        restore, preserve
            gcollapse (sum) b1 [fw = i2], sumcheck
            assert "`:type b1'" == "long"
        restore, preserve
            gcollapse (sum) b1 [fw = d2], sumcheck
            assert "`:type b1'" == "double"
        restore, preserve
            gen n = _n
            gcollapse (sum) b1 [fw = d2], by(n) sumcheck
            assert "`:type b1'" == "double"
            assert b1 == maxdouble()
        restore
    }

    * e-mail issue #0
    qui {
        clear
        set more off
        set seed 1
        set obs 2
        g y = 1.23
        preserve
            gcollapse (count) cy = y (first) fy = y, freq(z)
            assert abs(fy - 1.23) < 1e-6
        restore, preserve
            gcollapse (count) y (first) fy = y, freq(z)
            assert abs(fy - 1.23) < 1e-6
        restore, preserve
            gcollapse (first) fy = y (count) y , freq(z)
            assert abs(fy - 1.23) < 1e-6
        restore, preserve
            gcollapse (first) fy = y (count) cy = y, freq(z)
            assert abs(fy - 1.23) < 1e-6
        restore
    }

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

    qui `noisily' gen_data, n(500)
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

    qui `noisily' gen_data, n(500)
    qui expand 50
    qui `noisily' random_draws, random(2) binary(5)

    di _n(1) "{hline 80}" _n(1) "consistency_gcollapse_select_etc, `options'" _n(1) "{hline 80}" _n(1)

    compare_inner_gcollapse_select -str_12,              `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_select str_12 -str_32,       `options' tol(`tol') sort
    compare_inner_gcollapse_select str_12 -str_32 str_4, `options' tol(`tol') shuffle

    compare_inner_gcollapse_select -double1,                 `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_select double1 -double2,         `options' tol(`tol') sort
    compare_inner_gcollapse_select double1 -double2 double3, `options' tol(`tol') shuffle

    compare_inner_gcollapse_select -int1,           `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_select int1 -int2,      `options' tol(`tol') sort
    compare_inner_gcollapse_select int1 -int2 int3, `options' tol(`tol') shuffle

    compare_inner_gcollapse_select int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options' tol(`tol') shuffle

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

    qui `noisily' gen_data, n(500)
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
    local stats nunique nmissing sum mean geomean max min range percent first last firstnm lastnm median iqr skew kurt gini gini|dropneg gini|keepneg
    if ( !inlist("`weight'", "pweight") ) {
        local stats   `stats'   sd variance cv
        local sestats `sestats' sd variance cv
    }
    if ( !inlist("`weight'", "pweight", "iweight") ) {
        local stats   `stats'   semean
        local sestats `sestats' semean
    }
    if (  inlist("`weight'", "fweight", "") ) {
        local stats   `stats'   sebinomial sepoisson
        local sestats `sestats' sebinomial sepoisson
    }

    if ( `"`anything'"' == "" ) {
        gen id = 1
    }
    else {
        gegen id = group(`anything'), missing nods
    }

    gegen double nmissing     = nmissing    (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double nunique      = nunique     (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double percent      = percent     (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double mean         = mean        (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double sum          = sum         (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double median       = median      (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double min          = min         (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double max          = max         (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double range        = range       (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double iqr          = iqr         (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double first        = first       (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double last         = last        (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double firstnm      = firstnm     (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double lastnm       = lastnm      (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double skew         = skew        (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double kurt         = kurt        (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double geomean      = geomean     (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double gini         = gini        (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double gini_keepneg = gini|keepneg(random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double gini_dropneg = gini|dropneg(random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double q10          = pctile      (random1) `ifin' `wgt_ge',  by(`anything') nods p(10.5)
    gegen double q30          = pctile      (random1) `ifin' `wgt_ge',  by(`anything') nods p(30)
    gegen double q70          = pctile      (random1) `ifin' `wgt_ge',  by(`anything') nods p(70)
    gegen double q90          = pctile      (random1) `ifin' `wgt_ge',  by(`anything') nods p(90.5)
    if ( !inlist("`weight'", "iweight") ) {
    gegen double s1           = select      (random1) `ifin' `wgt_ge',  by(`anything') nods n(1)
    gegen double s3           = select      (random1) `ifin' `wgt_ge',  by(`anything') nods n(3)
    gegen double s999999      = select      (random1) `ifin' `wgt_ge',  by(`anything') nods n(999999)
    gegen double s_999999     = select      (random1) `ifin' `wgt_ge',  by(`anything') nods n(-999999)
    gegen double s_3          = select      (random1) `ifin' `wgt_ge',  by(`anything') nods n(-3)
    gegen double s_1          = select      (random1) `ifin' `wgt_ge',  by(`anything') nods n(-1)
    }

    local gextra
    foreach extra of local sestats {
        gegen double `extra' = `extra'(random1) `ifin' `wgt_ge',  by(`anything') nods
        local gextra `gextra' (`extra') g_`extra' = random1
    }

    if ( inlist("`weight'", "iweight") ) {
        qui `noisily' {
            gcollapse (nmissing)      g_nmissing     = random1 ///
                      (nunique)       g_nunique      = random1 ///
                      (percent)       g_percent      = random1 ///
                      (mean)          g_mean         = random1 ///
                      (sum)           g_sum          = random1 ///
                      (median)        g_median       = random1 ///
                      (min)           g_min          = random1 ///
                      (max)           g_max          = random1 ///
                      (range)         g_range        = random1 ///
                      (iqr)           g_iqr          = random1 ///
                      (first)         g_first        = random1 ///
                      (last)          g_last         = random1 ///
                      (firstnm)       g_firstnm      = random1 ///
                      (lastnm)        g_lastnm       = random1 ///
                      (skew)          g_skew         = random1 ///
                      (kurt)          g_kurt         = random1 ///
                      (geomean)       g_geomean      = random1 ///
                      (gini)          g_gini         = random1 ///
                      (gini|dropneg)  g_gini_dropneg = random1 ///
                      (gini|keepneg)  g_gini_keepneg = random1 ///
                      (p10.5)         g_q10          = random1 ///
                      (p30)           g_q30          = random1 ///
                      (p70)           g_q70          = random1 ///
                      (p90.5)         g_q90          = random1 ///
                      `gextra'                               ///
                  `ifin' `wgt_gc', by(id) benchmark verbose `options' merge double
         }
    else {
        qui `noisily' {
            gcollapse (nmissing)      g_nmissing     = random1 ///
                      (nunique)       g_nunique      = random1 ///
                      (percent)       g_percent      = random1 ///
                      (mean)          g_mean         = random1 ///
                      (sum)           g_sum          = random1 ///
                      (median)        g_median       = random1 ///
                      (min)           g_min          = random1 ///
                      (max)           g_max          = random1 ///
                      (range)         g_range        = random1 ///
                      (iqr)           g_iqr          = random1 ///
                      (first)         g_first        = random1 ///
                      (last)          g_last         = random1 ///
                      (firstnm)       g_firstnm      = random1 ///
                      (lastnm)        g_lastnm       = random1 ///
                      (skew)          g_skew         = random1 ///
                      (kurt)          g_kurt         = random1 ///
                      (geomean)       g_geomean      = random1 ///
                      (gini)          g_gini         = random1 ///
                      (gini|dropneg)  g_gini_dropneg = random1 ///
                      (gini|keepneg)  g_gini_keepneg = random1 ///
                      (p10.5)         g_q10          = random1 ///
                      (p30)           g_q30          = random1 ///
                      (p70)           g_q70          = random1 ///
                      (p90.5)         g_q90          = random1 ///
                      (select1)       g_s1           = random1 ///
                      (select3)       g_s3           = random1 ///
                      (select999999)  g_s999999      = random1 ///
                      (select-999999) g_s_999999     = random1 ///
                      (select-3)      g_s_3          = random1 ///
                      (select-1)      g_s_1          = random1 ///
                      `gextra'                               ///
                  `ifin' `wgt_gc', by(id) benchmark verbose `options' merge double
        }
    }

    if ( "`ifin'" == "" ) {
        di _n(1) "Checking full range`wtxt': `anything'"
    }
    else if ( "`ifin'" != "" ) {
        di _n(1) "Checking [`ifin']`wtxt' range: `anything'"
    }

    foreach _fun in `stats' q10 q30 q70 q90 {
        local fun: subinstr local _fun "|" "_", all
        cap noi assert (g_`fun' == `fun') | ((abs(g_`fun' - `fun') / min(abs(g_`fun'), abs(`fun'))) < `tol')
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
                    * save /tmp/xx, replace
                    exit _rc
                }
                else di as txt "    compare_gegen_gcollapse (imprecision): `fun'`wtxt' yielded similar results (tol = `tol')"
            }
            else {
                recast double g_`fun' `fun'
                cap noi assert (g_`fun' == `fun') | ((abs(g_`fun' - `fun') / min(abs(g_`fun'), abs(`fun'))) < `tol')
                if ( _rc ) {
                    di as err "    compare_gegen_gcollapse (failed): `fun'`wtxt' yielded different results (tol = `tol')"
                    * save /tmp/xx, replace
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

    if ( `"`anything'"' == "" ) {
        qui gen id = 1 `ifin'
    }
    else {
        qui gegen id = group(`anything') `ifin', missing nods
    }

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

    qui gcollapse (skew) skew  = random1 ///
                  (kurt) kurt  = random1 ///
                  (nunique) nq = random1 ///
        `ifin' `wgt_gc', by(id) benchmark verbose `options' double freq(f)

    if ( "`ifin'" == "" ) {
        di _n(1) "Checking full range`wtxt': `anything'"
    }
    else if ( "`ifin'" != "" ) {
        di _n(1) "Checking [`ifin']`wtxt' range: `anything'"
    }

    * For skewness and kurtosis, numerical imprecision can cause the
    * result to be -1 or 1 when it should really be missing. Internally
    * 0 / 0 is computed as ε / ε for some ε small.

    tempvar ix
    gen `ix' = _n
    foreach fun in kurt skew {
        local imprecise 0
        foreach j in `checks' {
            local ok 1
            if ( `j' != `=id[`j']' ) {
                qui sum `ix' if id == `j'
                if ( `r(N)' == 0 ) {
                    cap assert ``fun'_`j'' == . | "``fun'_`j''" == ""
                    if ( _rc ) {
                        di as txt "    compare_`fun'_gcollapse (failed): sum`wtxt' yielded a result and gcollapse did not"
                        exit _rc
                    }
                    local ok 0
                }
                local jj = `ix'[r(min)]
            }
            else local jj `j'

            if ( `ok' ) {
                cap assert ``fun'_`j'' == `fun'[`jj'] | abs(``fun'_`j'' - `fun'[`jj']) < `tol'
                if ( _rc & (nq[`j'] > 1) ) {
                    cap noi assert 0
                    di as err "    compare_`fun'_gcollapse (failed): sum`wtxt' yielded different results (tol = `tol')"
                    disp "``fun'_`j'' vs `=`fun'[`j']'; diff `=abs(``fun'_`j'' - `fun'[`j'])', N = `=f[`j']'"
                    exit _rc
                }
                else if ( _rc & (nq[`j'] == 1) ) {
                    local ++imprecise
                }
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
*                      Check new stats from 1.4                       *
***********************************************************************

capture program drop compare_inner_gcollapse_select
program compare_inner_gcollapse_select
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
        local wgen_i  `wgen_f'
        local wcall_i `wcall_f'
    }
    else {
        local wgt wgt(`wgt')
    }

    tempvar rsort
    if ( "`shuffle'" != "" ) gen `rsort' = runiform()
    if ( "`shuffle'" != "" ) sort `rsort'
    if ( ("`sort'"   != "") & ("`anything'" != "") ) qui hashsort `anything'

    local N = trim("`: di %15.0gc _N'")
    local hlen = 47 + length("`anything'") + length("`N'")
    di _n(2) "Checking select and 1.4+ funcs. N = `N'; varlist = `anything'" _n(1) "{hline `hlen'}"

    preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_a'
            local wgt wgt(both `wcall_a')
        }
        _compare_inner_gcollapse_select `anything', `options' tol(`tol') `wgt'
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
        _compare_inner_gcollapse_select  `anything' in `from' / `to', `options' `wgt' tol(`tol')
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_i'
            local wgt wgt(both `wcall_i')
        }
        _compare_inner_gcollapse_select `anything' if random2 > 0, `options' `wgt' tol(`tol')
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_p'
            local wgt wgt(both `wcall_p')
        }
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_gcollapse_select `anything' if random2 < 0 in `from' / `to', `options' `wgt' tol(`tol')
    restore
end

capture program drop _compare_inner_gcollapse_select
program _compare_inner_gcollapse_select
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

    local gcall
    local gcall `gcall' (count)        nj           = random1
    local gcall `gcall' (mean)         mean         = random1
    local gcall `gcall' (geomean)      geomean      = random1
    local gcall `gcall' (gini)         gini         = random1
    local gcall `gcall' (gini|dropneg) gini_dropneg = random1
    local gcall `gcall' (gini|keepneg) gini_keepneg = random1
    if !regexm("pw", `"`wgt'"') {
    local gcall `gcall' (sd)           sd           = random1
    local gcall `gcall' (variance)     variance     = random1
    local gcall `gcall' (cv)           cv           = random1
    }
    local gcall `gcall' (min)          min          = random1
    local gcall `gcall' (max)          max          = random1
    local gcall `gcall' (range)        range        = random1
    local gcall `gcall' (select1)      select1      = random1
    local gcall `gcall' (select2)      select2      = random1
    local gcall `gcall' (select3)      select3      = random1
    local gcall `gcall' (select9999)   select9999   = random1
    local gcall `gcall' (select-9999)  select_9999  = random1
    local gcall `gcall' (select-3)     select_3     = random1
    local gcall `gcall' (select-2)     select_2     = random1
    local gcall `gcall' (select-1)     select_1     = random1

    qui gcollapse `gcall' `ifin' `wgt_gc', by(`anything') `options' double merge replace
    if ( `"`anything'"' == "" ) {
        qui gen id = 1 `ifin'
    }
    else {
        qui gegen id = group(`anything') `ifin', missing nods
    }
    * save /tmp/aa, replace

    qui quickGini random1 `ifin' `wgt_gc', by(id) gen(_gini)
    qui quickGini random1 `ifin' `wgt_gc', by(id) gen(_gini_dropneg) dropneg
    qui quickGini random1 `ifin' `wgt_gc', by(id) gen(_gini_keepneg) keepneg
    foreach gini in " " _keepneg _dropneg {
        local gini `gini'
        cap assert reldif(_gini`gini', gini`gini') < `tol'
        local rc = _rc
        local gini: subinstr local gini "_" "|", all
        if ( `rc' ) {
            di as txt "    compare_gini`gini'_gcollapse (fail): gini`gini' yielded different results (tol = `tol')"
            exit 198
        }
        else {
            di as txt "    compare_gini`gini'_gcollapse (passed): gini`gini' yielded consistent results (tol = `tol')"
        }
    }

    if ( "`ifin'" == "" ) {
        di _n(1) "Checking full range`wtxt': `anything'"
    }
    else if ( "`ifin'" != "" ) {
        di _n(1) "Checking [`ifin']`wtxt' range: `anything'"
    }

    if !regexm("pw", `"`wgt'"') {
    cap assert (mi(cv) & (mi(sd) | (mean == 0))) | (abs((sd / mean) - cv) < `tol') `ifin'
        if ( _rc ) {
            di as txt "    compare_cv_gcollapse (fail): cv`wtxt' yielded different results (tol = `tol')"
            exit 198
        }
        else {
            di as txt "    compare_cv_gcollapse (passed): cv`wtxt' yielded consistent results (tol = `tol')"
        }
    }
    else {
            di as txt "    compare_cv_gcollapse (skip): cv`wtxt' skipped (not allowed with pweights)"
    }
    if !regexm("pw", `"`wgt'"') {
    cap assert (mi(variance) & mi(sd)) | (abs((sd^2 - variance) / min(sd^2, variance)) < `tol') `ifin'
        if ( _rc ) {
            di as txt "    compare_var_gcollapse (fail): var`wtxt' yielded different results (tol = `tol')"
            exit 198
        }
        else {
            di as txt "    compare_var_gcollapse (passed): var`wtxt' yielded consistent results (tol = `tol')"
        }
    }
    else {
            di as txt "    compare_var_gcollapse (skip): var`wtxt' skipped (not allowed with pweights)"
    }
    cap assert (mi(range) & (mi(min) | mi(max))) | (abs((range) - (max - min)) < `tol') `ifin'
        if ( _rc ) {
            di as txt "    compare_range_gcollapse (fail): range`wtxt' yielded different results (tol = `tol')"
            exit 198
        }
        else {
            di as txt "    compare_range_gcollapse (passed): range`wtxt' yielded consistent results (tol = `tol')"
        }

    if ( "`wgt'" != "" ) {
        qui {
            local 0 `wgt'
            syntax [aw fw iw pw]
            tempvar w wsum touse wsel
            mark `touse' `wgt' `ifin'
            markout `touse' random1
            keep if `touse'
            gen double `w' `exp'
            sort id random1 `w'
            by id (random1 `w'): gen double `wsum'  = sum(`w')
            gen long `wsel' = 0
        }
        foreach sel in 1 2 3 9999 {
            qui by id (random1 `w'): replace `wsel' = sum(`sel' > `wsum')
            cap by id (random1 `w'): assert (((abs(random1[`wsel'[_N] + 1] - select`sel') < `tol') | (mi(select`sel') & mi(random1[`wsel'[_N] + 1]))))
                if ( _rc ) {
                    di as txt "    compare_select`sel'_gcollapse (fail): select`wtxt' yielded different results (tol = `tol')"
                    exit 198
                }
                else {
                    di as txt "    compare_select`sel'_gcollapse (passed): select`wtxt' yielded consistent results (tol = `tol')"
                }
            qui by id (random1 `w'): replace `wsel' = cond(`wsum'[_N] - `sel' >= 0, sum((`wsum'[_N] - `sel') >= `wsum'), _N)
            cap by id (random1 `w'): assert (((abs(random1[`wsel'[_N] + 1] - select_`sel') < `tol') | (mi(select_`sel') & mi(random1[`wsel'[_N] + 1]))))
                if ( _rc ) {
                    di as txt "    compare_select-`sel'_gcollapse (fail): select`wtxt' yielded different results (tol = `tol')"
                    exit 198
                }
                else {
                    di as txt "    compare_select-`sel'_gcollapse (passed): select`wtxt' yielded consistent results (tol = `tol')"
                }
        }
    }
    else {
        if ( `"`ifin'"' != "" ) qui keep `ifin'
        sort id random1
        foreach sel in 1 2 3 9999 {
            cap by id (random1): assert (((abs(random1[`sel'] - select`sel') < `tol') | (mi(select`sel') & mi(random1[`sel']))))
                if ( _rc ) {
                    di as txt "    compare_select`sel'_gcollapse (fail): select`wtxt' yielded different results (tol = `tol')"
                    exit 198
                }
                else {
                    di as txt "    compare_select`sel'_gcollapse (passed): select`wtxt' yielded consistent results (tol = `tol')"
                }
            cap by id (random1): assert (((abs(random1[nj - `sel' + 1] - select_`sel') < `tol') | (mi(select_`sel') & mi(random1[nj - `sel' + 1]))))
                if ( _rc ) {
                    di as txt "    compare_select-`sel'_gcollapse (fail): select`wtxt' yielded different results (tol = `tol')"
                    exit 198
                }
                else {
                    di as txt "    compare_select-`sel'_gcollapse (passed): select`wtxt' yielded consistent results (tol = `tol')"
                }
        }
    }
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_collapse
program bench_collapse
    syntax, [tol(real 1e-6) bench(real 1) n(int 500) NOIsily style(str) vars(int 1) collapse fcollapse *]

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

    exit 0
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

    qui `noisily' gen_data, n(500)
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
    syntax, [tol(real 1e-6) bench(real 1) n(int 500) NOIsily *]

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

    gegen ggx0 = xtile(x)
    gegen ggx1 = xtile(log(x) + 1) if mod(_n, 10) in 20 / 80
    gegen ggx2 = xtile(x) [w = w],  nq(7) method(1)
    gegen ggx3 = xtile(x) [aw = w], nq(7) method(2)
    gegen ggx4 = xtile(x) [pw = w], nq(7) method(0)

    assert ggx0 == gx0
    assert ggx1 == gx1
    assert ggx2 == gx2
    assert ggx2 == gx2
    assert ggx4 == gx4

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
    gquantiles cp = x, nq(10) xtile

    fasterxtile gx0 = x , c(cp)
    fasterxtile gx1 = log(x) + 1 if mod(_n , 10) in 20 / 80, c(cp)

    fasterxtile gx2 = x [w = w]      if mod(_n , 10) in 20 / 80 , by(a b) c(cp) method(1)
    fasterxtile gx3 = x [aw = w]     if mod(_n , 10) in 20 / 80 , by(a b) c(cp) method(2)
    fasterxtile gx4 = x [pw = w]     if mod(_n , 10) in 20 / 80 , by(a b) c(cp) method(0)
    cap fasterxtile gx5 = x [fw = w] if mod(_n , 10) in 20 / 80 , by(b a) c(cp)
    assert _rc == 401
    fasterxtile gx5 = x [fw = int(w)], nq(108) by(-a b)

    drop gx*

    fasterxtile gx0 = x in 1
    cap fasterxtile gx1 = log(x) + 1 if mod(_n, 10) in 20 / 80, strict nq(100)
    assert _rc == 198
    fasterxtile gx2 = log(x) + 1 if mod(_n, 10) in 20 / 80, by(a) strict nq(100)
    assert gx2 == .

    exit 0
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

    compare_gquantiles_stata, n(5000) bench(10) `altdef' `options' wgt(`wcall_a') wgen(`wgen_a')

    local N = trim("`: di %15.0gc _N'")
    di _n(1) "{hline 80}" _n(1) "consistency_gquantiles_pctile_xtile, N = `N', `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(5000) skipstr
    qui expand 10
    qui `noisily' random_draws, random(2) double
    gen long   ix = _n
    gen double ru = runiform() * 100
    qui replace ix = . if mod(_n, 5000) == 0
    qui replace ru = . if mod(_n, 5000) == 0
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
    syntax, [bench(int 10) n(int 5000) *]
    compare_inner_quantiles, n(`n') bench(`bench') benchmode qopts(p(0.1 5 10 30 50 70 90 95 99.9))  qwhich(_pctile)
    compare_inner_quantiles, n(`n') bench(`bench') benchmode qopts(nq(10))  qwhich(_pctile)
    compare_inner_quantiles, n(`n') bench(`bench') benchmode qopts(nq(10))  qwhich(xtile)
    compare_inner_quantiles, n(`n') bench(`bench') benchmode qopts(nq(10))  qwhich(pctile)
end

capture program drop compare_gquantiles_stata
program compare_gquantiles_stata
    syntax, [bench(int 10) n(int 5000) noaltdef *]

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
    syntax, [bench(int 5) n(real 50000) benchmode wgen(str) *]
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
    _compare_inner_`qwhich' double1 `if' `in', `options' note("~ U(0,  500), no missings, groups of size 10")
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
    _compare_inner_`qwhich' double1 `if' `in', `options' note("~ U(0,  500), no missings, groups of size 10")
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
    _gquantiles_switch_nq   50000  2 `ver'
    _gquantiles_switch_nq   50000  5 `ver'
    _gquantiles_switch_nq   50000 10 `ver'
    _gquantiles_switch_nq   50000 20 `ver'
    _gquantiles_switch_nq   50000 30 `ver'
    _gquantiles_switch_nq   50000 40 `ver'
    di as txt "| ------------ | ---- | ------------- | --------------- | ---------------------- |"
    _gquantiles_switch_nq  500000  2 `ver'
    _gquantiles_switch_nq  500000  5 `ver'
    _gquantiles_switch_nq  500000 10 `ver'
    _gquantiles_switch_nq  500000 20 `ver'
    _gquantiles_switch_nq  500000 30 `ver'
    _gquantiles_switch_nq  500000 40 `ver'
    di as txt "| ------------ | ---- | ------------- | --------------- | ---------------------- |"
    _gquantiles_switch_nq 5000000  2 `ver'
    _gquantiles_switch_nq 5000000  5 `ver'
    _gquantiles_switch_nq 5000000 10 `ver'
    _gquantiles_switch_nq 5000000 20 `ver'
    _gquantiles_switch_nq 5000000 30 `ver'
    _gquantiles_switch_nq 5000000 40 `ver'

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
    _gquantiles_switch_cutoffs   50000    2 `ver'
    _gquantiles_switch_cutoffs   50000   50 `ver'
    _gquantiles_switch_cutoffs   50000  100 `ver'
    _gquantiles_switch_cutoffs   50000  200 `ver'
    _gquantiles_switch_cutoffs   50000  500 `ver'
    _gquantiles_switch_cutoffs   50000 1000 `ver'
    di as txt "| ------------ | ------- | ------------- | --------------- | ---------------------- |"
    _gquantiles_switch_cutoffs  500000    2 `ver'
    _gquantiles_switch_cutoffs  500000   50 `ver'
    _gquantiles_switch_cutoffs  500000  100 `ver'
    _gquantiles_switch_cutoffs  500000  200 `ver'
    _gquantiles_switch_cutoffs  500000  500 `ver'
    _gquantiles_switch_cutoffs  500000 1000 `ver'
    di as txt "| ------------ | ------- | ------------- | --------------- | ---------------------- |"
    _gquantiles_switch_cutoffs 5000000    2 `ver'
    _gquantiles_switch_cutoffs 5000000   50 `ver'
    _gquantiles_switch_cutoffs 5000000  100 `ver'
    _gquantiles_switch_cutoffs 5000000  200 `ver'
    _gquantiles_switch_cutoffs 5000000  500 `ver'
    _gquantiles_switch_cutoffs 5000000 1000 `ver'
end

capture program drop _gquantiles_switch_cutoffs
program _gquantiles_switch_cutoffs
    args n nq ver

    qui {
        clear
        if ( "`ver'" == "v1" ) {
            set obs `=`n' / 5000'
            gen x = rnormal() * 100
            expand 5000
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
            set obs `=`n' / 5000'
            gen x = rnormal() * 100
            expand 5000
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

    qui `noisily' gen_data, n(500)
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

    if ( `c(stata_version)' >= 14.1 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        _checks_gquantiles_by -strL1,             `options' `forcestrl'
        _checks_gquantiles_by strL1 -strL2,       `options' `forcestrl'
        _checks_gquantiles_by strL1 strL2  strL3, `options' `forcestrl'
    }

    exit 0
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

    compare_gquantiles_stata_by, n(5000) bench(10) `altdef' `options' wgt(`wcall_stata') wgen(`wgen_stata')

    local N = trim("`: di %15.0gc _N'")
    di _n(1) "{hline 80}" _n(1) "consistency_gquantiles_pctile_xtile_by, N = `N', `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(5000)
    qui expand 10
    qui `noisily' random_draws, random(3) double
    gen long   ix = _n
    gen double ru = runiform() * 100
    qui replace ix = . if mod(_n, 5000) == 0
    qui replace ru = . if mod(_n, 5000) == 0
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
    if ( `c(stata_version)' >= 14.1 ) {
        _consistency_inner_full_by -strL1        `if' `in', `options' var(`anything') `forcestrl'
        _consistency_inner_full_by strL1 -strL2  `if' `in', `options' var(`anything') `forcestrl'
    }

    _consistency_inner_full_by str_12 -str_4 double2 -double3 `if' `in', `options' var(`anything')
    if ( `c(stata_version)' >= 14.1 ) {
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
    syntax, [bench(int 10) n(int 5000) *]
    compare_inner_quantiles_by, n(`n') bench(`bench') benchmode qopts(nq(10))
    compare_inner_quantiles_by, n(`n') bench(`bench') benchmode nlist(2(2)20)
    compare_inner_quantiles_by, n(`n') bench(`bench') benchmode nqlist(2(2)20)
end

capture program drop compare_gquantiles_stata_by
program compare_gquantiles_stata_by
    syntax, [bench(int 10) n(int 5000) noaltdef *]

    if ( "`altdef'" != "noaltdef" ) {
    compare_inner_quantiles_by, n(`n') bench(`bench') qopts(altdef nq(10)) `options'
    compare_inner_quantiles_by, n(`n') bench(`bench') qopts(altdef nq(2))  `options'
    }

    compare_inner_quantiles_by, n(`n') bench(`bench') qopts(nq(10)) `options'
    compare_inner_quantiles_by, n(`n') bench(`bench') qopts(nq(2))  `options'
end

capture program drop compare_inner_quantiles_by
program compare_inner_quantiles_by
    syntax, [bench(int 100) n(real 500) benchmode wgen(str) *]
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
        if ( `c(stata_version)' >= 14.1 ) {
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

    if ( `c(stata_version)' >= 14.1 ) {
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
    if ( `c(stata_version)' < 14.1 ) {
        assert _rc == 17002
    }
    else {
        assert _rc == 17005
    }

    clear
    cap gegen
    assert _rc == 100
    cap gegen x = group(y)
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

    gegen z = count(z) if x == 8, by(z) replace
    assert z[8] == 1
    assert mi(z) | _n == 8
    gegen z = group(z) in 8 / 9, replace missing
    assert z == (x - 7) | mi(z)
    gegen z = tag(z) in 7 / 10, replace missing
    assert z[7] == 1
    assert z[8] == 1
    assert z[9] == 1
    assert (z == 0) | z == 1
    gegen z = sum(z) in 2 / 9, replace
    assert z == 3 | inlist(_n, 1, 10)
    gegen z = sum(x* z*) in 2 / 9, replace
    assert z == `=4 * (2 + 9) + 8 * 3' | inlist(_n, 1, 10)
    gegen z = sum(x* z*) if 0, replace
    assert z == .
    gegen z = sum(x* z*) if 1, replace
    assert z != .
    cap gegen z = sum(x* z*) if 1
    assert _rc == 110

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

    clear
    set obs 10
    gen byte x = _n
    replace x = . in 1/5
    gen y = mi(x)
    gegen s = nansum(x)    , by(y)
    gegen ns = sum(x)      , by(y)
    gegen nm = nmissing(x) , by(y)
    gegen f_s = nansum(x)    [fw = 1314], by(y)
    gegen f_ns = sum(x)      [fw = 1314], by(y)
    gegen f_nm = nmissing(x) [fw = 1314], by(y)
    gegen a_s = nansum(x)    [aw = 13.14], by(y)
    gegen a_ns = sum(x)      [aw = 13.14], by(y)
    gegen a_nm = nmissing(x) [aw = 13.14], by(y)
    gegen p_s = nansum(x)    [pw = 987654321], by(y)
    gegen p_ns = sum(x)      [pw = 987654321], by(y)
    gegen p_nm = nmissing(x) [pw = 987654321], by(y)
    assert cond(mi(x), mi(s) & mi(f_s) & mi(a_s), !mi(s) & !mi(f_s) & !mi(a_s))
    assert cond(mi(x), (nm == 5) & (a_nm == 5) & (f_nm == 5 * 1314) & (p_nm == 5 * 987654321), (nm == 0) & (a_nm == 0) & (f_nm == 0) & (p_nm == 0))

    * rank
    * ----

    clear
    set obs 10000
    gen x = ceil(runiform() * 10)
    gen g = round(_n / 100)

     egen double rankx_def1 = rank(x)
    gegen double rankx_def2 = rank(x)

     egen rankx_track1 = rank(x), track
    gegen rankx_track2 = rank(x), ties(track)

     egen rankx_field1 = rank(x), field
    gegen rankx_field2 = rank(x), ties(field)

     egen long rankx_uniq1 = rank(x), uniq
    gegen long rankx_uniq2 = rank(x), ties(uniq)

    gegen rankx_uniq3 = rank(x), ties(stable)

     egen double rankx_group_def1 = rank(x), by(g)
    gegen double rankx_group_def2 = rank(x), by(g)

     egen rankx_group_track1 = rank(x), by(g) track
    gegen rankx_group_track2 = rank(x), by(g) ties(track)

     egen rankx_group_field1 = rank(x), by(g) field
    gegen rankx_group_field2 = rank(x), by(g) ties(field)

     egen long rankx_group_uniq1 = rank(x), by(g) uniq
    gegen long rankx_group_uniq2 = rank(x), by(g) ties(uniq)

    gegen rankx_group_uniq3 = rank(x), by(g) ties(stable)

    assert (rankx_def1   == rankx_def2)
    assert (rankx_track1 == rankx_track2)
    assert (rankx_field1 == rankx_field2)

    sort x, stable
    assert rankx_uniq3 == _n

    gisid rankx_uniq1
    gisid rankx_uniq2

    assert (rankx_group_def1   == rankx_group_def2)
    assert (rankx_group_track1 == rankx_group_track2)
    assert (rankx_group_field1 == rankx_group_field2)

    cap drop ix
    sort g x, stable
    by g: gen ix = _n
    assert rankx_group_uniq3 == ix

    gisid g rankx_group_uniq1
    gisid g rankx_group_uniq2

    gegen double rankx_def2 = rank(x) [fw = 1], replace
    gegen rankx_track2      = rank(x) [fw = 1], replace ties(track)
    gegen rankx_field2      = rank(x) [fw = 1], replace ties(field)
    gegen long rankx_uniq2  = rank(x) [fw = 1], replace ties(uniq)
    gegen rankx_uniq3       = rank(x) [fw = 1], replace ties(stable)

    gegen double rankx_group_def2 = rank(x) [fw = 1], replace by(g)
    gegen rankx_group_track2      = rank(x) [fw = 1], replace by(g) ties(track)
    gegen rankx_group_field2      = rank(x) [fw = 1], replace by(g) ties(field)
    gegen long rankx_group_uniq2  = rank(x) [fw = 1], replace by(g) ties(uniq)
    gegen rankx_group_uniq3       = rank(x) [fw = 1], replace by(g) ties(stable)

    assert (rankx_def1   == rankx_def2)
    assert (rankx_track1 == rankx_track2)
    assert (rankx_field1 == rankx_field2)

    sort x, stable
    assert rankx_uniq3 == _n

    gisid rankx_uniq1
    gisid rankx_uniq2

    assert (rankx_group_def1   == rankx_group_def2)
    assert (rankx_group_track1 == rankx_group_track2)
    assert (rankx_group_field1 == rankx_group_field2)

    cap drop ix
    sort g x, stable
    by g: gen ix = _n
    assert rankx_group_uniq3 == ix

    gisid g rankx_group_uniq1
    gisid g rankx_group_uniq2

    clear
    set obs 10
    gen x = rnormal()
    gen fw = _n
    gen aw = runiform() * 5
    gen pw = runiform()
    gen iw = rnormal()
    replace fw = . in 5
    replace x  = . in 3

    gegen r1_def    = rank(x) [fw = fw], ties(def)
    gegen r1_field  = rank(x) [fw = fw], ties(field)
    gegen r1_track  = rank(x) [fw = fw], ties(track)
    gegen r1_uniq   = rank(x) [fw = fw], ties(uniq)
    gegen r1_stable = rank(x) [fw = fw], ties(stable)

    gegen r2 = rank(x) [aw = aw]
    gegen r3 = rank(x) [pw = pw]
    gegen r4 = rank(x) [iw = iw]

    gisid r1_uniq if !mi(r1_uniq)
    gisid r1_stable if !mi(r1_stable)

    expand fw

    gegen r_def    = rank(x) if !mi(fw), ties(def)
    gegen r_field  = rank(x) if !mi(fw), ties(field)
    gegen r_track  = rank(x) if !mi(fw), ties(track)

    assert r_def    == r1_def
    assert r_field  == r1_field
    assert r_track  == r1_track

    egen e_def    = rank(x) if !mi(fw)
    egen e_field  = rank(x) if !mi(fw), field
    egen e_track  = rank(x) if !mi(fw), track

    assert e_def    == r1_def
    assert e_field  == r1_field
    assert e_track  == r1_track

    * cumsum
    * ------

    clear
    set rmsg on
    set obs 1000000
    gen g = ceil(runiform() * 10)
    gen x = ceil(rnormal() * 10)
    gen y = ceil(rnormal() * 10)
    gen w = abs(round(rnormal() * 10, 0.1))
    gegen double cumx = cumsum(x) [aw = w], cumby(+) by(g)
    qui {
        sort g x, stable
        by g: gen double sumx = sum(x * w)
    }
    qui gen zz = reldif(sumx, cumx)
    qui sum zz, meanonly
    assert r(max) < 1e-8

    sysuse auto, clear
    gen ix = _n

    * fails
    cap noi gegen cumprice = cumsum(price), cumby(+ +) replace
    assert _rc == 198
    cap noi gegen cumprice = cumsum(price), cumby(- +) replace
    assert _rc == 198
    cap noi gegen cumprice = cumsum(price), cumby(+ -) replace
    assert _rc == 198
    cap noi gegen cumprice = cumsum(price), cumby(+ _) replace
    assert _rc == 111
    cap noi gegen cumprice = cumsum(price), cumby(+ price weight) replace
    assert _rc == 198
    cap noi gegen cumprice = cumsum(price), cumby(+ make) replace
    assert _rc == 198
    cap noi gegen cumprice = cumsum(price), cumby(price) replace
    assert _rc == 7
    cap noi gegen cumprice = cumsum(price), cumby(price -) replace
    assert _rc == 7

    sysuse auto, clear
    gen ix = _n

    * 1. Basic
    gegen cumprice = cumsum(price)
    gen sumprice = sum(price)
    assert (cumprice == sumprice)
    drop ???price

    * 2. by()
    gegen cumprice = cumsum(price), by(foreign)
    by foreign (ix), sort: gen sumprice = sum(price)
    assert (cumprice == sumprice)
    drop ???price

    * 3. +
    sort foreign price
    by foreign: gen sumprice = sum(price)
    sort foreign ix
    gegen cumprice = cumsum(price), by(foreign) cumby(+)
    assert (cumprice == sumprice)
    drop ???price

    gegen cumprice = cumsum(rep78), by(foreign) cumby(+)
    sort foreign rep78 cumprice
    by foreign: gen sumprice = sum(rep78) if !mi(rep78)
    sort foreign ix
    assert (cumprice == sumprice)
    drop ???price

    * 4. -
    gsort foreign -price
    by foreign: gen sumprice = sum(price)
    sort foreign ix
    gegen cumprice = cumsum(price), by(foreign) cumby(-)
    assert (cumprice == sumprice)
    drop ???price

    gegen cumprice = cumsum(rep78), by(foreign) cumby(-)
    gsort foreign -rep78 cumprice
    by foreign: gen sumprice = sum(rep78) if !mi(rep78)
    sort foreign ix
    assert (cumprice == sumprice)
    drop ???price

    * 5. + mpg
    sort foreign weight price
    by foreign: gen sumprice = sum(price)
    sort foreign ix
    gegen cumprice = cumsum(price), by(foreign) cumby(+ weight)
    assert (cumprice == sumprice)
    drop ???price

    * 6. - mpg
    gsort foreign -weight -price
    by foreign: gen sumprice = sum(price)
    sort foreign ix
    gegen cumprice = cumsum(price), by(foreign) cumby(- weight)
    assert (cumprice == sumprice)
    drop ???price

    * 7. + rep78
    sort foreign rep78 price
    by foreign: gen sumprice = sum(price) if !mi(rep78)
    sort foreign ix
    gegen cumprice = cumsum(price), by(foreign) cumby(+ rep78)
    assert (cumprice == sumprice)
    drop ???price

    * 8. - rep78
    gsort foreign -rep78 -price
    by foreign: gen sumprice = sum(price) if !mi(rep78)
    sort foreign ix
    gegen cumprice = cumsum(price), by(foreign) cumby(- rep78)
    assert (cumprice == sumprice)
    drop ???price

    * 9. [fw = rep78]
    sort foreign ix
    gen sumprice = price * rep78
    by foreign: replace sumprice = sum(sumprice) if !mi(rep78)
    gegen cumprice = cumsum(price) [fw = rep78], by(foreign)
    assert (cumprice == sumprice)
    drop ???price

    * 10. + [fw = rep78]
    gsort foreign price
    by foreign: gen sumprice = sum(price * rep78) if !mi(rep78)
    sort foreign ix
    gegen cumprice = cumsum(price) [fw = rep78], by(foreign) cumby(+)
    assert (cumprice == sumprice)
    drop ???price

    * 11. - [fw = rep78]
    gsort foreign -price
    by foreign: gen sumprice = sum(price * rep78) if !mi(rep78)
    sort foreign ix
    gegen cumprice = cumsum(price) [fw = rep78], by(foreign) cumby(-)
    assert (cumprice == sumprice)
    drop ???price

    * 12. + mpg [fw = rep78]
    sort foreign weight price
    by foreign: gen sumprice = sum(price * rep78) if !mi(rep78)
    sort foreign ix
    gegen cumprice = cumsum(price) [fw = rep78], by(foreign) cumby(+ weight)
    assert (cumprice == sumprice)
    drop ???price

    * 13. - mpg [fw = rep78]
    gsort foreign -weight -price
    by foreign: gen sumprice = sum(price * rep78) if !mi(rep78)
    sort foreign ix
    gegen cumprice = cumsum(price) [fw = rep78], by(foreign) cumby(- weight)
    assert (cumprice == sumprice)
    drop ???price

    * Shift
    * -----

    sysuse auto, clear
    gen ix = _n

    cap noi gegen gprice3 = shift(price), by(foreign) shiftby(3.8)
    assert _rc == 7
    cap noi gegen gprice3 = shift(price), by(foreign) shiftby(-.1)
    assert _rc == 7
    cap noi gegen gprice3 = shift(price), by(foreign) shiftby(-)
    assert _rc == 7
    cap noi gegen gprice3 = shift(price), by(foreign) shiftby(wa)
    assert _rc == 7
    cap noi gegen gprice3 = shift(price), by(foreign)
    assert _rc == 198

    gegen gprice_3 = shift(price), shiftby(-3) by(foreign)
    qui by foreign: gen price_3 = price[_n - 3]
    assert gprice_3 == price_3

    gegen gprice3 = shift(price), shiftby(3) by(foreign)
    qui by foreign: gen price3 = price[_n + 3]
    assert gprice3 == price3

    gegen gprice_6 = shift-6(price), by(foreign)
    qui by foreign: gen price_6 = price[_n - 6]
    assert gprice_6 == price_6

    gegen gprice6 = shift+6(price), by(foreign)
    qui by foreign: gen price6 = price[_n + 6]
    assert gprice6 == price6

    gegen gpricea = shift+0(price), by(foreign)
    gegen gpriceb = shift-0(price), by(foreign)
    gegen gpricec = shift|0(price), by(foreign)
    gegen gpriced = shift(price),   by(foreign) shiftby(0)

    assert price == gpricea
    assert price == gpriceb
    assert price == gpricec
    assert price == gpriced

    clear
    set rmsg on
    set obs 1000000
    gen g = ceil(runiform() * 10)
    gen x = ceil(rnormal() * 10)
    gen y = ceil(rnormal() * 10)
    gen w = abs(round(rnormal() * 10, 0.1))
    gen long ix = _n
    gegen gshiftx = shift(x) [aw = w], shiftby(-2) by(g)
    qui {
        gen byte now = mi(w) | w == 0
        sort g now, stable
        by g now: gen `:type x' shiftx = x[_n - 2]
    }
    assert (gshiftx == shiftx) | now

    * Gini
    * ----

    clear
    set obs 1000
    gen g  = int(runiform() * 10)
    gen y  = exp(int(rnormal()) + g) - exp(g)
    gen fw = int(runiform() * 5)
    gen aw = runiform() * 10
    replace aw = . if mod(_n, 42) == 0
    replace y  = . if mod(_n, 81) == 0
    gen long ix = _n

    quickGini y, by(g) gen(_qg1)
    quickGini y, by(g) gen(_qg2) dropneg
    quickGini y, by(g) gen(_qg3) keepneg

    quickGini y [fw = 1], by(g) gen(_qg4)
    quickGini y [fw = 1], by(g) gen(_qg5) dropneg
    quickGini y [fw = 1], by(g) gen(_qg6) keepneg

    quickGini y [fw = fw], by(g) gen(_qg7)
    quickGini y [fw = fw], by(g) gen(_qg8) dropneg
    quickGini y [fw = fw], by(g) gen(_qg9) keepneg

    quickGini y [aw = aw], by(g) gen(_qg10)
    quickGini y [aw = aw], by(g) gen(_qg11) dropneg
    quickGini y [aw = aw], by(g) gen(_qg12) keepneg

    gegen _ge1 = gini(y), by(g)
    gegen _ge2 = gini|dropneg(y),   by(g)
    gegen _ge3 = gini|keepneg(y),   by(g)
    gegen _ge4 = gini(y) if y >= 0, by(g)
    gegen _ge4 = firstnm(_ge4), by(g) replace

    gegen _ge5 = gini(y) [fw = 1], by(g)
    gegen _ge6 = gini|dropneg(y) [fw = 1], by(g)
    gegen _ge7 = gini|keepneg(y) [fw = 1], by(g)
    gegen _ge8 = gini(y) if y >= 0 [fw = 1], by(g)
    gegen _ge8 = firstnm(_ge8), by(g) replace

    gegen _ge9 = gini(y) [fw = fw], by(g)
    gegen _ge10 = gini|dropneg(y) [fw = fw], by(g)
    gegen _ge11 = gini|keepneg(y) [fw = fw], by(g)
    gegen _ge12 = gini(y) if y >= 0 [fw = fw], by(g)
    gegen _ge12 = firstnm(_ge12) if fw > 0 & !mi(fw), by(g) replace

    gegen _ge13 = gini(y) [aw = aw], by(g)
    gegen _ge14 = gini|dropneg(y) [aw = aw], by(g)
    gegen _ge15 = gini|keepneg(y) [aw = aw], by(g)
    gegen _ge16 = gini(y) if y >= 0 [aw = aw], by(g)
    gegen _ge16 = firstnm(_ge16) if aw > 0 & !mi(aw), by(g) replace

    assert reldif(_qg1,  _qg4) < 1e-6 | (mi(_qg1) & mi(_qg4))
    assert reldif(_qg2,  _qg5) < 1e-6 | (mi(_qg2) & mi(_qg5))
    assert reldif(_qg3,  _qg6) < 1e-6 | (mi(_qg3) & mi(_qg6))

    assert reldif(_ge1,  _ge5) < 1e-6 | (mi(_ge1) & mi(_ge5))
    assert reldif(_ge2,  _ge6) < 1e-6 | (mi(_ge2) & mi(_ge6))
    assert reldif(_ge3,  _ge7) < 1e-6 | (mi(_ge3) & mi(_ge7))
    assert reldif(_ge4,  _ge8) < 1e-6 | (mi(_ge4) & mi(_ge8))

    assert reldif(_qg1,  _ge1) < 1e-6 | (mi(_qg1) & mi(_ge1))
    assert reldif(_qg2,  _ge2) < 1e-6 | (mi(_qg2) & mi(_ge2))
    assert reldif(_qg2,  _ge2) < 1e-6 | (mi(_qg2) & mi(_ge4))
    assert reldif(_qg3,  _ge3) < 1e-6 | (mi(_qg3) & mi(_ge3))
    assert reldif(_ge4,  _ge2) < 1e-6 | (mi(_ge4) & mi(_ge2))

    assert reldif(_qg4,  _ge5) < 1e-6 | (mi(_qg4) & mi(_ge5))
    assert reldif(_qg5,  _ge6) < 1e-6 | (mi(_qg5) & mi(_ge6))
    assert reldif(_qg5,  _ge6) < 1e-6 | (mi(_qg5) & mi(_ge8))
    assert reldif(_qg6,  _ge7) < 1e-6 | (mi(_qg6) & mi(_ge7))
    assert reldif(_ge8,  _ge6) < 1e-6 | (mi(_ge8) & mi(_ge6))

    assert reldif(_qg7,  _ge9)  < 1e-6 | (mi(_qg7)  & mi(_ge9))
    assert reldif(_qg8,  _ge10) < 1e-6 | (mi(_qg8)  & mi(_ge10))
    assert reldif(_qg8,  _ge10) < 1e-6 | (mi(_qg8)  & mi(_ge12))
    assert reldif(_qg9,  _ge11) < 1e-6 | (mi(_qg9)  & mi(_ge11))
    assert reldif(_ge12, _ge10) < 1e-6 | (mi(_ge12) & mi(_ge10))

    assert reldif(_qg10, _ge13) < 1e-6 | (mi(_qg10) & mi(_ge13))
    assert reldif(_qg11, _ge14) < 1e-6 | (mi(_qg11) & mi(_ge14))
    assert reldif(_qg11, _ge14) < 1e-6 | (mi(_qg11) & mi(_ge16))
    assert reldif(_qg12, _ge15) < 1e-6 | (mi(_qg12) & mi(_ge15))
    assert reldif(_ge16, _ge14) < 1e-6 | (mi(_ge16) & mi(_ge14))

    exit 0
end

capture program drop checks_inner_egen
program checks_inner_egen
    syntax [anything], [tol(real 1e-6) wgt(str) *]

    local 0 `anything' `wgt', `options'
    syntax [anything] [aw fw iw pw], [*]

    local percentiles 1 10 30.5 50 70.5 90 99
    local selections  1 2 5 999999 -999999 -5 -2 -1
    local stats nunique nmissing total sum mean geomean max min range count median iqr percent first last firstnm lastnm skew kurt gini gini|dropneg gini|keepneg
    local skipbulk
    if ( !inlist("`weight'", "pweight") )            local stats `stats' sd variance cv
    if ( !inlist("`weight'", "pweight", "iweight") ) local stats `stats' semean
    if (  inlist("`weight'", "fweight", "") )        local stats `stats' sebinomial sepoisson

    tempvar gvar
    foreach fun of local stats {
        `noisily' gegen `gvar' = `fun'(random1) `wgt', by(`anything') replace `options'
        if ( "`weight'" == "" & !(`:list fun in skipbulk') & ("`fun'" != "nunique") ) {
        `noisily' gegen `gvar' = `fun'(random*) `wgt', by(`anything') replace `options'
        }
    }

    foreach p in `percentiles' {
        `noisily' gegen `gvar' = pctile(random1) `wgt', p(`p') by(`anything') replace `options'
        if ( "`weight'" == "" ) {
        `noisily' gegen `gvar' = pctile(random*) `wgt', p(`p') by(`anything') replace `options'
        }
    }

    if ( !inlist("`weight'", "iweight") ) {
        foreach n in `selections' {
            `noisily' gegen `gvar' = select(random1) `wgt', n(`n') by(`anything') replace `options'
            if ( "`weight'" == "" ) {
            `noisily' gegen `gvar' = select(random*) `wgt', n(`n') by(`anything') replace `options'
            }
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

    qui `noisily' gen_data, n(500)
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

    if ( `c(stata_version)' >= 14.1 ) {
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
    if ( ("`sort'" != "") & ("`anything'" != "") ) {
        if ( strpos(`"`anything'"', "strL") > 0 ) {
            sort `anything'
        }
        else {
            hashsort `anything'
        }
    }

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
    syntax, [tol(real 1e-6) bench(int 1) n(int 500) NOIsily *]

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

    if ( `c(stata_version)' >= 14.1 ) {
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

    if ( `c(stata_version)' >= 14.1 ) {
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

    clear
    set obs 10
    gen x = mod(_n, 3)
    gen y = mod(_n, 4)
    gunique x
    gunique y
    gunique y, by(x)
    cap gunique y, by(x)
    assert _rc == 110
    gen `:type _Unique' _Unique2 = _Unique
    gunique y, by(x) replace
    assert _Unique == _Unique2
    replace y = 0
    gunique y, by(x) replace
    assert _Unique == 1

    drop _U*
    gunique y, by(x) gen(nuniq)
    cap gunique y, by(x) gen(nuniq)
    assert _rc == 110
    gen `:type nuniq' nuniq2 = nuniq
    gunique y, by(x) gen(nuniq) replace
    assert nuniq == nuniq2
    replace y = 0
    gunique y, by(x) gen(nuniq) replace
    assert nuniq == 1

    exit 0
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

    qui `noisily' gen_data, n(500)
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

    compare_inner_unique int1 str_32 int3 double3  , `options'
    compare_inner_unique int1 int1 double2 double3 , `options'
    compare_inner_unique int1 double? str_* int?   , `options'

    if ( `c(stata_version)' >= 14.1 ) {
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
    if ( ("`sort'" != "") & ("`anything'" != "") ) {
        if ( strpos(`"`anything'"', "strL") > 0 ) {
            sort `anything'
        }
        else {
            hashsort `anything'
        }
    }

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
    syntax, [tol(real 1e-6) bench(int 1) n(int 500) NOIsily distinct joint distunique *]

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

    if ( `c(stata_version)' >= 14.1 ) {
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

    if ( `c(stata_version)' >= 14.1 ) {
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
    cap glevelsof x
    assert _rc == 920
    cap glevelsof x, gen(uniq) nolocal
    assert _rc == 0

    sysuse auto, clear
    glevelsof price
    glevelsof mpg
    glevelsof price   mpg     foreign
    glevelsof foreign mpg     price
    glevelsof mpg     foreign price
    glevelsof price   make    mpg     foreign
    glevelsof foreign make    mpg     price
    glevelsof mpg     make    foreign price
    glevelsof price   mpg     foreign
    glevelsof foreign mpg     price
    glevelsof mpg     foreign price
    glevelsof make    price   mpg     foreign
    glevelsof make    foreign mpg     price
    glevelsof make    mpg     foreign price
    glevelsof price   mpg     foreign make
    glevelsof foreign mpg     price   make
    glevelsof mpg     foreign price   make

    glevelsof price                           , mata(hi)
    glevelsof mpg                             , mata(hi)
    glevelsof price   mpg     foreign         , mata(hi)
    glevelsof foreign mpg     price           , mata(hi)
    glevelsof mpg     foreign price           , mata(hi)
    glevelsof price   make    mpg     foreign , mata(hi)
    glevelsof foreign make    mpg     price   , mata(hi)
    glevelsof mpg     make    foreign price   , mata(hi)
    glevelsof price   mpg     foreign         , mata(hi)
    glevelsof foreign mpg     price           , mata(hi)
    glevelsof mpg     foreign price           , mata(hi)
    glevelsof make    price   mpg     foreign , mata(hi)
    glevelsof make    foreign mpg     price   , mata(hi)
    glevelsof make    mpg     foreign price   , mata(hi)
    glevelsof price   mpg     foreign make    , mata(hi)
    glevelsof foreign mpg     price   make    , mata(hi)
    glevelsof mpg     foreign price   make    , mata(hi)

    clear
    set obs 2000
    gen long ix = _n
    gen r  = runiform()
    sort r

    glevelsof ix
    glevelsof ix, mata
    glevelsof ix, mata(hi) silent

    mata hi.desc()
    mata hi.getPrinted("%16.0g", 1)
    mata hi.desc()

    exit 0
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
    qui expand 5000

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

    if ( `c(stata_version)' >= 14.1 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        compare_inner_levelsof strL1, `options' `forcestrl'
        compare_inner_levelsof strL2, `options' `forcestrl'
        compare_inner_levelsof strL3, `options' `forcestrl'
    }

    qui `noisily' gen_data, n(500)
    qui expand 100

    local N    = trim("`: di %15.0gc _N'")
    local hlen = 24 + length("`options'") + length("`N'")
    di _n(1) "{hline 80}" _n(1) "compare_levelsof_gen, N = `N', `options'" _n(1) "{hline 80}" _n(1)

    compare_inner_levelsof_gen str_12,              `options' sort
    compare_inner_levelsof_gen str_12 str_32 str_4, `options'

    compare_inner_levelsof_gen double1,                 `options'
    compare_inner_levelsof_gen double1 double2 double3, `options' shuffle

    compare_inner_levelsof_gen int1,           `options' shuffle
    compare_inner_levelsof_gen int1 int2 int3, `options' sort

    compare_inner_levelsof_gen str_32 int3 double3  , `options'
    compare_inner_levelsof_gen int1 double2 double3 , `options'
    compare_inner_levelsof_gen double? str_* int?   , `options'
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
                    cap assert reldif(`l_gcmp', `l_scmp') < 1e-12
                    if ( _rc ) {
                        di as err "    compare_levelsof (failed): glevelsof `varlist' returned different levels with rounding"
                        exit 198
                    }
                }
            }
            di as txt "    compare_levelsof (passed): glevelsof `varlist' returned similar levels as levelsof (tol = 1e-12)"
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
                    cap assert reldif(`l_gcmp', `l_scmp') < 1e-12
                    if ( _rc ) {
                        di as err "    compare_levelsof (failed): glevelsof `varlist' returned different levels with rounding"
                        exit 198
                    }
                }
            }
            di as txt "    compare_levelsof (passed): glevelsof `varlist' returned similar levels as levelsof (tol = 1e-12)"
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
                        cap assert reldif(`l_gcmp', `l_scmp') < 1e-12
                        if ( _rc ) {
                            di as err "    compare_levelsof (failed): glevelsof `varlist' [in] returned different levels with rounding"
                            exit 198
                        }
                    }
                }
                di as txt "    compare_levelsof (passed): glevelsof `varlist' [in] returned similar levels as levelsof (tol = 1e-12)"
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
                        cap assert reldif(`l_gcmp', `l_scmp') < 1e-12
                        if ( _rc ) {
                            di as err "    compare_levelsof (failed): glevelsof `varlist' [in] returned different levels with rounding"
                            exit 198
                        }
                    }
                }
                di as txt "    compare_levelsof (passed): glevelsof `varlist' [in] returned similar levels as levelsof (tol = 1e-12)"
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
                        cap assert reldif(`l_gcmp', `l_scmp') < 1e-12
                        if ( _rc ) {
                            di as err "    compare_levelsof (failed): glevelsof `varlist' [if] returned different levels with rounding"
                            exit 198
                        }
                    }
                }
                di as txt "    compare_levelsof (passed): glevelsof `varlist' [if] returned similar levels as levelsof (tol = 1e-12)"
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
                        cap assert reldif(`l_gcmp', `l_scmp') < 1e-12
                        if ( _rc ) {
                            di as err "    compare_levelsof (failed): glevelsof `varlist' [if] returned different levels with rounding"
                            exit 198
                        }
                    }
                }
                di as txt "    compare_levelsof (passed): glevelsof `varlist' [if] returned similar levels as levelsof (tol = 1e-12)"
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
                        cap assert reldif(`l_gcmp', `l_scmp') < 1e-12
                        if ( _rc ) {
                            di as err "    compare_levelsof (failed): glevelsof `varlist' [if] [in] returned different levels with rounding"
                            exit 198
                        }
                    }
                }
                di as txt "    compare_levelsof (passed): glevelsof `varlist'  if] [in] returned similar levels as levelsof (tol = 1e-12)"
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
                        cap assert reldif(`l_gcmp', `l_scmp') < 1e-12
                        if ( _rc ) {
                            di as err "    compare_levelsof (failed): glevelsof `varlist' [if] [in] returned different levels with rounding"
                            exit 198
                        }
                    }
                }
                di as txt "    compare_levelsof (passed): glevelsof `varlist'  if] [in] returned similar levels as levelsof (tol = 1e-12)"
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
    qui expand `=500 * `bench''
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

    qui {
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

        if ( `c(stata_version)' >= 14.1 ) {
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
    }

    sysuse auto , clear
    forvalues i = 1 / 100 {
        gtop make price, ntop(`i') silent
    }

    sysuse auto , clear
    gtop price                           , mata
    gtop mpg                             , mata
    gtop price   mpg     foreign         , mata
    gtop foreign mpg     price           , mata
    gtop mpg     foreign price           , mata
    gtop price   make    mpg     foreign , mata
    gtop foreign make    mpg     price   , mata
    gtop mpg     make    foreign price   , mata
    gtop price   mpg     foreign         , mata
    gtop foreign mpg     price           , mata
    gtop mpg     foreign price           , mata
    gtop make    price   mpg     foreign , mata
    gtop make    foreign mpg     price   , mata
    gtop make    mpg     foreign price   , mata
    gtop price   mpg     foreign make    , mata
    gtop foreign mpg     price   make    , mata
    gtop mpg     foreign price   make    , mata

    expand mpg

    gtop price                           , ntop(.) mata(hi)
    gtop mpg                             , ntop(.) mata(hi)
    gtop price   mpg     foreign         , ntop(.) mata(hi)
    gtop foreign mpg     price           , ntop(.) mata(hi)
    gtop mpg     foreign price           , ntop(.) mata(hi)
    gtop price   make    mpg     foreign , ntop(.) mata(hi)
    gtop foreign make    mpg     price   , ntop(.) mata(hi)
    gtop mpg     make    foreign price   , ntop(-.) mata(hi)
    gtop price   mpg     foreign         , ntop(-.) mata(hi)
    gtop foreign mpg     price           , ntop(-.) mata(hi)
    gtop mpg     foreign price           , ntop(-.) mata(hi)
    gtop make    price   mpg     foreign , ntop(-.) mata(hi)
    gtop make    foreign mpg     price   , ntop(-.) mata(hi)
    gtop make    mpg     foreign price   , ntop(-.) mata(hi)
    gtop price   mpg     foreign make    , ntop(-.) mata
    gtop foreign mpg     price   make    , ntop(-.) mata
    gtop mpg     foreign price   make    , ntop(-.) mata

    clear
    set obs 2000
    gen long ix = _n
    gen r  = runiform()
    sort r

    gtop ix, ntop(.) mata
    gtop ix, ntop(.)
    gtop ix, ntop(.) mata(hi) silent

    mata hi.desc()
    mata hi.getPrinted("%16.0g", 1)
    mata hi.desc()

    gtop ix, mata(hi) silent
    * gtop ix, mata(hi) silent ntop(.) alpha

    exit 0
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
    gtoplevelsof `anything', `options' ntop(.)
    gtoplevelsof `anything', `options' ntop(-.)
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

    qui `noisily' gen_data, n(500)
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

    if ( `c(stata_version)' >= 14.1 ) {
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
    syntax [anything] [if] [in], [NOIsily tol(real 1e-6) contract wgt(str) *]

    if ( "`contract'" == "" ) local contract gcontract

    * cf(Cum) p(Pct) cp(PctCum)
    local opts freq(N)
    preserve
        qui {
            `noisily' `contract' `anything' `if' `in' `wgt', `opts'
            qui sum N, meanonly
            local r_N = `r(sum)'
            if ( strpos(`"`anything'"', "strL") > 0 ) {
                gsort -N `anything'
            }
            else {
                hashsort -N `anything'
            }
            local nl = min(_N, 10)
            keep in 1/`=min(_N, 10)'
            set obs `=_N+1'
            gen byte ID = 1
            replace ID  = 3 in `=_N'
            gen long ix = _n
            gen long Cum = sum(N)
            gen double Pct = 100 * N / `r_N'
            gen double PctCum = 100 * Cum / `r_N'
            replace Pct       = 100 - PctCum[10] in `=_N'
            replace PctCum    = 100 in `=_N'
            replace N         = `r_N' - Cum[10] in `=_N'
            replace Cum       = `r_N' in `=_N'
            local varlist: subinstr local anything "-" "", all
            if ( `:list sizeof varlist' == 1 ) {
                local levels [:skip:]
                forvalues i = 1 / `=_N' {
                    local levels `levels' `"`:disp `varlist'[`i']'"'
                }
            }
        }
        tempfile fg
        qui save `fg'
    restore

    tempname gmat
    preserve
        qui {
            `noisily' gtoplevelsof `anything' `if' `in' `wgt', mat(`gmat')
            if ( `:list sizeof varlist' == 1 ) {
                forvalues i = 1 / `nl' {
                    * noi disp `i', `"`:word `=`i'+1' of `levels''"', `"`:word `i' of `r(levels)''"'
                    cap assert (`"`:word `=`i'+1' of `levels''"' == `"`:word `i' of `r(levels)''"')
                    if ( _rc ) {
                        if ( "`if'`in'" == "" ) {
                            noi di as err "    compare_gtoplevelsof_gcontract (failed levels): full range, `anything'"
                        }
                        else if ( "`if'`in'" != "" ) {
                            noi di as err "    compare_gtoplevelsof_gcontract (failed levels): [`if' `in'], `anything'"
                        }
                        exit 198
                    }
                }
                if ( "`if'`in'" == "" ) {
                    noi di "    compare_gtoplevelsof_gcontract (passed): full range, same levels as gcontract"
                }
                else if ( "`if'`in'" != "" ) {
                    noi di "    compare_gtoplevelsof_gcontract (passed): [`if' `in'], same levels as gcontract"
                }
            }
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
    syntax, [tol(real 1e-6) bench(real 1) n(int 500) NOIsily *]

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
            if ( strpos(`"`anything'"', "strL") > 0 ) {
                gsort -freq `anything'
            }
            else {
                hashsort -freq `anything'
            }
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

    if ( `c(stata_version)' >= 14.1 ) {
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

    exit 0
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
    cap noi gisid `varlist' ix, `options' v bench missok
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

    qui `noisily' gen_data, n(500)
    qui expand 100

    local N    = trim("`: di %15.0gc _N'")
    local hlen = 20 + length("`options'") + length("`N'")
    di _n(1) "{hline 80}" _n(1) "compare_isid, N = `N', `options'" _n(1) "{hline 80}" _n(1)

    compare_inner_isid str_12,              `options'
    compare_inner_isid str_12 str_32 str_4, `options'

    compare_inner_isid double1,                 `options'
    compare_inner_isid double1 double2 double3, `options'

    compare_inner_isid int1,           `options'
    compare_inner_isid int1 int2,      `options'
    compare_inner_isid int1 int2 int3, `options'

    compare_inner_isid str_32 int3 double3  , `options'
    compare_inner_isid int1 double2 double3 , `options'
    compare_inner_isid double? str_* int?   , `options'

    if ( `c(stata_version)' >= 14.1 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        compare_inner_isid strL1,             `options' `forcestrl' sort
        compare_inner_isid strL1 strL2,       `options' `forcestrl' sort
        compare_inner_isid strL1 strL2 strL3, `options' `forcestrl' sort
    }
end

capture program drop compare_inner_isid
program compare_inner_isid
    syntax varlist, [sort *]

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

    if ( `"`sort'"' == "" ) hashsort `varlist'
    else sort `varlist'

    cap gisid `varlist', missok `options'
    local rc_gisid = _rc
    check_rc `rc_isid' `rc_gisid' , by([sorted] `varlist')

    cap isid `ix' `varlist', missok
    local rc_isid = _rc
    cap gisid `ix' `varlist', missok `options'
    local rc_gisid = _rc
    check_rc `rc_isid' `rc_gisid' , by( ix `varlist')

    * make sure sorted check gives same result

    if ( `"`sort'"' == "" ) hashsort `ix' `varlist'
    else sort `ix' `varlist'

    cap gisid `ix' `varlist', missok `options'
    local rc_gisid = _rc
    check_rc `rc_isid' `rc_gisid' , by([sorted] ix `varlist')

    cap isid `rsort' `varlist', missok
    local rc_isid = _rc
    cap gisid `rsort' `varlist', missok `options'
    local rc_gisid = _rc
    check_rc `rc_isid' `rc_gisid' , by( rsort `varlist')

    * make sure sorted check gives same result

    if ( `"`sort'"' == "" ) hashsort `rsort' `varlist'
    else sort `rsort' `varlist'

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
    syntax, [tol(real 1e-6) bench(int 1) n(int 500) NOIsily *]

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
* Checks in greshape
* ------------------
*
* 1. Unique j
* 2. Unique Xi
* 3. Missing j values
* 4. preserve, restore
* 5. Unique i
* 6. unsorted

capture program drop checks_greshape
program checks_greshape
    qui checks_inner_greshape_errors
    qui checks_inner_greshape_errors nochecks

    qui checks_inner_greshape_long
    qui checks_inner_greshape_long nochecks
    qui checks_inner_greshape_long " " xi
    qui checks_inner_greshape_long nochecks xi

    qui checks_inner_greshape_wide
    qui checks_inner_greshape_wide nochecks
    qui checks_inner_greshape_wide " " xi
    qui checks_inner_greshape_wide nochecks xi

    * Random check: chars, labels, etc.
    * ---------------------------------

    sysuse auto, clear
    note price: Hello, there!
    note price: GENERAL KENOBI!!!
    note price: You are a bold one.
    char price[varname] #GiraffesAreFake
    char price[note17]  This should not be listed by notes

    note mpg: I don't like sand
    note mpg: It's coarse and rough and irritating and it gets everywhere
    note mpg: It used to bother me that Anakin commits genocide and Padme stays with him.
    note mpg: But I think it's just supposed to show how much she's drawn to the dark side.
    note mpg: I mean, she did leave Jar Jar in charge, and Jar Jar did give Palpatine emergency powers
    note mpg: #JarJarWasSupposedToBeASithLordButYallRuinedItWithYourBickering
    char mpg[varname] Thisis my fight song
    char mpg[note11]  My I'm all right song

    label define pr .a A .b B
    label define mp .a C .b D
    label values price pr
    label values mpg   mp
    replace price = .a if mod(_n, 2)
    replace mpg   = .b if _n > 50

    preserve
        greshape wide price mpg, i(make) j(foreign)
        desc price* mpg*
    restore, preserve
        greshape wide price mpg, i(make) j(foreign) labelf(#stublabel#, #keyname# == #keyvaluelabel#)
        desc price* mpg*
    restore, preserve
        greshape wide price mpg, i(make) j(foreign) labelf(#stubname#, #keylabel# == #keyvalue#)
        desc price* mpg*
    restore, preserve
        label drop origin
        greshape wide price mpg, i(make) j(foreign) labelf(#stublabel#, #keyname# == #keyvaluelabel#)
        desc price* mpg*
    restore, preserve
        decode foreign, gen(fstr)
        greshape wide price mpg, i(make) j(fstr) labelf(#stublabel#, #keyname# == #keyvaluelabel#)
        desc price* mpg*
    restore, preserve
        decode foreign, gen(fstr)
        greshape wide price mpg, i(make) j(fstr)
        desc price* mpg*
    restore, preserve
        decode foreign, gen(fstr)
        greshape wide price mpg, i(make) j(fstr foreign)
        desc price* mpg*
    restore, preserve
        decode foreign, gen(fstr)
        greshape wide price mpg, i(make) j(foreign fstr) labelf(#stublabel#, #keyname# == #keyvaluelabel#)
        desc price* mpg*
    restore

    preserve
        greshape wide price mpg, i(make) j(foreign)
        greshape long price mpg, i(make) j(foreign)

        greshape wide price mpg, i(make) j(foreign)
        gen long   price2 = _n    
        gen double price3 = 3.14
        note price2: When the night!
        note price3: Has coooome....
        greshape long price mpg, i(make) j(foreign)
    restore

    preserve
        greshape spread price, i(make) j(foreign) xi(drop)
        greshape gather _*, j(foreign) values(price)
    restore

    preserve
        greshape spread mpg, i(make) j(foreign) xi(drop)
        greshape gather _*,  j(foreign) values(mpg)
    restore

    preserve
        greshape spread price mpg,   i(make) j(foreign) xi(drop)
        greshape gather price* mpg*, j(foreign) values(price_mpg)
    restore

    gen long   price2 = _n    
    gen double price3 = 3.14
    note price2: When the night!
    note price3: Has coooome....

    preserve
        greshape spread price, i(make) j(foreign) xi(drop)
        greshape gather _*, j(foreign) values(price)
    restore

    preserve
        greshape spread mpg, i(make) j(foreign) xi(drop)
        greshape gather _*,  j(foreign) values(mpg)
    restore
                                                              
    preserve
        greshape spread price mpg,   i(make) j(foreign) xi(drop)
        greshape gather price* mpg*, j(foreign) values(price_mpg)
    restore

    * Check dropmiss
    * --------------

    clear
    set obs 10
    gen i = _n
    gen x1 = 1
    gen x2 = 2
    gen z1 = "a"
    gen z2 = "bb"
    preserve
        greshape gather x*, values(x) key(var) dropmiss
    restore, preserve
        greshape long x, by(i) key(var) dropmiss nochecks
    restore, preserve
        greshape long x, by(i) key(var) dropmiss
    restore, preserve
        greshape gather z*, values(z) key(var) dropmiss
    restore, preserve
        greshape long z, by(i) key(var) dropmiss nochecks
    restore
        greshape long z, by(i) key(var) dropmiss

    clear
    set obs 10
    gen i = _n
    gen x1 = 1
    gen x2 = 2
    gen x3 = .
    gen z1 = "a"
    gen z2 = "bb"
    gen z3 = ""
    preserve
        greshape gather x*, values(x) key(var) dropmiss
    restore, preserve
        greshape long x, by(i) key(var) dropmiss nochecks
    restore, preserve
        greshape long x, by(i) key(var) dropmiss
    restore, preserve
        greshape gather z*, values(z) key(var) dropmiss
    restore, preserve
        greshape long z, by(i) key(var) dropmiss nochecks
    restore
        greshape long z, by(i) key(var) dropmiss

    clear
    set obs 10
    gen i = _n
    gen x1 = 1
    gen x2 = 2
    gen x3 = 3
    gen x4 = .
    gen x5 = 5
    replace x1 = . in 1
    replace x2 = . in 1
    replace x3 = . in 1
    replace x5 = . in 1
    replace x1 = . in 2
    replace x2 = . in 3
    replace x3 = . in 4
    replace x5 = . in 5
    replace x1 = . in 6
    replace x2 = . in 7
    replace x3 = . in 8
    replace x5 = . in 9

    gen z1 = "a"
    gen z2 = "bb"
    gen z3 = "ccc"
    gen z4 = ""
    gen z5 = "eeeee"
    replace z1 = "" in 1
    replace z2 = "" in 1
    replace z3 = "" in 1
    replace z5 = "" in 1
    replace z1 = "" in 2
    replace z2 = "" in 3
    replace z3 = "" in 4
    replace z5 = "" in 5
    replace z1 = "" in 6
    replace z2 = "" in 7
    replace z3 = "" in 8
    replace z5 = "" in 9

    preserve
        greshape gather x*, values(x) key(var) dropmiss
    restore, preserve
        greshape long x, by(i) key(var) dropmiss nochecks
    restore, preserve
        greshape long x, by(i) key(var) dropmiss
    restore, preserve
        greshape gather z*, values(z) key(var) dropmiss
    restore, preserve
        greshape long z, by(i) key(var) dropmiss nochecks
    restore, preserve
        greshape long z, by(i) key(var) dropmiss
    restore, preserve
        greshape long x z, by(i) key(var) dropmiss
    restore, preserve
        greshape long x z, by(i) key(var) nochecks dropmiss
    restore, preserve
        greshape long x z, by(i) key(var) nochecks
    restore
        greshape long x z, by(i) key(var)

    exit 0
end

capture program drop compare_greshape
program compare_greshape
    local n 500
    qui gen_data, n(`n')
    qui expand 100
    qui `noisily' random_draws, random(2) double
    gen long   ix_num = _n
    gen str    ix_str = "str" + string(_n)
    gen double ix_dbl = _pi + _n
    cap drop strL*
    qui hashsort random1

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    di _n(1) "{hline 80}" _n(1) "compare_greshape, N = `N', J = `J' `options'" _n(1) "{hline 80}" _n(1)

    rename double? dbl?
    rename int?    num?

    compare_fail_greshape versus_greshape dbl random,      j(_j) i(ix_num num1)
    compare_fail_greshape versus_greshape dbl random,      j(_j) i(ix_num num1 num2)
    compare_fail_greshape versus_greshape dbl random str_, j(_j) i(ix_num num1 num2 num3) string

    compare_fail_greshape versus_greshape num random,      j(_j) i(ix_dbl dbl1)
    compare_fail_greshape versus_greshape num random str_, j(_j) i(ix_dbl dbl1 dbl2 dbl3) string

    compare_fail_greshape versus_greshape dbl num random, j(_j) i(ix_str str_32)
    compare_fail_greshape versus_greshape dbl num random, j(_j) i(ix_str str_32 str_12 str_4) string

    compare_fail_greshape versus_greshape random, j(_j) i(ix_str str_32 num3 dbl3) string
    compare_fail_greshape versus_greshape random, j(_j) i(ix_num num1 dbl2 dbl3)   string

    disp
end

capture program drop compare_fail_greshape
program compare_fail_greshape
    gettoken cmd 0: 0
    syntax [anything], [tol(real 1e-6) *]
    cap `cmd' `0'
    if ( _rc ) {
        di "    compare_greshape (failed): `anything', `options'"
        exit _rc
    }
    else {
        di "    compare_greshape (passed): greshape wide/long gave identical data (via cf); `anything', `options'"
    }
end

***********************************************************************
*                               Errors                                *
***********************************************************************

capture program drop checks_inner_greshape_errors
program checks_inner_greshape_errors

    foreach v in v1 v2 {
        clear
        set obs 5
        gen i1 = _n
        gen i2 = -_n
        gen i3 = "why?" + string(mod(_n, 3))
        gen i4 = "hey" + string(-_n) + "thisIsLongRight?"
        expand 3
        if "`v'" == "v1" bys i1: gen j = "@#" + string(_n) + "|"
        else bys i1: gen j = _n + _N
        gen w = "|" + string(_n / 3) + "/"
        gen x = _N - _n
        gen y = _n / 2
        gen r = runiform()
        sort r
        drop r

        preserve
            greshape wide x y w, i(i1) j(j)
            assert _rc == 0
        restore, preserve
            cap greshape wide x, i(i1) j(j)
            assert _rc == 9
        restore, preserve
            if "`v'" == "v1" replace j = "2" if i1 == 1
            else replace j = 2 if i1 == 1
            cap greshape wide x y, i(i1) j(j)
            assert _rc == 9
        restore, preserve
            rename (i3 i4) (a3 a4)
            cap greshape long a, i(i1 i2) j(_j)
            assert _rc == 9
        restore, preserve
            cap greshape long i, i(i1 i2 j) j(_j)
            assert _rc == 198
        restore, preserve
            cap greshape long a, i(i1 i? j) j(_j)
            assert _rc == 111
        restore, preserve
            rename (i3 i4) (a3 a4)
            cap greshape long a, i(i1 i? j) j(_j)
            assert _rc == 0
        restore

        label var i3 "hey-o i3"
        label var i4 "bye-a i4"
        preserve
            greshape gather i3 i4, values(val) by(i1 i2) xi(drop)
            l in 1/10
        restore, preserve
            greshape gather i3 i4, values(val) by(i1 i2) xi(drop) uselabels
            l in 1/10
        restore, preserve
            greshape gather i3 i4, values(val) by(i1 i2) xi(drop) uselabels(i3)
            l in 1/10
        restore, preserve
            greshape gather i3 i4, values(val) by(i1 i2) xi(drop) uselabels(i3, exclude)
            l in 1/10
        restore
    }

    clear
    set obs 5
    gen bykey      = _n
    gen st1ub      = _n
    gen st2ub      = -_n
    gen foo3bar    = "foobar" + string(mod(_n, 3))
    gen foo4bar    = "foobar" + string(-_n) + "thisIsLongRight?"
    gen ali9ce5bob = "ali9cebob" + string(mod(_n, 3))
    gen ali9ce6bob = "ali9cebob" + string(-_n) + "thisIsLongRight?"
    gen w = "|" + string(_n / 3) + "/"
    gen x = _N - _n
    gen y = _n / 2
    gen r = runiform()
    sort r
    drop r

    preserve
        greshape long st(.+)ub (foo|alice)([0-9]+)(bar|bob)/2, by(bykey) j(j) match(regex)
        greshape wide st@ub foobar ali9ce*bob, by(bykey) j(j)
        greshape long st(.+)ub (foo|ali9ce)([0-9]+)(bar|bob)/2, by(bykey) j(j) match(regex)
    restore, preserve
        if ( `c(stata_version)' >= 14 ) {
            greshape long (?<=st).+(?=ub) (?<=(foo|ali\d{0,5}ce))(\d+)(?=(bar|bob)), by(bykey) j(j) match(ustrregex)
            greshape wide stub foo@bar ali9ce@bob, by(bykey) j(j)
        }
    restore
end

***********************************************************************
*                             Basic Tests                             *
***********************************************************************

capture program drop checks_inner_greshape_wide
program checks_inner_greshape_wide
    args opts extras

    clear
    set obs 5
    gen i1 = _n
    gen i2 = -_n
    gen i3 = "why?" + string(mod(_n, 3))
    gen i4 = "hey" + string(-_n) + "thisIsWideRight?"
    gen ca = "constant | " + string(_n) + " | group "
    gen cb = int(20 * runiform())
    expand 3
    bys i?: gen j1 = mod(_n, 6)
    bys i?: gen j2 = "waffle" + string(mod(_n, 6))
    gen str10  x  = "some"
    replace    x  = "whenever" in 4/ 9
    replace    x  = "wherever" in 9/l
    gen str20  p  = "another long one" + string(mod(_n, 4))
    replace    p  = "this b"   in 3 / 7
    replace    p  = "this c"   in 11/l
    gen float  z  = _n
    replace    z  = runiform() in 4 / 8
    replace    z  = runiform() in 12/l
    gen double w  = _n * 3.14
    replace    w  = rnormal()  in 7/l
    gen int    y  = _n
    replace    y  = int(10 * runiform()) in 3/l

    if ( `"`extras'"' != "" ) local xi ca cb
    else drop ca cb

disp as err "    set 1 `xi'"
    * 1. Single num i
    preserve
        * 1.1 num xij
        keep i1 j1 z `xi'
        greshape wide z, i(i1) j(j1) `opts'
        l
    restore, preserve
        keep i1 j1 z `xi'
        greshape wide z, i(i1) j(j1) `opts'
        l
    restore, preserve
        keep i1 j1 w z `xi'
        greshape wide w z, i(i1) j(j1) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 j1 x `xi'
        greshape wide x, i(i1) j(j1) string `opts'
        l
    restore, preserve
        keep i1 j1 x p `xi'
        greshape wide x p, i(i1) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 j1 x z `xi'
        greshape wide x z, i(i1) j(j1) string `opts'
        l
    restore, preserve
        drop i2-i4 j2
        greshape wide p w x y z, i(i1) j(j1) string `opts'
        l
    restore

disp as err "    set 2 `xi'"
    preserve
        * 1.1 num xij
        keep i1 j2 z `xi'
        greshape wide z, i(i1) j(j2) `opts'
        l
    restore, preserve
        keep i1 j2 z `xi'
        greshape wide z, i(i1) j(j2) `opts'
        l
    restore, preserve
        keep i1 j2 w z `xi'
        greshape wide w z, i(i1) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 j2 x `xi'
        greshape wide x, i(i1) j(j2) string `opts'
        l
    restore, preserve
        keep i1 j2 x p `xi'
        greshape wide x p, i(i1) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 j2 x z `xi'
        greshape wide x z, i(i1) j(j2) string `opts'
        l
    restore, preserve
        drop i2-i4 j1 `xi'
        greshape wide p w x y z, i(i1) j(j2) string `opts'
        l
    restore

disp as err "    set 3 `xi'"
    * 2. Multiple num i
    preserve
        * 1.1 num xij
        keep i1 i2 j1 z `xi'
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i1 i2 j1 z `xi'
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i1 i2 j1 w z `xi'
        greshape wide w z, i(i?) j(j1) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 i2 j1 x `xi'
        greshape wide x, i(i?) j(j1) string `opts'
        l
    restore, preserve
        keep i1 i2 j1 x p `xi'
        greshape wide x p, i(i?) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 i2 j1 x z `xi'
        greshape wide x z, i(i?) j(j1) string `opts'
        l
    restore, preserve
        drop i3 i4 j2
        greshape wide p w x y z, i(i?) j(j1) string `opts'
        l
    restore

disp as err "    set 4 `xi'"
    preserve
        * 1.1 num xij
        keep i1 i2 j2 z `xi'
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i1 i2 j2 z `xi'
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i1 i2 j2 w z `xi'
        greshape wide w z, i(i?) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 i2 j2 x `xi'
        greshape wide x, i(i?) j(j2) string `opts'
        l
    restore, preserve
        keep i1 i2 j2 x p `xi'
        greshape wide x p, i(i?) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 i2 j2 x z `xi'
        greshape wide x z, i(i?) j(j2) string `opts'
        l
    restore, preserve
        drop i3 i4 j1
        greshape wide p w x y z, i(i?) j(j2) string `opts'
        l
    restore

disp as err "    set 5 `xi'"
    * 3. Single str i
    preserve
        * 1.1 num xij
        keep i4 j1 z `xi'
        greshape wide z, i(i4) j(j1) `opts'
        l
    restore, preserve
        keep i4 j1 z `xi'
        greshape wide z, i(i4) j(j1) `opts'
        l
    restore, preserve
        keep i4 j1 w z `xi'
        greshape wide w z, i(i4) j(j1) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i4 j1 x `xi'
        greshape wide x, i(i4) j(j1) string `opts'
        l
    restore, preserve
        keep i4 j1 x p `xi'
        greshape wide x p, i(i4) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i4 j1 x z `xi'
        greshape wide x z, i(i4) j(j1) string `opts'
        l
    restore, preserve
        drop i1-i3 j2
        greshape wide p w x y z, i(i4) j(j1) string `opts'
        l
    restore

disp as err "    set 6 `xi'"
    preserve
        * 1.1 num xij
        keep i4 j2 z `xi'
        greshape wide z, i(i4) j(j2) `opts'
        l
    restore, preserve
        keep i4 j2 z `xi'
        greshape wide z, i(i4) j(j2) `opts'
        l
    restore, preserve
        keep i4 j2 w z `xi'
        greshape wide w z, i(i4) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i4 j2 x `xi'
        greshape wide x, i(i4) j(j2) string `opts'
        l
    restore, preserve
        keep i4 j2 x p `xi'
        greshape wide x p, i(i4) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i4 j2 x z `xi'
        greshape wide x z, i(i4) j(j2) string `opts'
        l
    restore, preserve
        drop i1-i3 j1
        greshape wide p w x y z, i(i4) j(j2) string `opts'
        l
    restore

disp as err "    set 7 `xi'"
    * 4. Multiple str i
    preserve
        * 1.1 num xij
        keep i3 i4 j1 z `xi'
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i3 i4 j1 z `xi'
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i3 i4 j1 w z `xi'
        greshape wide w z, i(i?) j(j1) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i3 i4 j1 x `xi'
        greshape wide x, i(i?) j(j1) string `opts'
        l
    restore, preserve
        keep i3 i4 j1 x p `xi'
        greshape wide x p, i(i?) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i3 i4 j1 x z `xi'
        greshape wide x z, i(i?) j(j1) string `opts'
        l
    restore, preserve
        drop i1 i2 j2
        greshape wide p w x y z, i(i?) j(j1) string `opts'
        l
    restore

disp as err "    set 8 `xi'"
    preserve
        * 1.1 num xij
        keep i3 i4 j2 z `xi'
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i3 i4 j2 z `xi'
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i3 i4 j2 w z `xi'
        greshape wide w z, i(i?) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i3 i4 j2 x `xi'
        greshape wide x, i(i?) j(j2) string `opts'
        l
    restore, preserve
        keep i3 i4 j2 x p `xi'
        greshape wide x p, i(i?) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i3 i4 j2 x z `xi'
        greshape wide x z, i(i?) j(j2) string `opts'
        l
    restore, preserve
        drop i1 i2 j1
        greshape wide p w x y z, i(i?) j(j2) string `opts'
        l
    restore

disp as err "    set 9 `xi'"
    * 5. Mixed str i
    preserve
        * 1.1 num xij
        keep i? j1 z `xi'
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i? j1 z `xi'
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i? j1 w z `xi'
        greshape wide w z, i(i?) j(j1) `opts'
        l
    restore, preserve
        * 1.1 str xij
        keep i? j1 x `xi'
        greshape wide x, i(i?) j(j1) string `opts'
        l
    restore, preserve
        keep i? j1 x p `xi'
        greshape wide x p, i(i?) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i? j1 x z `xi'
        greshape wide x z, i(i?) j(j1) string `opts'
        l
    restore, preserve
        drop j2
        greshape wide p w x y z, i(i?) j(j1) string `opts'
        l
    restore

disp as err "    set 10 `xi'"
    preserve
        * 1.1 num xij
        keep i? j2 z `xi'
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i? j2 z `xi'
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i? j2 w z `xi'
        greshape wide w z, i(i?) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i? j2 x `xi'
        greshape wide x, i(i?) j(j2) string `opts'
        l
    restore, preserve
        keep i? j2 x p `xi'
        greshape wide x p, i(i?) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i? j2 x z `xi'
        greshape wide x z, i(i?) j(j2) string `opts'
        l
    restore, preserve
        drop j1
        greshape wide p w x y z, i(i?) j(j2) string `opts'
        l
    restore
end

capture program drop checks_inner_greshape_long
program checks_inner_greshape_long
    args opts extras

    clear
    set obs 5
    gen i1 = _n
    gen i2 = -_n
    gen i3 = "why?" + string(mod(_n, 3))
    gen i4 = "hey" + string(-_n) + "thisIsLongRight?"
    gen ca = "constant | " + string(_n) + " | group "
    gen cb = int(20 * runiform())
    gen str5   xa  = "some"
    gen str8   xb  = "whenever"
    gen str10  xd  = "wherever"
    gen str20  pa  = "another long one" + string(mod(_n, 4))
    gen str8   pb  = "this b"
    gen str10  pd  = "this c"
    gen long   z1  = _n
    gen float  z2  = runiform()
    gen float  zd  = runiform()
    gen float  w1  = _n * 3.14
    gen double w5  = rnormal()
    gen int    y2  = _n
    gen float  y7  = int(10 * runiform())

    if ( `"`extras'"' != "" ) local xi ca cb
    else drop ca cb

disp as err "    set 1 `xi'"
    * 1. Single num i
    preserve
        * 1.1 num xij
        keep i1 z1 z2 `xi'
        greshape long z, i(i1) j(j) `opts'
        l
    restore, preserve
        keep i1 z1 z2 `xi'
        greshape long z, i(i1) j(j) `opts' dropmiss
        l
    restore, preserve
        keep i1 w* z* `xi'
        greshape long w z, i(i1) j(j) `opts'
        l
    restore, preserve
        keep i1 w* z* `xi'
        greshape long w z, i(i1) j(j) `opts' dropmiss
        l
    restore, preserve
        * 1.2 str xij
        keep i1 x* `xi'
        greshape long x, i(i1) j(j) string `opts'
        l
    restore, preserve
        keep i1 x* `xi'
        greshape long x, i(i1) j(j) string `opts' dropmiss
        l
    restore, preserve
        keep i1 x* p* `xi'
        greshape long x p, i(i1) j(j) string `opts'
        l
    restore, preserve
        keep i1 x* p* `xi'
        greshape long x p, i(i1) j(j) string `opts' dropmiss
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 x* z* `xi'
        greshape long x z, i(i1) j(j) string `opts'
        l
    restore, preserve
        keep i1 x* z* `xi'
        greshape long x z, i(i1) j(j) string `opts' dropmiss
        l
    restore, preserve
        drop i2-i4
        greshape long p w x y z, i(i1) j(j) string `opts'
        l
    restore, preserve
        drop i2-i4
        greshape long p w x y z, i(i1) j(j) string `opts' dropmiss
        l
    restore

disp as err "    set 2 `xi'"
    * 2. Multiple num i
    preserve
        * 1.1 num xij
        keep i1 i2 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i1 i2 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts' dropmiss
        l
    restore, preserve
        keep i1 i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i1 i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts' dropmiss
        l
    restore, preserve
        * 1.2 str xij
        keep i1 i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i1 i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        keep i1 i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i1 i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i1 i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        drop i3 i4
        greshape long p w x y z, i(i?) j(j) string `opts'
        l
    restore, preserve
        drop i3 i4
        greshape long p w x y z, i(i?) j(j) string `opts' dropmiss
        l
    restore

disp as err "    set 3 `xi'"
    * 3. Single str i
    preserve
        * 1.1 num xij
        keep i4 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i4 i2 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts' dropmiss
        l
    restore, preserve
        keep i4 i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i4 i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts' dropmiss
        l
    restore, preserve
        * 1.2 str xij
        keep i4 i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i4 i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        keep i4 i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i4 i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        * 1.3 mix xij
        keep i4 i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i4 i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        drop i1 i2 i3
        greshape long p w x y z, i(i?) j(j) string `opts'
        l
    restore, preserve
        drop i1 i2 i3
        greshape long p w x y z, i(i?) j(j) string `opts' dropmiss
        l
    restore

disp as err "    set 4 `xi'"
    * 4. Multiple str i
    preserve
        * 1.1 num xij
        keep i3 i4 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i3 i4 i2 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts' dropmiss
        l
    restore, preserve
        keep i3 i4 i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i3 i4 i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts' dropmiss
        l
    restore, preserve
        * 1.2 str xij
        keep i3 i4 i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i3 i4 i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        keep i3 i4 i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i3 i4 i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        * 1.3 mix xij
        keep i3 i4 i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i3 i4 i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        drop i1 i2
        greshape long p w x y z, i(i?) j(j) string `opts'
        l
    restore, preserve
        drop i1 i2
        greshape long p w x y z, i(i?) j(j) string `opts' dropmiss
        l
    restore

disp as err "    set 5 `xi'"
    * 5. Mixed str i
    preserve
        * 1.1 num xij
        keep i? z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i? i2 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts' dropmiss
        l
    restore, preserve
        keep i? i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i? i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts' dropmiss
        l
    restore, preserve
        * 1.2 str xij
        keep i? i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i? i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        keep i? i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i? i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        * 1.3 mix xij
        keep i? i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i? i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts' dropmiss
        l
    restore, preserve
        greshape long p w x y z, i(i?) j(j) string `opts'
        l
    restore, preserve
        greshape long p w x y z, i(i?) j(j) string `opts' dropmiss
        l
    restore
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_greshape
program bench_greshape
    syntax, [tol(real 1e-6) bench(real 1) n(int 500) NOIsily *]

    qui gen_data, n(`n')
    qui expand `=100 * `bench''
    qui `noisily' random_draws, random(2) double
    qui hashsort random1
    gen long   ix_num = _n
    gen str    ix_str = "str" + string(_n)
    gen double ix_dbl = _pi + _n
    cap drop strL*

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    di as txt _n(1)
    di as txt "Benchmark vs reshape, obs = `N', J = `J' (in seconds)"
    di as txt " reshape | greshape | ratio (c/g) | varlist"
    di as txt " ------- | -------- | ----------- | -------"

    rename double? dbl?
    rename int?    num?

    versus_greshape dbl random,      j(_j) i(ix_num num1)
    versus_greshape dbl random,      j(_j) i(ix_num num1 num2)
    versus_greshape dbl random str_, j(_j) i(ix_num num1 num2 num3) string

    versus_greshape num random,      j(_j) i(ix_dbl dbl1)
    versus_greshape num random str_, j(_j) i(ix_dbl dbl1 dbl2 dbl3) string

    versus_greshape dbl num random, j(_j) i(ix_str str_32)
    versus_greshape dbl num random, j(_j) i(ix_str str_32 str_12 str_4) string

    di _n(1) "{hline 80}" _n(1) "bench_greshape, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop versus_greshape
program versus_greshape, rclass
    syntax [anything], [i(str) j(str) *]

    preserve
        timer clear
        timer on 42
        qui reshape long `anything', i(`i') j(`j') `options'
        timer off 42
        qui timer list
        local time_long = r(t42)
        tempfile a
        qui save `"`a'"'

        timer clear
        timer on 42
        qui reshape wide `anything', i(`i') j(`j') `options'
        timer off 42
        qui timer list
        local time_wide = r(t42)
        tempfile b
        qui save `"`b'"'
    restore

    preserve
        timer clear
        timer on 43
        qui greshape long `anything', i(`i') j(`j') `options' check(2)
        timer off 43
        qui timer list
        local time_glong = r(t43)
        cf * using `"`a'"'

        timer clear
        timer on 43
        qui greshape wide `anything', i(`i') j(`j') `options' check(2)
        timer off 43
        qui timer list
        local time_gwide = r(t43)
        cf * using `"`b'"'
    restore

    local rs = `time_long'  / `time_glong'
    di as txt " `:di %7.3g `time_long'' | `:di %8.3g `time_glong'' | `:di %11.4g `rs'' | long `anything', i(`i')"
    local rs = `time_wide'  / `time_gwide'
    di as txt " `:di %7.3g `time_wide'' | `:di %8.3g `time_gwide'' | `:di %11.4g `rs'' | wide `anything', i(`i')"
end

***********************************************************************
*                               Testing                               *
***********************************************************************
capture program drop checks_gregress
program checks_gregress
    basic_gregress
    coll_gregress
    exit 0
end

capture program drop basic_gregress
program basic_gregress
    local tol 1e-8

    * Temporary; testing out backing out the FE
    * -----------------------------------------
    *
    * global GTOOLS_BETA = 1
    *
    * clear
    * set obs 30
    * gen x = rnormal()
    * gen y = ((x + rnormal()/2) > 0)
    * gen a = mod(_n, 4)
    * tab a, gen(_a)
    * logit y x _a*, r noconstant
    * gglm y x, absorb(a) pred(_xbd_) family(binomial)
    * mata GtoolsLogit.print()
    * gegen _tag_ = tag(a)
    * mata editmissing(sort((st_data(., "a", "_tag_"), st_data(., "x _xbd_", "_tag_") * (-GtoolsLogit.b' \ 1)), 1), 0)
    * 
    * sysuse auto, clear
    * keep foreign price mpg rep78
    * tab rep78, gen(_rep78)
    * logit foreign price mpg _rep78*, r noconstant
    * gglm foreign price mpg, robust absorb(rep78) pred(_xbd_) family(binomial)
    * mata GtoolsLogit.print()
    * gegen _tag_ = tag(rep78)
    * mata editmissing(sort((st_data(., "rep78", "_tag_"), st_data(., "price mpg _xbd_", "_tag_") * (-GtoolsLogit.b' \ 1)), 1), 0)

disp ""
disp "----------------------"
disp "Comparison Test 1: OLS"
disp "----------------------"
disp ""

    sysuse auto, clear
    qui gen w = _n
    qui gegen headcode = group(headroom)
    qui gen z1 = 0
    qui gen z2 = 0

    foreach v in v1 v2 v5 v7 {
        local w
        local r

        if ( "`v'" == "v2" ) local w [fw = w]
        if ( "`v'" == "v4" ) local w [fw = w]

        if ( "`v'" == "v5" ) local w [aw = w]
        if ( "`v'" == "v6" ) local w [aw = w]

        if ( "`v'" == "v7" ) local w [pw = w]
        if ( "`v'" == "v8" ) local w [pw = w]

        disp "greg checks `v': `w'"

        qui greg price mpg `w', by(foreign) `r'
            qui reg price mpg if foreign == 0 `w'
            mata: assert(all(abs(st_matrix("r(table)")[1 ,.] :- GtoolsRegress.b[1, .]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2 ,.] :- GtoolsRegress.se[1, .]) :< `tol'))
            qui reg price mpg if foreign == 1 `w'
            mata: assert(all((abs(st_matrix("r(table)")[1 ,.] :- GtoolsRegress.b[2, .])) :< `tol'))
            mata: assert(all((abs(st_matrix("r(table)")[2 ,.] :- GtoolsRegress.se[2, .])) :< `tol'))
        qui greg price mpg `w', by(foreign) robust `r'
            qui reg price mpg if foreign == 0 `w', robust
            mata: assert(all(abs(st_matrix("r(table)")[1 ,.] :- GtoolsRegress.b[1, .]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2 ,.] :- GtoolsRegress.se[1, .]) :< `tol'))
            qui reg price mpg if foreign == 1 `w', robust
            mata: assert(all(abs(st_matrix("r(table)")[1 ,.] :- GtoolsRegress.b[2, .]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2 ,.] :- GtoolsRegress.se[2, .]) :< `tol'))
        qui greg price mpg `w', by(foreign) cluster(headroom) `r'
            qui reg price mpg if foreign == 0 `w', cluster(headcode)
            mata: assert(all(abs(st_matrix("r(table)")[1 ,.] :- GtoolsRegress.b[1, .]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2 ,.] :- GtoolsRegress.se[1, .]) :< `tol'))
            qui reg price mpg if foreign == 1 `w', cluster(headcode)
            mata: assert(all(abs(st_matrix("r(table)")[1 ,.] :- GtoolsRegress.b[2, .]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2 ,.] :- GtoolsRegress.se[2, .]) :< `tol'))

        qui greg price mpg `w', absorb(rep78)
            qui areg price mpg `w', absorb(rep78)
            mata: assert(all(abs(st_matrix("r(table)")[1, 1] :- GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2, 1] :- GtoolsRegress.se[1, 1]) :< `tol'))
        qui greg price mpg `w', absorb(rep78) robust
            qui areg price mpg `w', absorb(rep78) robust
            mata: assert(all(abs(st_matrix("r(table)")[1, 1] :- GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2, 1] :- GtoolsRegress.se[1, 1]) :< `tol'))
        qui greg price mpg `w', absorb(rep78) cluster(headroom)
            qui areg price mpg `w', absorb(rep78) cluster(headroom)
            mata: assert(all(abs(st_matrix("r(table)")[1, 1] :- GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(abs(st_matrix("r(table)")[2, 1] :- GtoolsRegress.se[1, 1]) :< `tol'))

        qui greg price mpg `w', by(foreign) absorb(rep78)
            qui areg price mpg if foreign == 0 `w', absorb(rep78)
            mata: assert(all(abs(`=_b[mpg]' :- GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(abs(`=_se[mpg]' :- GtoolsRegress.se[1, 1]) :< `tol'))
            qui areg price mpg if foreign == 1 `w', absorb(rep78)
            mata: assert(all(abs(`=_b[mpg]' :- GtoolsRegress.b[2, 1]) :< `tol'))
            mata: assert(all(abs(`=_se[mpg]' :- GtoolsRegress.se[2, 1]) :< `tol'))
        qui greg price mpg `w', by(foreign) absorb(rep78) robust
            qui areg price mpg if foreign == 0 `w', absorb(rep78) robust
            mata: assert(all(abs(`=_b[mpg]' :- GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(abs(`=_se[mpg]' :- GtoolsRegress.se[1, 1]) :< `tol'))
            qui areg price mpg if foreign == 1 `w', absorb(rep78) robust
            mata: assert(all(abs(`=_b[mpg]' :- GtoolsRegress.b[2, 1]) :< `tol'))
            mata: assert(all(abs(`=_se[mpg]' :- GtoolsRegress.se[2, 1]) :< `tol'))
        qui greg price mpg `w', by(foreign) absorb(rep78) cluster(headroom)
            qui areg price mpg if foreign == 0 `w', absorb(rep78) cluster(headroom)
            mata: assert(all(abs(`=_b[mpg]' :- GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(abs(`=_se[mpg]' :- GtoolsRegress.se[1, 1]) :< `tol'))
            qui areg price mpg if foreign == 1 `w', absorb(rep78) cluster(headroom)
            mata: assert(all(abs(`=_b[mpg]' :- GtoolsRegress.b[2, 1]) :< `tol'))
            mata: assert(all(abs(`=_se[mpg]' :- GtoolsRegress.se[2, 1]) :< `tol'))

        qui greg price mpg `w', absorb(rep78 headroom)
            qui reg price mpg i.rep78 i.headcode `w'
            mata: assert(all(abs(`=_b[mpg]' :- GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(abs(`=_se[mpg]' :- GtoolsRegress.se[1, 1]) :< `tol'))
        qui greg price mpg `w', absorb(rep78 headroom) robust
            qui reg price mpg i.rep78 i.headcode `w', robust
            mata: assert(all(abs(`=_b[mpg]' :- GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(abs(`=_se[mpg]' :- GtoolsRegress.se[1, 1]) :< `tol'))
        qui greg price mpg `w', absorb(rep78 headroom) cluster(headroom)
            qui reg price mpg i.rep78 i.headcode `w', vce(cluster headcode)
            mata: assert(all(abs(`=_b[mpg]' :- GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(abs(`=_se[mpg]' :- GtoolsRegress.se[1, 1]) :< `tol'))

        qui greg price mpg `w', by(foreign) absorb(rep78 headroom)
            qui reg price mpg i.rep78 i.headcode if foreign == 0 `w'
            mata: assert(all(reldif(`=_b[mpg]', GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(reldif(`=_se[mpg]', GtoolsRegress.se[1, 1]) :< `tol'))
            qui reg price mpg i.rep78 i.headcode if foreign == 1 `w'
            mata: assert(all(reldif(`=_b[mpg]', GtoolsRegress.b[2, 1]) :< `tol'))
            mata: assert(all(reldif(`=_se[mpg]', GtoolsRegress.se[2, 1]) :< `tol'))
        qui greg price mpg `w', by(foreign) absorb(rep78 headroom) robust
            qui reg price mpg i.rep78 i.headcode if foreign == 0 `w', robust
            mata: assert(all(reldif(`=_b[mpg]', GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(reldif(`=_se[mpg]', GtoolsRegress.se[1, 1]) :< `tol'))
            qui reg price mpg i.rep78 i.headcode if foreign == 1 `w', robust
            mata: assert(all(reldif(`=_b[mpg]', GtoolsRegress.b[2, 1]) :< `tol'))
            mata: assert(all(reldif(`=_se[mpg]', GtoolsRegress.se[2, 1]) :< `tol'))
        qui greg price mpg `w', by(foreign) absorb(rep78 headroom) cluster(headroom)
            qui reg price mpg i.rep78 i.headcode if foreign == 0 `w', cluster(headroom)
            mata: assert(all(reldif(`=_b[mpg]', GtoolsRegress.b[1, 1]) :< `tol'))
            mata: assert(all(reldif(`=_se[mpg]', GtoolsRegress.se[1, 1]) :< `tol'))
            qui reg price mpg i.rep78 i.headcode if foreign == 1 `w', cluster(headroom)
            mata: assert(all(reldif(`=_b[mpg]', GtoolsRegress.b[2, 1]) :< `tol'))
            mata: assert(all(reldif(`=_se[mpg]', GtoolsRegress.se[2, 1]) :< `tol'))
    }

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

disp ""
disp "---------------------"
disp "Comparison Test 2: IV"
disp "---------------------"
disp ""

    local tol 1e-6
    sysuse auto, clear
    gen w = _n
    gegen headcode = group(headroom)

    local v
    local w
    foreach v in v1 v2 v3 v4 {
        local w
        if ( "`v'" == "v2" ) local w [fw = w]
        if ( "`v'" == "v3" ) local w [aw = w]
        if ( "`v'" == "v4" ) local w [pw = w]
        disp "iv checks `v': `w'"

        foreach av in v1 v2 v3 {
            if ( `"`av'"' == "v1" ) local avars
            if ( `"`av'"' == "v2" ) local avars i.rep78
            if ( `"`av'"' == "v3" ) local avars i.rep78 i.headcode

            if ( `"`av'"' == "v1" ) local absorb
            if ( `"`av'"' == "v2" ) local absorb absorb(rep78)
            if ( `"`av'"' == "v3" ) local absorb absorb(rep78 headcode)

            foreach vce in small robust cluster(headcode) {
                local gvce  = cond(`"`vce'"' == "small", "", `"`vce'"')
                local small = cond(`"`vce'"' == "small", "", `"small"')
                disp _skip(4) "basic checks: `vce' `small' `absorb'"
                qui givregress price (mpg = gear_ratio) weight turn                            `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) weight turn `avars'      `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
disp _skip(8) "check 1"
                qui givregress price (mpg = gear_ratio) weight                                 `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) weight      `avars'      `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
disp _skip(8) "check 2"
                qui givregress price (mpg = gear_ratio)                                        `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio)             `avars'      `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
disp _skip(8) "check 3"
                if ( "`av'" == "v1" ) {
                qui givregress price (mpg = gear_ratio) weight                                 `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio) weight      `avars'      `w' , `vce' noc `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
disp _skip(8) "check 4"
                }
                qui givregress price (mpg = gear_ratio turn displacement) weight               `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn displacement) weight `avars' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
disp _skip(8) "check 5"
                qui givregress price (mpg = gear_ratio turn) weight                            `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn) weight `avars'      `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
disp _skip(8) "check 6"
                qui givregress price (mpg weight = gear_ratio turn)                            `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg weight = gear_ratio turn) `avars'      `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
disp _skip(8) "check 7"
                qui givregress price (mpg weight = gear_ratio turn) displacement               `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg weight = gear_ratio turn) displacement `avars' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
disp _skip(8) "check 8"
                qui givregress price (mpg weight = gear_ratio turn displacement)               `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg weight = gear_ratio turn displacement) `avars' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
disp _skip(8) "check 9"
            }
        }

        * expand 10
        * gen _by = mod(_n, 2)
        * local by by(_by)
        local by by(foreign)
        local if1 if foreign == 0
        local if2 if foreign == 1
        foreach av in v1 v2 v3 {
            if ( `"`av'"' == "v1" ) local avars
            if ( `"`av'"' == "v2" ) local avars i.rep78
            if ( `"`av'"' == "v3" ) local avars i.rep78 i.headcode

            if ( `"`av'"' == "v1" ) local absorb
            if ( `"`av'"' == "v2" ) local absorb absorb(rep78)
            if ( `"`av'"' == "v3" ) local absorb absorb(rep78 headcode)

            foreach vce in small robust cluster(headcode) {
                local gvce  = cond(`"`vce'"' == "small", "", `"`vce'"')
                local small = cond(`"`vce'"' == "small", "", `"small"')
                disp _skip(4) "`by' checks: `vce' `small' `absorb'"
                qui givregress price (mpg = gear_ratio) weight turn                            `w' , `gvce' `absorb' `by'
                    qui ivregress 2sls price (mpg = gear_ratio) weight turn `avars' `if1' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
                    qui ivregress 2sls price (mpg = gear_ratio) weight turn `avars' `if2' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[2, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[2, .]) :< `tol'))
disp _skip(8) "check 1"
                qui givregress price (mpg = gear_ratio) weight                                 `w' , `gvce' `absorb' `by'
                    qui ivregress 2sls price (mpg = gear_ratio) weight      `avars' `if1' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
                    qui ivregress 2sls price (mpg = gear_ratio) weight      `avars' `if2' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[2, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[2, .]) :< `tol'))
disp _skip(8) "check 2"
                qui givregress price (mpg = gear_ratio)                                        `w' , `gvce' `absorb' `by'
                    qui ivregress 2sls price (mpg = gear_ratio)             `avars' `if1' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
                    qui ivregress 2sls price (mpg = gear_ratio)             `avars' `if2' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[2, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[2, .]) :< `tol'))
disp _skip(8) "check 3"
                if ( "`av'" == "v1" ) {
                qui givregress price (mpg = gear_ratio) weight                                 `w' , `gvce' `absorb' noc `by'
                    qui ivregress 2sls price (mpg = gear_ratio) weight      `avars' `if1' `w' , `vce' noc `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
                    qui ivregress 2sls price (mpg = gear_ratio) weight      `avars' `if2' `w' , `vce' noc `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[2, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[2, .]) :< `tol'))
disp _skip(8) "check 4"
                }
                qui givregress price (mpg = gear_ratio turn displacement) weight               `w' , `gvce' `absorb' `by'
                    qui ivregress 2sls price (mpg = gear_ratio turn displacement) weight `avars' `if1' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
                    qui ivregress 2sls price (mpg = gear_ratio turn displacement) weight `avars' `if2' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[2, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[2, .]) :< `tol'))
disp _skip(8) "check 5"
                qui givregress price (mpg = gear_ratio turn) weight                            `w' , `gvce' `absorb' `by'
                    qui ivregress 2sls price (mpg = gear_ratio turn) weight `avars' `if1' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
                    qui ivregress 2sls price (mpg = gear_ratio turn) weight `avars' `if2' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[2, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[2, .]) :< `tol'))
disp _skip(8) "check 6"
                qui givregress price (mpg weight = gear_ratio turn)                            `w' , `gvce' `absorb' `by'
                    qui ivregress 2sls price (mpg weight = gear_ratio turn) `avars' `if1' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
                    qui ivregress 2sls price (mpg weight = gear_ratio turn) `avars' `if2' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[2, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[2, .]) :< `tol'))
disp _skip(8) "check 7"
                qui givregress price (mpg weight = gear_ratio turn) displacement               `w' , `gvce' `absorb' `by'
                    qui ivregress 2sls price (mpg weight = gear_ratio turn) displacement `avars' `if1' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
                    qui ivregress 2sls price (mpg weight = gear_ratio turn) displacement `avars' `if2' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[2, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[2, .]) :< `tol'))
disp _skip(8) "check 8"
                qui givregress price (mpg weight = gear_ratio turn displacement)               `w' , `gvce' `absorb' `by'
                    qui ivregress 2sls price (mpg weight = gear_ratio turn displacement) `avars' `if1' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[1, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[1, .]) :< `tol'))
                    qui ivregress 2sls price (mpg weight = gear_ratio turn displacement) `avars' `if2' `w' , `vce' `small'
                    mata: assert(all(reldif(st_matrix("r(table)")[1, 1..GtoolsIV.kx], GtoolsIV.b[2, .])  :< `tol'))
                    mata: assert(all(reldif(st_matrix("r(table)")[2, 1..GtoolsIV.kx], GtoolsIV.se[2, .]) :< `tol'))
disp _skip(8) "check 9"
            }
        }
    }

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

disp ""
disp "--------------------------"
disp "Comparison Test 3: Poisson"
disp "--------------------------"
disp ""

    local tol 1e-4
    webuse ships, clear
    * use /tmp/ships, clear
    qui expand 2
    qui gen by = 1.5 - (_n < _N / 2)
    qui gen w = _n
    foreach v in v1 v2 v5 {
        disp "poisson checks `v'"
        local w
        local r

        if ( "`v'" == "v2" ) local w [fw = w]
        if ( "`v'" == "v4" ) local w [fw = w]

        if ( "`v'" == "v5" ) local w [pw = w]
        if ( "`v'" == "v6" ) local w [pw = w]

        qui gglm accident op_75_79 co_65_69 co_70_74 co_75_79 `w', robust `r' family(poisson)
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', r
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4], t[1, cols(t)]
            mata se = t[2, 1::4], t[2, cols(t)]
            mata assert(max(reldif(b, GtoolsPoisson.b)) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se)) < `tol')
disp _skip(8) "check 1"
        qui gglm accident op_75_79 co_65_69 co_70_74 co_75_79 `w', cluster(ship) `r' family(poisson)
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', cluster(ship)
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4], t[1, cols(t)]
            mata se = t[2, 1::4], t[2, cols(t)]
            mata assert(max(reldif(b, GtoolsPoisson.b)) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se)) < `tol')
disp _skip(8) "check 2"
        qui gglm accident op_75_79 co_65_69 co_70_74 co_75_79 `w', by(by) robust `r' family(poisson)
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w' if by == 0.5, r
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4], t[1, cols(t)]
            mata se = t[2, 1::4], t[2, cols(t)]
            mata assert(max(reldif(b, GtoolsPoisson.b[1, .])) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se[1, .])) < `tol')
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w' if by == 1.5, r
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4], t[1, cols(t)]
            mata se = t[2, 1::4], t[2, cols(t)]
            mata assert(max(reldif(b, GtoolsPoisson.b[2, .])) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se[2, .])) < `tol')
disp _skip(8) "check 3"
        qui gglm accident op_75_79 co_65_69 co_70_74 co_75_79 `w', by(by) cluster(ship) `r' family(poisson)
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w' if by == 0.5, cluster(ship)
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4], t[1, cols(t)]
            mata se = t[2, 1::4], t[2, cols(t)]
            mata assert(max(reldif(b, GtoolsPoisson.b[1, .])) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se[1, .])) < `tol')
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w' if by == 1.5, cluster(ship)
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4], t[1, cols(t)]
            mata se = t[2, 1::4], t[2, cols(t)]
            mata assert(max(reldif(b, GtoolsPoisson.b[2, .])) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se[2, .])) < `tol')
disp _skip(8) "check 4"
        qui gglm accident op_75_79 co_65_69 co_70_74 co_75_79 `w', absorb(ship) r family(poisson)
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 i.ship `w', r
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4]
            mata se = t[2, 1::4]
            mata assert(max(reldif(b, GtoolsPoisson.b)) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se)) < `tol')
disp _skip(8) "check 5"
        qui gglm accident op_75_79 co_65_69 co_70_74 co_75_79 `w', absorb(ship) cluster(ship) family(poisson)
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 i.ship `w', cluster(ship)
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4]
            mata se = t[2, 1::4]
            mata assert(max(reldif(b, GtoolsPoisson.b)) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se)) < `tol')
disp _skip(8) "check 6"
        qui gglm accident op_75_79 co_65_69 co_70_74 co_75_79 `w', by(by) absorb(ship) robust family(poisson)
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 i.ship `w' if by == 0.5, r
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4]
            mata se = t[2, 1::4]
            mata assert(max(reldif(b, GtoolsPoisson.b[1, .])) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se[1, .])) < `tol')
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 i.ship `w' if by == 1.5, r
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4]
            mata se = t[2, 1::4]
            mata assert(max(reldif(b, GtoolsPoisson.b[2, .])) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se[2, .])) < `tol')
disp _skip(8) "check 7"
        qui gglm accident op_75_79 co_65_69 co_70_74 co_75_79 `w', by(by) absorb(ship) cluster(ship) family(poisson)
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 i.ship `w' if by == 0.5, cluster(ship)
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4]
            mata se = t[2, 1::4]
            mata assert(max(reldif(b, GtoolsPoisson.b[1, .])) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se[1, .])) < `tol')
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 i.ship `w' if by == 1.5, cluster(ship)
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4]
            mata se = t[2, 1::4]
            mata assert(max(reldif(b, GtoolsPoisson.b[2, .])) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se[2, .])) < `tol')
disp _skip(8) "check 8"
    }

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

disp ""
disp "--------------------------"
disp "Stress Test 1: Consistency"
disp "--------------------------"
disp ""
    qui {
        clear
        set obs 10000
        gen e = rnormal() * 50
        gen g = ceil(runiform()*100)
        forvalues i = 1 / 4 {
            gen x`i' = rnormal() * `i' + `i'
        }
        gen byte ones = 1
        gen y = 5 - 4 * x1 + 3 * x2 - 2 * x3 + x4 + g + e
        gen w = int(50 * runiform())
        areg y x1 x2 x3 x4, absorb(g)
        greg y x1 x2 x3 x4, absorb(g) mata(coefs)
        greg y x1 x2 x3 x4, absorb(g) prefix(hdfe(_hdfe_)) mata(coefs)
        greg y x1 x2 x3 x4, absorb(g) prefix(hdfe(_hdfe_)) replace
        greg y x1 x2 x3 x4, absorb(g) prefix(b(_b_))
        greg y x1 x2 x3 x4, absorb(g) prefix(se(_se_))
        greg y x1 x2 x3 x4, absorb(g) gen(b(_bx1 _bx2 _bx3 _bx4))
        greg y x1 x2 x3 x4, absorb(g) gen(hdfe(_hy _hx1 _hx2 _hx3 _hx4)) mata(levels, nob nose)
        greg y x1 x2 x3 x4, absorb(g) gen(se(_sex1 _sex2 _sex3 _sex4))
        assert (_hdfe_y == _hy)
        foreach var in x1 x2 x3 x4 {
            assert (_hdfe_`var' == _h`var')
            assert (_b_`var' == _b`var')
            assert (_se_`var' == _se`var')
        }

        drop _*
        areg y x1 x2 x3 x4 [fw = w], absorb(g)
        greg y x1 x2 x3 x4 [fw = w], absorb(g) mata(coefs)
        greg y x1 x2 x3 x4 [fw = w], absorb(g) prefix(hdfe(_hdfe_)) mata(coefs)
        greg y x1 x2 x3 x4 [fw = w], absorb(g) prefix(hdfe(_hdfe_)) replace
        greg y x1 x2 x3 x4 [fw = w], absorb(g) prefix(b(_b_))
        greg y x1 x2 x3 x4 [fw = w], absorb(g) prefix(se(_se_))
        greg y x1 x2 x3 x4 [fw = w], absorb(g) gen(b(_bx1 _bx2 _bx3 _bx4))
        greg y x1 x2 x3 x4 [fw = w], absorb(g) gen(hdfe(_hy _hx1 _hx2 _hx3 _hx4)) mata(levels, nob nose)
        greg y x1 x2 x3 x4 [fw = w], absorb(g) gen(se(_sex1 _sex2 _sex3 _sex4))
        assert (_hdfe_y == _hy)
        foreach var in x1 x2 x3 x4 {
            assert (_hdfe_`var' == _h`var')
            assert (_b_`var' == _b`var')
            assert (_se_`var' == _se`var')
        }
    }

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

disp ""
disp "-----------------------------------"
disp "Stress Test 2: 'Large' observations"
disp "-----------------------------------"
disp ""
    qui {
        clear
        set obs 10000000
        gen e = rnormal() * 20
        gen g = ceil(runiform()*100)
        forvalues i = 1 / 4 {
            gen x`i' = rnormal() * `i' + `i'
        }
        gen byte ones = 1
        gen y = 5 - 4 * x1 + 3 * x2 - 2 * x3 + x4 + e
        gen w = int(50 * runiform())

        greg y x1 x2 x3 x4, mata(r1)
        reg  y x1 x2 x3 x4
            mata: check_gregress_consistency(`tol', 1, 1::r1.kx, r1)
        greg y x1 x2 x3 x4, r mata(r1)
        reg  y x1 x2 x3 x4, r
            mata: check_gregress_consistency(`tol', 1, 1::r1.kx, r1)
        greg y x1 x2 x3 x4, cluster(g) mata(r1)
        reg  y x1 x2 x3 x4, vce(cluster g)
            mata: check_gregress_consistency(`tol', 1, 1::r1.kx, r1)
        greg y x1 x2 x3 x4, absorb(g) mata(r1)
        areg y x1 x2 x3 x4, absorb(g)
            mata: check_gregress_consistency(`tol', 1, 1::r1.kx, r1)

        greg y x1 x2 x3 x4 [fw = w], mata(r1)
        reg  y x1 x2 x3 x4 [fw = w]
            mata: check_gregress_consistency(`tol', 1, 1::r1.kx, r1)
        greg y x1 x2 x3 x4 [fw = w], mata(r1) r
        reg  y x1 x2 x3 x4 [fw = w], r
            mata: check_gregress_consistency(`tol', 1, 1::r1.kx, r1)
        greg y x1 x2 x3 x4 [fw = w], mata(r1) cluster(g)
        reg  y x1 x2 x3 x4 [fw = w], vce(cluster g)
            mata: check_gregress_consistency(`tol', 1, 1::r1.kx, r1)
        greg y x1 x2 x3 x4 [fw = w], mata(r1) absorb(g)
        areg y x1 x2 x3 x4 [fw = w], absorb(g)
            mata: check_gregress_consistency(`tol', 1, 1::r1.kx, r1)
    }

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

    if ( `c(MP)' ) {
disp ""
disp "---------------------------"
disp "Stress Test 3: 'Wide' model"
disp "---------------------------"
disp ""
        qui {
            clear
            clear matrix
            set matsize 10000
            set obs 50000
            gen g = ceil(runiform()*10)
            gen e = rnormal() * 5
            forvalues i = 1 / 500 {
                gen x`i' = rnormal() * `i' + `i'
            }
            gen y = - 4 * x1 + 3 * x2 - 2 * x3 + x4 + e

            * Slower with all the vars, but no longer unreasonably so
            greg y x*, mata(r1) v bench(3)
            reg  y x*
                mata: check_gregress_consistency(`tol', 1, 1::r1.kx, r1)
            greg y x*, mata(r1) v bench(3) cluster(g)
            reg  y x*, vce(cluster g)
                mata: check_gregress_consistency(`tol', 1, 1::r1.kx, r1)
        }
    }

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

    * clear
    * local N 1000000
    * local G 10000
    * set rmsg on
    * set obs `N'
    * gen g1 = int(runiform() * `G')
    * gen g2 = int(runiform() * `G')
    * gen g3 = int(runiform() * `G')
    * gen g4 = int(runiform() * `G')
    * gen x1 = runiform()
    * gen x2 = runiform()
    * gen y  = 0.25 * x1 - 0.75 * x2 + g1 + g2 + g3 + 20 * rnormal()
    * gen w  = int(50 * runiform())
    *
    * reghdfe y x1 x2, absorb(g1 g2 g3)
    * greg y x1 x2, absorb(g1 g2 g3) mata(greg)
    * mata greg.print()
    *
    * reghdfe y x1 x2, absorb(g1 g2 g3) vce(robust)
    * greg y x1 x2, absorb(g1 g2 g3) mata(greg) r
    * mata greg.print()
    *
    * reghdfe y x1 x2, absorb(g1 g2 g3) vce(cluster g4)
    * greg y x1 x2, absorb(g1 g2 g3) cluster(g4) mata(greg)
    * mata greg.print()
    *
    * reghdfe y x1 x2 [fw = w], absorb(g1 g2 g3)
    * greg y x1 x2 [fw = w], absorb(g1 g2 g3) mata(greg)
    * mata greg.print()
    *
    * reghdfe y x1 x2 [fw = w], absorb(g1 g2 g3) vce(robust)
    * greg y x1 x2 [fw = w], absorb(g1 g2 g3) mata(greg) r
    * mata greg.print()
    *
    * reghdfe y x1 x2 [fw = w], absorb(g1 g2 g3) vce(cluster g4)
    * greg y x1 x2 [fw = w], absorb(g1 g2 g3) cluster(g4) mata(greg)
    * mata greg.print()
    *
    * reghdfe y x1 x2 [aw = w], absorb(g1 g2 g3)
    * greg y x1 x2 [aw = w], absorb(g1 g2 g3) mata(greg)
    * mata greg.print()
    *
    * reghdfe y x1 x2 [aw = w], absorb(g1 g2 g3) vce(robust)
    * greg y x1 x2 [aw = w], absorb(g1 g2 g3) mata(greg) r
    * mata greg.print()
    *
    * reghdfe y x1 x2 [aw = w], absorb(g1 g2 g3) vce(cluster g4)
    * greg y x1 x2 [aw = w], absorb(g1 g2 g3) cluster(g4) mata(greg)
    * mata greg.print()

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

    * Well, there is an issue when the number of absorbed effects are
    * close to the number of observations ):
end

capture program drop coll_gregress
program coll_gregress
    local tol 1e-8

disp ""
disp "------------------------"
disp "Collinearity Test 1: OLS"
disp "------------------------"
disp ""

    sysuse auto, clear
    qui gen w = _n
    qui gegen headcode = group(headroom)
    qui gen z1 = 0
    qui gen z2 = 0
    qui tab headcode, gen(_h)

    foreach v in v1 v2 v5 v7 {
        local w
        local r

        if ( "`v'" == "v2" ) local w [fw = w]
        if ( "`v'" == "v4" ) local w [fw = w]

        if ( "`v'" == "v5" ) local w [aw = w]
        if ( "`v'" == "v6" ) local w [aw = w]

        if ( "`v'" == "v7" ) local w [pw = w]
        if ( "`v'" == "v8" ) local w [pw = w]

        disp "greg checks `v': `w'"

        qui greg price mpg mpg `w', by(foreign) `r'
            qui reg price mpg mpg if foreign == 0 `w'
            mata: check_gregress_consistency(`tol', 1, ., GtoolsRegress)
            qui reg price mpg mpg if foreign == 1 `w'
            mata: check_gregress_consistency(`tol', 2, ., GtoolsRegress)
        qui greg price mpg mpg mpg `w', by(foreign) robust `r'
            qui reg price mpg mpg mpg if foreign == 0 `w', robust
            mata: check_gregress_consistency(`tol', 1, ., GtoolsRegress)
            qui reg price mpg mpg mpg if foreign == 1 `w', robust
            mata: check_gregress_consistency(`tol', 2, ., GtoolsRegress)
        qui greg price mpg mpg `w', by(foreign) cluster(headroom) `r'
            qui reg price mpg mpg if foreign == 0 `w', cluster(headcode)
            mata: check_gregress_consistency(`tol', 1, ., GtoolsRegress)
            qui reg price mpg mpg if foreign == 1 `w', cluster(headcode)
            mata: check_gregress_consistency(`tol', 2, ., GtoolsRegress)

        qui greg price mpg mpg `w', absorb(rep78)
            qui areg price mpg mpg `w', absorb(rep78)
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
        qui greg price mpg mpg `w', absorb(rep78) robust
            qui areg price mpg mpg `w', absorb(rep78) robust
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
        qui greg price mpg mpg `w', absorb(rep78) cluster(headroom)
            qui areg price mpg mpg `w', absorb(rep78) cluster(headroom)
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)

        qui greg price mpg mpg `w', by(foreign) absorb(rep78)
            qui areg price mpg mpg if foreign == 0 `w', absorb(rep78)
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
            qui areg price mpg mpg if foreign == 1 `w', absorb(rep78)
            mata: check_gregress_consistency(`tol', 2, 1::2, GtoolsRegress)
        qui greg price mpg mpg `w', by(foreign) absorb(rep78) robust
            qui areg price mpg mpg if foreign == 0 `w', absorb(rep78) robust
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
            qui areg price mpg mpg if foreign == 1 `w', absorb(rep78) robust
            mata: check_gregress_consistency(`tol', 2, 1::2, GtoolsRegress)
        qui greg price mpg mpg `w', by(foreign) absorb(rep78) cluster(headroom)
            qui areg price mpg mpg if foreign == 0 `w', absorb(rep78) cluster(headroom)
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
            qui areg price mpg mpg if foreign == 1 `w', absorb(rep78) cluster(headroom)
            mata: check_gregress_consistency(`tol', 2, 1::2, GtoolsRegress)

        cap drop _*
        qui tab headroom, gen(_h)
        qui greg price mpg mpg _h* `w', absorb(rep78 headroom)
            qui reg price mpg mpg i.rep78 i.headcode `w'
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
        qui greg price mpg mpg _h* `w', absorb(rep78 headroom) robust
            qui reg price mpg mpg i.rep78 i.headcode `w', robust
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
        qui greg price mpg mpg _h* `w', absorb(rep78 headroom) cluster(headroom)
            qui reg price mpg mpg i.rep78 i.headcode `w', vce(cluster headcode)
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)

        qui greg price mpg mpg _h* `w', by(foreign) absorb(rep78 headroom)
            qui reg price mpg mpg i.rep78 i.headcode if foreign == 0 `w'
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
            qui reg price mpg mpg i.rep78 i.headcode if foreign == 1 `w'
            mata: check_gregress_consistency(`tol', 2, 1::2, GtoolsRegress)
        qui greg price mpg mpg _h* `w', by(foreign) absorb(rep78 headroom) robust
            qui reg price mpg mpg i.rep78 i.headcode if foreign == 0 `w', robust
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
            qui reg price mpg mpg i.rep78 i.headcode if foreign == 1 `w', robust
            mata: check_gregress_consistency(`tol', 2, 1::2, GtoolsRegress)
        qui greg price mpg mpg _h* `w', by(foreign) absorb(rep78 headroom) cluster(headroom)
            qui reg price mpg mpg i.rep78 i.headcode if foreign == 0 `w', cluster(headroom)
            mata: check_gregress_consistency(`tol', 1, 1::2, GtoolsRegress)
            qui reg price mpg mpg i.rep78 i.headcode if foreign == 1 `w', cluster(headroom)
            mata: check_gregress_consistency(`tol', 2, 1::2, GtoolsRegress)

        qui greg price z1 z2 `w', `r' noc
            mata assert(all(GtoolsRegress.b  :== 0))
            mata assert(all(GtoolsRegress.se :== .))
        qui greg price _h* `w', `r' absorb(headroom) noc
            mata assert(all(GtoolsRegress.b  :== 0))
            mata assert(all(GtoolsRegress.se :== .))
    }

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

disp ""
disp "-----------------------"
disp "Collinearity Test 2: IV"
disp "-----------------------"
disp ""

    local tol 1e-6
    sysuse auto, clear
    gen w = _n
    gegen headcode = group(headroom)
    cap drop _*
    qui tab headcode, gen(_h)
    qui tab rep78,    gen(_r)
    qui gen _mpg          = mpg
    qui gen _mpg2         = mpg
    qui gen _mpg3         = mpg
    qui gen _price        = price
    qui gen _price2       = price
    qui gen _gear_ratio   = gear_ratio
    qui gen _weight       = weight
    qui gen _turn         = turn
    qui gen _displacement = displacement
    qui gen z1 = 0
    qui gen z2 = 0

    * Colinearity foo
    *
    * 1. Within
    *     - instrumented
    *     - instrument
    *     - exogenous
    *
    * 2. Across
    *     - (!) dependenet variable _and_ instrumented
    *     - (!) dependenet variable _and_ instrument
    *     - (!) dependenet variable _and_ exogenous
    *     - instrumented _and_ instrument
    *     - instrumented _and_ exogenous
    *     - instrument _and_ exogenous
    *
    * 3. Mixed Across
    *
    *     - dependenet _and_ instrumented _and_ instrument
    *     - dependenet _and_ instrumented _and_ exogenous
    *     - dependenet _and_ instrument _and_ exogenous
    *     - instrumented _and_ instrument _and_ exogenous

    local v
    local w
    foreach v in v1 v2 v3 v4 {
        local w
        if ( "`v'" == "v2" ) local w [fw = w]
        if ( "`v'" == "v3" ) local w [aw = w]
        if ( "`v'" == "v4" ) local w [pw = w]
        disp "iv checks `v': `w'"

        foreach av in v1 v2 v3 {
            if ( `"`av'"' == "v1" ) local avars
            if ( `"`av'"' == "v2" ) local avars ibn.rep78
            if ( `"`av'"' == "v3" ) local avars ibn.rep78 ibn.headcode

            if ( `"`av'"' == "v1" ) local absorb
            if ( `"`av'"' == "v2" ) local absorb absorb(rep78)
            if ( `"`av'"' == "v3" ) local absorb absorb(rep78 headcode)

            if ( `"`av'"' == "v1" ) local dvars
            if ( `"`av'"' == "v2" ) unab  dvars: _r*
            if ( `"`av'"' == "v3" ) unab  dvars: _r* _h*

            foreach vce in small robust cluster(headcode) {
                local gvce  = cond(`"`vce'"' == "small", "", `"`vce'"')
                local small = cond(`"`vce'"' == "small", "", `"small"')
                disp _skip(4) "basic checks: `vce' `small' `absorb'"

                qui givregress price (mpg = gear_ratio _gear_ratio) weight turn                       `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio) weight turn       `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio displacement) weight turn                 `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement) weight turn `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) weight _weight turn                           `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) weight _weight turn           `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio) weight turn                                `w' , `gvce' `absorb'
                qui givregress price (mpg = gear_ratio  _price) weight turn                           `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _price) weight turn            `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _price weight turn                            `w' , `gvce' `absorb'
                qui givregress price (mpg = _mpg) weight turn                                         `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg) weight turn                              `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight turn              `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg weight turn                              `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight turn              `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio weight turn                       `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio displacement) _gear_ratio weight turn                 `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio weight turn `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio displacement _price2) weight turn       `w' , `gvce' `absorb'
                qui givregress price (mpg _price = gear_ratio displacement) _price2 weight turn       `w' , `gvce' `absorb'
                qui givregress price (mpg = _price gear_ratio displacement) _price2 weight turn       `w' , `gvce' `absorb'
                qui givregress price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight turn                  `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight turn  `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 1"

                qui givregress price (mpg = gear_ratio _gear_ratio) weight                            `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio) weight            `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio displacement) weight                      `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement) weight      `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) weight _weight                                `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) weight _weight                `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio) weight                                     `w' , `gvce' `absorb'
                qui givregress price (mpg = gear_ratio  _price) weight                                `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _price) weight                 `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _price weight                                 `w' , `gvce' `absorb'
                qui givregress price (mpg = _mpg) weight                                              `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg) weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio weight                            `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio displacement) _gear_ratio weight                      `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio weight      `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio displacement _price2) weight            `w' , `gvce' `absorb'
                qui givregress price (mpg _price = gear_ratio displacement) _price2 weight            `w' , `gvce' `absorb'
                qui givregress price (mpg = _price gear_ratio displacement) _price2 weight            `w' , `gvce' `absorb'
                qui givregress price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight                       `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight       `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 2"

                qui givregress price (mpg = gear_ratio _gear_ratio)                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio)                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio displacement)                             `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement)             `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio)                                               `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio)                               `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio)                                            `w' , `gvce' `absorb'
                qui givregress price (mpg = gear_ratio  _price)                                       `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _price)                        `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _price                                        `w' , `gvce' `absorb'
                qui givregress price (mpg = _mpg)                                                     `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg)                                          `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _mpg)                          `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg                                          `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg                          `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio                                   `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio displacement) _gear_ratio                             `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio             `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio displacement _price2)                   `w' , `gvce' `absorb'
                qui givregress price (mpg _price = gear_ratio displacement) _price2                   `w' , `gvce' `absorb'
                qui givregress price (mpg = _price gear_ratio displacement) _price2                   `w' , `gvce' `absorb'
                qui givregress price (mpg _mpg = _mpg2 gear_ratio) _mpg3                              `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3              `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 3"

                if ( "`av'" == "v1" ) {
                qui givregress price (mpg = gear_ratio _gear_ratio) weight                            `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio) weight            `avars' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio displacement) weight                      `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement) weight      `avars' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) weight _weight                                `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio) weight _weight                `avars' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio) weight                                     `w' , `gvce' `absorb' noc
                qui givregress price (mpg = gear_ratio  _price) weight                                `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio _price) weight                 `avars' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _price weight                                 `w' , `gvce' `absorb' noc
                qui givregress price (mpg = _mpg) weight                                              `w' , `gvce' `absorb' noc
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg) weight                                   `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight                   `avars' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg weight                                   `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight                   `avars' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio weight                            `w' , `gvce' `absorb' noc
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio displacement) _gear_ratio weight                      `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio weight      `avars' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio displacement _price2) weight            `w' , `gvce' `absorb' noc
                qui givregress price (mpg _price = gear_ratio displacement) _price2 weight            `w' , `gvce' `absorb' noc
                qui givregress price (mpg = _price gear_ratio displacement) _price2 weight            `w' , `gvce' `absorb' noc
                qui givregress price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight                       `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight       `avars' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 4"
                }

                qui givregress price (mpg = gear_ratio turn _gear_ratio length) weight                            `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn _gear_ratio length) weight            `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio turn length displacement) weight                      `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = gear_ratio turn length displacement) weight      `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio turn length) weight _weight                                `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length) weight _weight                `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio turn length) weight                                     `w' , `gvce' `absorb'
                qui givregress price (mpg = gear_ratio turn length  _price) weight                                `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length _price) weight                 `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio turn length) _price weight                                 `w' , `gvce' `absorb'
                qui givregress price (mpg = _mpg) weight                                              `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio turn length _mpg) weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length _mpg) weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio turn length) _mpg weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length) _mpg weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio turn) _turn _gear_ratio weight                             `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio turn length displacement) _gear_ratio weight                      `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length displacement) _gear_ratio weight      `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio turn length displacement _price2) weight            `w' , `gvce' `absorb'
                qui givregress price (mpg _price = gear_ratio turn length displacement) _price2 weight            `w' , `gvce' `absorb'
                qui givregress price (mpg = _price gear_ratio turn length displacement) _price2 weight            `w' , `gvce' `absorb'
                qui givregress price (mpg _mpg = _mpg2 gear_ratio turn length) _mpg3 weight                       `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio turn length) _mpg3 weight       `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 5"

                qui givregress price (mpg length = gear_ratio _gear_ratio turn) weight                            `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _gear_ratio turn) weight            `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length _mpg = gear_ratio displacement turn) weight                      `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = gear_ratio displacement turn) weight      `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) weight _weight                                `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) weight _weight                `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio turn) weight                                     `w' , `gvce' `absorb'
                qui givregress price (mpg length = gear_ratio  _price turn) weight                                `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _price turn) weight                 `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _price weight                                 `w' , `gvce' `absorb'
                qui givregress price (mpg _turn = _mpg turn) weight                                              `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio _mpg turn) weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _mpg weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _mpg weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _gear_ratio weight                            `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio displacement turn) _gear_ratio weight                      `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio displacement turn) _gear_ratio weight      `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length _price = gear_ratio displacement _price2 turn) weight            `w' , `gvce' `absorb'
                qui givregress price (mpg length _price = gear_ratio displacement turn) _price2 weight            `w' , `gvce' `absorb'
                qui givregress price (mpg length = _price gear_ratio displacement turn) _price2 weight            `w' , `gvce' `absorb'
                qui givregress price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight                       `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight       `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 7"

                qui givregress price (mpg length = gear_ratio _gear_ratio turn) _displacement weight                            `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _gear_ratio turn) _displacement weight            `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length _mpg = gear_ratio displacement turn) _displacement weight                      `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = gear_ratio displacement turn) _displacement weight      `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _displacement weight _weight                                `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement weight _weight                `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio turn) weight                                     `w' , `gvce' `absorb'
                qui givregress price (mpg length = gear_ratio  _price turn) _displacement weight                                `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _price turn) _displacement weight                 `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _displacement _price weight                                 `w' , `gvce' `absorb'
                qui givregress price (mpg _turn = _mpg turn) _displacement weight                                              `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio _mpg turn) _displacement weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) _displacement weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _displacement _mpg weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement _mpg weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _displacement _gear_ratio weight                            `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio turn displacement trunk) _displacement _gear_ratio weight                      `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn displacement trunk) _displacement _gear_ratio weight      `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length _price = gear_ratio displacement _price2 turn) _displacement weight            `w' , `gvce' `absorb'
                qui givregress price (mpg length _price = gear_ratio displacement turn) _displacement _price2 weight            `w' , `gvce' `absorb'
                qui givregress price (mpg length = _price gear_ratio displacement turn) _displacement _price2 weight            `w' , `gvce' `absorb'
                qui givregress price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight                       `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight       `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 8"

                if ( inlist(`"`av'"', "v2", "v3") ) {
                qui givregress price (mpg length = gear_ratio _gear_ratio turn) _displacement `dvars' weight                        `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _gear_ratio turn) _displacement `dvars' weight        `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length _mpg = gear_ratio displacement turn) _displacement `dvars' weight                  `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = gear_ratio displacement turn) _displacement `dvars' weight  `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 5::`=4 + `:list sizeof dvars'')
                qui givregress price (mpg length = gear_ratio turn) _displacement `dvars' weight _weight                            `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement `dvars' weight _weight            `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (_price = gear_ratio turn) weight                                                          `w' , `gvce' `absorb'
                qui givregress price (mpg length = gear_ratio  _price turn) _displacement `dvars' weight                            `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _price turn) _displacement `dvars' weight             `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length = gear_ratio turn) _displacement _price `dvars' weight                         `w' , `gvce' `absorb'
                qui givregress price (mpg _turn = _mpg turn) _displacement weight                                               `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio _mpg turn) _displacement `dvars' weight                               `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) _displacement `dvars' weight               `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length = gear_ratio turn) _displacement _mpg `dvars' weight                               `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement `dvars' _mpg weight               `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length = gear_ratio turn) _displacement _gear_ratio `dvars' weight                        `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio turn displacement trunk) _displacement `dvars' _gear_ratio weight                 `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn displacement trunk) _displacement `dvars' _gear_ratio weight `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length _price = gear_ratio displacement _price2 turn) _displacement `dvars' weight        `w' , `gvce' `absorb'
                qui givregress price (mpg length _price = gear_ratio displacement turn) _displacement `dvars' _price2 weight        `w' , `gvce' `absorb'
                qui givregress price (mpg length = _price gear_ratio displacement turn) _displacement `dvars' _price2 weight        `w' , `gvce' `absorb'
                qui givregress price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 `dvars' weight                                 `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 `dvars' weight                 `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 5::`=4 + `:list sizeof dvars'')
disp _skip(8) "check 10"
                }

                qui givregress price (z1 = gear_ratio _gear_ratio) weight turn    `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (z1 z2 = gear_ratio _gear_ratio) weight turn `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = z1 z2) weight turn                    `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))                           
                    mata assert(all(GtoolsIV.se :== .))                           
                qui givregress price (z1 = z2) weight turn                        `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio) z1 z2                     `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio) z1 z2     `avars' `w' , `vce' `small' noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 11"
            }
        }

        * expand 10
        * gen _by = mod(_n, 2)
        * local by by(_by)
        qui expand 2, gen(_expand)
        local by by(foreign)
        local if1 if foreign == 0
        local if2 if foreign == 1
        foreach av in v1 v2 v3 {
            if ( `"`av'"' == "v1" ) local avars
            if ( `"`av'"' == "v2" ) local avars ibn.rep78
            if ( `"`av'"' == "v3" ) local avars ibn.rep78 ibn.headcode

            if ( `"`av'"' == "v1" ) local absorb
            if ( `"`av'"' == "v2" ) local absorb absorb(rep78)
            if ( `"`av'"' == "v3" ) local absorb absorb(rep78 headcode)

            if ( `"`av'"' == "v1" ) local dvars
            if ( `"`av'"' == "v2" ) unab  dvars: _r*
            if ( `"`av'"' == "v3" ) unab  dvars: _r* _h*

            foreach vce in small robust cluster(headcode) {
                local gvce  = cond(`"`vce'"' == "small", "", `"`vce'"')
                local small = cond(`"`vce'"' == "small", "", `"small"')
                disp _skip(4) "`by' checks: `vce' `small' `absorb'"

                qui givregress price (mpg = gear_ratio _gear_ratio) weight turn                       `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio) weight turn       `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio) weight turn       `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio displacement) weight turn                 `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement) weight turn `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement) weight turn `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) weight _weight turn                           `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) weight _weight turn           `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio) weight _weight turn           `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio) weight turn                                `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = gear_ratio  _price) weight turn                           `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _price) weight turn            `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _price) weight turn            `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _price weight turn                            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = _mpg) weight turn                                         `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg) weight turn                              `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight turn              `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight turn              `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg weight turn                              `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight turn              `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight turn              `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio weight turn                       `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio displacement) _gear_ratio weight turn                 `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio weight turn `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio weight turn `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio displacement _price2) weight turn       `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _price = gear_ratio displacement) _price2 weight turn       `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = _price gear_ratio displacement) _price2 weight turn       `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight turn                  `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight turn  `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight turn  `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 1"

                qui givregress price (mpg = gear_ratio _gear_ratio) weight                            `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio) weight            `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio) weight            `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio displacement) weight                      `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement) weight      `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement) weight      `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) weight _weight                                `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) weight _weight                `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio) weight _weight                `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio) weight                                     `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = gear_ratio  _price) weight                                `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _price) weight                 `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _price) weight                 `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _price weight                                 `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = _mpg) weight                                              `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg) weight                                   `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight                   `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight                   `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg weight                                   `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight                   `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight                   `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio weight                            `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio displacement) _gear_ratio weight                      `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio weight      `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio weight      `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio displacement _price2) weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _price = gear_ratio displacement) _price2 weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = _price gear_ratio displacement) _price2 weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight                       `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight       `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight       `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 2"

                qui givregress price (mpg = gear_ratio _gear_ratio)                                   `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio)                   `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio)                   `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio displacement)                             `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement)             `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement)             `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio)                                               `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio)                               `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio)                               `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio)                                            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = gear_ratio  _price)                                       `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _price)                        `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _price)                        `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _price                                        `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = _mpg)                                                     `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg)                                          `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _mpg)                          `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _mpg)                          `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg                                          `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg                          `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg                          `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio                                   `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio displacement) _gear_ratio                             `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio             `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio             `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio displacement _price2)                   `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _price = gear_ratio displacement) _price2                   `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = _price gear_ratio displacement) _price2                   `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _mpg = _mpg2 gear_ratio) _mpg3                              `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3              `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3              `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 3"

                if ( "`av'" == "v1" ) {
                qui givregress price (mpg = gear_ratio _gear_ratio) weight                            `w' , `by' `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio) weight            `avars' `w' `if1', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _gear_ratio) weight            `avars' `w' `if2', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio displacement) weight                      `w' , `by' `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement) weight      `avars' `w' `if1', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = gear_ratio displacement) weight      `avars' `w' `if2', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) weight _weight                                `w' , `by' `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio) weight _weight                `avars' `w' `if1', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio) weight _weight                `avars' `w' `if2', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio) weight                                     `w' , `by' `gvce' `absorb' noc
                qui givregress price (mpg = gear_ratio  _price) weight                                `w' , `by' `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio _price) weight                 `avars' `w' `if1', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _price) weight                 `avars' `w' `if2', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _price weight                                 `w' , `by' `gvce' `absorb' noc
                qui givregress price (mpg = _mpg) weight                                              `w' , `by' `gvce' `absorb' noc
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg) weight                                   `w' , `by' `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight                   `avars' `w' `if1', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight                   `avars' `w' `if2', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg weight                                   `w' , `by' `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight                   `avars' `w' `if1', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight                   `avars' `w' `if2', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio weight                            `w' , `by' `gvce' `absorb' noc
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio displacement) _gear_ratio weight                      `w' , `by' `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio weight      `avars' `w' `if1', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio displacement) _gear_ratio weight      `avars' `w' `if2', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio displacement _price2) weight            `w' , `by' `gvce' `absorb' noc
                qui givregress price (mpg _price = gear_ratio displacement) _price2 weight            `w' , `by' `gvce' `absorb' noc
                qui givregress price (mpg = _price gear_ratio displacement) _price2 weight            `w' , `by' `gvce' `absorb' noc
                qui givregress price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight                       `w' , `by' `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight       `avars' `w' `if1', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio) _mpg3 weight       `avars' `w' `if2', `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 4"
                }

                qui givregress price (mpg = gear_ratio turn _gear_ratio length) weight                            `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn _gear_ratio length) weight            `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio turn _gear_ratio length) weight            `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _mpg = gear_ratio turn length displacement) weight                      `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = gear_ratio turn length displacement) weight      `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = gear_ratio turn length displacement) weight      `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio turn length) weight _weight                                `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length) weight _weight                `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio turn length) weight _weight                `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio turn length) weight                                     `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = gear_ratio turn length  _price) weight                                `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length _price) weight                 `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio turn length _price) weight                 `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio turn length) _price weight                                 `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = _mpg) weight                                              `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio turn length _mpg) weight                                   `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length _mpg) weight                   `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio turn length _mpg) weight                   `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio turn length) _mpg weight                                   `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length) _mpg weight                   `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio turn length) _mpg weight                   `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio turn) _turn _gear_ratio weight                             `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio turn length displacement) _gear_ratio weight                      `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length displacement) _gear_ratio weight      `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio turn length displacement) _gear_ratio weight      `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg _price = gear_ratio turn length displacement _price2) weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _price = gear_ratio turn length displacement) _price2 weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg = _price gear_ratio turn length displacement) _price2 weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _mpg = _mpg2 gear_ratio turn length) _mpg3 weight                       `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio turn length) _mpg3 weight       `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg _mpg = _mpg2 gear_ratio turn length) _mpg3 weight       `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 5"

                qui givregress price (mpg length = gear_ratio _gear_ratio turn) weight                            `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _gear_ratio turn) weight            `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio _gear_ratio turn) weight            `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length _mpg = gear_ratio displacement turn) weight                      `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = gear_ratio displacement turn) weight      `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length _mpg = gear_ratio displacement turn) weight      `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) weight _weight                                `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) weight _weight                `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio turn) weight _weight                `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio turn) weight                                     `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length = gear_ratio  _price turn) weight                                `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _price turn) weight                 `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio _price turn) weight                 `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _price weight                                 `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _turn = _mpg turn) weight                                              `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio _mpg turn) weight                                   `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) weight                   `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) weight                   `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _mpg weight                                   `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _mpg weight                   `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _mpg weight                   `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _gear_ratio weight                            `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio displacement turn) _gear_ratio weight                      `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio displacement turn) _gear_ratio weight      `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio displacement turn) _gear_ratio weight      `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length _price = gear_ratio displacement _price2 turn) weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length _price = gear_ratio displacement turn) _price2 weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length = _price gear_ratio displacement turn) _price2 weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight                       `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight       `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight       `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 7"

                qui givregress price (mpg length = gear_ratio _gear_ratio turn) _displacement weight                            `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _gear_ratio turn) _displacement weight            `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio _gear_ratio turn) _displacement weight            `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length _mpg = gear_ratio displacement turn) _displacement weight                      `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = gear_ratio displacement turn) _displacement weight      `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length _mpg = gear_ratio displacement turn) _displacement weight      `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _displacement weight _weight                                `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement weight _weight                `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement weight _weight                `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (_price = gear_ratio turn) weight                                     `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length = gear_ratio  _price turn) _displacement weight                                `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _price turn) _displacement weight                 `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio _price turn) _displacement weight                 `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _displacement _price weight                                 `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _turn = _mpg turn) _displacement weight                                              `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio _mpg turn) _displacement weight                                   `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) _displacement weight                   `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) _displacement weight                   `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _displacement _mpg weight                                   `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement _mpg weight                   `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement _mpg weight                   `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _displacement _gear_ratio weight                            `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio turn displacement trunk) _displacement _gear_ratio weight                      `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn displacement trunk) _displacement _gear_ratio weight      `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length = gear_ratio turn displacement trunk) _displacement _gear_ratio weight      `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length _price = gear_ratio displacement _price2 turn) _displacement weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length _price = gear_ratio displacement turn) _displacement _price2 weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length = _price gear_ratio displacement turn) _displacement _price2 weight            `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight                       `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight       `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 weight       `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 8"

                if ( inlist(`"`av'"', "v2", "v3") ) {
                qui givregress price (mpg length = gear_ratio _gear_ratio turn) _displacement `dvars' weight                        `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _gear_ratio turn) _displacement `dvars' weight        `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                    qui ivregress 2sls price (mpg length = gear_ratio _gear_ratio turn) _displacement `dvars' weight        `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length _mpg = gear_ratio displacement turn) _displacement `dvars' weight                  `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = gear_ratio displacement turn) _displacement `dvars' weight  `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 5::`=4 + `:list sizeof dvars'')
                    qui ivregress 2sls price (mpg length _mpg = gear_ratio displacement turn) _displacement `dvars' weight  `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV, 5::`=4 + `:list sizeof dvars'')
                qui givregress price (mpg length = gear_ratio turn) _displacement `dvars' weight _weight                            `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement `dvars' weight _weight            `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement `dvars' weight _weight            `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (_price = gear_ratio turn) weight                                                          `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length = gear_ratio  _price turn) _displacement `dvars' weight                            `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _price turn) _displacement `dvars' weight             `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                    qui ivregress 2sls price (mpg length = gear_ratio _price turn) _displacement `dvars' weight             `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length = gear_ratio turn) _displacement _price `dvars' weight                         `w' , `by' `gvce' `absorb'
                qui givregress price (mpg _turn = _mpg turn) _displacement weight                                               `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio _mpg turn) _displacement `dvars' weight                               `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) _displacement `dvars' weight               `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) _displacement `dvars' weight               `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length = gear_ratio turn) _displacement _mpg `dvars' weight                               `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement `dvars' _mpg weight               `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement `dvars' _mpg weight               `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length = gear_ratio turn) _displacement _gear_ratio `dvars' weight                        `w' , `by' `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== 0))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio turn displacement trunk) _displacement `dvars' _gear_ratio weight                 `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn displacement trunk) _displacement `dvars' _gear_ratio weight `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                    qui ivregress 2sls price (mpg length = gear_ratio turn displacement trunk) _displacement `dvars' _gear_ratio weight `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length _price = gear_ratio displacement _price2 turn) _displacement `dvars' weight        `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length _price = gear_ratio displacement turn) _displacement `dvars' _price2 weight        `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length = _price gear_ratio displacement turn) _displacement `dvars' _price2 weight        `w' , `by' `gvce' `absorb'
                qui givregress price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 `dvars' weight                                 `w' , `by' `gvce' `absorb'
                    qui ivregress 2sls price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 `dvars' weight                 `avars' `w' `if1', `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 5::`=4 + `:list sizeof dvars'')
                    qui ivregress 2sls price (mpg length _mpg = _mpg2 gear_ratio turn) _mpg3 `dvars' weight                 `avars' `w' `if2', `vce' `small'
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV, 5::`=4 + `:list sizeof dvars'')
disp _skip(8) "check 10"
                }

                qui givregress price (z1 = gear_ratio _gear_ratio) weight turn      `w' , `gvce' `absorb' `by'
                    mata assert(all(GtoolsIV.b  :== 0))                             
                    mata assert(all(GtoolsIV.se :== .))                             
                qui givregress price (z1 z2 = gear_ratio _gear_ratio) weight turn   `w' , `gvce' `absorb' `by'
                    mata assert(all(GtoolsIV.b  :== 0))                             
                    mata assert(all(GtoolsIV.se :== .))                             
                qui givregress price (mpg = z1 z2) weight turn                      `w' , `gvce' `absorb' `by'
                    mata assert(all(GtoolsIV.b  :== 0))                             
                    mata assert(all(GtoolsIV.se :== .))                             
                qui givregress price (z1 = z2) weight turn                          `w' , `gvce' `absorb' `by'
                    mata assert(all(GtoolsIV.b  :== 0))                             
                    mata assert(all(GtoolsIV.se :== .))                             
                qui givregress price (mpg = gear_ratio) z1 z2                       `w' , `gvce' `absorb' noc `by'
                    qui ivregress 2sls price (mpg = gear_ratio) z1 z2 `avars' `if1' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                    qui ivregress 2sls price (mpg = gear_ratio) z1 z2 `avars' `if2' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 2, 1::GtoolsIV.kx, GtoolsIV)
disp _skip(8) "check 11"
            }
        }
        qui drop if _expand
        qui drop _expand
    }

    * ------------------------------------------------------------------------
    * ------------------------------------------------------------------------

disp ""
disp "----------------------------"
disp "Collinearity Test 3: Poisson"
disp "----------------------------"
disp ""

    local tol 1e-4
    webuse ships, clear
    * use /tmp/ships, clear
    qui expand 2
    qui gen by = 1.5 - (_n < _N / 2)
    qui gen w = _n
    qui tab ship, gen(_s)
    unab svars: _s*
    qui gen z1 = 0
    qui gen z2 = 0

    foreach v in v1 v2 v5 {
        disp "poisson checks `v'"
        local w
        local r

        if ( "`v'" == "v2" ) local w [fw = w]
        if ( "`v'" == "v4" ) local w [fw = w]

        if ( "`v'" == "v5" ) local w [pw = w]
        if ( "`v'" == "v6" ) local w [pw = w]

        qui gglm accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w', robust `r' family(poisson)
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w', r
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson)
disp _skip(8) "check 1"
        qui gglm accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w', cluster(ship) `r' family(poisson)
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w', cluster(ship)
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson)
disp _skip(8) "check 2"
        qui gglm accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w', by(by) robust `r' family(poisson)
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w' if by == 0.5, r
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson)
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w' if by == 1.5, r
            mata: check_gregress_consistency(`tol', 2, 1::GtoolsPoisson.kx, GtoolsPoisson)
disp _skip(8) "check 3"
        qui gglm accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w', by(by) cluster(ship) `r' family(poisson)
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w' if by == 0.5, cluster(ship)
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson)
        qui poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w' if by == 1.5, cluster(ship)
            mata: check_gregress_consistency(`tol', 2, 1::GtoolsPoisson.kx, GtoolsPoisson)
disp _skip(8) "check 4"
        qui gglm accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars'        `w', absorb(ship) r family(poisson)
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars' i.ship `w', r
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson, 7::`=6 + `:list sizeof svars'')
disp _skip(8) "check 5"
        qui gglm accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars'        `w', absorb(ship) cluster(ship) family(poisson)
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars' i.ship `w', cluster(ship)
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson, 7::`=6 + `:list sizeof svars'')
disp _skip(8) "check 6"
        qui gglm accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars'        `w', by(by) absorb(ship) robust family(poisson)
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars' i.ship `w' if by == 0.5, r
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson, 7::`=6 + `:list sizeof svars'')
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars' i.ship `w' if by == 1.5, r
            mata: check_gregress_consistency(`tol', 2, 1::GtoolsPoisson.kx, GtoolsPoisson, 7::`=6 + `:list sizeof svars'')
disp _skip(8) "check 7"
        qui gglm accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars'        `w', by(by) absorb(ship) cluster(ship) family(poisson)
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars' i.ship `w' if by == 0.5, cluster(ship)
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson, 7::`=6 + `:list sizeof svars'')
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars' i.ship `w' if by == 1.5, cluster(ship)
            mata: check_gregress_consistency(`tol', 2, 1::GtoolsPoisson.kx, GtoolsPoisson, 7::`=6 + `:list sizeof svars'')
disp _skip(8) "check 8"

        qui gglm accident z1 z2 `w', robust noc family(poisson)
            mata assert(all(GtoolsPoisson.b  :== 0))
            mata assert(all(GtoolsPoisson.se :== .))
disp _skip(8) "check 9"
    }
end

cap mata mata drop check_gregress_consistency()
mata
void function check_gregress_consistency(
    real scalar tol,
    real scalar row,
    real vector col,
    class GtoolsRegressOutput scalar res,
    | real colvector missok)
{
    real scalar missokb, missokse
    real rowvector b, se, tolb, tolse, sameb, samese

    b  = st_matrix("r(table)")[1, col]
    se = st_matrix("r(table)")[2, col]

    if ( args() > 4 ) {
        missokb  = all(res.b[row, missok]  :== 0)
        missokse = all(res.se[row, missok] :== .)

        b[missok]  = res.b[row, missok]
        se[missok] = res.se[row, missok]
    }
    else {
        missokb  = 1
        missokse = 1
    }

    tolb   = reldif(b,  res.b[row, col])  :< tol
    tolse  = reldif(se, res.se[row, col]) :< tol

    sameb  = (b  :== res.b[row, col])
    samese = (se :== res.se[row, col])

    assert(all(colmax(tolb  \ sameb))  & missokb)
    assert(all(colmax(tolse \ samese)) & missokse)
}
end

***********************************************************************
*                               Testing                               *
***********************************************************************

* capture program drop simpleHDFE
* program simpleHDFE
*     syntax varlist, absorb(varlist) [tol(real 1e-8)]
*     gettoken y x: varlist
*     tempvar diff
*
*     local dmx
*     foreach xvar of local x {
*         tempvar `xvar'1
*         tempvar `xvar'2
*         local dmx `dmx' ``xvar'1'
*     }
*
*     qui gen double `diff' = 0
*     foreach xvar of local x {
*         qui gen double ``xvar'1' = `xvar'
*         qui gen double ``xvar'2' = `xvar'
*     }
*
*     tempvar `y'1 `y'2
*     qui gen double ``y'1' = `y'
*     qui gen double ``y'2' = `y'
*     local dmy ``y'1'
*
*     foreach avar of local absorb {
*         gstats transform (demean) `dmy' `dmx', by(`avar') replace
*     }
*
*     local supnorm = 1
*     while ( `supnorm' > `tol' ) {
*         foreach avar of local absorb {
*             gstats transform (demean) `dmy' `dmx', by(`avar') replace
*             qui replace `diff' = abs(``y'2' - ``y'1')
*             qui replace ``y'2' = ``y'1'
*             foreach xvar of local x {
*                 qui replace `diff' = `diff' + abs(``xvar'2' - ``xvar'1')
*                 qui replace ``xvar'2' = ``xvar'1'
*             }
*             sum `diff', meanonly
*             local supnorm = `r(max)'
*             if ( `supnorm' < `tol' ) break
*             disp `supnorm'
*         }
*     }
*
*     reg `dmy' `dmx', noc
* end

* Collinearity test
* -----------------

* cap mata mata drop my_lu()
* cap mata mata drop my_ldu()
* cap mata mata drop my_qr()
* cap mata mata drop my_householder()
* cap mata mata drop my_dot()
* cap mata mata drop my_norm()
*
* mata
* void function my_ldu (real matrix A, real scalar N, real matrix L, real vector D)
* {
*     real scalar i, j, k
*
*     L = J(N, N, 0)
*     for (j = 1; j <= N; j++) {
*         L[j, j] = 1
*     }
*     D = J(N, 1, 0)
*
*     for (i = 1; i <= N; i++) {
*         if ( i > 1 ) {
*             D[i] = A[i, i] - (L[i, 1::(i - 1)]:^2) * D[1::(i - 1)]
*         }
*         else {
*             D[i] = A[i, i]
*         }
*         for (j = i + 1; j <= N; j++) {
*             if ( i > 1 ) {
*                 L[j, i] = (A[j, i] - (L[j, 1::(i - 1)] :* L[i, 1::(i - 1)]) * D[1::(i - 1)]) / D[i]
*             }
*             else {
*                 L[j, i] = A[j, i] / D[i]
*             }
*         }
*     }
* }
*
* void function my_lu (real matrix A, real scalar N)
* {
*     real scalar i, j, k
*
*     for (j = 1; j <= N; j++) {
*         for (k = 1; k <= j - 1; k++) {
*             for (i = j; i <= N; i++) {
*                 A[i, j] = A[i, j] - A[i, k] * A[j, k]
*             }
*         }
*         A[j, j] = sqrt(A[j, j])
*         for (i = j + 1; i <= N; i++) {
*             A[i, j] = A[i, j] / A[j, j]
*         }
*     }
*
*     for (j = 1; j <= N; j++) {
*         for (i = 1; i < j; i++) {
*             A[i, j] = 0
*         }
*     }
* }
*
* void function my_qr (real matrix A, real scalar N, real matrix Q, real matrix H)
* {
*     real scalar i
*
*     Q = diag(J(1, N, 1))
*     for (i = 1; i < N; i++) {
*         H = diag(J(1, N, 1))
*         H[i::N, i::N] = my_householder(A[i::N, i], N - i + 1, H[i::N, i::N])
*         Q = Q * H
*         A = H * A
*     }
* }
*
* real matrix function my_householder (real vector a, real scalar N, real matrix H)
* {
*     real scalar i, j
*     real scalar anorm, adot
*
*     if ( a[1] < 0 ) {
*         anorm = -my_norm(a, N)
*     }
*     else {
*         anorm = my_norm(a, N)
*     }
*
*     adot = 1;
*     for (i = N; i > 1; i--) {
*         a[i] = a[i] / (a[1] + anorm)
*         adot = adot + a[i] * a[i];
*     }
*
*     a[1] = 1
*     adot = 2 / adot
*     for (i = 1; i <= N; i++) {
*         H[i, i] = 1 - adot * a[i] * a[i]
*         for (j = i + 1; j <= N; j++) {
*             H[i, j] = -adot * a[i] * a[j]
*         }
*     }
*
*     for (i = 1; i <= N; i++) {
*         for (j = 1; j < i; j++) {
*             H[i, j] = H[j, i]
*         }
*     }
*
*     return(H)
* }
*
* real scalar function my_dot (real vector a, real scalar N)
* {
*     real scalar i
*     real scalar dot
*     dot = 0
*     for (i = 1; i <= N; i++) {
*         dot = dot + a[i] * a[i]
*     }
*     return (dot)
* }
*
* real scalar function my_norm (real vector a, real scalar N)
* {
*     return (sqrt(my_dot(a, N)))
* }
* end

* IV via mata
* -----------

* mata: w  = st_data(., "w")
* mata: y  = st_data(., "price")
* mata: X  = st_data(., "mpg")
* mata: E  = st_data(., "weight turn ones")
* mata: Z  = st_data(., "gear_ratio")
* mata: ZZ = (E, Z)' * diag(w) * (E, Z)
* mata: Zi = invsym(ZZ)
* mata: PZ = (E, Z)' * diag(w) * X
* mata: BZ = Zi * PZ
* mata: PX = (E, Z) * BZ, E
* mata: XX = PX' * diag(w) * PX
* mata: Xi = invsym(XX)
* mata: Xy = PX' * diag(w) * y
* mata: b  = Xi * Xy
* mata: e  = y :- (X, E) * b
* mata: DD = PX' * diag(w :* e:^2) * PX
* mata: V  = Xi * DD * Xi
* mata: ZZ
* mata: PZ
* mata: BZ
* mata: XX
* mata: Xy
* mata: b
* mata: V

capture program drop checks_gstats
program checks_gstats
    checks_gstats_hdfe
    checks_gstats_winsor
    checks_gstats_summarize
    checks_gstats_transform
    checks_gstats_transform nogreedy
    exit 0
end

capture program drop compare_gstats
program compare_gstats
    compare_gstats_winsor
    compare_gstats_winsor, cuts(5 95)
    compare_gstats_winsor, cuts(30 70)

    compare_gstats_transform
    compare_gstats_transform, weights
    compare_gstats_transform, nogreedy
    compare_gstats_transform, nogreedy weights

    compare_gstats_hdfe, method(cg)
    compare_gstats_hdfe, method(map)
    compare_gstats_hdfe, method(it)
    compare_gstats_hdfe, method(squarem)
    compare_gstats_hdfe, weights method(cg)
    compare_gstats_hdfe, weights method(map)
    compare_gstats_hdfe, weights method(it)
    compare_gstats_hdfe, weights method(squarem)
end

***********************************************************************
*                            Compare hdfe                             *
***********************************************************************

capture program drop checks_gstats_hdfe
program checks_gstats_hdfe
    global GTOOLS_BETA = 1

    clear
    set obs `=2 * 5'
    gen fedbl1 = _n * 1.5
    expand `=3 * 5'
    bys fedbl1: gen fedbl2 = _n * 2.5
    replace fedbl2 = fedbl2 + ((fedbl1 / 2) - 1) * 7.5
    expand 5
    gen double fedbl3 = _n * 5.27
    gen double fedbl4 = int((_N / 5)  * rnormal()) / 100
    gen double fedbl5 = int((_N / 10) * rnormal()) / 100
    gen double w1 = runiform()
    gen long   w2 = int(_N * runiform())

    gen y    = 10 * rnormal()
    gen x    = 10 * rnormal()
    gen ybak = y
    gen xbak = x
    gen g    = mod(_n, 123)

    forvalues i = 1 / 5 {
        gen feint`i' = int(fedbl`i')
        gen festr`i' = "festr`i'" + string(fedbl`i')
    }

    cap mata mata drop GtoolsByLevels
    gstats hdfe _y = y _x = x, absorb(fedbl1 fedbl2) mata(info)
        return list
        cap mata info.desc()
        assert _rc == 3000
    gstats hdfe _y = y _x = x, absorb(fedbl1 fedbl2) by(g) replace
        cap mata GtoolsByLevels.desc()
        assert _rc == 3000
    gstats hdfe _y = y _x = x, absorb(fedbl1 fedbl2) by(g) replace mata
        return list
        mata GtoolsByLevels.desc()
    gstats hdfe _y = y _x = x, absorb(fedbl1 fedbl2) by(g) mata(test) replace
        mata test.desc()

    cap gstats hdfe _y = y _x = x, absorb(fedbl4 fedbl5) maxiter(.) replace
    assert _rc == 0
    cap gstats hdfe _y = y _x = x, absorb(fedbl4 fedbl5) maxiter(1) replace
    assert _rc == 430

    qui gstats hdfe _ghdfe2_y = y _ghdfe2_x = x, absorb(fedbl1 fedbl2)  method(map)
    qui gstats hdfe y x, absorb(fedbl1 fedbl2) gen(_ghdfe3_y _ghdfe3_x) method(squarem)
    qui gstats hdfe y x, absorb(fedbl1 fedbl2) gen(_ghdfe4_y _ghdfe4_x) method(cg)
    qui gstats hdfe y x, absorb(fedbl1 fedbl2) gen(_ghdfe5_y _ghdfe5_x) method(it)
    qui gstats hdfe _ghdfe6_y = y x `wgt`w'' `ifin`ifin'', absorb(fedbl1 fedbl2) prefix(_ghdfe6_) method(map)
    qui gstats hdfe _ghdfe7_y = y x `wgt`w'' `ifin`ifin'', absorb(fedbl1 fedbl2) prefix(_ghdfe7_) method(squarem)
    qui gstats hdfe _ghdfe8_y = y x `wgt`w'' `ifin`ifin'', absorb(fedbl1 fedbl2) prefix(_ghdfe8_) method(cg)
    qui gstats hdfe _ghdfe9_y = y x `wgt`w'' `ifin`ifin'', absorb(fedbl1 fedbl2) prefix(_ghdfe9_) method(it)
    forvalues i = 3 / 9 {
        assert reldif(_ghdfe2_y, _ghdfe`i'_y) < 1e-6
        assert reldif(_ghdfe2_x, _ghdfe`i'_x) < 1e-6
    }

    qui gstats hdfe _ghdfe2_y = y _ghdfe2_x = x, absorb(festr1 festr2)  method(map)     replace
    qui gstats hdfe y x, absorb(festr1 festr2) gen(_ghdfe3_y _ghdfe3_x) method(squarem) replace
    qui gstats hdfe y x, absorb(festr1 festr2) gen(_ghdfe4_y _ghdfe4_x) method(cg)      replace
    qui gstats hdfe y x, absorb(festr1 festr2) gen(_ghdfe5_y _ghdfe5_x) method(it)      replace
    qui gstats hdfe _ghdfe6_y = y x `wgt`w'' `ifin`ifin'', absorb(festr1 festr2) prefix(_ghdfe6_) method(map)     replace
    qui gstats hdfe _ghdfe7_y = y x `wgt`w'' `ifin`ifin'', absorb(festr1 festr2) prefix(_ghdfe7_) method(squarem) replace
    qui gstats hdfe _ghdfe8_y = y x `wgt`w'' `ifin`ifin'', absorb(festr1 festr2) prefix(_ghdfe8_) method(cg)      replace
    qui gstats hdfe _ghdfe9_y = y x `wgt`w'' `ifin`ifin'', absorb(festr1 festr2) prefix(_ghdfe9_) method(it)      replace
    forvalues i = 3 / 9 {
        assert reldif(_ghdfe2_y, _ghdfe`i'_y) < 1e-6
        assert reldif(_ghdfe2_x, _ghdfe`i'_x) < 1e-6
    }

    local fegroups 1          ///
                 | 2          ///
                 | 3          ///
                 | 1 2        /// | 2 1 ///
                 | 4 5        /// | 5 4 ///
                 | 1 2 3      ///
                 | 2 3 1      ///
                 | 4 5 3      ///
                 | 4 3 5

    local femixes dbl         ///
                | str         ///
                | int         ///
                | dbl str int ///
                | str int dbl ///
                | int dbl str

    local fegroups_bak: copy local fegroups
    local femixes_bak:  copy local femixes

    local wgt1 "         "
    local wgt2 [aw = w1]
    local wgt3 [fw = w2]

    local ifin1
    local ifin2 if x > 0
    local ifin3 in `=floor(_N/5)' / `=floor(_N/2)'
    local ifin4 if x > 0 in `=floor(_N/5)' / `=floor(_N/2)'

    local ifinstr1 "    "
    local ifinstr2 "  if"
    local ifinstr3 "  in"
    local ifinstr4 ifin

    local fegroups: copy local fegroups_bak
    local femixes:  copy local femixes_bak

    disp "gstats hdfe sanity"
    while ( trim("`fegroups'") != "" ) {
        gettoken groups fegroups: fegroups, p(|)
        gettoken _      fegroups: fegroups, p(|)

        local femixes: copy local femixes_bak
        while ( trim("`femixes'") != "" ) {
            gettoken mixes femixes: femixes, p(|)
            gettoken _     femixes: femixes, p(|)

            if ( `:list sizeof groups' == 1 & `:list sizeof mixes' > 1 ) continue

            local fes
            forvalues i = 1 / `:list sizeof groups' {
                local g:   word `i' of `groups'
                local mix: word `i' of `mixes'
                if ( `:list sizeof groups' > 1 & `:list sizeof mixes' == 1 ) {
                    local mix: word 1 of `mixes'
                }
                local fes `fes' fe`mix'`g'
            }

            forvalues ifin = 1 / 4 {
                forvalues w = 1 / 3 {
                    forvalues missing = 1 / 4 {
                        if ( `missing' == 2 ) qui replace x = . if runiform() < 0.2
                        if ( `missing' == 3 ) qui replace y = . if runiform() < 0.1
                        if ( `missing' == 4 ) {
                            qui replace x = . if runiform() < 0.2
                            qui replace y = . if runiform() < 0.1
                        }

                        local yeshdfe
                        local nohdfe
                        cap drop _*hdfe*_*

                        mata printf("    `missing' `ifinstr`ifin'' `wgt`w'' `fes'")
                        qui gregress y x `wgt`w'' `ifin`ifin'', absorb(`fes') mata(,nob nose) prefix(hdfe(_ghdfe_)) hdfetol(1e-12) maxiter(.) replace method(map)
                        qui gstats hdfe y x `wgt`w'' `ifin`ifin'', absorb(`fes') prefix(_ghdfe1_) method(squarem) tol(1e-12) maxiter(.) replace
                        qui gstats hdfe y x `wgt`w'' `ifin`ifin'', absorb(`fes') prefix(_ghdfe2_) method(map)     tol(1e-12) maxiter(.) replace
                        qui gstats hdfe y x `wgt`w'' `ifin`ifin'', absorb(`fes') prefix(_ghdfe3_) method(cg)      tol(1e-12) maxiter(.) replace
                        qui gstats hdfe y x `wgt`w'' `ifin`ifin'', absorb(`fes') prefix(_ghdfe4_) method(it)      tol(1e-12) maxiter(.) replace

                        forvalues i = 1 / 4 {
                            local checkx (reldif(_ghdfe_y, _ghdfe`i'_y) < 1e-6) | (max(_ghdfe_y, _ghdfe`i'_y) < 1e-5)
                            local checky (reldif(_ghdfe_x, _ghdfe`i'_x) < 1e-6) | (max(_ghdfe_x, _ghdfe`i'_x) < 1e-5)
                            cap noi assert `checkx'
                            if ( _rc ) {
                                if ( `i' == 3 ) {
                                    qui count if !(`checkx')
                                    if ( `r(N)' > 5 ) exit _rc
                                    else {
                                        noi disp "`r(N)' / `=_N' observations were off for algorithm CG"
                                        noi cl x _ghdfe_x _ghdfe3_x if !(`checkx')
                                        noi disp "This is probably fine; algorithm CG is coded to exit"
                                        noi disp "prematurely if vector improvements get too close to 0."
                                        noi disp "Pay attention to the regress checks and hdfe compare."
                                    }
                                }
                                else {
                                    noi disp "algorithm `i' failed ):"
                                    exit _rc
                                }
                            }
                            cap noi assert `checky'
                            if ( _rc ) {
                                if ( `i' == 3 ) {
                                    qui count if !(`checky')
                                    if ( `r(N)' > 5 ) exit _rc
                                    else {
                                        noi disp "`r(N)' / `=_N' observations were off for algorithm CG"
                                        noi cl y _ghdfe_y _ghdfe3_y if !(`checky')
                                        noi disp "This is probably fine; algorithm CG is coded to exit"
                                        noi disp "prematurely if vector improvements get too close to 0."
                                        noi disp "Pay attention to the regress checks and hdfe compare."
                                    }
                                }
                                else {
                                    noi disp "algorithm `i' failed ):"
                                    exit _rc
                                }
                            }

                            if ( (`missing' > 1) | (`ifin' > 1) ) {
                                assert mi(_ghdfe`i'_y) if mi(_ghdfe_y)
                                assert mi(_ghdfe`i'_x) if mi(_ghdfe_x)
                            }
                        }

                        if ( `missing' > 1 ) {
                            if ( "`ifin`ifin''" != "" ) {
                                cap reghdfe y `wgt`w'' `ifin`ifin'' & !mi(x), absorb(`fes') res(_hdfe_y) tol(1e-12) keepsingletons
                                cap reghdfe x `wgt`w'' `ifin`ifin'' & !mi(y), absorb(`fes') res(_hdfe_x) tol(1e-12) keepsingletons
                            }
                            else {
                                cap reghdfe y `wgt`w'' if !mi(x), absorb(`fes') res(_hdfe_y) tol(1e-12) keepsingletons
                                cap reghdfe x `wgt`w'' if !mi(y), absorb(`fes') res(_hdfe_x) tol(1e-12) keepsingletons
                            }
                        }
                        else {
                            cap reghdfe y `wgt`w'' `ifin`ifin'', absorb(`fes') res(_hdfe_y) tol(1e-12) keepsingletons
                            cap reghdfe x `wgt`w'' `ifin`ifin'', absorb(`fes') res(_hdfe_x) tol(1e-12) keepsingletons
                        }
                        if ( _rc == 0 ) {
                            local checkx (reldif(_ghdfe3_x, _hdfe_x)  < 1e-6) | (max(_hdfe_x, _ghdfe3_x) < 1e-5)
                            local checky (reldif(_ghdfe3_y, _hdfe_y)  < 1e-6) | (max(_hdfe_y, _ghdfe3_y) < 1e-5)
                            cap noi assert  `checkx'
                            if ( _rc ) {
                                qui count if !(`checkx')
                                if ( `r(N)' > 5 ) exit _rc
                                else {
                                    noi disp "`r(N)' / `=_N' observations were off vs reghdfe"
                                    noi cl x _hdfe_x _ghdfe3_x if !(`checkx')
                                    noi disp "This is probably fine; while both use CG internally"
                                    noi disp "reghdfe has a slightly lower tolerance (though reghdfe's"
                                    noi disp "internals should be more precise, it can exit earlier)."
                                }
                            }
                            cap noi assert  `checky'
                            if ( _rc ) {
                                qui count if !(`checky')
                                if ( `r(N)' > 5 ) exit _rc
                                else {
                                    noi disp "`r(N)' / `=_N' observations were off vs reghdfe"
                                    noi cl y _hdfe_y _ghdfe3_y if !(`checky')
                                    noi disp "This is probably fine; while both use CG internally"
                                    noi disp "reghdfe has a slightly lower tolerance (though reghdfe's"
                                    noi disp "internals should be more precise, it can exit earlier)."
                                }
                            }
                            if ( (`missing' > 1) | (`ifin' > 1) ) {
                                assert mi(_ghdfe3_y) if mi(_hdfe_y)
                                assert mi(_ghdfe3_x) if mi(_hdfe_x)
                            }
                            local yeshdfe `yeshdfe' reghdfe
                        }
                        else {
                            local nohdfe `nohdfe' reghdfe
                        }

                        * hdfe is a convenient but outdated package (it's the precursor to
                        * reghdfe). don't use bc it is very slow.
                        *
                        * if ( ("`ifin`ifin''" == "") & (strpos("`fes'", "str") == 0) ) {
                        *     cap hdfe y x `wgt`w'', absorb(`fes') gen(_hdfe2_) tol(1e-12) keepsingletons
                        *     if ( _rc == 0 ) {
                        *         assert reldif(_ghdfe1_y, _hdfe2_y) < 1e-6
                        *         assert reldif(_ghdfe1_x, _hdfe2_x) < 1e-6
                        *         if ( (`missing' > 1) | (`ifin' > 1) ) {
                        *             assert mi(_ghdfe1_y) if mi(_hdfe_y)
                        *             assert mi(_ghdfe1_x) if mi(_hdfe_x)
                        *         }
                        *         local yeshdfe `yeshdfe' hdfe
                        *     }
                        *     else {
                        *         local nohdfe `nohdfe' hdfe
                        *     }
                        * }

                        mata printf("`nohdfe'" != ""? " (failed: `nohdfe'; run: `yeshdfe')\n": "\n")

                        if ( `missing' == 2 ) qui replace x = xbak
                        if ( `missing' == 3 ) qui replace y = ybak
                        if ( `missing' == 4 ) {
                            qui replace x = xbak
                            qui replace y = ybak
                        }
                    }
                }
            }
        }
    }
end

capture program drop compare_gstats_hdfe
program compare_gstats_hdfe
    syntax, [weights *]

    qui `noisily' gen_data, n(500)
    qui expand 100
    qui `noisily' random_draws, random(2) double
    gen long   ix    = _n
    gen double ixdbl = _n * 3.14159265
    gen str    ixstr = "ix" + string(_n)
    gen double ru  = runiform() * 500
    qui replace ix = . if mod(_n, 500) == 0
    qui replace ru = . if mod(_n, 500) == 0
    qui gen int    special1 = 1
    qui gen double special2 = 3.1415
    qui gen str8   special3 = "special3"
    qui sort random1

    local N = trim("`: di %15.0gc _N'")
    di _n(1) "{hline 80}" _n(1) "compare_gstats_hdfe, N = `N', `options'" _n(1) "{hline 80}" _n(1)

    if ( `"`weights'"' != "" ) {
        qui {
            gen unif_0_100     = 100 * runiform() if mod(_n, 100)
            gen int_unif_0_100 = int(100 * runiform()) if mod(_n, 100)
            gen float_unif_0_1 = runiform() if mod(_n, 100)
            gen rnormal_0_10   = 10 * rnormal() if mod(_n, 100)
        }

        local wcall_a  wgt([aw = unif_0_100])
        local wcall_f  wgt([fw = int_unif_0_100])
        local wcall_a2 wgt([aw = float_unif_0_1])
        local wcall_i: copy local wcall_a
        * Note: I'm not allowing iweights

        compare_inner_gstats_hdfe, `options' `wcall_a'
        disp

        compare_inner_gstats_hdfe in 1 / 5, `options' `wcall_f'
        disp

        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        compare_inner_gstats_hdfe in `from' / `to', `options' `wcall_a2'
        disp

        compare_inner_gstats_hdfe if random2 > 0, `options' `wcall_i'
        disp

        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        compare_inner_gstats_hdfe if random2 < 0 in `from' / `to', `options' `wcall_a'
        disp
    }
    else {
        compare_inner_gstats_hdfe, `options'
        disp

        compare_inner_gstats_hdfe in 1 / 5, `options'
        disp

        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        compare_inner_gstats_hdfe in `from' / `to', `options'
        disp

        compare_inner_gstats_hdfe if random2 > 0, `options'
        disp

        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        compare_inner_gstats_hdfe if random2 < 0 in `from' / `to', `options'
        disp
    }
end

capture program drop compare_inner_gstats_hdfe
program compare_inner_gstats_hdfe
    syntax [if] [in], [wgt(passthru) *]

    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(special1)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(special2)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(special3)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(special1 special2 special3)

    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(ix)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(ixdbl)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(ixstr)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(ix ixdbl ixstr)

    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(str_12)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(str_12 str_32 str_4)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(double1)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(double1 double2 double3)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(int1)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(int1 int2)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(int1 int2 int3)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(str_32 int3 double3)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(int1 double2 double3)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(double? str_* int?)

    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(int1 int2)       by(ix)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(int1 int2)       by(ixdbl)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(int1 int2)       by(ixstr)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(int1 int2)       by(ix ixdbl ixstr)

    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(ix)                 by(special1)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(ixstr)              by(special2)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(int1 int2)          by(special3)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(double? str_* int?) by(special1 special2 special3)

    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(int1 int2)          by(str_12)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(int1 int2)          by(str_12 str_32 str_4)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(str_12 str_4)       by(double1)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(str_12 str_4)       by(double1 double2 double3)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(double1 double2)    by(int1)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(double1 double2)    by(int1 int2)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(double1 double2)    by(int1 int2 int3)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(int1 int2)          by(str_32 int3 double3)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(int1 int2)          by(int1 double2 double3)
    compare_fail_gstats_hdfe versus_gstats_hdfe `if' `in', `options' `wgt' absorb(double? str_* int?) by(double? str_* int?)
end

capture program drop compare_fail_gstats_hdfe
program compare_fail_gstats_hdfe
    gettoken cmd 0: 0
    syntax [anything] [if] [in], [tol(real 1e-6) by(str) *]
    cap `cmd' `0'

    if "`by'" == "" {
        local compare reghdfe and greg
    }
    else {
        local compare greg
    }

    if ( _rc ) {
        if ( "`if'`in'" == "" ) {
            di "    compare_gstats_hdfe (failed): full range, `anything'; `options' `by'"
        }
        else if ( "`if'`in'" != "" ) {
            di "    compare_gstats_hdfe (failed): [`if'`in'], `anything'; `options' `by'"
        }
        exit _rc
    }
    else {
        if ( "`if'`in'" == "" ) {
            di "    compare_gstats_hdfe (passed): full range, gstats results equal to `compare' (tol = `tol'; `anything'; `options' `by')"
        }
        else if ( "`if'`in'" != "" ) {
            di "    compare_gstats_hdfe (passed): [`if'`in'], gstats results equal to `compare' (tol = `tol'; `anything'; `options' `by')"
        }
    }
end

capture program drop versus_gstats_hdfe
program versus_gstats_hdfe, rclass
    syntax [if] [in], [tol(real 1e-6) absorb(str) by(str) wgt(str) *]

    timer clear
    timer on 42
    qui gstats hdfe random1 random2 `if' `in' `wgt', `options' absorb(`absorb') by(`by') prefix(_hdfe1_) tol(1e-12) maxiter(.)
    timer off 42
    qui timer list
    local time_ghdfe = r(t42)

    timer clear
    timer on 43
    qui gregress random1 random2 `if' `in' `wgt', absorb(`absorb') by(`by') mata(,nob nose) prefix(hdfe(_hdfe2_)) hdfetol(1e-12)
    timer off 43
    qui timer list
    local time_greg = r(t43)

    if "`by'" == "" {
        timer clear
        timer on 44
        qui reghdfe random2 `if' `in' `wgt', absorb(`absorb') res(_hdfe3_random2) tol(1e-12) keepsingletons
        timer off 44
        qui timer list
        local time_hdfe = r(t44)
    }

    cap assert ((abs(_hdfe1_random1 - _hdfe2_random1) < `tol') | (_hdfe1_random1 == _hdfe2_random1))
    if ( _rc ) {
        exit _rc
    }

    cap assert ((abs(_hdfe1_random2 - _hdfe2_random2) < `tol') | (_hdfe1_random2 == _hdfe2_random2))
    if ( _rc ) {
        exit _rc
    }

    if "`by'" == "" {
        cap assert ((abs(_hdfe1_random2 - _hdfe3_random2) < `tol') | (_hdfe1_random2 == _hdfe3_random2))
        if ( _rc ) {
            exit _rc
        }
    }

    qui drop _hdfe*_*

    if "`by'" == "" {
        local rs = `time_hdfe'  / `time_ghdfe'
        di as txt "    `:di %6.3g `time_hdfe'' | `:di %13.3g `time_ghdfe'' | `:di %11.4g `rs'' | `absorb' (`by')"
    }
end

***********************************************************************
*                          Compare summarize                          *
***********************************************************************

capture program drop checks_gstats_summarize
program checks_gstats_summarize
    clear
    set obs 10
    gen x = string(_n) + "some"
    gen y = mod(_n, 3)
    gen w = string(mod(_n, 4)) + "Other That is Long"
    gen v = -mod(_n, 7)
    gen z = runiform()
    gen z2 = rnormal()
    if ( `c(stata_version)' >= 14.1 ) {
    gen strL L = "This one is strL and what will hapennnnn!!!???" + string(mod(_n, 4))
    }
    else {
    gen L = "This one is strL and what will hapennnnn!!!???" + string(mod(_n, 4))
    }
    gen a = "hey"
    replace a = "" in 3 / 6
    replace a = " " in 7 / 10

    gstats tab z
    gstats tab z y
    gstats tab z,   matasave
    mata: GstatsOutput.desc()
    gstats tab z y, matasave
    mata: GstatsOutput.desc()
    gstats tab z y, matasave by(x)
    mata: GstatsOutput.desc()
    mata: GstatsOutput.help()

    gstats tab z, by(y x) s(mean sd min max) matasave pretty
    mata GstatsOutput.printOutput()
    mata GstatsOutput.getf(1, 2, GstatsOutput.maxl)
    mata GstatsOutput.getnum(1, 1)
    mata GstatsOutput.getchar(1, 2)
    cap noi mata assert(.  == GstatsOutput.getnum(1, 2))
    cap noi mata assert("" == GstatsOutput.getchar(1, 1))
    mata GstatsOutput.getOutputRow(1)
    mata GstatsOutput.getOutputRow(5)
    cap mata GstatsOutput.getOutputRow(999)
    assert _rc == 3301
    mata GstatsOutput.getOutputCol(1)
    mata GstatsOutput.getOutputCol(4)
    cap mata GstatsOutput.getOutputCol(999)
    assert _rc == 3301
    mata GstatsOutput.getOutputVar("z")
    cap noi mata assert(J(1, 0, .) == GstatsOutput.getOutputVar("x"))
    mata GstatsOutput.getOutputGroup(1)
    mata GstatsOutput.getOutputGroup(5)
    cap mata GstatsOutput.getOutputGroup(999)
    assert _rc == 3301

    gstats tab z* , by(a x)       s(mean sd min max) pretty
    gstats tab z  , by(w y v x L) s(mean sd min max) col(var)
    gstats tab z  , by(L)         s(mean sd min max) col(var)
    gstats tab z  , by(L x)       s(mean sd min max) col(var)


    gstats tab z  , by(x)         s(mean sd min max) matasave pretty
    gstats tab z  , by(a x)       s(mean sd min max) matasave pretty
    gstats tab z  , by(y)         s(mean sd min max) matasave
    gstats tab z  , by(x y)       s(mean sd min max) matasave
    gstats tab z  , by(x v y w)   s(mean sd min max) matasave
    gstats tab z  , by(w y v x)   s(mean sd min max) matasave pretty
    gstats tab z  , by(w y v x L) s(mean sd min max) matasave pretty labelw(100)

    qui _checks_gstats_summarize
    qui _checks_gstats_summarize, pool
    qui _checks_gstats_summarize [fw = mpg]
    qui _checks_gstats_summarize [aw = gear_ratio]
    qui _checks_gstats_summarize [pw = gear_ratio / 4]
    qui _checks_gstats_summarize if foreign
    qui _checks_gstats_summarize if foreign, pool
    qui _checks_gstats_summarize if foreign [fw = mpg]
    qui _checks_gstats_summarize if foreign [aw = gear_ratio]
    qui _checks_gstats_summarize if foreign [pw = gear_ratio / 4]
    qui _checks_gstats_summarize in 23
    qui _checks_gstats_summarize in 1 / 2
    qui _checks_gstats_summarize in 23, pool
    qui _checks_gstats_summarize in 1 / 2, pool
    qui _checks_gstats_summarize in 1 / 2 [fw = mpg]
    qui _checks_gstats_summarize in 1 / 2 [aw = gear_ratio]
    qui _checks_gstats_summarize in 1 / 2 [pw = gear_ratio / 4]
end

capture program drop _checks_gstats_summarize
program _checks_gstats_summarize
    if ( strpos(`"`0'"', ",") == 0 ) {
        local 0 `0',
    }
    sysuse auto, clear
    gstats sum price       `0'
    gstats sum price       `0' f
    gstats sum price       `0' nod
    gstats sum price       `0' nod f
    gstats sum price       `0' meanonly
    gstats sum price mpg   `0'
    gstats sum *           `0'
    gstats sum price price `0'
    gstats sum price mpg * `0' nod
    gstats sum price mpg * `0' nod f

    gstats sum price       , tab
    gstats sum price       , tab f
    gstats sum price       , tab nod
    gstats sum price       , tab nod f
    gstats sum price       , tab meanonly
    gstats sum price mpg   , tab
    gstats sum *           , tab
    gstats sum price price , tab
    gstats sum price mpg * , tab nod
    gstats sum price mpg * , tab nod f

    cap noi gstats tab price       , statistics(n) stats(n)
    assert _rc == 198
    cap noi gstats tab price       , nod
    assert _rc == 198
    cap noi gstats tab *
    assert _rc == 7
    cap noi gstats tab price       , meanonly
    assert _rc == 198

    gstats tab price       ,
    gstats tab price       , s(mean sd min max)
    gstats tab price       , statistics(count n nmissing percent nunique)
    gstats tab price       , stats(rawsum nansum rawnansum median p32.4 p50 p99)
    gstats tab price       , stat(iqr q median sd variance cv geomean)
    gstats tab price       ,
    gstats tab price       , stat(min max range select2 select10 select-4 select-9)
    cap gstats tab price   , stat(select0)
    assert _rc == 110
    cap gstats tab price   , stat(select-0)
    assert _rc == 110
    gstats tab price       , stat(first last firstnm lastnm semean sebinomial sepoisson)
    gstats tab price mpg   , stat(skewness kurtosis)
    gstats tab price price , stat()

    gstats sum price `0' tab
    gstats sum price `0' tab pretty
    gstats sum price `0' tab nod
    gstats sum price `0' tab meanonly
    gstats sum price `0' by(foreign) tab
    gstats sum price `0' by(foreign) tab pretty
    gstats sum price `0' by(foreign) tab nod
    gstats sum price `0' by(foreign) tab meanonly pretty
    gstats sum price `0' by(rep78)   tab
    gstats sum price `0' by(rep78)   tab nod
    gstats sum price `0' by(rep78)   tab meanonly

    gstats sum price `0' col(stat) tab
    gstats sum price `0' col(var)  tab nod
    gstats sum price `0' col(var)  tab meanonly
    gstats sum price `0' by(foreign)  col(stat) tab
    gstats sum price `0' by(foreign)  col(var)  tab nod
    gstats sum price `0' by(foreign)  col(var)  tab meanonly
    gstats sum price `0' by(rep78)    col(stat) tab
    gstats sum price `0' by(rep78)    col(var)  tab nod
    gstats sum price `0' by(rep78)    col(var)  tab meanonly

    gstats tab price         `0' col(var) s(mean sd min max)
    gstats tabstat price     `0' col(var) s(mean sd min max) by(foreign)
    gstats tabstat price mpg `0' col(var) s(mean sd min max) by(foreign)
    gstats tabstat price     `0' col(var) s(mean sd min max) by(rep78)
    gstats tabstat price mpg `0' col(var) s(mean sd min max) by(rep78)
    gstats tabstat price mpg `0' col(var) s(mean sd min max) by(rep78)

    gstats tab price         `0' s(mean sd min max)
    gstats tabstat price     `0' s(mean sd min max) by(foreign)
    gstats tabstat price mpg `0' s(mean sd min max) by(foreign)
    gstats tabstat price     `0' s(mean sd min max) by(rep78)
    gstats tabstat price mpg `0' s(mean sd min max) by(rep78)
    gstats tabstat price mpg `0' s(mean sd min max) by(rep78)

    gstats tab price         `0'
    gstats tab price         `0' pretty
    gstats tabstat price     `0' by(foreign)
    gstats tabstat price mpg `0' by(foreign)
    gstats tabstat price     `0' by(rep78)
    gstats tabstat price mpg `0' by(rep78)
    gstats tabstat price mpg `0' by(rep78)

    gstats tab price         `0' col(var)
    gstats tabstat price     `0' col(var) by(foreign)
    gstats tabstat price mpg `0' col(var) by(foreign)
    gstats tabstat price     `0' col(var) by(rep78)
    gstats tabstat price mpg `0' col(var) by(rep78)
    gstats tabstat price mpg `0' col(var) by(rep78)
end

***********************************************************************
*                           Compare winsor                            *
***********************************************************************

capture program drop checks_gstats_winsor
program checks_gstats_winsor
    * TODO: Pending
    sysuse auto, clear
    cap gstats winsor price if foreign, cuts(10 90) replace
    assert _rc == 198

    cap noi gstats winsor price, by(foreign) cuts(10)
    cap noi gstats winsor price, by(foreign) cuts(90)
    cap noi gstats winsor price, by(foreign) cuts(. 90)
    cap noi gstats winsor price, by(foreign) cuts(10 .)
    cap noi gstats winsor price, by(foreign) cuts(-1 10)
    cap noi gstats winsor price, by(foreign) cuts(10 101)
    preserve
        cap noi gstats winsor price, by(foreign) cuts(0 10) gen(x)
        cap noi gstats winsor price, by(foreign) cuts(10 100) gen(y)
        cap noi gstats winsor price, by(foreign) cuts(100 100) gen(zz)
        cap noi gstats winsor price, by(foreign) cuts(0 0) gen(yy)
    restore
    gstats winsor price, by(foreign)
    winsor2 price, by(foreign) replace

    winsor2 price mpg, by(foreign) cuts(10 90) s(_w2)
    gstats winsor price mpg, by(foreign) cuts(10 90) s(_w2) replace
    desc

    * gtools, upgrade branch(develop)
    clear
    set obs 500000
    gen long id = int((_n-1) / 1000)
    gunique id
    gen double x = runiform()
    gen double y = runiform()
    set rmsg on
    winsor2 x y, by(id) s(_w1)
    gstats winsor x y, by(id) s(_w2)
    gegen x_g3 = winsor(x), by(id)
    gegen y_g3 = winsor(y), by(id)

    desc
    assert abs(x_w1 - x_w2) < 1e-6
    assert abs(y_w1 - y_w2) < 1e-6
    assert abs(x_g3 - x_w2) < 1e-6
    assert abs(y_g3 - y_w2) < 1e-6

    replace y = . if mod(_n, 123) == 0
    replace x = . if mod(_n, 321) == 0

    gstats winsor x [w=y], by(id) s(_w3)
    gstats winsor x [w=y], by(id) s(_w5) trim

    gegen x_g4 = winsor(x) [w=y], by(id)
    gegen x_g5 = winsor(x) [w=y], by(id) trim

    gegen p1  = pctile(x) [aw = y], by(id) p(1)
    gegen p99 = pctile(x) [aw = y], by(id) p(99)

    gen x_w4 = cond(x < p1, p1, cond(x > p99, p99, x))

    assert (abs(x_w3 - x_w4) < 1e-6 | mi(x_w3 - x_w4))
    assert (abs(x_g4 - x_w3) < 1e-6 | mi(x_g4 - x_w3))
    assert (abs(x_g5 - x_w5) < 1e-6 | mi(x_g5 - x_w5))
end

capture program drop compare_gstats_winsor
program compare_gstats_winsor
    syntax, [*]

    qui `noisily' gen_data, n(500)
    qui expand 100
    qui `noisily' random_draws, random(2) double
    gen long   ix  = _n
    gen double ru  = runiform() * 500
    qui replace ix = . if mod(_n, 500) == 0
    qui replace ru = . if mod(_n, 500) == 0
    qui sort random1

    local N = trim("`: di %15.0gc _N'")
    di _n(1) "{hline 80}" _n(1) "compare_gstats_winsor, N = `N', `options'" _n(1) "{hline 80}" _n(1)

    compare_inner_gstats_winsor, `options'
    disp

    compare_inner_gstats_winsor in 1 / 5, `options'
    disp

    local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
    local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
    local from = cond(`in1' < `in2', `in1', `in2')
    local to   = cond(`in1' > `in2', `in1', `in2')
    compare_inner_gstats_winsor in `from' / `to', `options'
    disp

    compare_inner_gstats_winsor if random2 > 0, `options'
    disp

    local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
    local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
    local from = cond(`in1' < `in2', `in1', `in2')
    local to   = cond(`in1' > `in2', `in1', `in2')
    compare_inner_gstats_winsor if random2 < 0 in `from' / `to', `options'
    disp
end

capture program drop compare_inner_gstats_winsor
program compare_inner_gstats_winsor
    syntax [if] [in], [*]
    compare_fail_gstats_winsor versus_gstats_winsor `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor `if' `in', `options' trim

    compare_fail_gstats_winsor versus_gstats_winsor str_12              `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor str_12              `if' `in', `options' trim
    compare_fail_gstats_winsor versus_gstats_winsor str_12 str_32 str_4 `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor str_12 str_32 str_4 `if' `in', `options' trim

    compare_fail_gstats_winsor versus_gstats_winsor double1                 `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor double1                 `if' `in', `options' trim
    compare_fail_gstats_winsor versus_gstats_winsor double1 double2 double3 `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor double1 double2 double3 `if' `in', `options' trim

    compare_fail_gstats_winsor versus_gstats_winsor int1           `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor int1           `if' `in', `options' trim
    compare_fail_gstats_winsor versus_gstats_winsor int1 int2      `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor int1 int2      `if' `in', `options' trim
    compare_fail_gstats_winsor versus_gstats_winsor int1 int2 int3 `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor int1 int2 int3 `if' `in', `options' trim

    compare_fail_gstats_winsor versus_gstats_winsor str_32 int3 double3  `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor str_32 int3 double3  `if' `in', `options' trim
    compare_fail_gstats_winsor versus_gstats_winsor int1 double2 double3 `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor int1 double2 double3 `if' `in', `options' trim
    compare_fail_gstats_winsor versus_gstats_winsor double? str_* int?   `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor double? str_* int?   `if' `in', `options' trim
end

capture program drop compare_fail_gstats_winsor
program compare_fail_gstats_winsor
    gettoken cmd 0: 0
    syntax [anything] [if] [in], [tol(real 1e-6) *]
    cap `cmd' `0'
    if ( _rc ) {
        if ( "`if'`in'" == "" ) {
            di "    compare_gstats_winsor (failed): full range, `anything'; `options'"
        }
        else if ( "`if'`in'" != "" ) {
            di "    compare_gstats_winsor (failed): [`if'`in'], `anything'; `options'"
        }
        exit _rc
    }
    else {
        if ( "`if'`in'" == "" ) {
            di "    compare_gstats_winsor (passed): full range, gstats results equal to winsor2 (tol = `tol'; `anything'; `options')"
        }
        else if ( "`if'`in'" != "" ) {
            di "    compare_gstats_winsor (passed): [`if'`in'], gstats results equal to winsor2 (tol = `tol'; `anything'; `options')"
        }
    }
end

***********************************************************************
*                          Compare transform                          *
***********************************************************************

capture program drop checks_gstats_transform
program checks_gstats_transform

    local percentiles p1 p10 p30.5 p50 p70.5 p90 p99
    local selections  select1 select2 select5 select-5 select-2 select-1
    local stats       nmissing sum mean geomean cv sd variance max min range count first last firstnm lastnm median iqr skew kurt

    local percentiles p1 p30.5 p70.5 p99
    local selections  select1 select5 select-2 select-1
    local stats       nmissing sum mean geomean cv sd variance max min range count first last firstnm lastnm median iqr skew kurt

    *********************************
    *  Basic check transform stats  *
    *********************************

    sysuse auto, clear
    gstats transform (normalize) p1 = price p2 = price (demean) p3 = price (moving first) p4 = price, by(foreign) nogreedy

    clear
    set obs 10
    gen long x1 = _n
    gen long x2 = -_n
    gstats transform x1 = x2 x2 = x1, replace `0'
    assert x1 != .
    assert x2 != .
    gstats transform x1, replace `0'
    assert x1 != .
    gstats transform x1 x2, replace `0'
    assert x2 != .

    clear
    set obs 10
    gen long x1 = _n
    gen long x2 = -_n
    gstats transform x1 x2 (normalize) x1 x2, autorename replace `0'

    ******************
    *  Moving stats  *
    ******************

    foreach by in foreign mpg {
        disp "`by'"
        foreach stat in `stats' `selections' `percentiles' {
            disp "    `stat'"
            qui sysuse auto, clear
            qui replace mpg = . if mod(_n, 19) == 0
            qui {
                gstats transform (moving `stat' -3  -1) x1 = price, by(`by') `0'
                gstats transform (moving `stat'  4  2)  x2 = price, by(`by') `0'
                gstats transform (moving `stat'  3  6)  x3 = price, by(`by') `0'
                gstats transform (moving `stat'  -3 6)  x4 = price, by(`by') `0'
            }

            local r1 moving `stat' -3 -1
            local r2 moving `stat' -3 6
            local r3 moving `stat' -3 .
            local r4 moving `stat'
            local call (`r1') x5 = price (`r2') x6 = price (`r3') x7 = price (`r4') x8 = price

            qui {
                gstats transform `call' , by(`by') replace window(-4 4) `0'
                gstats transform `call' , by(`by') replace window( 4 8) `0'
                gstats transform `call' , by(`by') replace window( 8 3) `0'
                gstats transform `call' , by(`by') replace window(-4 .) `0'
                gstats transform `call' , by(`by') replace window( . 4) `0'
                gstats transform `call' , by(`by') replace window( . .) `0'

                gstats transform `call' [ w = gear_ratio * 10]      , by(`by') replace window(-4 4) `0'
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace window( 4 8) `0'
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace window( 9 2) `0'
                gstats transform `call' [fw = int(gear_ratio * 10)] , by(`by') replace window(-4 .) `0'
                gstats transform `call' [iw = gear_ratio / 10]      , by(`by') replace window( . 4) `0'
                gstats transform `call' [pw = gear_ratio / 10]      , by(`by') replace window( . .) `0'
            }
        }
    }

    *****************
    *  Range stats  *
    *****************

    foreach by in foreign mpg {
        disp "`by' (main)"
        qui sysuse auto, clear
        qui keep if mod(_n, 3) == 0
        qui replace mpg = . if mod(_n, 19) == 0
        local sl: copy local stat
        local ul: copy local stat

        foreach stat in `stats' `selections' `percentiles' {
            disp "    `stat'"

            local s1  ( range `stat'   -3      5.5      gear_ratio ) p1  = price       // g1  = weight
            local s2  ( range `stat'   -3     -1        mpg        ) p2  = price       // g2  = weight
            local s3  ( range `stat' 7.33      3        length     ) p3  = gear_ratio  // g3  = weight
            local s4  ( range `stat'   -3      5.5                 ) p4  = gear_ratio  // g4  = weight
            local s5  ( range `stat'   -3     -1                   ) p5  = gear_ratio  // g5  = weight
            local s6  ( range `stat'    2      6.25     turn       ) p6  = gear_ratio  // g6  = weight
            local s7  ( range `stat'   -3      .        turn       ) p7  = gear_ratio  // g7  = weight
            local s8  ( range `stat'    .      3        gear_ratio ) p8  = gear_ratio  // g8  = weight
            local s9  ( range `stat'    .     -3        gear_ratio ) p9  = price       // g9  = weight
            local s10 ( range `stat' 7.33      3                   ) p10 = price       // g10 = weight
            local s11 ( range `stat'    2      6.25                ) p11 = price       // g11 = weight
            local s12 ( range `stat'   -3      .                   ) p12 = gear_ratio  // g12 = weight
            local s13 ( range `stat'    .      3                   ) p13 = gear_ratio  // g13 = weight
            local s14 ( range `stat'    .     -3                   ) p14 = price       // g14 = weight
            local s15 ( range `stat'    3      .        gear_ratio ) p15 = price       // g15 = weight
            local s16 ( range `stat'                               ) p16 = price       // g16 = weight

            local call
            forvalues i = 1 / 16 {
                local call `call' `s`i''
            }

            qui {
                gstats transform `call' , by(`by') replace interval(-4 4) `0'
                gstats transform `call' , by(`by') replace interval( 4 8) `0'
                gstats transform `call' , by(`by') replace interval( 8 3) `0'
                gstats transform `call' , by(`by') replace interval(-4 .) `0'
                gstats transform `call' , by(`by') replace interval( . 4) `0'
                gstats transform `call' , by(`by') replace interval( . .) `0'
            }

            qui {
                gstats transform `call' [ w = gear_ratio * 10]      , by(`by') replace interval(-4 4) `0'
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 4 8) `0'
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 9 2) `0'
                gstats transform `call' [fw = int(gear_ratio * 10)] , by(`by') replace interval(-4 .) `0'
                gstats transform `call' [iw = gear_ratio / 10]      , by(`by') replace interval( . 4) `0'
                gstats transform `call' [pw = gear_ratio / 10]      , by(`by') replace interval( . .) `0'
            }

            qui {
                gstats transform `call' , by(`by') replace interval(-4 4) `0' excludeself
                gstats transform `call' , by(`by') replace interval( 4 8) `0' excludeself
                gstats transform `call' , by(`by') replace interval( 8 3) `0' excludeself
                gstats transform `call' , by(`by') replace interval(-4 .) `0' excludeself
                gstats transform `call' , by(`by') replace interval( . 4) `0' excludeself
                gstats transform `call' , by(`by') replace interval( . .) `0' excludeself
            }

            qui {
                gstats transform `call' [ w = gear_ratio * 10]      , by(`by') replace interval(-4 4) `0' excludeself
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 4 8) `0' excludeself
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 9 2) `0' excludeself
                gstats transform `call' [fw = int(gear_ratio * 10)] , by(`by') replace interval(-4 .) `0' excludeself
                gstats transform `call' [iw = gear_ratio / 10]      , by(`by') replace interval( . 4) `0' excludeself
                gstats transform `call' [pw = gear_ratio / 10]      , by(`by') replace interval( . .) `0' excludeself
            }

            qui {
                gstats transform `call' , by(`by') replace interval(-4 4) `0' excludebounds
                gstats transform `call' , by(`by') replace interval( 4 8) `0' excludebounds
                gstats transform `call' , by(`by') replace interval( 8 3) `0' excludebounds
                gstats transform `call' , by(`by') replace interval(-4 .) `0' excludebounds
                gstats transform `call' , by(`by') replace interval( . 4) `0' excludebounds
                gstats transform `call' , by(`by') replace interval( . .) `0' excludebounds
            }

            qui {
                gstats transform `call' [ w = gear_ratio * 10]      , by(`by') replace interval(-4 4) `0' excludebounds
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 4 8) `0' excludebounds
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 9 2) `0' excludebounds
                gstats transform `call' [fw = int(gear_ratio * 10)] , by(`by') replace interval(-4 .) `0' excludebounds
                gstats transform `call' [iw = gear_ratio / 10]      , by(`by') replace interval( . 4) `0' excludebounds
                gstats transform `call' [pw = gear_ratio / 10]      , by(`by') replace interval( . .) `0' excludebounds
            }
        }

        disp "`by' (combo)"
        qui sysuse auto, clear
        qui keep if mod(_n, 3) == 0
        qui replace mpg = . if mod(_n, 19) == 0
        local sl: copy local stat
        local ul: copy local stat

        foreach stat in `stats' `selections' `percentiles' {
            disp "    `stat'"

            local s1  ( range mean       -3`sl'  5.5`ul'  gear_ratio ) p1  = price       // g1  = weight
            local s2  ( range mean        3      .                   ) p2  = price       // g2  = weight
            local s3  ( range nmissing   -3`sl'  5.5`ul'             ) p3  = gear_ratio  // g3  = weight
            local s4  ( range sum        -3`sl' -1`ul'               ) p4  = gear_ratio  // g4  = weight
            local s5  ( range mean     7.33`sl'  3`ul'               ) p5  = gear_ratio  // g5  = weight
            local s6  ( range geomean     2`sl'  6.25`ul'            ) p6  = gear_ratio  // g6  = weight
            local s7  ( range cv         -3`sl'  .                   ) p7  = gear_ratio  // g7  = weight
            local s8  ( range sd          .      3`ul'               ) p8  = gear_ratio  // g8  = weight
            local s9  ( range variance   -3`sl' -1`ul'    length     ) p9  = gear_ratio  // g9  = weight
            local s10 ( range max      7.33`sl'  3`ul'    length     ) p10 = price       // g10 = weight
            local s11 ( range min         .     -3`ul'               ) p11 = price       // g11 = weight
            local s12 ( range range       2`sl'  6.25`ul' gear_ratio ) p12 = price       // g12 = weight
            local s13 ( range count       3      .                   ) p13 = price       // g13 = weight
            local s14 ( range first      -3`sl'  .        gear_ratio ) p14 = price       // g14 = weight
            local s15 ( range last        .      3`ul'    mpg        ) p15 = price       // g15 = weight
            local s16 ( range mean        .     -3`ul'    mpg        ) p16 = price       // g16 = weight
            local s17 ( range firstnm    -3`sl'  5.5                 ) p17 = price       // g17 = weight
            local s18 ( range lastnm      3      .        mpg        ) p18 = price       // g18 = weight
            local s19 ( range median     -3`sl'  5.5      gear_ratio ) p19 = price       // g19 = weight
            local s20 ( range iqr        -3     -1`ul'               ) p20 = price       // g20 = weight
            local s21 ( range skew       -3     -1`ul'    gear_ratio ) p21 = price       // g21 = weight
            local s22 ( range kurt                                   ) p22 = price       // g22 = weight

            local call
            forvalues i = 1 / 22 {
                local call `call' `s`i''
            }

            qui {
                gstats transform `call' , by(`by') replace interval(-4 4) `0'
                gstats transform `call' , by(`by') replace interval( 4 8) `0'
                gstats transform `call' , by(`by') replace interval( 8 3) `0'
                gstats transform `call' , by(`by') replace interval(-4 .) `0'
                gstats transform `call' , by(`by') replace interval( . 4) `0'
                gstats transform `call' , by(`by') replace interval( . .) `0'
            }

            qui {
                gstats transform `call' [ w = gear_ratio * 10]      , by(`by') replace interval(-4 4) `0'
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 4 8) `0'
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 9 2) `0'
                gstats transform `call' [fw = int(gear_ratio * 10)] , by(`by') replace interval(-4 .) `0'
                gstats transform `call' [iw = gear_ratio / 10]      , by(`by') replace interval( . 4) `0'
                gstats transform `call' [pw = gear_ratio / 10]      , by(`by') replace interval( . .) `0'
            }

            qui {
                gstats transform `call' , by(`by') replace interval(-4 4) `0' excludeself
                gstats transform `call' , by(`by') replace interval( 4 8) `0' excludeself
                gstats transform `call' , by(`by') replace interval( 8 3) `0' excludeself
                gstats transform `call' , by(`by') replace interval(-4 .) `0' excludeself
                gstats transform `call' , by(`by') replace interval( . 4) `0' excludeself
                gstats transform `call' , by(`by') replace interval( . .) `0' excludeself
            }

            qui {
                gstats transform `call' [ w = gear_ratio * 10]      , by(`by') replace interval(-4 4) `0' excludeself
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 4 8) `0' excludeself
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 9 2) `0' excludeself
                gstats transform `call' [fw = int(gear_ratio * 10)] , by(`by') replace interval(-4 .) `0' excludeself
                gstats transform `call' [iw = gear_ratio / 10]      , by(`by') replace interval( . 4) `0' excludeself
                gstats transform `call' [pw = gear_ratio / 10]      , by(`by') replace interval( . .) `0' excludeself
            }

            qui {
                gstats transform `call' , by(`by') replace interval(-4 4) `0' excludebounds
                gstats transform `call' , by(`by') replace interval( 4 8) `0' excludebounds
                gstats transform `call' , by(`by') replace interval( 8 3) `0' excludebounds
                gstats transform `call' , by(`by') replace interval(-4 .) `0' excludebounds
                gstats transform `call' , by(`by') replace interval( . 4) `0' excludebounds
                gstats transform `call' , by(`by') replace interval( . .) `0' excludebounds
            }

            qui {
                gstats transform `call' [ w = gear_ratio * 10]      , by(`by') replace interval(-4 4) `0' excludebounds
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 4 8) `0' excludebounds
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 9 2) `0' excludebounds
                gstats transform `call' [fw = int(gear_ratio * 10)] , by(`by') replace interval(-4 .) `0' excludebounds
                gstats transform `call' [iw = gear_ratio / 10]      , by(`by') replace interval( . 4) `0' excludebounds
                gstats transform `call' [pw = gear_ratio / 10]      , by(`by') replace interval( . .) `0' excludebounds
            }
        }
    }

    *******************
    *  Non-moving by  *
    *******************

    foreach by in foreign rep78 mpg {
        sysuse auto, clear

        gegen _m1 = mean(price),   by(`by')
        gegen _s1 = sd(price),     by(`by')
        gegen _d1 = median(price), by(`by')
        gen   _x1 = (price - _m1) / _s1
        gen   _x3 = (price - _m1)
        gen   _x4 = (price - _d1)

        gegen x1 = normalize(price),   by(`by') `0' labelf(#stat:pretty# #sourcelabel#) replace
        gegen x2 = standardize(price), by(`by') `0'
        gegen x3 = demean(price),      by(`by') `0'
        gegen x4 = demedian(price),    by(`by') `0'

        gen diff1 = abs(x1 - _x1) / max(min(abs(x1), abs(_x1)), 1)
        gen diff2 = abs(x2 - _x1) / max(min(abs(x2), abs(_x1)), 1)
        gen diff3 = abs(x3 - _x3) / max(min(abs(x3), abs(_x3)), 1)
        gen diff4 = abs(x4 - _x4) / max(min(abs(x4), abs(_x4)), 1)

        assert (diff1 < 1e-3) | mi(diff1)
        assert (diff2 < 1e-3) | mi(diff2)
        assert (diff3 < 1e-3) | mi(diff3)
        assert (diff4 < 1e-3) | mi(diff4)
    }

    foreach by in foreign rep78 mpg {
        sysuse auto, clear

        gegen _m1 = mean(price)   [aw = gear_ratio * 10], by(`by')
        gegen _s1 = sd(price)     [aw = gear_ratio * 10], by(`by')
        gegen _d1 = median(price) [pw = gear_ratio / 10], by(`by')
        gen   _x1 = (price - _m1) / _s1
        gen   _x3 = (price - _m1)
        gen   _x4 = (price - _d1)

        gegen x1 = normalize(price)   [aw = gear_ratio * 10], by(`by') `0' labelf(#stat:pretty# #sourcelabel#) replace
        gegen x2 = standardize(price) [aw = gear_ratio * 10], by(`by') `0'
        gegen x3 = demean(price)      [aw = gear_ratio * 10], by(`by') `0'
        gegen x4 = demedian(price)    [pw = gear_ratio / 10], by(`by') `0'

        gen diff1 = abs(x1 - _x1) / max(min(abs(x1), abs(_x1)), 1)
        gen diff2 = abs(x2 - _x1) / max(min(abs(x2), abs(_x1)), 1)
        gen diff3 = abs(x3 - _x3) / max(min(abs(x3), abs(_x3)), 1)
        gen diff4 = abs(x4 - _x4) / max(min(abs(x4), abs(_x4)), 1)

        assert (diff1 < 1e-3) | mi(diff1)
        assert (diff2 < 1e-3) | mi(diff2)
        assert (diff3 < 1e-3) | mi(diff3)
        assert (diff4 < 1e-3) | mi(diff4)
    }

    foreach by in foreign rep78 mpg {
        sysuse auto, clear

        gegen _m1 = mean(price)   [fw = int(gear_ratio * 10)], by(`by')
        gegen _s1 = sd(price)     [fw = int(gear_ratio * 10)], by(`by')
        gegen _d1 = median(price) [iw = gear_ratio / 10],      by(`by')
        gen   _x1 = (price - _m1) / _s1
        gen   _x3 = (price - _m1)
        gen   _x4 = (price - _d1)

        gegen x1 = normalize(price)   [fw = int(gear_ratio * 10)], by(`by') `0' labelf(#stat:pretty# #sourcelabel#) replace
        gegen x2 = standardize(price) [fw = int(gear_ratio * 10)], by(`by') `0'
        gegen x3 = demean(price)      [fw = int(gear_ratio * 10)], by(`by') `0'
        gegen x4 = demedian(price)    [iw = gear_ratio / 10],      by(`by') `0'

        gen diff1 = abs(x1 - _x1) / max(min(abs(x1), abs(_x1)), 1)
        gen diff2 = abs(x2 - _x1) / max(min(abs(x2), abs(_x1)), 1)
        gen diff3 = abs(x3 - _x3) / max(min(abs(x3), abs(_x3)), 1)
        gen diff4 = abs(x4 - _x4) / max(min(abs(x4), abs(_x4)), 1)

        assert (diff1 < 1e-3) | mi(diff1)
        assert (diff2 < 1e-3) | mi(diff2)
        assert (diff3 < 1e-3) | mi(diff3)
        assert (diff4 < 1e-3) | mi(diff4)
    }
end

capture program drop compare_gstats_transform
program compare_gstats_transform
    syntax, [weights *]

    qui `noisily' gen_data, n(500)
    qui expand 20
    qui `noisily' random_draws, random(5) double
    gen long   ix = _n
    gen double ru = runiform() * 500
    qui replace ix = . if mod(_n, 500) == 0
    qui replace ru = . if mod(_n, 500) == 0
    qui sort random1

    local N = trim("`: di %15.0gc _N'")
    di _n(1) "{hline 80}" _n(1) "compare_gstats_transform, N = `N', `options'" _n(1) "{hline 80}" _n(1)

    if ( `"`weights'"' != "" ) {

        qui {
            gen unif_0_100     = 100 * runiform() if mod(_n, 100)
            gen int_unif_0_100 = int(100 * runiform()) if mod(_n, 100)
            gen float_unif_0_1 = runiform() if mod(_n, 100)
            gen rnormal_0_10   = 10 * rnormal() if mod(_n, 100)
        }

        local wcall_a  wgt([aw = unif_0_100])
        local wcall_f  wgt([fw = int_unif_0_100])
        local wcall_a2 wgt([aw = float_unif_0_1])
        local wcall_i  wgt([iw = rnormal_0_10])

        compare_inner_gstats_transform, `options' `wcall_a'
        disp

        compare_inner_gstats_transform in 1 / 5, `options' `wcall_f'
        disp

        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        compare_inner_gstats_transform in `from' / `to', `options' `wcall_a2'
        disp

        compare_inner_gstats_transform if random2 > 0, `options' `wcall_i'
        disp

        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        compare_inner_gstats_transform if random2 < 0 in `from' / `to', `options' `wcall_a'
        disp
    }
    else {
        compare_inner_gstats_transform, `options'
        disp

        compare_inner_gstats_transform in 1 / 5, `options'
        disp

        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        compare_inner_gstats_transform in `from' / `to', `options'
        disp

        compare_inner_gstats_transform if random2 > 0, `options'
        disp

        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        compare_inner_gstats_transform if random2 < 0 in `from' / `to', `options'
        disp
    }
end

capture program drop compare_inner_gstats_transform
program compare_inner_gstats_transform
    syntax [if] [in], [wgt(passthru) *]

    * ---------------------------------------------------------------------

    compare_fail_gstats_transform versus_gstats_transform                         `if' `in', `options' `wgt'

    compare_fail_gstats_transform versus_gstats_transform str_12                  `if' `in', `options' `wgt'
    compare_fail_gstats_transform versus_gstats_transform str_12 str_32 str_4     `if' `in', `options' `wgt'

    compare_fail_gstats_transform versus_gstats_transform double1                 `if' `in', `options' `wgt'
    compare_fail_gstats_transform versus_gstats_transform double1 double2 double3 `if' `in', `options' `wgt'

    compare_fail_gstats_transform versus_gstats_transform int1                    `if' `in', `options' `wgt'
    compare_fail_gstats_transform versus_gstats_transform int1 int2               `if' `in', `options' `wgt'
    compare_fail_gstats_transform versus_gstats_transform int1 int2 int3          `if' `in', `options' `wgt'

    compare_fail_gstats_transform versus_gstats_transform str_32 int3 double3     `if' `in', `options' `wgt'
    compare_fail_gstats_transform versus_gstats_transform int1 double2 double3    `if' `in', `options' `wgt'
    compare_fail_gstats_transform versus_gstats_transform double? str_* int?      `if' `in', `options' `wgt'

    * ---------------------------------------------------------------------

    if ( `"`wgt'"' == "" ) {
        compare_fail_gstats_transform versus_gstats_transform_moving                         `if' `in', `options' `wgt' pr(rangestat w/index)

        compare_fail_gstats_transform versus_gstats_transform_moving str_12                  `if' `in', `options' `wgt' pr(rangestat w/index)
        compare_fail_gstats_transform versus_gstats_transform_moving str_12 str_32 str_4     `if' `in', `options' `wgt' pr(rangestat w/index)

        compare_fail_gstats_transform versus_gstats_transform_moving double1                 `if' `in', `options' `wgt' pr(rangestat w/index)
        compare_fail_gstats_transform versus_gstats_transform_moving double1 double2 double3 `if' `in', `options' `wgt' pr(rangestat w/index)

        compare_fail_gstats_transform versus_gstats_transform_moving int1                    `if' `in', `options' `wgt' pr(rangestat w/index)
        compare_fail_gstats_transform versus_gstats_transform_moving int1 int2               `if' `in', `options' `wgt' pr(rangestat w/index)
        compare_fail_gstats_transform versus_gstats_transform_moving int1 int2 int3          `if' `in', `options' `wgt' pr(rangestat w/index)

        compare_fail_gstats_transform versus_gstats_transform_moving str_32 int3 double3     `if' `in', `options' `wgt' pr(rangestat w/index)
        compare_fail_gstats_transform versus_gstats_transform_moving int1 double2 double3    `if' `in', `options' `wgt' pr(rangestat w/index)
        compare_fail_gstats_transform versus_gstats_transform_moving double? str_* int?      `if' `in', `options' `wgt' pr(rangestat w/index)
    }

    * ---------------------------------------------------------------------

    if ( `"`wgt'"' == "" ) {
        compare_fail_gstats_transform versus_gstats_transform_range                         `if' `in', `options' `wgt' pr(rangestat)

        compare_fail_gstats_transform versus_gstats_transform_range str_12                  `if' `in', `options' `wgt' pr(rangestat)
        compare_fail_gstats_transform versus_gstats_transform_range str_12 str_32 str_4     `if' `in', `options' `wgt' pr(rangestat)

        compare_fail_gstats_transform versus_gstats_transform_range double1                 `if' `in', `options' `wgt' pr(rangestat)
        compare_fail_gstats_transform versus_gstats_transform_range double1 double2 double3 `if' `in', `options' `wgt' pr(rangestat)

        compare_fail_gstats_transform versus_gstats_transform_range int1                    `if' `in', `options' `wgt' pr(rangestat)
        compare_fail_gstats_transform versus_gstats_transform_range int1 int2               `if' `in', `options' `wgt' pr(rangestat)
        compare_fail_gstats_transform versus_gstats_transform_range int1 int2 int3          `if' `in', `options' `wgt' pr(rangestat)

        compare_fail_gstats_transform versus_gstats_transform_range str_32 int3 double3     `if' `in', `options' `wgt' pr(rangestat)
        compare_fail_gstats_transform versus_gstats_transform_range int1 double2 double3    `if' `in', `options' `wgt' pr(rangestat)
        compare_fail_gstats_transform versus_gstats_transform_range double? str_* int?      `if' `in', `options' `wgt' pr(rangestat)
    }
end

capture program drop compare_fail_gstats_transform
program compare_fail_gstats_transform
    gettoken cmd 0: 0
    syntax [anything] [if] [in], [tol(real 1e-6) PRogram(str) *]
    cap `cmd' `0'
    if ( _rc ) {
        if ( "`if'`in'" == "" ) {
            di "    compare_gstats_transform (failed): full range (vs `program') `anything'; `options'"
        }
        else if ( "`if'`in'" != "" ) {
            di "    compare_gstats_transform (failed): [`if'`in'] (vs `program') `anything'; `options'"
        }
        exit _rc
    }
    else {
        if ( "`if'`in'" == "" ) {
            di "    compare_gstats_transform (passed): full range, gstats results equal to `program' (tol = `tol'; `anything'; `options')"
        }
        else if ( "`if'`in'" != "" ) {
            di "    compare_gstats_transform (passed): [`if'`in'], gstats results equal to `program' (tol = `tol'; `anything'; `options')"
        }
    }
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

* di as txt _n(1)
* di as txt "Benchmark vs Summary, detail; obs = `N', J = `J' (in seconds)"
* di as txt "    sum, d | gstats sum, d | ratio (c/g) | varlist"
* di as txt "    ------ | ------------- | ----------- | -------"
* di as txt "           |               |             | int1
* di as txt "           |               |             | int2
* di as txt "           |               |             | int3
* di as txt "           |               |             | double1
* di as txt "           |               |             | double2
* di as txt "           |               |             | double3
* di as txt "           |               |             | int1 int2 int3 double1 double2 double3

capture program drop bench_gstats
program bench_gstats
    bench_gstats_winsor
end

capture program drop bench_gstats_winsor
program bench_gstats_winsor
    syntax, [tol(real 1e-6) bench(real 1) n(int 500) NOIsily *]

    qui gen_data, n(`n')
    qui expand `=100 * `bench''
    qui `noisily' random_draws, random(2) double
    qui hashsort random1

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    di as txt _n(1)
    di as txt "Benchmark vs winsor2, obs = `N', J = `J' (in seconds)"
    di as txt "    winsor | gstats winsor | ratio (c/g) | varlist"
    di as txt "    ------ | ------------- | ----------- | -------"

    versus_gstats_winsor, `options'

    versus_gstats_winsor str_12,              `options'
    versus_gstats_winsor str_12 str_32 str_4, `options'

    versus_gstats_winsor double1,                 `options'
    versus_gstats_winsor double1 double2 double3, `options'

    versus_gstats_winsor int1,           `options'
    versus_gstats_winsor int1 int2,      `options'
    versus_gstats_winsor int1 int2 int3, `options'

    versus_gstats_winsor str_32 int3 double3,  `options'
    versus_gstats_winsor int1 double2 double3, `options'

    di _n(1) "{hline 80}" _n(1) "bench_gstats_winsor, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop versus_gstats_winsor
program versus_gstats_winsor, rclass
    syntax [anything] [if] [in], [tol(real 1e-6) trim *]

    timer clear
    timer on 42
    qui winsor2 random2 `if' `in', by(`anything') s(_w1) `options' `trim'
    timer off 42
    qui timer list
    local time_winsor = r(t42)

    timer clear
    timer on 43
    qui gstats winsor random2 `if' `in', by(`anything') s(_w2) `options' `trim'
    timer off 43
    qui timer list
    local time_gwinsor = r(t43)

    cap assert (abs(random2_w1 - random2_w2) < `tol' | random2_w1 == random2_w2)
    if ( _rc & ("`trim'" != "") ) {
        disp as err "(warning: `r(N)' indiscrepancies might be due to a numerical precision bug in winsor2)"
    }
    else if ( _rc ) {
        exit _rc
    }
    qui drop random2_w*

    local rs = `time_winsor'  / `time_gwinsor'
    di as txt "    `:di %6.3g `time_winsor'' | `:di %13.3g `time_gwinsor'' | `:di %11.4g `rs'' | `anything'"
end

***********************************************************************
*                          Transform versus                           *
***********************************************************************

capture program drop versus_gstats_transform
program versus_gstats_transform, rclass
    syntax [anything] [if] [in], [tol(real 1e-6) wgt(str) *]

    local tcall1 (demean)    _out2 = random2 (demedian) _out3 = random3 (normalize) _out4 = random4 _out5 = random5
    local tcall2 (demean)    _out* = random*
    local tcall3 (normalize) _out* = random*
    local tcall4 (cumsum)    _out1 = random1 _out2 = random2 (cumsum +) _out3 = random3 (cumsum -) _out4 = random4 (cumsum + random3) _out5 = random5
    local tcall5 (rank)      _out* = random*
    local tcall6 (shift -1)  _out1 = random1 _out2 = random2 (shift +3) _out3 = random3 (shift -4) _out4 = random4 (shift 2) _out5 = random5

    local gcall1 (mean)   _goutm2   = random2 _goutm4 = random4 _goutm5 = random5 /*
              */ (sd)                         _gouts4 = random4 _gouts5 = random5 /*
              */ (median) _goutmed3 = random3
    local gcall2 (mean) _gout*  = random*
    local gcall3 (mean) _goutm* = random* (sd) _gouts* = random*

    local I = cond(`"`wgt'"' == "", 6, 4)
    forvalues i = 1 / `I' {
        local opts = cond(`i' != 5, "", "ties(. track . field .)")
        cap drop _out*

        timer clear
        timer on 42
        qui gstats transform `tcall`i'' `if' `in' `wgt', by(`anything') wild replace `options' `opts'
        timer off 42
        qui timer list
        local time_gtransform = r(t42)

        preserve
        gen long _sort = _n
        timer clear
        timer on 43
        if ( `i' == 1 ) {
            local start = 2
            qui {
                gcollapse `gcall`i'' `if' `in' `wgt', by(`anything') wild merge replace
                gen _gout2 = (random2 - _goutm2)
                gen _gout3 = (random3 - _goutmed3)
                gen _gout4 = (random4 - _goutm4) / _gouts4
                gen _gout5 = (random5 - _goutm5) / _gouts5
            }
        }
        else if ( `i' == 2 ) {
            local start = 1
            qui gcollapse `gcall`i'' `if' `in' `wgt', by(`anything') wild merge replace _subtract
        }
        else if ( `i' == 3 ) {
            local start = 1
            qui {
                gcollapse `gcall`i'' `if' `in' `wgt', by(`anything') wild merge replace
                gen _gout1 = (random1 - _goutm1) / _gouts1
                gen _gout2 = (random2 - _goutm2) / _gouts2
                gen _gout3 = (random3 - _goutm3) / _gouts3
                gen _gout4 = (random4 - _goutm4) / _gouts4
                gen _gout5 = (random5 - _goutm5) / _gouts5
            }
        }
        else if ( `i' == 4 ) {
            qui {
                local start = 1
                if ( `"`if'`in'"' != "" ) keep `if' `in'
                if ( `"`wgt'"' != "" ) {
                    local 0 `wgt'
                    syntax [aw fw pw iw]
                    tempvar w
                    gen double `w' `exp'
                    local w1 * `w'
                    local w2 & !mi(`w')
                }
                else {
                    local w1
                    local w2
                }

                if ( `"`anything'"' != "" ) {
                    sort `anything', stable
                    by `anything': gen _gout1 = sum(random1 `w1') if !mi(random1) `w2'
                    by `anything': gen _gout2 = sum(random2 `w1') if !mi(random2) `w2'
                    sort `anything' random3, stable
                    by `anything': gen _gout3 = sum(random3 `w1') if !mi(random3) `w2'
                    sort `anything' random3 random5, stable
                    by `anything': gen _gout5 = sum(random5 `w1') if !mi(random5) `w2'
                    gsort `anything' -random4 _sort
                    by `anything': gen _gout4 = sum(random4 `w1') if !mi(random4) `w2'
                }
                else {
                    gen _gout1 = sum(random1 `w1') if !mi(random1) `w2'
                    gen _gout2 = sum(random2 `w1') if !mi(random2) `w2'
                    sort random3, stable
                    gen _gout3 = sum(random3 `w1') if !mi(random3) `w2'
                    sort random3 random5, stable
                    gen _gout5 = sum(random5 `w1') if !mi(random5) `w2'
                    gsort -random4 _sort
                    gen _gout4 = sum(random4 `w1') if !mi(random4) `w2'
                }
            }
        }
        else if ( `i' == 5 ) {
            qui {
                local start = 1
                egen double _gout1 = rank(random1) `if' `in', by(`anything')
                egen double _gout2 = rank(random2) `if' `in', by(`anything') track
                egen double _gout3 = rank(random3) `if' `in', by(`anything')
                egen double _gout4 = rank(random4) `if' `in', by(`anything') field
                egen double _gout5 = rank(random5) `if' `in', by(`anything')
            }
        }
        else if ( `i' == 6 ) {
            qui {
                mark _touse `if' `in'
                sort `anything' _touse, stable
                local start = 1
                by `anything' _touse: gen `:type random1' _gout1 = random1[_n - 1] if _touse
                by `anything' _touse: gen `:type random2' _gout2 = random2[_n - 1] if _touse
                by `anything' _touse: gen `:type random3' _gout3 = random3[_n + 3] if _touse
                by `anything' _touse: gen `:type random4' _gout4 = random4[_n - 4] if _touse
                by `anything' _touse: gen `:type random5' _gout5 = random5[_n + 2] if _touse
            }
        }
        timer off 43
        qui timer list
        local time_manual = r(t43)

        sort _sort
        forvalues j = `start' / 5 {
            cap assert (abs((_gout`j' - _out`j') / max(abs(_gout`j'), 1)) < `tol' | _gout`j' == _out`j')
            if ( _rc ) {
                disp `j'
                exit _rc
            }
        }
        restore

        cap drop _*
        local rs = `time_manual'  / `time_gtransform'
        di as txt "    `:di %6.3g `time_manual'' | `:di %13.3g `time_gtransform'' | `:di %11.4g `rs'' | (`i') `anything'"
    }
end

capture program drop versus_gstats_transform_range
program versus_gstats_transform_range, rclass
    syntax [anything] [if] [in], [tol(real 1e-6) wgt(str) pr(str) *]

    local rcall1
    local rcall2
    local rcall3
    local rcall4

    local rcall1 `rcall1'  (count)    _out1  = random2
    local rcall1 `rcall1'  (first)    _out12 = random2
    local rcall1 `rcall1'  (firstnm)  _out13 = random2
    local rcall1 `rcall1'  (min)      _out9  = random2
    local rcall1 `rcall1'  (mean)     _out3  = random2

    local rcall2 `rcall2'  (missing)  _out2  = random2
    local rcall2 `rcall2'  (last)     _out14 = random2
    local rcall2 `rcall2'  (lastnm)   _out15 = random2
    local rcall2 `rcall2'  (max)      _out11 = random2
    local rcall2 `rcall2'  (sum)      _out4  = random2

    local rcall3 `rcall3'  (sd)       _out5  = random2
    local rcall3 `rcall3'  (variance) _out6  = random2

    local rcall4 `rcall4'  (skewness) _out7  = random2
    local rcall4 `rcall4'  (kurtosis) _out8  = random2
    local rcall4 `rcall4'  (median)   _out10 = random2

    local tcall1
    local tcall2
    local tcall3
    local tcall4

    local tcall1 `tcall1' (range count)    _gout1  = random2
    local tcall1 `tcall1' (range first)    _gout12 = random2
    local tcall1 `tcall1' (range firstnm)  _gout13 = random2
    local tcall1 `tcall1' (range min)      _gout9  = random2
    local tcall1 `tcall1' (range mean)     _gout3  = random2

    local tcall2 `tcall2' (range nmissing) _gout2  = random2
    local tcall2 `tcall2' (range last)     _gout14 = random2
    local tcall2 `tcall2' (range lastnm)   _gout15 = random2
    local tcall2 `tcall2' (range max)      _gout11 = random2
    local tcall2 `tcall2' (range sum)      _gout4  = random2

    local tcall3 `tcall3' (range sd)       _gout5  = random2
    local tcall3 `tcall3' (range variance) _gout6  = random2

    local tcall4 `tcall4' (range skewness) _gout7  = random2
    local tcall4 `tcall4' (range kurtosis) _gout8  = random2
    local tcall4 `tcall4' (range median)   _gout10 = random2

    local opts
    gegen double _sd = sd(random4) `if' `in' `wgt', by(`anything')
    qui gen double _low  = random4 - 0.75 * _sd
    qui gen double _high = random4 + 0.75 * _sd

    timer clear
    timer on 42
    qui gstats transform `tcall1'  `if' `in' `wgt', by(`anything') `options' interval(-0.5    0.5    random3)
    qui gstats transform `tcall2'  `if' `in' `wgt', by(`anything') `options' interval(-0.75sd 0.75sd random4)
    qui gstats transform `tcall3'  `if' `in' `wgt', by(`anything') `options' interval(-0.5      .    random3)
    qui gstats transform `tcall4'  `if' `in' `wgt', by(`anything') `options' interval(   .    0.5    random3)
    timer off 42
    qui timer list
    local time_gtransform = r(t42)

    timer clear
    timer on 43
    rangestat `rcall1' `if' `in' `wgt', by(`anything') interval(random3 -0.5   0.5)
    rangestat `rcall2' `if' `in' `wgt', by(`anything') interval(random4 _low _high)
    rangestat `rcall3' `if' `in' `wgt', by(`anything') interval(random3 -0.5     .)
    rangestat `rcall4' `if' `in' `wgt', by(`anything') interval(random3    .   0.5)
    timer off 43
    qui timer list
    local time_manual = r(t43)

    forvalues j = 1 / 15 {
        cap assert (((abs(_gout`j' - _out`j') / max(abs(_gout`j'), 1)) < `tol') | (_gout`j' == _out`j'))
        if ( _rc ) {
            disp `j'
            exit _rc
        }
    }
    * head random? _sd _low _high _gout4 _out4

    cap drop _*
    local rs = `time_manual'  / `time_gtransform'
    di as txt "    `:di %6.3g `time_manual'' | `:di %13.3g `time_gtransform'' | `:di %11.4g `rs'' | (`i') `anything'"
end

capture program drop versus_gstats_transform_moving
program versus_gstats_transform_moving, rclass
    syntax [anything] [if] [in], [tol(real 1e-6) wgt(str) pr(str) *]

    local rcall1
    local rcall2
    local rcall3

    local rcall1 `rcall1'  (count)    _out1  = random2
    local rcall1 `rcall1'  (first)    _out12 = random2
    local rcall1 `rcall1'  (firstnm)  _out13 = random2
    local rcall1 `rcall1'  (min)      _out9  = random2
    local rcall1 `rcall1'  (mean)     _out3  = random2

    local rcall2 `rcall2'  (missing)  _out2  = random2
    local rcall2 `rcall2'  (last)     _out14 = random2
    local rcall2 `rcall2'  (lastnm)   _out15 = random2
    local rcall2 `rcall2'  (max)      _out11 = random2
    local rcall2 `rcall2'  (sum)      _out4  = random2

    local rcall3 `rcall3'  (sd)       _out5  = random2
    local rcall3 `rcall3'  (variance) _out6  = random2
    local rcall3 `rcall3'  (skewness) _out7  = random2
    local rcall3 `rcall3'  (kurtosis) _out8  = random2
    local rcall3 `rcall3'  (median)   _out10 = random2

    local tcall1
    local tcall2
    local tcall3

    local tcall1 `tcall1' (moving count)    _gout1  = random2
    local tcall1 `tcall1' (moving first)    _gout12 = random2
    local tcall1 `tcall1' (moving firstnm)  _gout13 = random2
    local tcall1 `tcall1' (moving min)      _gout9  = random2
    local tcall1 `tcall1' (moving mean)     _gout3  = random2

    local tcall2 `tcall2' (moving nmissing) _gout2  = random2
    local tcall2 `tcall2' (moving last)     _gout14 = random2
    local tcall2 `tcall2' (moving lastnm)   _gout15 = random2
    local tcall2 `tcall2' (moving max)      _gout11 = random2
    local tcall2 `tcall2' (moving sum)      _gout4  = random2

    local tcall3 `tcall3' (moving sd)       _gout5  = random2
    local tcall3 `tcall3' (moving variance) _gout6  = random2
    local tcall3 `tcall3' (moving skewness) _gout7  = random2
    local tcall3 `tcall3' (moving kurtosis) _gout8  = random2
    local tcall3 `tcall3' (moving median)   _gout10 = random2

    if ( `"`anything'"' != "" ) {
        qui bys `anything': gen _index = _n
        qui bys `anything': gen _ilow  = _n > 5
        qui bys `anything': gen _ihigh = _n < (_N - 5 + 1)
    }
    else {
        qui gen _index = _n
        qui gen _ilow  = _n > 5
        qui gen _ihigh = _n < (_N - 5 + 1)
    }

    timer clear
    timer on 42
    qui gstats transform `tcall1'  `if' `in' `wgt', by(`anything') `options' window(-5 5)
    qui gstats transform `tcall2'  `if' `in' `wgt', by(`anything') `options' window(-5 .)
    qui gstats transform `tcall3'  `if' `in' `wgt', by(`anything') `options' window( . 5)
    timer off 42
    qui timer list
    local time_gtransform = r(t42)

    timer clear
    timer on 43
    qui rangestat `rcall1' `if' `in' `wgt', by(`anything') interval(_index -5 5)
    qui rangestat `rcall2' `if' `in' `wgt', by(`anything') interval(_index -5 .)
    qui rangestat `rcall3' `if' `in' `wgt', by(`anything') interval(_index  . 5)
    timer off 43
    qui timer list
    local time_manual = r(t43)

    qui {
        replace _out1  = . if _ilow == 0
        replace _out12 = . if _ilow == 0
        replace _out13 = . if _ilow == 0
        replace _out9  = . if _ilow == 0
        replace _out3  = . if _ilow == 0

        replace _out1  = . if _ihigh == 0
        replace _out12 = . if _ihigh == 0
        replace _out13 = . if _ihigh == 0
        replace _out9  = . if _ihigh == 0
        replace _out3  = . if _ihigh == 0

        replace _out2  = . if _ilow == 0
        replace _out14 = . if _ilow == 0
        replace _out15 = . if _ilow == 0
        replace _out11 = . if _ilow == 0
        replace _out4  = . if _ilow == 0

        replace _out5  = . if _ihigh == 0
        replace _out6  = . if _ihigh == 0
        replace _out7  = . if _ihigh == 0
        replace _out8  = . if _ihigh == 0
        replace _out10 = . if _ihigh == 0
    }

    forvalues j = 1 / 15 {
        cap assert (((abs(_gout`j' - _out`j') / max(abs(_gout`j'), 1)) < `tol') | (_gout`j' == _out`j'))
        if ( _rc ) {
            disp `j'
            gen _diff`j' = abs(_gout`j' - _out`j') / max(abs(_gout`j'), 1)
            * exit _rc
        }
    }

    cap drop _*
    local rs = `time_manual'  / `time_gtransform'
    di as txt "    `:di %6.3g `time_manual'' | `:di %13.3g `time_gtransform'' | `:di %11.4g `rs'' | (`i') `anything'"
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

    if ( `c(stata_version)' >= 14.1 ) {
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

    exit 0
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
    syntax, [tol(real 1e-6) NOIsily bench(int 1) n(int 500) *]

    qui `noisily' gen_data, n(`n')
    qui expand `=100 * `bench''
    qui `noisily' random_draws, random(2)
    qui gen rsort = rnormal()
    qui sort rsort

    compare_duplicates_internal str_12,              `options'
    compare_duplicates_internal str_12 str_32 str_4, `options'

    compare_duplicates_internal double1,                 `options'
    compare_duplicates_internal double1 double2 double3, `options'

    compare_duplicates_internal int1,           `options'
    compare_duplicates_internal int1 int2 int3, `options'

    compare_duplicates_internal str_32 int3 double3,  `options'
    compare_duplicates_internal int1 double2 double3, `options'
    compare_duplicates_internal double? str_* int?,   `options'

    if ( `c(stata_version)' >= 14.1 ) {
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
    syntax, [tol(real 1e-6) NOIsily bench(int 1) n(int 500) *]
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

    if ( `c(stata_version)' >= 14.1 ) {
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

    if ( `c(stata_version)' >= 14.1 ) {
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

    * 1.4.1 removed strL support in hashsort
    * if ( `c(stata_version)' >= 14.1 ) {
    *     local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
    *     checks_inner_hashsort -strL1,             `options' `forcestrl'
    *     checks_inner_hashsort strL1 -strL2,       `options' `forcestrl'
    *     checks_inner_hashsort strL1 -strL2 strL3, `options' `forcestrl'
    * }

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

    exit 0
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
    syntax, [tol(real 1e-6) NOIsily bench(int 1) n(int 500) benchmode *]
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

    * 1.4.1 removed strL support in hashsort
    * if ( `c(stata_version)' >= 14.1 ) {
    *     local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
    *     compare_gsort -strL1,             `options' mfirst `forcestrl'
    *     compare_gsort strL1 -strL2,       `options' mfirst `forcestrl'
    *     compare_gsort strL1 -strL2 strL3, `options' mlast  `forcestrl'
    * }

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

    * 1.4.1 removed strL support in hashsort
    * if ( `c(stata_version)' >= 14.1 ) {
    *     local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
    *     compare_sort strL1,             `options' mfirst `forcestrl'
    *     compare_sort strL1 strL2,       `options' mfirst `forcestrl'
    *     compare_sort strL1 strL2 strL3, `options' mlast  `forcestrl'
    * }

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
* Run

if ( `"`0'"' == "" ) local 0 dependencies basic_checks comparisons switches bench_test
main, `0'
