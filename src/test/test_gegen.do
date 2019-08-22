capture program drop checks_gegen
program checks_gegen
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_egen, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(5000)
    qui expand 2
    qui `noisily' random_draws, random(2)
    gen long ix = _n

    checks_inner_egen, `options'

    checks_inner_egen -str_12,              `options' hash(0)
    checks_inner_egen str_12 -str_32,       `options' hash(1)
    checks_inner_egen str_12 -str_32 str_4, `options' hash(2)

    checks_inner_egen -double1,                 `options' hash(2)
    checks_inner_egen double1 -double2,         `options' hash(0)
    checks_inner_egen double1 -double2 double3, `options' hash(1)

    checks_inner_egen -int1,           `options' hash(1)
    checks_inner_egen int1 -int2,      `options' hash(2)
    checks_inner_egen int1 -int2 int3, `options' hash(0)

    checks_inner_egen -int1 -str_32 -double1,                                         `options'
    checks_inner_egen int1 -str_32 double1 -int2 str_12 -double2,                     `options'
    checks_inner_egen int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options'

    if ( `c(stata_version)' >= 14.1 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        checks_inner_egen -strL1,             `options' hash(1) `forcestrl'
        checks_inner_egen strL1 -strL2,       `options' hash(2) `forcestrl'
        checks_inner_egen strL1 -strL2 strL3, `options' hash(0) `forcestrl'
    }

    clear
    set obs 10
    gen x = .
    gegen y = total(x), missing
    gegen z = total(x)
    assert y == .
    assert z == 0

    clear
    gen x = 1
    cap gegen y = group(x)
    assert _rc == 111

    clear
    set obs 10
    gen x = 1
    gegen y = group(x) if x > 1
    gegen z = tag(x)   if x > 1

    clear
    sysuse auto
    tempfile auto
    save `"`auto'"'

    clear
    set obs 5
    gen x = _n
    gen strL y = "hi" + string(mod(_n, 2)) + char(9) + char(0)
    replace y  = fileread(`"`auto'"') in 1
    cap gegen z = group(y)
    if ( `c(stata_version)' < 14.1 ) {
        assert _rc == 17002
    }
    else {
        assert _rc == 17005
    }

    clear
    cap gegen
    assert _rc == 100
    cap gegen x = group(y)
    assert _rc == 111
    set obs 10
    gen x = .
    gegen y = group(x)
    assert y == .
    gegen y = group(x), missing replace
    assert y == 1

    clear
    set obs 10
    gen x = _n
    gegen y = group(x) if 0
    assert y == .
    gegen z = group(x) if 1
    assert z == x
    gegen z = group(x) in 1 / 3, replace
    assert z == x | mi(z)
    gegen z = group(x) in 8, replace
    assert z == 1 | mi(z)

    gegen z = sum(x) in 1 / 3, by(x) replace
    assert z == x | mi(z)
    gegen z = sum(x) if x == 7, by(x) replace
    assert z == x | mi(z)
    gegen z = count(x) if x == 8, by(x) replace
    assert z == 1 | mi(z)

    gegen z = count(z) if x == 8, by(z) replace
    assert z[8] == 1
    assert mi(z) | _n == 8
    gegen z = group(z) in 8 / 9, replace missing
    assert z == (x - 7) | mi(z)
    gegen z = tag(z) in 7 / 10, replace missing
    assert z[7] == 1
    assert z[8] == 1
    assert z[9] == 1
    assert (z == 0) | z == 1
    gegen z = sum(z) in 2 / 9, replace
    assert z == 3 | inlist(_n, 1, 10)
    gegen z = sum(x* z*) in 2 / 9, replace
    assert z == `=4 * (2 + 9) + 8 * 3' | inlist(_n, 1, 10)
    gegen z = sum(x* z*) if 0, replace
    assert z == .
    gegen z = sum(x* z*) if 1, replace
    assert z != .
    cap gegen z = sum(x* z*) if 1
    assert _rc == 110

    clear
    set obs 10
    gen x = 1
    gen w = .
    gegen z = sum(x) [w = w]
    drop z
    replace w = 0
    gegen z = sum(x) [w = w]
    drop z
    gegen z = sum(x) [w = w] if w == 3.14

    clear
    set obs 10
    gen byte x = _n
    replace x = . in 1/5
    gen y = mi(x)
    gegen s = nansum(x)    , by(y)
    gegen ns = sum(x)      , by(y)
    gegen nm = nmissing(x) , by(y)
    gegen f_s = nansum(x)    [fw = 1314], by(y)
    gegen f_ns = sum(x)      [fw = 1314], by(y)
    gegen f_nm = nmissing(x) [fw = 1314], by(y)
    gegen a_s = nansum(x)    [aw = 13.14], by(y)
    gegen a_ns = sum(x)      [aw = 13.14], by(y)
    gegen a_nm = nmissing(x) [aw = 13.14], by(y)
    gegen p_s = nansum(x)    [pw = 987654321], by(y)
    gegen p_ns = sum(x)      [pw = 987654321], by(y)
    gegen p_nm = nmissing(x) [pw = 987654321], by(y)
    assert cond(mi(x), mi(s) & mi(f_s) & mi(a_s), !mi(s) & !mi(f_s) & !mi(a_s))
    assert cond(mi(x), (nm == 5) & (a_nm == 5) & (f_nm == 5 * 1314) & (p_nm == 5 * 987654321), (nm == 0) & (a_nm == 0) & (f_nm == 0) & (p_nm == 0))

    clear
    set obs 10000
    gen x = ceil(runiform() * 10)
    gen g = round(_n / 100)

     egen double rankx_def1 = rank(x)
    gegen double rankx_def2 = rank(x)

     egen rankx_track1 = rank(x), track
    gegen rankx_track2 = rank(x), ties(track)

     egen rankx_field1 = rank(x), field
    gegen rankx_field2 = rank(x), ties(field)

     egen long rankx_uniq1 = rank(x), uniq
    gegen long rankx_uniq2 = rank(x), ties(uniq)

    gegen rankx_uniq3 = rank(x), ties(stable)

     egen double rankx_group_def1 = rank(x), by(g)
    gegen double rankx_group_def2 = rank(x), by(g)

     egen rankx_group_track1 = rank(x), by(g) track
    gegen rankx_group_track2 = rank(x), by(g) ties(track)

     egen rankx_group_field1 = rank(x), by(g) field
    gegen rankx_group_field2 = rank(x), by(g) ties(field)

     egen long rankx_group_uniq1 = rank(x), by(g) uniq
    gegen long rankx_group_uniq2 = rank(x), by(g) ties(uniq)

    gegen rankx_group_uniq3 = rank(x), by(g) ties(stable)

    assert (rankx_def1   == rankx_def2)
    assert (rankx_track1 == rankx_track2)
    assert (rankx_field1 == rankx_field2)

    sort x, stable
    assert rankx_uniq3 == _n

    gisid rankx_uniq1
    gisid rankx_uniq2

    assert (rankx_group_def1   == rankx_group_def2)
    assert (rankx_group_track1 == rankx_group_track2)
    assert (rankx_group_field1 == rankx_group_field2)

    cap drop ix
    sort g x, stable
    by g: gen ix = _n
    assert rankx_group_uniq3 == ix

    gisid g rankx_group_uniq1
    gisid g rankx_group_uniq2

    gegen double rankx_def2 = rank(x) [fw = 1], replace
    gegen rankx_track2      = rank(x) [fw = 1], replace ties(track)
    gegen rankx_field2      = rank(x) [fw = 1], replace ties(field)
    gegen long rankx_uniq2  = rank(x) [fw = 1], replace ties(uniq)
    gegen rankx_uniq3       = rank(x) [fw = 1], replace ties(stable)

    gegen double rankx_group_def2 = rank(x) [fw = 1], replace by(g)
    gegen rankx_group_track2      = rank(x) [fw = 1], replace by(g) ties(track)
    gegen rankx_group_field2      = rank(x) [fw = 1], replace by(g) ties(field)
    gegen long rankx_group_uniq2  = rank(x) [fw = 1], replace by(g) ties(uniq)
    gegen rankx_group_uniq3       = rank(x) [fw = 1], replace by(g) ties(stable)

    assert (rankx_def1   == rankx_def2)
    assert (rankx_track1 == rankx_track2)
    assert (rankx_field1 == rankx_field2)

    sort x, stable
    assert rankx_uniq3 == _n

    gisid rankx_uniq1
    gisid rankx_uniq2

    assert (rankx_group_def1   == rankx_group_def2)
    assert (rankx_group_track1 == rankx_group_track2)
    assert (rankx_group_field1 == rankx_group_field2)

    cap drop ix
    sort g x, stable
    by g: gen ix = _n
    assert rankx_group_uniq3 == ix

    gisid g rankx_group_uniq1
    gisid g rankx_group_uniq2

    clear
    set obs 10
    gen x = rnormal()
    gen fw = _n
    gen aw = runiform() * 5
    gen pw = runiform()
    gen iw = rnormal()
    replace fw = . in 5
    replace x  = . in 3

    gegen r1_def    = rank(x) [fw = fw], ties(def)
    gegen r1_field  = rank(x) [fw = fw], ties(field)
    gegen r1_track  = rank(x) [fw = fw], ties(track)
    gegen r1_uniq   = rank(x) [fw = fw], ties(uniq)
    gegen r1_stable = rank(x) [fw = fw], ties(stable)

    gegen r2 = rank(x) [aw = aw]
    gegen r3 = rank(x) [pw = pw]
    gegen r4 = rank(x) [iw = iw]

    gisid r1_uniq if !mi(r1_uniq)
    gisid r1_stable if !mi(r1_stable)

    expand fw

    gegen r_def    = rank(x) if !mi(fw), ties(def)
    gegen r_field  = rank(x) if !mi(fw), ties(field)
    gegen r_track  = rank(x) if !mi(fw), ties(track)

    assert r_def    == r1_def   
    assert r_field  == r1_field 
    assert r_track  == r1_track 

    egen e_def    = rank(x) if !mi(fw)
    egen e_field  = rank(x) if !mi(fw), field
    egen e_track  = rank(x) if !mi(fw), track

    assert e_def    == r1_def   
    assert e_field  == r1_field 
    assert e_track  == r1_track 
end

capture program drop checks_inner_egen
program checks_inner_egen
    syntax [anything], [tol(real 1e-6) wgt(str) *]

    local 0 `anything' `wgt', `options'
    syntax [anything] [aw fw iw pw], [*]

    local percentiles 1 10 30.5 50 70.5 90 99
    local selections  1 2 5 999999 -999999 -5 -2 -1
    local stats nunique nmissing total sum mean geomean max min range count median iqr percent first last firstnm lastnm skew kurt
    local skipbulk
    if ( !inlist("`weight'", "pweight") )            local stats `stats' sd variance cv
    if ( !inlist("`weight'", "pweight", "iweight") ) local stats `stats' semean
    if (  inlist("`weight'", "fweight", "") )        local stats `stats' sebinomial sepoisson

    tempvar gvar
    foreach fun of local stats {
        `noisily' gegen `gvar' = `fun'(random1) `wgt', by(`anything') replace `options'
        if ( "`weight'" == "" & !(`:list fun in skipbulk') ) {
        `noisily' gegen `gvar' = `fun'(random*) `wgt', by(`anything') replace `options'
        }
    }

    foreach p in `percentiles' {
        `noisily' gegen `gvar' = pctile(random1) `wgt', p(`p') by(`anything') replace `options'
        if ( "`weight'" == "" ) {
        `noisily' gegen `gvar' = pctile(random*) `wgt', p(`p') by(`anything') replace `options'
        }
    }

    if ( !inlist("`weight'", "iweight") ) {
        foreach n in `selections' {
            `noisily' gegen `gvar' = select(random1) `wgt', n(`n') by(`anything') replace `options'
            if ( "`weight'" == "" ) {
            `noisily' gegen `gvar' = select(random*) `wgt', n(`n') by(`anything') replace `options'
            }
        }
    }

    if ( "`anything'" != "" ) {
        `noisily' gegen `gvar' = tag(`anything')   `wgt', replace `options'
        `noisily' gegen `gvar' = group(`anything') `wgt', replace `options'
        `noisily' gegen `gvar' = count(1)          `wgt', by(`anything') replace `options'
    }
