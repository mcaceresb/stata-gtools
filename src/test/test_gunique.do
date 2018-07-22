capture program drop checks_unique
program checks_unique
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_unique, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(5000)
    qui expand 2
    gen long ix = _n

    checks_inner_unique str_12,              `options'
    checks_inner_unique str_12 str_32,       `options' by(str_4) replace
    checks_inner_unique str_12 str_32 str_4, `options'

    checks_inner_unique double1,                 `options'
    checks_inner_unique double1 double2,         `options' by(double3) replace
    checks_inner_unique double1 double2 double3, `options'

    checks_inner_unique int1,           `options'
    checks_inner_unique int1 int2,      `options' by(int3) replace
    checks_inner_unique int1 int2 int3, `options'

    checks_inner_unique int1 str_32 double1,                                        `options'
    checks_inner_unique int1 str_32 double1 int2 str_12 double2,                    `options' by(int3 str_4 double3) replace
    checks_inner_unique int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")

        * This is for the benefit of gtop, which can only handle strings that are so long
        qui `noisily' gen_data, n(50)
        qui expand 200
        gen long ix = _n

        checks_inner_unique strL1,             `options' `forcestrl'
        checks_inner_unique strL1 strL2,       `options' `forcestrl' by(strL3) replace
        checks_inner_unique strL1 strL2 strL3, `options' `forcestrl'
    }

    clear
    gen x = 1
    cap gunique x
    assert _rc == 2000

    clear
    set obs 10
    gen x = 1
    cap gunique x if x < 0
    assert _rc == 0
    cap gunique x if 0
    assert _rc == 0
    replace x = .
    cap gunique x if 0
    assert _rc == 0
end

capture program drop checks_inner_unique
program checks_inner_unique
    syntax varlist, [*]
    cap gunique `varlist', `options' v bench miss
    assert _rc == 0

    cap gunique `varlist' in 1, `options' miss d
    assert _rc == 0
    assert `r(N)' == `r(J)'
    assert `r(J)' == 1

    cap gunique `varlist' if _n == 1, `options' miss
    assert _rc == 0
    assert `r(N)' == `r(J)'
    assert `r(J)' == 1

    cap gunique `varlist' if _n < 10 in 5, `options' miss d
    assert _rc == 0
    assert `r(N)' == `r(J)'
    assert `r(J)' == 1
end

***********************************************************************
*                               Compare                               *
***********************************************************************

capture program drop compare_unique
program compare_unique
    syntax, [tol(real 1e-6) NOIsily distinct unique *]

    if ( "`distinct'`unique'" == "" ) local unique unique
    if ( ("`distinct'" != "") & ("`unique'" != "") ) {
        di as err "Specify only one of: unique distinct"
        exit 198
    }

    qui `noisily' gen_data, n(1000)
    qui expand 100

    local N    = trim("`: di %15.0gc _N'")
    local hlen = 22 + length("`options'") + length("`N'")
    di _n(1) "{hline 80}" _n(1) "compare_`distinct'`unique', N = `N', `options'" _n(1) "{hline 80}" _n(1)

    local options `options' `distinct'`unique'

    compare_inner_unique str_12,              `options' sort
    compare_inner_unique str_12 str_32,       `options' shuffle
    compare_inner_unique str_12 str_32 str_4, `options'

    compare_inner_unique double1,                 `options'
    compare_inner_unique double1 double2,         `options' sort
    compare_inner_unique double1 double2 double3, `options' shuffle

    compare_inner_unique int1,           `options' shuffle
    compare_inner_unique int1 int2,      `options'
    compare_inner_unique int1 int2 int3, `options' sort

    compare_inner_unique int1 str_32 double1,                                        `options'
    compare_inner_unique int1 str_32 double1 int2 str_12 double2,                    `options'
    compare_inner_unique int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        compare_inner_unique strL1,             `options' `forcestrl' shuffle
        compare_inner_unique strL1 strL2,       `options' `forcestrl' 
        compare_inner_unique strL1 strL2 strL3, `options' `forcestrl' sort
    }
end

