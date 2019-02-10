capture program drop checks_gstats
program checks_gstats
    * TODO: Pending
    sysuse auto, clear

    cap noi gstats winsor price, by(foreign) cuts(10)
    cap noi gstats winsor price, by(foreign) cuts(90)
    cap noi gstats winsor price, by(foreign) cuts(. 90)
    cap noi gstats winsor price, by(foreign) cuts(10 .)
    cap noi gstats winsor price, by(foreign) cuts(-1 10)
    cap noi gstats winsor price, by(foreign) cuts(10 101)
    preserve
        cap noi gstats winsor price, by(foreign) cuts(0 10) gen(x)
        cap noi gstats winsor price, by(foreign) cuts(10 100) gen(y)
        cap noi gstats winsor price, by(foreign) cuts(100 100) gen(zz)
        cap noi gstats winsor price, by(foreign) cuts(0 0) gen(yy)
    restore
    gstats winsor price, by(foreign)
    winsor2 price, by(foreign) replace

    winsor2 price mpg, by(foreign) cuts(10 90) s(_w2)
    gstats winsor price mpg, by(foreign) cuts(10 90) s(_w2) replace
    desc

    * gtools, upgrade branch(develop)
    clear
    set obs 500000
    gen long id = int((_n-1) / 1000)
    gunique id
    gen double x = runiform()
    gen double y = runiform()
    set rmsg on
    winsor2 x y, by(id) s(_w1)
    gstats winsor x y, by(id) s(_w2)
    desc
    assert abs(x_w1 - x_w2) < 1e-6
    assert abs(y_w1 - y_w2) < 1e-6

    replace y = . if mod(_n, 123) == 0
    replace x = . if mod(_n, 321) == 0
    gstats winsor x [w=y], by(id) s(_w3)
    gstats winsor x [w=y], by(id) s(_w5) trim
    gegen p1  = pctile(x) [aw = y], by(id) p(1)
    gegen p99 = pctile(x) [aw = y], by(id) p(99)
    gen x_w4 = cond(x < p1, p1, cond(x > p99, p99, x))
    assert (abs(x_w3 - x_w4) < 1e-6 | mi(x_w3 - x_w4))
end

capture program drop compare_gstats
program compare_gstats
    compare_gstats_winsor
    compare_gstats_winsor, cuts(5 95)
    compare_gstats_winsor, cuts(30 70)
end

***********************************************************************
*                           Compare winsor                            *
***********************************************************************

