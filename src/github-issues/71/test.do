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

    * Run the things
    * --------------

    cap noi {
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
        * qui do docs/examples/gstats.do
        * qui do docs/examples/greshape.do
        * qui do docs/examples/gregress.do

        if ( `:list posof "dependencies" in options' ) {
            cap ssc install ralpha
            cap ssc install ftools
            cap ssc install unique
            cap ssc install winsor2
            cap ssc install distinct
            cap ssc install moremata
            cap ssc install fastxtile
            cap ssc install egenmisc
            cap ssc install egenmore
            cap ssc install rangestat
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

capture program drop checks_gregress
program checks_gregress
    basic_gregress
    coll_gregress
end

capture program drop basic_gregress
program basic_gregress
    local tol 1e-8

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

        qui gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', robust `r'
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', r
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4], t[1, cols(t)]
            mata se = t[2, 1::4], t[2, cols(t)]
            mata assert(max(reldif(b, GtoolsPoisson.b)) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se)) < `tol')
disp _skip(8) "check 1"
        qui gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', cluster(ship) `r'
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', cluster(ship)
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4], t[1, cols(t)]
            mata se = t[2, 1::4], t[2, cols(t)]
            mata assert(max(reldif(b, GtoolsPoisson.b)) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se)) < `tol')
disp _skip(8) "check 2"
        qui gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', by(by) robust `r'
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
        qui gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', by(by) cluster(ship) `r'
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
        qui gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', absorb(ship) r
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 i.ship `w', r
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4]
            mata se = t[2, 1::4]
            mata assert(max(reldif(b, GtoolsPoisson.b)) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se)) < `tol')
disp _skip(8) "check 5"
        qui gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', absorb(ship) cluster(ship)
        qui poisson accident op_75_79 co_65_69 co_70_74 co_75_79 i.ship `w', cluster(ship)
            mata t  = st_matrix("r(table)")
            mata b  = t[1, 1::4]
            mata se = t[2, 1::4]
            mata assert(max(reldif(b, GtoolsPoisson.b)) < `tol')
            mata assert(max(reldif(se, GtoolsPoisson.se)) < `tol')
disp _skip(8) "check 6"
        qui gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', by(by) absorb(ship) robust
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
        qui gpoisson accident op_75_79 co_65_69 co_70_74 co_75_79 `w', by(by) absorb(ship) cluster(ship)
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
            mata assert(all(GtoolsRegress.b  :== .))
            mata assert(all(GtoolsRegress.se :== .))

        qui greg price _h* `w', `r' absorb(headroom) noc
            mata assert(all(GtoolsRegress.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg) weight turn                              `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight turn              `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg weight turn                              `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight turn              `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio weight turn                       `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg) weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio weight                            `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg)                                          `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio _mpg)                          `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg                                          `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg                          `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio                                   `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio _mpg) weight                                   `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio _mpg) weight                   `avars' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _mpg weight                                   `w' , `gvce' `absorb' noc
                    qui ivregress 2sls price (mpg = gear_ratio) _mpg weight                   `avars' `w' , `vce' `small'   noc
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio) _gear_ratio weight                            `w' , `gvce' `absorb' noc
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = gear_ratio turn length _mpg) weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length _mpg) weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio turn length) _mpg weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg = gear_ratio turn length) _mpg weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg = gear_ratio turn) _turn _gear_ratio weight                             `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio _mpg turn) weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _mpg weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _mpg weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _gear_ratio weight                            `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio _mpg turn) _displacement weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) _displacement weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _displacement _mpg weight                                   `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement _mpg weight                   `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV)
                qui givregress price (mpg length = gear_ratio turn) _displacement _gear_ratio weight                            `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg length = gear_ratio _mpg turn) _displacement `dvars' weight                               `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio _mpg turn) _displacement `dvars' weight               `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length = gear_ratio turn) _displacement _mpg `dvars' weight                               `w' , `gvce' `absorb'
                    qui ivregress 2sls price (mpg length = gear_ratio turn) _displacement `dvars' _mpg weight               `avars' `w' , `vce' `small'
                    mata: check_gregress_consistency(`tol', 1, 1::GtoolsIV.kx, GtoolsIV, 4::`=3 + `:list sizeof dvars'')
                qui givregress price (mpg length = gear_ratio turn) _displacement _gear_ratio `dvars' weight                        `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (z1 z2 = gear_ratio _gear_ratio) weight turn `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
                    mata assert(all(GtoolsIV.se :== .))
                qui givregress price (mpg = z1 z2) weight turn                    `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))                           
                    mata assert(all(GtoolsIV.se :== .))                           
                qui givregress price (z1 = z2) weight turn                        `w' , `gvce' `absorb'
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))
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
                    mata assert(all(GtoolsIV.b  :== .))                             
                    mata assert(all(GtoolsIV.se :== .))                             
                qui givregress price (z1 z2 = gear_ratio _gear_ratio) weight turn   `w' , `gvce' `absorb' `by'
                    mata assert(all(GtoolsIV.b  :== .))                             
                    mata assert(all(GtoolsIV.se :== .))                             
                qui givregress price (mpg = z1 z2) weight turn                      `w' , `gvce' `absorb' `by'
                    mata assert(all(GtoolsIV.b  :== .))                             
                    mata assert(all(GtoolsIV.se :== .))                             
                qui givregress price (z1 = z2) weight turn                          `w' , `gvce' `absorb' `by'
                    mata assert(all(GtoolsIV.b  :== .))                             
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

        qui gpoisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w', robust `r'
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w', r
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson)
disp _skip(8) "check 1"
        qui gpoisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w', cluster(ship) `r'
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w', cluster(ship)
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson)
disp _skip(8) "check 2"
        qui gpoisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w', by(by) robust `r'
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w' if by == 0.5, r
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson)
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w' if by == 1.5, r
            mata: check_gregress_consistency(`tol', 2, 1::GtoolsPoisson.kx, GtoolsPoisson)
disp _skip(8) "check 3"
        qui gpoisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w', by(by) cluster(ship) `r'
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w' if by == 0.5, cluster(ship)
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson)
        qui poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `w' if by == 1.5, cluster(ship)
            mata: check_gregress_consistency(`tol', 2, 1::GtoolsPoisson.kx, GtoolsPoisson)
