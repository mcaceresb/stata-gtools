capture program drop checks_isid
program checks_isid
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_isid, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(5000)
    qui expand 2
    gen long ix = _n

    checks_inner_isid str_12,              `options'
    checks_inner_isid str_12 str_32,       `options'
    checks_inner_isid str_12 str_32 str_4, `options'

    checks_inner_isid double1,                 `options'
    checks_inner_isid double1 double2,         `options'
    checks_inner_isid double1 double2 double3, `options'

    checks_inner_isid int1,           `options'
    checks_inner_isid int1 int2,      `options'
    checks_inner_isid int1 int2 int3, `options'

    checks_inner_isid int1 str_32 double1,                                        `options'
    checks_inner_isid int1 str_32 double1 int2 str_12 double2,                    `options'
    checks_inner_isid int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    clear
    gen x = 1
    cap gisid x
    assert _rc == 0
end

capture program drop checks_inner_isid
program checks_inner_isid
    syntax varlist, [*]
    cap gisid `varlist', `options' v b missok
    assert _rc == 459

    cap gisid `varlist' in 1, `options' missok
    assert _rc == 0

    cap gisid `varlist' if _n == 1, `options' missok
    assert _rc == 0

    cap gisid `varlist' if _n < 10 in 5, `options' missok
    assert _rc == 0
end

***********************************************************************
*                               Compare                               *
***********************************************************************

