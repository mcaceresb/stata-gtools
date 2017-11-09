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
*     - [X] binpct
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

    qui `noisily' gen_data, n(5000) random(2) skipstr
    qui expand 2
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
    checks_inner_gquantiles 2 * int1 + log(double1),       `options'
    checks_inner_gquantiles int1 * double3 + exp(double3), `options' method(1)
end

capture program drop checks_inner_gquantiles
program checks_inner_gquantiles
    syntax anything, [tol(real 1e-6) NOIsily *]
    cap drop __*
    local qui = cond("`noisily'" == "", "qui", "noisily")

    `qui' {
        gquantiles __p1 = `anything', pctile `options' nq(10)
        l in 1/10

        gquantiles __p2 = `anything', pctile `options' cutpoints(__p1)
        gquantiles __p3 = `anything', pctile `options' quantiles(10 30 50 70 90)
        gquantiles __p4 = `anything', pctile `options' cutoffs(10 30 50 70 90)
        cap gquantiles __p5 = `anything', pctile `options' cutquantiles(rn)
        assert _rc == 198
        gquantiles __p5 = `anything', pctile `options' cutquantiles(ru)

        gquantiles __x1 = `anything', xtile `options' nq(10)
        gquantiles __x2 = `anything', xtile `options' cutpoints(__p1)
        gquantiles __x3 = `anything', xtile `options' quantiles(10 30 50 70 90)
        gquantiles __x4 = `anything', xtile `options' cutoffs(10 30 50 70 90)
        cap gquantiles __x5 = `anything', xtile `options' cutquantiles(rn)
        assert _rc == 198
        gquantiles __x5 = `anything', xtile `options' cutquantiles(ru)

        gquantiles `anything', _pctile `options' nq(10)

        cap gquantiles `anything', _pctile `options' cutpoints(__p1)
        assert _rc == 198
        gquantiles `anything', _pctile `options' cutpoints(__p1) pctile(__p2) replace

        gquantiles `anything', _pctile `options' quantiles(10 30 50 70 90)

        cap gquantiles `anything', _pctile `options' cutoffs(10 30 50 70 90)
        assert _rc == 198
        gquantiles `anything', _pctile `options' cutoffs(10 30 50 70 90) binfreq

        cap gquantiles `anything', _pctile `options' cutquantiles(ru)
        assert _rc == 198
        gquantiles `anything', _pctile `options' cutpoints(__p1)  xtile(__x5) replace
    }

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
        assert _rc == 198
        cap gquantiles __p2 = `anything', pctile altdef binpct `options' cutpoints(__p1)
        assert _rc == 198
        gquantiles __p2 = `anything', pctile altdef binfreq(__f2) binpct(__fp2) `options' cutpoints(__p1)
        cap gquantiles __p2 = `anything', pctile altdef binfreq(__f2) binpct(__fp2) `options' cutpoints(__p1)
        assert _rc == 198
        gquantiles __p2 = `anything', pctile altdef binfreq(__f2) binpct(__fp2) `options' cutpoints(__p1) replace

        gquantiles __p3 = `anything', pctile altdef binfreq binpct `options' quantiles(10 30 50 70 90)
        matrix list r(quantiles_binfreq) 
        matrix list r(quantiles_binpct) 

        gquantiles __p4 = `anything', pctile altdef binfreq binpct `options' cutoffs(10 30 50 70 90)
        matrix list r(cutoffs_binfreq) 
        matrix list r(cutoffs_binpct) 

        cap gquantiles __p5 = `anything', pctile altdef binpct `options' cutquantiles(ru)
        assert _rc == 198
        cap gquantiles __p5 = `anything', pctile altdef binfreq `options' cutquantiles(ru)
        assert _rc == 198
        gquantiles __p5 = `anything', pctile altdef binfreq(__f5) binpct(__fp5)  `options' cutquantiles(ru)
        cap gquantiles __p5 = `anything', pctile altdef binfreq(__f5) binpct(__fp5)  `options' cutquantiles(ru)
        assert _rc == 198
        gquantiles __p5 = `anything', pctile altdef binfreq(__f5) binpct(__fp5)  `options' cutquantiles(ru) replace

        gquantiles __x1 = `anything', pctile altdef binfreq `options' nq(10) replace
        matrix list r(quantiles_binfreq) 



        gquantiles __x1 = `anything', pctile altdef binfreq `options' nq(10) replace
        cap gquantiles __x1 = `anything' in 1/5, pctile altdef binfreq `options' nq(10) replace
        assert inlist(_rc, 0, 2000)
        cap gquantiles __x1 = `anything' in 1/5, pctile altdef binfreq `options' nq(10) replace strict
        assert inlist(_rc, 198, 2000)

        cap gquantiles __x2 = `anything', pctile altdef binfreq `options' cutpoints(__p1)
        assert _rc == 198
        cap gquantiles __x2 = `anything', pctile altdef binpct `options' cutpoints(__p1)
        assert _rc == 198
        gquantiles __x2 = `anything', pctile altdef binfreq(__xf2) binpct(__fx2) `options' cutpoints(__p1)
        cap gquantiles __x2 = `anything', pctile altdef binfreq(__xf2) binpct(__fx2) `options' cutpoints(__p1)
        assert _rc == 198
        gquantiles __x2 = `anything', pctile altdef binfreq(__xf2) binpct(__fx2) `options' cutpoints(__p1) replace

        gquantiles __x3 = `anything', pctile altdef binfreq binpct `options' quantiles(10 30 50 70 90)
        matrix list r(quantiles_binfreq) 
        matrix list r(quantiles_binpct) 

        gquantiles __x4 = `anything', pctile altdef binfreq binpct `options' cutoffs(10 30 50 70 90)
        matrix list r(cutoffs_binfreq) 
        matrix list r(cutoffs_binpct) 

        cap gquantiles __x5 = `anything', pctile altdef binpct `options' cutquantiles(ru)
        assert _rc == 198
        cap gquantiles __x5 = `anything', pctile altdef binfreq `options' cutquantiles(ru)
        assert _rc == 198
        gquantiles __x5 = `anything', pctile altdef binfreq(__xf5) binpct(__fx5)  `options' cutquantiles(ru)
        cap gquantiles __x5 = `anything', pctile altdef binfreq(__xf5) binpct(__fx5)  `options' cutquantiles(ru)
        assert _rc == 198
        gquantiles __x5 = `anything', pctile altdef binfreq(__xf5) binpct(__fp5)  `options' cutquantiles(ru) replace



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
    syntax, [NOIsily *]
    local options `options' `noisily'

    compare_gquantiles_stata, n(10000) bench(10) `options'

    local N = trim("`: di %15.0gc _N'")
    di _n(1) "{hline 80}" _n(1) "consistency_gquantiles_pctile_xtile, N = `N', `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(10000) random(2) double skipstr
    qui expand 10
    gen long   ix = _n
    gen double ru = runiform() * 100
    qui replace ix = . if mod(_n, 10000) == 0
    qui replace ru = . if mod(_n, 10000) == 0
    qui sort random1

    _consistency_inner_gquantiles, `options'
    _consistency_inner_gquantiles in 1 / 5, `options' corners

    local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
    local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
    local from = cond(`in1' < `in2', `in1', `in2')
    local to   = cond(`in1' > `in2', `in1', `in2')
    _consistency_inner_gquantiles in `from' / `to', `options'

    _consistency_inner_gquantiles if random2 > 0, `options'

    local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
    local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
    local from = cond(`in1' < `in2', `in1', `in2')
    local to   = cond(`in1' > `in2', `in1', `in2')
    _consistency_inner_gquantiles `anything' if random2 < 0 in `from' / `to', `options'

    local N = trim("`: di %15.0gc _N'")
    di _n(1) "{hline 80}" _n(1) "consistency_gquantiles_internals, N = `N', `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop _consistency_inner_gquantiles
program _consistency_inner_gquantiles
    syntax [if] [in], [tol(real 1e-6) NOIsily corners *]

    if ( "`corners'" == "" ) {
    _consistency_inner_full double1 `if' `in', `options'
    _consistency_inner_full double3 `if' `in', `options'
    _consistency_inner_full ru      `if' `in', `options'

    _consistency_inner_full int1 `if' `in', `options'
    _consistency_inner_full int3 `if' `in', `options'
    _consistency_inner_full ix   `if' `in', `options'

    _consistency_inner_full int1^2 + 3 * double1          `if' `in', `options'
    _consistency_inner_full 2 * int1 + log(double1)       `if' `in', `options'
    _consistency_inner_full int1 * double3 + exp(double3) `if' `in', `options'
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
    syntax anything [if] [in], [*]

    if ( "`if'`in'" != "" ) {
        local ifinstr ""
        if ( "`if'" != "" ) local ifinstr `ifinstr' [`if']
        if ( "`in'" != "" ) local ifinstr `ifinstr' [`in']
    }

    local hlen = length("Internal consistency for gquantiles `anything', `ifinstr'")
    di as txt _n(1) "Internal consistency for gquantiles `anything', `ifinstr'" _n(1) "{hline `hlen'}" _n(1)

    _consistency_inner_nq `anything' `if' `in', `options' nq(2)
    _consistency_inner_nq `anything' `if' `in', `options' nq(10)
    _consistency_inner_nq `anything' `if' `in', `options' nq(100)
    _consistency_inner_nq `anything' `if' `in', `options' nq(801)
    _consistency_inner_nq `anything' `if' `in', `options' nq(`=_N + 1')

    _consistency_inner_nq `anything' `if' `in', altdef `options' nq(2)
    _consistency_inner_nq `anything' `if' `in', altdef `options' nq(10)
    _consistency_inner_nq `anything' `if' `in', altdef `options' nq(100)
    _consistency_inner_nq `anything' `if' `in', altdef `options' nq(801)
    _consistency_inner_nq `anything' `if' `in', altdef `options' nq(`=_N + 1')
end

capture program drop _consistency_inner_nq
program _consistency_inner_nq
    syntax anything [if] [in], [tol(real 1e-10) nq(real 2) *]
    cap drop __*
    local rc = 0

    qui {
    gquantiles __p1 = `anything' `if' `in', pctile `options' nq(`nq') genp(__g1) binfreq(__f1) binpct(__fp1) xtile(__x1)
    gquantiles __p2 = `anything' `if' `in', pctile `options' cutpoints(__p1) binfreq(__f2) binpct(__fp2) xtile(__x2)
    if ( `nq' <= 801 ) {
        glevelsof __g1, silent
        gquantiles __p3 = `anything' `if' `in', pctile `options' quantiles(`r(levels)') binfreq binpct binfreq(__f3) binpct(__fp3) xtile(__x3)
        scalar ___s3   = r(nqused)
        matrix ___mp3  = r(quantiles_used)
        matrix ___mf3  = r(quantiles_binfreq)
        matrix ___mfp3 = r(quantiles_binpct)

        glevelsof __p1, silent
        gquantiles __p4 = `anything' `if' `in', pctile `options' cutoffs(`r(levels)') binfreq binpct binfreq(__f4) binpct(__fp4) xtile(__x4)
        scalar ___s4   = r(nqused)
        matrix ___mp4  = r(cutoffs_used)
        matrix ___mf4  = r(cutoffs_binfreq)
        matrix ___mfp4 = r(cutoffs_binpct)
    }
    gquantiles __p5 = `anything' `if' `in', pctile `options' cutquantiles(__g1) binfreq(__f5) binpct(__fp5) xtile(__x5)
    }

    cap _compare_inner_nqvars `tol'
    if ( `rc' ) {
        di as err "    consistency_internal_gquantiles (failed): pctile via nq(`nq') `options' not all equal"
        exit `rc'
    }

    qui {
    cap drop __*
    gquantiles __x1 = `anything' `if' `in', xtile `options' nq(`nq') genp(__g1) binfreq(__f1) binpct(__fp1) pctile(__p1)
    gquantiles __x2 = `anything' `if' `in', xtile `options' cutpoints(__p1) binfreq(__f2) binpct(__fp2) pctile(__p2)
    if ( `nq' <= 801 ) {
        glevelsof __g1, silent
        gquantiles __x3 = `anything' `if' `in', xtile `options' quantiles(`r(levels)') binfreq binpct binfreq(__f3) binpct(__fp3) pctile(__p3)
        scalar ___s3   = r(nqused)
        matrix ___mp3  = r(quantiles_used)
        matrix ___mf3  = r(quantiles_binfreq)
        matrix ___mfp3 = r(quantiles_binpct)

        glevelsof __p1, silent
        gquantiles __x4 = `anything' `if' `in', xtile `options' cutoffs(`r(levels)') binfreq binpct binfreq(__f4) binpct(__fp4) pctile(__p4)
        scalar ___s4   = r(nqused)
        matrix ___mp4  = r(cutoffs_used)
        matrix ___mf4  = r(cutoffs_binfreq)
        matrix ___mfp4 = r(cutoffs_binpct)
    }
    gquantiles __x5 = `anything' `if' `in', xtile `options' cutquantiles(__g1) binfreq(__f5) binpct(__fp5) pctile(__p5)
    }

    cap _compare_inner_nqvars `tol'
    if ( `rc' ) {
        di as err "    consistency_internal_gquantiles (failed): xtile via nq(`nq') `options' not all equal"
        exit `rc'
    }

    qui if ( `nq' <= 801 ) {
        local options `options' returnlimit(1)
        gquantiles `anything' `if' `in', _pctile `options' nq(`nq') genp(__g1) binfreq(__f1) binpct(__fp1) pctile(__p1) xtile(__x1) replace
        gquantiles `anything' `if' `in', _pctile `options' cutpoints(__p1) binfreq(__f2) binpct(__fp2) pctile(__p2) xtile(__x2) replace

        glevelsof __g1, silent
        gquantiles `anything' `if' `in', _pctile `options' quantiles(`r(levels)') binfreq binpct binfreq(__f3) binpct(__fp3) pctile(__p3) xtile(__x3) replace
        scalar ___s3   = r(nqused)
        matrix ___mp3  = r(quantiles_used)
        matrix ___mf3  = r(quantiles_binfreq)
        matrix ___mfp3 = r(quantiles_binpct)

        glevelsof __p1, silent
        gquantiles `anything' `if' `in', _pctile `options' cutoffs(`r(levels)') binfreq binpct binfreq(__f4) binpct(__fp4) pctile(__p4) xtile(__x4) replace
        scalar ___s4   = r(nqused)
        matrix ___mp4  = r(cutoffs_used)
        matrix ___mf4  = r(cutoffs_binfreq)
        matrix ___mfp4 = r(cutoffs_binpct)

        gquantiles `anything' `if' `in', _pctile `options' cutquantiles(__g1) binfreq(__f5) binpct(__fp5) pctile(__p5) xtile(__x5) replace
    }

    cap _compare_inner_nqvars `tol'
    if ( `rc' ) {
        di as err "    consistency_internal_gquantiles (failed): xtile via nq(`nq') `options' not all equal"
        exit `rc'
    }

    di as txt "    consistency_internal_gquantiles (passed): xtile, pctile, and _pctile via nq(`nq') `options' (tol = `tol')"
end

capture program drop _compare_inner_nqvars
program _compare_inner_nqvars, rclass
    args tol
    local rc = 0

    _compare_inner_nqvars_rc __p1 __p2 `tol'
    local rc = max(`rc', `r(rc)')
    _compare_inner_nqvars_rc __f1 __f2 `tol'
    local rc = max(`rc', `r(rc)')
    _compare_inner_nqvars_rc __fp1 __fp2 `tol'
    local rc = max(`rc', `r(rc)')
    _compare_inner_nqvars_rc __x1 __x2 `tol'
    local rc = max(`rc', `r(rc)')

    if ( `nq' <= 801 ) {
        _compare_inner_nqvars_rc __p1 __p3 `tol'
        local rc = max(`rc', `r(rc)')
        _compare_inner_nqvars_rc __f1 __f3 `tol'
        local rc = max(`rc', `r(rc)')
        _compare_inner_nqvars_rc __fp1 __fp3 `tol'
        local rc = max(`rc', `r(rc)')
        _compare_inner_nqvars_rc __x1 __x3 `tol'
        local rc = max(`rc', `r(rc)')

        _compare_inner_nqvars_rc __p1 __p4 `tol'
        local rc = max(`rc', `r(rc)')
        _compare_inner_nqvars_rc __f1 __f4 `tol'
        local rc = max(`rc', `r(rc)')
        _compare_inner_nqvars_rc __fp1 __fp4 `tol'
        local rc = max(`rc', `r(rc)')
        _compare_inner_nqvars_rc __x1 __x4 `tol'
        local rc = max(`rc', `r(rc)')

        assert scalar(___s3) == scalar(___s4)
        mata: assert(all(abs(st_matrix("___mp3")  :- st_matrix("___mp4"))  :< `tol'))
        mata: assert(all(abs(st_matrix("___mf3")  :- st_matrix("___mf4"))  :< `tol'))
        mata: assert(all(abs(st_matrix("___mfp3") :- st_matrix("___mfp4")) :< `tol'))

        mata: assert(all(abs(st_matrix("___mp3")  :- st_data(1::st_numscalar("___s3"), "__p1"))  :< `tol'))
        mata: assert(all(abs(st_matrix("___mf3")  :- st_data(1::st_numscalar("___s3"), "__f3"))  :< `tol'))
        mata: assert(all(abs(st_matrix("___mfp3") :- st_data(1::st_numscalar("___s3"), "__fp3")) :< `tol'))

        mata: assert(all(abs(st_matrix("___mp4")  :- st_data(1::st_numscalar("___s4"), "__p1"))  :< `tol'))
        mata: assert(all(abs(st_matrix("___mf4")  :- st_data(1::st_numscalar("___s4"), "__f4"))  :< `tol'))
        mata: assert(all(abs(st_matrix("___mfp4") :- st_data(1::st_numscalar("___s4"), "__fp4")) :< `tol'))
    }

    local rc = 0
    _compare_inner_nqvars_rc __p1 __p5 `tol'
    local rc = max(`rc', `r(rc)')
    _compare_inner_nqvars_rc __f1 __f5 `tol'
    local rc = max(`rc', `r(rc)')
    _compare_inner_nqvars_rc __fp1 __fp5 `tol'
    local rc = max(`rc', `r(rc)')
    _compare_inner_nqvars_rc __x1 __x5 `tol'
    local rc = max(`rc', `r(rc)')

    return rc = `rc'
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

    if ( "`altdef'" != "noaltdef" ) {
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(500))  qwhich(xtile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(100))  qwhich(xtile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(10))   qwhich(xtile) `options'
    compare_inner_quantiles, n(`n') bench(`bench') qopts(altdef nq(2))    qwhich(xtile) `options'
    }

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
    gen double ru = runiform() * 100
    qui replace ix = . if mod(_n, `n') == 0
    qui replace ru = . if mod(_n, `n') == 0
    qui sort random1

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
    syntax [if] [in], [tol(real 1e-6) NOIsily qopts(str) qwhich(str) benchmode table corners *]

    if ( "`if'`in'" != "" ) {
        local ifinstr ""
        if ( "`if'" != "" ) local ifinstr `ifinstr' [`if']
        if ( "`in'" != "" ) local ifinstr `ifinstr' [`in']

        if ( ("`corners'" != "")  & ("`qwhich'" == "xtile")) {
            disp as txt "(note: skipped `ifinstr' tests for xtile; this test is for pctile and _pctile only)"
            exit 0
        }
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

    if ( "`corners'" == "" ) {
    _compare_inner_`qwhich' double1 `if' `in', `options' note("~ U(0,  1000), no missings, groups of size 10")
    _compare_inner_`qwhich' double3 `if' `in', `options' note("~ N(10, 5), many missings, groups of size 10")
    _compare_inner_`qwhich' ru      `if' `in', `options' note("~ N(0, 100), few missings, unique")

    _compare_inner_`qwhich' int1 `if' `in', `options' note("discrete (no missings, many groups)")
    _compare_inner_`qwhich' int3 `if' `in', `options' note("discrete (many missings, few groups)")
    _compare_inner_`qwhich' ix   `if' `in', `options' note("discrete (few missings, unique)")

    _compare_inner_`qwhich' int1^2 + 3 * double1          `if' `in', `options'
    _compare_inner_`qwhich' 2 * int1 + log(double1)       `if' `in', `options'
    _compare_inner_`qwhich' int1 * double3 + exp(double3) `if' `in', `options'
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
    syntax anything [if] [in], [note(str) benchmode table qopts(str) sorted *]
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
    qui gquantiles `gxtile' = `anything' `if' `in', xtile `qopts' `options'
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
        tempvar diff
        gen `diff' = `xtile' - `gxtile'
        gtoplevelsof `diff'
        if ( strpos("`qopts'", "altdef") ) {
            local qopts: subinstr local qopts "altdef" " ", all
            qui gquantiles `anything' `if' `in', xtile(`gxtile') `qopts' replace
            cap assert `xtile' == `gxtile'
            if ( _rc ) {
                di as err "    compare_xtile (failed): gquantiles xtile = `anything' gave different levels to xtile"
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
                     _n(2) "and change 'altdev' to 'altdef' (or add option -noaltdef- to compare_gquantiles)."
            }
            exit 198
        }
        else {
            di as err "    compare_xtile (failed): gquantiles xtile = `anything' gave different levels to xtile"
            cap assert `xtile' == `fxtile'
            if ( _rc & (`rc_f' == 0) ) {
                di as txt "    (note: fastxtile also gave different levels)"
            }
            sum `xtile' `gxtile' `diff'
            l `xtile' `gxtile' `diff' in 1/20
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
    syntax anything [if] [in], [benchmode table qopts(str) reltol(real 1e-9) tol(real 1e-6) note(str) sorted *]
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
    qui gquantiles `gpctile' = `anything' `if' `in', pctile `gqopts' `options'
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
            sum `pctile' `gpctile' `comp'
            l `pctile' `gpctile' in 1/20
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
                sum `pctpct' `gpctpct' `comp'
                l `pctpct' `gpctpct' in 1/20
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
    syntax anything [if] [in], [benchmode table qopts(str) reltol(real 1e-9) tol(real 1e-6) note(str) sorted *]
    tempvar exp
    qui gen double `exp' = `anything'

    if ( "`sorted'" != "" ) {
        sort `exp'
    }

    timer clear
    timer on 43
    qui gquantiles `exp' `if' `in', _pctile `qopts' `options'
    timer off 43
    qui timer list
    local time_gpctile = r(t43)
    local nq = `r(nqused)'
    forvalues q = 1 / `nq' {
        scalar qr_`q' = `r(r`q')'
    }

    timer clear
    timer on 42
    qui _pctile `exp' `if' `in', `qopts'
    timer off 42
    qui timer list
    local time_pctile = r(t42)
    forvalues q = 1 / `nq' {
        scalar r_`q' = `r(r`q')'
    }

    forvalues q = 1 / `nq' {
        if ( abs(scalar(qr_`q') - scalar(r_`q')) > `tol' ) {
            scalar comp = `=scalar(r_`q')' * `reltol'
            scalar comp = cond(scalar(comp) < `tol', `tol', scalar(comp))
            if ( abs(scalar(qr_`q') - scalar(r_`q')) > `comp' ) {
                di as err "    compare__pctile (failed): gquantiles `anything', _pctile gave different percentiles to _pctile (reltol = `reltol')"
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
        cap scalar drop qr_`q'
        cap scalar drop r_`q'
        cap scalar drop comp
    }

    if ( "`benchmode'" == "" ) {
        di as txt "    compare__pctile (passed): gquantiles `anything', _pctile gave similar results to _pctile (reltol = `reltol', tol = `tol')"
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
