capture program drop checks_gcollapse
program checks_gcollapse
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_gcollapse, `options'" _n(1) "{hline 80}" _n(1)
    local options `options' tol(`tol')

    qui `noisily' gen_data, n(5000)
    qui expand 2
    qui `noisily' random_draws, random(2)
    gen long ix = _n

    checks_inner_collapse, `options'

    checks_inner_collapse -str_12,              `options'
    checks_inner_collapse str_12 -str_32,       `options'
    checks_inner_collapse str_12 -str_32 str_4, `options'

    checks_inner_collapse -double1,                 `options'
    checks_inner_collapse double1 -double2,         `options'
    checks_inner_collapse double1 -double2 double3, `options'

    checks_inner_collapse -int1,           `options'
    checks_inner_collapse int1 -int2,      `options'
    checks_inner_collapse int1 -int2 int3, `options'

    checks_inner_collapse -int1 -str_32 -double1,                                         `options'
    checks_inner_collapse int1 -str_32 double1 -int2 str_12 -double2,                     `options'
    checks_inner_collapse int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options'

    **************************************
    *  Misc tests of new options in 1.4  *
    **************************************

    sysuse auto, clear

    local gcall
    local gcall `gcall' (mean)         mean         = price
    local gcall `gcall' (geomean)      geomean      = price
    local gcall `gcall' (gini)         gini         = price
    local gcall `gcall' (gini|dropneg) gini_dropneg = price
    local gcall `gcall' (gini|keepneg) gini_keepneg = price
    local gcall `gcall' (sd)           sd           = price
    local gcall `gcall' (variance)     variance     = price
    local gcall `gcall' (cv)           cv           = price
    local gcall `gcall' (min)          min          = price
    local gcall `gcall' (max)          max          = price
    local gcall `gcall' (range)        range        = price
    local gcall `gcall' (select1)      select1      = price
    local gcall `gcall' (select2)      select2      = price
    local gcall `gcall' (select3)      select3      = price
    local gcall `gcall' (select99)     select99     = price
    local gcall `gcall' (select-99)    select_99    = price
    local gcall `gcall' (select-3)     select_3     = price
    local gcall `gcall' (select-2)     select_2     = price
    local gcall `gcall' (select-1)     select_1     = price

    gcollapse `gcall', by(foreign) merge
    assert abs((sd / mean) - cv) < `tol'
    assert abs((sd^2 - variance) / min(sd^2, variance)) < `tol'
    assert abs((range) - (max - min)) < `tol'

    bys foreign (price): assert abs(price[1] - select1) < `tol'
    bys foreign (price): assert abs(price[2] - select2) < `tol'
    bys foreign (price): assert abs(price[3] - select3) < `tol'
    bys foreign (price): assert abs(price[_N - 2] - select_3) < `tol'
    bys foreign (price): assert abs(price[_N - 1] - select_2) < `tol'
    bys foreign (price): assert abs(price[_N - 0] - select_1) < `tol'

    assert mi(select99)
    assert mi(select_99)

    clear
    qui {
        set obs 10
        gen x = _n
        gen w = 1.5
        replace x = .  in 1/2
        replace x = .a in 3
        replace x = .b in 4
        replace x = .c in 5
        replace x = .d in 6
    }
    gsort -x

        local gcall
        local gcall `gcall' (min)   min   = x
        local gcall `gcall' (max)   max   = x
        local gcall `gcall' (range) range = x
    preserve
        gcollapse `gcall'
        assert min == 7
        assert max == 10
        assert range == 3
    restore, preserve
        gcollapse `gcall' if mi(x)
        assert min == .
        assert max == .d
        assert range == .
    restore, preserve
        gcollapse `gcall' if x > .
        assert min == .a
        assert max == .d
        assert range == .
    restore

        local gcall
        local gcall `gcall' (select1)   select1   = x
        local gcall `gcall' (select2)   select2   = x
        local gcall `gcall' (select3)   select3   = x
        local gcall `gcall' (select99)  select99  = x
        local gcall `gcall' (select-99) select_99 = x
        local gcall `gcall' (select-3)  select_3  = x
        local gcall `gcall' (select-2)  select_2  = x
        local gcall `gcall' (select-1)  select_1  = x
        local rawstat select1 select2 select3 select99 select_99 select_3 select_2 select_1
    preserve
        gcollapse `gcall'
        assert select1   == 7
        assert select2   == 8
        assert select3   == 9
        assert select99  == .
        assert select_99 == .
        assert select_3  == 8
        assert select_2  == 9
        assert select_1  == 10
    restore, preserve
        gcollapse `gcall' if mi(x)
        assert select1   == .
        assert select2   == .
        assert select3   == .a
        assert select99  == .
        assert select_99 == .
        assert select_3  == .b
        assert select_2  == .c
        assert select_1  == .d
    restore, preserve
        gcollapse `gcall' if x > .
        assert select1   == .a
        assert select2   == .b
        assert select3   == .c
        assert select99  == .
        assert select_99 == .
        assert select_3  == .b
        assert select_2  == .c
        assert select_1  == .d
    restore

    preserve
        gcollapse `gcall' [w = w], rawstat(`rawstat')
        assert select1   == 7
        assert select2   == 8
        assert select3   == 9
        assert select99  == .
        assert select_99 == .
        assert select_3  == 8
        assert select_2  == 9
        assert select_1  == 10
    restore, preserve
        gcollapse `gcall' if mi(x) [w = w], rawstat(`rawstat')
        assert select1   == .
        assert select2   == .
        assert select3   == .a
        assert select99  == .
        assert select_99 == .
        assert select_3  == .b
        assert select_2  == .c
        assert select_1  == .d
    restore, preserve
        gcollapse `gcall' if x > . [w = w], rawstat(`rawstat')
        assert select1   == .a
        assert select2   == .b
        assert select3   == .c
        assert select99  == .
        assert select_99 == .
        assert select_3  == .b
        assert select_2  == .c
        assert select_1  == .d
    restore

    preserve
        gcollapse `gcall' [w = w]
        assert select1   == 7
        assert select2   == 8
        assert select3   == 8
        assert select99  == .
        assert select_99 == .
        assert select_3  == 9
        assert select_2  == 9
        assert select_1  == 10
    restore, preserve
        gcollapse `gcall' if mi(x) [w = w]
        assert select1   == .
        assert select2   == .
        assert select3   == .
        assert select99  == .
        assert select_99 == .
        assert select_3  == .
        assert select_2  == .
        assert select_1  == .
    restore, preserve
        gcollapse `gcall' if x > . [w = w]
        assert select1   == .
        assert select2   == .
        assert select3   == .
        assert select99  == .
        assert select_99 == .
        assert select_3  == .
        assert select_2  == .
        assert select_1  == .
    restore

        local gcall
        local gcall `gcall' (select1)   select1   = x
        local gcall `gcall' (select2)   select2   = x
        local gcall `gcall' (select3)   select3   = x
        local gcall `gcall' (select99)  select99  = x
        local gcall `gcall' (select-99) select_99 = x
        local gcall `gcall' (select-3)  select_3  = x
        local gcall `gcall' (select-2)  select_2  = x
        local gcall `gcall' (select-1)  select_1  = x
        local gcall `gcall' (rawselect1)   rawselect1   = x
        local gcall `gcall' (rawselect2)   rawselect2   = x
        local gcall `gcall' (rawselect3)   rawselect3   = x
        local gcall `gcall' (rawselect99)  rawselect99  = x
        local gcall `gcall' (rawselect-99) rawselect_99 = x
        local gcall `gcall' (rawselect-3)  rawselect_3  = x
        local gcall `gcall' (rawselect-2)  rawselect_2  = x
        local gcall `gcall' (rawselect-1)  rawselect_1  = x
        local rawstat select1 select2 select3 select99 select_99 select_3 select_2 select_1
    preserve
        gcollapse `gcall' [w = w], rawstat(`rawstat')
        assert (select1   == 7)  & (select1   == rawselect1)
        assert (select2   == 8)  & (select2   == rawselect2)
        assert (select3   == 9)  & (select3   == rawselect3)
        assert (select99  == .)  & (select99  == rawselect99)
        assert (select_99 == .)  & (select_99 == rawselect_99)
        assert (select_3  == 8)  & (select_3  == rawselect_3)
        assert (select_2  == 9)  & (select_2  == rawselect_2)
        assert (select_1  == 10) & (select_1  == rawselect_1)
    restore, preserve
        gcollapse `gcall' if mi(x) [w = w], rawstat(`rawstat')
        assert (select1   == .)   & (select1   == rawselect1)
        assert (select2   == .)   & (select2   == rawselect2)
        assert (select3   == .a)  & (select3   == rawselect3)
        assert (select99  == .)   & (select99  == rawselect99)
        assert (select_99 == .)   & (select_99 == rawselect_99)
        assert (select_3  == .b)  & (select_3  == rawselect_3)
        assert (select_2  == .c)  & (select_2  == rawselect_2)
        assert (select_1  == .d)  & (select_1  == rawselect_1)
    restore, preserve
        gcollapse `gcall' if x > . [w = w], rawstat(`rawstat')
        assert (select1   == .a)  & (select1   == rawselect1)
        assert (select2   == .b)  & (select2   == rawselect2)
        assert (select3   == .c)  & (select3   == rawselect3)
        assert (select99  == .)   & (select99  == rawselect99)
        assert (select_99 == .)   & (select_99 == rawselect_99)
        assert (select_3  == .b)  & (select_3  == rawselect_3)
        assert (select_2  == .c)  & (select_2  == rawselect_2)
        assert (select_1  == .d)  & (select_1  == rawselect_1)
    restore

    **************************
    *  Undocumented options  *
    **************************

    clear
    set obs 100
    gen x = _n
    gen y = mod(_n, 13)
    gen z = mod(_n, 3)
    gegen dmx = mean(x), _subtract
    gegen dmy = mean(y), _subtract
    gegen  mx = mean(x)
    gegen  my = mean(y)
    assert abs(dmx - (x - mx)) < `tol'
    assert abs(dmy - (y - my)) < `tol'

    drop *m?
    gcollapse (mean) dmx = x dmy = y, merge _subtract
    gcollapse (mean)  mx = x  my = y, merge
    assert abs(dmx - (x - mx)) < `tol'
    assert abs(dmy - (y - my)) < `tol'

    drop *m?
    gegen dmx = mean(x), by(z) _subtract
    gegen dmy = mean(y), by(z) _subtract
    gegen  mx = mean(x), by(z)
    gegen  my = mean(y), by(z)
    assert abs(dmx - (x - mx)) < `tol'
    assert abs(dmy - (y - my)) < `tol'

    drop *m?
    gcollapse (mean) dmx = x dmy = y, by(z) merge _subtract
    gcollapse (mean)  mx = x  my = y, by(z) merge
    assert abs(dmx - (x - mx)) < `tol'
    assert abs(dmy - (y - my)) < `tol'

    ****************
    *  Misc tests  *
    ****************

    clear
    cap gcollapse
    assert _rc == 198
    set obs 10
    cap gcollapse
    assert _rc == 198
    gen x = .
    gcollapse x

    clear
    set obs 10
    gen x = .
    gen w = .
    cap gcollapse x [w = w]
    assert _rc == 2000
    cap gcollapse x if w == 0
    assert _rc == 2000

    clear
    set obs 10
    gen x = _n
    gen y = 1
    gcollapse (kurt) mx = x, merge
    cap gcollapse (kurt) mx = x, merge
    assert _rc == 110
    gcollapse mx = x, merge replace
    gcollapse mx = x, merge by(y) replace
    cap gcollapse y = x,  merge by(y)
    assert _rc == 110
    cap gcollapse y = x,  merge by(y) replace
    assert _rc == 110
    gcollapse y = x,  merge by(y) debug_replaceby
    cap gcollapse x = x,  merge by(y)
    assert _rc == 110
    gcollapse x = x,  merge by(y) replace
    cap gcollapse mx = x,  merge by(y)
    assert _rc == 110

    * Weird stuff happens when you try to use tempvar names without
    * calling tempvar. DON'T!

    * clear
    * set obs 10
    * gen x = _n
    * gen y = 1
    * gcollapse __000000 = x __000001 = x __000002 = x,         merge by(y)
    * gcollapse __000000 = x __000001 = x __000002 = x if 1,    merge by(y)
    * gcollapse __000000 = x __000001 = x __000002 = x [w = y], merge by(y)

    clear
    set obs 10
    gen byte x = _n
    replace x = . in 1/5
    gen y = mi(x)
    preserve
        gcollapse (nmissing) nm = x ///
                  (sum) s = x       ///
                  (rawsum) rs = x   ///
                  (nansum) ns = x   ///
                  (rawnansum) rns = x, by(y)
        l
        assert !mi(s) & !mi(rs)
        assert  mi(ns[2]) &  mi(rns[2])
        assert !mi(ns[1]) & !mi(rns[1])
        assert (nm[1] == 0) & (nm[2] == 5)
    restore, preserve
        gcollapse (nmissing) nm = x ///
                  (sum) s = x       ///
                  (rawsum) rs = x   ///
                  (nansum) ns = x   ///
                  (rawnansum) rns = x [fw = 9123], by(y)
        assert !mi(s) & !mi(rs)
        assert  mi(ns[2]) &  mi(rns[2])
        assert !mi(ns[1]) & !mi(rns[1])
        assert (nm[1] == 0) & (nm[2] == 5 * 9123)
    restore, preserve
        gcollapse (nmissing) nm = x ///
                  (sum) s = x       ///
                  (rawsum) rs = x   ///
                  (nansum) ns = x   ///
                  (rawnansum) rns = x [pw = 987654321], by(y)
        assert !mi(s) & !mi(rs)
        assert  mi(ns[2]) &  mi(rns[2])
        assert !mi(ns[1]) & !mi(rns[1])
        assert (nm[1] == 0) & (nm[2] == 5 * 987654321)
    restore, preserve
        gcollapse (nmissing) nm = x ///
                  (sum) s = x       ///
                  (rawsum) rs = x   ///
                  (nansum) ns = x   ///
                  (rawnansum) rns = x [aw = 2323.412], by(y)
        assert !mi(s) & !mi(rs)
        assert  mi(ns[2]) &  mi(rns[2])
        assert !mi(ns[1]) & !mi(rns[1])
        assert (nm[1] == 0) & (nm[2] == 5)
    restore
    gcollapse (nmissing) nm = x ///
              (sum) s = x       ///
              (rawsum) rs = x   ///
              (nansum) ns = x   ///
              (rawnansum) rns = x, by(y) missing
    assert s == ns
    assert rs == rns
    assert  mi(ns[2]) &  mi(rns[2])
    assert !mi(ns[1]) & !mi(rns[1])
    assert (nm[1] == 0) & (nm[2] == 5)