capture program drop compare_inner_unique
program compare_inner_unique
    syntax varlist, [distinct unique sort shuffle *]

    tempvar rsort
    if ( "`shuffle'" != "" ) gen `rsort' = runiform()
    if ( "`shuffle'" != "" ) sort `rsort'
    if ( ("`sort'" != "") & ("`anything'" != "") ) hashsort `anything'

    if ( "`distinct'" != "" ) {
        local joint joint
        local rname ndistinct
    }
    else {
        local joint
        local rname unique
    }

    local options `options' `joint'

    tempvar rsort ix
    gen `rsort' = runiform()
    gen long `ix' = _n

    cap `distinct'`unique' `varlist', `joint'
    local nJ_`distinct'`unique' = `r(`rname')'
    cap g`distinct'`unique' `varlist', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( `varlist') `distinct'`unique'

    cap `distinct'`unique' `ix' `varlist', `joint'
    local nJ_`distinct'`unique' = `r(`rname')'
    cap g`distinct'`unique' `ix' `varlist', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( ix `varlist') `distinct'`unique'

    cap `distinct'`unique' `rsort' `varlist', `joint'
    local nJ_`distinct'`unique' = `r(`rname')'
    cap g`distinct'`unique' `rsort' `varlist', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( rsort `varlist') `distinct'`unique'

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    qui replace `ix' = `=_N / 2' if _n > `=_N / 2'
    cap `distinct'`unique' `ix', `joint'
    local nJ_`distinct'`unique' = `r(`rname')'
    cap g`distinct'`unique' `ix', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( ix) `distinct'`unique'

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    preserve
        qui keep in 100 / `=ceil(`=_N / 2')'
        cap `distinct'`unique' `ix' `varlist', `joint'
        local nJ_`distinct'`unique' = `r(`rname')'
    restore
    cap g`distinct'`unique' `ix' `varlist' in 100 / `=ceil(`=_N / 2')', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels  `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( ix `varlist' in 100 / `=ceil(`=_N / 2')') `distinct'`unique'

    preserve
        qui keep in `=ceil(`=_N / 2')' / `=_N'
        cap `distinct'`unique' `ix' `varlist', `joint'
        local nJ_`distinct'`unique' = `r(`rname')'
    restore
    cap g`distinct'`unique' `ix' `varlist' in `=ceil(`=_N / 2')' / `=_N', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels  `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( ix `varlist' in `=ceil(`=_N / 2')' / `=_N') `distinct'`unique'

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    preserve
        qui keep if _n < `=_N / 2'
        cap `distinct'`unique' `ix' `varlist', `joint'
        local nJ_`distinct'`unique' = `r(`rname')'
    restore
    cap g`distinct'`unique' `ix' `varlist' if _n < `=_N / 2', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels  `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( ix `varlist' if _n < `=_N / 2') `distinct'`unique'

    preserve
        qui keep if _n > `=_N / 2'
        cap `distinct'`unique' `ix' `varlist', `joint'
        local nJ_`distinct'`unique' = `r(`rname')'
    restore
    cap g`distinct'`unique' `ix' `varlist' if _n > `=_N / 2', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels  `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( ix `varlist' if _n > `=_N / 2') `distinct'`unique'

    * ---------------------------------------------------------------------
    * ---------------------------------------------------------------------

    qui replace `ix' = 100 in 1 / 100

    preserve
        qui keep if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')'
        cap `distinct'`unique' `ix' `varlist', `joint'
        local nJ_`distinct'`unique' = `r(`rname')'
    restore
    cap g`distinct'`unique' `ix' `varlist' if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels  `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( ix `varlist' if _n < `=_N / 4' in 100 / `=ceil(`=_N / 2')') `distinct'`unique'

    preserve
        qui keep if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N'
        cap `distinct'`unique' `ix' `varlist', `joint'
        local nJ_`distinct'`unique' = `r(`rname')'
    restore
    cap g`distinct'`unique' `ix' `varlist' if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N', `options'
    local nJ_g`distinct'`unique' = `r(`rname')'
    check_nlevels  `nJ_`distinct'`unique'' `nJ_g`distinct'`unique'' , by( ix `varlist' if _n > `=_N / 4' in `=ceil(`=_N / 1.5')' / `=_N') `distinct'`unique'

    di _n(1)
end

