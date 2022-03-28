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
