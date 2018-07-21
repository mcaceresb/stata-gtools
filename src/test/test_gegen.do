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

    if ( `c(stata_version)' >= 14 ) {
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
    if ( `c(stata_version)' < 14 ) {
        assert _rc == 17002
    }
    else {
        assert _rc == 17005
    }
end

capture program drop checks_inner_egen
program checks_inner_egen
    syntax [anything], [tol(real 1e-6) wgt(str) *]

    local 0 `anything' `wgt', `options'
    syntax [anything] [aw fw iw pw], [*]

    local percentiles 1 10 30.5 50 70.5 90 99
    local stats nunique total sum mean max min count median iqr percent first last firstnm lastnm skew kurt
    if ( !inlist("`weight'", "pweight") )            local stats `stats' sd
    if ( !inlist("`weight'", "pweight", "iweight") ) local stats `stats' semean
    if (  inlist("`weight'", "fweight", "") )        local stats `stats' sebinomial sepoisson

    tempvar gvar
    foreach fun of local stats {
        `noisily' gegen `gvar' = `fun'(random1) `wgt', by(`anything') replace `options'
        if ( "`weight'" == "" ) {
        `noisily' gegen `gvar' = `fun'(random*) `wgt', by(`anything') replace `options'
        }
    }

    foreach p in `percentiles' {
        `noisily' gegen `gvar' = pctile(random1) `wgt', p(`p') by(`anything') replace `options'
        if ( "`weight'" == "" ) {
        `noisily' gegen `gvar' = pctile(random*) `wgt', p(`p') by(`anything') replace `options'
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

    qui `noisily' gen_data, n(1000)
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

    if ( `c(stata_version)' >= 14 ) {
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
    if ( ("`sort'" != "") & ("`anything'" != "") ) hashsort `anything'

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
    syntax, [tol(real 1e-6) bench(int 1) n(int 1000) NOIsily *]

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

    if ( `c(stata_version)' >= 14 ) {
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
