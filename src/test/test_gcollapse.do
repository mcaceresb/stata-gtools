capture program drop checks_gcollapse
program checks_gcollapse
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_gcollapse, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(5000) random(2)
    qui expand 2
    gen long ix = _n

    checks_inner_collapse, `options'

    checks_inner_collapse -str_12,              `options'
    checks_inner_collapse str_12 -str_32,       `options'
    checks_inner_collapse str_12 -str_32 str_4, `options'

    checks_inner_collapse -double1,                 `options'
    checks_inner_collapse double1 -double2,         `options'
    checks_inner_collapse double1 -double2 double3, `options'

    checks_inner_collapse -int1,           `options'
    checks_inner_collapse int1 -int2,      `options'
    checks_inner_collapse int1 -int2 int3, `options'

    checks_inner_collapse -int1 -str_32 -double1,                                         `options'
    checks_inner_collapse int1 -str_32 double1 -int2 str_12 -double2,                     `options'
    checks_inner_collapse int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options'
end

capture program drop checks_inner_collapse
program checks_inner_collapse
    syntax [anything], [tol(real 1e-6) *]

    local stats sum mean sd max min count median iqr percent first last firstnm lastnm semean sebinomial sepoisson
    local percentiles p1 p10 p30.5 p50 p70.5 p90 p99

    local collapse_str ""
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') r1_`stat' = random1
        local collapse_str `collapse_str' (`stat') r2_`stat' = random2
    }
    foreach pct of local percentiles {
        local collapse_str `collapse_str' (`pct') r1_`:subinstr local pct "." "_", all' = random1
        local collapse_str `collapse_str' (`pct') r2_`:subinstr local pct "." "_", all' = random2
    }

    preserve
        gcollapse `collapse_str', by(`anything') verbose `options'
    restore, preserve
        gcollapse `collapse_str', by(`anything') verbose benchmark `options'
    restore, preserve
        gcollapse `collapse_str', by(`anything') verbose forceio `options'
    restore, preserve
        gcollapse `collapse_str', by(`anything') verbose forcemem `options'
    restore, preserve
        gcollapse `collapse_str', by(`anything') verbose benchmark cw `options'
    restore, preserve
        gcollapse `collapse_str', by(`anything') verbose benchmark fast `options'
    restore, preserve
        gcollapse `collapse_str', by(`anything') double `options'
    restore, preserve
        gcollapse `collapse_str', by(`anything') merge `options'
    restore, preserve
        gcollapse `collapse_str', by(`anything') verbose `options' benchmark debug_io_check(0)
    restore
end

***********************************************************************
*                            Corner cases                             *
***********************************************************************

