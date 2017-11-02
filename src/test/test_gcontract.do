capture program drop checks_gcontract
program checks_gcontract
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_gcontract, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(5000) random(2)
    qui expand 2
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

    qui `noisily' gen_data, n(1000) random(2) binary(1)
    qui expand 50

    di as txt _n(1) "{hline 80}" _n(1) "consistency_gtoplevelsof_gcontract, `options'" _n(1) "{hline 80}" _n(1)

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
    syntax, [tol(real 1e-6) bench(real 1) n(int 1000) NOIsily *]

    qui gen_data, n(`n') random(1) double
    qui expand `=100 * `bench''
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
