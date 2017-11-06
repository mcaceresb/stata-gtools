* capture program drop checks_levelsof
* program checks_levelsof
*     syntax, [tol(real 1e-6) NOIsily *]
*     di _n(1) "{hline 80}" _n(1) "checks_levelsof, `options'" _n(1) "{hline 80}" _n(1)
*
*     qui `noisily' gen_data, n(50)
*     qui expand 200
*     gen long ix = _n
*
*     checks_inner_levelsof str_12,              `options'
*     checks_inner_levelsof str_12 str_32,       `options'
*     checks_inner_levelsof str_12 str_32 str_4, `options'
*
*     checks_inner_levelsof double1,                 `options'
*     checks_inner_levelsof double1 double2,         `options'
*     checks_inner_levelsof double1 double2 double3, `options'
*
*     checks_inner_levelsof int1,           `options'
*     checks_inner_levelsof int1 int2,      `options'
*     checks_inner_levelsof int1 int2 int3, `options'
*
*     checks_inner_levelsof int1 str_32 double1,                                        `options'
*     checks_inner_levelsof int1 str_32 double1 int2 str_12 double2,                    `options'
*     checks_inner_levelsof int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'
*
*     clear
*     gen x = 1
*     cap glevelsof x
*     assert _rc == 2000
*
*     clear
*     set obs 100000
*     gen x = _n
*     cap glevelsof x in 1 / 10000 if mod(x, 3) == 0
*     assert _rc == 0
* end
*
* capture program drop checks_inner_levelsof
* program checks_inner_levelsof
*     syntax varlist, [*]
*     cap noi glevelsof `varlist', `options' v bench clean silent
*     assert _rc == 0
*
*     cap glevelsof `varlist' in 1, `options' silent miss
*     assert _rc == 0
*
*     cap glevelsof `varlist' in 1, `options' miss
*     assert _rc == 0
*
*     cap glevelsof `varlist' if _n == 1, `options' local(hi) miss
*     assert _rc == 0
*     assert `"`r(levels)'"' == `"`hi'"'
*
*     cap glevelsof `varlist' if _n < 10 in 5, `options' s(" | ") cols(", ") miss
*     assert _rc == 0
* end

***********************************************************************
*                               Compare                               *
***********************************************************************

* compare_xtile, n(100000)  bench(5)
* compare_xtile, n(1000000) bench(5)

* pctile, xtile tests
*     - nquantiles
*     - cutpoints
*     - quantiles
*     - cutoffs
*     - cutquantiles
* _pctile tests
*     - nquantiles
*     - cutpoints (fail w/o gen)
*     - quantiles
*     - cutoffs (fail w/o bincount)
*     - cutquantiles (fail w/o gen)
* options (all):
*     - altdef 
*     - genp()
*     - bincount 
*     - pctile() with xtile
*     - xtile() with pctile
* consistency, xtile:
*     - xtile,  nquantiles()   == xtile, cutpoints(pctile, nquantiles())
*     - xtile,  cutpoints()    == xtile, cutoffs()
*     - xtile,  cutquantiles() == xtile, quantiles()
* consistency, pctile == _pctile:
*     - nquantiles
*     - cutpoints
*     - quantiles
*     - cutoffs
*     - cutquantiles
* sanity:
*     - replace
*     - strict
*     - minmax
* todo:
*     by(str)
*     method

