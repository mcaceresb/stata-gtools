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
        if ("`float'" != "")  replace group = group / `nj'
        if ("`string'" != "") tostring group, `:di cond("`replace'" == "", "gen(groupstr)", "replace")'
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

capture program drop checks_simplest_gcollapse
program checks_simplest_gcollapse
    syntax, [tol(real 1e-6)]
    di _n(1) "{hline 80}" _n(1) "checks_simplest_gcollapse" _n(1) "{hline 80}" _n(1)

    * sim, n(500000) nj(8) njsub(4) string groupmiss outmiss
    sim, n(50000) nj(8) njsub(4) string groupmiss outmiss

    local stats sum mean sd max min count percent first last firstnm lastnm median iqr
    local collapse_str ""
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') `stat' = rnorm
    }
    local collapse_str `collapse_str' (p23) p23 = rnorm
    local collapse_str `collapse_str' (p77) p77 = rnorm

    local i = 0
    mytimer 9
    preserve
        mytimer 9 info
        gcollapse `collapse_str' (p2.5) p2_5 = rnorm, by(groupsub groupstr) verbose benchmark
        mytimer 9 info "gcollapse 2 groups"
        * l
        tempfile f`i'
        save `f`i''
        local ++i
    restore, preserve
        mytimer 9 info
        fcollapse `collapse_str' (p2) p2 = rnorm (p3) p3 = rnorm, by(groupsub group) verbose
        mytimer 9 info "fcollapse 2 groups"
        * l
        tempfile f`i'
        save `f`i''
        local ++i
    restore, preserve
        mytimer 9 info
        collapse `collapse_str' (p2) p2 = rnorm (p3) p3 = rnorm, by(groupsub groupstr)
        mytimer 9 info "collapse 2 groups"
        * l
        tempfile f`i'
        save `f`i''
        local ++i
    restore

    preserve
        mytimer 9 info
        gcollapse `collapse_str' (p2.5) p2_5 = rnorm, by(groupstr) verbose benchmark
        mytimer 9 info "gcollapse 1 group"
        * l
        tempfile f`i'
        save `f`i''
        local ++i
    restore, preserve
        mytimer 9 info
        fcollapse `collapse_str' (p2) p2 = rnorm (p3) p3 = rnorm, by(groupstr) verbose
        mytimer 9 info "fcollapse 1 group"
        * l
        tempfile f`i'
        save `f`i''
        local ++i
    restore, preserve
        mytimer 9 info
        collapse `collapse_str' (p2) p2 = rnorm (p3) p3 = rnorm, by(groupstr)
        mytimer 9 info "collapse 1 group"
        * l
        tempfile f`i'
        save `f`i''
        local ++i
    restore
    mytimer 9 off

    preserve
    use `f2', clear
        local bad_any = 0
        local bad groupsub groupstr
        foreach var in `stats' p23 p77 {
            rename `var' c_`var'
        }
        merge 1:1 groupsub groupstr using `f0', assert(3)
        foreach var in `stats' p23 p77 {
            qui count if (abs(`var' - c_`var') > `tol') & !mi(c_`var')
            if ( `r(N)' > 0 ) {
                gen byte bad_`var' = abs(`var' - c_`var') > `tol'
                local bad `bad' *`var'
                di "`var' has `:di r(N)' mismatches".
                local bad_any = 1
            }
        }
        if ( `bad_any' ) {
            order `bad'
            l `bad'
        }
        else {
            di "gcollapse produced identical data to collapse (tol = `tol')"
        }

    restore, preserve

    use `f5', clear
        local bad_any = 0
        local bad groupstr
        foreach var in `stats' p23 p77 {
            rename `var' c_`var'
        }
        merge 1:1 groupstr using `f3', assert(3)
        foreach var in `stats' p23 p77 {
            qui count if (abs(`var' - c_`var') > `tol') & !mi(c_`var')
            if ( `r(N)' > 0 ) {
                gen byte bad_`var' = abs(`var' - c_`var') > `tol'
                local bad `bad' *`var'
                di "`var' has `:di r(N)' mismatches".
                local bad_any = 1
            }
        }
        if ( `bad_any' ) {
            order `bad'
            l `bad'
        }
        else {
            di "gcollapse produced identical data to collapse (tol = `tol')"
        }
    restore

    di ""
    di as txt "Passed! checks_simplest_gcollapse"
end

capture program drop checks_byvars_gcollapse
program checks_byvars_gcollapse
    di _n(1) "{hline 80}" _n(1) "checks_byvars_gcollapse" _n(1) "{hline 80}" _n(1)

    sim, n(1000) nj(250) string
    set rmsg on
    preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupsub) verbose
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(group) verbose
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupstr) verbose
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(grouplong) verbose
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupsub) verbose
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(group groupsub) verbose
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(grouplong groupsub) verbose
    restore, preserve
        gcollapse (mean) rnorm (sum) sum = rnorm (sd) sd = rnorm, by(groupstr groupsub) verbose
    restore
    set rmsg off


    di ""
    di as txt "Passed! checks_byvars_gcollapse"
end

capture program drop checks_options_gcollapse
program checks_options_gcollapse
    di _n(1) "{hline 80}" _n(1) "checks_options_gcollapse" _n(1) "{hline 80}" _n(1)

    local stats mean count median iqr
    local collapse_str ""
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') `stat' = rnorm `stat'2 = rnorm
    }

    sim, n(200) nj(10) string outmiss
    preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark
        l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose unsorted
        l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) verbose benchmark cw
        l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) double
        l
    restore, preserve
        gcollapse `collapse_str', by(groupstr) merge
        l
    restore

    sort groupstr groupsub
    preserve
        gcollapse `collapse_nopct', by(groupstr groupsub) verbose benchmark
        l in 1 / 5
    restore, preserve
        gcollapse `collapse_nopct', by(groupstr groupsub) verbose benchmark smart
        l in 1 / 5
    restore, preserve
        gcollapse `collapse_nopct', by(groupsub groupstr) verbose benchmark smart
        l in 1 / 5
    restore, preserve
        gcollapse `collapse_nopct', by(groupstr) verbose benchmark
        l in 1 / 5
    restore, preserve
        gcollapse `collapse_nopct', by(groupstr) verbose benchmark smart
        l in 1 / 5
    restore, preserve
        gcollapse `collapse_nopct', by(groupsub) verbose benchmark smart
        l
    restore, preserve
        gcollapse `collapse_nopct', by(groupsub) verbose benchmark
        l
    restore

    di ""
    di as txt "Passed! checks_options_gcollapse"
end

* TODO: Edge cases (nothing in anything, no -by-, should mimic collapse // 2017-05-16 08:03 EDT
