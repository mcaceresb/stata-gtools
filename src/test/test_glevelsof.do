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
