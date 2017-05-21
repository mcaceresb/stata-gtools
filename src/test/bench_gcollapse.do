***********************************************************************
*                           Data simulation                           *
***********************************************************************

capture program drop bench_sim
program bench_sim
    syntax, [n(int 100) nj(int 10) njsub(int 2) nvars(int 2)]
    local offset = -123456

    clear
    set obs `n'
    gen group  = ceil(`nj' *  _n / _N) + `offset'
    gen long grouplong = ceil(`nj' *  _n / _N) + `offset'
    bys group: gen groupsub      = ceil(`njsub' *  _n / _N)
    bys group: gen groupsubfloat = ceil(`njsub' *  _n / _N) + 0.5
    tostring group, gen(groupstr)
    replace groupstr = "i am a modesly long string" + groupstr

    forvalues i = 1 / `nvars' {
        gen x`i' = rnormal()
    }
    gen rsort = runiform() - 0.5
    sort rsort

    replace group = . if runiform() < 0.1
    replace rsort = . if runiform() < 0.1
end

capture program drop bench_sim_ftools
program bench_sim_ftools
    args n k
    clear
    qui set obs `n'
    noi di "(obs set)"
    loc m = ceil(`n' / 10)
    gen long x1  = ceil(uniform() * 10000) * 100
    gen int  x2  = ceil(uniform() * 3000)
    gen byte x3  = ceil(uniform() * 100)
    gen str  x4  = "u" + string(ceil(uniform() * 100), "%5.0f")
    gen long x5  = ceil(uniform() * 5000)
    gen str  x6  = "u" + string(ceil(uniform() * 10), "%5.0f")
    noi di "(Xs set)"
    forv i = 1 / `k' {
        gen double y`i' = 123.456 + runiform()
    }
    loc obs_k = ceil(`c(N)' / 1000)
end

***********************************************************************
*                       ftools-style benchmarks                       *
***********************************************************************

capture program drop bench_ftools
program bench_ftools
    syntax anything, by(str) [kvars(int 5) stats(str) kmin(int 4) kmax(int 7) multi]
    if ("`stats'" == "") local stats sum

    local collapse ""
    foreach stat of local stats {
        local collapse `collapse' (`stat')
        foreach var of local anything {
            local collapse `collapse' `stat'_`var' = `var'
        }
    }

    local i = 0
    local N ""
    di "Benchmarking N for J = 100; by(`by')"
    di "    vars  = `anything'"
    di "    stats = `stats'"
    forvalues k = `kmin' / `kmax' {
        mata: printf("    `:di %21.0gc `:di 2 * 10^`k'''")
        local N `N' `:di %21.0g 2 * 10^`k''
        qui bench_sim_ftools `:di %21.0g 2 * 10^`k'' `kvars'
        preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" gcollapse ")
                qui gcollapse `collapse', by(`by') `multi'
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" collapse ")
                qui collapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" fcollapse ")
                qui fcollapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'')\n")
        restore
    }

    local i = 1
    di "Results varying N for J = 100; by(`by')"
    di "|              N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |"
    di "| -------------- | --------- | --------- | --------- | ----------- | ----------- |"
    foreach nn in `N' {
        local ii  = `i' + 1
        local iii = `i' + 2
        di "| `:di %14.0gc `nn'' | `:di %9.2f `r`i''' | `:di %9.2f `r`ii''' | `:di %9.2f `r`iii''' | `:di %11.2f `r`iii'' / `r`i''' | `:di %11.2f `r`ii'' / `r`i''' |"
        local ++i
        local ++i
        local ++i
    }
    timer clear
end

***********************************************************************
*                             benchmarks                              *
***********************************************************************

capture program drop bench_sample_size
program bench_sample_size
    syntax anything, by(str) [nj(int 10) pct(str) stats(str) kmin(int 4) kmax(int 7) multi]
    * NOTE: fcollapse can't do sd, apparently
    if ("`stats'" == "") local stats sum mean max min count percent first last firstnm lastnm
    local stats `stats' `pct'

    local collapse ""
    foreach stat of local stats {
        local collapse `collapse' (`stat')
        foreach var of local anything {
            local collapse `collapse' `stat'_`var' = `var'
        }
    }

    local i = 0
    local N ""
    di "Benchmarking N for J = `nj'; by(`by')"
    di "    vars  = `anything'"
    di "    stats = `stats'"
    forvalues k = `kmin' / `kmax' {
        mata: printf("    `:di %21.0gc `:di 2 * 10^`k'''")
        local N `N' `:di %21.0g 2 * 10^`k''
        qui bench_sim, n(`:di %21.0g 2 * 10^`k'') nj(`nj') njsub(2) nvars(2)
        preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" gcollapse ")
                qui gcollapse `collapse', by(`by') `multi'
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" collapse ")
                qui collapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" fcollapse ")
                qui fcollapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'')\n")
        restore
    }

    local i = 1
    di "Results varying N for J = `nj'; by(`by')"
    di "|              N | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |"
    di "| -------------- | --------- | --------- | --------- | ----------- | ----------- |"
    foreach nn in `N' {
        local ii  = `i' + 1
        local iii = `i' + 2
        di "| `:di %14.0gc `nn'' | `:di %9.2f `r`i''' | `:di %9.2f `r`ii''' | `:di %9.2f `r`iii''' | `:di %11.2f `r`iii'' / `r`i''' | `:di %11.2f `r`ii'' / `r`i''' |"
        local ++i
        local ++i
        local ++i
    }
    timer clear
