capture program drop checks_gstats
program checks_gstats
    checks_gstats_winsor
    checks_gstats_summarize
end

capture program drop compare_gstats
program compare_gstats
    compare_gstats_winsor
    compare_gstats_winsor, cuts(5 95)
    compare_gstats_winsor, cuts(30 70)
end

***********************************************************************
*                          Compare summarize                          *
***********************************************************************

capture program drop checks_gstats_summarize
program checks_gstats_summarize
    clear
    set obs 10
    gen x = string(_n) + "some"
    gen y = mod(_n, 3)
    gen w = string(mod(_n, 4)) + "Other That is Long"
    gen v = -mod(_n, 7)
    gen z = runiform()
    gen z2 = rnormal()
    if ( `c(stata_version)' >= 14.1 ) {
    gen strL L = "This one is strL and what will hapennnnn!!!???" + string(mod(_n, 4))
    }
    else {
    gen L = "This one is strL and what will hapennnnn!!!???" + string(mod(_n, 4))
    }
    gen a = "hey"
    replace a = "" in 3 / 6
    replace a = " " in 7 / 10

    gstats tab z
    gstats tab z y
    gstats tab z,   matasave
    mata: GstatsOutput.desc()
    gstats tab z y, matasave
    mata: GstatsOutput.desc()
    gstats tab z y, matasave by(x)
    mata: GstatsOutput.desc()
    mata: GstatsOutput.help()

    gstats tab z, by(y x) s(mean sd min max) matasave pretty
    mata GstatsOutput.printOutput()
    mata GstatsOutput.getf(1, 2, GstatsOutput.maxl)
    mata GstatsOutput.getnum(1, 1)
    mata GstatsOutput.getchar(1, 2)
    cap noi mata assert(.  == GstatsOutput.getnum(1, 2))
    cap noi mata assert("" == GstatsOutput.getchar(1, 1))
    mata GstatsOutput.getOutputRow(1)
    mata GstatsOutput.getOutputRow(5)
    cap mata GstatsOutput.getOutputRow(999)
    assert _rc == 3301
    mata GstatsOutput.getOutputCol(1)
    mata GstatsOutput.getOutputCol(4)
    cap mata GstatsOutput.getOutputCol(999)
    assert _rc == 3301
    mata GstatsOutput.getOutputVar("z")
    cap noi mata assert(J(1, 0, .) == GstatsOutput.getOutputVar("x"))
    mata GstatsOutput.getOutputGroup(1)
    mata GstatsOutput.getOutputGroup(5)
    cap mata GstatsOutput.getOutputGroup(999)
    assert _rc == 3301

    gstats tab z* , by(a x)       s(mean sd min max) pretty
    gstats tab z  , by(w y v x L) s(mean sd min max) col(var)
    gstats tab z  , by(L)         s(mean sd min max) col(var)
    gstats tab z  , by(L x)       s(mean sd min max) col(var)


    gstats tab z  , by(x)         s(mean sd min max) matasave pretty
    gstats tab z  , by(a x)       s(mean sd min max) matasave pretty
    gstats tab z  , by(y)         s(mean sd min max) matasave
    gstats tab z  , by(x y)       s(mean sd min max) matasave
    gstats tab z  , by(x v y w)   s(mean sd min max) matasave
    gstats tab z  , by(w y v x)   s(mean sd min max) matasave pretty
    gstats tab z  , by(w y v x L) s(mean sd min max) matasave pretty labelw(100)

    qui _checks_gstats_summarize
    qui _checks_gstats_summarize, pool
    qui _checks_gstats_summarize [fw = mpg]
    qui _checks_gstats_summarize [aw = gear_ratio]
    qui _checks_gstats_summarize [pw = gear_ratio / 4]
    qui _checks_gstats_summarize if foreign
    qui _checks_gstats_summarize if foreign, pool
    qui _checks_gstats_summarize if foreign [fw = mpg]
    qui _checks_gstats_summarize if foreign [aw = gear_ratio]
    qui _checks_gstats_summarize if foreign [pw = gear_ratio / 4]
    qui _checks_gstats_summarize in 23
    qui _checks_gstats_summarize in 1 / 2
    qui _checks_gstats_summarize in 23, pool
    qui _checks_gstats_summarize in 1 / 2, pool
    qui _checks_gstats_summarize in 1 / 2 [fw = mpg]
    qui _checks_gstats_summarize in 1 / 2 [aw = gear_ratio]
    qui _checks_gstats_summarize in 1 / 2 [pw = gear_ratio / 4]
end

capture program drop _checks_gstats_summarize
program _checks_gstats_summarize
    if ( strpos(`"`0'"', ",") == 0 ) {
        local 0 `0',
    }
    sysuse auto, clear
    gstats sum price       `0'
    gstats sum price       `0' f
    gstats sum price       `0' nod
    gstats sum price       `0' nod f
    gstats sum price       `0' meanonly
    gstats sum price mpg   `0'
    gstats sum *           `0'
    gstats sum price price `0'
    gstats sum price mpg * `0' nod
    gstats sum price mpg * `0' nod f

    gstats sum price       , tab
    gstats sum price       , tab f
    gstats sum price       , tab nod
    gstats sum price       , tab nod f
    gstats sum price       , tab meanonly
    gstats sum price mpg   , tab
    gstats sum *           , tab
    gstats sum price price , tab
    gstats sum price mpg * , tab nod
    gstats sum price mpg * , tab nod f

    cap noi gstats tab price       , statistics(n) stats(n)
    assert _rc == 198
    cap noi gstats tab price       , nod
    assert _rc == 198
    cap noi gstats tab *
    assert _rc == 7
    cap noi gstats tab price       , meanonly
    assert _rc == 198

    gstats tab price       ,
    gstats tab price       , s(mean sd min max)
    gstats tab price       , statistics(count n nmissing percent nunique)
    gstats tab price       , stats(rawsum nansum rawnansum median p32.4 p50 p99)
    gstats tab price       , stat(iqr q median sd variance cv)
    gstats tab price       ,
    gstats tab price       , stat(min max range select2 select10 select-4 select-9)
    cap gstats tab price   , stat(select0)
    assert _rc == 110
    cap gstats tab price   , stat(select-0)
    assert _rc == 110
    gstats tab price       , stat(first last firstnm lastnm semean sebinomial sepoisson)
    gstats tab price mpg   , stat(skewness kurtosis)
    gstats tab price price , stat()

    gstats sum price `0' tab
    gstats sum price `0' tab pretty
    gstats sum price `0' tab nod
    gstats sum price `0' tab meanonly
    gstats sum price `0' by(foreign) tab
    gstats sum price `0' by(foreign) tab pretty
    gstats sum price `0' by(foreign) tab nod
    gstats sum price `0' by(foreign) tab meanonly pretty
    gstats sum price `0' by(rep78)   tab
    gstats sum price `0' by(rep78)   tab nod
    gstats sum price `0' by(rep78)   tab meanonly

    gstats sum price `0' col(stat) tab
    gstats sum price `0' col(var)  tab nod
    gstats sum price `0' col(var)  tab meanonly
    gstats sum price `0' by(foreign)  col(stat) tab
    gstats sum price `0' by(foreign)  col(var)  tab nod
    gstats sum price `0' by(foreign)  col(var)  tab meanonly
    gstats sum price `0' by(rep78)    col(stat) tab
    gstats sum price `0' by(rep78)    col(var)  tab nod
    gstats sum price `0' by(rep78)    col(var)  tab meanonly

    gstats tab price         `0' col(var) s(mean sd min max)
    gstats tabstat price     `0' col(var) s(mean sd min max) by(foreign)
    gstats tabstat price mpg `0' col(var) s(mean sd min max) by(foreign)
    gstats tabstat price     `0' col(var) s(mean sd min max) by(rep78)
    gstats tabstat price mpg `0' col(var) s(mean sd min max) by(rep78)
    gstats tabstat price mpg `0' col(var) s(mean sd min max) by(rep78)

    gstats tab price         `0' s(mean sd min max)
    gstats tabstat price     `0' s(mean sd min max) by(foreign)
    gstats tabstat price mpg `0' s(mean sd min max) by(foreign)
    gstats tabstat price     `0' s(mean sd min max) by(rep78)
    gstats tabstat price mpg `0' s(mean sd min max) by(rep78)
    gstats tabstat price mpg `0' s(mean sd min max) by(rep78)

    gstats tab price         `0'
    gstats tab price         `0' pretty
    gstats tabstat price     `0' by(foreign)
    gstats tabstat price mpg `0' by(foreign)
    gstats tabstat price     `0' by(rep78)
    gstats tabstat price mpg `0' by(rep78)
    gstats tabstat price mpg `0' by(rep78)

    gstats tab price         `0' col(var)
    gstats tabstat price     `0' col(var) by(foreign)
    gstats tabstat price mpg `0' col(var) by(foreign)
    gstats tabstat price     `0' col(var) by(rep78)
    gstats tabstat price mpg `0' col(var) by(rep78)
    gstats tabstat price mpg `0' col(var) by(rep78)
end

***********************************************************************
*                           Compare winsor                            *
***********************************************************************

capture program drop checks_gstats_winsor
program checks_gstats_winsor
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
