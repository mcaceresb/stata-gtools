capture program drop checks_duplicates
program checks_duplicates
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_duplicates, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(5000)
    qui expand 2

    checks_inner_duplicates str_12,              `options'
    checks_inner_duplicates str_12 str_32,       `options'
    checks_inner_duplicates str_12 str_32 str_4, `options'

    checks_inner_duplicates double1,                 `options'
    checks_inner_duplicates double1 double2,         `options'
    checks_inner_duplicates double1 double2 double3, `options'

    checks_inner_duplicates int1,           `options'
    checks_inner_duplicates int1 int2,      `options'
    checks_inner_duplicates int1 int2 int3, `options'

    checks_inner_duplicates int1 str_32 double1,                                        `options'
    checks_inner_duplicates int1 str_32 double1 int2 str_12 double2,                    `options'
    checks_inner_duplicates int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    if ( `c(stata_version)' >= 14 ) {
        checks_inner_duplicates strL1,             `options'
        checks_inner_duplicates strL1 strL2,       `options'
        checks_inner_duplicates strL1 strL2 strL3, `options'
    }

    sysuse auto, clear
    gen idx = _n
    qui gduplicates report foreign,       `options'
    assert r(unique_value) == 2
    qui gduplicates report foreign price, `options'
    assert r(unique_value) == _N
    qui gduplicates report foreign make,  `options'
    assert r(unique_value) == _N
    qui gduplicates report idx,           `options' gtools(v bench)
end

capture program drop checks_inner_duplicates
program checks_inner_duplicates
    syntax varlist, [*]
    preserve
    tempvar tag
    qui gduplicates report   `varlist', gtools(`options')
    qui gduplicates examples `varlist', gtools(`options')
    qui gduplicates list     `varlist', gtools(`options')
    qui gduplicates tag      `varlist', gtools(`options') gen(`tag')
    cap gduplicates drop     `varlist', gtools(`options')
    assert _rc == 198
    qui gduplicates drop     `varlist', force
    restore
end

***********************************************************************
*                               Compare                               *
***********************************************************************

capture program drop compare_duplicates
program compare_duplicates
    syntax, [tol(real 1e-6) NOIsily bench(int 1) n(int 1000) *]

    qui `noisily' gen_data, n(`n')
    qui expand `=100 * `bench''
    qui `noisily' random_draws, random(2)
    qui gen rsort = rnormal()
    qui sort rsort

    compare_duplicates_internal str_12,              `options'
    compare_duplicates_internal str_12 str_32,       `options'
    compare_duplicates_internal str_12 str_32 str_4, `options'

    compare_duplicates_internal double1,                 `options'
    compare_duplicates_internal double1 double2,         `options'
    compare_duplicates_internal double1 double2 double3, `options'

    compare_duplicates_internal int1,           `options'
    compare_duplicates_internal int1 int2,      `options'
    compare_duplicates_internal int1 int2 int3, `options'

    compare_duplicates_internal int1 str_32 double1,                                        `options'
    compare_duplicates_internal int1 str_32 double1 int2 str_12 double2,                    `options'
    compare_duplicates_internal int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    if ( `c(stata_version)' >= 14 ) {
        compare_duplicates_internal strL1,             `options'
        compare_duplicates_internal strL1 strL2,       `options'
        compare_duplicates_internal strL1 strL2 strL3, `options'
    }
end