disp _skip(8) "check 4"
        qui gpoisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars'        `w', absorb(ship) r
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars' i.ship `w', r
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson, 7::`=6 + `:list sizeof svars'')
disp _skip(8) "check 5"
        qui gpoisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars'        `w', absorb(ship) cluster(ship)
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars' i.ship `w', cluster(ship)
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson, 7::`=6 + `:list sizeof svars'')
disp _skip(8) "check 6"
        qui gpoisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars'        `w', by(by) absorb(ship) robust
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars' i.ship `w' if by == 0.5, r
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson, 7::`=6 + `:list sizeof svars'')
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars' i.ship `w' if by == 1.5, r
            mata: check_gregress_consistency(`tol', 2, 1::GtoolsPoisson.kx, GtoolsPoisson, 7::`=6 + `:list sizeof svars'')
disp _skip(8) "check 7"
        qui gpoisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars'        `w', by(by) absorb(ship) cluster(ship)
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars' i.ship `w' if by == 0.5, cluster(ship)
            mata: check_gregress_consistency(`tol', 1, 1::GtoolsPoisson.kx, GtoolsPoisson, 7::`=6 + `:list sizeof svars'')
        qui  poisson accident op_75_79 co_75_79 co_65_69 co_70_74 co_75_79 co_70_74 `svars' i.ship `w' if by == 1.5, cluster(ship)
            mata: check_gregress_consistency(`tol', 2, 1::GtoolsPoisson.kx, GtoolsPoisson, 7::`=6 + `:list sizeof svars'')
disp _skip(8) "check 8"

        qui gpoisson accident z1 z2 `w', robust noc
            mata assert(all(GtoolsPoisson.b  :== .))
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

checks_gregress,  `noisily' oncollision(error)
