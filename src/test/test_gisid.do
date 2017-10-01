capture program drop checks_isid
program checks_isid
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "consistency_isid, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' sim, n(5000) nj(100) njsub(4) string groupmiss outmiss
    gen ix = _n

    foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by groupsub groupstr
        if ( `i' == 3 ) local by groupstr groupsubstr 
        if ( `i' == 6 ) local by groupsub group
        if ( `i' == 9 ) local by grouplong
        cap gisid `by', `options' v b missok
        assert _rc == 459

        cap gisid `by' in 1, `options'
        assert _rc == 0

        cap gisid `by' if _n == 1, `options'
        assert _rc == 0

        cap gisid `by' if _n < 10 in 5, `options'
        assert _rc == 0
    }

    clear
    gen x = 1
    cap gisid x
    assert _rc == 0
end

capture program drop compare_isid
program compare_isid
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "consistency_isid, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' sim, n(500000) nj(10000) njsub(4) string groupmiss outmiss
    gen ix = _n

    local i 0
    foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by groupsub groupstr
        if ( `i' == 3 ) local by groupstr groupsubstr 
        if ( `i' == 6 ) local by groupsub group
        if ( `i' == 9 ) local by grouplong
        cap isid `by', missok
        local rc_isid = _rc
        cap gisid `by', missok `options'
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by(`by')
    }

    foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by rsort rnorm groupsub groupstr
        if ( `i' == 3 ) local by rsort rnorm groupstr
        if ( `i' == 6 ) local by rsort rnorm groupsub group
        if ( `i' == 9 ) local by rsort rnorm grouplong
        cap isid `by', missok
        local rc_isid = _rc
        cap gisid `by', missok
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by(`by')
    }

    foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by ix groupsub groupstr
        if ( `i' == 3 ) local by ix groupstr
        if ( `i' == 6 ) local by ix groupsub group
        if ( `i' == 9 ) local by ix grouplong
        cap isid `by', missok
        local rc_isid = _rc
        cap gisid `by', missok `options'
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by(`by')
    }

    qui replace ix = `=_N / 2' if _n > `=_N / 2'
    cap isid ix
    local rc_isid = _rc
    cap gisid ix, `options'
    local rc_gisid = _rc
    check_rc `rc_isid' `rc_gisid' , by(ix)

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by ix groupsub groupstr
        if ( `i' == 3 ) local by ix groupstr
        if ( `i' == 6 ) local by ix groupsub group
        if ( `i' == 9 ) local by ix grouplong

        preserve
            qui keep in 100 / `=ceil(`=_N / 2')'
            cap isid `by', missok
            local rc_isid = _rc
        restore
        cap gisid `by' in 100 / `=ceil(`=_N / 2')', missok `options'
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by( `by' in 100 / `=ceil(`=_N / 2')')

        preserve
            qui keep in `=ceil(`=_N / 2')' / `=_N'
            cap isid `by', missok
            local rc_isid = _rc
        restore
        cap gisid `by' in `=ceil(`=_N / 2')' / `=_N', missok `options'
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by(`by' in `=ceil(`=_N / 2')' / `=_N')

    di _n(1)

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

        preserve
            qui keep if _n < `=_N / 2'
            cap isid `by', missok
            local rc_isid = _rc
        restore
        cap gisid `by' if _n < `=_N / 2', missok
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by(`by' if _n < `=_N / 2')

        preserve
            qui keep if _n > `=_N / 2'
            cap isid `by', missok
            local rc_isid = _rc
        restore
        cap gisid `by' if _n > `=_N / 2', missok `options'
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by(`by' if _n > `=_N / 2')

    di _n(1)

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

        qui replace ix = 100 in 1 / 100

        preserve
            qui keep if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')'
            cap isid `by', missok
            local rc_isid = _rc
        restore
        cap gisid `by' if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')', missok `options'
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by( `by' if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')')

        preserve
            qui keep if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N'
            cap isid `by', missok
            local rc_isid = _rc
        restore
        cap gisid `by' if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N', missok
        local rc_gisid = _rc
        check_rc  `rc_isid' `rc_gisid' , by( `by' if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N')

        qui replace ix = _n in 1 / 100
    }
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
    syntax, [tol(real 1e-6) bench(int 1) NOIsily *]

    cap gen_data, n(10000) expand(`=100 * `bench'')
    qui gen rsort = rnormal()
    qui sort rsort

    local N = trim("`: di %15.0gc _N'")

    di _n(1)
    di "Benchmark vs isid, obs = `N', all calls include an index to ensure uniqueness (in seconds)"
    di "     isid | fisid | gisid | ratio (i/g) | ratio (f/g) | varlist"
    di "     ---- | ----- | ----- | ----------- | ----------- | -------"

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

    di _n(1)
    di "Benchmark vs isid, obs = `N', J = 10,000 (in seconds)"
    di "     isid | fisid | gisid | ratio (i/g) | ratio (f/g) | varlist"
    di "     ---- | ----- | ----- | ----------- | ----------- | -------"

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

    di _n(1) "{hline 80}" _n(1) "bench_isid, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop gen_data
program gen_data
    syntax, [n(int 100) expand(int 1)]
    clear
    set obs `n'
    qui ralpha str_long,  l(5)
    qui ralpha str_mid,   l(3)
    qui ralpha str_short, l(1)
    gen str32 str_32   = str_long + "this is some string padding"
    gen str12 str_12   = str_mid  + "padding" + str_short + str_short
    gen str4  str_4    = str_mid  + str_short

    gen long int1  = floor(rnormal())
    gen long int2  = floor(uniform() * 1000)
    gen long int3  = floor(rnormal() * 5 + 10)

    gen double double1 = rnormal()
    gen double double2 = uniform() * 1000
    gen double double3 = rnormal() * 5 + 10

    qui expand `expand'
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
        cap isid `varlist' `ix'
        assert inlist(_rc, 0, 459)
        timer off 42
        qui timer list
        local time_isid = r(t42)
    restore

    preserve
        timer clear
        timer on 43
        cap gisid `varlist' `ix', `options'
        assert inlist(_rc, 0, 459)
        timer off 43
        qui timer list
        local time_gisid = r(t43) 
    restore

    if ( "`fisid'" == "fisid" ) {
    preserve
        timer clear
        timer on 44
        cap fisid `varlist' `ix'
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
    di "    `:di %5.3g `time_isid'' | `:di %5.3g `time_fisid'' | `:di %5.3g `time_gisid'' | `:di %11.3g `rs'' | `:di %11.3g `rf'' | `varlist'"
end
