capture program drop consistency_gcollapse
program consistency_gcollapse
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "consistency_gcollapse, `options'" _n(1) "{hline 80}" _n(1)

    local stats sum mean sd max min count percent first last firstnm lastnm median iqr
    local percentiles p1 p13 p30 p50 p70 p87 p99
    local collapse_str ""
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') `stat' = rnorm
    }
    foreach pct of local percentiles {
        local collapse_str `collapse_str' (`pct') `pct' = rnorm
    }

    qui sim, n(50000) nj(8) njsub(4) string groupmiss outmiss float
    mytimer 9
    qui `noisily' foreach i in 0 3 6 9 {
        if ( `i' == 0 ) local by groupsub groupstr
        if ( `i' == 3 ) local by groupstr groupsubstr 
        if ( `i' == 6 ) local by groupsub group
        if ( `i' == 9 ) local by grouplong
    preserve
        mytimer 9 info
        gcollapse `collapse_str', by(`by') verbose benchmark `options'
        mytimer 9 info "gcollapse to groups"
        tempfile f`i'
        save `f`i''
    restore, preserve
        mytimer 9 info
        collapse `collapse_str', by(`by')
        mytimer 9 info "collapse to groups"
        tempfile f`:di `i' + 2'
        save `f`:di `i' + 2''
    restore
    }
    mytimer 9 off

    qui sim, n(50000) nj(8000) njsub(4) string groupmiss outmiss
    qui `noisily' foreach i in 12 15 18 21 {
        if (`i' == 12) local by groupsub groupstr
        if (`i' == 15) local by groupstr
        if (`i' == 18) local by groupsub group
        if (`i' == 21) local by grouplong
    preserve
        mytimer 9 info
        gcollapse `collapse_str', by(`by') verbose benchmark `options'
        mytimer 9 info "gcollapse to groups"
        tempfile f`i'
        save `f`i''
    restore, preserve
        mytimer 9 info
        collapse `collapse_str', by(`by')
        mytimer 9 info "collapse to groups"
        tempfile f`:di `i' + 2'
        save `f`:di `i' + 2''
    restore
    }

    qui sim, n(50000) nj(8000) njsub(4) string groupmiss outmiss
    qui `noisily' foreach i in 24 27 30 33 {
        if (`i' == 24) local by groupsub groupstr
        if (`i' == 27) local by groupstr
        if (`i' == 30) local by groupsub group
        if (`i' == 33) local by grouplong
        local in1  = ceil((0.00 + 0.25 * runiform()) * `=_N')
        local in2  = ceil((0.75 + 0.25 * runiform()) * `=_N')
        local from = cond(`in1' < `in2', `in1', `in2')
        local to   = cond(`in1' > `in2', `in1', `in2')
        local ifin if rsort < 0 in `from' / `to'
        qui count `ifin'
        if (`r(N)' == 0) {
            local in1  = ceil(runiform() * 10)
            local in2  = ceil(`=_N' - runiform() * 10)
            local from = cond(`in1' < `in2', `in1', `in2')
            local to   = cond(`in1' > `in2', `in1', `in2')
            local ifin if rsort < 0 in `from' / `to'
        }
    preserve
        mytimer 9 info
        gcollapse `collapse_str' `ifin', by(`by') verbose benchmark `options'
        mytimer 9 info "gcollapse to groups"
        tempfile f`i'
        save `f`i''
    restore, preserve
        mytimer 9 info
        collapse `collapse_str' `ifin', by(`by')
        mytimer 9 info "collapse to groups"
        tempfile f`:di `i' + 2'
        save `f`:di `i' + 2''
    restore
    }

    foreach i in 0 3 6 9 12 15 18 21 24 27 30 33 {
    preserve
    use `f`:di `i' + 2'', clear
        local bad_any = 0
        if (`i' == 0  ) local bad groupsub groupstr
        if (`i' == 3  ) local bad groupstr groupsubstr 
        if (`i' == 6  ) local bad groupsub group
        if (`i' == 9  ) local bad grouplong
        if (`i' == 12 ) local bad groupsub groupstr
        if (`i' == 15 ) local bad groupstr
        if (`i' == 18 ) local bad groupsub group
        if (`i' == 21 ) local bad grouplong
        if (`i' == 24 ) local bad groupsub groupstr
        if (`i' == 27 ) local bad groupstr
        if (`i' == 30 ) local bad groupsub group
        if (`i' == 33 ) local bad grouplong
        if ( `i' == 0 ) {
            di _n(1) "Comparing collapse for N = 50,000 with J1 = 8 and J2 = 4"
        }
        if ( `i' == 12 ) {
            di _n(1) "Comparing collapse for N = 50,000 with J1 = 8,000 and J2 = 4"
        }
        if ( `i' == 24 ) {
            di _n(1) "Comparing collapse for N = 50,000 with J1 = 8,000 and J2 = 4 (if in)"
        }
        local by `bad'
        foreach var in `stats' `percentiles' {
            rename `var' c_`var'
        }
        qui merge 1:1 `by' using `f`i'', assert(3)
        foreach var in `stats' `percentiles' {
            qui count if ( (abs(`var' - c_`var') > `tol') & (`var' != c_`var'))
            if ( `r(N)' > 0 ) {
                gen bad_`var' = abs(`var' - c_`var') * (`var' != c_`var')
                local bad `bad' *`var'
                di "`var' has `:di r(N)' mismatches".
                local bad_any = 1
            }
        }
        if ( `bad_any' ) {
            order `bad'
            egen bad_any = rowmax(bad_*)
            l *count* `bad' if bad_any
            sum bad_*
            exit 9
        }
        else {
            di "    compare_collapse (passed): gcollapse results equal to collapse (tol = `tol', `by')"
        }
    restore
    }
end

capture program drop checks_byvars_gcollapse
program checks_byvars_gcollapse
    syntax, [*]
    di _n(1) "{hline 80}" _n(1) "checks_byvars_gcollapse `options'" _n(1) "{hline 80}" _n(1)

    sim, n(1000) nj(250) string

    set rmsg on
    preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, verbose `options' by(groupstr)
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, verbose `options' by(group)
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, verbose `options' by(groupsub)
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, verbose `options' by(grouplong)
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, verbose `options' by(groupsub)
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, verbose `options' by(group groupsub)
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, verbose `options' by(grouplong groupsub)
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, verbose `options' by(groupstr groupsub)
    restore
    set rmsg off

    di ""
    di as txt "Passed! checks_byvars_gcollapse `options'"
end

capture program drop checks_options_gcollapse
program checks_options_gcollapse
    syntax, [*]
    di _n(1) "{hline 80}" _n(1) "checks_options_gcollapse `options'" _n(1) "{hline 80}" _n(1)

    local stats mean count median iqr
    local collapse_str ""
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') `stat' = rnorm `stat'2 = rnorm
    }

    sim, n(200) nj(10) string outmiss
    preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose forceio `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose forcemem `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark cw `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark fast `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) double `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) merge `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore

    preserve
        gcollapse `collapse_str', verbose benchmark `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse rnorm (mean) mean_rnorm = rnorm, by(groupstr groupsub) verbose benchmark `options'
        assert rnorm == mean_rnorm
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse rnorm, verbose benchmark `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore

    sort groupstr groupsub
    preserve
        gcollapse `collapse_str', by(groupstr groupsub) verbose benchmark `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr groupsub) verbose benchmark smart `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupsub groupstr) verbose benchmark smart `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark smart `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupsub) verbose benchmark smart `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupsub) verbose benchmark `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore

    di ""
    di as txt "Passed! checks_options_gcollapse `options'"
end

capture program drop checks_corners
program checks_corners
    syntax, [*]
    di _n(1) "{hline 80}" _n(1) "checks_corners `options'" _n(1) "{hline 80}" _n(1)

    qui {
        sysuse auto, clear
        gen price2 = price
        gcollapse price = price2, by(make) v b `options'
        gcollapse price in 1,     by(make) v b `options'
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
