capture program drop checks_gstats
program checks_gstats
    sysuse auto, clear

    gstats winsor price, by(foreign)
    winsor2 price, by(foreign) replace

    winsor2 price mpg, by(foreign) cuts(10 90) s(_w2)
    gstats winsor price mpg, by(foreign) cuts(10 90) s(_w2) replace
    desc
    * l price* mpg* foreign 
    exit 12345

    * gtools, upgrade branch(develop)
    clear
    set obs 1000000
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
    exit 12345
end

***********************************************************************
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_gstats_winsor
program bench_gstats_winsor
    syntax, [tol(real 1e-6) bench(real 1) n(int 1000) NOIsily *]

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
    versus_gstats_winsor str_12 str_32,       `options'
    versus_gstats_winsor str_12 str_32 str_4, `options'

    versus_gstats_winsor double1,                 `options'
    versus_gstats_winsor double1 double2,         `options'
    versus_gstats_winsor double1 double2 double3, `options'

    versus_gstats_winsor int1,           `options'
    versus_gstats_winsor int1 int2,      `options'
    versus_gstats_winsor int1 int2 int3, `options'

    versus_gstats_winsor int1 str_32 double1,                                        `options'
    versus_gstats_winsor int1 str_32 double1 int2 str_12 double2,                    `options'
    versus_gstats_winsor int1 str_32 double1 int2 str_12 double2 int3 str_4 double3, `options'

    di _n(1) "{hline 80}" _n(1) "bench_gstats_winsor, `options'" _n(1) "{hline 80}" _n(1)
end

capture program drop versus_gstats_winsor
program versus_gstats_winsor, rclass
    syntax [anything], [*]

    timer clear
    timer on 42
    qui winsor2 random2 `if' `in', by(`anything') s(_w1)
    timer off 42
    qui timer list
    local time_winsor = r(t42)

    timer clear
    timer on 43
    qui gstats winsor random2 `if' `in', by(`anything') s(_w2)
    timer off 43
    qui timer list
    local time_gwinsor = r(t43)

    local rs = `time_winsor'  / `time_gwinsor'
    di as txt "    `:di %6.3g `time_winsor'' | `:di %13.3g `time_gwinsor'' | `:di %11.4g `rs'' | `anything'"
    drop *_w?
end
