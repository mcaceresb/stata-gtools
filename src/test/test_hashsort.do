capture program drop checks_hashsort
program checks_hashsort
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_hashsort, `options'" _n(1) "{hline 80}" _n(1)
    sysuse auto, clear
    gen idx = _n
    hashsort -foreign rep78 make -mpg, `options'
    hashsort idx, `options'
    hashsort -foreign rep78, `options'
    hashsort idx, `options'
    hashsort foreign rep78 mpg, `options'
    hashsort idx, v b `options'
end

capture program drop compare_hashsort
program compare_hashsort
    syntax, [tol(real 1e-6) NOIsily *]

    cap gen_data, n(10000)
    qui expand 100

    local N = trim("`: di %15.0gc _N'")

    di _n(2)
    di "Benchmark vs sort, obs = `N', J = 10,000 (in seconds; datasets are compared via {opt cf})"
    di "    ratio | sort | hashsort | varlist"
    di "    ----- | ---- | -------- | -------"

    compare_sort str_12, `options'
    compare_sort str_12 str_32, `options'
    compare_sort str_12 str_32 str_4, `options'

    compare_sort double1, `options'
    compare_sort double1 double2, `options'
    compare_sort double1 double2 double3, `options'

    compare_sort int1, `options'
    compare_sort int1 int2, `options'
    compare_sort int1 int2 int3, `options'

    compare_sort int1 str_32 double1, `options'
    compare_sort int1 str_32 double1 int2 str_12 double2, `options'
    compare_sort int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    di _n(2)
    di "Benchmark vs gsort, obs = `N', J = 10,000 (in seconds; datasets are compared via {opt cf})"
    di "    ratio | gsort | hashsort | varlist"
    di "    ----- | ----- | -------- | -------"

    compare_gsort -str_12, `options'
    compare_gsort str_12 -str_32, `options'
    compare_gsort str_12 -str_32 str_4, `options'

    compare_gsort -double1, `options'
    compare_gsort double1 -double2, `options'
    compare_gsort double1 -double2 double3, `options'

    compare_gsort -int1, `options'
    compare_gsort int1 -int2, `options'
    compare_gsort int1 -int2 int3, `options'

    compare_gsort -int1 -str_32 -double1, `options'
    compare_gsort int1 -str_32 double1 -int2 str_12 -double2, `options'

    * cap gen_data, n(100)
    * qui expand 10000
    * compare_gsort int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options'

    di _n(1) "{hline 80}" _n(1) "compare_hashsort, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop gen_data
program gen_data
    syntax, [n(int 100)]
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
end

capture program drop compare_sort
program compare_sort, rclass
    syntax varlist, [*]

    timer clear
    preserve
        timer on 42
        sort `varlist' , stable
        timer off 42
        tempfile file_sort
        qui save `file_sort'
    restore
    qui timer list
    local time_sort `:di %9.3g r(t42)'

    timer clear
    preserve
        timer on 43
        qui hashsort `varlist', v b `options'
        timer off 43
        cf * using `file_sort'
    restore
    qui timer list
    local time_hashsort `:di %9.3g r(t43)'

    local r `:di %9.3g `time_sort' / `time_hashsort''
    di "     `r' | `time_sort' |     `time_hashsort' | `varlist'"
    return scalar time_sort  = `time_sort'
    return scalar time_hashsort = `time_hashsort'
end

capture program drop compare_gsort
program compare_gsort, rclass
    syntax anything, [*]
    tempvar ix
    gen long `ix' = _n

    timer clear
    preserve
        timer on 42
        gsort `anything' `ix'
        timer off 42
        tempfile file_sort
        qui save `file_sort'
    restore
    qui timer list
    local time_sort `:di %9.3g r(t42)'

    timer clear
    preserve
        timer on 43
        qui hashsort `anything', v b `options'
        timer off 43
        cf * using `file_sort'
    restore
    qui timer list
    local time_hashsort `:di %9.3g r(t43)'

    local r `:di %9.3g `time_sort' / `time_hashsort''
    di "     `r' |  `time_sort' |     `time_hashsort' | `anything'"
    return scalar time_sort  = `time_sort'
    return scalar time_hashsort = `time_hashsort'
end