capture program drop bench_gquantiles
program bench_gquantiles
    syntax, [bench(int 10) n(int 10000) *]
    compare_inner_quantiles, n(`n') bench(`bench') benchmode qopts(nq(10))  qwhich(_pctile)
    compare_inner_quantiles, n(`n') bench(`bench') benchmode qopts(p(0.1 5 10 30 50 70 90 95 99.9))  qwhich(_pctile)
    compare_inner_quantiles, n(`n') bench(`bench') benchmode qopts(nq(10))  qwhich(xtile)
    compare_inner_quantiles, n(`n') bench(`bench') benchmode qopts(nq(10))  qwhich(pctile)
end

capture program drop compare_gquantiles
program compare_gquantiles
    syntax, [bench(int 10) n(int 10000) *]

    compare_inner_quantiles, n(`n') bench(`bench') qopts(p(0.1 5 10 30 50 70 90 95 99.9)) qwhich(_pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(801)) qwhich(_pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(100)) qwhich(_pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(10))  qwhich(_pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(2))   qwhich(_pctile) `options'

    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef p(0.1 5 10 30 50 70 90 95 99.9)) qwhich(_pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(801)) qwhich(_pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(100)) qwhich(_pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(10))  qwhich(_pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(2))   qwhich(_pctile) `options'

    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(500))  qwhich(xtile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(100))  qwhich(xtile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(10))   qwhich(xtile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(2))    qwhich(xtile) `options'

    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(500))  qwhich(xtile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(100))  qwhich(xtile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(10))   qwhich(xtile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(2))    qwhich(xtile) `options'

    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(500))  qwhich(pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(100))  qwhich(pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(10))   qwhich(pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(nq(2))    qwhich(pctile) `options'

    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(500))  qwhich(pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(100))  qwhich(pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(10))   qwhich(pctile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(2))    qwhich(pctile) `options'
end

capture program drop compare_inner_quantiles
program compare_inner_quantiles
    syntax, [bench(int 5) n(real 100000) benchmode *]
    local options `options' `benchmode'

    qui `noisily' gen_data, n(`n') random(2) double skipstr
    qui expand `bench'
    gen long   ix = _n
    gen double ru = rnormal() * 100
    qui replace ix = . if mod(_n, `n') == 0
    qui replace ru = . if mod(_n, `n') == 0
    qui sort random1

    _compare_inner_gquantiles, `options'

    if ( "`benchmode'" == "" ) {
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
    syntax [if] [in], [tol(real 1e-6) NOIsily qopts(str) qwhich(str) benchmode table *]

    if ( "`if'`in'" != "" ) {
        local ifinstr ""
        if ( "`if'" != "" ) local ifinstr `ifinstr' [`if']
        if ( "`in'" != "" ) local ifinstr `ifinstr' [`in']
    }

    local options `options' `benchmode' `table' qopts(`qopts')

    local N = trim("`: di %15.0gc _N'")
    di as txt _n(1)
    di as txt "Compare `qwhich'"
    di as txt "     - opts:  `qopts'"
    di as txt "     - if in: `ifinstr'"
    di as txt "     - obs:   `N'"
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

    _compare_inner_`qwhich' double1 `if' `in', `options' note("~ U(0,  1000), no missings, groups of size `bench'")
    _compare_inner_`qwhich' double3 `if' `in', `options' note("~ N(10, 5), many missings, groups of size `bench'")
    _compare_inner_`qwhich' ru      `if' `in', `options' note("~ N(0, 100), few missings, unique")

    _compare_inner_`qwhich' int1 `if' `in', `options' note("discrete (no missings, many groups)")
    _compare_inner_`qwhich' int3 `if' `in', `options' note("discrete (many missings, few groups)")
    _compare_inner_`qwhich' ix   `if' `in', `options' note("discrete (few missings, unique)")

    _compare_inner_`qwhich' int1^2 + 3 * double1          `if' `in', `options'
    _compare_inner_`qwhich' 2 * int1 + log(double1)       `if' `in', `options'
    _compare_inner_`qwhich' int1 * double3 + exp(double3) `if' `in', `options'
end

***********************************************************************
*                              Internals                              *
***********************************************************************

capture program drop _compare_inner_xtile
program _compare_inner_xtile
    syntax anything [if] [in], [note(str) benchmode table qopts(str) *]
    tempvar xtile fxtile gxtile

    timer clear
    timer on 43
    qui gquantiles `gxtile' = `anything' `if' `in', xtile `qopts'
    timer off 43
    qui timer list
    local time_gxtile = r(t43)

    timer clear
    timer on 42
    qui xtile `xtile' = `anything' `if' `in', `qopts'
    timer off 42
    qui timer list
    local time_xtile = r(t42)

    timer clear
    timer on 44
    cap fastxtile `fxtile' = `anything' `if' `in', `qopts'
    local rc_f = _rc
    timer off 44
    qui timer list
    local time_fxtile = r(t44)
    if ( `rc_f' ) {
        local time_fxtile = .
        di "(note: fastxtile failed where xtile succeeded)"
    }

    cap assert `xtile' == `gxtile'
    if ( _rc ) {
        if ( strpos("`qopts'", "altdef") ) {
            local qopts: subinstr local qopts "altdef" " ", all
            qui gquantiles `anything' `if' `in', xtile(`gxtile') `qopts' replace
            cap assert `xtile' == `gxtile'
            if ( _rc ) {
                di as err "    compare_xtile (failed): gquantiles xtile = `anything' gave different levels to xtile"
            }
            else {
                di as err "    compare_xtile (???)"
                di as err "Note: gquantiles xtile = `anything', altdef gave different levels to xtile, altdef."
                di as err "However, gquantiles xtile = `anything' without altdef was the same.  On some systems,"
                di as err "xtile.ado has a typo in line 135. Change -altdev- to -altdef- and re-run the tests."
            }
            exit 198
        }
        else {
            di as err "    compare_xtile (failed): gquantiles xtile = `anything' gave different levels to xtile"
            cap assert `xtile' == `fxtile'
            if ( _rc & (`rc_f' == 0) ) {
                di as txt "    (note: fastxtile also gave different levels)"
            }
            exit 198
        }
    }

    cap assert `xtile' == `fxtile'
    if ( _rc & (`rc_f' == 0) ) {
        di as txt "    (note: fastxtile gave different levels to xtile)"
    }

    if ( "`benchmode'" == "" ) {
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
    syntax anything [if] [in], [note(str) benchmode table qopts(str) reltol(real 1e-9) tol(real 1e-6) note(str) *]
    tempvar pctile pctpct gpctile gpctpct

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
    qui gquantiles `gpctile' = `anything' `if' `in', pctile `gqopts'
    timer off 43
    qui timer list
    local time_gpctile = r(t43)

    timer clear
    timer on 42
    qui pctile `pctile' = `anything' `if' `in', `qopts'
    timer off 42
    qui timer list
    local time_pctile = r(t42)

    tempvar comp
    qui gen double `comp' = `pctile' * `reltol' if !mi(`pctile')
    qui replace `comp'    = cond(`comp' < `tol', `tol', `comp') if !mi(`pctile')
    cap assert abs(`pctile' - `gpctile') < `tol' | ( mi(`pctile') & mi(`gpctile'))
    if ( _rc ) {
        tempvar gpctile2
        qui gen `:type `pctile'' `gpctile2' = `gpctile'
        cap assert abs(`pctile' - `gpctile2') < `comp' | ( mi(`pctile') & mi(`gpctile'))
        if ( _rc ) {
            di as err "    compare_pctile (failed): gquantiles pctile = `anything' gave different percentiles to pctile (reltol = `reltol')"
            exit 198
        }
    }

    if ( "`benchmode'" == "" ) {
        cap assert abs(`pctpct' - `gpctpct') < `tol' | ( mi(`pctpct') & mi(`gpctpct'))
        if ( _rc ) {
            tempvar gpctpct2
            qui gen `:type `pctpct'' `gpctpct2' = `gpctpct'
            qui replace `comp' = `pctpct' * `reltol' if !mi(`pctpct')
            qui replace `comp' = cond(`comp' < `tol', `tol', `comp') if !mi(`pctpct')
            cap assert abs(`pctpct' - `gpctpct2') < `comp' | ( mi(`pctile') & mi(`gpctile'))
            if ( _rc ) {
                di as err "    compare_pctile (failed): gquantiles pctile = `anything', genp() gave different percentages to pctile, genp()"
                exit 198
            }
            else {
                di as txt "    compare_pctile (passed): gquantiles pctile = `anything', genp() gave similar results to pctile (reltol = `reltol', tol = `tol')"
            }
        }
        else {
            di as txt "    compare_pctile (passed): gquantiles pctile = `anything', genp() gave similar results to pctile (reltol = `reltol', tol = `tol')"
        }
    }

    if ( ("`table'" != "") | ("`benchmode'" != "") ) {
        local rs = `time_pctile'  / `time_gpctile'
        di as txt "    `:di %6.3g `time_pctile'' | `:di %10.3g `time_gpctile'' | `:di %11.3g `rs'' | `anything' (`note')"
    }
end

capture program drop _compare_inner__pctile
program _compare_inner__pctile
    syntax anything [if] [in], [benchmode table qopts(str) reltol(real 1e-9) tol(real 1e-6) note(str) *]
    tempvar exp
    qui gen double `exp' = `anything'

    timer clear
    timer on 43
    qui gquantiles `exp' `if' `in', _pctile `qopts' v bench(2)
    timer off 43
    qui timer list
    local time_gpctile = r(t43)
    local nq = `r(nqused)'
    forvalues q = 1 / `nq' {
        local qr_`q' = `r(r`q')'
    }

    timer clear
    timer on 42
    qui _pctile `exp' `if' `in', `qopts'
    timer off 42
    qui timer list
    local time_pctile = r(t42)
    forvalues q = 1 / `nq' {
        local r_`q' = `r(r`q')'
    }

    forvalues q = 1 / `nq' {
        if ( abs(`qr_`q'' - `r_`q'') > `tol' ) {
            local comp = `r_`q'' * `reltol'
            local comp = cond(`comp' < `tol', `tol', `comp')
            if ( abs(`qr_`q'' - `r_`q'') > `comp' ) {
                di as err "    compare__pctile (failed): gquantiles `anything', _pctile gave different percentiles to _pctile (reltol = `reltol')"
                exit 198
            }
        }
    }

    if ( "`benchmode'" == "" ) {
        di as txt "    compare_pctile (passed): gquantiles `anything', _pctile gave similar results to _pctile (reltol = `reltol', tol = `tol')"
    }

    if ( ("`table'" != "") | ("`benchmode'" != "") ) {
        local rs = `time_pctile'  / `time_gpctile'
        di as txt "    `:di %7.3g `time_pctile'' | `:di %10.3g `time_gpctile'' | `:di %11.3g `rs'' | `anything' (`note')"
    }
end
