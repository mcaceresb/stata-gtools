* Checks in greshape
* ------------------
*
* 1. Unique j
* 2. Unique Xi
* 3. Missing j values
* 4. preserve, restore
* 5. Unique i
* 6. unsorted

capture program drop checks_greshape
program checks_greshape
    qui checks_inner_greshape_errors
    qui checks_inner_greshape_errors nochecks

    qui checks_inner_greshape_long
    qui checks_inner_greshape_long nochecks
    qui checks_inner_greshape_long " " xi
    qui checks_inner_greshape_long nochecks xi

    qui checks_inner_greshape_wide
    qui checks_inner_greshape_wide nochecks
    qui checks_inner_greshape_wide " " xi
    qui checks_inner_greshape_wide nochecks xi
end

***********************************************************************
*                               Errors                                *
***********************************************************************

capture program drop checks_inner_greshape_errors
program checks_inner_greshape_errors

    foreach v in v1 v2 {
        clear
        set obs 5
        gen i1 = _n
        gen i2 = -_n
        gen i3 = "why?" + string(mod(_n, 3))
        gen i4 = "hey" + string(-_n) + "thisIsLongRight?"
        expand 3
        if "`v'" == "v1" bys i1: gen j = "@#" + string(_n) + "|"
        else bys i1: gen j = _n + _N
        gen w = "|" + string(_n / 3) + "/"
        gen x = _N - _n
        gen y = _n / 2
        gen r = runiform()
        sort r
        drop r
        preserve
            greshape wide x y w, i(i1) j(j)
            assert _rc == 0
        restore, preserve
            cap greshape wide x, i(i1) j(j)
            assert _rc == 9
        restore, preserve
            if "`v'" == "v1" replace j = "2" if i1 == 1
            else replace j = 2 if i1 == 1
            cap greshape wide x y, i(i1) j(j)
            assert _rc == 9
        restore, preserve
            rename (i3 i4) (a3 a4)
            cap greshape long a, i(i1 i2) j(_j)
            assert _rc == 9
        restore, preserve
            cap greshape long i, i(i1 i2 j) j(_j)
            assert _rc == 198
        restore, preserve
            cap greshape long a, i(i1 i? j) j(_j)
            assert _rc == 111
        restore, preserve
            rename (i3 i4) (a3 a4)
            cap greshape long a, i(i1 i? j) j(_j)
            assert _rc == 0
        restore
    }
end

***********************************************************************
*                             Basic Tests                             *
***********************************************************************

capture program drop checks_inner_greshape_wide
program checks_inner_greshape_wide
    args opts extras

    clear
    set obs 5
    gen i1 = _n
    gen i2 = -_n
    gen i3 = "why?" + string(mod(_n, 3))
    gen i4 = "hey" + string(-_n) + "thisIsWideRight?"
    gen ca = "constant | " + string(_n) + " | group "
    gen cb = int(20 * runiform())
    expand 3
    bys i?: gen j1 = mod(_n, 6)
    bys i?: gen j2 = "waffle" + string(mod(_n, 6))
    gen str10  x  = "some"
    replace    x  = "whenever" in 4/ 9
    replace    x  = "wherever" in 9/l
    gen str20  p  = "another long one" + string(mod(_n, 4))
    replace    p  = "this b"   in 3 / 7
    replace    p  = "this c"   in 11/l
    gen float  z  = _n
    replace    z  = runiform() in 4 / 8
    replace    z  = runiform() in 12/l
    gen double w  = _n * 3.14
    replace    w  = rnormal()  in 7/l
    gen int    y  = _n
    replace    y  = int(10 * runiform()) in 3/l

    if ( `"`extras'"' != "" ) local xi ca cb
    else drop ca cb

