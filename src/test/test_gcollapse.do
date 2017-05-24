capture program drop sim
program sim, rclass
    syntax, [offset(str) n(int 100) nj(int 10) njsub(int 2) string float sortg replace groupmiss outmiss]
    qui {
        if ("`offset'" == "") local offset 0
        clear
        set obs `n'
        gen group  = ceil(`nj' *  _n / _N) + `offset'
        bys group: gen groupsub   = ceil(`njsub' *  _n / _N)
        bys group: gen groupfloat = ceil(`njsub' *  _n / _N) + 0.5
        gen rsort = runiform() - 0.5
        gen rnorm = rnormal()
        if ("`sortg'" == "")  sort rsort
        if ("`groupmiss'" != "") replace group = . if runiform() < 0.1
        if ("`outmiss'" != "") replace rsort = . if runiform() < 0.1
        if ("`outmiss'" != "") replace rnorm = . if runiform() < 0.1
        if ("`float'" != "")  replace group = group / `nj'
        if ("`string'" != "") {
            tostring group, `:di cond("`replace'" == "", "gen(groupstr)", "replace")'
            local target `:di cond("`replace'" == "", "groupstr", "group")'
            replace `target' = "i am a modesly long string" + `target'
        }
        gen long grouplong = ceil(`nj' *  _n / _N) + `offset'
    }
    sum rsort
    di "Obs = " trim("`:di %21.0gc _N'") "; Groups = " trim("`:di %21.0gc `nj''")
    compress
    return local n  = `n'
    return local nj = `nj'
    return local offset = `offset'
    return local string = ("`string'" != "")
end

capture program drop checks_consistency_gcollapse
program checks_consistency_gcollapse
    syntax, [tol(real 1e-6) NOIsily *]
    di _n(1) "{hline 80}" _n(1) "checks_consistency_gcollapse `options'" _n(1) "{hline 80}" _n(1)

    local stats sum mean sd max min count percent first last firstnm lastnm median iqr
    local collapse_str ""
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') `stat' = rnorm
    }
    local collapse_str `collapse_str' (p23) p23 = rnorm
    local collapse_str `collapse_str' (p77) p77 = rnorm

    sim, n(50000) nj(8) njsub(4) string groupmiss outmiss
    mytimer 9
    qui `noisily' foreach i in 0 3 6 9 {
        if (`i' == 0) local by groupsub groupstr
        if (`i' == 3) local by groupstr
        if (`i' == 6) local by groupsub group
        if (`i' == 9) local by grouplong
    preserve
        mytimer 9 info
        gcollapse `collapse_str', by(`by') verbose benchmark `options'
        mytimer 9 info "gcollapse to groups"
        tempfile f`i'
        save `f`i''
    * I originally was also testing fcollapse, but it can't do sd for
    * some reason, and you can't mix string and numeric variables...
    * restore, preserve
    *     mytimer 9 info
    *     if (`i' != 0) {
    *         fcollapse `collapse_str', by(`by') verbose
    *         mytimer 9 info "fcollapse to groups"
    *         tempfile f`:di `i' + 1'
    *         save `f`:di `i' + 1''
    *     }
    restore, preserve
        mytimer 9 info
        collapse `collapse_str', by(`by')
        mytimer 9 info "collapse to groups"
        tempfile f`:di `i' + 2'
        save `f`:di `i' + 2''
    restore
    }
    mytimer 9 off

    sim, n(50000) nj(8000) njsub(4) string groupmiss outmiss
    qui `noisily' foreach i in 12 15 18 21 {
        if (`i' == 12) local by groupsub groupstr
        if (`i' == 15) local by groupstr
        if (`i' == 18) local by groupsub group
        if (`i' == 21) local by grouplong
    preserve
        mytimer 9 info
        gcollapse `collapse_str', by(`by') verbose benchmark `options'
        mytimer 9 info "gcollapse 2 groups"
        tempfile f`i'
        save `f`i''
    * restore, preserve
    *     mytimer 9 info
    *     if (`i' != 12) {
    *         fcollapse `collapse_str', by(`by') verbose
    *         mytimer 9 info "fcollapse to groups"
    *         tempfile f`:di `i' + 1'
    *         save `f`:di `i' + 1''
    *     }
    restore, preserve
        mytimer 9 info
        collapse `collapse_str', by(`by')
        mytimer 9 info "collapse to groups"
        tempfile f`:di `i' + 2'
        save `f`:di `i' + 2''
    restore
    }

    foreach i in 0 3 6 9 12 15 18 21 {
    preserve
    use `f`:di `i' + 2'', clear
        local bad_any = 0
        if (`i' == 0)  local bad groupsub groupstr
        if (`i' == 3)  local bad groupstr
        if (`i' == 6)  local bad groupsub group
        if (`i' == 9)  local bad grouplong
        if (`i' == 12) local bad groupsub groupstr
        if (`i' == 15) local bad groupstr
        if (`i' == 18) local bad groupsub group
        if (`i' == 21) local bad grouplong
        local by `bad'
        foreach var in `stats' p23 p77 {
            rename `var' c_`var'
        }
        qui merge 1:1 `by' using `f`i'', assert(3)
        foreach var in `stats' p23 p77 {
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
            di "gcollapse produced identical data to collapse (tol = `tol', `by')"
        }
    restore
    }

    * foreach i in 4 7 10 16 19 22 {
    * preserve
    * use `f`:di `i' + 1'', clear
    *     local bad_any = 0
    *     if (`i' == 4)  local bad groupstr
    *     if (`i' == 7)  local bad groupsub group
    *     if (`i' == 10) local bad grouplong
    *     if (`i' == 16) local bad groupstr
    *     if (`i' == 19) local bad groupsub group
    *     if (`i' == 22) local bad grouplong
    *     local by `bad'
    *     foreach var in `stats' p23 p77 {
    *         rename `var' c_`var'
    *     }
    *     qui merge 1:1 `bad' using `f`i'', assert(3)
    *     foreach var in `stats' p23 p77 {
    *         qui count if ( (abs(`var' - c_`var') > `tol') & (`var' != c_`var'))
    *         if ( `r(N)' > 0 ) {
    *             gen bad_`var' = abs(`var' - c_`var') * (`var' != c_`var')
    *             local bad `bad' *`var'
    *             di "`var' has `:di r(N)' mismatches".
    *             local bad_any = 1
    *         }
    *     }
    *     if ( `bad_any' ) {
    *         order `bad'
    *         egen bad_any = rowmax(bad_*)
    *         l *count* `bad' if bad_any & _n < 100
    *         sum bad_*
    *         di "fcollapse produced different data to collapse (tol = `tol', `by')"
    *     }
    *     else {
    *         di "fcollapse produced identical data to collapse (tol = `tol', `by')"
    *     }
    * restore
    * }

    di ""
    di as txt "Passed! checks_consistency_gcollapse `options'"
end

capture program drop checks_byvars_gcollapse
program checks_byvars_gcollapse
    syntax, [*]
    di _n(1) "{hline 80}" _n(1) "checks_byvars_gcollapse `options'" _n(1) "{hline 80}" _n(1)

    sim, n(1000) nj(250) string
    set rmsg on
    preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupsub) verbose `options'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(group) verbose `options'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupstr) verbose `options'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(grouplong) verbose `options'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupsub) verbose `options'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(group groupsub) verbose `options'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(grouplong groupsub) verbose `options'
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupstr groupsub) verbose `options'
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
        gcollapse `collapse_str', by(groupstr) verbose unsorted `options'
        if ( `=_N' > 10 ) l in 1/10
        if ( `=_N' < 10 ) l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark cw `options'
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

* TODO: Edge cases (nothing in anything, no -by-, should mimic collapse // 2017-05-16 08:03 EDT
