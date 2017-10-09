capture program drop checks_levelsof
program checks_levelsof
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_levelsof, `options'" _n(1) "{hline 80}" _n(1)

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
    di _n(1) "{hline 80}" _n(1) "compare_levelsof, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' sim, n(500000) nj(10) njsub(4) string groupmiss outmiss
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
