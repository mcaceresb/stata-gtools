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
    replace groupstr = "i am a modestly long string" + groupstr

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
    syntax anything, by(str) [kvars(int 5) stats(str) kmin(int 4) kmax(int 7) legacy *]
    if ("`stats'" == "") local stats sum

    local collapse ""
    foreach stat of local stats {
        local collapse `collapse' (`stat')
        foreach var of local anything {
            local collapse `collapse' `stat'_`var' = `var'
        }
    }

    * First set of benchmarks: default vs collapse, fcollapse
    * -------------------------------------------------------

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
                gcollapse `collapse', by(`by') fast `legacy'
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" collapse ")
                qui collapse `collapse', by(`by') fast
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" fcollapse ")
                qui fcollapse `collapse', by(`by') fast
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
    syntax anything, by(str) [nj(int 10) pct(str) stats(str) kmin(int 4) kmax(int 7) legacy *]
    * NOTE: sometimes, fcollapse can't do sd
    if ("`stats'" == "") local stats sum mean max min count percent first last firstnm lastnm
    local stats `stats' `pct'

    local collapse ""
    foreach stat of local stats {
        local collapse `collapse' (`stat')
        foreach var of local anything {
            local collapse `collapse' `stat'_`var' = `var'
        }
    }

    * First set of benchmarks: default vs collapse, fcollapse
    * -------------------------------------------------------

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
                qui gcollapse `collapse', by(`by') fast `legacy'
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" collapse ")
                qui collapse `collapse', by(`by') fast
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" fcollapse ")
                qui fcollapse `collapse', by(`by') fast
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
    syntax anything, by(str) [pct(str) stats(str) obsexp(int 6) kmin(int 1) kmax(int 6) legacy *]
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

    * First set of benchmarks: default vs collapse, fcollapse
    * -------------------------------------------------------

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
                qui gcollapse `collapse', by(`by') fast `legacy'
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" collapse ")
                qui collapse `collapse', by(`by') fast
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" fcollapse ")
                qui fcollapse `collapse', by(`by') fast
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

***********************************************************************
*                      Benchmark fcollapse only                       *
***********************************************************************

