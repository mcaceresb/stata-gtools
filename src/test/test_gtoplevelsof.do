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
