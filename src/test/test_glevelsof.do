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
