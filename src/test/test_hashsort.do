capture program drop checks_hashsort
program checks_hashsort
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_hashsort, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(5000)
    qui expand 2
    gen long ix = _n

    checks_inner_hashsort -str_12,              `options'
    checks_inner_hashsort str_12 -str_32,       `options'
    checks_inner_hashsort str_12 -str_32 str_4, `options'

    checks_inner_hashsort -double1,                 `options'
    checks_inner_hashsort double1 -double2,         `options'
    checks_inner_hashsort double1 -double2 double3, `options'

    checks_inner_hashsort -int1,           `options'
    checks_inner_hashsort int1 -int2,      `options'
    checks_inner_hashsort int1 -int2 int3, `options'

    checks_inner_hashsort -int1 -str_32 -double1,                                         `options'
    checks_inner_hashsort int1 -str_32 double1 -int2 str_12 -double2,                     `options'
    checks_inner_hashsort int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options'

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        checks_inner_hashsort -strL1,             `options' `forcestrl'
        checks_inner_hashsort strL1 -strL2,       `options' `forcestrl'
        checks_inner_hashsort strL1 -strL2 strL3, `options' `forcestrl'
    }

    sysuse auto, clear
    gen idx = _n
    hashsort -foreign rep78 make -mpg, `options'
    hashsort idx,                      `options'
    hashsort -foreign -rep78,          `options'
    hashsort idx,                      `options'
    hashsort foreign rep78 mpg,        `options'
    hashsort idx,                      `options' v bench

    * https://github.com/mcaceresb/stata-gtools/issues/31
    qui {
        clear
        set obs 10
        gen x = "hi"
        replace x = "" in 1 / 5
        gen y = floor(_n / 3)
        replace y = .a in 1
        replace y = .b in 2
        replace y = .c in 3
        replace y = .  in 4

        preserve
            gsort x -y
            tempfile a
            save "`a'"
        restore
        hashsort x -y, mlast
        cf * using "`a'"
    }

    ****************
    *  Misc tests  *
    ****************

    clear
    gen x = 1
    hashsort x

    clear
    set obs 10
    gen x = _n
    expand 3
    hashsort x, gen(y) sortgen
    assert "`:sortedby'" == "y"
    hashsort x, v
    assert "`:sortedby'" == "x"
    hashsort x, skipcheck v
    hashsort x, gen(y) replace
    assert "`:sortedby'" == "x"
end

capture program drop checks_inner_hashsort
program checks_inner_hashsort
    syntax anything, [*]
    tempvar ix
    hashsort `anything', `options' gen(`ix')
    hashsort `: subinstr local anything "-" "", all', `options'
    hashsort ix, `options'
end

capture program drop bench_hashsort
program bench_hashsort
    compare_hashsort `0'
end

capture program drop compare_hashsort
program compare_hashsort
    syntax, [tol(real 1e-6) NOIsily bench(int 1) n(int 1000) benchmode *]
    local options `options' `benchmode'
    if ( "`benchmode'" == "" ) {
        local benchcomp Comparison
    }
    else {
        local benchcomp Benchmark
    }

    cap gen_data, n(`n')
    qui expand 10 * `bench'
    qui gen rsort = rnormal()
    qui sort rsort

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    di _n(1)
    di "`benchcomp' vs gsort, obs = `N', J = `J' (in seconds; datasets are compared via {opt cf})"
    di "    gsort | hashsort | ratio (g/h) | varlist"
    di "    ----- | -------- | ----------- | -------"

    compare_gsort -str_12,              `options' mfirst
    compare_gsort str_12 -str_32,       `options' mfirst
    compare_gsort str_12 -str_32 str_4, `options' mfirst

    compare_gsort -double1,                 `options' mfirst
    compare_gsort double1 -double2,         `options' mlast
    compare_gsort double1 -double2 double3, `options' mfirst

    compare_gsort -int1,           `options' mfirst
    compare_gsort int1 -int2,      `options' mfirst
    compare_gsort int1 -int2 int3, `options' mlast

    compare_gsort -int1 -str_32 -double1,                                         `options' mlast
    compare_gsort int1 -str_32 double1 -int2 str_12 -double2,                     `options' mfirst
    compare_gsort int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options' mfirst

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        compare_gsort -strL1,             `options' mfirst `forcestrl'
        compare_gsort strL1 -strL2,       `options' mfirst `forcestrl'
        compare_gsort strL1 -strL2 strL3, `options' mlast  `forcestrl'
    }

    qui expand 10
    local N = trim("`: di %15.0gc _N'")
    cap drop rsort
    qui gen rsort = rnormal()
    qui sort rsort

    di _n(1)
    di "`benchcomp' vs sort (stable), obs = `N', J = `J' (in seconds; datasets are compared via {opt cf})"
    di "     sort | fsort | hashsort | ratio (s/h) | ratio (f/h) | varlist"
    di "     ---- | ----- | -------- | ----------- | ----------- | -------"

    compare_sort str_12,              `options' fsort
    compare_sort str_12 str_32,       `options' fsort
    compare_sort str_12 str_32 str_4, `options' fsort

    compare_sort double1,                 `options' fsort
    compare_sort double1 double2,         `options' fsort
    compare_sort double1 double2 double3, `options' fsort

    compare_sort int1,           `options' fsort
    compare_sort int1 int2,      `options' fsort
    compare_sort int1 int2 int3, `options' fsort

    compare_sort int1 str_32 double1,                                        `options'
    compare_sort int1 str_32 double1 int2 str_12 double2,                    `options'
    compare_sort int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        compare_sort strL1,             `options' mfirst `forcestrl'
        compare_sort strL1 strL2,       `options' mfirst `forcestrl'
        compare_sort strL1 strL2 strL3, `options' mlast  `forcestrl'
    }

    di _n(1) "{hline 80}" _n(1) "compare_hashsort, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop compare_sort
