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

***********************************************************************
*                              fcollapse                              *
***********************************************************************

capture program drop compare_gf
program compare_gf
    syntax, nj(int) by(varlist) [pct]

    local stats sum mean sd max min count percent first last firstnm lastnm
    local collapse_nopct ""
    foreach stat of local stats {
        local collapse_nopct `collapse_nopct' (`stat') `stat' = rsort
    }

    local stats sum mean sd max min count percent first last firstnm lastnm median iqr
    local collapse_str ""
    foreach stat of local stats {
        local collapse_str `collapse_str' (`stat') `stat' = rsort
    }
    local collapse_str `collapse_str' (p23) p23 = rsort
    local collapse_str `collapse_str' (p77) p77 = rsort

    if ("`pct'" == "") local collapse `collapse_nopct'
    if ("`pct'" != "") local collapse `collapse_str'

    preserve
        timer clear
        timer on 9
            gcollapse `collapse', by(`by') verbose benchmark
        timer off 9
        qui timer list
        local r9 = `r(t9)'
    restore, preserve
        timer clear
        timer on 8
            fcollapse `collapse', by(`by') verbose
        timer off 8
        qui timer list
        local r8 = `r(t8)'
    restore

    di "Results for N = " trim("`:di %21.0gc _N'") "; nj = " trim("`:di %21.0gc `nj''; by(`by')")
    di "    gtools = `:di trim("`:di %21.4gc `r9''")' seconds"
    di "    ftools = `:di trim("`:di %21.4gc `r8''")' seconds"
    di "    ratio  = `:di trim("`:di %21.4gc `r8' / `r9''")'"
    timer clear
end

* sim, n(100000)    nj(10000)    string
* sim, n(1000000)   nj(100000)   string
* sim, n(5000000)   nj(500000)   string njsub(4)
* sim, n(10000000)  nj(10000)    string njsub(4)
* sim, n(30000000)  nj(3000000)  string sortg
* sim, n(100000000) nj(10000000) string sortg

* sim, n(10000000)  nj(1000000)  string njsub(4)
* sim, n(1000000)   nj(500000)   string njsub(4)
* sim, n(1000000)   nj(100000)   string njsub(4)
* sim, n(1000000)   nj(50000)    string njsub(4)
* sim, n(1000000)   nj(10000)    string njsub(4)
* sim, n(1000000)   nj(5000)     string njsub(4)

* cd /homes/nber/caceres/gtools/build
cd /home/mauricio/Documents/projects/dev/code/archive/2017/stata-gtools/build
!cd ..; ./build.py
do gcollapse.ado
* do gtools_tests.do

sim, n(`:di 10^6') nj(`:di 10^3') string njsub(5)
compare_gf, nj(`:di 10^3') by(groupstr)
compare_gf, nj(`:di 10^3') by(groupstr) pct
compare_gf, nj(`:di 10^3') by(grouplong groupsub)
compare_gf, nj(`:di 10^3') by(grouplong groupsub) pct

sim, n(`:di 10^6') nj(`:di 10^5') string njsub(5)
compare_gf, nj(`:di 10^5') by(groupstr)
compare_gf, nj(`:di 10^5') by(groupstr) pct
compare_gf, nj(`:di 10^5') by(grouplong groupsub)
compare_gf, nj(`:di 10^5') by(grouplong groupsub) pct

sim, n(`:di 10^7') nj(`:di 10^4') string njsub(5)
compare_gf, nj(`:di 10^4') by(groupstr)
compare_gf, nj(`:di 10^4') by(groupstr) pct
compare_gf, nj(`:di 10^4') by(grouplong groupsub)
compare_gf, nj(`:di 10^4') by(grouplong groupsub) pct

sim, n(`:di 10^7') nj(`:di 10^6') string njsub(5)
compare_gf, nj(`:di 10^5') by(groupstr)
compare_gf, nj(`:di 10^5') by(groupstr) pct
compare_gf, nj(`:di 10^5') by(grouplong groupsub)
compare_gf, nj(`:di 10^5') by(grouplong groupsub) pct