disp as err "    set 1 `xi'"
    * 1. Single num i
    preserve
        * 1.1 num xij
        keep i1 j1 z `xi'
        greshape wide z, i(i1) j(j1) `opts'
        l
    restore, preserve
        keep i1 j1 z `xi'
        greshape wide z, i(i1) j(j1) `opts'
        l
    restore, preserve
        keep i1 j1 w z `xi'
        greshape wide w z, i(i1) j(j1) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 j1 x `xi'
        greshape wide x, i(i1) j(j1) string `opts'
        l
    restore, preserve
        keep i1 j1 x p `xi'
        greshape wide x p, i(i1) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 j1 x z `xi'
        greshape wide x z, i(i1) j(j1) string `opts'
        l
    restore, preserve
        drop i2-i4 j2
        greshape wide p w x y z, i(i1) j(j1) string `opts'
        l
    restore

disp as err "    set 2 `xi'"
    preserve
        * 1.1 num xij
        keep i1 j2 z `xi'
        greshape wide z, i(i1) j(j2) `opts'
        l
    restore, preserve
        keep i1 j2 z `xi'
        greshape wide z, i(i1) j(j2) `opts'
        l
    restore, preserve
        keep i1 j2 w z `xi'
        greshape wide w z, i(i1) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 j2 x `xi'
        greshape wide x, i(i1) j(j2) string `opts'
        l
    restore, preserve
        keep i1 j2 x p `xi'
        greshape wide x p, i(i1) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 j2 x z `xi'
        greshape wide x z, i(i1) j(j2) string `opts'
        l
    restore, preserve
        drop i2-i4 j1 `xi'
        greshape wide p w x y z, i(i1) j(j2) string `opts'
        l
    restore

disp as err "    set 3 `xi'"
    * 2. Multiple num i
    preserve
        * 1.1 num xij
        keep i1 i2 j1 z `xi'
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i1 i2 j1 z `xi'
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i1 i2 j1 w z `xi'
        greshape wide w z, i(i?) j(j1) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 i2 j1 x `xi'
        greshape wide x, i(i?) j(j1) string `opts'
        l
    restore, preserve
        keep i1 i2 j1 x p `xi'
        greshape wide x p, i(i?) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 i2 j1 x z `xi'
        greshape wide x z, i(i?) j(j1) string `opts'
        l
    restore, preserve
        drop i3 i4 j2
        greshape wide p w x y z, i(i?) j(j1) string `opts'
        l
    restore

disp as err "    set 4 `xi'"
    preserve
        * 1.1 num xij
        keep i1 i2 j2 z `xi'
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i1 i2 j2 z `xi'
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i1 i2 j2 w z `xi'
        greshape wide w z, i(i?) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 i2 j2 x `xi'
        greshape wide x, i(i?) j(j2) string `opts'
        l
    restore, preserve
        keep i1 i2 j2 x p `xi'
        greshape wide x p, i(i?) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 i2 j2 x z `xi'
        greshape wide x z, i(i?) j(j2) string `opts'
        l
    restore, preserve
        drop i3 i4 j1
        greshape wide p w x y z, i(i?) j(j2) string `opts'
        l
    restore

disp as err "    set 5 `xi'"
    * 3. Single str i
    preserve
        * 1.1 num xij
        keep i4 j1 z `xi'
        greshape wide z, i(i4) j(j1) `opts'
        l
    restore, preserve
        keep i4 j1 z `xi'
        greshape wide z, i(i4) j(j1) `opts'
        l
    restore, preserve
        keep i4 j1 w z `xi'
        greshape wide w z, i(i4) j(j1) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i4 j1 x `xi'
        greshape wide x, i(i4) j(j1) string `opts'
        l
    restore, preserve
        keep i4 j1 x p `xi'
        greshape wide x p, i(i4) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i4 j1 x z `xi'
        greshape wide x z, i(i4) j(j1) string `opts'
        l
    restore, preserve
        drop i1-i3 j2
        greshape wide p w x y z, i(i4) j(j1) string `opts'
        l
    restore

disp as err "    set 6 `xi'"
    preserve
        * 1.1 num xij
        keep i4 j2 z `xi'
        greshape wide z, i(i4) j(j2) `opts'
        l
    restore, preserve
        keep i4 j2 z `xi'
        greshape wide z, i(i4) j(j2) `opts'
        l
    restore, preserve
        keep i4 j2 w z `xi'
        greshape wide w z, i(i4) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i4 j2 x `xi'
        greshape wide x, i(i4) j(j2) string `opts'
        l
    restore, preserve
        keep i4 j2 x p `xi'
        greshape wide x p, i(i4) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i4 j2 x z `xi'
        greshape wide x z, i(i4) j(j2) string `opts'
        l
    restore, preserve
        drop i1-i3 j1
        greshape wide p w x y z, i(i4) j(j2) string `opts'
        l
    restore

disp as err "    set 7 `xi'"
    * 4. Multiple str i
    preserve
        * 1.1 num xij
        keep i3 i4 j1 z `xi'
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i3 i4 j1 z `xi'
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i3 i4 j1 w z `xi'
        greshape wide w z, i(i?) j(j1) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i3 i4 j1 x `xi'
        greshape wide x, i(i?) j(j1) string `opts'
        l
    restore, preserve
        keep i3 i4 j1 x p `xi'
        greshape wide x p, i(i?) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i3 i4 j1 x z `xi'
        greshape wide x z, i(i?) j(j1) string `opts'
        l
    restore, preserve
        drop i1 i2 j2
        greshape wide p w x y z, i(i?) j(j1) string `opts'
        l
    restore

disp as err "    set 8 `xi'"
    preserve
        * 1.1 num xij
        keep i3 i4 j2 z `xi'
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i3 i4 j2 z `xi'
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i3 i4 j2 w z `xi'
        greshape wide w z, i(i?) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i3 i4 j2 x `xi'
        greshape wide x, i(i?) j(j2) string `opts'
        l
    restore, preserve
        keep i3 i4 j2 x p `xi'
        greshape wide x p, i(i?) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i3 i4 j2 x z `xi'
        greshape wide x z, i(i?) j(j2) string `opts'
        l
    restore, preserve
        drop i1 i2 j1
        greshape wide p w x y z, i(i?) j(j2) string `opts'
        l
    restore

disp as err "    set 9 `xi'"
    * 5. Mixed str i
    preserve
        * 1.1 num xij
        keep i? j1 z `xi'
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i? j1 z `xi'
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i? j1 w z `xi'
        greshape wide w z, i(i?) j(j1) `opts'
        l
    restore, preserve
        * 1.1 str xij
        keep i? j1 x `xi'
        greshape wide x, i(i?) j(j1) string `opts'
        l
    restore, preserve
        keep i? j1 x p `xi'
        greshape wide x p, i(i?) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i? j1 x z `xi'
        greshape wide x z, i(i?) j(j1) string `opts'
        l
    restore, preserve
        drop j2
        greshape wide p w x y z, i(i?) j(j1) string `opts'
        l
    restore