capture program drop check_nlevels
program check_nlevels
    syntax anything, by(str) [distinct unique]

    tokenize `anything'
    local nJ   `1'
    local nJ_g `2'

    if ( `nJ' != `nJ_g' ) {
        di as err "    compare_`distinct'`unique' (failed): `distinct'`unique' `by' gave `nJ' levels but g`distinct'`unique' gave `nJ_g'"
        exit 198
    }
    else {
        di as txt "    compare_`distinct'`unique' (passed): `distinct'`unique' and g`distinct'`unique' `by' gave the same number of levels"
    }
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_unique
program bench_unique
    syntax, [tol(real 1e-6) bench(int 1) n(int 1000) NOIsily distinct joint distunique *]

    if ( "`distinct'" != "" ) {
        local dstr distinct
        local dsep --------
    }
    else {
        local dstr unique
        local dsep ------
    }

    if ( "`joint'" != "" ) {
        local dj   , joint;
    }
    else {
        local dj   ,
    }

    local options `options' `distinct' `joint' `distunique'

    qui `noisily' gen_data, n(`n')
    qui expand `=100 * `bench''
    qui gen rsort = rnormal()
    qui sort rsort

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    if ( ("`distunique'" != "") & ("`joint'" != "") ) {
        di as txt _n(1)
        di as txt "Benchmark vs `dstr'`dj' obs = `N', all calls include a unique index (in seconds)"
        di as txt "     `dstr' |    unique | g`dstr' | ratio (d/g) | ratio (u/g) | varlist"
        di as txt "     `dsep' | -`dsep' | -`dsep' | ----------- | ----------- | -------"
    }
    else {
        di as txt _n(1)
        di as txt "Benchmark vs `dstr'`dj' obs = `N', all calls include a unique index (in seconds)"
        di as txt "     `dstr' | f`dstr' | g`dstr' | ratio (d/g) | ratio (u/g) | varlist"
        di as txt "     `dsep' | -`dsep' | -`dsep' | ----------- | ----------- | -------"
    }

    versus_unique str_12,              `options' unique
    versus_unique str_12 str_32,       `options' unique
    versus_unique str_12 str_32 str_4, `options' unique

    versus_unique double1,                 `options' unique
    versus_unique double1 double2,         `options' unique
    versus_unique double1 double2 double3, `options' unique

    versus_unique int1,           `options' unique
    versus_unique int1 int2,      `options' unique
    versus_unique int1 int2 int3, `options' unique

    * versus_unique str_12,              `options' funique unique
    * versus_unique str_12 str_32,       `options' funique unique
    * versus_unique str_12 str_32 str_4, `options' funique unique
    *
    * versus_unique double1,                 `options' funique unique
    * versus_unique double1 double2,         `options' funique unique
    * versus_unique double1 double2 double3, `options' funique unique
    *
    * versus_unique int1,           `options' funique unique
    * versus_unique int1 int2,      `options' funique unique
    * versus_unique int1 int2 int3, `options' funique unique

    versus_unique int1 str_32 double1,                                        unique `options'
    versus_unique int1 str_32 double1 int2 str_12 double2,                    unique `options'
    versus_unique int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, unique `options'

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        versus_unique strL1,             `options' `forcestrl' unique
        versus_unique strL1 strL2,       `options' `forcestrl' unique
        versus_unique strL1 strL2 strL3, `options' `forcestrl' unique
    }

    if ( ("`distunique'" != "") & ("`joint'" != "") ) {
        di as txt _n(1)
        di as txt "Benchmark vs `dstr'`dj' obs = `N', J = `J' (in seconds)"
        di as txt "     `dstr' |    unique | g`dstr' | ratio (d/g) | ratio (u/g) | varlist"
        di as txt "     `dsep' | -`dsep' | -`dsep' | ----------- | ----------- | -------"
    }
    else {
        di as txt _n(1)
        di as txt "Benchmark vs `dstr'`dj' obs = `N', J = `J' (in seconds)"
        di as txt "     `dstr' | f`dstr' | g`dstr' | ratio (u/g) | ratio (f/g) | varlist"
        di as txt "     `dsep' | -`dsep' | -`dsep' | ----------- | ----------- | -------"
    }

    versus_unique str_12,              `options'
    versus_unique str_12 str_32,       `options'
    versus_unique str_12 str_32 str_4, `options'

    versus_unique double1,                 `options'
    versus_unique double1 double2,         `options'
    versus_unique double1 double2 double3, `options'

    versus_unique int1,           `options'
    versus_unique int1 int2,      `options'
    versus_unique int1 int2 int3, `options'

    * versus_unique str_12,              `options' funique
    * versus_unique str_12 str_32,       `options' funique
    * versus_unique str_12 str_32 str_4, `options' funique
    *
    * versus_unique double1,                 `options' funique
    * versus_unique double1 double2,         `options' funique
    * versus_unique double1 double2 double3, `options' funique
    *
    * versus_unique int1,           `options' funique
    * versus_unique int1 int2,      `options' funique
    * versus_unique int1 int2 int3, `options' funique

    versus_unique int1 str_32 double1,                                        `options'
    versus_unique int1 str_32 double1 int2 str_12 double2,                    `options'
    versus_unique int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    if ( `c(stata_version)' >= 14 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        versus_unique strL1,             `options' `forcestrl'
        versus_unique strL1 strL2,       `options' `forcestrl'
        versus_unique strL1 strL2 strL3, `options' `forcestrl'
    }

    di as txt _n(1) "{hline 80}" _n(1) "bench_unique, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop versus_unique