capture program drop compare_isid
program compare_isid
    syntax, [tol(real 1e-6) NOIsily *]

    qui `noisily' gen_data, n(1000)
    qui expand 100

    local N    = trim("`: di %15.0gc _N'")
    local hlen = 20 + length("`options'") + length("`N'")
    di _n(1) "{hline 80}" _n(1) "compare_isid, N = `N', `options'" _n(1) "{hline 80}" _n(1)

    compare_inner_isid str_12,              `options'
    compare_inner_isid str_12 str_32,       `options'
    compare_inner_isid str_12 str_32 str_4, `options'

    compare_inner_isid double1,                 `options'
    compare_inner_isid double1 double2,         `options'
    compare_inner_isid double1 double2 double3, `options'

    compare_inner_isid int1,           `options'
    compare_inner_isid int1 int2,      `options'
    compare_inner_isid int1 int2 int3, `options'

    compare_inner_isid int1 str_32 double1,                                        `options'
    compare_inner_isid int1 str_32 double1 int2 str_12 double2,                    `options'
    compare_inner_isid int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'
end

capture program drop compare_inner_isid
program compare_inner_isid
    syntax varlist, [*]
    tempvar rsort ix
    gen `rsort' = runiform()
    gen long `ix' = _n

    cap isid `varlist', missok
    local rc_isid = _rc
    cap gisid `varlist', missok `options'
    local rc_gisid = _rc
    check_rc `rc_isid' `rc_gisid' , by( `varlist')

    cap isid `ix' `varlist', missok
    local rc_isid = _rc
    cap gisid `ix' `varlist', missok `options'
    local rc_gisid = _rc
    check_rc `rc_isid' `rc_gisid' , by( ix `varlist')

    cap isid `rsort' `varlist', missok
    local rc_isid = _rc
    cap gisid `rsort' `varlist', missok `options'
    local rc_gisid = _rc
    check_rc `rc_isid' `rc_gisid' , by( rsort `varlist')

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    qui replace `ix' = `=_N / 2' if _n > `=_N / 2'
    cap isid `ix'
    local rc_isid = _rc
    cap gisid `ix', `options'
    local rc_gisid = _rc
    check_rc `rc_isid' `rc_gisid' , by( ix)

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    preserve
        qui keep in 100 / `=ceil(`=_N / 2')'
        cap isid `ix' `varlist', missok
        local rc_isid = _rc
    restore
    cap gisid `ix' `varlist' in 100 / `=ceil(`=_N / 2')', missok `options'
    local rc_gisid = _rc
    check_rc  `rc_isid' `rc_gisid' , by( ix `varlist' in 100 / `=ceil(`=_N / 2')')

    preserve
        qui keep in `=ceil(`=_N / 2')' / `=_N'
        cap isid `ix' `varlist', missok
        local rc_isid = _rc
    restore
    cap gisid `ix' `varlist' in `=ceil(`=_N / 2')' / `=_N', missok `options'
    local rc_gisid = _rc
    check_rc  `rc_isid' `rc_gisid' , by( ix `varlist' in `=ceil(`=_N / 2')' / `=_N')

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    preserve
        qui keep if _n < `=_N / 2'
        cap isid `ix' `varlist', missok
        local rc_isid = _rc
    restore
    cap gisid `ix' `varlist' if _n < `=_N / 2', missok
    local rc_gisid = _rc
    check_rc  `rc_isid' `rc_gisid' , by( ix `varlist' if _n < `=_N / 2')

    preserve
        qui keep if _n > `=_N / 2'
        cap isid `ix' `varlist', missok
        local rc_isid = _rc
    restore
    cap gisid `ix' `varlist' if _n > `=_N / 2', missok `options'
    local rc_gisid = _rc
    check_rc  `rc_isid' `rc_gisid' , by( ix `varlist' if _n > `=_N / 2')

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    qui replace `ix' = 100 in 1 / 100

    preserve
        qui keep if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')'
        cap isid `ix' `varlist', missok
        local rc_isid = _rc
    restore
    cap gisid `ix' `varlist' if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')', missok `options'
    local rc_gisid = _rc
    check_rc  `rc_isid' `rc_gisid' , by( ix `varlist' if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')')

    preserve
        qui keep if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N'
        cap isid `ix' `varlist', missok
        local rc_isid = _rc
    restore
    cap gisid `ix' `varlist' if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N', missok
    local rc_gisid = _rc
    check_rc  `rc_isid' `rc_gisid' , by( ix `varlist' if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N')

    di _n(1)
end

capture program drop check_rc
program check_rc
    syntax anything, by(str)

    tokenize `anything'
    local rc_isid  `1'
    local rc_gisid `2'

    if ( `rc_isid' != `rc_gisid' ) {
        if ( `rc_isid' & (`rc_gisid' == 0) ) {
            di as err "    compare_isid (failed): isid `by' was an id but gisid returned error r(`rc_isid')"
            exit `rc_gisid'
        }
        else if ( (`rc_isid' == 0) & `rc_gisid' ) {
            di as err "    compare_isid (failed): gisid `by' was an id but isid returned error r(`rc_gisid')"
            exit `rc_isid'
        }
        else {
            di as err "    compare_isid (failed): `by' was not an id but isid and gisid returned different errors r(`rc_isid') vs r(`rc_gisid')"
            exit `rc_gisid'
        }
    }
    else {
        if ( _rc ) {
            di as txt "    compare_isid (passed): `by' was not an id"
        }
        else {
            di as txt "    compare_isid (passed): `by' was an id"
        }
    }
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_isid
program bench_isid
    syntax, [tol(real 1e-6) bench(int 1) n(int 1000) NOIsily *]

    qui `noisily' gen_data, n(`n')
    qui expand `=100 * `bench''
    qui gen rsort = rnormal()
    qui sort rsort

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    di as txt _n(1)
    di as txt "Benchmark vs isid, obs = `N', all calls include an index to ensure uniqueness (in seconds)"
    di as txt "     isid | fisid | gisid | ratio (i/g) | ratio (f/g) | varlist"
    di as txt "     ---- | ----- | ----- | ----------- | ----------- | -------"

    versus_isid str_12,              `options' fisid unique
    versus_isid str_12 str_32,       `options' fisid unique
    versus_isid str_12 str_32 str_4, `options' fisid unique

    versus_isid double1,                 `options' fisid unique
    versus_isid double1 double2,         `options' fisid unique
    versus_isid double1 double2 double3, `options' fisid unique

    versus_isid int1,           `options' fisid unique
    versus_isid int1 int2,      `options' fisid unique
    versus_isid int1 int2 int3, `options' fisid unique

    versus_isid int1 str_32 double1,                                        unique `options'
    versus_isid int1 str_32 double1 int2 str_12 double2,                    unique `options'
    versus_isid int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, unique `options'

    di as txt _n(1)
    di as txt "Benchmark vs isid, obs = `N', J = `J' (in seconds)"
    di as txt "     isid | fisid | gisid | ratio (i/g) | ratio (f/g) | varlist"
    di as txt "     ---- | ----- | ----- | ----------- | ----------- | -------"

    versus_isid str_12,              `options' fisid
    versus_isid str_12 str_32,       `options' fisid
    versus_isid str_12 str_32 str_4, `options' fisid

    versus_isid double1,                 `options' fisid
    versus_isid double1 double2,         `options' fisid
    versus_isid double1 double2 double3, `options' fisid

    versus_isid int1,           `options' fisid
    versus_isid int1 int2,      `options' fisid
    versus_isid int1 int2 int3, `options' fisid

    versus_isid int1 str_32 double1,                                        `options'
    versus_isid int1 str_32 double1 int2 str_12 double2,                    `options'
    versus_isid int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    di as txt _n(1) "{hline 80}" _n(1) "bench_isid, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop versus_isid
program versus_isid, rclass
    syntax varlist, [fisid unique *]
    if ( "`unique'" == "unique" ) {
        tempvar ix
        gen `ix' = `=_N' - _n
        if ( strpos("`varlist'", "str") ) qui tostring `ix', replace
    }

    preserve
        timer clear
        timer on 42
        cap isid `varlist' `ix', missok
        assert inlist(_rc, 0, 459)
        timer off 42
        qui timer list
        local time_isid = r(t42)
    restore

    preserve
        timer clear
        timer on 43
        cap gisid `varlist' `ix', `options' missok
        assert inlist(_rc, 0, 459)
        timer off 43
        qui timer list
        local time_gisid = r(t43)
    restore

    if ( "`fisid'" == "fisid" ) {
    preserve
        timer clear
        timer on 44
        cap fisid `varlist' `ix', missok
        assert inlist(_rc, 0, 459)
        timer off 44
        qui timer list
        local time_fisid = r(t44)
    restore
    }
    else {
        local time_fisid = .
    }

    local rs = `time_isid'  / `time_gisid'
    local rf = `time_fisid' / `time_gisid'
    di as txt "    `:di %5.3g `time_isid'' | `:di %5.3g `time_fisid'' | `:di %5.3g `time_gisid'' | `:di %11.3g `rs'' | `:di %11.3g `rf'' | `varlist'"
end
