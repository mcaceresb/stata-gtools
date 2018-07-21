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
