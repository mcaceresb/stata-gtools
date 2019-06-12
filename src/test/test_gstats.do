capture program drop checks_gstats
program checks_gstats
    checks_gstats_winsor
    checks_gstats_summarize
    checks_gstats_transform
    checks_gstats_transform nogreedy
end

capture program drop compare_gstats
program compare_gstats
    compare_gstats_winsor
    compare_gstats_winsor, cuts(5 95)
    compare_gstats_winsor, cuts(30 70)

    compare_gstats_transform
    compare_gstats_transform, weights
    compare_gstats_transform, nogreedy
    compare_gstats_transform, nogreedy weights
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
    gstats tab price       , stat(iqr q median sd variance cv geomean)
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
    gegen x_g3 = winsor(x), by(id)
    gegen y_g3 = winsor(y), by(id)

    desc
    assert abs(x_w1 - x_w2) < 1e-6
    assert abs(y_w1 - y_w2) < 1e-6
    assert abs(x_g3 - x_w2) < 1e-6
    assert abs(y_g3 - y_w2) < 1e-6

    replace y = . if mod(_n, 123) == 0
    replace x = . if mod(_n, 321) == 0

    gstats winsor x [w=y], by(id) s(_w3)
    gstats winsor x [w=y], by(id) s(_w5) trim

    gegen x_g4 = winsor(x) [w=y], by(id)
    gegen x_g5 = winsor(x) [w=y], by(id) trim

    gegen p1  = pctile(x) [aw = y], by(id) p(1)
    gegen p99 = pctile(x) [aw = y], by(id) p(99)

    gen x_w4 = cond(x < p1, p1, cond(x > p99, p99, x))

    assert (abs(x_w3 - x_w4) < 1e-6 | mi(x_w3 - x_w4))
    assert (abs(x_g4 - x_w3) < 1e-6 | mi(x_g4 - x_w3))
    assert (abs(x_g5 - x_w5) < 1e-6 | mi(x_g5 - x_w5))
end

capture program drop compare_gstats_winsor
program compare_gstats_winsor
    syntax, [*]

    qui `noisily' gen_data, n(500)
    qui expand 100
    qui `noisily' random_draws, random(2) double
    gen long   ix  = _n
    gen double ru  = runiform() * 500
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
*                          Compare transform                          *
***********************************************************************

