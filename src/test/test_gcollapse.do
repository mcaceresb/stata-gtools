capture program drop checks_gcollapse
program checks_gcollapse
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_gcollapse, `options'" _n(1) "{hline 80}" _n(1)

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

    * untested here; run the examples
    * replace with merge
    * labelformat
    * labelprogram
end

capture program drop checks_inner_collapse
program checks_inner_collapse
    syntax [anything], [tol(real 1e-6) wgt(str) *]

    local 0 `anything' `wgt', `options'
    syntax [anything] [aw fw iw pw], [*]

    local percentiles p1 p10 p30.5 p50 p70.5 p90 p99
    local stats nunique sum mean max min count percent first last firstnm lastnm median iqr skew kurt
    if ( !inlist("`weight'", "pweight") )            local stats `stats' sd
    if ( !inlist("`weight'", "pweight", "iweight") ) local stats `stats' semean
    if (  inlist("`weight'", "fweight", "") )        local stats `stats' sebinomial sepoisson

    local collapse_str ""
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') r1_`stat' = random1
    }
    foreach pct of local percentiles {
        local collapse_str `collapse_str' (`pct') r1_`:subinstr local pct "." "_", all' = random1
    }
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') r2_`stat' = random2
    }
    foreach pct of local percentiles {
        local collapse_str `collapse_str' (`pct') r2_`:subinstr local pct "." "_", all' = random2
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

    qui `noisily' gen_data, n(1000)
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

    qui `noisily' gen_data, n(1000)
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

    qui `noisily' gen_data, n(1000)
    qui expand 50
    qui `noisily' random_draws, random(2) binary(5)

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
    local stats nunique sum mean max min percent first last firstnm lastnm median iqr skew kurt
    if ( !inlist("`weight'", "pweight") ) {
        local stats   `stats'   sd
        local sestats `sestats' sd
    }
    if ( !inlist("`weight'", "pweight", "iweight") ) {
        local stats   `stats'   semean
        local sestats `sestats' semean
    }
    if (  inlist("`weight'", "fweight", "") ) {
        local stats   `stats'   sebinomial sepoisson
        local sestats `sestats' sebinomial sepoisson
    }

    gegen id = group(`anything'), missing

    gegen double nunique = nunique (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double percent = percent (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double mean    = mean    (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double sum     = sum     (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double median  = median  (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double min     = min     (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double max     = max     (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double iqr     = iqr     (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double first   = first   (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double last    = last    (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double firstnm = firstnm (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double lastnm  = lastnm  (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double skew    = skew    (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double kurt    = kurt    (random1) `ifin' `wgt_ge',  by(`anything')
    gegen double q10     = pctile  (random1) `ifin' `wgt_ge',  by(`anything') p(10.5)
    gegen double q30     = pctile  (random1) `ifin' `wgt_ge',  by(`anything') p(30)
    gegen double q70     = pctile  (random1) `ifin' `wgt_ge',  by(`anything') p(70)
    gegen double q90     = pctile  (random1) `ifin' `wgt_ge',  by(`anything') p(90.5)

    local gextra
    foreach extra of local sestats {
        gegen double `extra' = `extra'(random1) `ifin' `wgt_ge',  by(`anything')
        local gextra `gextra' (`extra') g_`extra' = random1
    }

    qui `noisily' {
        gcollapse (nunique)    g_nunique    = random1 ///
                  (percent)    g_percent    = random1 ///
                  (mean)       g_mean       = random1 ///
                  (sum)        g_sum        = random1 ///
                  (median)     g_median     = random1 ///
                  (min)        g_min        = random1 ///
                  (max)        g_max        = random1 ///
                  (iqr)        g_iqr        = random1 ///
                  (first)      g_first      = random1 ///
                  (last)       g_last       = random1 ///
                  (firstnm)    g_firstnm    = random1 ///
                  (lastnm)     g_lastnm     = random1 ///
                  (skew)       g_skew       = random1 ///
                  (kurt)       g_kurt       = random1 ///
                  (p10.5)      g_q10        = random1 ///
                  (p30)        g_q30        = random1 ///
                  (p70)        g_q70        = random1 ///
                  (p90.5)      g_q90        = random1 ///
                  `gextra'                            ///
              `ifin' `wgt_gc', by(id) benchmark verbose `options' merge double
    }

    if ( "`ifin'" == "" ) {
        di _n(1) "Checking full range`wtxt': `anything'"
    }
    else if ( "`ifin'" != "" ) {
        di _n(1) "Checking [`ifin']`wtxt' range: `anything'"
    }

    foreach fun in `stats' q10 q30 q70 q90 {
        cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
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
                    save /tmp/xx, replace
                    exit _rc
                }
                else di as txt "    compare_gegen_gcollapse (imprecision): `fun'`wtxt' yielded similar results (tol = `tol')"
            }
            else {
                recast double g_`fun' `fun'
                cap noi assert (g_`fun' == `fun') | abs(g_`fun' - `fun') < `tol'
                if ( _rc ) {
                    di as err "    compare_gegen_gcollapse (failed): `fun'`wtxt' yielded different results (tol = `tol')"
                    save /tmp/xx, replace
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

    qui gegen id = group(`anything') `ifin', missing
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

    qui gcollapse (skew) skew = random1 (kurt) kurt = random1 (nunique) nq = random1 ///
        `ifin' `wgt_gc', by(id) benchmark verbose `options' double

    if ( "`ifin'" == "" ) {
        di _n(1) "Checking full range`wtxt': `anything'"
    }
    else if ( "`ifin'" != "" ) {
        di _n(1) "Checking [`ifin']`wtxt' range: `anything'"
    }

    * For skewness and kurtosis, numerical imprecision can cause the
    * result to be -1 or 1 when it should really be missing. Internally
    * 0 / 0 is computed as ε / ε for some ε small.

    foreach fun in kurt skew {
        local imprecise 0
        foreach j in `checks' {
            * disp "`j'"
            cap assert ``fun'_`j'' == `fun'[`j'] | abs(``fun'_`j'' - `fun'[`j']) < `tol'
            if ( _rc & (nq[`j'] > 1) ) {
                cap noi assert 0
                di as err "    compare_`fun'_gcollapse (failed): sum`wtxt' yielded different results (tol = `tol')"
                disp "``fun'_`j'' vs `=`fun'[`j']'; diff `=abs(``fun'_`j'' - `fun'[`j'])'"
                exit _rc
            }
            else if ( _rc & (nq[`j'] == 1) ) {
                local ++imprecise
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
*                             Benchmarks                              *
***********************************************************************

capture program drop bench_collapse
program bench_collapse
    syntax, [tol(real 1e-6) bench(real 1) n(int 1000) NOIsily style(str) vars(int 1) collapse fcollapse *]

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