capture program drop checks_corners
program checks_corners
    syntax, [*]
    di _n(1) "{hline 80}" _n(1) "checks_corners `options'" _n(1) "{hline 80}" _n(1)

    qui {
        sysuse auto, clear
        gen price2 = price
        cap noi gcollapse price = price2 if price < 0
        assert _rc == 2000
    }

    qui {
        sysuse auto, clear
        gen price2 = price
        gcollapse price = price2
    }

    qui {
        sysuse auto, clear
        gen price2 = price
        gcollapse price = price2, by(make) v b `options'
        gcollapse price in 1,     by(make) v b `options'
    }

    qui {
        clear
        set matsize 100
        set obs 10
        forvalues i = 1/101 {
            gen x`i' = 10
        }
        gen zz = runiform()
        preserve
            gcollapse zz, by(x*) `options'
        restore, preserve
            gcollapse x*, by(zz) `options'
        restore
    }

    qui {
        clear
        set matsize 400
        set obs 10
        forvalues i = 1/300 {
            gen x`i' = 10
        }
        gen zz = runiform()
        preserve
            gcollapse zz, by(x*) `options'
        restore, preserve
            gcollapse x*, by(zz) `options'
        restore
    }

    qui {
        clear
        set obs 10
        forvalues i = 1/800 {
            gen x`i' = 10
        }
        gen zz = runiform()
        preserve
            gcollapse zz, by(x*) `options'
        restore, preserve
            gcollapse x*, by(zz) `options'
        restore

        * Only fails in Stata/IC
        * gen x801 = 10
        * preserve
        *     collapse zz, by(x*) `options'
        * restore, preserve
        *     collapse x*, by(zz) `options'
        * restore
    }

    di ""
    di as txt "Passed! checks_corners `options'"
end

***********************************************************************
*                               Compare                               *
***********************************************************************

capture program drop compare_gcollapse
program compare_gcollapse
    syntax, [tol(real 1e-6) NOIsily *]

    * This should be ignored for compare_inner_gcollapse_gegen bc of merge
    local debug_io debug_io_check(0) debug_io_threshold(0.0001)

    qui `noisily' gen_data, n(1000) random(2)
    qui expand 100

    di _n(1) "{hline 80}" _n(1) "consistency_gcollapse_gegen, `options'" _n(1) "{hline 80}" _n(1)

    compare_inner_gcollapse_gegen, `options' tol(`tol')

    compare_inner_gcollapse_gegen -str_12,              `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_gegen str_12 -str_32,       `options' tol(`tol')
    compare_inner_gcollapse_gegen str_12 -str_32 str_4, `options' tol(`tol')

    compare_inner_gcollapse_gegen -double1,                 `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_gegen double1 -double2,         `options' tol(`tol')
    compare_inner_gcollapse_gegen double1 -double2 double3, `options' tol(`tol')

    compare_inner_gcollapse_gegen -int1,           `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_gegen int1 -int2,      `options' tol(`tol')
    compare_inner_gcollapse_gegen int1 -int2 int3, `options' tol(`tol')

    compare_inner_gcollapse_gegen -int1 -str_32 -double1, `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_gegen int1 -str_32 double1 -int2 str_12 -double2, `options' tol(`tol')
    compare_inner_gcollapse_gegen int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options' tol(`tol')

    qui `noisily' gen_data, n(1000) random(2) binary(1)
    qui expand 50

    di _n(1) "{hline 80}" _n(1) "consistency_collapse, `options'" _n(1) "{hline 80}" _n(1)

    compare_inner_collapse, `options' tol(`tol')

    compare_inner_collapse str_12,              `options' tol(`tol') forcemem
    compare_inner_collapse str_12 str_32,       `options' tol(`tol') forceio
    compare_inner_collapse str_12 str_32 str_4, `options' tol(`tol') `debug_io'

    compare_inner_collapse double1,                 `options' tol(`tol') forcemem
    compare_inner_collapse double1 double2,         `options' tol(`tol') forceio
    compare_inner_collapse double1 double2 double3, `options' tol(`tol') `debug_io'

    compare_inner_collapse int1,           `options' tol(`tol') forcemem
    compare_inner_collapse int1 int2,      `options' tol(`tol') forceio
    compare_inner_collapse int1 int2 int3, `options' tol(`tol') `debug_io'

    compare_inner_collapse int1 str_32 double1,                                        `options' tol(`tol') forcemem
    compare_inner_collapse int1 str_32 double1 int2 str_12 double2,                    `options' tol(`tol') forceio
    compare_inner_collapse int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options' tol(`tol') `debug_io'
end

capture program drop compare_inner_gcollapse_gegen
program compare_inner_gcollapse_gegen
    syntax [anything], [tol(real 1e-6) *]

    local N = trim("`: di %15.0gc _N'")
    local hlen = 45 + length("`anything'") + length("`N'")
    di _n(2) "Checking gegen vs gcollapse. N = `N'; varlist = `anything'" _n(1) "{hline `hlen'}"

    preserve
        _compare_inner_gcollapse_gegen `anything', `options' tol(`tol')
    restore, preserve
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_gcollapse_gegen  `anything' in `from' / `to', `options' tol(`tol')
    restore, preserve
        _compare_inner_gcollapse_gegen `anything' if random2 > 0, `options' tol(`tol')
    restore, preserve
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_gcollapse_gegen `anything' if random2 < 0 in `from' / `to', `options' tol(`tol')
    restore
end