capture program drop checks_gstats_transform
program checks_gstats_transform

    local percentiles p1 p10 p30.5 p50 p70.5 p90 p99
    local selections  select1 select2 select5 select-5 select-2 select-1
    local stats       nmissing sum mean geomean cv sd variance max min range count first last firstnm lastnm median iqr skew kurt

    *********************************
    *  Basic check transform stats  *
    *********************************

    sysuse auto, clear
    gstats transform (normalize) p1 = price p2 = price (demean) p3 = price (moving first) p4 = price, by(foreign) nogreedy

    clear
    set obs 10
    gen long x1 = _n
    gen long x2 = -_n
    gstats transform x1 = x2 x2 = x1, replace `0'
    assert x1 != .
    assert x2 != .
    gstats transform x1, replace `0'
    assert x1 != .
    gstats transform x1 x2, replace `0'
    assert x2 != .

    clear
    set obs 10
    gen long x1 = _n
    gen long x2 = -_n
    gstats transform x1 x2 (normalize) x1 x2, autorename replace `0'

    ******************
    *  Moving stats  *
    ******************

    foreach by in foreign mpg {
        disp "`by'"
        foreach stat in `stats' `selections' `percentiles' {
            disp "    `stat'"
            qui sysuse auto, clear
            qui replace mpg = . if mod(_n, 19) == 0
            qui {
                gstats transform (moving `stat' -3  -1) x1 = price, by(`by') `0'
                gstats transform (moving `stat'  4  2)  x2 = price, by(`by') `0'
                gstats transform (moving `stat'  3  6)  x3 = price, by(`by') `0'
                gstats transform (moving `stat'  -3 6)  x4 = price, by(`by') `0'
            }

            local r1 moving `stat' -3 -1
            local r2 moving `stat' -3 6
            local r3 moving `stat' -3 .
            local r4 moving `stat'
            local call (`r1') x5 = price (`r2') x6 = price (`r3') x7 = price (`r4') x8 = price

            qui {
                gstats transform `call' , by(`by') replace window(-4 4) `0'
                gstats transform `call' , by(`by') replace window( 4 8) `0'
                gstats transform `call' , by(`by') replace window( 8 3) `0'
                gstats transform `call' , by(`by') replace window(-4 .) `0'
                gstats transform `call' , by(`by') replace window( . 4) `0'
                gstats transform `call' , by(`by') replace window( . .) `0'

                gstats transform `call' [ w = gear_ratio * 10]      , by(`by') replace window(-4 4) `0'
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace window( 4 8) `0'
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace window( 9 2) `0'
                gstats transform `call' [fw = int(gear_ratio * 10)] , by(`by') replace window(-4 .) `0'
                gstats transform `call' [iw = gear_ratio / 10]      , by(`by') replace window( . 4) `0'
                gstats transform `call' [pw = gear_ratio / 10]      , by(`by') replace window( . .) `0'
            }
        }
    }

    *****************
    *  Range stats  *
    *****************

    foreach by in foreign mpg {
        disp "`by' (main)"
        qui sysuse auto, clear
        qui keep if mod(_n, 3) == 0
        qui replace mpg = . if mod(_n, 19) == 0
        local sl: copy local stat
        local ul: copy local stat

        foreach stat in `stats' `selections' `percentiles' {
            disp "    `stat'"

            local s1  ( range `stat'   -3      5.5      gear_ratio ) p1  = price       // g1  = weight
            local s2  ( range `stat'   -3     -1        mpg        ) p2  = price       // g2  = weight
            local s3  ( range `stat' 7.33      3        length     ) p3  = gear_ratio  // g3  = weight
            local s4  ( range `stat'   -3      5.5                 ) p4  = gear_ratio  // g4  = weight
            local s5  ( range `stat'   -3     -1                   ) p5  = gear_ratio  // g5  = weight
            local s6  ( range `stat'    2      6.25     turn       ) p6  = gear_ratio  // g6  = weight
            local s7  ( range `stat'   -3      .        turn       ) p7  = gear_ratio  // g7  = weight
            local s8  ( range `stat'    .      3        gear_ratio ) p8  = gear_ratio  // g8  = weight
            local s9  ( range `stat'    .     -3        gear_ratio ) p9  = price       // g9  = weight
            local s10 ( range `stat' 7.33      3                   ) p10 = price       // g10 = weight
            local s11 ( range `stat'    2      6.25                ) p11 = price       // g11 = weight
            local s12 ( range `stat'   -3      .                   ) p12 = gear_ratio  // g12 = weight
            local s13 ( range `stat'    .      3                   ) p13 = gear_ratio  // g13 = weight
            local s14 ( range `stat'    .     -3                   ) p14 = price       // g14 = weight
            local s15 ( range `stat'    3      .        gear_ratio ) p15 = price       // g15 = weight
            local s16 ( range `stat'                               ) p16 = price       // g16 = weight

            local call
            forvalues i = 1 / 16 {
                local call `call' `s`i''
            }

            qui {
                gstats transform `call' , by(`by') replace interval(-4 4) `0'
                gstats transform `call' , by(`by') replace interval( 4 8) `0'
                gstats transform `call' , by(`by') replace interval( 8 3) `0'
                gstats transform `call' , by(`by') replace interval(-4 .) `0'
                gstats transform `call' , by(`by') replace interval( . 4) `0'
                gstats transform `call' , by(`by') replace interval( . .) `0'
            }

            qui {
                gstats transform `call' [ w = gear_ratio * 10]      , by(`by') replace interval(-4 4) `0'
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 4 8) `0'
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 9 2) `0'
                gstats transform `call' [fw = int(gear_ratio * 10)] , by(`by') replace interval(-4 .) `0'
                gstats transform `call' [iw = gear_ratio / 10]      , by(`by') replace interval( . 4) `0'
                gstats transform `call' [pw = gear_ratio / 10]      , by(`by') replace interval( . .) `0'
            }

            qui {
                gstats transform `call' , by(`by') replace interval(-4 4) `0' excludeself
                gstats transform `call' , by(`by') replace interval( 4 8) `0' excludeself
                gstats transform `call' , by(`by') replace interval( 8 3) `0' excludeself
                gstats transform `call' , by(`by') replace interval(-4 .) `0' excludeself
                gstats transform `call' , by(`by') replace interval( . 4) `0' excludeself
                gstats transform `call' , by(`by') replace interval( . .) `0' excludeself
            }

            qui {
                gstats transform `call' [ w = gear_ratio * 10]      , by(`by') replace interval(-4 4) `0' excludeself
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 4 8) `0' excludeself
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 9 2) `0' excludeself
                gstats transform `call' [fw = int(gear_ratio * 10)] , by(`by') replace interval(-4 .) `0' excludeself
                gstats transform `call' [iw = gear_ratio / 10]      , by(`by') replace interval( . 4) `0' excludeself
                gstats transform `call' [pw = gear_ratio / 10]      , by(`by') replace interval( . .) `0' excludeself
            }

            qui {
                gstats transform `call' , by(`by') replace interval(-4 4) `0' excludebounds
                gstats transform `call' , by(`by') replace interval( 4 8) `0' excludebounds
                gstats transform `call' , by(`by') replace interval( 8 3) `0' excludebounds
                gstats transform `call' , by(`by') replace interval(-4 .) `0' excludebounds
                gstats transform `call' , by(`by') replace interval( . 4) `0' excludebounds
                gstats transform `call' , by(`by') replace interval( . .) `0' excludebounds
            }

            qui {
                gstats transform `call' [ w = gear_ratio * 10]      , by(`by') replace interval(-4 4) `0' excludebounds
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 4 8) `0' excludebounds
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 9 2) `0' excludebounds
                gstats transform `call' [fw = int(gear_ratio * 10)] , by(`by') replace interval(-4 .) `0' excludebounds
                gstats transform `call' [iw = gear_ratio / 10]      , by(`by') replace interval( . 4) `0' excludebounds
                gstats transform `call' [pw = gear_ratio / 10]      , by(`by') replace interval( . .) `0' excludebounds
            }
        }

        disp "`by' (combo)"
        qui sysuse auto, clear
        qui keep if mod(_n, 3) == 0
        qui replace mpg = . if mod(_n, 19) == 0
        local sl: copy local stat
        local ul: copy local stat

        foreach stat in `stats' `selections' `percentiles' {
            disp "    `stat'"

            local s1  ( range mean       -3`sl'  5.5`ul'  gear_ratio ) p1  = price       // g1  = weight
            local s2  ( range mean        3      .                   ) p2  = price       // g2  = weight
            local s3  ( range nmissing   -3`sl'  5.5`ul'             ) p3  = gear_ratio  // g3  = weight
            local s4  ( range sum        -3`sl' -1`ul'               ) p4  = gear_ratio  // g4  = weight
            local s5  ( range mean     7.33`sl'  3`ul'               ) p5  = gear_ratio  // g5  = weight
            local s6  ( range geomean     2`sl'  6.25`ul'            ) p6  = gear_ratio  // g6  = weight
            local s7  ( range cv         -3`sl'  .                   ) p7  = gear_ratio  // g7  = weight
            local s8  ( range sd          .      3`ul'               ) p8  = gear_ratio  // g8  = weight
            local s9  ( range variance   -3`sl' -1`ul'    length     ) p9  = gear_ratio  // g9  = weight
            local s10 ( range max      7.33`sl'  3`ul'    length     ) p10 = price       // g10 = weight
            local s11 ( range min         .     -3`ul'               ) p11 = price       // g11 = weight
            local s12 ( range range       2`sl'  6.25`ul' gear_ratio ) p12 = price       // g12 = weight
            local s13 ( range count       3      .                   ) p13 = price       // g13 = weight
            local s14 ( range first      -3`sl'  .        gear_ratio ) p14 = price       // g14 = weight
            local s15 ( range last        .      3`ul'    mpg        ) p15 = price       // g15 = weight
            local s16 ( range mean        .     -3`ul'    mpg        ) p16 = price       // g16 = weight
            local s17 ( range firstnm    -3`sl'  5.5                 ) p17 = price       // g17 = weight
            local s18 ( range lastnm      3      .        mpg        ) p18 = price       // g18 = weight
            local s19 ( range median     -3`sl'  5.5      gear_ratio ) p19 = price       // g19 = weight
            local s20 ( range iqr        -3     -1`ul'               ) p20 = price       // g20 = weight
            local s21 ( range skew       -3     -1`ul'    gear_ratio ) p21 = price       // g21 = weight
            local s22 ( range kurt                                   ) p22 = price       // g22 = weight

            local call
            forvalues i = 1 / 22 {
                local call `call' `s`i''
            }

            qui {
                gstats transform `call' , by(`by') replace interval(-4 4) `0'
                gstats transform `call' , by(`by') replace interval( 4 8) `0'
                gstats transform `call' , by(`by') replace interval( 8 3) `0'
                gstats transform `call' , by(`by') replace interval(-4 .) `0'
                gstats transform `call' , by(`by') replace interval( . 4) `0'
                gstats transform `call' , by(`by') replace interval( . .) `0'
            }

            qui {
                gstats transform `call' [ w = gear_ratio * 10]      , by(`by') replace interval(-4 4) `0'
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 4 8) `0'
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 9 2) `0'
                gstats transform `call' [fw = int(gear_ratio * 10)] , by(`by') replace interval(-4 .) `0'
                gstats transform `call' [iw = gear_ratio / 10]      , by(`by') replace interval( . 4) `0'
                gstats transform `call' [pw = gear_ratio / 10]      , by(`by') replace interval( . .) `0'
            }

            qui {
                gstats transform `call' , by(`by') replace interval(-4 4) `0' excludeself
                gstats transform `call' , by(`by') replace interval( 4 8) `0' excludeself
                gstats transform `call' , by(`by') replace interval( 8 3) `0' excludeself
                gstats transform `call' , by(`by') replace interval(-4 .) `0' excludeself
                gstats transform `call' , by(`by') replace interval( . 4) `0' excludeself
                gstats transform `call' , by(`by') replace interval( . .) `0' excludeself
            }

            qui {
                gstats transform `call' [ w = gear_ratio * 10]      , by(`by') replace interval(-4 4) `0' excludeself
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 4 8) `0' excludeself
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 9 2) `0' excludeself
                gstats transform `call' [fw = int(gear_ratio * 10)] , by(`by') replace interval(-4 .) `0' excludeself
                gstats transform `call' [iw = gear_ratio / 10]      , by(`by') replace interval( . 4) `0' excludeself
                gstats transform `call' [pw = gear_ratio / 10]      , by(`by') replace interval( . .) `0' excludeself
            }

            qui {
                gstats transform `call' , by(`by') replace interval(-4 4) `0' excludebounds
                gstats transform `call' , by(`by') replace interval( 4 8) `0' excludebounds
                gstats transform `call' , by(`by') replace interval( 8 3) `0' excludebounds
                gstats transform `call' , by(`by') replace interval(-4 .) `0' excludebounds
                gstats transform `call' , by(`by') replace interval( . 4) `0' excludebounds
                gstats transform `call' , by(`by') replace interval( . .) `0' excludebounds
            }

            qui {
                gstats transform `call' [ w = gear_ratio * 10]      , by(`by') replace interval(-4 4) `0' excludebounds
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 4 8) `0' excludebounds
                gstats transform `call' [aw = gear_ratio * 10]      , by(`by') replace interval( 9 2) `0' excludebounds
                gstats transform `call' [fw = int(gear_ratio * 10)] , by(`by') replace interval(-4 .) `0' excludebounds
                gstats transform `call' [iw = gear_ratio / 10]      , by(`by') replace interval( . 4) `0' excludebounds
                gstats transform `call' [pw = gear_ratio / 10]      , by(`by') replace interval( . .) `0' excludebounds
            }
        }
    }

    *******************
    *  Non-moving by  *
    *******************

    foreach by in foreign rep78 mpg {
        sysuse auto, clear

        gegen _m1 = mean(price),   by(`by')
        gegen _s1 = sd(price),     by(`by')
        gegen _d1 = median(price), by(`by')
        gen   _x1 = (price - _m1) / _s1
        gen   _x3 = (price - _m1)
        gen   _x4 = (price - _d1)

        gegen x1 = normalize(price),   by(`by') `0' labelf(#stat:pretty# #sourcelabel#) replace
        gegen x2 = standardize(price), by(`by') `0'
        gegen x3 = demean(price),      by(`by') `0'
        gegen x4 = demedian(price),    by(`by') `0'

        gen diff1 = abs(x1 - _x1) / max(min(abs(x1), abs(_x1)), 1)
        gen diff2 = abs(x2 - _x1) / max(min(abs(x2), abs(_x1)), 1)
        gen diff3 = abs(x3 - _x3) / max(min(abs(x3), abs(_x3)), 1)
        gen diff4 = abs(x4 - _x4) / max(min(abs(x4), abs(_x4)), 1)

        assert (diff1 < 1e-3) | mi(diff1)
        assert (diff2 < 1e-3) | mi(diff2)
        assert (diff3 < 1e-3) | mi(diff3)
        assert (diff4 < 1e-3) | mi(diff4)
    }

    foreach by in foreign rep78 mpg {
        sysuse auto, clear

        gegen _m1 = mean(price)   [aw = gear_ratio * 10], by(`by')
        gegen _s1 = sd(price)     [aw = gear_ratio * 10], by(`by')
        gegen _d1 = median(price) [pw = gear_ratio / 10], by(`by')
        gen   _x1 = (price - _m1) / _s1
        gen   _x3 = (price - _m1)
        gen   _x4 = (price - _d1)

        gegen x1 = normalize(price)   [aw = gear_ratio * 10], by(`by') `0' labelf(#stat:pretty# #sourcelabel#) replace
        gegen x2 = standardize(price) [aw = gear_ratio * 10], by(`by') `0'
        gegen x3 = demean(price)      [aw = gear_ratio * 10], by(`by') `0'
        gegen x4 = demedian(price)    [pw = gear_ratio / 10], by(`by') `0'

        gen diff1 = abs(x1 - _x1) / max(min(abs(x1), abs(_x1)), 1)
        gen diff2 = abs(x2 - _x1) / max(min(abs(x2), abs(_x1)), 1)
        gen diff3 = abs(x3 - _x3) / max(min(abs(x3), abs(_x3)), 1)
        gen diff4 = abs(x4 - _x4) / max(min(abs(x4), abs(_x4)), 1)

        assert (diff1 < 1e-3) | mi(diff1)
        assert (diff2 < 1e-3) | mi(diff2)
        assert (diff3 < 1e-3) | mi(diff3)
        assert (diff4 < 1e-3) | mi(diff4)
    }

    foreach by in foreign rep78 mpg {
        sysuse auto, clear

        gegen _m1 = mean(price)   [fw = int(gear_ratio * 10)], by(`by')
        gegen _s1 = sd(price)     [fw = int(gear_ratio * 10)], by(`by')
        gegen _d1 = median(price) [iw = gear_ratio / 10],      by(`by')
        gen   _x1 = (price - _m1) / _s1
        gen   _x3 = (price - _m1)
        gen   _x4 = (price - _d1)

        gegen x1 = normalize(price)   [fw = int(gear_ratio * 10)], by(`by') `0' labelf(#stat:pretty# #sourcelabel#) replace
        gegen x2 = standardize(price) [fw = int(gear_ratio * 10)], by(`by') `0'
        gegen x3 = demean(price)      [fw = int(gear_ratio * 10)], by(`by') `0'
        gegen x4 = demedian(price)    [iw = gear_ratio / 10],      by(`by') `0'

        gen diff1 = abs(x1 - _x1) / max(min(abs(x1), abs(_x1)), 1)
        gen diff2 = abs(x2 - _x1) / max(min(abs(x2), abs(_x1)), 1)
        gen diff3 = abs(x3 - _x3) / max(min(abs(x3), abs(_x3)), 1)
        gen diff4 = abs(x4 - _x4) / max(min(abs(x4), abs(_x4)), 1)

        assert (diff1 < 1e-3) | mi(diff1)
        assert (diff2 < 1e-3) | mi(diff2)
        assert (diff3 < 1e-3) | mi(diff3)
        assert (diff4 < 1e-3) | mi(diff4)
    }
end

capture program drop compare_gstats_transform
program compare_gstats_transform
    syntax, [weights *]

    qui `noisily' gen_data, n(500)
    qui expand 20
    qui `noisily' random_draws, random(5) double
    gen long   ix = _n
    gen double ru = runiform() * 500
    qui replace ix = . if mod(_n, 500) == 0
    qui replace ru = . if mod(_n, 500) == 0
    qui sort random1

    local N = trim("`: di %15.0gc _N'")
    di _n(1) "{hline 80}" _n(1) "compare_gstats_transform, N = `N', `options'" _n(1) "{hline 80}" _n(1)

    if ( `"`weights'"' != "" ) {

        qui {
            gen unif_0_100     = 100 * runiform() if mod(_n, 100)
            gen int_unif_0_100 = int(100 * runiform()) if mod(_n, 100)
            gen float_unif_0_1 = runiform() if mod(_n, 100)
            gen rnormal_0_10   = 10 * rnormal() if mod(_n, 100)
        }

        local wcall_a  wgt([aw = unif_0_100])
        local wcall_f  wgt([fw = int_unif_0_100])
        local wcall_a2 wgt([aw = float_unif_0_1])
        local wcall_i  wgt([iw = rnormal_0_10])

        compare_inner_gstats_transform, `options' `wcall_a'
        disp

        compare_inner_gstats_transform in 1 / 5, `options' `wcall_f'
        disp

        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        compare_inner_gstats_transform in `from' / `to', `options' `wcall_a2'
        disp

        compare_inner_gstats_transform if random2 > 0, `options' `wcall_i'
        disp

        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        compare_inner_gstats_transform if random2 < 0 in `from' / `to', `options' `wcall_a'
        disp
    }
    else {
        compare_inner_gstats_transform, `options'
        disp

        compare_inner_gstats_transform in 1 / 5, `options'
        disp

        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        compare_inner_gstats_transform in `from' / `to', `options'
        disp

        compare_inner_gstats_transform if random2 > 0, `options'
        disp

        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        compare_inner_gstats_transform if random2 < 0 in `from' / `to', `options'
        disp
    }
end

capture program drop compare_inner_gstats_transform
program compare_inner_gstats_transform
    syntax [if] [in], [wgt(passthru) *]

    * ---------------------------------------------------------------------

    compare_fail_gstats_transform versus_gstats_transform                         `if' `in', `options' `wgt'

    compare_fail_gstats_transform versus_gstats_transform str_12                  `if' `in', `options' `wgt'
    compare_fail_gstats_transform versus_gstats_transform str_12 str_32 str_4     `if' `in', `options' `wgt'

    compare_fail_gstats_transform versus_gstats_transform double1                 `if' `in', `options' `wgt'
    compare_fail_gstats_transform versus_gstats_transform double1 double2 double3 `if' `in', `options' `wgt'

    compare_fail_gstats_transform versus_gstats_transform int1                    `if' `in', `options' `wgt'
    compare_fail_gstats_transform versus_gstats_transform int1 int2               `if' `in', `options' `wgt'
    compare_fail_gstats_transform versus_gstats_transform int1 int2 int3          `if' `in', `options' `wgt'

    compare_fail_gstats_transform versus_gstats_transform str_32 int3 double3     `if' `in', `options' `wgt'
    compare_fail_gstats_transform versus_gstats_transform int1 double2 double3    `if' `in', `options' `wgt'
    compare_fail_gstats_transform versus_gstats_transform double? str_* int?      `if' `in', `options' `wgt'

    * ---------------------------------------------------------------------

    if ( `"`wgt'"' == "" ) {
        compare_fail_gstats_transform versus_gstats_transform_moving                         `if' `in', `options' `wgt' pr(rangestat w/index)

        compare_fail_gstats_transform versus_gstats_transform_moving str_12                  `if' `in', `options' `wgt' pr(rangestat w/index)
        compare_fail_gstats_transform versus_gstats_transform_moving str_12 str_32 str_4     `if' `in', `options' `wgt' pr(rangestat w/index)

        compare_fail_gstats_transform versus_gstats_transform_moving double1                 `if' `in', `options' `wgt' pr(rangestat w/index)
        compare_fail_gstats_transform versus_gstats_transform_moving double1 double2 double3 `if' `in', `options' `wgt' pr(rangestat w/index)

        compare_fail_gstats_transform versus_gstats_transform_moving int1                    `if' `in', `options' `wgt' pr(rangestat w/index)
        compare_fail_gstats_transform versus_gstats_transform_moving int1 int2               `if' `in', `options' `wgt' pr(rangestat w/index)
        compare_fail_gstats_transform versus_gstats_transform_moving int1 int2 int3          `if' `in', `options' `wgt' pr(rangestat w/index)

        compare_fail_gstats_transform versus_gstats_transform_moving str_32 int3 double3     `if' `in', `options' `wgt' pr(rangestat w/index)
        compare_fail_gstats_transform versus_gstats_transform_moving int1 double2 double3    `if' `in', `options' `wgt' pr(rangestat w/index)
        compare_fail_gstats_transform versus_gstats_transform_moving double? str_* int?      `if' `in', `options' `wgt' pr(rangestat w/index)
    }

    * ---------------------------------------------------------------------

    if ( `"`wgt'"' == "" ) {
        compare_fail_gstats_transform versus_gstats_transform_range                         `if' `in', `options' `wgt' pr(rangestat)

        compare_fail_gstats_transform versus_gstats_transform_range str_12                  `if' `in', `options' `wgt' pr(rangestat)
        compare_fail_gstats_transform versus_gstats_transform_range str_12 str_32 str_4     `if' `in', `options' `wgt' pr(rangestat)

        compare_fail_gstats_transform versus_gstats_transform_range double1                 `if' `in', `options' `wgt' pr(rangestat)
        compare_fail_gstats_transform versus_gstats_transform_range double1 double2 double3 `if' `in', `options' `wgt' pr(rangestat)

        compare_fail_gstats_transform versus_gstats_transform_range int1                    `if' `in', `options' `wgt' pr(rangestat)
        compare_fail_gstats_transform versus_gstats_transform_range int1 int2               `if' `in', `options' `wgt' pr(rangestat)
        compare_fail_gstats_transform versus_gstats_transform_range int1 int2 int3          `if' `in', `options' `wgt' pr(rangestat)

        compare_fail_gstats_transform versus_gstats_transform_range str_32 int3 double3     `if' `in', `options' `wgt' pr(rangestat)
        compare_fail_gstats_transform versus_gstats_transform_range int1 double2 double3    `if' `in', `options' `wgt' pr(rangestat)
        compare_fail_gstats_transform versus_gstats_transform_range double? str_* int?      `if' `in', `options' `wgt' pr(rangestat)
    }
end

capture program drop compare_fail_gstats_transform
program compare_fail_gstats_transform
    gettoken cmd 0: 0
    syntax [anything] [if] [in], [tol(real 1e-6) PRogram(str) *]
    cap `cmd' `0'
    if ( _rc ) {
        if ( "`if'`in'" == "" ) {
            di "    compare_gstats_transform (failed): full range (vs `program') `anything'; `options'"
        }
        else if ( "`if'`in'" != "" ) {
            di "    compare_gstats_transform (failed): [`if'`in'] (vs `program') `anything'; `options'"
        }
        exit _rc
    }
    else {
        if ( "`if'`in'" == "" ) {
            di "    compare_gstats_transform (passed): full range, gstats results equal to `program' (tol = `tol'; `anything'; `options')"
        }
        else if ( "`if'`in'" != "" ) {
            di "    compare_gstats_transform (passed): [`if'`in'], gstats results equal to `program' (tol = `tol'; `anything'; `options')"
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

***********************************************************************
*                          Transform versus                           *
***********************************************************************

capture program drop versus_gstats_transform
program versus_gstats_transform, rclass
    syntax [anything] [if] [in], [tol(real 1e-6) wgt(str) *]

    local tcall1 (demean)    _out2 = random2 (demedian) _out3 = random3 (normalize) _out4 = random4 _out5 = random5
    local tcall2 (demean)    _out* = random*
    local tcall3 (normalize) _out* = random*

    local gcall1 (mean)   _goutm2   = random2 _goutm4 = random4 _goutm5 = random5 /*
              */ (sd)                         _gouts4 = random4 _gouts5 = random5 /*
              */ (median) _goutmed3 = random3
    local gcall2 (mean) _gout*  = random*
    local gcall3 (mean) _goutm* = random* (sd) _gouts* = random*

    forvalues i = 1 / 3 {
        timer clear
        timer on 42
        qui gstats transform `tcall`i'' `if' `in' `wgt', by(`anything') wild replace `options'
        timer off 42
        qui timer list
        local time_gtransform = r(t42)

        timer clear
        timer on 43
        if ( `i' == 1 ) {
            local start = 2
            qui {
                gcollapse `gcall`i'' `if' `in' `wgt', by(`anything') wild merge replace
                gen _gout2 = (random2 - _goutm2)
                gen _gout3 = (random3 - _goutmed3)
                gen _gout4 = (random4 - _goutm4) / _gouts4
                gen _gout5 = (random5 - _goutm5) / _gouts5
            }
        }
        else if ( `i' == 2 ) {
            local start = 1
            qui gcollapse `gcall`i'' `if' `in' `wgt', by(`anything') wild merge replace _subtract
        }
        else if ( `i' == 3 ) {
            local start = 1
            qui {
                gcollapse `gcall`i'' `if' `in' `wgt', by(`anything') wild merge replace
                gen _gout1 = (random1 - _goutm1) / _gouts1
                gen _gout2 = (random2 - _goutm2) / _gouts2
                gen _gout3 = (random3 - _goutm3) / _gouts3
                gen _gout4 = (random4 - _goutm4) / _gouts4
                gen _gout5 = (random5 - _goutm5) / _gouts5
            }
        }
        timer off 43
        qui timer list
        local time_manual = r(t43)

        forvalues j = `start' / 5 {
            cap assert (abs((_gout`j' - _out`j') / max(abs(_gout`j'), 1)) < `tol' | _gout`j' == _out`j')
            if ( _rc ) {
                disp `j'
                exit _rc
            }
        }

        cap drop _*
        local rs = `time_manual'  / `time_gtransform'
        di as txt "    `:di %6.3g `time_manual'' | `:di %13.3g `time_gtransform'' | `:di %11.4g `rs'' | (`i') `anything'"
    }
end

capture program drop versus_gstats_transform_range
program versus_gstats_transform_range, rclass
    syntax [anything] [if] [in], [tol(real 1e-6) wgt(str) pr(str) *]

    local rcall1
    local rcall2
    local rcall3
    local rcall4

    local rcall1 `rcall1'  (count)    _out1  = random2
    local rcall1 `rcall1'  (first)    _out12 = random2
    local rcall1 `rcall1'  (firstnm)  _out13 = random2
    local rcall1 `rcall1'  (min)      _out9  = random2
    local rcall1 `rcall1'  (mean)     _out3  = random2
                        
    local rcall2 `rcall2'  (missing)  _out2  = random2
    local rcall2 `rcall2'  (last)     _out14 = random2
    local rcall2 `rcall2'  (lastnm)   _out15 = random2
    local rcall2 `rcall2'  (max)      _out11 = random2
    local rcall2 `rcall2'  (sum)      _out4  = random2
                        
    local rcall3 `rcall3'  (sd)       _out5  = random2
    local rcall3 `rcall3'  (variance) _out6  = random2

    local rcall4 `rcall4'  (skewness) _out7  = random2
    local rcall4 `rcall4'  (kurtosis) _out8  = random2
    local rcall4 `rcall4'  (median)   _out10 = random2

    local tcall1
    local tcall2
    local tcall3
    local tcall4

    local tcall1 `tcall1' (range count)    _gout1  = random2
    local tcall1 `tcall1' (range first)    _gout12 = random2
    local tcall1 `tcall1' (range firstnm)  _gout13 = random2
    local tcall1 `tcall1' (range min)      _gout9  = random2
    local tcall1 `tcall1' (range mean)     _gout3  = random2

    local tcall2 `tcall2' (range nmissing) _gout2  = random2
    local tcall2 `tcall2' (range last)     _gout14 = random2
    local tcall2 `tcall2' (range lastnm)   _gout15 = random2
    local tcall2 `tcall2' (range max)      _gout11 = random2
    local tcall2 `tcall2' (range sum)      _gout4  = random2

    local tcall3 `tcall3' (range sd)       _gout5  = random2
    local tcall3 `tcall3' (range variance) _gout6  = random2

    local tcall4 `tcall4' (range skewness) _gout7  = random2
    local tcall4 `tcall4' (range kurtosis) _gout8  = random2
    local tcall4 `tcall4' (range median)   _gout10 = random2

    local opts
    gegen double _sd = sd(random4) `if' `in' `wgt', by(`anything')
    qui gen double _low  = random4 - 0.75 * _sd
    qui gen double _high = random4 + 0.75 * _sd

    timer clear
    timer on 42
    qui gstats transform `tcall1'  `if' `in' `wgt', by(`anything') `options' interval(-0.5    0.5    random3)
    qui gstats transform `tcall2'  `if' `in' `wgt', by(`anything') `options' interval(-0.75sd 0.75sd random4)
    qui gstats transform `tcall3'  `if' `in' `wgt', by(`anything') `options' interval(-0.5      .    random3)
    qui gstats transform `tcall4'  `if' `in' `wgt', by(`anything') `options' interval(   .    0.5    random3)
    timer off 42
    qui timer list
    local time_gtransform = r(t42)

    timer clear
    timer on 43
    rangestat `rcall1' `if' `in' `wgt', by(`anything') interval(random3 -0.5   0.5)
    rangestat `rcall2' `if' `in' `wgt', by(`anything') interval(random4 _low _high)
    rangestat `rcall3' `if' `in' `wgt', by(`anything') interval(random3 -0.5     .)
    rangestat `rcall4' `if' `in' `wgt', by(`anything') interval(random3    .   0.5)
    timer off 43
    qui timer list
    local time_manual = r(t43)

    forvalues j = 1 / 15 {
        cap assert (((abs(_gout`j' - _out`j') / max(abs(_gout`j'), 1)) < `tol') | (_gout`j' == _out`j'))
        if ( _rc ) {
            disp `j'
            exit _rc
        }
    }
    * head random? _sd _low _high _gout4 _out4

    cap drop _*
    local rs = `time_manual'  / `time_gtransform'
    di as txt "    `:di %6.3g `time_manual'' | `:di %13.3g `time_gtransform'' | `:di %11.4g `rs'' | (`i') `anything'"
end

capture program drop versus_gstats_transform_moving
program versus_gstats_transform_moving, rclass
    syntax [anything] [if] [in], [tol(real 1e-6) wgt(str) pr(str) *]

    local rcall1
    local rcall2
    local rcall3

    local rcall1 `rcall1'  (count)    _out1  = random2
    local rcall1 `rcall1'  (first)    _out12 = random2
    local rcall1 `rcall1'  (firstnm)  _out13 = random2
    local rcall1 `rcall1'  (min)      _out9  = random2
    local rcall1 `rcall1'  (mean)     _out3  = random2
                        
    local rcall2 `rcall2'  (missing)  _out2  = random2
    local rcall2 `rcall2'  (last)     _out14 = random2
    local rcall2 `rcall2'  (lastnm)   _out15 = random2
    local rcall2 `rcall2'  (max)      _out11 = random2
    local rcall2 `rcall2'  (sum)      _out4  = random2
                        
    local rcall3 `rcall3'  (sd)       _out5  = random2
    local rcall3 `rcall3'  (variance) _out6  = random2
    local rcall3 `rcall3'  (skewness) _out7  = random2
    local rcall3 `rcall3'  (kurtosis) _out8  = random2
    local rcall3 `rcall3'  (median)   _out10 = random2

    local tcall1
    local tcall2
    local tcall3

    local tcall1 `tcall1' (moving count)    _gout1  = random2
    local tcall1 `tcall1' (moving first)    _gout12 = random2
    local tcall1 `tcall1' (moving firstnm)  _gout13 = random2
    local tcall1 `tcall1' (moving min)      _gout9  = random2
    local tcall1 `tcall1' (moving mean)     _gout3  = random2

    local tcall2 `tcall2' (moving nmissing) _gout2  = random2
    local tcall2 `tcall2' (moving last)     _gout14 = random2
    local tcall2 `tcall2' (moving lastnm)   _gout15 = random2
    local tcall2 `tcall2' (moving max)      _gout11 = random2
    local tcall2 `tcall2' (moving sum)      _gout4  = random2

    local tcall3 `tcall3' (moving sd)       _gout5  = random2
    local tcall3 `tcall3' (moving variance) _gout6  = random2
    local tcall3 `tcall3' (moving skewness) _gout7  = random2
    local tcall3 `tcall3' (moving kurtosis) _gout8  = random2
    local tcall3 `tcall3' (moving median)   _gout10 = random2

    if ( `"`anything'"' != "" ) {
        qui bys `anything': gen _index = _n
        qui bys `anything': gen _ilow  = _n > 5
        qui bys `anything': gen _ihigh = _n < (_N - 5 + 1)
    }
    else {
        qui gen _index = _n
        qui gen _ilow  = _n > 5
        qui gen _ihigh = _n < (_N - 5 + 1)
    }

    timer clear
    timer on 42
    qui gstats transform `tcall1'  `if' `in' `wgt', by(`anything') `options' window(-5 5)
    qui gstats transform `tcall2'  `if' `in' `wgt', by(`anything') `options' window(-5 .)
    qui gstats transform `tcall3'  `if' `in' `wgt', by(`anything') `options' window( . 5)
    timer off 42
    qui timer list
    local time_gtransform = r(t42)

    timer clear
    timer on 43
    qui rangestat `rcall1' `if' `in' `wgt', by(`anything') interval(_index -5 5)
    qui rangestat `rcall2' `if' `in' `wgt', by(`anything') interval(_index -5 .)
    qui rangestat `rcall3' `if' `in' `wgt', by(`anything') interval(_index  . 5)
    timer off 43
    qui timer list
    local time_manual = r(t43)

    qui {
        replace _out1  = . if _ilow == 0
        replace _out12 = . if _ilow == 0
        replace _out13 = . if _ilow == 0
        replace _out9  = . if _ilow == 0
        replace _out3  = . if _ilow == 0

        replace _out1  = . if _ihigh == 0
        replace _out12 = . if _ihigh == 0
        replace _out13 = . if _ihigh == 0
        replace _out9  = . if _ihigh == 0
        replace _out3  = . if _ihigh == 0

        replace _out2  = . if _ilow == 0
        replace _out14 = . if _ilow == 0
        replace _out15 = . if _ilow == 0
        replace _out11 = . if _ilow == 0
        replace _out4  = . if _ilow == 0

        replace _out5  = . if _ihigh == 0
        replace _out6  = . if _ihigh == 0
        replace _out7  = . if _ihigh == 0
        replace _out8  = . if _ihigh == 0
        replace _out10 = . if _ihigh == 0
    }

    forvalues j = 1 / 15 {
        cap assert (((abs(_gout`j' - _out`j') / max(abs(_gout`j'), 1)) < `tol') | (_gout`j' == _out`j'))
        if ( _rc ) {
            disp `j'
            gen _diff`j' = abs(_gout`j' - _out`j') / max(abs(_gout`j'), 1)
            * exit _rc
        }
    }

    cap drop _*
    local rs = `time_manual'  / `time_gtransform'
    di as txt "    `:di %6.3g `time_manual'' | `:di %13.3g `time_gtransform'' | `:di %11.4g `rs'' | (`i') `anything'"
end