program versus_unique, rclass
    syntax varlist, [funique unique distinct joint distunique *]
    if ( "`unique'" == "unique" ) {
        tempvar ix
        gen `ix' = `=_N' - _n
        if ( strpos("`varlist'", "str") ) qui tostring `ix', replace
    }

    preserve
        timer clear
        timer on 42
        cap unique `varlist' `ix'
        assert inlist(_rc, 0, 459)
        timer off 42
        qui timer list
        local time_unique = r(t42)
    restore

    preserve
        timer clear
        timer on 43
        cap gunique `varlist' `ix', `options'
        assert inlist(_rc, 0, 459)
        timer off 43
        qui timer list
        local time_gunique = r(t43)
    restore

    if ( ("`funique'" == "funique") & ("`distinct'" == "") ) {
    preserve
        timer clear
        timer on 44
        cap funique `varlist' `ix'
        assert inlist(_rc, 0, 459)
        timer off 44
        qui timer list
        local time_funique = r(t44)
    restore
    }
    else if ( "`distunique'" != "" ) {
    preserve
        timer clear
        timer on 44
        cap unique `varlist' `ix'
        assert inlist(_rc, 0, 459)
        timer off 44
        qui timer list
        local time_funique = r(t44)
    restore
    }
    else {
        local time_funique = .
    }

    local rs = `time_unique'  / `time_gunique'
    local rf = `time_funique' / `time_gunique'

    if ( "`distinct'" == "" ) {
    di as txt "    `:di %7.3g `time_unique'' | `:di %7.3g `time_funique'' | `:di %7.3g `time_gunique'' | `:di %11.3g `rs'' | `:di %11.3g `rf'' | `varlist'"
    }
    else {
    di as txt "    `:di %9.3g `time_unique'' | `:di %9.3g `time_funique'' | `:di %9.3g `time_gunique'' | `:di %11.3g `rs'' | `:di %11.3g `rf'' | `varlist'"
    }
end

* Prototype of -unique-
* ---------------------

* cap mata: mata drop funique()
* mata:
* mata set matastrict off
* void funique(string scalar varlist, real scalar detail)
* {
* 	class Factor scalar F
* 	F = factor(varlist)
* 	printf("{txt}Number of unique values of turn is {res}%-11.0f{txt}\n", F.num_levels)
* 	printf("{txt}Number of records is {res}%-11.0f{txt}\n", F.num_obs)
* 	if (detail) {
* 		(void) st_addvar("long", tempvar=st_tempname())
* 		st_store(1::F.num_levels, tempvar, F.counts)
* 		st_varlabel(tempvar, "Records per " + invtokens(F.varlist))
* 		stata("su " + tempvar + ", detail")
* 	}
* }
* end
*
* cap program drop funique
* program funique
* 	syntax varlist [if] [in], [Detail]
* 	
* 	mata: funique("`varlist'", "`detail'"!="")
* end
