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
        gen rsort = runiform()
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
    di _n(1) "{hline 80}" _n(1) "checks_simplest_gcollapse" _n(1) "{hline 80}" _n(1)

    sim, n(500000) nj(8) njsub(4) string groupmiss outmiss

    local stats sum mean sd max min count percent first last firstnm lastnm median iqr
    local collapse_str ""
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') `stat' = rsort
    }
    local collapse_str `collapse_str' (p23) p23 = rsort
    local collapse_str `collapse_str' (p77) p77 = rsort

    set rmsg on
    preserve
        gcollapse `collapse_str' (p2.5) p2_5 = rsort, by(groupsub groupstr) verbose
        l
    restore, preserve
        fcollapse `collapse_str' (p2) p2 = rsort (p3) p3 = rsort, by(groupsub group) verbose
        l
    restore, preserve
        collapse `collapse_str' (p2) p2 = rsort (p3) p3 = rsort, by(groupsub groupstr)
        l
    restore
    set rmsg off

    set rmsg on
    preserve
        gcollapse `collapse_str' (p2.5) p2_5 = rsort, by(groupstr) verbose
        l
    restore, preserve
        fcollapse `collapse_str' (p2) p2 = rsort (p3) p3 = rsort, by(groupstr) verbose
        l
    restore, preserve
        collapse `collapse_str' (p2) p2 = rsort (p3) p3 = rsort, by(groupstr)
        l
    restore
    set rmsg off


    di ""
    di as txt "Passed! checks_simplest_gcollapse"
end

capture program drop checks_byvars_gcollapse
program checks_byvars_gcollapse
    di _n(1) "{hline 80}" _n(1) "checks_byvars_gcollapse" _n(1) "{hline 80}" _n(1)

    sim, n(1000) nj(250) string
    set rmsg on
    preserve
        gcollapse (mean) rsort (sum) sum = rsort (sd) sd = rsort, by(groupsub) verbose
    restore, preserve
        gcollapse (mean) rsort (sum) sum = rsort (sd) sd = rsort, by(group) verbose
    restore, preserve
        gcollapse (mean) rsort (sum) sum = rsort (sd) sd = rsort, by(groupstr) verbose
    restore, preserve
        gcollapse (mean) rsort (sum) sum = rsort (sd) sd = rsort, by(grouplong) verbose
    restore, preserve
        gcollapse (mean) rsort (sum) sum = rsort (sd) sd = rsort, by(groupsub) verbose
    restore, preserve
        gcollapse (mean) rsort (sum) sum = rsort (sd) sd = rsort, by(group groupsub) verbose
    restore, preserve
        gcollapse (mean) rsort (sum) sum = rsort (sd) sd = rsort, by(grouplong groupsub) verbose
    restore, preserve
        gcollapse (mean) rsort (sum) sum = rsort (sd) sd = rsort, by(groupstr groupsub) verbose
    restore
    set rmsg off


    di ""
    di as txt "Passed! checks_byvars_gcollapse"
end

* TODO: Edge cases (nothing in anything, no -by-, should mimic collapse // 2017-05-16 08:03 EDT