capture program drop compare_gstats_winsor
program compare_gstats_winsor
    syntax, [*]
    qui `noisily' gen_data, n(500)
    qui expand 100
    qui `noisily' random_draws, random(2) double
    gen long   ix = _n
    gen double ru = runiform() * 500
    qui replace ix = . if mod(_n, 500) == 0
    qui replace ru = . if mod(_n, 500) == 0
    qui sort random1

    local N = trim("`: di %15.0gc _N'")
    di _n(1) "{hline 80}" _n(1) "compare_gstats_winsor, N = `N', `options'" _n(1) "{hline 80}" _n(1)

    compare_inner_gstats_winsor, `options'
    disp

    compare_inner_gstats_winsor in 1 / 5, `options'
    disp

    local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
    local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
    local from = cond(`in1' < `in2', `in1', `in2')
    local to   = cond(`in1' > `in2', `in1', `in2')
    compare_inner_gstats_winsor in `from' / `to', `options'
    disp

    compare_inner_gstats_winsor if random2 > 0, `options'
    disp

    local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
    local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
    local from = cond(`in1' < `in2', `in1', `in2')
    local to   = cond(`in1' > `in2', `in1', `in2')
    compare_inner_gstats_winsor if random2 < 0 in `from' / `to', `options'
    disp
end

capture program drop compare_inner_gstats_winsor
program compare_inner_gstats_winsor
    syntax [if] [in], [*]
    compare_fail_gstats_winsor versus_gstats_winsor `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor `if' `in', `options' trim

    compare_fail_gstats_winsor versus_gstats_winsor str_12              `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor str_12              `if' `in', `options' trim
    compare_fail_gstats_winsor versus_gstats_winsor str_12 str_32 str_4 `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor str_12 str_32 str_4 `if' `in', `options' trim

    compare_fail_gstats_winsor versus_gstats_winsor double1                 `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor double1                 `if' `in', `options' trim
    compare_fail_gstats_winsor versus_gstats_winsor double1 double2 double3 `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor double1 double2 double3 `if' `in', `options' trim

    compare_fail_gstats_winsor versus_gstats_winsor int1           `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor int1           `if' `in', `options' trim
    compare_fail_gstats_winsor versus_gstats_winsor int1 int2      `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor int1 int2      `if' `in', `options' trim
    compare_fail_gstats_winsor versus_gstats_winsor int1 int2 int3 `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor int1 int2 int3 `if' `in', `options' trim

    compare_fail_gstats_winsor versus_gstats_winsor str_32 int3 double3  `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor str_32 int3 double3  `if' `in', `options' trim
    compare_fail_gstats_winsor versus_gstats_winsor int1 double2 double3 `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor int1 double2 double3 `if' `in', `options' trim
    compare_fail_gstats_winsor versus_gstats_winsor double? str_* int?   `if' `in', `options'
    compare_fail_gstats_winsor versus_gstats_winsor double? str_* int?   `if' `in', `options' trim
end

capture program drop compare_fail_gstats_winsor
program compare_fail_gstats_winsor
    gettoken cmd 0: 0
    syntax [anything] [if] [in], [tol(real 1e-6) *]
    cap `cmd' `0'
    if ( _rc ) {
        if ( "`if'`in'" == "" ) {
            di "    compare_gstats_winsor (failed): full range, `anything'; `options'"
        }
        else if ( "`if'`in'" != "" ) {
            di "    compare_gstats_winsor (failed): [`if'`in'], `anything'; `options'"
        }
        exit _rc
    }
    else {
        if ( "`if'`in'" == "" ) {
            di "    compare_gstats_winsor (passed): full range, gstats results equal to winsor2 (tol = `tol'; `anything'; `options')"
        }
        else if ( "`if'`in'" != "" ) {
            di "    compare_gstats_winsor (passed): [`if'`in'], gstats results equal to winsor2 (tol = `tol'; `anything'; `options')"
        }
    }
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

* di as txt _n(1)
* di as txt "Benchmark vs Summary, detail; obs = `N', J = `J' (in seconds)"
* di as txt "    sum, d | gstats sum, d | ratio (c/g) | varlist"
* di as txt "    ------ | ------------- | ----------- | -------"
* di as txt "           |               |             | int1
* di as txt "           |               |             | int2
* di as txt "           |               |             | int3
* di as txt "           |               |             | double1
* di as txt "           |               |             | double2
* di as txt "           |               |             | double3
* di as txt "           |               |             | int1 int2 int3 double1 double2 double3

capture program drop bench_gstats
program bench_gstats
    bench_gstats_winsor
end

capture program drop bench_gstats_winsor
program bench_gstats_winsor
    syntax, [tol(real 1e-6) bench(real 1) n(int 500) NOIsily *]

    qui gen_data, n(`n')
    qui expand `=100 * `bench''
    qui `noisily' random_draws, random(2) double
    qui hashsort random1

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    di as txt _n(1)
    di as txt "Benchmark vs winsor2, obs = `N', J = `J' (in seconds)"
    di as txt "    winsor | gstats winsor | ratio (c/g) | varlist"
    di as txt "    ------ | ------------- | ----------- | -------"

    versus_gstats_winsor, `options'

    versus_gstats_winsor str_12,              `options'
    versus_gstats_winsor str_12 str_32 str_4, `options'

    versus_gstats_winsor double1,                 `options'
    versus_gstats_winsor double1 double2 double3, `options'

    versus_gstats_winsor int1,           `options'
    versus_gstats_winsor int1 int2,      `options'
    versus_gstats_winsor int1 int2 int3, `options'

    versus_gstats_winsor str_32 int3 double3,  `options'
    versus_gstats_winsor int1 double2 double3, `options'

    di _n(1) "{hline 80}" _n(1) "bench_gstats_winsor, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop versus_gstats_winsor
program versus_gstats_winsor, rclass
    syntax [anything] [if] [in], [tol(real 1e-6) trim *]

    timer clear
    timer on 42
    qui winsor2 random2 `if' `in', by(`anything') s(_w1) `options' `trim'
    timer off 42
    qui timer list
    local time_winsor = r(t42)

    timer clear
    timer on 43
    qui gstats winsor random2 `if' `in', by(`anything') s(_w2) `options' `trim'
    timer off 43
    qui timer list
    local time_gwinsor = r(t43)

    cap assert (abs(random2_w1 - random2_w2) < `tol' | random2_w1 == random2_w2)
    if ( _rc & ("`trim'" != "") ) {
        disp as err "(warning: `r(N)' indiscrepancies might be due to a numerical precision bug in winsor2)"
    }
    else if ( _rc ) {
        exit _rc
    }
    qui drop random2_w*

    local rs = `time_winsor'  / `time_gwinsor'
    di as txt "    `:di %6.3g `time_winsor'' | `:di %13.3g `time_gwinsor'' | `:di %11.4g `rs'' | `anything'"
end