end

***********************************************************************
*                               Compare                               *
***********************************************************************

capture program drop compare_egen
program compare_egen
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "consistency_egen, `options'" _n(1) "{hline 80}" _n(1)

    qui `noisily' gen_data, n(500)
    * qui expand 100
    qui `noisily' random_draws, random(2) float
    qui expand 10

    compare_inner_egen, `options' tol(`tol')

    compare_inner_egen str_12,              `options' tol(`tol') hash(1)
    compare_inner_egen str_12 str_32,       `options' tol(`tol') hash(0) sort
    compare_inner_egen str_12 str_32 str_4, `options' tol(`tol') hash(2) shuffle

    compare_inner_egen double1,                 `options' tol(`tol') hash(2) shuffle
    compare_inner_egen double1 double2,         `options' tol(`tol') hash(1)
    compare_inner_egen double1 double2 double3, `options' tol(`tol') hash(0) sort

    compare_inner_egen int1,           `options' tol(`tol') hash(0) sort
    compare_inner_egen int1 int2,      `options' tol(`tol') hash(2) shuffle
    compare_inner_egen int1 int2 int3, `options' tol(`tol') hash(1)

    compare_inner_egen int1 str_32 double1,                                        `options' tol(`tol')
    compare_inner_egen int1 str_32 double1 int2 str_12 double2,                    `options' tol(`tol')
    compare_inner_egen int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options' tol(`tol')

    if ( `c(stata_version)' >= 14.1 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        compare_inner_egen strL1,             `options' tol(`tol') hash(0) `forcestrl' sort
        compare_inner_egen strL1 strL2,       `options' tol(`tol') hash(2) `forcestrl' shuffle
        compare_inner_egen strL1 strL2 strL3, `options' tol(`tol') hash(1) `forcestrl'
    }
end

capture program drop compare_inner_egen
program compare_inner_egen
    syntax [anything], [tol(real 1e-6) sort shuffle *]

    tempvar rsort
    if ( "`shuffle'" != "" ) gen `rsort' = runiform()
    if ( "`shuffle'" != "" ) sort `rsort'
    if ( ("`sort'" != "") & ("`anything'" != "") ) {
        if ( strpos(`"`anything'"', "strL") > 0 ) {
            sort `anything'
        }
        else {
            hashsort `anything'
        }
    }

    local N = trim("`: di %15.0gc _N'")
    local hlen = 31 + length("`anything'") + length("`N'")

    di _n(2) "Checking egen. N = `N'; varlist = `anything'" _n(1) "{hline `hlen'}"

    _compare_inner_egen `anything', `options' tol(`tol')

    local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
    local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
    local from = cond(`in1' < `in2', `in1', `in2')
    local to   = cond(`in1' > `in2', `in1', `in2')
    _compare_inner_egen `anything' in `from' / `to', `options' tol(`tol')

    _compare_inner_egen `anything' if random2 > 0, `options' tol(`tol')

    local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
    local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
    local from = cond(`in1' < `in2', `in1', `in2')
    local to   = cond(`in1' > `in2', `in1', `in2')
    _compare_inner_egen `anything' if random2 < 0 in `from' / `to', `options' tol(`tol')
end

capture program drop _compare_inner_egen
program _compare_inner_egen
    syntax [anything] [if] [in], [tol(real 1e-6) *]

    local stats       total sum mean sd max min count median iqr skew kurt
    local percentiles 1 10 30 50 70 90 99

    cap drop g*_*
    cap drop c*_*

    tempvar g_fun

    if ( "`if'`in'" == "" ) {
        di _n(1) "Checking full egen range: `anything'"
    }
    else if ( "`if'`in'" != "" ) {
        di _n(1) "Checking [`if' `in'] egen range: `anything'"
    }

    foreach fun of local stats {
        timer clear
        timer on 43
        qui `noisily' gegen float `g_fun' = `fun'(random1) `if' `in', by(`anything') replace `options'
        timer off 43
        qui timer list
        local time_gegen = r(t43)

        timer clear
        timer on 42
        qui `noisily'  egen float c_`fun' = `fun'(random1) `if' `in', by(`anything')
        timer off 42
        qui timer list
        local time_egen = r(t42)

        local rs = `time_egen'  / `time_gegen'
        local tinfo `:di %4.3g `time_gegen'' vs `:di %4.3g `time_egen'', ratio `:di %4.3g `rs''

        cap noi assert (`g_fun' == c_`fun') | abs(`g_fun' - c_`fun') < `tol'
        if ( _rc ) {
            di as err "    compare_egen (failed): gegen `fun' not equal to egen (tol = `tol'; `tinfo')"
            exit _rc
        }
        else di as txt "    compare_egen (passed): gegen `fun' results similar to egen (tol = `tol'; `tinfo')"
    }

    foreach p in `percentiles' {
        timer clear
        timer on 43
        qui  `noisily' gegen float `g_fun' = pctile(random1) `if' `in', by(`anything') p(`p') replace `options'
        timer off 43
        qui timer list
        local time_gegen = r(t43)


        timer clear
        timer on 42
        qui  `noisily'  egen float c_p`p'  = pctile(random1) `if' `in', by(`anything') p(`p')
        timer off 42
        qui timer list
        local time_egen = r(t42)

        local rs = `time_egen'  / `time_gegen'
        local tinfo `:di %4.3g `time_gegen'' vs `:di %4.3g `time_egen'', ratio `:di %4.3g `rs''

        cap noi assert (`g_fun' == c_p`p') | abs(`g_fun' - c_p`p') < `tol'
        if ( _rc ) {
            di as err "    compare_egen (failed): gegen percentile `p' not equal to egen (tol = `tol'; `tinfo')"
            exit _rc
        }
        else di as txt "    compare_egen (passed): gegen percentile `p' results similar to egen (tol = `tol'; `tinfo')"
    }

    foreach fun in tag group {
        timer clear
        timer on 43
        qui  `noisily' gegen float `g_fun' = `fun'(`anything') `if' `in', replace `options'
        timer off 43
        qui timer list
        local time_gegen = r(t43)


        timer clear
        timer on 42
        qui  `noisily'  egen float c_`fun' = `fun'(`anything') `if' `in'
        timer off 42
        qui timer list
        local time_egen = r(t42)

        local rs = `time_egen'  / `time_gegen'
        local tinfo `:di %4.3g `time_gegen'' vs `:di %4.3g `time_egen'', ratio `:di %4.3g `rs''

        cap noi assert (`g_fun' == c_`fun') | abs(`g_fun' - c_`fun') < `tol'
        if ( _rc ) {
            di as err "    compare_egen (failed): gegen `fun' not equal to egen (tol = `tol'; `tinfo')"
            exit _rc
        }
        else di as txt "    compare_egen (passed): gegen `fun' results similar to egen (tol = `tol'; `tinfo')"

        timer clear
        timer on 43
        qui  `noisily' gegen float `g_fun' = `fun'(`anything') `if' `in', missing replace `options'
        timer off 43
        qui timer list
        local time_gegen = r(t43)


        timer clear
        timer on 42
        qui  `noisily'  egen float c_`fun'2 = `fun'(`anything') `if' `in', missing
        timer off 42
        qui timer list
        local time_egen = r(t42)

        local rs = `time_egen'  / `time_gegen'
        local tinfo `:di %4.3g `time_gegen'' vs `:di %4.3g `time_egen'', ratio `:di %4.3g `rs''

        cap noi assert (`g_fun' == c_`fun'2) | abs(`g_fun' - c_`fun'2) < `tol'
        if ( _rc ) {
            di as err "    compare_egen (failed): gegen `fun', missing not equal to egen (tol = `tol'; `tinfo')"
            exit _rc
        }
        else di as txt "    compare_egen (passed): gegen `fun', missing results similar to egen (tol = `tol'; `tinfo')"
    }

    {
        qui  `noisily' gegen g_g1 = group(`anything') `if' `in', counts(g_c1) fill(.) v `options' missing
        qui  `noisily' gegen g_g2 = group(`anything') `if' `in', counts(g_c2)         v `options' missing
        qui  `noisily' gegen g_c3 = count(1) `if' `in', by(`anything')
        qui  `noisily'  egen c_t1 = tag(`anything') `if' `in',  missing
        cap noi assert ( (g_c1 == g_c3) | ((c_t1 == 0) & (g_c1 == .)) ) & (g_c2 == g_c3)
        if ( _rc ) {
            di as err "    compare_egen (failed): gegen `fun' counts not equal to gegen count (tol = `tol')"
            exit _rc
        }
        else di as txt "    compare_egen (passed): gegen `fun' counts results similar to gegen count (tol = `tol')"
    }

    cap drop g_*
    cap drop c_*
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_egen
program bench_egen
    syntax, [tol(real 1e-6) bench(int 1) n(int 500) NOIsily *]

    qui gen_data, n(`n')
    qui expand `=100 * `bench''
    qui `noisily' random_draws, random(1)
    qui sort random1

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    di _n(1)
    di "Benchmark vs egen, obs = `N', J = `J' (in seconds)"
    di "     egen | fegen | gegen | ratio (e/g) | ratio (f/g) | varlist"
    di "     ---- | ----- | ----- | ----------- | ----------- | -------"

    versus_egen str_12,              `options' fegen
    versus_egen str_12 str_32,       `options' fegen
    versus_egen str_12 str_32 str_4, `options' fegen

    versus_egen double1,                 `options' fegen
    versus_egen double1 double2,         `options' fegen
    versus_egen double1 double2 double3, `options' fegen

    versus_egen int1,           `options' fegen
    versus_egen int1 int2,      `options' fegen
    versus_egen int1 int2 int3, `options' fegen

    versus_egen int1 str_32 double1,                                        `options'
    versus_egen int1 str_32 double1 int2 str_12 double2,                    `options'
    versus_egen int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    if ( `c(stata_version)' >= 14.1 ) {
        local forcestrl: disp cond(strpos(lower("`c(os)'"), "windows"), "forcestrl", "")
        versus_egen strL1,             `options' `forcestrl'
        versus_egen strL1 strL2,       `options' `forcestrl'
        versus_egen strL1 strL2 strL3, `options' `forcestrl'
    }

    di _n(1) "{hline 80}" _n(1) "bench_egen, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop versus_egen
program versus_egen, rclass
    syntax varlist, [fegen *]

    preserve
        timer clear
        timer on 42
        cap egen id = group(`varlist')
        timer off 42
        qui timer list
        local time_egen = r(t42)
    restore

    preserve
        timer clear
        timer on 43
        cap gegen id = group(`varlist'), `options'
        timer off 43
        qui timer list
        local time_gegen = r(t43)
    restore

    if ( "`fegen'" == "fegen" ) {
    preserve
        timer clear
        timer on 44
        cap fegen id = group(`varlist')
        timer off 44
        qui timer list
        local time_fegen = r(t44)
    restore
    }
    else {
        local time_fegen = .
    }

    local rs = `time_egen'  / `time_gegen'
    local rf = `time_fegen' / `time_gegen'
    di "    `:di %5.3g `time_egen'' | `:di %5.3g `time_fegen'' | `:di %5.3g `time_gegen'' | `:di %11.3g `rs'' | `:di %11.3g `rf'' | `varlist'"
end