program compare_sort, rclass
    syntax varlist, [fsort benchmode *]
    local rc = 0

    timer clear
    preserve
        timer on 42
        sort `varlist' , stable
        timer off 42
        tempfile file_sort
        qui save `file_sort'
    restore
    qui timer list
    local time_sort = r(t42)

    timer clear
    preserve
        timer on 43
        qui hashsort `varlist', `options'
        timer off 43
        cf * using `file_sort'
        * if ( _rc ) {
        *     qui ds *
        *     local memvars `r(varlist)'
        *     local firstvar: word 1 of `varlist'
        *     local compvars: list memvars - firstvar
        *     if ( "`compvars'" != "" ) {
        *         cf `compvars' using `file_sort'
        *     }
        *     keep `firstvar'
        *     tempfile file_first
        *     qui save `file_first'
        *
        *     use `firstvar' using `file_sort', clear
        *     rename `firstvar' c_`firstvar'
        *     qui merge 1:1 _n using `file_first'
        *     cap noi assert (`firstvar' == c_`firstvar') | (abs(`firstvar' - c_`firstvar') < 1e-15)
        *     if ( _rc ) {
        *         local rc = _rc
        *         di as err "hashsort gave different sort order to sort"
        *     }
        *     else {
        *         if ("`benchmode'" == "") di as txt "    hashsort same as sort but sortpreserve trick caused some loss of precision (< 1e-15)"
        *     }
        * }

        * Make sure already sorted check is OK
        qui gen byte one = 1
        hashsort one `varlist', `options'
        qui drop one
        cf * using `file_sort'
        * if ( _rc ) {
        *     qui ds *
        *     local memvars `r(varlist)'
        *     local firstvar: word 1 of `varlist'
        *     local compvars: list memvars - firstvar
        *     if ( "`compvars'" != "" ) {
        *         cf `compvars' using `file_sort'
        *     }
        *     keep `firstvar'
        *     tempfile file_one
        *     qui save `file_one'
        *
        *     use `firstvar' using `file_sort', clear
        *     rename `firstvar' c_`firstvar'
        *     qui merge 1:1 _n using `file_one'
        *     cap noi assert (`firstvar' == c_`firstvar') | (abs(`firstvar' - c_`firstvar') < 1e-15)
        *     if ( _rc ) {
        *         local rc = _rc
        *         di as err "hashsort gave different sort order to sort"
        *     }
        *     else {
        *         if ("`benchmode'" == "") di as txt "    hashsort same as sort but sortpreserve trick caused some loss of precision (< 1e-15)"
        *     }
        * }
    restore
    qui timer list
    local time_hashsort = r(t43)

    if ( `rc' ) exit `rc'

    if ( "`fsort'" == "fsort" ) {
        timer clear
        preserve
            timer on 44
            cap fsort `varlist'
            local rc_f = _rc
            timer off 44
            if ( `rc_f' ) {
                disp as err "(warning: fsort `varlist' failed)"
            }
            else {
                cap noi cf * using `file_sort'
                if ( _rc ) {
                    disp as txt "(note: ftools `varlist' returned different data vs sort, stable)"
                }
            }
        restore
        if ( `rc_f' ) {
            local time_fsort = .
        }
        else {
            qui timer list
            local time_fsort = r(t44)
        }
    }
    else {
        local time_fsort = .
    }

    local rs = `time_sort'  / `time_hashsort'
    local rf = `time_fsort' / `time_hashsort'
    di "    `:di %5.3g `time_sort'' | `:di %5.3g `time_fsort'' | `:di %8.3g `time_hashsort'' | `:di %11.3g `rs'' | `:di %11.3g `rf'' | `varlist'"
end

capture program drop compare_gsort
program compare_gsort, rclass
    syntax anything, [benchmode mfirst mlast *]
    tempvar ix
    gen long `ix' = _n
    if ( "`benchmode'" == "" ) local gstable `ix'

    timer clear
    preserve
        timer on 42
        gsort `anything' `gstable', `mfirst'
        timer off 42
        tempfile file_sort
        qui save `file_sort'
    restore
    qui timer list
    local time_sort = r(t42)

    timer clear
    preserve
        timer on 43
        qui hashsort `anything', `mlast'  `options'
        timer off 43
        cf `:di subinstr("`anything'", "-", "", .)' using `file_sort'
    restore
    qui timer list
    local time_hashsort = r(t43)

    local rs = `time_sort'  / `time_hashsort'
    di "    `:di %5.3g `time_sort'' | `:di %8.3g `time_hashsort'' | `:di %11.3g `rs'' | `anything'"
end