capture program drop _compare_inner_gcollapse_gegen
program _compare_inner_gcollapse_gegen
    syntax [anything] [if] [in], [tol(real 1e-6) *]

    gegen id = group(`anything'), missing

    gegen double mean       = mean       (random1) `if' `in',  by(`anything')
    gegen double sum        = sum        (random1) `if' `in',  by(`anything')
    gegen double median     = median     (random1) `if' `in',  by(`anything')
    gegen double sd         = sd         (random1) `if' `in',  by(`anything')
    gegen double iqr        = iqr        (random1) `if' `in',  by(`anything')
    gegen double first      = first      (random1) `if' `in',  by(`anything')
    gegen double last       = last       (random1) `if' `in',  by(`anything')
    gegen double firstnm    = firstnm    (random1) `if' `in',  by(`anything')
    gegen double lastnm     = lastnm     (random1) `if' `in',  by(`anything')
    gegen double semean     = semean     (random1) `if' `in',  by(`anything')
    gegen double sebinomial = sebinomial (random1) `if' `in',  by(`anything')
    gegen double sepoisson  = sepoisson  (random1) `if' `in',  by(`anything')
    gegen double q10        = pctile     (random1) `if' `in',  by(`anything') p(10.5)
    gegen double q30        = pctile     (random1) `if' `in',  by(`anything') p(30)
    gegen double q70        = pctile     (random1) `if' `in',  by(`anything') p(70)
    gegen double q90        = pctile     (random1) `if' `in',  by(`anything') p(90.5)

    qui `noisily' {
        gcollapse (mean)       g_mean       = random1  ///
                  (sum)        g_sum        = random1  ///
                  (median)     g_median     = random1  ///
                  (sd)         g_sd         = random1  ///
                  (iqr)        g_iqr        = random1  ///
                  (first)      g_first      = random1  ///
                  (last)       g_last       = random1  ///
                  (firstnm)    g_firstnm    = random1  ///
                  (lastnm)     g_lastnm     = random1  ///
                  (semean)     g_semean     = random1  ///
                  (sebinomial) g_sebinomial = random1  ///
                  (sepoisson)  g_sepoisson  = random1  ///
                  (p10.5)      g_q10        = random1  ///
                  (p30)        g_q30        = random1  ///
                  (p70)        g_q70        = random1  ///
                  (p90.5)      g_q90        = random1 `if' `in', by(id) benchmark verbose `options' merge double
    }

    if ( "`if'`in'" == "" ) {
        di _n(1) "Checking full range: `anything'"
    }
    else if ( "`if'`in'" != "" ) {
        di _n(1) "Checking [`if' `in'] range: `anything'"
    }

    foreach fun in mean sum median sd iqr first last firstnm lastnm semean sebinomial sepoisson q10 q30 q70 q90 {
        cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
        if ( _rc ) {
            recast double g_`fun' `fun'
            cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
            if ( _rc ) {
                di as err "    compare_gegen_gcollapse (failed): `fun' yielded different results (tol = `tol')"
                exit _rc
            }
            else di as txt "    compare_gegen_gcollapse (passed): `fun' yielded same results (tol = `tol')"
        }
        else di as txt "    compare_gegen_gcollapse (passed): `fun' yielded same results (tol = `tol')"
    }
end

capture program drop compare_inner_collapse
program compare_inner_collapse
    syntax [anything], [tol(real 1e-6) *]

    local N = trim("`: di %15.0gc _N'")
    local hlen = 35 + length("`anything'") + length("`N'")
    di _n(2) "Checking collapse. N = `N'; varlist = `anything'" _n(1) "{hline `hlen'}"

    preserve
        _compare_inner_collapse `anything', `options' tol(`tol')
    restore, preserve
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_collapse  `anything' in `from' / `to', `options' tol(`tol')
    restore, preserve
        _compare_inner_collapse `anything' if random2 > 0, `options' tol(`tol')
    restore, preserve
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_collapse `anything' if random2 < 0 in `from' / `to', `options' tol(`tol')
    restore
end

capture program drop _compare_inner_collapse
program _compare_inner_collapse
    syntax [anything] [if] [in], [tol(real 1e-6) *]

    local stats sum mean sd max min count percent first last firstnm lastnm median iqr semean sebinomial sepoisson
    local percentiles p1 p13 p30 p50 p70 p87 p99
    local collapse_str ""
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') r1_`stat' = random1
        local collapse_str `collapse_str' (`stat') r2_`stat' = random2
    }
    foreach pct of local percentiles {
        local collapse_str `collapse_str' (`pct') r1_`pct' = random1
        local collapse_str `collapse_str' (`pct') r2_`pct' = random2
    }

    preserve
        timer clear
        timer on 43
        qui `noisily' gcollapse `collapse_str', by(`anything') verbose benchmark `options'
        timer off 43
        qui timer list
        local time_gcollapse = r(t43)
        tempfile fg
        qui save `fg'
    restore

    preserve
        timer clear
        timer on 42
        qui `noisily' collapse `collapse_str', by(`anything')
        timer off 42
        qui timer list
        local time_gcollapse = r(t42)
        tempfile fc
        qui save `fc'
    restore

    preserve
    use `fc', clear
        local bad_any = 0
        local bad `anything'
        local by  `anything'
        foreach var in `stats' `percentiles' {
            rename r1_`var' c_r1_`var'
            rename r2_`var' c_r2_`var'
        }
        if ( "`by'" == "" ) {
            qui merge 1:1 _n using `fg', assert(3)
        }
        else {
            qui merge 1:1 `by' using `fg', assert(3)
        }
        foreach var in `stats' `percentiles' {
            qui count if ( (abs(r1_`var' - c_r1_`var') > `tol') & (r1_`var' != c_r1_`var'))
            if ( `r(N)' > 0 ) {
                gen bad_r1_`var' = abs(r1_`var' - c_r1_`var') * (r1_`var' != c_r1_`var')
                local bad `bad' *r1_`var'
                di "    r1_`var' has `:di r(N)' mismatches".
                local bad_any = 1
                order *r1_`var'
            }

            qui count if ( (abs(r2_`var' - c_r2_`var') > `tol') & (r2_`var' != c_r2_`var'))
            if ( `r(N)' > 0 ) {
                gen bad_r2_`var' = abs(r2_`var' - c_r2_`var') * (r2_`var' != c_r2_`var')
                local bad `bad' *r2_`var'
                di "    r2_`var' has `:di r(N)' mismatches".
                local bad_any = 1
                order *r2_`var'
            }
        }
        if ( `bad_any' ) {
            if ( "`if'`in'" == "" ) {
                di "    compare_collapse (failed): full range, `anything'"
            }
            else if ( "`if'`in'" != "" ) {
                di "    compare_collapse (failed): [`if' `in'], `anything'"
            }
            order `bad'
            egen bad_any = rowmax(bad_*)
            l *count* *mean* `bad' if bad_any
            sum bad_*
            desc
            exit 9
        }
        else {
            if ( "`if'`in'" == "" ) {
                di "    compare_collapse (passed): full range, gcollapse results equal to collapse (tol = `tol')"
            }
            else if ( "`if'`in'" != "" ) {
                di "    compare_collapse (passed): [`if' `in'], gcollapse results equal to collapse (tol = `tol')"
            }
        }
    restore
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_collapse
program bench_collapse
    syntax, [tol(real 1e-6) bench(real 1) n(int 1000) NOIsily style(str) vars(int 1) collapse fcollapse *]

    qui gen_data, n(`n') random(`vars') double
    qui expand `=100 * `bench''
    qui hashsort random1

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    if ( "`style'" == "full" ) {
        local ststr "all available plus percentiles 10, 30, 70, 90"
    }
    else if ( "`style'" == "ftools" ) {
        local ststr "mean median min max"
    }
    else {
        local ststr "sum"
    }

    if ( `vars' > 1 ) {
        local vstr "x1-x`vars'"
    }
    else {
        local vstr x1
    }

    di as txt _n(1)
    di as txt "Benchmark vs collapse (in seconds)"
    di as txt "    - obs:     `N'"
    di as txt "    - groups:  `J'"
    di as txt "    - vars:    `vstr' ~ N(0, 10)"
    di as txt "    - stats:   `ststr'"
    di as txt "    - options: fast"
    di as txt _n(1)
    di as txt "    collapse | fcollapse | gcollapse | ratio (c/g) | ratio (f/g) | varlist"
    di as txt "    -------- | --------- | --------- | ----------- | ----------- | -------"

    local options `options' style(`style') vars(`vars')
    versus_collapse,                         `options' `collapse' `fcollapse'
    versus_collapse str_12 str_32 str_4,     `options' `collapse' `fcollapse'
    versus_collapse double1 double2 double3, `options' `collapse' `fcollapse'
    versus_collapse int1 int2,               `options' `collapse' `fcollapse'
    versus_collapse int3 str_32 double1,     `options' `collapse'

    di _n(1) "{hline 80}" _n(1) "bench_collapse, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop versus_collapse
program versus_collapse, rclass
    syntax [anything], [fcollapse collapse style(str) vars(int 1) *]

    local stats       ""
    local percentiles ""

    if ( "`style'" == "full" ) {
        local stats sum mean sd max min count median iqr percent first last firstnm lastnm
        local percentiles p10 p30 p70 p90
    }
    else if ( "`style'" == "ftools" ) {
        local stats mean median min max
    }
    else {
        local stats sum
    }

    local collapse_str ""
    foreach stat of local stats {
        forvalues k = 1 / `vars' {
            local collapse_str `collapse_str' (`stat') r`k'_`stat' = random`k'
        }
    }
    foreach pct of local percentiles {
        forvalues k = 1 / `vars' {
            local collapse_str `collapse_str' (`pct') r`k'_`pct' = random`k'
        }
    }

    if ( "`collapse'" == "collapse" ) {
    preserve
        timer clear
        timer on 42
        qui collapse `collapse_str', by(`anything') fast
        timer off 42
        qui timer list
        local time_collapse = r(t42)
    restore
    }
    else {
        local time_collapse = .
    }

    preserve
        timer clear
        timer on 43
        qui gcollapse `collapse_str', by(`anything') `options' fast
        timer off 43
        qui timer list
        local time_gcollapse = r(t43)
    restore

    if ( "`fcollapse'" == "fcollapse" ) {
    preserve
        timer clear
        timer on 44
        qui fcollapse `collapse_str', by(`anything') fast
        timer off 44
        qui timer list
        local time_fcollapse = r(t44)
    restore
    }
    else {
        local time_fcollapse = .
    }

    local rs = `time_collapse'  / `time_gcollapse'
    local rf = `time_fcollapse' / `time_gcollapse'
    di as txt "    `:di %8.3g `time_collapse'' | `:di %9.3g `time_fcollapse'' | `:di %9.3g `time_gcollapse'' | `:di %11.3g `rs'' | `:di %11.3g `rf'' | `anything'"
end