capture program drop bench_switch_fcoll
program bench_switch_fcoll
    syntax anything, style(str) [GCOLLapse(str) legacy *]
    if !inlist("`style'", "ftools", "gtools") {
        di as error "Don't know benchmark style '`style''; available: ftools, gtools"
        exit 198
    }

    local 0 `anything', `options'
    if ( "`style'" == "ftools" ) {
        syntax anything, by(str) [kvars(int 5) stats(str) kmin(int 4) kmax(int 7) *]
        if ("`stats'" == "") local stats sum
        local i = 0
        local N ""
        local L N
        local dstr J = 100
        di "Benchmarking `L' for `dstr'; by(`by')"
        di "    vars  = `anything'"
        di "    stats = `stats'"

        mata: print_matrix = J(1, 0, "")
        mata: sim_matrix   = J(1, 0, "")
        forvalues k = `kmin' / `kmax' {
            mata: print_matrix = print_matrix, "    `:di %21.0gc `:di 2 * 10^`k'''"
            mata: sim_matrix   = sim_matrix,   "bench_sim_ftools `:di %21.0g 2 * 10^`k'' `kvars'"
            local N `N' `:di %21.0g 2 * 10^`k''
        }
    }
    else {
        * syntax anything, by(str) [margin(str) nj(int 10) pct(str) stats(str) obsexp(int 6) kmin(int 1) kmax(int 6) *]
        syntax anything, by(str) [margin(str) nj(int 10) pct(str) stats(str) obsexp(int 6) kmin(int 4) kmax(int 7) nvars(int 2) *]
        if !inlist("`margin'", "N", "J") {
            di as error "Don't know margin '`margin''; available: N, J"
            exit 198
        }

        if ("`stats'" == "") local stats sum mean max min count percent first last firstnm lastnm
        local stats `stats' `pct'
        local i = 0
        local N ""
        local L `margin'
        local jstr = trim("`:di %21.0gc `nj''")
        local nstr = trim("`:di %21.0gc `:di 5 * 10^`obsexp'''")
        local dstr = cond("`L'" == "N", "J = `jstr'", "N = `nstr'")
        di "Benchmarking `L' for `dstr'; by(`by')"
        di "    vars  = `anything'"
        di "    stats = `stats'"

        mata: print_matrix = J(1, 0, "")
        mata: sim_matrix   = J(1, 0, "")
        forvalues k = `kmin' / `kmax' {
            if ( "`L'" == "N" ) {
                mata: print_matrix = print_matrix, "    `:di %21.0gc `:di 2 * 10^`k'''"
                mata: sim_matrix   = sim_matrix, "bench_sim, n(`:di %21.0g 2 * 10^`k'') nj(`nj') njsub(2) nvars(`nvars')"
            }
            else {
                mata: print_matrix = print_matrix, "    `:di %21.0gc `:di 10^`k'''"
                mata: sim_matrix   = sim_matrix, "bench_sim, n(`:di %21.0g 5 * 10^`obsexp'') nj(`:di %21.0g 10^`k'') njsub(2) nvars(`nvars')"
            }
            local J `J' `:di %21.0g 10^`k''
            local N `N' `:di %21.0g 2 * 10^`k''
        }
    }

    local collapse ""
    foreach stat of local stats {
        local collapse `collapse' (`stat')
        foreach var of local anything {
            local collapse `collapse' `stat'_`var' = `var'
        }
    }

    if ( "`gcollapse'" == "" ) local w f
    else local w g

    forvalues k = 1 / `:di `kmax' - `kmin' + 1' {
        mata: st_local("sim",   sim_matrix[`k'])
        qui `sim'
        mata: printf(print_matrix[`k'])
        preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" gcollapse-default `options'")
                qui gcollapse `collapse', by(`by') `options' fast `legacy'
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') ")
        restore, preserve
            local ++i
            timer clear
            timer on `i'
            mata: printf(" `w'collapse `gcollapse'")
                qui `w'collapse `collapse', by(`by') fast `gcollapse'
            timer off `i'
            qui timer list
            local r`i' = `r(t`i')'
            mata: printf(" (`r`i'') \n")
        restore
    }

    local i = 1
    di "Results varying `L' for `dstr'; by(`by')"
    di "|              `L' | gcollapse | `w'collapse | ratio (f/g) |"
    di "| -------------- | --------- | --------- | ----------- |"
    foreach nn in ``L'' {
        local ii  = `i' + 1
        di "| `:di %14.0gc `nn'' | `:di %9.2f `r`i''' | `:di %9.2f `r`ii''' | `:di %11.2f `r`ii'' / `r`i''' |"
        local ++i
        local ++i
    }
    timer clear
end

* Benchmarks in the README
* ------------------------

* bench_ftools y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(4) kmax(7) kvars(15)
* bench_ftools y1 y2 y3,   by(x3) kmin(4) kmax(7) kvars(3) stats(mean median)
* bench_ftools y1 y2 y3 y4 y5 y6 y7 y8 y9 y10, by(x3) kmin(4) kmax(7) kvars(10) stats(mean median min max)
* bench_sample_size x1 x2, by(groupstr) kmin(4) kmax(7) pct(median iqr p23 p77)
* bench_group_size x1 x2,  by(groupstr) kmin(1) kmax(6) pct(median iqr p23 p77) obsexp(6) 

* Misc
* ----

* bench_ftools y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15, by(x3) kmin(5) kmax(8) kvars(15)
* bench_ftools y1 y2 y3,   by(x3) kmin(5) kmax(8) kvars(3) stats(mean median)
* bench_ftools y1 y2 y3 y4 y5 y6 y7 y8 y9 y10, by(x3) kmin(5) kmax(8) kvars(10) stats(mean median min max)
* bench_sample_size x1 x2, by(groupstr) kmin(5) kmax(8) pct(median iqr p23 p77)
* bench_group_size x1 x2,  by(groupstr) kmin(1) kmax(7) pct(median iqr p23 p77) obsexp(7)