disp as err "    set 10 `xi'"
    preserve
        * 1.1 num xij
        keep i? j2 z `xi'
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i? j2 z `xi'
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i? j2 w z `xi'
        greshape wide w z, i(i?) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i? j2 x `xi'
        greshape wide x, i(i?) j(j2) string `opts'
        l
    restore, preserve
        keep i? j2 x p `xi'
        greshape wide x p, i(i?) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i? j2 x z `xi'
        greshape wide x z, i(i?) j(j2) string `opts'
        l
    restore, preserve
        drop j1
        greshape wide p w x y z, i(i?) j(j2) string `opts'
        l
    restore
end

capture program drop checks_inner_greshape_long
program checks_inner_greshape_long
    args opts extras

    clear
    set obs 5
    gen i1 = _n
    gen i2 = -_n
    gen i3 = "why?" + string(mod(_n, 3))
    gen i4 = "hey" + string(-_n) + "thisIsLongRight?"
    gen ca = "constant | " + string(_n) + " | group "
    gen cb = int(20 * runiform())
    gen str5   xa  = "some"
    gen str8   xb  = "whenever"
    gen str10  xd  = "wherever"
    gen str20  pa  = "another long one" + string(mod(_n, 4))
    gen str8   pb  = "this b"
    gen str10  pd  = "this c"
    gen long   z1  = _n
    gen float  z2  = runiform()
    gen float  zd  = runiform()
    gen float  w1  = _n * 3.14
    gen double w5  = rnormal()
    gen int    y2  = _n
    gen float  y7  = int(10 * runiform())

    if ( `"`extras'"' != "" ) local xi ca cb
    else drop ca cb