end

capture program drop checks_inner_collapse
program checks_inner_collapse
    syntax [anything], [tol(real 1e-6) wgt(str) *]

    local 0 `anything' `wgt', `options'
    syntax [anything] [aw fw iw pw], [*]

    local percentiles p1 p10 p30.5 p50 p70.5 p90 p99
    local selections  select1 select2 select5 select999999 select-999999 select-5 select-2 select-1
    local stats nunique nmissing sum mean geomean max min range count percent first last firstnm lastnm median iqr skew kurt gini gini|dropneg gini|keepneg
    if ( !inlist("`weight'", "pweight") )            local stats `stats' sd variance cv
    if ( !inlist("`weight'", "pweight", "iweight") ) local stats `stats' semean
    if (  inlist("`weight'", "fweight", "") )        local stats `stats' sebinomial sepoisson

    local collapse_str ""
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') r1_`:subinstr local stat "|" "_", all' = random1
    }
    foreach pct of local percentiles {
        local collapse_str `collapse_str' (`pct') r1_`:subinstr local pct "." "_", all' = random1
    }
    if ( !inlist("`weight'", "iweight") ) {
        foreach sel of local selections {
            local collapse_str `collapse_str' (`sel') s1_`:subinstr local sel "-" "_", all' = random1
        }
    }

    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') r2_`:subinstr local stat "|" "_", all' = random2
    }
    foreach pct of local percentiles {
        local collapse_str `collapse_str' (`pct') r2_`:subinstr local pct "." "_", all' = random2
    }
    if ( !inlist("`weight'", "iweight") ) {
        foreach sel of local selections {
            local collapse_str `collapse_str' (`sel') s2_`:subinstr local sel "-" "_", all' = random2
        }
    }

    preserve
        gcollapse `collapse_str' `wgt', by(`anything') verbose `options'
    restore, preserve
        gcollapse `collapse_str' `wgt', by(`anything') verbose benchmark `options'
    restore, preserve
        gcollapse `collapse_str' `wgt', by(`anything') verbose forceio `options'
    restore, preserve
        gcollapse `collapse_str' `wgt', by(`anything') verbose forcemem `options'
    restore, preserve
        gcollapse `collapse_str' `wgt', by(`anything') verbose benchmark cw `options'
    restore, preserve
        gcollapse `collapse_str' `wgt', by(`anything') verbose benchmark fast `options'
    restore, preserve
        gcollapse `collapse_str' `wgt', by(`anything') double `options'
    restore, preserve
        gcollapse `collapse_str' `wgt', by(`anything') merge `options'
    restore, preserve
        gcollapse `collapse_str' `wgt', by(`anything') verbose `options' benchmark debug_io_check(0)
    restore
end

***********************************************************************
*                            Corner cases                             *
***********************************************************************

capture program drop checks_corners
program checks_corners
    syntax, [*]
    di _n(1) "{hline 80}" _n(1) "checks_corners `options'" _n(1) "{hline 80}" _n(1)

    * Negative or zero values for geomean
    qui {
        clear
        set obs 10
        gen g = mod(_n, 2)
        gen x = _n - 6
        gen w = cond(x < 0, 0, _n)
        preserve
            gcollapse (geomean) x, by(g)
            assert mi(x)
        restore, preserve
            gcollapse (geomean) x if x > 0, by(g)
            assert x != 0 & !mi(x)
        restore, preserve
            gcollapse (geomean) x if x >= 0, by(g)
            assert x[1] == 0 & !mi(x[2])
        restore, preserve
            gcollapse (geomean) x [aw = w], by(g)
            assert x[1] == 0 & !mi(x[2])
        restore, preserve
            gcollapse (geomean) x [fw = w], by(g)
            assert x[1] == 0 & !mi(x[2])
        restore
    }

    * Parsing by: in gegen
    qui {
        clear
        set obs 10
        gen var = mod(_n, 3)
        gen y   = _n
        gen u   = runiform()
        cap noi by var: gegen x = mean(max(y, y[1]))
        by var (u), sort: gegen x = mean(max(y, y[1]))
        sort y
        bys var (u): gegen z = mean(max(y, y[1]))
        bys var (u):  egen w = mean(max(y, y[1]))
        assert x == z
        assert x == w
    }

    * Parsing negatives
    qui {
        sysuse auto, clear
        gtop * if foreign [w = rep78]
        gtop -* if foreign [w = rep78]
        gen bye = 1
        gtop bye *n*
        gtop bye -*n*

        glevelsof *  if (27 * foreign)
        glevelsof -* if (27 * foreign)

        sysuse auto, clear
        gcontract * if foreign [w = rep78]

        sysuse auto, clear
        gcontract foreign -*n* price if price > 5000 [w = rep78]

        sysuse auto, clear
        gcollapse price if price > 5000 [w = rep78], by(*n*)

        sysuse auto, clear
        gcollapse price if price > 5000 [w = rep78], by(foreign -*n*)

        clear
        set obs 3
        gen  i = _n
        gen x1 = 1
        gen x2 = 2
        gen y3 = _n
        cap noi greshape long x y
        cap noi greshape wide x y
        cap noi greshape spread x y
        cap noi greshape spread x y
        greshape long x y, i(i) j(j)
        greshape wide x y, i(i) j(j)
        greshape long x y, by(i) j(j)
        greshape wide x y, by(i) j(j)
        greshape long x y, i(i) keys(j)
        greshape wide x y, i(i) keys(j)
        greshape long x y, by(i) keys(j)
        greshape wide x y, by(i) keys(j)
        greshape long x y, by(i) keys(j)
        gen k = _N - _n
        greshape wide x y, by(i) keys(j k)
        cap noi greshape
        greshape long x y, by(i) keys(j) string
        replace j = "" in 1 / 10
        cap noi greshape wide x y, by(i) keys(j) nomisscheck
        replace j = " " in 1 / 10
        cap noi greshape wide x y, by(i) keys(j) nomisscheck
        replace j = "" in 1 / 10
        gen j2 = j
        cap noi greshape wide x y, by(i) keys(j j2) nomisscheck
    }

    * https://github.com/mcaceresb/stata-gtools/issues/45
    qui {
        clear
        set obs 5
        gen long id1 = 0
        gen int id2  = 0
        replace id1 = 3 in 1
        replace id1 = 3 in 2
        replace id1 = 9 in 3
        replace id1 = 4 in 4
        replace id1 = 9 in 5
        replace id2 = 6 in 1
        replace id2 = 7 in 2
        replace id2 = 1 in 3
        replace id2 = 1 in 4
        replace id2 = 1 in 5
        gen id3 = _n
        tostring id1 id2, gen(sid1 sid2)
        cap noi gisid id1 id2, v
        assert _rc == 459
        cap noi gisid sid1 sid2, v
        assert _rc == 459

        sort id1 id2
        cap noi gisid id1 id2, v
        assert _rc == 459
        sort sid1 sid2
        cap noi gisid sid1 sid2, v
        assert _rc == 459

        gen sid3 = string(_n)
        cap noi gisid id1 id2 id3, v
        assert _rc == 0
        cap noi gisid sid1 sid2 sid3, v
        assert _rc == 0
    }

    * https://github.com/mcaceresb/stata-gtools/issues/44
    qui {
        * 1. byte, int, long upgraded to int, long, double
        * 2. byte, int, long preserved
        * 3. float always upgraded
        * 4. float, double never downgraded
        * 5. Overflow warning
        clear
        set obs 10
        gen byte    b1 = 1
        gen int     i1 = 2
        gen long    l1 = 3
        gen float   f1 = 3.14
        gen double  d1 = 3.141592
        gen byte    b2 = maxbyte()
        gen int     i2 = maxint()
        gen long    l2 = maxlong()
        gen float   f2 = maxfloat()
        gen double  d2 = maxdouble()

        preserve
            gcollapse (sum) *
            foreach var of varlist * {
                assert "`:type `var''" == "double"
            }
        restore, preserve
            gcollapse (sum) *, sumcheck
            foreach var of varlist f1 d1 l2 f2 d2 {
                assert "`:type `var''" == "double"
            }
            assert "`:type b1'" == "byte"
            assert "`:type i1'" == "int"
            assert "`:type l1'" == "long"
            assert "`:type b2'" == "int"
            assert "`:type i2'" == "long"
        restore, preserve
            gcollapse (mean) m_* = * (sum) * (max) mx_* = *, sumcheck wild
            foreach var of varlist f1 d1 l2 f2 d2 {
                assert "`:type `var''" == "double"
            }
            assert "`:type b1'" == "byte"
            assert "`:type i1'" == "int"
            assert "`:type l1'" == "long"
            assert "`:type b2'" == "int"
            assert "`:type i2'" == "long"
        restore, preserve
            gcollapse (sum) s_* = * (mean) m_* = * (max) mx_* = *, sumcheck wild
            foreach var of varlist s_f1 s_d1 s_l2 s_f2 s_d2 {
                assert "`:type `var''" == "double"
            }
            assert "`:type s_b1'" == "byte"
            assert "`:type s_i1'" == "int"
            assert "`:type s_l1'" == "long"
            assert "`:type s_b2'" == "int"
            assert "`:type s_i2'" == "long"
        restore, preserve
            gcollapse (sum) s_* = * (mean) * (max) mx_* = *, sumcheck wild
            foreach var of varlist s_f1 s_d1 s_l2 s_f2 s_d2 {
                assert "`:type `var''" == "double"
            }
            assert "`:type s_b1'" == "byte"
            assert "`:type s_i1'" == "byte"
            assert "`:type s_l1'" == "byte"
            assert "`:type s_b2'" == "int"
            assert "`:type s_i2'" == "long"
        restore, preserve
            gcollapse (sum) b1 [fw = i2], sumcheck
            assert "`:type b1'" == "long"
        restore, preserve
            gcollapse (sum) b1 [fw = d2], sumcheck
            assert "`:type b1'" == "double"
        restore, preserve
            gen n = _n
            gcollapse (sum) b1 [fw = d2], by(n) sumcheck
            assert "`:type b1'" == "double"
            assert b1 == maxdouble()
        restore
    }

    * e-mail issue #0
    qui {
        clear
        set more off
        set seed 1
        set obs 2
        g y = 1.23
        preserve
            gcollapse (count) cy = y (first) fy = y, freq(z)
            assert abs(fy - 1.23) < 1e-6
        restore, preserve
            gcollapse (count) y (first) fy = y, freq(z)
            assert abs(fy - 1.23) < 1e-6
        restore, preserve
            gcollapse (first) fy = y (count) y , freq(z)
            assert abs(fy - 1.23) < 1e-6
        restore, preserve
            gcollapse (first) fy = y (count) cy = y, freq(z)
            assert abs(fy - 1.23) < 1e-6
        restore
    }

    * https://github.com/mcaceresb/stata-gtools/issues/39
    qui {
        clear
        set obs 5
        gen x = _n
        gen strL y = "hi"
        cap gcollapse (p70) x, by(y)
        assert _rc == 17002

        clear
        set obs 5
        gen x = _n
        gen strL y = "hi"
        cap gcollapse (p70) x, by(y) compress
        assert _rc == 0

        clear
        set obs 5
        gen x = _n
        gen strL y = "hi" + string(mod(_n, 2)) + char(9) + char(0)
        cap gcollapse (p70) x, by(y)
        assert _rc == 17002
        cap gcollapse (p70) x, by(y) compress
        assert _rc == 17004
    }

    * https://github.com/mcaceresb/stata-gtools/issues/38
    qui {
        clear
        set obs 5
        gen x = _n
        gcollapse (p70) x
        assert x == 4

        clear
        set obs 5
        gen x = _n
        gcollapse (p80) x
        assert x == 4.5

        clear
        set obs 5
        gen x = _n
        gcollapse (p80.0001) x
        assert x == 5

        clear
        set obs 3
        gen x = _n
        gcollapse (p50) x
        assert x == 2

        clear
        set obs 3
        gen x = _n
        gcollapse (p66.6) x
        assert x == 2

        clear
        set obs 3
        gen x = _n
        gcollapse (p66.7) x
        assert x == 3
    }

    * https://github.com/mcaceresb/stata-gtools/issues/32
    qui {
        clear
        sysuse auto
        set varabbrev on
        gcollapse head = head
        set varabbrev off
    }

    qui {
        clear
        set obs 10
        gen x = .
        gcollapse (sum) y = x, merge missing
        gcollapse (sum) z = x, merge
        assert y == .
        assert z == 0
    }

    * https://github.com/mcaceresb/stata-gtools/issues/27
    qui {
        clear
        set obs 10
        gen xxx = 1
        set varabbrev on
        cap confirm xx
        gcollapse xx = xxx
        cap confirm x
        set varabbrev off
    }

    qui {
        sysuse auto, clear
        gen price2 = price
        cap noi gcollapse price = price2 if price < 0
        assert _rc == 2000
    }

    qui {
        sysuse auto, clear
        gen price2 = price
        gcollapse price = price2
    }

    qui {
        sysuse auto, clear
        gen price2 = price
        gcollapse price = price2, by(make) v bench `options'
        gcollapse price in 1,     by(make) v bench `options'
    }

    qui {
        clear
        set matsize 100
        set obs 10
        forvalues i = 1/101 {
            gen x`i' = 10
        }
        gen zz = runiform()
        preserve
            gcollapse zz, by(x*) `options'
        restore, preserve
            gcollapse x*, by(zz) `options'
        restore
    }

    qui {
        clear
        set matsize 400
        set obs 10
        forvalues i = 1/300 {
            gen x`i' = 10
        }
        gen zz = runiform()
        preserve
            gcollapse zz, by(x*) `options'
        restore, preserve
            gcollapse x*, by(zz) `options'
        restore
    }

    qui {
        clear
        set obs 10
        forvalues i = 1/800 {
            gen x`i' = 10
        }
        gen zz = runiform()
        preserve
            gcollapse zz, by(x*) `options'
        restore, preserve
            gcollapse x*, by(zz) `options'
        restore

        * Only fails in Stata/IC
        * gen x801 = 10
        * preserve
        *     collapse zz, by(x*) `options'
        * restore, preserve
        *     collapse x*, by(zz) `options'
        * restore
    }

    di ""
    di as txt "Passed! checks_corners `options'"
end

***********************************************************************
*                               Compare                               *
***********************************************************************

capture program drop compare_gcollapse
program compare_gcollapse
    syntax, [tol(real 1e-6) NOIsily *]

    * This should be ignored for compare_inner_gcollapse_gegen bc of merge
    local debug_io debug_io_check(0) debug_io_threshold(0.0001)

    qui `noisily' gen_data, n(500)
    qui expand 100
    qui `noisily' random_draws, random(2)

    di _n(1) "{hline 80}" _n(1) "consistency_gcollapse_gegen, `options'" _n(1) "{hline 80}" _n(1)

    compare_inner_gcollapse_gegen, `options' tol(`tol')

    compare_inner_gcollapse_gegen -str_12,              `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_gegen str_12 -str_32,       `options' tol(`tol') sort
    compare_inner_gcollapse_gegen str_12 -str_32 str_4, `options' tol(`tol') shuffle

    compare_inner_gcollapse_gegen -double1,                 `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_gegen double1 -double2,         `options' tol(`tol') sort
    compare_inner_gcollapse_gegen double1 -double2 double3, `options' tol(`tol') shuffle

    compare_inner_gcollapse_gegen -int1,           `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_gegen int1 -int2,      `options' tol(`tol') sort
    compare_inner_gcollapse_gegen int1 -int2 int3, `options' tol(`tol') shuffle

    compare_inner_gcollapse_gegen -int1 -str_32 -double1, `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_gegen int1 -str_32 double1 -int2 str_12 -double2, `options' tol(`tol') sort
    compare_inner_gcollapse_gegen int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options' tol(`tol') shuffle

    qui `noisily' gen_data, n(500)
    qui expand 50
    qui `noisily' random_draws, random(2) binary(5)

    di _n(1) "{hline 80}" _n(1) "consistency_gcollapse_select_etc, `options'" _n(1) "{hline 80}" _n(1)

    compare_inner_gcollapse_select -str_12,              `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_select str_12 -str_32,       `options' tol(`tol') sort
    compare_inner_gcollapse_select str_12 -str_32 str_4, `options' tol(`tol') shuffle

    compare_inner_gcollapse_select -double1,                 `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_select double1 -double2,         `options' tol(`tol') sort
    compare_inner_gcollapse_select double1 -double2 double3, `options' tol(`tol') shuffle

    compare_inner_gcollapse_select -int1,           `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_select int1 -int2,      `options' tol(`tol') sort
    compare_inner_gcollapse_select int1 -int2 int3, `options' tol(`tol') shuffle

    compare_inner_gcollapse_select int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options' tol(`tol') shuffle

    di _n(1) "{hline 80}" _n(1) "consistency_gcollapse_skew_kurt, `options'" _n(1) "{hline 80}" _n(1)

    compare_inner_gcollapse_skew, `options' tol(`tol')

    compare_inner_gcollapse_skew -str_12,              `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_skew str_12 -str_32,       `options' tol(`tol') sort
    compare_inner_gcollapse_skew str_12 -str_32 str_4, `options' tol(`tol') shuffle

    compare_inner_gcollapse_skew -double1,                 `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_skew double1 -double2,         `options' tol(`tol') sort
    compare_inner_gcollapse_skew double1 -double2 double3, `options' tol(`tol') shuffle

    compare_inner_gcollapse_skew -int1,           `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_skew int1 -int2,      `options' tol(`tol') sort
    compare_inner_gcollapse_skew int1 -int2 int3, `options' tol(`tol') shuffle

    compare_inner_gcollapse_skew -int1 -str_32 -double1, `options' tol(`tol') `debug_io'
    compare_inner_gcollapse_skew int1 -str_32 double1 -int2 str_12 -double2, `options' tol(`tol') sort
    compare_inner_gcollapse_skew int1 -str_32 double1 -int2 str_12 -double2 int3 -str_4 double3, `options' tol(`tol') shuffle

    qui `noisily' gen_data, n(500)
    qui expand 50
    qui `noisily' random_draws, random(2) binary(5)

    di _n(1) "{hline 80}" _n(1) "consistency_collapse, `options'" _n(1) "{hline 80}" _n(1)

    compare_inner_collapse, `options' tol(`tol')

    compare_inner_collapse str_12,              `options' tol(`tol') forcemem sort
    compare_inner_collapse str_12 str_32,       `options' tol(`tol') forceio shuffle
    compare_inner_collapse str_12 str_32 str_4, `options' tol(`tol') `debug_io'

    compare_inner_collapse double1,                 `options' tol(`tol') forcemem
    compare_inner_collapse double1 double2,         `options' tol(`tol') forceio sort
    compare_inner_collapse double1 double2 double3, `options' tol(`tol') `debug_io' shuffle

    compare_inner_collapse int1,           `options' tol(`tol') forcemem shuffle
    compare_inner_collapse int1 int2,      `options' tol(`tol') forceio
    compare_inner_collapse int1 int2 int3, `options' tol(`tol') `debug_io' sort

    compare_inner_collapse int1 str_32 double1,                                        `options' tol(`tol') forcemem
    compare_inner_collapse int1 str_32 double1 int2 str_12 double2,                    `options' tol(`tol') forceio
    compare_inner_collapse int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options' tol(`tol') `debug_io'
end

***********************************************************************
*                            Compare gegen                            *
***********************************************************************

capture program drop compare_inner_gcollapse_gegen
program compare_inner_gcollapse_gegen
    syntax [anything], [tol(real 1e-6) sort shuffle wgt(str) *]

    gettoken wfun wfoo: wgt
    local wfun `wfun'
    local wfoo `wfoo'
    if ( `"`wfoo'"' == "mix" ) {
        local wgen_a  qui gen unif_0_100 = 100 * runiform() if mod(_n, 100)
        local wcall_a "[aw = unif_0_100]"
        local wgen_f  qui gen int_unif_0_100 = int(100 * runiform()) if mod(_n, 100)
        local wcall_f "[fw = int_unif_0_100]"
        local wgen_p  qui gen float_unif_0_1 = runiform() if mod(_n, 100)
        local wcall_p "[pw = float_unif_0_1]"
        local wgen_i  qui gen rnormal_0_10 = 10 * rnormal() if mod(_n, 100)
        local wcall_i "[iw = rnormal_0_10]"
    }
    else {
        local wgt wgt(`wgt')
    }

    tempvar rsort
    if ( "`shuffle'" != "" ) gen `rsort' = runiform()
    if ( "`shuffle'" != "" ) sort `rsort'
    if ( ("`sort'" != "") & ("`anything'" != "") ) qui hashsort `anything'

    local N = trim("`: di %15.0gc _N'")
    local hlen = 45 + length("`anything'") + length("`N'")
    di _n(2) "Checking gegen vs gcollapse. N = `N'; varlist = `anything'" _n(1) "{hline `hlen'}"

    preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_a'
            local wgt wgt(both `wcall_a')
        }
        _compare_inner_gcollapse_gegen `anything', `options' tol(`tol') `wgt'
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_f'
            local wgt wgt(both `wcall_f')
        }
        if ( "`shuffle'" != "" ) sort `rsort'
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_gcollapse_gegen  `anything' in `from' / `to', `options' `wgt' tol(`tol')
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_i'
            local wgt wgt(both `wcall_i')
        }
        _compare_inner_gcollapse_gegen `anything' if random2 > 0, `options' `wgt' tol(`tol')
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_p'
            local wgt wgt(both `wcall_p')
        }
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_gcollapse_gegen `anything' if random2 < 0 in `from' / `to', `options' `wgt' tol(`tol')
    restore
end

capture program drop _compare_inner_gcollapse_gegen
program _compare_inner_gcollapse_gegen
    syntax [anything] [if] [in], [tol(real 1e-6) wgt(str) *]

    gettoken wfun wgt: wgt
    local wgt `wgt'

    if ( "`wgt'" != "" ) {
        if inlist("`wfun'", "both", "g") {
            local wgt_gc `wgt'
        }
        if inlist("`wfun'", "both", "c") {
            local wgt_ge `wgt'
        }
        if ( "`wfun'" == "both" ) {
            local wtxt " `wgt'"
        }
        else if ( "`wfun'" == "g" ) {
            local wtxt " `wgt' (gcollapse only)"
        }
        else if ( "`wfun'" == "c" ) {
            local wtxt " `wgt' (gegen only)"
        }
    }

    local ifin `if' `in'
    local anything_ `anything'
    local options_  `options'
    local 0 `wgt'
    syntax [aw fw iw pw]
    local anything `anything_'
    local options  `options_'

    local sestats
    local stats nunique nmissing sum mean geomean max min range percent first last firstnm lastnm median iqr skew kurt gini gini|dropneg gini|keepneg
    if ( !inlist("`weight'", "pweight") ) {
        local stats   `stats'   sd variance cv
        local sestats `sestats' sd variance cv
    }
    if ( !inlist("`weight'", "pweight", "iweight") ) {
        local stats   `stats'   semean
        local sestats `sestats' semean
    }
    if (  inlist("`weight'", "fweight", "") ) {
        local stats   `stats'   sebinomial sepoisson
        local sestats `sestats' sebinomial sepoisson
    }

    if ( `"`anything'"' == "" ) {
        gen id = 1
    }
    else {
        gegen id = group(`anything'), missing nods
    }

    gegen double nmissing     = nmissing    (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double nunique      = nunique     (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double percent      = percent     (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double mean         = mean        (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double sum          = sum         (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double median       = median      (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double min          = min         (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double max          = max         (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double range        = range       (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double iqr          = iqr         (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double first        = first       (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double last         = last        (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double firstnm      = firstnm     (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double lastnm       = lastnm      (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double skew         = skew        (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double kurt         = kurt        (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double geomean      = geomean     (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double gini         = gini        (random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double gini_keepneg = gini|keepneg(random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double gini_dropneg = gini|dropneg(random1) `ifin' `wgt_ge',  by(`anything') nods
    gegen double q10          = pctile      (random1) `ifin' `wgt_ge',  by(`anything') nods p(10.5)
    gegen double q30          = pctile      (random1) `ifin' `wgt_ge',  by(`anything') nods p(30)
    gegen double q70          = pctile      (random1) `ifin' `wgt_ge',  by(`anything') nods p(70)
    gegen double q90          = pctile      (random1) `ifin' `wgt_ge',  by(`anything') nods p(90.5)
    if ( !inlist("`weight'", "iweight") ) {
    gegen double s1           = select      (random1) `ifin' `wgt_ge',  by(`anything') nods n(1)
    gegen double s3           = select      (random1) `ifin' `wgt_ge',  by(`anything') nods n(3)
    gegen double s999999      = select      (random1) `ifin' `wgt_ge',  by(`anything') nods n(999999)
    gegen double s_999999     = select      (random1) `ifin' `wgt_ge',  by(`anything') nods n(-999999)
    gegen double s_3          = select      (random1) `ifin' `wgt_ge',  by(`anything') nods n(-3)
    gegen double s_1          = select      (random1) `ifin' `wgt_ge',  by(`anything') nods n(-1)
    }

    local gextra
    foreach extra of local sestats {
        gegen double `extra' = `extra'(random1) `ifin' `wgt_ge',  by(`anything') nods
        local gextra `gextra' (`extra') g_`extra' = random1
    }

    if ( inlist("`weight'", "iweight") ) {
        qui `noisily' {
            gcollapse (nmissing)      g_nmissing     = random1 ///
                      (nunique)       g_nunique      = random1 ///
                      (percent)       g_percent      = random1 ///
                      (mean)          g_mean         = random1 ///
                      (sum)           g_sum          = random1 ///
                      (median)        g_median       = random1 ///
                      (min)           g_min          = random1 ///
                      (max)           g_max          = random1 ///
                      (range)         g_range        = random1 ///
                      (iqr)           g_iqr          = random1 ///
                      (first)         g_first        = random1 ///
                      (last)          g_last         = random1 ///
                      (firstnm)       g_firstnm      = random1 ///
                      (lastnm)        g_lastnm       = random1 ///
                      (skew)          g_skew         = random1 ///
                      (kurt)          g_kurt         = random1 ///
                      (geomean)       g_geomean      = random1 ///
                      (gini)          g_gini         = random1 ///
                      (gini|dropneg)  g_gini_dropneg = random1 ///
                      (gini|keepneg)  g_gini_keepneg = random1 ///
                      (p10.5)         g_q10          = random1 ///
                      (p30)           g_q30          = random1 ///
                      (p70)           g_q70          = random1 ///
                      (p90.5)         g_q90          = random1 ///
                      `gextra'                               ///
                  `ifin' `wgt_gc', by(id) benchmark verbose `options' merge double
         }
    else {
        qui `noisily' {
            gcollapse (nmissing)      g_nmissing     = random1 ///
                      (nunique)       g_nunique      = random1 ///
                      (percent)       g_percent      = random1 ///
                      (mean)          g_mean         = random1 ///
                      (sum)           g_sum          = random1 ///
                      (median)        g_median       = random1 ///
                      (min)           g_min          = random1 ///
                      (max)           g_max          = random1 ///
                      (range)         g_range        = random1 ///
                      (iqr)           g_iqr          = random1 ///
                      (first)         g_first        = random1 ///
                      (last)          g_last         = random1 ///
                      (firstnm)       g_firstnm      = random1 ///
                      (lastnm)        g_lastnm       = random1 ///
                      (skew)          g_skew         = random1 ///
                      (kurt)          g_kurt         = random1 ///
                      (geomean)       g_geomean      = random1 ///
                      (gini)          g_gini         = random1 ///
                      (gini|dropneg)  g_gini_dropneg = random1 ///
                      (gini|keepneg)  g_gini_keepneg = random1 ///
                      (p10.5)         g_q10          = random1 ///
                      (p30)           g_q30          = random1 ///
                      (p70)           g_q70          = random1 ///
                      (p90.5)         g_q90          = random1 ///
                      (select1)       g_s1           = random1 ///
                      (select3)       g_s3           = random1 ///
                      (select999999)  g_s999999      = random1 ///
                      (select-999999) g_s_999999     = random1 ///
                      (select-3)      g_s_3          = random1 ///
                      (select-1)      g_s_1          = random1 ///
                      `gextra'                               ///
                  `ifin' `wgt_gc', by(id) benchmark verbose `options' merge double
        }
    }

    if ( "`ifin'" == "" ) {
        di _n(1) "Checking full range`wtxt': `anything'"
    }
    else if ( "`ifin'" != "" ) {
        di _n(1) "Checking [`ifin']`wtxt' range: `anything'"
    }

    foreach _fun in `stats' q10 q30 q70 q90 {
        local fun: subinstr local _fun "|" "_", all
        cap noi assert (g_`fun' == `fun') | ((abs(g_`fun' - `fun') / min(abs(g_`fun'), abs(`fun'))) < `tol')
        if ( _rc ) {
            if inlist("`fun'", "skew", "kurt") {
                local a1 ((g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol')
                local a2 (inlist(g_`fun', 1, -1) & mi(`fun'))
                local a3 (inlist(`fun', 1, -1)   & mi(g_`fun'))
                local a4 (nunique == 1)
                cap noi assert `a1' | ((`a2' | `a3') & `a4')
                if ( _rc ) {
                    di as err "    compare_gegen_gcollapse (failed): `fun'`wtxt' yielded different results (tol = `tol')"
                    keep `ifin'
                    keep if !(`a1' | ((`a2' | `a3') & `a4'))
                    * save /tmp/xx, replace
                    exit _rc
                }
                else di as txt "    compare_gegen_gcollapse (imprecision): `fun'`wtxt' yielded similar results (tol = `tol')"
            }
            else {
                recast double g_`fun' `fun'
                cap noi assert (g_`fun' == `fun') | ((abs(g_`fun' - `fun') / min(abs(g_`fun'), abs(`fun'))) < `tol')
                if ( _rc ) {
                    di as err "    compare_gegen_gcollapse (failed): `fun'`wtxt' yielded different results (tol = `tol')"
                    * save /tmp/xx, replace
                    exit _rc
                }
                else di as txt "    compare_gegen_gcollapse (passed): `fun'`wtxt' yielded same results (tol = `tol')"
            }
        }
        else di as txt "    compare_gegen_gcollapse (passed): `fun'`wtxt' yielded same results (tol = `tol')"
    }
end

***********************************************************************
*                          Compare collapse                           *
***********************************************************************

capture program drop compare_inner_collapse
program compare_inner_collapse
    syntax [anything], [tol(real 1e-6) sort shuffle wgt(str) *]

    gettoken wfun wfoo: wgt
    local wfun `wfun'
    local wfoo `wfoo'
    if ( `"`wfoo'"' == "mix" ) {
        local wgen_a  qui gen unif_0_100 = 100 * runiform() if mod(_n, 100)
        local wcall_a "[aw = unif_0_100]"
        local wgen_f  qui gen int_unif_0_100 = int(100 * runiform())
        local wcall_f "[fw = int_unif_0_100]"
        local wgen_i  qui gen rnormal_0_10 = 10 * rnormal()
        local wcall_i "[iw = rnormal_0_10]"
        local wgen_p  qui gen float_unif_0_1 = runiform()
        local wcall_p "[pw = float_unif_0_1]"
    }
    else {
        local wgt wgt(`wgt')
    }

    tempvar rsort
    if ( "`shuffle'" != "" ) gen `rsort' = runiform()
    if ( "`shuffle'" != "" ) sort `rsort'
    if ( ("`sort'" != "") & ("`anything'" != "") ) qui hashsort `anything'

    local N = trim("`: di %15.0gc _N'")
    local hlen = 35 + length("`anything'") + length("`N'")
    di _n(2) "Checking collapse. N = `N'; varlist = `anything'" _n(1) "{hline `hlen'}"

    preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_a'
            local wgt wgt(both `wcall_a')
        }
        _compare_inner_collapse `anything', `options' `wgt' tol(`tol')
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_f'
            local wgt wgt(both `wcall_f')
        }
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_collapse  `anything' in `from' / `to', `options' `wgt' tol(`tol')
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_i'
            local wgt wgt(both `wcall_i')
        }
        _compare_inner_collapse `anything' if random2 > 0, `options' `wgt' tol(`tol')
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_p'
            local wgt wgt(both `wcall_p')
        }
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_collapse `anything' if random2 < 0 in `from' / `to', `options' `wgt' tol(`tol')
    restore
end

capture program drop _compare_inner_collapse
program _compare_inner_collapse
    syntax [anything] [if] [in], [tol(real 1e-6) wgt(str) *]

    gettoken wfun wgt: wgt
    local wgt `wgt'

    if ( "`wgt'" != "" ) {
        if inlist("`wfun'", "both", "g") {
            local wgt_gc `wgt'
        }
        if inlist("`wfun'", "both", "c") {
            local wgt_ge `wgt'
        }
        if ( "`wfun'" == "both" ) {
            local wtxt " `wgt'"
        }
        else if ( "`wfun'" == "g" ) {
            local wtxt " `wgt' (gcollapse only)"
        }
        else if ( "`wfun'" == "c" ) {
            local wtxt " `wgt' (collapse only)"
        }
    }

    local ifin `if' `in'
    local anything_ `anything'
    local options_  `options'
    local 0 `wgt'
    syntax [aw fw iw pw]
    local anything `anything_'
    local options  `options_'

    local stats sum mean max min count first last firstnm lastnm median iqr
    if ( !inlist("`weight'", "pweight") )            local stats `stats' sd
    if ( !inlist("`weight'", "pweight", "iweight") ) local stats `stats' semean
    if (  inlist("`weight'", "fweight", "") )        local stats `stats' sebinomial sepoisson

    local percentiles p1 p13 p30 p50 p70 p87 p99
    local collapse_str ""
    local k1 ""
    local k2 ""
    local k3 ""

    foreach pct of local percentiles {
        local k1 `k1' r1_`pct'
        local collapse_str `collapse_str' (`pct') r1_`pct' = random1
    }
    foreach stat of local stats {
        local k1 `k1' r1_`stat'
        local collapse_str `collapse_str' (`stat') r1_`stat' = random1
    }
    foreach pct of local percentiles {
        local k2 `k2' r2_`pct'
        local collapse_str `collapse_str' (`pct') r2_`pct' = random2
    }
    foreach stat of local stats {
        local k2 `k2' r2_`stat'
        local collapse_str `collapse_str' (`stat') r2_`stat' = random2
    }
    local k3 r1_percent r2_percent
    local collapse_str `collapse_str' (percent) r1_percent = random1 r2_percent = random2

    if ( "`wgt'" == "" ) {
        local freq freq(freq)
        local wgt_gc [fw = 42]
    }

    local sopts by(`anything') verbose benchmark `options' `freq'
    preserve
        qui `noisily' gcollapse `collapse_str' `ifin' `wgt_gc', `sopts' rawstat(`k1')
        if ( "`wgt'" == "" ) {
            drop `k2'
        }
        else {
            drop `k1'
        }
        tempfile fg1
        qui save `fg1'
    restore, preserve
        qui `noisily' gcollapse `collapse_str' `ifin' `wgt_gc', `sopts' rawstat(`k2')
        if ( "`wgt'" == "" ) {
            drop `k1'
        }
        else {
            drop `k2'
        }
        tempfile fg2
        qui save `fg2'
    restore, preserve
        use `fg1', clear
            qui ds *
            local mergevars `r(varlist)'
            local mergevars: list mergevars - k1
            local mergevars: list mergevars - k2
            local mergevars: list mergevars - k3
            if ( "`mergevars'" == "" ) {
                local mergevars _n
            }
            qui merge 1:1 `mergevars' using `fg2', assert(3) nogen
        tempfile fg
        qui save `fg'
    restore

    preserve
        if ( "`wgt'" == "" ) {
            qui gen long freq = 1
            qui `noisily' collapse `collapse_str' (sum) freq `ifin' `wgt_ge', by(`anything')
        }
        else {
            qui `noisily' collapse `collapse_str' `ifin' `wgt_ge', by(`anything')
        }
        tempfile fc
        qui save `fc'
    restore

    preserve
    use `fc', clear
        local bad_any = 0
        local bad `anything'
        local by  `anything'
        foreach var in `stats' `percentiles' {
            rename r1_`var' c_r1_`var'
            rename r2_`var' c_r2_`var'
        }
        cap rename freq c_freq
        if ( "`by'" == "" ) {
            qui merge 1:1 _n using `fg', assert(3)
        }
        else {
            qui merge 1:1 `by' using `fg', assert(3)
        }
        foreach var in `stats' `percentiles' {

            * I am not entirely sure why this check is here. I figured
            * it had to be a corner case where I might return . and
            * stata 0 or the converse... Not 100% why that changes if
            * there is a weight, where it failed.

            if inlist("`var'", "sd", "semean") {
                local nonz1 & (r1_`var' != 0 & c_r1_`var' != .) & (r1_`var' != . & c_r1_`var' != 0)
                local nonz2 & (r2_`var' != 0 & c_r2_`var' != .) & (r2_`var' != . & c_r2_`var' != 0)
            }
            else {
                local nonz1
                local nonz2
            }

            qui count if ( (abs(r1_`var' - c_r1_`var') > `tol') & (r1_`var' != c_r1_`var')) `nonz1'
            if ( `r(N)' > 0 ) {
                gen bad_r1_`var' = abs(r1_`var' - c_r1_`var') * (r1_`var' != c_r1_`var')
                local bad `bad' *r1_`var'
                di "    r1_`var' has `:di r(N)' mismatches".
                local bad_any = 1
                order *r1_`var'
            }

            qui count if ( (abs(r2_`var' - c_r2_`var') > `tol') & (r2_`var' != c_r2_`var')) `nonz2'
            if ( `r(N)' > 0 ) {
                gen bad_r2_`var' = abs(r2_`var' - c_r2_`var') * (r2_`var' != c_r2_`var')
                local bad `bad' *r2_`var'
                di "    r2_`var' has `:di r(N)' mismatches".
                local bad_any = 1
                order *r2_`var'
            }
        }
        if ( "`wgt'" == "" ) {
            qui count if ( (abs(freq - c_freq) > `tol') & (freq != c_freq))
            if ( `r(N)' > 0 ) {
                gen bad_freq = abs(freq - c_freq) * (freq != c_freq)
                local bad `bad' *freq
                di "    freq has `:di r(n)' mismatches".
                local bad_any = 1
                order *freq
            }
        }
        if ( `bad_any' ) {
            if ( "`ifin'" == "" ) {
                di "    compare_collapse (failed): full range`wtxt', `anything'"
            }
            else if ( "`ifin'" != "" ) {
                di "    compare_collapse (failed): [`ifin']`wtxt', `anything'"
            }
            order `bad'
            egen bad_any = rowmax(bad_*)
            * l *count* *mean* `bad' if bad_any
            sum bad_*
            desc
            exit 9
        }
        else {
            if ( "`ifin'" == "" ) {
                di "    compare_collapse (passed): full range`wtxt', gcollapse results equal to collapse (tol = `tol')"
            }
            else if ( "`ifin'" != "" ) {
                di "    compare_collapse (passed): [`ifin']`wtxt', gcollapse results equal to collapse (tol = `tol')"
            }
        }
    restore
end

***********************************************************************
*                           Check skewness                            *
***********************************************************************

capture program drop compare_inner_gcollapse_skew
program compare_inner_gcollapse_skew
    syntax [anything], [tol(real 1e-6) sort shuffle wgt(str) *]

    * iw and pw not allowed in -sum, detail-

    gettoken wfun wfoo: wgt
    local wfun `wfun'
    local wfoo `wfoo'
    if ( `"`wfoo'"' == "mix" ) {
        local wgen_a  qui gen unif_0_100 = 100 * runiform() if mod(_n, 100)
        local wcall_a "[aw = unif_0_100]"
        local wgen_f  qui gen int_unif_0_100 = int(100 * runiform()) if mod(_n, 100)
        local wcall_f "[fw = int_unif_0_100]"
        local wgen_p  `wgen_a'
        local wcall_p `wcall_a'
        local wgen_i  `wgen_f'
        local wcall_i `wcall_f'
    }
    else {
        local wgt wgt(`wgt')
    }

    tempvar rsort
    if ( "`shuffle'" != "" ) gen `rsort' = runiform()
    if ( "`shuffle'" != "" ) sort `rsort'
    if ( ("`sort'" != "") & ("`anything'" != "") ) qui hashsort `anything'

    local N = trim("`: di %15.0gc _N'")
    local hlen = 45 + length("`anything'") + length("`N'")
    di _n(2) "Checking skewness and kurtosis. N = `N'; varlist = `anything'" _n(1) "{hline `hlen'}"

    preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_a'
            local wgt wgt(both `wcall_a')
        }
        _compare_inner_gcollapse_skew `anything', `options' tol(`tol') `wgt'
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_f'
            local wgt wgt(both `wcall_f')
        }
        if ( "`shuffle'" != "" ) sort `rsort'
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_gcollapse_skew  `anything' in `from' / `to', `options' `wgt' tol(`tol')
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_i'
            local wgt wgt(both `wcall_i')
        }
        _compare_inner_gcollapse_skew `anything' if random2 > 0, `options' `wgt' tol(`tol')
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_p'
            local wgt wgt(both `wcall_p')
        }
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_gcollapse_skew `anything' if random2 < 0 in `from' / `to', `options' `wgt' tol(`tol')
    restore
end

capture program drop _compare_inner_gcollapse_skew
program _compare_inner_gcollapse_skew
    syntax [anything] [if] [in], [tol(real 1e-6) wgt(str) *]

    gettoken wfun wgt: wgt
    local wgt `wgt'

    if ( "`wgt'" != "" ) {
        if inlist("`wfun'", "both", "g") {
            local wgt_gc `wgt'
        }
        if inlist("`wfun'", "both", "c") {
            local wgt_ge `wgt'
        }
        if ( "`wfun'" == "both" ) {
            local wtxt " `wgt'"
        }
        else if ( "`wfun'" == "g" ) {
            local wtxt " `wgt' (gcollapse only)"
        }
        else if ( "`wfun'" == "c" ) {
            local wtxt " `wgt' (gegen only)"
        }
    }

    local ifin `in' `if'
    if ( `"`if'"' == "" ) {
        local sifin `in' if id ==
    }
    else {
        local sifin `in' `if' & id ==
    }

    local anything_ `anything'
    local options_   `options'
    local 0 `wgt'
    syntax [aw fw iw pw]
    local anything `anything_'
    local options  `options_'

    if ( `"`anything'"' == "" ) {
        qui gen id = 1 `ifin'
    }
    else {
        qui gegen id = group(`anything') `ifin', missing nods
    }

    qui gunique id `ifin', missing
    local J = `r(J)'
    qui sum id
    local maxid = `r(max)'
    * gquantiles id, pctile(idlevel) cutpoints(id) dedup

    local checks
    forvalues i = 1 / 10 {
        local j = ceil(runiform() * `J')
        qui sum random1 `sifin' `j' `wgt_gc', d
        local sd_`j'   = r(sd)
        local skew_`j' = r(skewness)
        local kurt_`j' = r(kurtosis)
        local checks `checks' `j'
    }

    qui sum random1 `sifin' `maxid' `wgt_gc', d
    local sd_`maxid'   = r(sd)
    local skew_`maxid' = r(skewness)
    local kurt_`maxid' = r(kurtosis)
    local checks `checks' `maxid'

    qui gcollapse (skew) skew  = random1 ///
                  (kurt) kurt  = random1 ///
                  (nunique) nq = random1 ///
        `ifin' `wgt_gc', by(id) benchmark verbose `options' double freq(f)

    if ( "`ifin'" == "" ) {
        di _n(1) "Checking full range`wtxt': `anything'"
    }
    else if ( "`ifin'" != "" ) {
        di _n(1) "Checking [`ifin']`wtxt' range: `anything'"
    }

    * For skewness and kurtosis, numerical imprecision can cause the
    * result to be -1 or 1 when it should really be missing. Internally
    * 0 / 0 is computed as ε / ε for some ε small.

    tempvar ix
    gen `ix' = _n
    foreach fun in kurt skew {
        local imprecise 0
        foreach j in `checks' {
            local ok 1
            if ( `j' != `=id[`j']' ) {
                qui sum `ix' if id == `j'
                if ( `r(N)' == 0 ) {
                    cap assert ``fun'_`j'' == . | "``fun'_`j''" == ""
                    if ( _rc ) {
                        di as txt "    compare_`fun'_gcollapse (failed): sum`wtxt' yielded a result and gcollapse did not"
                        exit _rc
                    }
                    local ok 0
                }
                local jj = `ix'[r(min)]
            }
            else local jj `j'

            if ( `ok' ) {
                cap assert ``fun'_`j'' == `fun'[`jj'] | abs(``fun'_`j'' - `fun'[`jj']) < `tol'
                if ( _rc & (nq[`j'] > 1) ) {
                    cap noi assert 0
                    di as err "    compare_`fun'_gcollapse (failed): sum`wtxt' yielded different results (tol = `tol')"
                    disp "``fun'_`j'' vs `=`fun'[`j']'; diff `=abs(``fun'_`j'' - `fun'[`j'])', N = `=f[`j']'"
                    exit _rc
                }
                else if ( _rc & (nq[`j'] == 1) ) {
                    local ++imprecise
                }
            }
        }

        if ( `imprecise' ) {
            di as txt "    compare_`fun'_gcollapse (imprecision): sum`wtxt' yielded similar results (tol = `tol'; `imprecise' imprecisions)"
        }
        else {
            di as txt "    compare_`fun'_gcollapse (passed): sum`wtxt' yielded same results (tol = `tol')"
        }
    }
end

***********************************************************************
*                      Check new stats from 1.4                       *
***********************************************************************

capture program drop compare_inner_gcollapse_select
program compare_inner_gcollapse_select
    syntax [anything], [tol(real 1e-6) sort shuffle wgt(str) *]

    gettoken wfun wfoo: wgt
    local wfun `wfun'
    local wfoo `wfoo'
    if ( `"`wfoo'"' == "mix" ) {
        local wgen_a  qui gen unif_0_100 = 100 * runiform() if mod(_n, 100)
        local wcall_a "[aw = unif_0_100]"
        local wgen_f  qui gen int_unif_0_100 = int(100 * runiform()) if mod(_n, 100)
        local wcall_f "[fw = int_unif_0_100]"
        local wgen_p  qui gen float_unif_0_1 = runiform() if mod(_n, 100)
        local wcall_p "[pw = float_unif_0_1]"
        local wgen_i  `wgen_f'
        local wcall_i `wcall_f'
    }
    else {
        local wgt wgt(`wgt')
    }

    tempvar rsort
    if ( "`shuffle'" != "" ) gen `rsort' = runiform()
    if ( "`shuffle'" != "" ) sort `rsort'
    if ( ("`sort'"   != "") & ("`anything'" != "") ) qui hashsort `anything'

    local N = trim("`: di %15.0gc _N'")
    local hlen = 47 + length("`anything'") + length("`N'")
    di _n(2) "Checking select and 1.4+ funcs. N = `N'; varlist = `anything'" _n(1) "{hline `hlen'}"

    preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_a'
            local wgt wgt(both `wcall_a')
        }
        _compare_inner_gcollapse_select `anything', `options' tol(`tol') `wgt'
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_f'
            local wgt wgt(both `wcall_f')
        }
        if ( "`shuffle'" != "" ) sort `rsort'
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_gcollapse_select  `anything' in `from' / `to', `options' `wgt' tol(`tol')
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_i'
            local wgt wgt(both `wcall_i')
        }
        _compare_inner_gcollapse_select `anything' if random2 > 0, `options' `wgt' tol(`tol')
    restore, preserve
        if ( `"`wfoo'"' == "mix" ) {
            `wgen_p'
            local wgt wgt(both `wcall_p')
        }
        local in1 = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2 = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        _compare_inner_gcollapse_select `anything' if random2 < 0 in `from' / `to', `options' `wgt' tol(`tol')
    restore
end

capture program drop _compare_inner_gcollapse_select
program _compare_inner_gcollapse_select
    syntax [anything] [if] [in], [tol(real 1e-6) wgt(str) *]

    gettoken wfun wgt: wgt
    local wgt `wgt'

    if ( "`wgt'" != "" ) {
        if inlist("`wfun'", "both", "g") {
            local wgt_gc `wgt'
        }
        if inlist("`wfun'", "both", "c") {
            local wgt_ge `wgt'
        }
        if ( "`wfun'" == "both" ) {
            local wtxt " `wgt'"
        }
        else if ( "`wfun'" == "g" ) {
            local wtxt " `wgt' (gcollapse only)"
        }
        else if ( "`wfun'" == "c" ) {
            local wtxt " `wgt' (gegen only)"
        }
    }

    local ifin `in' `if'

    local gcall
    local gcall `gcall' (count)        nj           = random1
    local gcall `gcall' (mean)         mean         = random1
    local gcall `gcall' (geomean)      geomean      = random1
    local gcall `gcall' (gini)         gini         = random1
    local gcall `gcall' (gini|dropneg) gini_dropneg = random1
    local gcall `gcall' (gini|keepneg) gini_keepneg = random1
    if !regexm("pw", `"`wgt'"') {
    local gcall `gcall' (sd)           sd           = random1
    local gcall `gcall' (variance)     variance     = random1
    local gcall `gcall' (cv)           cv           = random1
    }                                               
    local gcall `gcall' (min)          min          = random1
    local gcall `gcall' (max)          max          = random1
    local gcall `gcall' (range)        range        = random1
    local gcall `gcall' (select1)      select1      = random1
    local gcall `gcall' (select2)      select2      = random1
    local gcall `gcall' (select3)      select3      = random1
    local gcall `gcall' (select9999)   select9999   = random1
    local gcall `gcall' (select-9999)  select_9999  = random1
    local gcall `gcall' (select-3)     select_3     = random1
    local gcall `gcall' (select-2)     select_2     = random1
    local gcall `gcall' (select-1)     select_1     = random1

    qui gcollapse `gcall' `ifin' `wgt_gc', by(`anything') `options' double merge replace
    if ( `"`anything'"' == "" ) {
        qui gen id = 1 `ifin'
    }
    else {
        qui gegen id = group(`anything') `ifin', missing nods
    }
    * save /tmp/aa, replace

    qui quickGini random1 `ifin' `wgt_gc', by(id) gen(_gini)
    qui quickGini random1 `ifin' `wgt_gc', by(id) gen(_gini_dropneg) dropneg
    qui quickGini random1 `ifin' `wgt_gc', by(id) gen(_gini_keepneg) keepneg
    foreach gini in " " _keepneg _dropneg {
        local gini `gini'
        cap assert reldif(_gini`gini', gini`gini') < `tol'
        local rc = _rc
        local gini: subinstr local gini "_" "|", all
        if ( `rc' ) {
            di as txt "    compare_gini`gini'_gcollapse (fail): gini`gini' yielded different results (tol = `tol')"
            exit 198
        }
        else {
            di as txt "    compare_gini`gini'_gcollapse (passed): gini`gini' yielded consistent results (tol = `tol')"
        }
    }

    if ( "`ifin'" == "" ) {
        di _n(1) "Checking full range`wtxt': `anything'"
    }
    else if ( "`ifin'" != "" ) {
        di _n(1) "Checking [`ifin']`wtxt' range: `anything'"
    }

    if !regexm("pw", `"`wgt'"') {
    cap assert (mi(cv) & (mi(sd) | (mean == 0))) | (abs((sd / mean) - cv) < `tol') `ifin'
        if ( _rc ) {
            di as txt "    compare_cv_gcollapse (fail): cv`wtxt' yielded different results (tol = `tol')"
            exit 198
        }
        else {
            di as txt "    compare_cv_gcollapse (passed): cv`wtxt' yielded consistent results (tol = `tol')"
        }
    }
    else {
            di as txt "    compare_cv_gcollapse (skip): cv`wtxt' skipped (not allowed with pweights)"
    }
    if !regexm("pw", `"`wgt'"') {
    cap assert (mi(variance) & mi(sd)) | (abs((sd^2 - variance) / min(sd^2, variance)) < `tol') `ifin'
        if ( _rc ) {
            di as txt "    compare_var_gcollapse (fail): var`wtxt' yielded different results (tol = `tol')"
            exit 198
        }
        else {
            di as txt "    compare_var_gcollapse (passed): var`wtxt' yielded consistent results (tol = `tol')"
        }
    }
    else {
            di as txt "    compare_var_gcollapse (skip): var`wtxt' skipped (not allowed with pweights)"
    }
    cap assert (mi(range) & (mi(min) | mi(max))) | (abs((range) - (max - min)) < `tol') `ifin'
        if ( _rc ) {
            di as txt "    compare_range_gcollapse (fail): range`wtxt' yielded different results (tol = `tol')"
            exit 198
        }
        else {
            di as txt "    compare_range_gcollapse (passed): range`wtxt' yielded consistent results (tol = `tol')"
        }

    if ( "`wgt'" != "" ) {
        qui {
            local 0 `wgt'
            syntax [aw fw iw pw]
            tempvar w wsum touse wsel
            mark `touse' `wgt' `ifin'
            markout `touse' random1
            keep if `touse'
            gen double `w' `exp'
            sort id random1 `w'
            by id (random1 `w'): gen double `wsum'  = sum(`w')
            gen long `wsel' = 0
        }
        foreach sel in 1 2 3 9999 {
            qui by id (random1 `w'): replace `wsel' = sum(`sel' > `wsum')
            cap by id (random1 `w'): assert (((abs(random1[`wsel'[_N] + 1] - select`sel') < `tol') | (mi(select`sel') & mi(random1[`wsel'[_N] + 1]))))
                if ( _rc ) {
                    di as txt "    compare_select`sel'_gcollapse (fail): select`wtxt' yielded different results (tol = `tol')"
                    exit 198
                }
                else {
                    di as txt "    compare_select`sel'_gcollapse (passed): select`wtxt' yielded consistent results (tol = `tol')"
                }
            qui by id (random1 `w'): replace `wsel' = cond(`wsum'[_N] - `sel' >= 0, sum((`wsum'[_N] - `sel') >= `wsum'), _N)
            cap by id (random1 `w'): assert (((abs(random1[`wsel'[_N] + 1] - select_`sel') < `tol') | (mi(select_`sel') & mi(random1[`wsel'[_N] + 1]))))
                if ( _rc ) {
                    di as txt "    compare_select-`sel'_gcollapse (fail): select`wtxt' yielded different results (tol = `tol')"
                    exit 198
                }
                else {
                    di as txt "    compare_select-`sel'_gcollapse (passed): select`wtxt' yielded consistent results (tol = `tol')"
                }
        }
    }
    else {
        if ( `"`ifin'"' != "" ) qui keep `ifin'
        sort id random1
        foreach sel in 1 2 3 9999 {
            cap by id (random1): assert (((abs(random1[`sel'] - select`sel') < `tol') | (mi(select`sel') & mi(random1[`sel'])))) 
                if ( _rc ) {
                    di as txt "    compare_select`sel'_gcollapse (fail): select`wtxt' yielded different results (tol = `tol')"
                    exit 198
                }
                else {
                    di as txt "    compare_select`sel'_gcollapse (passed): select`wtxt' yielded consistent results (tol = `tol')"
                }
            cap by id (random1): assert (((abs(random1[nj - `sel' + 1] - select_`sel') < `tol') | (mi(select_`sel') & mi(random1[nj - `sel' + 1]))))
                if ( _rc ) {
                    di as txt "    compare_select-`sel'_gcollapse (fail): select`wtxt' yielded different results (tol = `tol')"
                    exit 198
                }
                else {
                    di as txt "    compare_select-`sel'_gcollapse (passed): select`wtxt' yielded consistent results (tol = `tol')"
                }
        }
    }
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_collapse
program bench_collapse
    syntax, [tol(real 1e-6) bench(real 1) n(int 500) NOIsily style(str) vars(int 1) collapse fcollapse *]

    qui gen_data, n(`n')
    qui expand `=100 * `bench''
    qui `noisily' random_draws, random(`vars') double
    qui hashsort random1

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    if ( "`style'" == "full" ) {
        local ststr "all available plus percentiles 10, 30, 70, 90"
    }
    else if ( "`style'" == "ftools" ) {
        local ststr "mean median min max"
    }
    else {
        local ststr "sum"
    }

    if ( `vars' > 1 ) {
        local vstr "x1-x`vars'"
    }
    else {
        local vstr x1
    }

    di as txt _n(1)
    di as txt "Benchmark vs collapse (in seconds)"
    di as txt "    - obs:     `N'"
    di as txt "    - groups:  `J'"
    di as txt "    - vars:    `vstr' ~ N(0, 10)"
    di as txt "    - stats:   `ststr'"
    di as txt "    - options: fast"
    di as txt _n(1)
    di as txt "    collapse | fcollapse | gcollapse | ratio (c/g) | ratio (f/g) | varlist"
    di as txt "    -------- | --------- | --------- | ----------- | ----------- | -------"

    local options `options' style(`style') vars(`vars')
    versus_collapse,                         `options' `collapse' `fcollapse'
    versus_collapse str_12 str_32 str_4,     `options' `collapse' `fcollapse'
    versus_collapse double1 double2 double3, `options' `collapse' `fcollapse'
    versus_collapse int1 int2,               `options' `collapse' `fcollapse'
    versus_collapse int3 str_32 double1,     `options' `collapse'

    di _n(1) "{hline 80}" _n(1) "bench_collapse, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop versus_collapse
program versus_collapse, rclass
    syntax [anything], [fcollapse collapse style(str) vars(int 1) *]

    local stats       ""
    local percentiles ""

    if ( "`style'" == "full" ) {
        local stats sum mean sd max min count median iqr percent first last firstnm lastnm
        local percentiles p10 p30 p70 p90
    }
    else if ( "`style'" == "ftools" ) {
        local stats mean median min max
    }
    else {
        local stats sum
    }

    local collapse_str ""
    foreach stat of local stats {
        forvalues k = 1 / `vars' {
            local collapse_str `collapse_str' (`stat') r`k'_`stat' = random`k'
        }
    }
    foreach pct of local percentiles {
        forvalues k = 1 / `vars' {
            local collapse_str `collapse_str' (`pct') r`k'_`pct' = random`k'
        }
    }

    if ( "`collapse'" == "collapse" ) {
    preserve
        timer clear
        timer on 42
        qui collapse `collapse_str', by(`anything') fast
        timer off 42
        qui timer list
        local time_collapse = r(t42)
    restore
    }
    else {
        local time_collapse = .
    }

    preserve
        timer clear
        timer on 43
        qui gcollapse `collapse_str', by(`anything') `options' fast
        timer off 43
        qui timer list
        local time_gcollapse = r(t43)
    restore

    if ( "`fcollapse'" == "fcollapse" ) {
    preserve
        timer clear
        timer on 44
        qui fcollapse `collapse_str', by(`anything') fast
        timer off 44
        qui timer list
        local time_fcollapse = r(t44)
    restore
    }
    else {
        local time_fcollapse = .
    }

    local rs = `time_collapse'  / `time_gcollapse'
    local rf = `time_fcollapse' / `time_gcollapse'
    di as txt "    `:di %8.3g `time_collapse'' | `:di %9.3g `time_fcollapse'' | `:di %9.3g `time_gcollapse'' | `:di %11.3g `rs'' | `:di %11.3g `rf'' | `anything'"
end