end

capture program drop bench_group_size
program bench_group_size
    syntax anything, by(str) [pct(str) stats(str) obsexp(int 6) kmin(int 1) kmax(int 6) multi]
    * NOTE: fcollapse can't do sd, apparently
    if ("`stats'" == "") local stats sum mean max min count percent first last firstnm lastnm
    local stats `stats' `pct'

    local collapse ""
    foreach stat of local stats {
        local collapse `collapse' (`stat')
        foreach var of local anything {
            local collapse `collapse' `stat'_`var' = `var'
        }
    }

    local nstr = trim("`:di %21.0gc `:di 5 * 10^`obsexp'''")
    local i = 0
    local N ""
    di "Benchmarking J for N = `nstr'; by(`by')"
    di "    vars  = `anything'"
    di "    stats = `stats'"
    forvalues k = `kmin' / `kmax' {
        mata: printf("    `:di %21.0gc `:di 10^`k'''")
        local N `N' `:di %21.0g 10^`k''
        qui bench_sim, n(`:di %21.0g 5 * 10^`obsexp'') nj(`:di %21.0g 10^`k'') njsub(2) nvars(2)
        preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" gcollapse ")
                qui gcollapse `collapse', by(`by') `multi'
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" collapse ")
                qui collapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" fcollapse ")
                qui fcollapse `collapse', by(`by')
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'')\n")
        restore
    }

    local i = 1
    di "Results varying J for N = `nstr'; by(`by')"
    di "|              J | gcollapse |  collapse | fcollapse | ratio (f/g) | ratio (c/g) |"
    di "| -------------- | --------- | --------- | --------- | ----------- | ----------- |"
    foreach nn in `N' {
        local ii  = `i' + 1
        local iii = `i' + 2
        di "| `:di %14.0gc `nn'' | `:di %9.2f `r`i''' | `:di %9.2f `r`ii''' | `:di %9.2f `r`iii''' | `:di %11.2f `r`iii'' / `r`i''' | `:di %11.2f `r`ii'' / `r`i''' |"
        local ++i
        local ++i
        local ++i
    }
    timer clear
end

* !cd ..; ./build.py
* do gcollapse.ado
* do gegen.ado
* do gtools_tests.do

* Benchmarks in the README
* ------------------------

* bench_ftools y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(4) kmax(7) kvars(15)
* bench_ftools y1 y2 y3, by(x3)    kmin(4) kmax(7) kvars(3) stats(mean median)
* bench_group_size x1 x2,  by(groupstr) obsexp(6) kmax(6) pct(median iqr p23 p77)
* bench_sample_size x1 x2, by(groupstr) kmin(4)   kmax(7) pct(median iqr p23 p77)

* Misc
* ----

* bench_ftools y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(4) kmax(5) kvars(15)
* bench_ftools y1 y2 y3, by(x3)    kmin(4) kmax(5) kvars(3) stats(mean median)
* bench_group_size x1 x2,  by(groupstr) obsexp(4) kmax(4) pct(median iqr p23 p77)
* bench_sample_size x1 x2, by(groupstr) kmin(4)   kmax(5) pct(median iqr p23 p77)

* bench_ftools y1 y2 y3 y4 y5, by(x3) kmin(2) kmax(5) kvars(5)
* bench_group_size  x1 x2,  by(group) obsexp(5) kmax(4)
* bench_group_size  x1 x2,  by(group) obsexp(5) kmax(4) pct(median iqr p23 p77)
* bench_sample_size x1 x2,  by(group) kmin(2)   kmax(5)
* bench_sample_size x1 x2,  by(group) kmin(2)   kmax(5) pct(median iqr p23 p77)

* bench_group_size x1 x2,  by(groupstr) obsexp(6) kmax(6)
* bench_group_size x1 x2,  by(groupstr) obsexp(6) kmax(6) pct(median iqr p23 p77)
* bench_sample_size x1 x2, by(groupstr) kmin(4)   kmax(7)
* bench_sample_size x1 x2, by(groupstr) kmin(4)   kmax(7) pct(median iqr p23 p77)
* bench_ftools y1 y2 y3,   by(x4 x6)    kmin(4)   kmax(7) kvars(3) stats(mean median)