disp as err "    set 1 `xi'"
    * 1. Single num i
    preserve
        * 1.1 num xij
        keep i1 z1 z2 `xi'
        greshape long z, i(i1) j(j) `opts'
        l
    restore, preserve
        keep i1 z1 z2 `xi'
        greshape long z, i(i1) j(j) `opts'
        l
    restore, preserve
        keep i1 w* z* `xi'
        greshape long w z, i(i1) j(j) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 x* `xi'
        greshape long x, i(i1) j(j) string `opts'
        l
    restore, preserve
        keep i1 x* p* `xi'
        greshape long x p, i(i1) j(j) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 x* z* `xi'
        greshape long x z, i(i1) j(j) string `opts'
        l
    restore, preserve
        drop i2-i4
        greshape long p w x y z, i(i1) j(j) string `opts'
        l
    restore

disp as err "    set 2 `xi'"
    * 2. Multiple num i
    preserve
        * 1.1 num xij
        keep i1 i2 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i1 i2 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i1 i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i1 i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts'
        l
    restore, preserve
        drop i3 i4
        greshape long p w x y z, i(i?) j(j) string `opts'
        l
    restore

disp as err "    set 3 `xi'"
    * 3. Single str i
    preserve
        * 1.1 num xij
        keep i4 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i4 i2 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i4 i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i4 i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i4 i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i4 i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts'
        l
    restore, preserve
        drop i1 i2 i3
        greshape long p w x y z, i(i?) j(j) string `opts'
        l
    restore

disp as err "    set 4 `xi'"
    * 4. Multiple str i
    preserve
        * 1.1 num xij
        keep i3 i4 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i3 i4 i2 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i3 i4 i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i3 i4 i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i3 i4 i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i3 i4 i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts'
        l
    restore, preserve
        drop i1 i2
        greshape long p w x y z, i(i?) j(j) string `opts'
        l
    restore

disp as err "    set 5 `xi'"
    * 5. Mixed str i
    preserve
        * 1.1 num xij
        keep i? z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i? i2 z1 z2 `xi'
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i? i2 w* z* `xi'
        greshape long w z, i(i?) j(j) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i? i2 x* `xi'
        greshape long x, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i? i2 x* p* `xi'
        greshape long x p, i(i?) j(j) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i? i2 x* z* `xi'
        greshape long x z, i(i?) j(j) string `opts'
        l
    restore, preserve
        greshape long p w x y z, i(i?) j(j) string `opts'
        l
    restore
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_greshape
program bench_greshape
    syntax, [tol(real 1e-6) bench(real 1) n(int 1000) NOIsily *]

    qui gen_data, n(`n')
    qui expand `=100 * `bench''
    qui `noisily' random_draws, random(2) double
    qui hashsort random1
    gen long   ix_num = _n
    gen str    ix_str = "str" + string(_n)
    gen double ix_dbl = _pi + _n

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    di as txt _n(1)
    di as txt "Benchmark vs winsor2, obs = `N', J = `J' (in seconds)"
    di as txt " reshape | greshape | ratio (c/g) | varlist"
    di as txt " ------- | -------- | ----------- | -------"

    rename double? dbl?
    rename int?    num?

    versus_greshape dbl random,      j(_j) i(ix_num num1)
    versus_greshape dbl random,      j(_j) i(ix_num num1 num2)
    versus_greshape dbl random str_, j(_j) i(ix_num num1 num2 num3) string

    versus_greshape num random,      j(_j) i(ix_dbl dbl1)
    versus_greshape num random str_, j(_j) i(ix_dbl dbl1 dbl2 dbl3) string

    versus_greshape dbl num random, j(_j) i(ix_str str_32)
    versus_greshape dbl num random, j(_j) i(ix_str str_32 str_12 str_4) string

    di _n(1) "{hline 80}" _n(1) "bench_greshape, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop versus_greshape
program versus_greshape, rclass
    syntax [anything], [i(str) j(str) *]

    preserve
        timer clear
        timer on 42
        qui reshape long `anything', i(`i') j(`j') `options'
        timer off 42
        qui timer list
        local time_long = r(t42)
        tempfile a
        qui save `"`a'"'

        timer clear
        timer on 42
        qui reshape wide `anything', i(`i') j(`j') `options'
        timer off 42
        qui timer list
        local time_wide = r(t42)
        tempfile b
        qui save `"`b'"'
    restore

    preserve
        timer clear
        timer on 43
        qui greshape long `anything', i(`i') j(`j') `options' check(2)
        timer off 43
        qui timer list
        local time_glong = r(t43)
        cf * using `"`a'"'

        timer clear
        timer on 43
        qui greshape wide `anything', i(`i') j(`j') `options' check(2)
        timer off 43
        qui timer list
        local time_gwide = r(t43)
        cf * using `"`b'"'
    restore

    local rs = `time_long'  / `time_glong'
    di as txt " `:di %7.3g `time_long'' | `:di %8.3g `time_glong'' | `:di %11.4g `rs'' | long `anything', i(`i')"
    local rs = `time_wide'  / `time_gwide'
    di as txt " `:di %7.3g `time_wide'' | `:di %8.3g `time_gwide'' | `:di %11.4g `rs'' | wide `anything', i(`i')"
end

* use /home/mauricio/bulk/lib/benchmark-stata-r/1e7, clear
* gduplicates drop id1 id2 id3, force
* keep if _n < _N/10
* set rmsg on
* greshape gather id4 id5 id6 v1 v2 v3, j(variable) value(value)
* greshape spread value, j(variable)