capture program drop compare_duplicates_internal
program compare_duplicates_internal
    syntax varlist, [*]

    if ( "`benchmode'" == "" )  {
        di _n(2) "Checking duplicates; varlist = `varlist'" _n(1) "{hline `hlen'}"
    }

    preserve
        _compare_duplicates `varlist' `if' `in', `options' report
        _compare_duplicates `varlist' `if' `in', `options' tag
        _compare_duplicates `varlist' `if' `in', `options' drop
    restore, preserve
        if ( "`shuffle'" != "" ) sort `rsort'
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_duplicates `varlist' in `from' / `to', `options' report
        _compare_duplicates `varlist' in `from' / `to', `options' tag
        _compare_duplicates `varlist' in `from' / `to', `options' drop
    restore, preserve
        _compare_duplicates `varlist' if random2 > 0, `options' report
        _compare_duplicates `varlist' if random2 > 0, `options' tag
        _compare_duplicates `varlist' if random2 > 0, `options' drop
    restore, preserve
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_duplicates `varlist' if random2 < 0 in `from' / `to', `options' report
        _compare_duplicates `varlist' if random2 < 0 in `from' / `to', `options' tag
        _compare_duplicates `varlist' if random2 < 0 in `from' / `to', `options' drop
    restore
end

***********************************************************************
*                              Benchmark                              *
***********************************************************************

capture program drop bench_duplicates
program bench_duplicates
    syntax, [tol(real 1e-6) NOIsily bench(int 1) n(int 1000) *]
    local options `options' benchmode

    qui `noisily' gen_data, n(`n')
    qui expand `=100 * `bench''
    qui gen rsort = rnormal()
    qui sort rsort

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    di as txt _n(1)
    di as txt "Benchmark vs duplicates report, obs = `N', J = `J' (in seconds)"
    di as txt "    duplicates | gduplicates | ratio (g/h) | varlist"
    di as txt "    ---------- | ----------- | ----------- | -------"

    _compare_duplicates str_12,              `options' report
    _compare_duplicates str_12 str_32,       `options' report
    _compare_duplicates str_12 str_32 str_4, `options' report

    _compare_duplicates double1,                 `options' report
    _compare_duplicates double1 double2,         `options' report
    _compare_duplicates double1 double2 double3, `options' report

    _compare_duplicates int1,           `options' report
    _compare_duplicates int1 int2,      `options' report
    _compare_duplicates int1 int2 int3, `options' report

    _compare_duplicates int1 str_32 double1,                                        `options' report
    _compare_duplicates int1 str_32 double1 int2 str_12 double2,                    `options' report
    _compare_duplicates int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options' report

    if ( `c(stata_version)' >= 14 ) {
        _compare_duplicates strL1,             `options' report
        _compare_duplicates strL1 strL2,       `options' report
        _compare_duplicates strL1 strL2 strL3, `options' report
    }

    di as txt _n(1)
    di as txt "Benchmark vs duplicates drop, obs = `N', J = `J' (in seconds; output compared via {opt cf})"
    di as txt "    duplicates | gduplicates | ratio (g/h) | varlist"
    di as txt "    ---------- | ----------- | ----------- | -------"

    _compare_duplicates str_12,              `options' drop
    _compare_duplicates str_12 str_32,       `options' drop
    _compare_duplicates str_12 str_32 str_4, `options' drop

    _compare_duplicates double1,                 `options' drop
    _compare_duplicates double1 double2,         `options' drop
    _compare_duplicates double1 double2 double3, `options' drop

    _compare_duplicates int1,           `options' drop
    _compare_duplicates int1 int2,      `options' drop
    _compare_duplicates int1 int2 int3, `options' drop

    _compare_duplicates int1 str_32 double1,                                        `options' drop
    _compare_duplicates int1 str_32 double1 int2 str_12 double2,                    `options' drop
    _compare_duplicates int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options' drop

    if ( `c(stata_version)' >= 14 ) {
        _compare_duplicates strL1,             `options' drop
        _compare_duplicates strL1 strL2,       `options' drop
        _compare_duplicates strL1 strL2 strL3, `options' drop
    }

    di _n(1) "{hline 80}" _n(1) "compare_duplicates, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop _compare_duplicates
program _compare_duplicates, rclass
    syntax varlist [if] [in], [drop report tag benchmode *]

    tempvar r_tag g_tag
    if ( "`drop'" != "" ) {
        local force force
    }
    else if ( "`tag'" != "" ) {
        local r_gen gen(`r_tag')
        local g_gen gen(`g_tag')
    }

    timer clear
    if ( "`drop'" != "" ) preserve
        timer on 42
        qui duplicates `tag' `drop' `report' `varlist' `if' `in', `force' `r_gen'
        timer off 42
        if ( "`report'" != "" ) {
            local r_duplicates = `r(unique_value)'
        }
        else if ( "`drop'" != "" ) {
            tempfile file_duplicates
            qui save `file_duplicates'
        }
        else if ( "`tag'" != "" ) {
        }
    if ( "`drop'" != "" ) restore
    qui timer list
    local time_duplicates = r(t42)

    timer clear
    if ( "`drop'" != "" ) preserve
        timer on 43
        qui gduplicates `tag' `drop' `report' `varlist' `if' `in', `force' gtools(`options') `g_gen'
        timer off 43
        if ( "`report'" != "" ) {
            cap noi assert `r(unique_value)' == `r_duplicates'
            if ( _rc ) exit _rc
            local rc = _rc
        }
        else if ( "`drop'" != "" ) {
            cap noi cf * using `file_duplicates'
            local rc = _rc
        }
        else if ( "`tag'" != "" ) {
            cap noi assert `r_tag' == `g_tag'
            local rc = _rc
        }
        else {
            local rc 0
        }
    if ( "`drop'" != "" ) restore

    if ( "`benchmode'" == "" ) {
        local dstr: di %7s "`drop'`report'`tag'"

        if ( `rc' ) {
            di as err "    compare_gduplicates (failed): `dstr' `if' `in' yielded different results"
        }
        else {
            di as txt "    compare_gduplicates (passed): `dstr' `if' `in' yielded identical results"
        }
        exit `rc'
    }

    qui timer list
    local time_gduplicates = r(t43)

    local rs = `time_duplicates'  / `time_gduplicates'
    di as txt "    `:di %10.3g `time_duplicates'' | `:di %11.3g `time_gduplicates'' | `:di %11.3g `rs'' | `varlist'"
end
