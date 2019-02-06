capture program drop checks_greshape
program checks_greshape
    qui testLong
    qui testLong unsorted nodupcheck

    qui testWide
    qui testWide unsorted
end

***********************************************************************
*                             Basic Tests                             *
***********************************************************************

capture program drop testWide
program testWide
    args opts

    clear
    set obs 5
    gen i1 = _n
    gen i2 = -_n
    gen i3 = "why?" + string(mod(_n, 3))
    gen i4 = "hey" + string(-_n) + "thisIsWideRight?"
    expand 3
    gen j1 = mod(_n, 6)
    gen j2 = "waffle" + string(mod(_n, 6))
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

    * 1. Single num i
    preserve
        * 1.1 num xij
        keep i1 j1 z
        greshape wide z, i(i1) j(j1) `opts'
        l
    restore, preserve
        keep i1 j1 z
        greshape wide z, i(i1) j(j1) `opts'
        l
    restore, preserve
        keep i1 j1 w z
        greshape wide w z, i(i1) j(j1) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 j1 x
        greshape wide x, i(i1) j(j1) string `opts'
        l
    restore, preserve
        keep i1 j1 x p
        greshape wide x p, i(i1) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 j1 x z
        greshape wide x z, i(i1) j(j1) string `opts'
        l
    restore, preserve
        drop i2-i4 j2
        greshape wide p w x y z, i(i1) j(j1) string `opts'
        l
    restore

    preserve
        * 1.1 num xij
        keep i1 j2 z
        greshape wide z, i(i1) j(j2) `opts'
        l
    restore, preserve
        keep i1 j2 z
        greshape wide z, i(i1) j(j2) `opts'
        l
    restore, preserve
        keep i1 j2 w z
        greshape wide w z, i(i1) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 j2 x
        greshape wide x, i(i1) j(j2) string `opts'
        l
    restore, preserve
        keep i1 j2 x p
        greshape wide x p, i(i1) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 j2 x z
        greshape wide x z, i(i1) j(j2) string `opts'
        l
    restore, preserve
        drop i2-i4 j1
        greshape wide p w x y z, i(i1) j(j2) string `opts'
        l
    restore

    * 2. Multiple num i
    preserve
        * 1.1 num xij
        keep i1 i2 j1 z
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i1 i2 j1 z
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i1 i2 j1 w z
        greshape wide w z, i(i?) j(j1) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 i2 j1 x
        greshape wide x, i(i?) j(j1) string `opts'
        l
    restore, preserve
        keep i1 i2 j1 x p
        greshape wide x p, i(i?) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 i2 j1 x z
        greshape wide x z, i(i?) j(j1) string `opts'
        l
    restore, preserve
        drop i3 i4 j2
        greshape wide p w x y z, i(i?) j(j1) string `opts'
        l
    restore

    preserve
        * 1.1 num xij
        keep i1 i2 j2 z
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i1 i2 j2 z
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i1 i2 j2 w z
        greshape wide w z, i(i?) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 i2 j2 x
        greshape wide x, i(i?) j(j2) string `opts'
        l
    restore, preserve
        keep i1 i2 j2 x p
        greshape wide x p, i(i?) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 i2 j2 x z
        greshape wide x z, i(i?) j(j2) string `opts'
        l
    restore, preserve
        drop i3 i4 j1
        greshape wide p w x y z, i(i?) j(j2) string `opts'
        l
    restore

    * 3. Single str i
    preserve
        * 1.1 num xij
        keep i4 j1 z
        greshape wide z, i(i4) j(j1) `opts'
        l
    restore, preserve
        keep i4 j1 z
        greshape wide z, i(i4) j(j1) `opts'
        l
    restore, preserve
        keep i4 j1 w z
        greshape wide w z, i(i4) j(j1) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i4 j1 x
        greshape wide x, i(i4) j(j1) string `opts'
        l
    restore, preserve
        keep i4 j1 x p
        greshape wide x p, i(i4) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i4 j1 x z
        greshape wide x z, i(i4) j(j1) string `opts'
        l
    restore, preserve
        drop i1-i3 j2
        greshape wide p w x y z, i(i4) j(j1) string `opts'
        l
    restore

    preserve
        * 1.1 num xij
        keep i4 j2 z
        greshape wide z, i(i4) j(j2) `opts'
        l
    restore, preserve
        keep i4 j2 z
        greshape wide z, i(i4) j(j2) `opts'
        l
    restore, preserve
        keep i4 j2 w z
        greshape wide w z, i(i4) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i4 j2 x
        greshape wide x, i(i4) j(j2) string `opts'
        l
    restore, preserve
        keep i4 j2 x p
        greshape wide x p, i(i4) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i4 j2 x z
        greshape wide x z, i(i4) j(j2) string `opts'
        l
    restore, preserve
        drop i1-i3 j1
        greshape wide p w x y z, i(i4) j(j2) string `opts'
        l
    restore

    * 4. Multiple str i
    preserve
        * 1.1 num xij
        keep i3 i4 j1 z
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i3 i4 j1 z
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i3 i4 j1 w z
        greshape wide w z, i(i?) j(j1) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i3 i4 j1 x
        greshape wide x, i(i?) j(j1) string `opts'
        l
    restore, preserve
        keep i3 i4 j1 x p
        greshape wide x p, i(i?) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i3 i4 j1 x z
        greshape wide x z, i(i?) j(j1) string `opts'
        l
    restore, preserve
        drop i1 i2 j2
        greshape wide p w x y z, i(i?) j(j1) string `opts'
        l
    restore

    preserve
        * 1.1 num xij
        keep i3 i4 j2 z
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i3 i4 j2 z
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i3 i4 j2 w z
        greshape wide w z, i(i?) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i3 i4 j2 x
        greshape wide x, i(i?) j(j2) string `opts'
        l
    restore, preserve
        keep i3 i4 j2 x p
        greshape wide x p, i(i?) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i3 i4 j2 x z
        greshape wide x z, i(i?) j(j2) string `opts'
        l
    restore, preserve
        drop i1 i2 j1
        greshape wide p w x y z, i(i?) j(j2) string `opts'
        l
    restore

    * 5. Mixed str i
    preserve
        * 1.1 num xij
        keep i? j1 z
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i? j1 z
        greshape wide z, i(i?) j(j1) `opts'
        l
    restore, preserve
        keep i? j1 w z
        greshape wide w z, i(i?) j(j1) `opts'
        l
    restore, preserve
        * 1.1 str xij
        keep i? j1 x
        greshape wide x, i(i?) j(j1) string `opts'
        l
    restore, preserve
        keep i? j1 x p
        greshape wide x p, i(i?) j(j1) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i? j1 x z
        greshape wide x z, i(i?) j(j1) string `opts'
        l
    restore, preserve
        drop j2
        greshape wide p w x y z, i(i?) j(j1) string `opts'
        l
    restore

    preserve
        * 1.1 num xij
        keep i? j2 z
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i? j2 z
        greshape wide z, i(i?) j(j2) `opts'
        l
    restore, preserve
        keep i? j2 w z
        greshape wide w z, i(i?) j(j2) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i? j2 x
        greshape wide x, i(i?) j(j2) string `opts'
        l
    restore, preserve
        keep i? j2 x p
        greshape wide x p, i(i?) j(j2) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i? j2 x z
        greshape wide x z, i(i?) j(j2) string `opts'
        l
    restore, preserve
        drop j1
        greshape wide p w x y z, i(i?) j(j2) string `opts'
        l
    restore
end

capture program drop testLong
program testLong
    args opts

    clear
    set obs 5
    gen i1 = _n
    gen i2 = -_n
    gen i3 = "why?" + string(mod(_n, 3))
    gen i4 = "hey" + string(-_n) + "thisIsLongRight?"
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

    * 1. Single num i
    preserve
        * 1.1 num xij
        keep i1 z1 z2
        greshape long z, i(i1) j(j) `opts'
        l
    restore, preserve
        keep i1 z1 z2
        greshape long z, i(i1) j(j) `opts'
        l
    restore, preserve
        keep i1 w* z*
        greshape long w z, i(i1) j(j) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 x*
        greshape long x, i(i1) j(j) string `opts'
        l
    restore, preserve
        keep i1 x* p*
        greshape long x p, i(i1) j(j) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 x* z*
        greshape long x z, i(i1) j(j) string `opts'
        l
    restore, preserve
        drop i2-i4
        greshape long p w x y z, i(i1) j(j) string `opts'
        l
    restore

    * 2. Multiple num i
    preserve
        * 1.1 num xij
        keep i1 i2 z1 z2
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i1 i2 z1 z2
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i1 i2 w* z*
        greshape long w z, i(i?) j(j) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i1 i2 x*
        greshape long x, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i1 i2 x* p*
        greshape long x p, i(i?) j(j) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i1 i2 x* z*
        greshape long x z, i(i?) j(j) string `opts'
        l
    restore, preserve
        drop i3 i4
        greshape long p w x y z, i(i?) j(j) string `opts'
        l
    restore

    * 3. Single str i
    preserve
        * 1.1 num xij
        keep i4 z1 z2
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i4 i2 z1 z2
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i4 i2 w* z*
        greshape long w z, i(i?) j(j) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i4 i2 x*
        greshape long x, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i4 i2 x* p*
        greshape long x p, i(i?) j(j) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i4 i2 x* z*
        greshape long x z, i(i?) j(j) string `opts'
        l
    restore, preserve
        drop i1 i2 i3
        greshape long p w x y z, i(i?) j(j) string `opts'
        l
    restore

    * 4. Multiple str i
    preserve
        * 1.1 num xij
        keep i3 i4 z1 z2
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i3 i4 i2 z1 z2
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i3 i4 i2 w* z*
        greshape long w z, i(i?) j(j) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i3 i4 i2 x*
        greshape long x, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i3 i4 i2 x* p*
        greshape long x p, i(i?) j(j) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i3 i4 i2 x* z*
        greshape long x z, i(i?) j(j) string `opts'
        l
    restore, preserve
        drop i1 i2
        greshape long p w x y z, i(i?) j(j) string `opts'
        l
    restore

    * 5. Mixed str i
    preserve
        * 1.1 num xij
        keep i? z1 z2
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i? i2 z1 z2
        greshape long z, i(i?) j(j) `opts'
        l
    restore, preserve
        keep i? i2 w* z*
        greshape long w z, i(i?) j(j) `opts'
        l
    restore, preserve
        * 1.2 str xij
        keep i? i2 x*
        greshape long x, i(i?) j(j) string `opts'
        l
    restore, preserve
        keep i? i2 x* p*
        greshape long x p, i(i?) j(j) string `opts'
        l
    restore, preserve
        * 1.3 mix xij
        keep i? i2 x* z*
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

    local N = trim("`: di %15.0gc _N'")
    local J = trim("`: di %15.0gc `n''")

    di as txt _n(1)
    di as txt "Benchmark vs winsor2, obs = `N', J = `J' (in seconds)"
    di as txt " reshape | greshape | ratio (c/g) | varlist"
    di as txt " ------- | -------- | ----------- | -------"

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

        timer clear
        timer on 42
        qui reshape wide `anything', i(`i') j(`j') `options'
        timer off 42
        qui timer list
        local time_wide = r(t42)
    restore

    preserve
        timer clear
        timer on 43
        qui greshape long `anything', i(`i') j(`j') `options'
        timer off 43
        qui timer list
        local time_glong = r(t43)

        timer clear
        timer on 43
        qui greshape wide `anything', i(`i') j(`j') `options'
        timer off 43
        qui timer list
        local time_gwide = r(t43)
    restore

    local rs = `time_long'  / `time_glong'
    di as txt " `:di %7.3g `time_long'' | `:di %8.3g `time_glong'' | `:di %11.4g `rs'' | long `anything', i(`i')"
    local rs = `time_wide'  / `time_gwide'
    di as txt " `:di %7.3g `time_wide'' | `:di %8.3g `time_gwide'' | `:di %11.4g `rs'' | wide `anything', i(`i')"
    drop *_w?
end
